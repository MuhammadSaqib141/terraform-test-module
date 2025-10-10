const fastify = require('fastify')({ logger: true });

// A health check endpoint for Container Apps to monitor the service's health.
fastify.get('/healthz', (request, reply) => {
  reply.code(200).send({ status: 'ok' });
});

// The main endpoint for creating a new order.
fastify.post('/orders', async (request, reply) => {
  const newOrder = request.body;
  newOrder.id = `order-${Math.floor(Math.random() * 10000)}`;
  newOrder.status = 'received';
  newOrder.createdAt = new Date().toISOString();

  try {
    // Publish event to Dapr pub/sub using built-in fetch
    // const daprResponse = await fetch('http://localhost:3500/v1.0/publish/messagebus/orders', {
    const daprPort = process.env.DAPR_HTTP_PORT || 3500;
    const daprResponse = await fetch(`http://localhost:${daprPort}/v1.0/publish/messagebus/orders`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(newOrder)
    });

    if (daprResponse.ok) {
      fastify.log.info({ order: newOrder.id }, "Order published to Event Hub viaaaa Dapr");
      reply.code(201).send(newOrder);
    } else {
      const errorText = await daprResponse.text();
      fastify.log.error(`Failed to publish order event: ${daprResponse.status} - ${errorText}`);
      reply.code(500).send({ error: "Failed to process order" });
    }
  } catch (error) {
    fastify.log.error(error, "Error publishing order event");
    reply.code(500).send({ error: "Failed to process order" });
  }
});

// Start the server and listen on all network interfaces inside the container.
fastify.listen({ port: 3000, host: '0.0.0.0' }, (err, address) => {
  if (err) {
    fastify.log.error(err);
    process.exit(1);
  }
});
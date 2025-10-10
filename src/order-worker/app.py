import logging
import sys
import os
import json
import requests
from flask import Flask, request, jsonify

# Configure logging
logging.basicConfig(
    stream=sys.stdout,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

app = Flask(__name__)

DAPR_PORT = os.getenv("DAPR_HTTP_PORT", "3500")
# IMPORTANT: Use the explicit state API with key control
STATE_URL = f"http://localhost:{DAPR_PORT}/v1.0/state/statestore"


# -------------------------------------------------------------
# Subscription configuration
# -------------------------------------------------------------
@app.route("/dapr/subscribe", methods=["GET"])
def subscribe():
    """
    toldd the Dapr sidecar what topics we're subscribing to.
    """
    subs = [{
        "pubsubname": "messagebus",   # matches component name in pubsub.yaml.tftpl
        "topic": "orders",            # topic name = Event Hub hub_name
        "route": "/orders"            # Deliver messages on /orders endpoint
    }]
    logging.info(f"Subscriptions exposed: {subs}")
    return jsonify(subs)

@app.route("/orders", methods=["POST"])
def handle_orders():
    """
    Handle order events published to the 'orders' topic.
    """
    cloud_event = request.get_json() or {}
    
    # Extract the actual order data from CloudEvent
    if "data" in cloud_event:
        event = cloud_event["data"]
    else:
        event = cloud_event
    
    order_id = event.get("id")
    
    if not order_id:
        logging.error("Missing 'id' in order event")
        return jsonify({"status": "ERROR", "message": "Missing order id"}), 400
    
    # Ensure customerId exists
    if "customerId" not in event:
        event["customerId"] = "anonymous"
    
    logging.info("="*60)
    logging.info("New order event received via Dapr Pub/Sub")
    logging.info(f"Order ID: {order_id}")
    logging.info(f"Event payload: {json.dumps(event, indent=2)}")
    
    clean_key = order_id
    

    '''
    TOD: Need to remove the below check block.

    # If the order_id already has a prefix, don't add another
    if "||" in clean_key:
        logging.warning(f" Key already has prefix: {clean_key}")
        # Extract just the order ID part
        clean_key = clean_key.split("||")[-1]
        logging.info(f"Cleaned key: {clean_key}")
    '''
    state_payload = [{
        "key": clean_key,
        "value": event,
        "metadata": {
            "partitionKey": clean_key
        }
    }]
    
    logging.info(f"Saving with clean key: {clean_key}")
    
    try:
        response = requests.post(STATE_URL, json=state_payload, timeout=5)
        if response.status_code == 204:
            logging.info(f"Successfully saved order {clean_key}")
            return jsonify({"status": "SUCCESS"}), 200
        else:
            logging.error(f"Failed saving order {clean_key}")
            logging.error(f"Response: {response.text}")
            return jsonify({"status": "ERROR"}), 500
    except Exception as e:
        logging.exception("Exception while saving order")
        return jsonify({"status": "ERROR", "message": str(e)}), 500


# -------------------------------------------------------------
# Health + Diagnostic Endpoints
# -------------------------------------------------------------
@app.route("/health", methods=["GET"])
def health():
    return "healthy", 200

@app.route("/", methods=["GET"])
def root():
    return jsonify({
        "status": "Worker running",
        "subscriptions": ["/dapr/subscribe"],
        "event_handler": "/orders",
        "health": "/health"
    }), 200

# -------------------------------------------------------------
# Main entrypoint
# -------------------------------------------------------------
if __name__ == "__main__":
    logging.info("Order Worker service starting...")
    logging.info(f"Listening on port 5000, Dapr sidecar at port {DAPR_PORT}")
    app.run(host="0.0.0.0", port=5000, debug=False)
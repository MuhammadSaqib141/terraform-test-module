# ./modules/search_configuration/main.tf

# =============================================================================
# 1. AI Search Datasource
# Creates the datasource imperatively using a curl command.
# =============================================================================
resource "null_resource" "create_datasource" {
  triggers = {
    # This sha256 hash ensures the command only re-runs if the config changes.
    config_hash = sha256(jsonencode(var.search_setup.datasource))
  }

  provisioner "local-exec" {
    # Using a heredoc (<<EOT) for a clean, multi-line command.
    command = <<EOT
      curl -s -f -X PUT '${var.search_endpoint}/datasources/${var.search_setup.datasource.name}?api-version=2023-11-01' \
      -H 'Content-Type: application/json' \
      -H 'api-key: ${var.search_admin_key}' \
      -d '${jsonencode({
    name                      = var.search_setup.datasource.name
    type                      = var.search_setup.datasource.type
    credentials               = var.search_setup.datasource.credentials
    container                 = var.search_setup.datasource.container
    dataChangeDetectionPolicy = var.search_setup.datasource.dataChangeDetectionPolicy
})}'
    EOT
}
}

# =============================================================================
# 2. AI Search Index
# Creates the index imperatively using a curl command.
# =============================================================================
resource "null_resource" "create_index" {
  triggers = {
    config_hash = sha256(jsonencode(var.search_setup.index))
  }

  provisioner "local-exec" {
    command = <<EOT
      curl -s -f -X PUT '${var.search_endpoint}/indexes/${var.search_setup.index.name}?api-version=2023-11-01' \
      -H 'Content-Type: application/json' \
      -H 'api-key: ${var.search_admin_key}' \
      -d '${jsonencode({
    name       = var.search_setup.index.name
    fields     = var.search_setup.index.fields
    suggesters = var.search_setup.index.suggesters
})}'
    EOT
}
}

# =============================================================================
# 3. AI Search Indexer
# Creates the indexer imperatively, depending on the successful creation
# of the datasource and index.
# =============================================================================
resource "null_resource" "create_indexer" {
  triggers = {
    config_hash = sha256(jsonencode(var.search_setup.indexer))
  }

  provisioner "local-exec" {
    command = <<EOT
      curl -s -f -X PUT '${var.search_endpoint}/indexers/${var.search_setup.indexer.name}?api-version=2023-11-01' \
      -H 'Content-Type: application/json' \
      -H 'api-key: ${var.search_admin_key}' \
      -d '${jsonencode({
    name = var.search_setup.indexer.name
    # We use the names directly from the input variable, as we know what they are.
    dataSourceName  = var.search_setup.datasource.name
    targetIndexName = var.search_setup.index.name
    schedule = {
      interval = var.search_setup.indexer.schedule
    }
})}'
    EOT
}

# Ensure this only runs AFTER the datasource and index are created.
depends_on = [
  null_resource.create_datasource,
  null_resource.create_index
]
}

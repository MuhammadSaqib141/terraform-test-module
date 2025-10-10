output "datasource_name" {
  description = "The name of the configured AI Search datasource."
  value       = var.search_setup.datasource.name
}

output "index_name" {
  description = "The name of the configured AI Search index."
  value       = var.search_setup.index.name
}

output "indexer_name" {
  description = "The name of the configured AI Search indexer."
  value       = var.search_setup.indexer.name
}
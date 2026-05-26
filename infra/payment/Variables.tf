variable "home_services_routing" {
  description = "Map of business units to secret API keys"
  type        = map(string)
  sensitive   = true
}
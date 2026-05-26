variable "project_name" { type = string; default = "e5realestate" }
variable "primary_region" { type = string; default = "us-west-2" }
variable "replica_region" { type = string; default = "us-west-1" }
variable "source_bucket_name" { type = string }
variable "replica_bucket_name" { type = string }
variable "force_destroy" { type = bool; default = true }
variable "index_document" { type = string; default = "index.html" }
variable "error_document" { type = string; default = "error.html" }
variable "acm_certificate_arn" { type = string }
variable "common_tags" {
  type    = map(string)
  default = { ManagedBy = "Terraform" }
}
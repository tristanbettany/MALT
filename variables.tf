variable "cors" {
  default = {}
}
variable "actions" {
  default = {}
}
variable "segment_four_resources" {
  default = {}
}
variable "segment_three_resources" {
  default = {}
}
variable "segment_two_resources" {
  default = {}
}
variable "segment_one_resources" {
  default = {}
}
variable "use_api_gateway" {
  default = false
}
variable "functions" {}
variable "env_ms_name" {}
variable "ms_name" {}
variable "ms_env" {}

variable "aws_account_id" {}

variable "files_to_exclude_from_zip" {
  default = [
    "terraform",
    "Dockerfile",
    "README.md",
    ".env",
    ".idea",
    ".git",
    ".gitignore",
  ]
}

variable "access_policy" {
  default = ""
}

variable "domain_name" {
  default = ""
}
variable "domain_zone_id" {
  default = ""
}
variable "domain_certificate_arn" {
  default = ""
}
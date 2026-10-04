variable "name" {
  description = "Name prefix for all VPC resources."
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC (a /16 works well with the /24 subnet carving)."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability Zones to spread subnets across."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "true = one shared NAT (cheap, single point of failure). false = one NAT per AZ (HA, costs more)."
  type        = bool
  default     = true
}

variable "vm_username" {
  type = string
  # default = ""
}
variable "local_public_ip" {
  type = string
  # default = ""
}
variable "cert_password" {
  type      = string
  sensitive = true
  # default = ""
}

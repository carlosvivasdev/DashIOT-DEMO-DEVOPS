# resource "digitalocean_firewall" "default_cluster" {
#   name = "only-22-80-and-443"
#   tags = ["k8s-cluster"]
#   inbound_rule {
#     protocol         = "tcp"
#     port_range       = "22"
#     source_addresses = ["192.168.1.0/24", "2002:1:2::/48"]
#   }

#   inbound_rule {
#     protocol         = "tcp"
#     port_range       = "30286"
#     source_addresses = ["0.0.0.0/0", "::/0"]
#   }

# }














































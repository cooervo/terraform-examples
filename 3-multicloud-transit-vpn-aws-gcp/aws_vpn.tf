# Routing specs
# VPN specs

resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_customer_gateway" "customer_gateway_1" {
  bgp_asn    = google_compute_router.transit_router_to_aws.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.vpn_gateway_to_aws.vpn_interfaces[0].ip_address
  type       = "ipsec.1"
}

resource "aws_customer_gateway" "customer_gateway_2" {
  bgp_asn    = google_compute_router.transit_router_to_aws.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.vpn_gateway_to_aws.vpn_interfaces[1].ip_address
  type       = "ipsec.1"
}

resource "aws_vpn_connection" "cx_1" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gateway.id
  customer_gateway_id = aws_customer_gateway.customer_gateway_1.id
  type                = "ipsec.1"
}

resource "aws_vpn_connection" "cx_2" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gateway.id
  customer_gateway_id = aws_customer_gateway.customer_gateway_2.id
  type                = "ipsec.1"
}
resource "aws_route_table_association" "main" {
  count = 3

  subnet_id      = aws_subnet.main[count.index].id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  propagating_vgws = [aws_vpn_gateway.vpn_gateway.id]
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_internet_gateway.id
  }
}



# Routing specs

resource "google_compute_router" "transit_router_to_aws" {
  name    = "router-main"
  network = google_compute_network.main.id
  project = var.gcp_project_id

  bgp {
    asn = 65273
  }
}

resource "google_compute_ha_vpn_gateway" "vpn_gateway_to_aws" {
  name    = "vpn-aws"
  network = google_compute_network.main.id
  project = var.gcp_project_id
}

resource "google_compute_external_vpn_gateway" "aws_gateway" {
  name            = "aws-gateway"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "VPN gateway on AWS side"
  project         = var.gcp_project_id

  interface {
    id         = 0
    ip_address = aws_vpn_connection.cx_1.tunnel1_address
  }

  interface {
    id         = 1
    ip_address = aws_vpn_connection.cx_1.tunnel2_address
  }

  interface {
    id         = 2
    ip_address = aws_vpn_connection.cx_2.tunnel1_address
  }

  interface {
    id         = 3
    ip_address = aws_vpn_connection.cx_2.tunnel2_address
  }
}

resource "google_compute_vpn_tunnel" "main-1" {
  name                            = "vpn-tunnel-1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.vpn_gateway_to_aws.self_link
  shared_secret                   = aws_vpn_connection.cx_1.tunnel1_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.self_link
  peer_external_gateway_interface = 0
  router                          = google_compute_router.transit_router_to_aws.name
  ike_version                     = 2
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "main-2" {
  name                            = "vpn-tunnel-2"
  vpn_gateway                     = google_compute_ha_vpn_gateway.vpn_gateway_to_aws.self_link
  shared_secret                   = aws_vpn_connection.cx_1.tunnel2_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.self_link
  peer_external_gateway_interface = 1
  router                          = google_compute_router.transit_router_to_aws.name
  ike_version                     = 2
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "main-3" {
  name                            = "vpn-tunnel-3"
  vpn_gateway                     = google_compute_ha_vpn_gateway.vpn_gateway_to_aws.self_link
  shared_secret                   = aws_vpn_connection.cx_2.tunnel1_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.self_link
  peer_external_gateway_interface = 2
  router                          = google_compute_router.transit_router_to_aws.name
  ike_version                     = 2
  vpn_gateway_interface           = 1
}

resource "google_compute_vpn_tunnel" "main-4" {
  name                            = "vpn-tunnel-4"
  vpn_gateway                     = google_compute_ha_vpn_gateway.vpn_gateway_to_aws.self_link
  shared_secret                   = aws_vpn_connection.cx_2.tunnel2_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.self_link
  peer_external_gateway_interface = 3
  router                          = google_compute_router.transit_router_to_aws.name
  ike_version                     = 2
  vpn_gateway_interface           = 1
}

resource "google_compute_router_interface" "main-1" {
  name       = "interface-1"
  router     = google_compute_router.transit_router_to_aws.name
  ip_range   = "${aws_vpn_connection.cx_1.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.main-1.name
}

resource "google_compute_router_interface" "main-2" {
  name       = "interface-2"
  router     = google_compute_router.transit_router_to_aws.name
  ip_range   = "${aws_vpn_connection.cx_1.tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.main-2.name
}

resource "google_compute_router_interface" "main-3" {
  name       = "interface-3"
  router     = google_compute_router.transit_router_to_aws.name
  ip_range   = "${aws_vpn_connection.cx_2.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.main-3.name
}

resource "google_compute_router_interface" "main-4" {
  name       = "interface-4"
  router     = google_compute_router.transit_router_to_aws.name
  ip_range   = "${aws_vpn_connection.cx_2.tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.main-4.name
}

resource "google_compute_router_peer" "main-1" {
  name                      = "peer-1"
  router                    = google_compute_router.transit_router_to_aws.name
  peer_ip_address           = aws_vpn_connection.cx_1.tunnel1_vgw_inside_address
  peer_asn                  = aws_vpn_connection.cx_1.tunnel1_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.main-1.name
}

resource "google_compute_router_peer" "main-2" {
  name                      = "peer-2"
  router                    = google_compute_router.transit_router_to_aws.name
  peer_ip_address           = aws_vpn_connection.cx_1.tunnel2_vgw_inside_address
  peer_asn                  = aws_vpn_connection.cx_1.tunnel2_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.main-2.name
}

resource "google_compute_router_peer" "main-3" {
  name                      = "peer-3"
  router                    = google_compute_router.transit_router_to_aws.name
  peer_ip_address           = aws_vpn_connection.cx_2.tunnel1_vgw_inside_address
  peer_asn                  = aws_vpn_connection.cx_2.tunnel1_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.main-3.name
}

resource "google_compute_router_peer" "main-4" {
  name                      = "peer-4"
  router                    = google_compute_router.transit_router_to_aws.name
  peer_ip_address           = aws_vpn_connection.cx_2.tunnel2_vgw_inside_address
  peer_asn                  = aws_vpn_connection.cx_2.tunnel2_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.main-4.name
}

# Network controls
Public ALB: internet TCP 443 and 80 redirect. Web: public ALB SG TCP 443. Internal ALB: web SG TCP 443. API: internal ALB SG TCP 8443. DB: API SG TCP 5432. No inbound SSH. DB subnets have local routes only. Use SSM for administration and HTTPS egress for updates; tighten egress using endpoints where feasible.

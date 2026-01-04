resource "aws_security_group" "allow_https" {
  name        = "allow_https"
  description = "Allow HTTPS inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.allow_https.id
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  referenced_security_group_id = module.alb.security_group_id   
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.allow_https.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}

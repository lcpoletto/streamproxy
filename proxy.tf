provider "aws" {
  region = "sa-east-1"
}

data "external" "public_ip" {
  program = ["curl", "https://api.ipify.org?format=json"]
}

data "aws_ami" "proxy" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "proxy" {
  name = "allow_proxy"
  description = "Allow inbound to proxy and outbound to internet."

  ingress {
    protocol    = "TCP"
    from_port   = 8888
    to_port     = 8888
    cidr_blocks = ["${data.external.public_ip.result.ip}/32"]
  }

  ingress {
    protocol    = "TCP"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["${data.external.public_ip.result.ip}/32"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#resource "aws_key_pair" "proxy" {
#  key_name   = "proxy"
#  public_key = "${file("/home/lcpoletto/.ssh/id_rsa.pub")}"
#}

resource "aws_instance" "proxy" {
  ami           = "${data.aws_ami.proxy.id}"
  instance_type = "t3.micro"
#  key_name      = "proxy"
  associate_public_ip_address = true
  security_groups = ["${aws_security_group.proxy.name}"]

  user_data = <<EOF
#!/usr/bin/env bash

mkdir -p /var/log
touch /var/log/user_data.log
echo "Starting user data processing." > /var/log/user_data.log
apt-get update
echo "Ran apt-get update." >> /var/log/user_data.log
apt-get install tinyproxy -y
echo "installed tinyproxy." >> /var/log/user_data.log

echo "Allow ${data.external.public_ip.result.ip}/32" >> /etc/tinyproxy/tinyproxy.conf
echo "Updated tinyproxy config." >> /var/log/user_data.log

service tinyproxy restart
echo "Restarted tinyproxy service." >> /var/log/user_data.log

EOF
}

output "proxy_ip" {
  value = "${aws_instance.proxy.public_ip}"
}

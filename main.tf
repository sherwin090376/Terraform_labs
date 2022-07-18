#Configure provider
provider "aws" {
  region     = "ap-southeast-1"
  access_key = "AKIAS5PJ2T73GBXSDIIX"
  secret_key = "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"
}
#Configure VPC
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  
    tags = {
    Name = "my-vpc"
  }
}
#Configure Security Group Allow TLS
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = " ssh from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
#creating internet gateway
resource "aws_internet_gateway" "gw01" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "my_internet_gateway"
  }
}
#creating route table
resource "aws_route_table" "rt_prod" {
  vpc_id = aws_vpc.main.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw01.id
  }
 
  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw01.id
  }
 
  tags = {
    Name = "PROD"
  }
}

#creat subnet 
resource "aws_subnet" "subnet01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
   map_public_ip_on_launch = true

  # depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "PRD_Subnet"
  }
}
 #Associate route_table 
resource "aws_route_table_association" "rt_associate1" {
  subnet_id      = aws_subnet.subnet01.id
  route_table_id = aws_route_table.rt_prod.id
}
 
#create security group to allow ports 22,80,443
resource "aws_security_group" "allow_web_access" {
  name        = "allow_web-traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.main.id
 
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
   ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
   ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "allow_web_access"
  }
}
#create a NetInterface
resource "aws_network_interface" "web_nic" {
  subnet_id       = aws_subnet.subnet01.id
  private_ips     = ["10.0.1.100"]
  security_groups = [aws_security_group.allow_web_access.id]
}
 
/*assign an elastic IP to the network interface
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web_nic.id
  associate_with_private_ip = "10.0.10.100"
  depends_on                = [aws_internet_gateway.first-gateway]
}
 */

 #create instance
resource "aws_instance" "Ubuntu_server" {
  ami           = "ami-055147723b7bca09a"
  instance_type = "t2.micro"
  availability_zone = "ap-southeast-1a"
  key_name = "linux_keypair"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web_nic.id
    
  }
  /*  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF */
 tags = {
    Name = "ubuntu webserver"
  }
  
}
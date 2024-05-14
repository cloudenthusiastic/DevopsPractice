provider "aws" {
  region = "us-east-1"

}

terraform {
  backend "s3" {
    bucket  = "cloudenthusiasticonline-terraform-bucket"
    key     = "terraform/terraform.tfstate"
    encrypt = true
    region  = "us-east-1"
  }
}

# terraform {
#   backend "s3" {
#     bucket         = "abhishek-s3-demo-xyz" # change this
#     key            = "abhi/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-lock"
#   }
# }


# resource "aws_dynamodb_table" "terraform_lock" {
#   name           = "terraform-lock"
#   billing_mode   = "PAY_PER_REQUEST"
#   hash_key       = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Project VPC"
  }

}

#############################################

resource "aws_subnet" "privateSubnet1" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

}

resource "aws_subnet" "publicSubnet1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "privateSubnet2" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

}

resource "aws_subnet" "publicSubnet2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

#############################################
resource "aws_route_table" "publicRT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "publicAssociation1" {
  subnet_id      = aws_subnet.publicSubnet1.id
  route_table_id = aws_route_table.publicRT.id
}

resource "aws_route_table_association" "publicAssociation2" {
  subnet_id      = aws_subnet.publicSubnet2.id
  route_table_id = aws_route_table.publicRT.id
}

#############################################
resource "aws_route_table" "privateRT1" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat1.id
  }
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.privateSubnet1.id
  route_table_id = aws_route_table.privateRT1.id
}

resource "aws_route_table" "privateRT2" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat2.id
  }
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.privateSubnet2.id
  route_table_id = aws_route_table.privateRT2.id
}



resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "Project IGW"
  }
}

resource "aws_eip" "publicip1" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat1" {
  subnet_id         = aws_subnet.publicSubnet1.id
  allocation_id     = aws_eip.publicip1.id
  connectivity_type = "public"

  tags = {
    Name = "gw NAT1"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}


resource "aws_eip" "publicip2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat2" {
  subnet_id         = aws_subnet.publicSubnet2.id
  allocation_id     = aws_eip.publicip2.id
  connectivity_type = "public"

  tags = {
    Name = "gw NAT2"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}


resource "aws_security_group" "test_security_group" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "sec-group"
  }
  dynamic "ingress" {
    for_each = [80, 22, 5000]
    iterator = port
    content {
      description = "security group"
      from_port   = port.value
      protocol    = "tcp"
      to_port     = port.value
      cidr_blocks = ["0.0.0.0/0"]

    }

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

}

############ to get ubuntu image
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

###

resource "aws_key_pair" "deployer" {
  key_name   = "web-key"
  public_key = file("/home/codespace/.ssh/id_rsa.pub")
}

resource "aws_instance" "web1" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.test_security_group.id}"]
  subnet_id       = aws_subnet.privateSubnet1.id
  key_name        = aws_key_pair.deployer.key_name
  user_data       = file("userscript.sh")
  tags = {
    Name = "HelloWorld1"
  }

}

resource "aws_instance" "web2" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.test_security_group.id}"]
  subnet_id       = aws_subnet.privateSubnet2.id
  key_name        = aws_key_pair.deployer.key_name
  user_data       = file("userscript.sh")
  tags = {
    Name = "HelloWorld2"
  }

}


resource "aws_instance" "web3" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.test_security_group.id}"]
  subnet_id       = aws_subnet.publicSubnet1.id
  key_name        = aws_key_pair.deployer.key_name
  tags = {
    Name = "Bastion"
  }

  connection {
    user        = "ubuntu"
    host        = self.public_ip
    type        = "ssh"
    private_key = file("/home/codespace/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = "/home/codespace/.ssh/id_rsa"
    destination = "/home/ubuntu/id_rsa"
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip}"

  }
}

# resource "aws_s3_bucket" "bucketname" {
#   bucket = "cloudenthusiasticonline-terraform-bucket"

# }

resource "aws_lb" "test" {
  name               = "terraform-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.test_security_group.id}"]
  subnets            = [aws_subnet.publicSubnet1.id, aws_subnet.publicSubnet2.id]


  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  # for_each = lookup(aws_instance.web1.id, aws_instance.web2.id)

  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.web2.id
  port             = 80
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}


output "web1ip" {
  value = aws_instance.web1.private_ip

}

output "lbdns" {
  value = aws_lb.test.dns_name

}

output "web2ip" {
  value = aws_instance.web2.private_ip

}

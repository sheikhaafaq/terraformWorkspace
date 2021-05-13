provider "aws" {
	region = "ap-south-1"
	profile = "default"
	#acesskey="XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
	#secretkey="XXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

resource "aws_vpc" "myvpc" {
	cidr_block = "10.0.0.0/16"
	instance_tenancy = "default"
	tags = { Name = "vpc by TF" }
}

resource "aws_subnet" "mysubnet" {
	vpc_id = aws_vpc.myvpc.id
	cidr_block = "10.0.1.0/24"
	tags = { Name = "subnet by TF"}
	availability_zone = "ap-south-1b"

}

resource "aws_internet_gateway" "mygw" {
	vpc_id = aws_vpc.myvpc.id
	tags = { Name = "gw by TF" }
}

resource "aws_route_table" "myroute" {
	vpc_id =  aws_vpc.myvpc.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.mygw.id
	}
	tags = { Name = "public route by TF" }
}
# Assign the routing table to mysubnet

resource "aws_route_table_association" "ass-rt" {
	subnet_id = aws_subnet.mysubnet.id
	route_table_id = aws_route_table.myroute.id
}

#Define the security Group for public subenet

resource "aws_security_group" "mysg" {
	name = "vpc-test-web"
	description = "Allow incomming http connections  & ssh access" 
	ingress { 
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = [ "0.0.0.0/0" ]
	}
	ingress {
                from_port = 22
                to_port = 22
                protocol = "tcp"
                cidr_blocks = [ "0.0.0.0/0" ] 
        }
	egress {
                from_port = 0
                to_port = 0
                protocol = "-1"
                cidr_blocks = [ "0.0.0.0/0" ]
        }
	vpc_id = aws_vpc.myvpc.id
	tags = { Name = "sg by TF" }
}


resource "aws_instance" "webos1" {
	ami = "ami-010aff33ed5991201"
	instance_type = "t2.micro"
	subnet_id = aws_subnet.mysubnet.id
	vpc_security_group_ids = [ aws_security_group.mysg.id ]
	associate_public_ip_address = true
	key_name = "awskey"
	tags = {
		Name = "webos by TF"
	}
}


resource "aws_ebs_volume" "vol1" {
	availability_zone = aws_instance.webos1.availability_zone
	size = 1
	tags = { Name = "external volume by TF" }
}
	
resource "aws_volume_attachment" "att_vol" {
	device_name= "/dev/sdc"
	instance_id = aws_instance.webos1.id
	volume_id = aws_ebs_volume.vol1.id
	force_detach = true
}

resource "local_file" "f1" {
    content  = "[cloud] \n${aws_instance.webos1.public_ip}"
    filename = "/terraformWorkspace/workspace/inventory.txt"
}

resource "null_resource"  "ansible" {
	provisioner  "local-exec" {
	command = "ansible-playbook /terraformWorkspace/workspace/ansibleWS/terraform.yml"
	}
	provisioner  "local-exec" {
        command = "firefox http://${aws_instance.webos1.public_ip}/web/index.html"
        }

}

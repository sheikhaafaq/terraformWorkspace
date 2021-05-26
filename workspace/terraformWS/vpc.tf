#--------> vpc <-----------------
resource "aws_vpc" "myVpc" {
    cidr_block = var.vpc_cidr
    tags = { Name = "tfVpc"}
  
}

#----------> Internet Gateway <------------
resource "aws_internet_gateway" "myIgw" {
    vpc_id = aws_vpc.myVpc.id
    tags = { Name = "tfIgw"}
  
}

#-------------> Subnets < -------------------
resource "aws_subnet" "mySubnet" {
    vpc_id = aws_vpc.myVpc.id
    cidr_block = element( var.subnet_cidr, count.index )
    availability_zone = element (var.az, count.index )
    count = length( var.subnet_cidr )
    map_public_ip_on_launch = false
    tags = { Name = "subnet-${ count.index + 1 }" }
}

#--------------> Route Table <----------------
resource "aws_route_table" "myRt" {
    vpc_id = aws_vpc.myVpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myIgw.id 
    }
    tags = { Name = "myPublicRt" }

}

#-------------> Associate Route Table <------------
resource "aws_route_table_association" "myAss" {
    count = length( var.subnet_cidr )
    subnet_id = element( aws_subnet.mySubnet.*.id, count.index )
    route_table_id = aws_route_table.myRt.id 
  
}

#-----------> Security Group <----------------------
resource "aws_security_group" "mySg" {
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
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
        }
	vpc_id = aws_vpc.myVpc.id
	tags = { Name = "tfSg" }
}



resource "aws_instance" "myOs" {
	count = length(var.subnet_cidr)
	ami = "ami-010aff33ed5991201"
	instance_type = "t2.micro"
	subnet_id = aws_subnet.mySubnet[count.index].id
	vpc_security_group_ids = [ aws_security_group.mySg.id ]
	associate_public_ip_address = true
	key_name = "awskey"
	tags = {
		Name = "webOs-${count.index + 1}"
	}
}


resource "aws_ebs_volume" "vol1" {
	count = length( var.subnet_cidr )
	availability_zone = aws_instance.myOs[count.index].availability_zone
	size = 1
	tags = { Name = "External Volume for myOs-${count.index}" }
}

resource "aws_volume_attachment" "att_vol" {
	count = length( var.subnet_cidr )
	device_name= "/dev/sdc"
	instance_id = aws_instance.myOs[count.index].id
	volume_id = aws_ebs_volume.vol1[count.index].id
	force_detach = true
}

resource "local_file" "f1" {
    content  = "[cloud] \n${aws_instance.myOs[0].public_ip}\n${aws_instance.myOs[1].public_ip}"
    filename = "/terraformWorkspace/workspace/inventory.txt"
}

resource "null_resource"  "ansible" {
	provisioner  "local-exec" {
	command = "ansible-playbook /terraformWorkspace/workspace/ansibleWS/terraform.yml"
	}
	provisioner  "local-exec" {
        command = "firefox http://${aws_instance.myOs[1].public_ip}/web/index.html"
        }

}


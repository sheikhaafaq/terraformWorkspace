#-----> Region <-------
variable "aws_region" {
    default = "ap-south-1"

}

#-----> vpc_cidr <-------
variable "vpc_cidr" {
    default = "10.0.0.0/16"
  
}

#------> subnet_cidr <----------
variable "subnet_cidr" {
    type = list
    default = [ "10.0.1.0/24" , "10.0.2.0/24" ]

}

#-------> availability zones <-------
variable "az" {
    type = list
    default = ["ap-south-1a", "ap-south-1b"]

}


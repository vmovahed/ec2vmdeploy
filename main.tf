locals {
       region = "us-east-1"
       vpc = "vpc-0a28a064bc6db2258"
       ssh_user = "ubuntu"
       ami = "ami-08c40ec9ead489470"
       itype = "t2.micro"
       subnet = "subnet-01c0f9f4c71cd82e8"
       publicip = true
       keyname = "capstone-proj-key-pair"
       public_key_path = "/home/vahid/deploy2ec2/myseckey.pub"
       private_key_path = "/home/vahid/deploy2ec2/myseckey"
       secgroupname = "Deploy-Sec-Group"
}

resource "aws_key_pair" "myec2keypair" {
  key_name   = local.keyname
  #public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDe9svXCfFKtQt0X8DNZ7leuUbnZAEj9vzpR5FY4HQnI8Sc63m4kHbHMosO8cdAJb3MPS1QplWEfKUiEQ67XieekxHlEDAc0hdsnLPtANmINGmdL8txtpEDkvIRp7Ua98+qmdmf3aAVOQaxc6fm1Fl2kyAM0CsZ6Qhjhse2Yhif9IMu22msDzqqsc8vpUtTCQry0qJCjVXUBVeRcy0hfvBX1uYlmpwYygDn0PFEtVVq8e+QZryzEoI6vI7dVF/Lz21IJe18JngItc3ok5dQwNX40K6mMWZKqTZjXj4858Nqc/TH8MczcuccVBrpD7CNwfEjn6vvW7pKlfgo1/TujiZXlnxPujKZi6+ocYDQ8jIcsGe37wZtE1qyPLSbCE9bbi7YAiriVafSDPH4sSvXEp6EsJejwclcA6Hbnhm6m56rMtwqEmhA3qHu+2R9n2IMPVxWz8uMDMJ+bHSVWtrky4SBJh1mnSAtWyS0y8+ww730Ay2r6/jvzXPzWFhQrN27k1c= vahid@vdevops"
  public_key = file(local.public_key_path)
}

resource "aws_security_group" "myproject-sg" {
     name = local.secgroupname
     description = local.secgroupname
     vpc_id = local.vpc

  // To Allow SSH Transport
  ingress {
       from_port = 22
       protocol = "tcp"
       to_port = 22
       cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 81 for unit test
  ingress {
       from_port = 81
       protocol = "tcp"
       to_port = 81
       cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 8080 for Jenkins
  ingress {
       from_port = 8080
       protocol = "tcp"
       to_port = 8080
       cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
       from_port       = 0
       to_port         = 0
       protocol        = "-1"
       cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
        create_before_destroy = true
  }
}

resource "aws_instance" "ec2-deploy" {
      ami = local.ami
      instance_type = local.itype
      subnet_id = local.subnet
      associate_public_ip_address = local.publicip
      key_name = local.keyname

      vpc_security_group_ids = [
        aws_security_group.myproject-sg.id
  ]
     root_block_device {
          delete_on_termination = true
          volume_size = 50
          volume_type = "gp2"
      }
     tags = {
         Name ="Capstone-Server"
         Environment = "PROD"
         OS = "UBUNTU"
         Managed = "INFRA"
      }

      depends_on = [ aws_security_group.myproject-sg ]
  connection {
    type = "ssh"
    host = self.public_ip
    user = local.ssh_user
    private_key = file(local.private_key_path)
    timeout = "4m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Wait for SSH connection to be ready...'"
    ]
  }

  provisioner "local-exec" {
    #To populate the Ansible inventory file
    command = "echo ${self.public_ip} > myhosts"
  }

#provisioner "local-exec" {
    #To execute the ansible playbook
 #   command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} wordpress-deploy.yml"
 # }

}
output "ec2instance" {
  value = aws_instance.ec2-deploy.public_ip
}



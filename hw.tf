provider "aws" {
region  =  "ap-south-1"
profile = "myaryan"
}


resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}


resource "aws_security_group" "allow_traffic" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-9aeff2f2"

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
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
    Name = "allow_tls"
  }
}


resource "aws_ebs_volume" "volume" {
  availability_zone = "ap-south-1b"
  size              = 1

  tags = {
    Name = "myvolume"
  }
}

resource "aws_instance"   "myin"  {
  ami =                                             "ami-01a2d02f77c044d3a"
  instance_type =                             "t2.micro"
  key_name=                                   "deployer-key"
  security_groups=                         ["allow_tls"]

connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/Users/aryan/Desktop/tera/mytest/hw/key1122.pem")
    host     = aws_instance.myin.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "lwos1"
  }

}




resource "aws_volume_attachment" "attachvol" {
  device_name = "/dev/sdh"
  volume_id   = "vol-0973f79a14878bb0d"
  instance_id = "i-0fc3359eceaa7c373"
  depends_on = [
    aws_ebs_volume.volume,
    aws_instance.myin
    ]
}


resource "null_resource" "nullremote5"  {

depends_on = [
    aws_volume_attachment.attachvol,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
 private_key = file("/Users/aryan/Desktop/tera/mytest/hw/key1122.pem")
    host     = aws_instance.myin.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/aryanbansal22/cloud.git  /var/www/html/"
    ]
  }
}

resource "aws_s3_bucket" "lasts119" {
  bucket = "tigerlasts"
  acl    = "public-read"

  tags = {
    Name        = "tigerlasts"
    Environment = "Dev"
  }
    versioning {
    	enabled = true
}
}

resource "aws_s3_bucket_object" "object" {
  bucket = "tigerlasts"
  key    = "tiger.jpg"
  source = "tiger.jpg"
  depends_on=[
                         aws_s3_bucket.lasts119
                         ]
                   }
                   
    
    
    resource "aws_cloudfront_distribution" "myCloudfront" {
  origin {
    domain_name = "tiger.jpg"
    origin_id   = "S3-tiger"
    
    custom_origin_config{
    	http_port = 80
    	https_port= 80
        origin_protocol_policy="match-viewer"
        origin_ssl_protocols=["TLSv1", "TLSv1.1", "TLSv1.2"]
       }
      }

 enabled             = true
 
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-tiger"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  
   restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate{
  	cloudfront_default_certificate= true
  }
  
}
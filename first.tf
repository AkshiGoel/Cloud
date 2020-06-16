provider "aws" {
   region  = "ap-south-1"
   profile ="myakshiprof"
}

resource "aws_instance" "akshiinstance" {
ami="ami-0447a12f28fddb066"
instance_type="t2.micro"
key_name="mykey2"
security_groups=["launch-wizard-1"]


 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/lk/Desktop/mykey2.pem")
    host     = aws_instance.akshiinstance.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

tags={
Name="terraOS"
}
}

output  "myoutaz" {
	value = aws_instance.akshiinstance.availability_zone
}

output  "my_public_ip" {
	value = aws_instance.akshiinstance.public_ip
}


resource "aws_ebs_volume" "akshiebs" {
  availability_zone = aws_instance.akshiinstance.availability_zone
  size              = 1
  tags = {
    Name = "terraEBS"
  }
}

resource "aws_volume_attachment" "akshiebsattach" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.akshiebs.id}"
  instance_id = "${aws_instance.akshiinstance.id}"
  force_detach = true
}

output "myos_ip" {
  value = aws_instance.akshiinstance.public_ip
}


resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.akshiinstance.public_ip} > publicip.txt"
  	}
}


resource "null_resource" "nullremote3"  {

depends_on = [
    aws_volume_attachment.akshiebsattach,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/lk/Desktop/mykey2.pem")
    host     = aws_instance.akshiinstance.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/AkshiGoel/forTerra.git /var/www/html/"
    ]
  }
}


resource "aws_s3_bucket" "akshis3" {
  bucket = "akshiterrabucket1"
  acl    = "public-read"
 
 
 provisioner "local-exec" {
        command     = "git clone https://github.com/AkshiGoel/forTerra forTerra"
    }
  

  tags = {
    Name        = "mybucket"
    Environment = "Dev"
  }
}


resource "aws_s3_bucket_object" "image-upload" {
    bucket  = aws_s3_bucket.akshis3.bucket
    key     = "gd1.png"
    source  = "forTerra/gd1.png"
    acl     = "public-read-write"
}

resource "null_resource" "nullremote4"  {


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/lk/Desktop/mykey2.pem")
    host     = aws_instance.akshiinstance.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo git clone https://github.com/AkshiGoel/forTerra.git /var/www/html/"
    ]
  }
}



resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.akshis3.bucket_domain_name
    origin_id   = aws_s3_bucket.akshis3.bucket 
	}			  

  enabled             = true
  is_ipv6_enabled     = true 

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id    = aws_s3_bucket.akshis3.bucket

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

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  

connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/lk/Desktop/mykey2.pem")
    host     = aws_instance.akshiinstance.public_ip
  }


provisioner "remote-exec" {
        inline  = [
	    "sudo su << EOF","echo \"<img src='http://${self.domain_name}/${aws_s3_bucket_object.image-upload.key}'>\" >> /var/www/html/index.html",
         "EOF"
        ]
    }
}

output "cf_op" {
  value =aws_s3_bucket.akshis3.bucket_regional_domain_name
}

output "cf_op2"{
 value=aws_s3_bucket.akshis3.bucket
 }

output "cf_op3"{
 value=aws_cloudfront_distribution.s3_distribution.domain_name
 }


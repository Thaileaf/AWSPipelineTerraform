provider "aws" {
  region = "us-east-1"  
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "league-data-collection-vpc"
  }
}

# Create a subnet
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "league-data-collection-subnet"
  }
}


resource "aws_ec2_instance_connect_endpoint" "private_connect" {
  subnet_id = aws_subnet.private.id
  security_group_ids = [aws_security_group.ec2_connect.id]

  tags = {
    Name = "EC2 Instance Connect Endpoint"
  }

}

# Create a security group for endpoint
resource "aws_security_group" "ec2_connect" {
  name        = "ec2-connect-sg"
  description = "Seucrity group for ec2_connect endpoint"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2 Connect"
  }
}

# Security Group for EC2 Instance
resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_connect.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2 SG"
  }
}

# Create an IAM role for EC2
resource "aws_iam_role" "ec2_s3_access_role" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach S3 access policy to the IAM role
resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  
  role       = aws_iam_role.ec2_s3_access_role.name
}

# Create an EC2 instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_s3_access_role.name
}

# Create an EC2 instance
resource "aws_instance" "data_collector" {
  ami           = "ami-0ff8a91507f77f867"  # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = "t2.micro"
  
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  key_name = "idrsa"
  
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "DataCollector"
  }
}

# Create an S3 bucket
resource "aws_s3_bucket" "data_bucket" {
  bucket = "league-datasets"  

  tags = {
    Name = "DataCollectionBucket"
  }
}


# Output the name of the S3 bucket
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.data_bucket.id
}
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.data_collector.id
}
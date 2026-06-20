data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_s3_bucket" "uploads" {
  bucket = "${var.project_name}-${data.aws_caller_identity.current.account_id}"

  # New S3 buckets automatically block public access by default (AWS account setting).
  # We skip aws_s3_bucket_public_access_block here because many learner IAM policies
  # lack s3:GetBucketPublicAccessBlock / s3:PutBucketPublicAccessBlock and fail with 403.
  force_destroy = true
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_upload_role" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy_document" "s3_upload_policy" {
  statement {
    sid    = "ListBucketPrefix"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.uploads.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["uploads/*"]
    }
  }

  statement {
    sid    = "UploadObjectsOnly"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload",
    ]
    resources = ["${aws_s3_bucket.uploads.arn}/uploads/*"]
  }
}

resource "aws_iam_policy" "s3_upload_policy" {
  name   = "${var.project_name}-s3-upload"
  policy = data.aws_iam_policy_document.s3_upload_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_upload_policy" {
  role       = aws_iam_role.ec2_upload_role.name
  policy_arn = aws_iam_policy.s3_upload_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.ec2_upload_role.name
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH from your IP only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y awscli
              EOF

  tags = {
    Name = "${var.project_name}-ec2"
  }
}

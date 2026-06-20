output "ec2_public_ip" {
  description = "Public IP for SSH"
  value       = aws_instance.app.public_ip
}

output "s3_bucket_name" {
  description = "Target bucket for uploads"
  value       = aws_s3_bucket.uploads.id
}

output "ssh_command" {
  description = "SSH command example"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_instance.app.public_ip}"
}

output "upload_test_command" {
  description = "Run on EC2 after SSH to verify S3 upload"
  value       = "aws s3 cp /tmp/upload-test.txt s3://${aws_s3_bucket.uploads.id}/uploads/upload-test.txt"
}

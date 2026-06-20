# terraform-ec2-s3-iam-role

Terraform tutorial project: launch an EC2 instance and grant **least-privilege S3 upload access** using an IAM instance profile — no long-lived access keys on the server.

## What this creates

- S3 bucket with public access blocked
- IAM role scoped to `uploads/*` prefix only
- IAM instance profile attached to EC2
- EC2 instance (Amazon Linux 2023) in the default VPC
- Security group allowing SSH only from your IP

## Prerequisites

- AWS account with permissions for EC2, S3, IAM, and VPC/security groups
- [Terraform](https://developer.hashicorp.com/terraform/install) 1.5+
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured (`aws configure`)
- An EC2 key pair in your target region

## Quick start

1. Copy the example variables file and edit your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Set `key_name` and `ssh_cidr` in `terraform.tfvars`.

3. Deploy:

```bash
terraform init
terraform plan
terraform apply
```

4. SSH into the instance:

```bash
terraform output ssh_command
```

5. On the EC2 instance, verify role and upload:

```bash
aws sts get-caller-identity
echo "upload test $(date)" > /tmp/upload-test.txt
aws s3 cp /tmp/upload-test.txt s3://<BUCKET_NAME>/uploads/upload-test.txt
aws s3 ls s3://<BUCKET_NAME>/uploads/
```

Replace `<BUCKET_NAME>` with `terraform output -raw s3_bucket_name`.

## Clean up

```bash
terraform destroy
```

## Security notes

- Do not put IAM user access keys on EC2 for this pattern.
- SSH is restricted to `ssh_cidr` — update it if your IP changes.
- This is a learning baseline, not a production hardening template.

## Related article

Companion tutorial: [Terraform EC2 and S3 Upload Access](https://dev.to/) *(add your dev.to link after publishing)*

## License

See [LICENSE](LICENSE).

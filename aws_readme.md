# Before migration to AssumeRole
Get credentials for tefform user: `aws iam create-access-key --user-name terraform-service-account`
Identify your current credentials: `aws sts get-caller-identity`

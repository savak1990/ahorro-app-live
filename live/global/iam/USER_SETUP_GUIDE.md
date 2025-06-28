# Ahorro Developer AWS Setup Guide

Welcome to the Ahorro development team! This guide will help you set up AWS access for the Ahorro application.

## Getting Your Credentials

### For Administrators
To retrieve console credentials for a developer user, run:

```bash
cd /path/to/ahorro-app-live/live/global/iam

# Get console login information
terraform output -json console_login_info
```

### For Developers
You should receive from your administrator:
- **Console Username**: Your IAM username
- **Console Password**: Your temporary login password
- **AWS Account ID**: The 12-digit account identifier
- **Console URL (Account ID)**: `https://[ACCOUNT-ID].signin.aws.amazon.com/console`
- **Console URL (Alias)**: `https://ahorro-app.signin.aws.amazon.com/console` (if account alias is configured)

**Note**: You will create your own programmatic access keys after initial console login.

## Self-Service Access Management

### First Time Setup

1. **Login to AWS Console**
   - Go to: `https://ahorro-app.signin.aws.amazon.com/console` (preferred if available)
   - Or: `https://[ACCOUNT-ID].signin.aws.amazon.com/console` (fallback)
   - Username: `[PROVIDED_BY_ADMIN]`
   - Password: `[PROVIDED_BY_ADMIN]`

2. **Change Your Password (Recommended)**
   ```bash
   # After initial login, change your password via CLI or console
   aws iam change-password
   ```

3. **Create Your Access Keys**
   ```bash
   # Create your first access key pair
   aws iam create-access-key --user-name [YOUR_USERNAME]
   
   # This will output:
   # {
   #   "AccessKey": {
   #     "AccessKeyId": "AKIA...",
   #     "SecretAccessKey": "...",
   #     "Status": "Active",
   #     "CreateDate": "..."
   #   }
   # }
   ```

### Managing Your Access Keys
You can have up to 2 active access keys:

```bash
# List your current access keys
aws iam list-access-keys --user-name [YOUR_USERNAME]

# Create a new access key (useful for key rotation)
aws iam create-access-key --user-name [YOUR_USERNAME]

# Delete an old access key when no longer needed
aws iam delete-access-key --user-name [YOUR_USERNAME] --access-key-id [OLD_KEY_ID]

# Deactivate an access key (without deleting)
aws iam update-access-key --user-name [YOUR_USERNAME] --access-key-id [KEY_ID] --status Inactive
```

## Setup Steps

### 1. Initial AWS Console Login

1. Go to: `https://ahorro-app.signin.aws.amazon.com/console` (preferred)
   - Or: `https://[ACCOUNT-ID].signin.aws.amazon.com/console` (if alias doesn't work)
2. Use your IAM username provided by admin
3. Use your initial password provided by admin
4. **Important**: Change your password immediately after first login

### 2. Create Access Keys

In the AWS Console or via CLI:

**Via Console:**
1. Go to IAM → Users → [Your Username] → Security credentials
2. Click "Create access key"
3. Choose "Command Line Interface (CLI)"
4. Save the Access Key ID and Secret Access Key securely

**Via CLI (after console login):**
```bash
aws iam create-access-key --user-name [YOUR_USERNAME]
```

### 3. Configure AWS CLI

```bash
aws configure
```

When prompted, enter your newly created credentials:
- **AWS Access Key ID**: `[YOUR_CREATED_ACCESS_KEY]`
- **AWS Secret Access Key**: `[YOUR_CREATED_SECRET_KEY]`
- **Default region name**: `eu-west-1`
- **Default output format**: `json`

### 4. Test CLI Access

```bash
# Verify your identity
aws sts get-caller-identity

# Test S3 access (should show ahorro buckets only)
aws s3 ls

# Test Secrets Manager access
aws secretsmanager list-secrets --query 'SecretList[?starts_with(Name, `ahorro`)]'
```

## Prerequisites

- Install AWS CLI: `brew install awscli` (macOS) or follow [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## What You Can Access

Your access is restricted to Ahorro-related resources, plus you can manage your own IAM credentials:

✅ **Allowed:**
- S3 buckets starting with "ahorro-"
- Lambda functions starting with "ahorro-"
- RDS databases tagged with "Project=ahorro-app"
- DynamoDB tables starting with "ahorro-"
- Secrets Manager secrets starting with "ahorro-"
- CloudWatch logs for ahorro services
- **Self-service IAM actions**: Change password, create/delete your own access keys

❌ **Not Allowed:**
- Resources without proper ahorro naming
- Resources without "Project=ahorro-app" tags
- Other users' IAM credentials
- Other AWS accounts or regions (except eu-west-1)

## Running Makefile Commands

You can now run all Makefile targets in the ahorro-transactions-service:

```bash
cd /path/to/ahorro-transactions-service

# Build the service
make build

# Deploy to AWS
make deploy

# Run tests
make test

# Clean build artifacts
make clean

# Any other targets defined in the Makefile
make [target-name]
```

## Troubleshooting

### Common Issues

1. **Access Denied Errors**
   - Ensure the resource has "ahorro-" prefix or "Project=ahorro-app" tag
   - Check you're in the eu-west-1 region

2. **CLI Not Working**
   ```bash
   # Verify your configuration
   aws configure list
   
   # Test basic connectivity
   aws sts get-caller-identity
   ```

3. **Console Login Issues**
   - Verify the correct account ID in the URL
   - Use your exact IAM username (case-sensitive)
   - If password doesn't work, contact admin

4. **Access Key Issues**
   - Ensure you created the keys correctly via console or CLI
   - Check that you're using the right Access Key ID and Secret
   - Verify keys are Active status: `aws iam list-access-keys --user-name [YOUR_USERNAME]`

### Getting Help

- Check CloudWatch logs for detailed error messages
- Contact the infrastructure team for access issues
- Review this guide for common solutions

## Administrative Tasks

### Adding New Users
Administrators can modify user access by updating the Secrets Manager secret:

```bash
# Update the secret with new user information
aws secretsmanager put-secret-value \
  --secret-id ahorro-app-secrets \
  --secret-string '{
    "domain_name": "your-domain.com",
    "transactions_db_username": "db-user",
    "transactions_db_password": "db-password",
    "dev_name_1": "new-developer-username",
    "default_aws_password": "new-default-password"
  }'

# Apply changes
cd /path/to/ahorro-app-live/live/global/iam
terraform plan
terraform apply
```

## Security Best Practices

1. Change your console password on first login
2. Never share your AWS credentials
3. Use MFA when possible
4. Don't hardcode credentials in code
5. Use environment variables or AWS CLI profiles
6. Report any suspicious activity immediately

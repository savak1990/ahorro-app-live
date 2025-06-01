
- **stable/**: Terraform configuration for the stable environment.
- **prod/**: Terraform configuration for the production environment.
- **Makefile**: Automation commands for deploying environments.
- **.gitignore**: Ignores local state and sensitive files.

## Usage

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html)
- AWS CLI configured with appropriate credentials

### Deploying an Environment

To deploy the `global-s3` environment:

```bash
make deploy-global-s3
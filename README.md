

Deploy an Ubuntu Instance from a Terraform plan stored in Github to Azure.

Installation

Requires Jenkins 2.0, Terraform v0.9.3 or higher and the AzureRM provider for Azure 2.0
- create jenkins job, install keys in the correct places, Git plugin, SSH plugin and some others
- Requires credentials and App setup in Azure.

Tests
The terraform can be tested with: terraform plan azure.tf

Contributors

jeff@collettpark.com

License

These code samples are licensed under MIT

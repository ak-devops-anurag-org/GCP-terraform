# GCP Terraform VM Project

This project provisions a simple Google Cloud Platform (GCP) virtual machine (VM) instance using Terraform. It is designed to be cost-effective and suitable for a free tier account.

## Project Structure

The project is organized into the following directories and files:

```
gcp-terraform-vm
├── modules
│   └── vm
│       ├── main.tf          # Main configuration for the VM instance
│       ├── variables.tf     # Input variables for the VM module
│       └── outputs.tf       # Outputs for the VM module
├── environments
│   └── dev
│       ├── main.tf          # Entry point for the development environment
│       └── terraform.tfvars  # Variable values for the development environment
├── scripts
│   └── startup.sh           # Startup script for the VM instance
├── provider.tf              # Provider configuration for Google Cloud
├── versions.tf              # Required Terraform and provider versions
├── main.tf                  # Main entry point for the Terraform configuration
├── variables.tf             # Global input variables for the project
├── outputs.tf               # Global outputs for the project
├── terraform.tfvars.example  # Example variable values
├── backend.tf.example       # Example configuration for remote state management
├── .gitignore               # Files and directories to ignore by Git
└── README.md                # Project documentation
```

## Setup Instructions

1. **Install Terraform**: Ensure you have Terraform installed on your machine. You can download it from the [Terraform website](https://www.terraform.io/downloads.html).

2. **Configure Google Cloud Credentials**: Set up your Google Cloud credentials by following the instructions in the [Google Cloud documentation](https://cloud.google.com/docs/authentication/getting-started).

3. **Clone the Repository**: Clone this repository to your local machine.

4. **Navigate to the Project Directory**: Change into the project directory:
   ```
   cd gcp-terraform-vm
   ```

5. **Initialize Terraform**: Run the following command to initialize the Terraform project:
   ```
   terraform init
   ```

6. **Review and Customize Variables**: Edit the `environments/dev/terraform.tfvars` file to customize the variable values for your development environment.

7. **Plan the Deployment**: Run the following command to see the resources that will be created:
   ```
   terraform plan
   ```

8. **Apply the Configuration**: If everything looks good, apply the configuration to create the VM instance:
   ```
   terraform apply
   ```

9. **Access the VM**: Once the VM is created, you can access it using the public IP address outputted by Terraform.

## Usage

This project is designed to be modular, allowing you to easily extend or modify the VM configuration by updating the files in the `modules/vm` directory. You can also create additional environments by duplicating the `environments/dev` directory and modifying the necessary files.

## Contributing

Feel free to submit issues or pull requests if you have suggestions for improvements or additional features.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.
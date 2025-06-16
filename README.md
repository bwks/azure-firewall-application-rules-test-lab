# Azure Firewall Lab

This is the companion repo for [this](https://stratuslabs.net/blog/azure-firewall-application-rules-processing) blog post. Please see the post for further details.

## Usage

### Environment Variables
Set the following shell env vars or, update `variables.tf` and `main.tf`
```
### main.tf
ARM_SUBSCRIPTION_ID # Subscription to deploy resources into.

### variables.tf
TF_VAR_vm_username # Username will be applied to VMs as a sudo user.
TF_VAR_local_public_ip # Used to restrict access to your local public IP in Azure FW rules.
```

### Generate Certificates
```
./certs.sh
```

### Deploy Azure Resources
```
cd ..
terraform apply

# Get FIREWALL_PIP from output to use in next step

cd certs/
FIREWALL_PIP="x.x.x.x" ./deploy.sh
```

### Configure VMs
```
cd certs/
FIREWALL_PIP="x.x.x.x" ./deploy.sh
```
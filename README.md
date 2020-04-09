# demo-f5-cis-gcp-gke-terraform-cloud
Deploy F5 container ingress(CIS) with Google Kubernetes Engine (GKE) as the backend using Terraform cloud. 

# Prerequisites:

- ## Terraform Cloud
    [Terraform Cloud Account](https://app.terraform.io/)

- ## GCE service Account
    [GCP Service account with key](https://console.cloud.google.com/iam-admin/serviceaccounts/)

# Overview:
 1. Create workspace in Terraform Cloud
 2. Fork this repo for your edits and builds.
 3. Link Terraform Cloud to the repo for githooks
 4. Create gcp service account and key for Terraform Cloud
    - login to gcp and issue a service account with permissions to your project
 5. set project variables for Terraform Cloud project

# ***Mark items as sensitive for write only access***
## Variables:
    - projectPrefix
        - project prefix/tag for all object names
        
            example: "mydeployment-"

    - serviceAccountFile
        - your json service account [ sensitive]
            
            example: ""

    - gcpProjectId
        - the project ID you want to deploy in
            
            example: ""

    - gcpRegion
        - the gcp region you want to deploy in
            example: "us-east1"

    - gcpZone
        - the gcp zone you want to deploy in
            
            example: "us-east1-b"

    - adminSrcAddr
        - ip/mask in cidr formatt for admin access
            
            example: "myexternalip/32"

    - adminAccount
        - admin account name ( not admin)

                example: "myuser"
            
    - adminPass [ sensitive]
        - your temp password
            
            example: "MysuperPass"
            
    - gceSshPubKeyFile [ sensitive]
        - contents of the admin ssh public key file
            
            example: ""

    - customImage
        - string of the path to your custom image

            example: "projects/my-project-id/global/images/f5-bigip-15-1-0-0-0-31-byol-all-1slot-fxaschncp"

    - bigipLicense1
        - string of license key if your using byol

            example: "my-key-value-text-string"
6. queue a run of the project

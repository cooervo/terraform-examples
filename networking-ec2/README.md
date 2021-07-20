### Plan

1. Create a VPC
2. Create Internet Gateway
3. Create Custom Route Table
4. Create a Subnet
5. Associate Subnet with Route table
6. Create Security Group to allow port 22 (ssh), 80 (http) and 443 (https)
7. Create Network Interface with an IP in the subnet created in step 4
8. Assign an Elastic IP to the Network Interface created in step 7
9. Create Ubuntu instance and install apache server in it. 

locals {
  webvm_custom_data = <<CUSTOM_DATA
#!/bin/sh
#!/bin/sh
#sudo yum update -y
sudo yum install -y httpd
sudo systemctl enable httpd
sudo systemctl start httpd  
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo chmod -R 777 /var/www/html 
sudo echo "Welcome to Azure Verified Modules - Application Gateway Root - VM Hostname: $(hostname)" > /var/www/html/index.html
sudo mkdir /var/www/html/app1
sudo echo "Welcome to Azure Verified Modules - Application Gateway Host App1 - VM Hostname: $(hostname)" > /var/www/html/app1/hostname.html
sudo echo "Welcome to Azure Verified Modules - Application Gateway - App1 Status Page" > /var/www/html/app1/status.html
sudo echo '<!DOCTYPE html> <html> <body style="background-color:rgb(132, 204, 22);"> <h1>Welcome to Azure Verified Modules - Application Gateway APP-1 </h1> <p>Terraform Demo</p> <p>Application Version: V1</p> </body></html>' | sudo tee /var/www/html/app1/index.html
sudo mkdir /var/www/html/app2
sudo echo "Welcome to Azure Verified Modules - Application Gateway Host App1 - VM Hostname: $(hostname)" > /var/www/html/app2/hostname.html
sudo echo "Welcome to Azure Verified Modules - Application Gateway - App1 Status Page" > /var/www/html/app2/status.html
sudo echo '<!DOCTYPE html> <html> <body style="background-color:rgb(22, 134, 204);"> <h1>Welcome to Azure Verified Modules - Application Gateway APP-2 </h1> <p>Terraform Demo</p> <p>Application Version: V1</p> </body></html>' | sudo tee /var/www/html/app2/index.html

CUSTOM_DATA
}

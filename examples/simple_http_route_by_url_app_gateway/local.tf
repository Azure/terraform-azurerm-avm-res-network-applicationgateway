
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
sudo mkdir /var/www/html/images
sudo echo "Welcome to Azure Verified Modules - Application Gateway [IMAGES] - VM Hostname: $(hostname)" > /var/www/html/images/test.html
sudo mkdir /var/www/html/video
sudo echo "Welcome to Azure Verified Modules - Application Gateway [VIDEO] - VM Hostname: $(hostname)" > /var/www/html/video/test.html
CUSTOM_DATA
}

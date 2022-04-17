#! /bin/bash
yum update -y
yum install python3 -y
pip3 install flask
pip3 install flask_mysql
yum install git -y
cd /home/ec2-user && git clone https://github.com/fikretgit/DevOps-Project/Terraform/Project_2-Phonebook-Application/phonebook.git
python3 /home/ec2-user/phonebook/phonebook-app.py

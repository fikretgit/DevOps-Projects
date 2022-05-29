## Part 1 - Launch the instances

- Create 4 `Red Hat Enterprise Linux 8 (HVM), SSD Volume Type - ami-0b0af3577fe5e3532 (64-bit x86) / ami-01fc429821bf1f4b4 (64-bit Arm)` ami. 

- ansible_control (t2.medium) (tag: Name=ansible_control) (tag: key:stack Value:ansible_project)(sec-group:ssh-80 everywhere)

- ansible_postgresql, ansible_nodejs, ansible_react (t2.micro) (Add 5000, 3000, 5432 to security groups)

- The name and tag to the ec2 instances;
key: Name  Value: ansible_postgresql,   key:environment value:development,   key:stack value:ansible_project
key: Name  Value: ansible_react,        key:environment value:development,   key:stack value:ansible_project
key: Name  Value: ansible_nodejs,       key:environment value:development,   key:stack value:ansible_project

## Part 2 - Prepare the scene

Connect the ansible_control node
   
   - Copy the student files

   - Run the commands below to install Python3 and Ansible. 

$ sudo yum update -y

$ sudo yum install -y python3 

$ pip3 install --user ansible

$ ansible --version

- Create ansible directory and change directory to this directory.

mkdir ansible
cd ansible
```
- Create `ansible.cfg` files.

```
[defaults]
host_key_checking = False
inventory=inventory_aws_ec2.yml
interpreter_python=auto_silent
private_key_file=/home/ec2-user/xxxxx.pem   #type your key.pem
remote_user=ec2-user
```
- copy pem file from local to home directory of ec2-user.

scp -i <pem-file> <pem-file> ec2-user@<public-ip of ansible_control>:/home/ec2-user

$ chmod 400 xxxxx.pem
```
## Part 3 - Creating dynamic inventory (Targets will get Ip address by this, IP address can be change when ec2 stop etc.)

- go to AWS Management Consol and select the IAM roles:

- click the  "create role" then create a role with "AmazonEC2FullAccess"

- go to EC2 instance Dashboard, and select the control-node instance

- select actions -> security -> modify IAM role

- select the role thay you have jsut created for EC2 full access and save it.

- install "boto3"

```bash
pip3 install --user boto3   # We need it to use dynamic inventory
```
- Create `inventory_aws_ec2.yml` file under the ansible directory. 

```yaml
plugin: aws_ec2
regions:
  - "us-east-1"
filters:
  tag:stack: ansible_project
keyed_groups:
  - key: tags.Name
  - key: tags.environment
compose:
  ansible_host: public_ip_address
```

$ ansible-inventory -i inventory_aws_ec2.yml --graph
```
@all:
  |--@_ansible_control:
  |  |--ec2-3-80-96-146.compute-1.amazonaws.com
  |--@_ansible_nodejs:
  |  |--ec2-3-239-243-194.compute-1.amazonaws.com
  |--@_ansible_postgresql:
  |  |--ec2-3-236-160-236.compute-1.amazonaws.com
  |--@_ansible_react:
  |  |--ec2-3-236-197-117.compute-1.amazonaws.com
  |--@_development:
  |  |--ec2-3-236-160-236.compute-1.amazonaws.com
  |  |--ec2-3-236-197-117.compute-1.amazonaws.com
  |  |--ec2-3-239-243-194.compute-1.amazonaws.com
  |--@aws_ec2:
  |  |--ec2-3-236-160-236.compute-1.amazonaws.com
  |  |--ec2-3-236-197-117.compute-1.amazonaws.com
  |  |--ec2-3-239-243-194.compute-1.amazonaws.com
  |  |--ec2-3-80-96-146.compute-1.amazonaws.com
  |--@ungrouped:
```

- To make sure that all our hosts are reachable with dynamic inventory, we will run various ad-hoc commands that use the ping module.

$ ansible all -m ping --key-file "~/xxxxxx.pem"
```
```
## Part 4 - Prepare the playbook files

- Create `ansible-Project` directory under home directory and change directory to this directory.

```bash
mkdir ansible-Project
cd ansible-Project
```

- Create `postgres`, `nodejs`, `react` directories.

```bash
mkdir postgres nodejs react
```

- Copy `~/student_files/todo-app-pern` directory to ansible-Project directory.

- Change directory to `postgres` directory.

```bash
cd postgres
```
- Copy `init.sql` file from `student_files/todo-app-pern/database` to `postgres` directory. (For the initialize database)

- Create a Dockerfile

```Dockerfile    (Write 'postgress' to search on 'hub.docker.com' content given)
FROM postgres

COPY ./init.sql /docker-entrypoint-initdb.d/     

EXPOSE 5432
```
- change directory `~/ansible` directory.

```bash
cd ~/ansible
```

- Create a yaml file as postgres playbook and name it `docker_postgre.yml`.

```yaml
- See it in 'solution_files/wide_solution/postgre_files'
```
- Execute it.
$ ansible-playbook --ask-vault-pass docker_postgre.yml
```

- Change directory to `~/ansible-Project/nodejs` directory.

```bash
cd ~/ansible-Project/nodejs
```

- Create a Dockerfile.
```
-Dockerfile inside 'solution_files/wide_solution/nodejs_files'


- Change the `~/ansible-Project/todo-app-pern/server/.env` file as below.
```
SERVER_PORT=5000
DB_USER=postgres
DB_PASSWORD=Pp123456789
DB_NAME=clarustodo
DB_HOST=<private ip of postgresql instance>
DB_PORT=5432
```

cd ~/ansible-Project/nodejs
```
- Create a yaml file as nodejs playbook and name it `docker_nodejs.yml`.

```yaml
- See the file inside wide_solution/nodejs_file
```
- Execute it.
ansible-playbook docker_nodejs.yml
```

- Change directory to `~/ansible-Project/react` directory.

```bash
cd ~/ansible-Project/react
```
- Create a Dockerfile.

Dockerfile inside 'solution_files/wide_solution/react_files'


- Change the `~/ansible-Project/todo-app-pern/client/.env` file as below.

```
REACT_APP_BASE_URL=http://<public ip of nodejs>:5000/
```

```bash
cd ~/ansible-Project/react
```

- Create a yaml file as react playbook and name it `docker_react.yml`.

```yaml
- See the file inside solution/wide_solution/react_file

- Execute it.
ansible-playbook docker_react.yml
```
````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````

## Part 5 - Prepare one playbook file for all instances.

- Create a `docker_project.yaml` file under `the ~/ansible` folder.

```yaml
- See 'docker_project.yml' the file solution_files/one_playbook

- Execute it.
```
ansible-playbook docker_project.yaml
```

## Part 6 - Prepare one playbook roles for all instances.

- Create a 'roles' folder under ansible directory.
$ cd roles
$ ansible-galaxy init docker
$ ansible-galaxy init postgre
$ ansible-galaxy init nodejs
$ ansible-galaxy init react    # These commands create 4 empty folder under ansible/roles.

- We will take the plays previous method copy to the tasks as a role;

- Tasks file 'main.yml' for 'ansible/roles/docker/tasks' fill it.

#  We will work on the 'tasks', 'vars' and 'files' of the Postgre-Nodejs-React directory under 'ansible/roles'

- Fill the 'main.yml' file for /home/ec2-user/ansible/roles/postgre/tasks.

- Fill the main.yml file under '/home/ec2-user/ansible/roles/postgre/vars' 

- Copy the 'Dockerfile and init.sql" files from 'wide_solution/postgre_files' to the 'roles/postgre/files'.
* On main.yml file We don't need to give the path of script, Dockerfile because we will put them into "files" 'ansible/roles/postgre/files'


- Copy the 'Dockerfile' and 'server' folder to the '/home/ec2-user/ansible/roles/nodejs/files'

- Fill the 'main.yml' file for /home/ec2-user/ansible/roles/nodejs/tasks.

-  Fill the main.yml file under '/home/ec2-user/ansible/roles/nodejs/vars' 


- Copy the 'Dockerfile' and 'client' folder to the '/home/ec2-user/ansible/roles/react/files'

- Fill the 'main.yml' file for /home/ec2-user/ansible/roles/react/tasks.

-  Fill the main.yml file under '/home/ec2-user/ansible/roles/react/vars'
```
```
- Create 'play-role.yml' 'ansible.cfg' file under '/home/ec2-user/ansible'

$ cd ansible
$ ansible-playbook play-role.yml 

The work done and the project will work. However there is another way, we could get the ready-role from ansible-galaxy;

- Get the docker role of 'geerlingguy' from ansible-galaxy or by command.
$ ansible-galaxy search docker --platform EL | grep geerl
$ ansible-galaxy install geerlingguy.docker   # Ready and more comprehensive ready-docker role from geerling guy downloaded to ec2.

- Create 'play-newrole.yml'
$ ansible-playbook play-newrole.yml







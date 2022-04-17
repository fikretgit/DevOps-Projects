data "aws_vpc" "selected" {
  default = true
}

data "aws_ami" "instance" {
  owners = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10*"]
  }
}

data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

resource "aws_launch_template" "asg-lt" {
  name = "phonebook-lt"
  image_id = data.aws_ami.instance.id
  instance_type = "t2.micro"
  key_name = "xxxxxx" # write your keyname
  vpc_security_group_ids = [aws_security_group.server-sg.id]
  user_data = filebase64("user-data.sh")
  depends_on = [github_repository_file.dbendpoint]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Web Server of Phonebook App"
    }
  }
}

resource "aws_alb_target_group" "app-lb-tg" {
  name = "phonebook-lb-tg"
  protocol = "HTTP"
  port = 80
  vpc_id = data.aws_vpc.selected.id
  target_type = "instance"
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}

resource "aws_alb" "app-lb" {
  name = "phonebook-lb-tf"
  internal = false
  ip_address_type = "ipv4"
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb-sg.id]
  subnets = data.aws_subnets.example.ids
}

resource "aws_alb_listener" "app-listener" {
  load_balancer_arn = aws_alb.app-lb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.app-lb-tg.arn
  }
}

resource "aws_autoscaling_group" "app-asg" {
  max_size = 3
  min_size = 1
  desired_capacity = 2
  name = "phonebook-asg"
  health_check_grace_period = 300
  health_check_type = "ELB"
  target_group_arns = [aws_alb_target_group.app-lb-tg.arn]
  vpc_zone_identifier = aws_alb.app-lb.subnets



  launch_template {
    id = aws_launch_template.asg-lt.id
    version = aws_launch_template.asg-lt.latest_version
  }
}

resource "aws_db_instance" "db-server" {
  instance_class = "db.t2.micro"
  allocated_storage = 20
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  allow_major_version_upgrade = false
  auto_minor_version_upgrade = true
  backup_retention_period = 0
  identifier = "phonebook-app-db"
  db_name = "phonebook"
  engine = "mysql"
  engine_version = "8.0.28"
  username = "xxxxxx"  # type your username
  password = "xxxxxxx"  # type your password
  monitoring_interval = 0
  multi_az = false
  port = 3306
  publicly_accessible = false
  skip_final_snapshot = true
}

resource "github_repository_file" "dbendpoint" {
  content    = aws_db_instance.db-server.address
  file       = "dbserver.endpoint"
  repository = "phonebook"
  overwrite_on_create = true
  branch = "main"  # you change if your branch name "master"
}
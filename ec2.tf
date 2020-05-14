resource "aws_eip" "tfEIP_RH8" {
  instance = aws_instance.tfRH8_ans.id
  vpc = true
}

resource "aws_instance" "tfRH8_ans" {
  ami = "ami-07dd14faa8a17fb3e"
  instance_type = "t2.micro"
  disable_api_termination = false
  key_name = aws_key_pair.ec2_key.id
  vpc_security_group_ids = [aws_security_group.tfSG01.id]
  subnet_id = aws_subnet.tfpublic-a.id
  private_ip = "10.0.0.11"
  associate_public_ip_address = true

  user_data = <<EOF
#!/bin/bash
dnf install -y telnet
dnf install -y gcc zlib-devel bzip2 bzip2-devel readline readline-devel sqlite sqlite-devel openssl openssl-devel git libffi-devel make git
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
EOF

  tags = {
    Name = "tfRH8_ans"
  }
}


data "template_file" "init" {
  template = file(var.user_data_path)
  vars = {
    admin_password = var.admin_password
  }
}

resource "aws_instance" "tfWin2019" {
  ami = "ami-008755994dfc325f7"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ec2_key.id
  vpc_security_group_ids = [aws_security_group.tfSG01.id]
  subnet_id = aws_subnet.tfprivate-a.id
  private_ip = "10.0.1.11"
  associate_public_ip_address = false

  user_data     = data.template_file.init.rendered

  connection {
    type = "winrm"
    user = "Administrator"
    password = var.admin_password
  }

  tags = {
    Name = "tfWin2019"
  }
}

resource "aws_instance" "tfUbuntu18" {
  ami = "ami-0278fe6949f6b1a06"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ec2_key.id
  vpc_security_group_ids = [aws_security_group.tfSG01.id]
  subnet_id = aws_subnet.tfprivate-b.id
  private_ip = "10.0.2.11"
  associate_public_ip_address = false

  tags = {
    Name = "tfUbuntu18"
  }
}

output "RH8_public_ip" {
  value = aws_eip.tfEIP_RH8.public_ip
}

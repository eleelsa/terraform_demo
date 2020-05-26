#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
  dnf install -y telnet
  dnf install -y gcc zlib-devel bzip2 bzip2-devel readline readline-devel sqlite sqlite-devel openssl openssl-devel git libffi-devel make git
  git clone https://github.com/pyenv/pyenv.git ~/.pyenv
  echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bash_profile
  echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
  cp -pf /root/.ssh/authorized_keys /root/.ssh/authorized_keys.org && cp -pf /home/ec2-user/.ssh/authorized_keys /root/.ssh/authorized_keys

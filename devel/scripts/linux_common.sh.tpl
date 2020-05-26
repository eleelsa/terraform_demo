exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
  cp -pf /root/.ssh/authorized_keys /root/.ssh/authorized_keys.org && cp -pf /home/ec2-user/.ssh/authorized_keys /root/.ssh/authorized_keys 

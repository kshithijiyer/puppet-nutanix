1) Setup puppet agent package (since we are running the tasks against the puppet vendored ruby)
el: yum -ivh http://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm; yum install puppet-agent
deb: http://apt.puppet.com/README.txt - install the pc1 repo version for your os

2) setup /etc/nutanix.yaml:
---
servers:
  default:
    hostname: 'hostname'
    port: 'port'
    username: 'username'
    password: 'password' 

3) set environment variables according to the tasks associated .json, ie:
PT_vm_name='testing'
echo $PT_vm_name

4) run the task: /opt/puppetlabs/puppet/bin/ruby tasks/list_vms.rb


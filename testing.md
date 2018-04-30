1) Setup puppet agent package (since we are running the tasks against the puppet vendored ruby)
- el: yum -ivh http://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm; yum install puppet-agent
- deb: http://apt.puppet.com/README.txt - install the pc1 repo version for your os

2) setup /etc/nutanix.yaml:

```yaml
---
servers:
  default:
    hostname: 'hostname'
    port: 'port'
    username: 'username'
    password: 'password'
```

3) Pass the example .json (puppet tasks are passed json'fied version of all params on standard in)

4) run the task:  cat examples/test_vm.json | /opt/puppetlabs/puppet/bin/ruby tasks/list_vms.rb

5) Example output from a run:
```
$ cat examples/test_vm.json | tasks/create_vm.rb
Attempting to create testing-provisioning
Request Accepted
VM creation is RUNNING
VM creation is still RUNNING
VM creation is still RUNNING
{"success":"True","details":{"uuid":"844615cb-4935-4c52-b625-8f51fc08f354","name":"testing-provisioning"}}
```

6) note the structured data in the result, that will be picked up by tasks and can be used in future plans
#!/opt/puppetlabs/puppet/bin/ruby
# Puppet Task Name: 
#
# This is where you put the shell code for your task.
#
# You can write Puppet tasks in any language you want and it's easy to 
# adapt an existing Python, PowerShell, Ruby, etc. script. Learn more at:
# http://puppet.com/docs/bolt/latest/converting_scripts_to_tasks.html 
# 
# Puppet tasks make it easy for you to enable others to use your script. Tasks 
# describe what it does, explains parameters and which are required or optional, 
# as well as validates parameter type. For examples, if parameter "instances" 
# must be an integer and the optional "datacenter" parameter must be one of 
# portland, sydney, belfast or singapore then the .json file 
# would include:
#   "parameters": {
#     "instances": {
#       "description": "Number of instances to create",
#       "type": "Integer"
#     }, 
#     "datacenter": {
#       "description": "Datacenter where instances will be created",
#       "type": "Enum[portland, sydney, belfast, singapore]"
#     }
#   }
# Learn more at: https://puppet.com/docs/bolt/latest/task_metadata.html
#

# since tasks can't share libraries yet, we need to copy this between each task

require 'yaml'
require 'json'
require 'net/https'

def load_config 
    server = ENV['PT_servername'] || 'default'
    configpath = ENV['PT_configpath'] || '/etc/nutanix.yaml'

    config = YAML.load_file(configpath)

    return config['servers'][server]
end

config = load_config

server = config['hostname']
port = config['port']

username = config['username']
password = config['password']

# end copy of common methods


# this is the hash we're constructing from the variables passed by the end user
# we could add some sane defaults here, don't know if API will merge fields not represented
new_vm = {
    "description" => ENV['PT_description'],
    "name" => ENV['PT_vm_name'],
    "memory_mb" =>  ENV['PT_memory_mb'],
    "num_cores_per_vcpu" => ENV['PT_num_cores_per_vcpu'],
    "num_vcpus" => ENV['PT_num_vcpus'],
    "vm_customization_config" => {
        "datasource_type" => "CONFIG_DRIVE_V2",
        "fresh_install" => true,
        "userdata" => ENV['PT_userdata'],
        "userdata_path" => ENV['PT_userdata_path']
    },
}

request = Net::HTTP::Post.new("https://#{server}:#{port}/PrismGateway/services/rest/v2.0/vms/", 'Content-Type' => 'application/json')
request.basic_auth username, password
request.body = new_vm.to_json

client = Net::HTTP.new(server, port)
client.use_ssl = true
client.verify_mode = OpenSSL::SSL::VERIFY_NONE

response = client.request(request)

if response.code == '200'
    puts 'request submitted'
    puts response.body
end

response_body = JSON[request.body]

task_uuid = response_body['task_uuid']

## do a while loop here to wait for the VM to be provisioned
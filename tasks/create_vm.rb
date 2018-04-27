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

# bash testing shortcuts
# export PT_vm_name=testing-$(date "+%Y-%m-%d-%S")
# export PT_memory_mb=1024
# export PT_subnet_uuid=9d271b40-38d4-4cf1-b4f0-e5ac16b853e7
# export PT_num_vcpus=1
# export PT_num_cores_per_vcpu=1

# should switch this to much smarter mapping / kv thing to deal with json passing instead of env

new_vm = {
    "api_version"=> "3.0",
    "metadata" => {
        "kind"=> "vm"
    },
    "spec" => {
        "name" => "#{ENV['PT_vm_name']}",
        "resources" => {
            "memory_size_mib" => ENV['PT_memory_mb'].to_i,
            "nic_list" => [
                {
                    "subnet_reference" => {
                        "kind" => "subnet",
                        "uuid" => "#{ENV['PT_subnet_uuid']}"
                    }
                }
            ],
            "num_sockets" => ENV['PT_num_vcpus'].to_i,
            "num_vcpus_per_socket" => ENV['PT_num_cores_per_vcpu'].to_i,
            "power_state" => "ON"
        }
    }
}

puts "Attempting to create #{ENV['PT_vm_name']}"

request = Net::HTTP::Post.new("https://#{server}:#{port}/api/nutanix/v3/vms", 'Content-Type' => 'application/json')
request.basic_auth username, password
request.body = new_vm.to_json

client = Net::HTTP.new(server, port)
client.use_ssl = true
client.verify_mode = OpenSSL::SSL::VERIFY_NONE

response = client.request(request)

#puts response.code
#puts response.body['status']

if response.code == '202'
    puts 'Request Accepted'
end

response_body = JSON[response.body]

task_uuid = response_body['status']['execution_context']['task_uuid']

task = Net::HTTP::Get.new("https://#{server}:#{port}/api/nutanix/v3/tasks/#{task_uuid}")
task.basic_auth username, password

task_response = client.request(task)

task_status = JSON[task_response.body]['status']

puts "VM creation is #{task_status}"

while task_status != 'SUCCEEDED'
    puts "VM creation is still #{task_status}"
    sleep(5)
    task_response = client.request(task)
    task_status = JSON[task_response.body]['status']
end

puts "#{ENV['PT_vm_name']} has been created!"
## do a while loop here to wait for the VM to be provisioned
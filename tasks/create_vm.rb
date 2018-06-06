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
# as well as validates parameter type. For examples, if parameter 'instances' 
# must be an integer and the optional 'datacenter' parameter must be one of 
# portland, sydney, belfast or singapore then the .json file 
# would include:
#   'parameters': {
#     'instances': {
#       'description': 'Number of instances to create',
#       'type': 'Integer'
#     }, 
#     'datacenter': {
#       'description': 'Datacenter where instances will be created',
#       'type': 'Enum[portland, sydney, belfast, singapore]'
#     }
#   }
# Learn more at: https://puppet.com/docs/bolt/latest/task_metadata.html
#

# since tasks can't share libraries yet, we need to copy this between each task

require 'yaml'
require 'json'
require 'net/https'

params = JSON.parse(STDIN.read)

def make_error(msg)
  error = {
    '_error' => {
      'kind' => 'execution error',
      'msg'  => msg,
      'details' => {}
    }
  }
  return error
end

def load_config(params)
  server = params['servername'] || 'default'
  configpath = params['configpath'] || '/etc/nutanix.yaml'
  
  config = YAML.load_file(configpath)

  return config['servers'][server]
end

config = load_config(params)

server = config['hostname']
port = config['port']

username = config['username']
password = config['password']

# our universal extra features loader

additional_params = params['additional_params'] || {}

# end copy of common methods

# bash testing shortcuts
# cat examples/test_vm.json | ./create_vm.rb

new_vm = {
  'api_version' => '3.1',
  'metadata' => {
    'kind'=> 'vm'
  },
  'spec' => {
    'name' => "#{params['vm_name']}",
    'resources' => {
      'memory_size_mib' => params['memory_mb'].to_i,
      'nic_list' => [
        {
        'subnet_reference' => {
          'kind' => 'subnet',
          'uuid' => "#{params['subnet_uuid']}"
          }
        }],
      'num_sockets' => params['num_vcpus'].to_i,
      'num_vcpus_per_socket' => params['num_cores_per_vcpu'].to_i,
      'power_state' => 'ON',
      'guest_customization'=> {
        'cloud_init' => {
          'user_data' => "#{params['userdata']}"
        }
      }
    }
  }
}

# here we want to merge whatever additional params were provided with the specific values
# more specific overrides generic

vm_payload = additional_params.merge(new_vm)

puts "Attempting to create #{params['vm_name']}"

request = Net::HTTP::Post.new("https://#{server}:#{port}/api/nutanix/v3/vms", 'Content-Type' => "application/json")
request.basic_auth username, password
request.body = vm_payload.to_json

client = Net::HTTP.new(server, port)
client.use_ssl = true
client.verify_mode = OpenSSL::SSL::VERIFY_NONE

response = client.request(request)

if response.code == '202'
  puts 'Request Accepted'
end

response_body = JSON[response.body]

vm_uuid = response_body['metadata']['uuid']
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

results = {
  'success' => 'True',
  'details' => {
    'uuid' => "#{vm_uuid}",
    'name' => "#{params['vm_name']}"
  }
}

puts results.to_json

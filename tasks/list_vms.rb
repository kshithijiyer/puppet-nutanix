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


#https://docs.ruby-lang.org/en/2.0.0/Net/HTTP.html

request = Net::HTTP::Get.new("https://#{server}:#{port}/PrismGateway/services/rest/v2.0/vms/")
request.basic_auth username, password

client = Net::HTTP.new(server, port)
client.use_ssl = true
client.verify_mode = OpenSSL::SSL::VERIFY_NONE

result = client.request(request)

puts result.inspect

puts result.body
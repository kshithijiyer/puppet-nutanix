#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

# Puppet Task Name: Delete VM
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
      'details' => {},
    },
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

# end copy of common methods

request = Net::HTTP::Delete.new("https://#{server}:#{port}/api/nutanix/v3/vms/#{params['uuid']}", 'Content-Type' => 'application/json')
request.basic_auth username, password

client = Net::HTTP.new(server, port)
client.use_ssl = true
client.verify_mode = OpenSSL::SSL::VERIFY_NONE

response = client.request(request)

results = {}

if response.code == '202'
  puts 'Request Accepted'
  results['result'] = 'success'
else
  results['_error'] = {
    'kind' => 'execution error',
    'msg'  => response.code,
    'details' => JSON.parse(response.body),
  }
end

puts results.to_json

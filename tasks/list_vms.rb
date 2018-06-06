#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true
#
# Puppet Task Name: Create VM
#
# This is where you put the shell code for your task.
#
# You can write Puppet tasks in any language you want and it's easy to 
# adapt an existing Python, PowerShell, Ruby, etc. script. Learn more at:
# http://puppet.com/docs/bolt/latest/converting_scripts_to_tasks.html 
# 
# Learn more at: https://puppet.com/docs/bolt/latest/task_metadata.html
#

# since tasks can't share libraries yet, we need to copy this between each task

require 'yaml'
require 'json'
require 'net/https'

params = JSON.parse(STDIN.read)

def make_error (msg)
  error = {
    '_error' => {
      'kind' => "nutanix-nutanix/error",
      'msg'  => msg,
      'details' => {}
    }
  }
  return error
end

def load_config (params)
  server = params['servername'] || 'default'
  configpath = params['configpath'] || "/etc/nutanix.yaml"
  
  config = YAML.load_file(configpath)

  return config['servers'][server]
end

config = load_config(params)

server = config['hostname']
port = config['port']

username = config['username']
password = config['password']

# end copy of common methods

default_payload = { 'kind' => 'vm', 'length' => 5}

payload = default_payload.merge(params)

payload.delete('servername')
payload.delete('configpath')

puts payload.to_json

#https://docs.ruby-lang.org/en/2.0.0/Net/HTTP.html

request = Net::HTTP::Post.new("https://#{server}:#{port}/api/nutanix/v3/vms/list", 'Content-Type' => "application/json")
request.basic_auth username, password
request.body = payload.to_json

client = Net::HTTP.new(server, port)
client.use_ssl = true
client.verify_mode = OpenSSL::SSL::VERIFY_NONE

response = client.request(request)

result = {}

result['response'] = response.code
result['result'] = JSON.parse(response.body)

puts result.to_json

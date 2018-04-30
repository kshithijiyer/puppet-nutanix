
# Nutanix

Welcome to the Nutanix Puppet module




#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with nutanix](#setup)
    * [What nutanix affects](#what-nutanix-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with nutanix](#beginning-with-nutanix)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

This is currently a Task centric module for Nutanix. It allows for creation of VMs in an existing nutanix infrastructure.

This module will expand over time to include full Puppet Types/Providers, however this is a 0.1.X release so there is a lot of changes to come. This requires a Nutanix build of 5.5 or later, since was built using the V3 API calls.

## Setup

### Setup Requirements

This module assumes you've configured a provisioning account for your Nutanix system and have a VM with the credentials on it that can contact the Nutanix systems. For a small installation or just testing this could be the system running the tasks from (such as a Puppet Enterprise Master).

Create a file called /etc/nutanix.yaml with the following format:

```yaml
---
servers:
  default:
    hostname: 'hostname'
    port: 'port'
    username: 'username'
    password: 'password'
```

One can specify multiple Nutanix installations in a single file, but default is assumed and will be used if no other one is specified in a task.

### Beginning with nutanix

Once the /etc/nutanix.yaml has been created, you can verify the connectivity between the task running host and the Nutanix system by running the list_vms.rb task. It loads the nutanix.yaml file and interacts with the Nutanix API just as the other tasks do.

## Usage

For creating a VM in the nutanix system, there are two ways to run this task: as a command line / bolt task, or via Puppet Enterprise console. In either case, one will need to be familiar with the Nutanix platform to perform these commands.

## Reference

Users need a complete list of your module's classes, types, defined types providers, facts, and functions, along with the parameters for each. You can provide this list either via Puppet Strings code comments or as a complete list in the README Reference section.

* If you are using Puppet Strings code comments, this Reference section should include Strings information so that your users know how to access your documentation.

* If you are not using Puppet Strings, include a list of all of your classes, defined types, and so on, along with their parameters. Each element in this listing should include:

  * The data type, if applicable.
  * A description of what the element does.
  * Valid values, if the data type doesn't make it obvious.
  * Default value, if any.

## Limitations

This task has only been tested on POSIX platforms, and relies on the Ruby build that ships with the Puppet Agent being present. Easiest way to do that is to run this task from a machine managed by Puppet.

## Development

Since your module is awesome, other users will want to play with it. Let them know what the ground rules for contributing are.

## Release Notes/Contributors/Etc. **Optional**

If you aren't using changelog, put your release notes here (though you should consider using changelog). You can also add any additional sections you feel are necessary or important to include here. Please use the `## ` header.

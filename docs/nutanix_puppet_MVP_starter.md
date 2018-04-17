##Day 1 Pointers
Prism Central is the primary API endpoint that we’ll be developing against. 

We use swagger-ui as our live API Explorer, which you can access from the “Admin” menu in the upper right hand corner of our UI, and clicking API Explorer. 

I’d suggest starting there and seeing what different calls and methods we have exposed. That also serves as our live documentation; however, we have even more documentation available on our Developer Portal, specifically here: http://developer.nutanix.com/reference/prism_central/v3/

## Scope of Work Notes
* Create Puppet module provider
    * This would include all CRUD functions below. 
    * We’d also like to understand the “path” to add more CRUD operations as we expand the scope of our API. This means repeatable processes where possible
* CRUD for vms
    * VMs are exactly what they sound like, these are virtual machines that run on a virtualization platform, very similar to instances in AWS or virtual machines in VMware vSphere.
    * VMs consist of some of amount of “compute” resources, like vCPUs and memory, as well as some storage and network resources.
    * VMs can have both CDROMs and vDisks, which are just virtual hard drives (like VMDKs in VMW). Unlike AWS, these vDisks are NOT ephemeral by default.
    * VMs can have one or more virtual networks, which tie in with “subnets” (defined below). For “managed network” subnets, a virtual NIC can have an IP address “automatically” assigned or “manually” assigned. In the manual case, you’d actually provide an IP address that goes within the “managed” network.
    * VMs can have all sorts of different, optional properties depending on the use case, such as affinity rules, virtual GPUs, UEFI boot.
    * VM’s can also be assigned to “categories” (see the network_security_rules section for category notes)
    * A single VM will live in a single Nutanix cluster. VM’s can be provisioned to any cluster within Prism Central. In the API, you’ll see something to the effect of “cluster” keyword within the /vms/ API spec, this is where you need to tell it where to go
    * There is also a concept of “projects”, which is tied to something we have called the Self Service portal. You’ll see that in the “metadata” object of a vms in the API spec. I should be able to “place” a VM within a project if I know the name of the project.
* CRUD for images
    * Images encompass disks (like VMDK, VHD, QCOW2, etc) as well as ISOs, and are roughly similar to AMI’s within AWS
    * Images get created within Prism Central as a general “catalog” of images, much like an “iTunes Store” for server images, and roughly similar to the AWS marketplace for common AMI’s
    * Once an image is created in Prism Central, virtual machines can use these as a boot device (like using an AMI where its bootable and ready to go) or they can be used as CD ROM devices (like attaching a SQL Server ISO, to install an application separately)
    * Prism Central becomes the catalog for images in the version you’re working on, and handles moving the images in between clusters when request.
    * Images can come from an HTTP server, like an internet destination or internal HTTP enabled filer OR they can be uploaded from a local file via the API. We’ll want both methods working if possible.
* CRUD for network_security_rules
    * network_security_rules are the construct for “micro-segmentation” within Prism Central, and these become “Security Policies” in the UI
    * network_security_rules have a variety of permutations, but generally involve some inbound traffic going to one or more virtual machines or applications, as well as potential “outbound” traffic leaving those VM’s or apps going to other destinations.
    * If you’ve ever worked with a firewall, these constructs will be pretty similar.
    * The “tie in” between network_security_rules is CATEGORIES, so you may need to implement CRUD for categories as a sub construct of this particular task. Categories are a “label” that can be applied to an “entity” (like a VM). 
    * For example, if I made a network security rule that allowed 10.20.30.40/24 to access port 443 on the “exchange” application, it wouldn’t do anything until I add a category to the RULE and then add that category to the APP/VM.
    * I wouldn’t be surprised if these are the most difficult CRUD function to implement, given their overall function complexity, but I’m really looking forward to see what you can do :)
* CRUD for subnets
    * subnets are the API name for “VLANs” / virtual networks, and are roughly analogous to a virtual port group within VMware.
    * subnets are usually just given a logical name, like “production VLAN 93” as well as a layer 2 802.1q VLAN ID, like “93” in this example
    * subnets can also be “managed networks”, where we act as the DHCP server, and take a variety of typical inputs, like Layer 3 network ID (10.42.77.0/24), as well as a DHCP pool, DNS server, DNS network name, and so on.
    * subnets are the “attachment point” for virtual NICs, which are the virtual network adapters within a virtual machine. This means that the subnet typically need to be created BEFORE a VM’s vNIC(s) are created, otherwise, they have nowhere to attach to.
* CRUD for volume_groups
    * volume_groups are a way to abstract virtual disks from the virtual (or physical) machine accessing them. This is similar in concept to AWS EBC volumes, where they can be attached to a virtual machine instance; however, they are their own first class citizen. 
    * volume_groups can be accessed by multiple VM’s, for file system clustering purposes. This workflow is rare, but when needed, very popular.
    * volume_groups are usually accessed by a single VM; however, they can also be presented via iSCSI to a physical/bare metal machine OR be presented to a virtual machine as an “in-guest iSCSI disk”. These are rare, but still needed on occasion. This is similar to presenting a NetApp vol from an aggregate to a machine via iSCSI (and other similar storage technologies
    * volume_groups also support iSCSI CHAP for authentication, when being accessed physical/bare metal (or via in-guest iSCSI).
* Testing of all 5 entities before publishing
    * This is just the starter, let’s move this to a markdown document in GitHub, so we can track changes as code, and even drive events from code possibly
    * TEST PLAN 
        * We should have unit tests as code where possible. I’m not sure how this works with puppet, but we’re up for recommendations.
        * We’ll also want recommendations on what other clients and providers are doing for “continuous integration” testing. As you can imagine, we have a massive QA infrastructure internally to do our internal product testing, so we can share what we’re doing there
        * It may make sense to have you guys talk to our India based QA resources, to sync up on QA strategy, and perhaps we can simply plug in to our QA automation infrastructure, such that this is very extensible.
    * TESTING NOTE
        * All testing should be performed against Prism Central; however, I’d like to have ONE basic workflow tested against Prism Element, which is the name for directly connecting to a cluster.
    * Vms
        * Simple create: Create virtual machine (2 vCPU, 4GB mem), create new vDisk (50G), attach to existing network, power on
        * Advanced create: create multiple “simple” VMs at the same time (handling a “bulk” operation if possible), attach one VM to multiple virtual networks, create VM’s with multiple vDisks.
        * “Reporting” (read): Output inventory of virtual machines (i.e GET /vms/ on existing system after they are created)
        * “Update”: Take an existing virtual machine and increase vCPU, increase memory, add more vDisks, attach another vNIC
        * “Update”: Add a volume group to a VM, remove volume group from the VM
        * “Update”: Add a category to a VM
        * “Update: Add VM to a project
        * “Cleanup” (delete): Delete VM’s that were created and take the environment “back to zero”
    * Image
        * Create: Create images from HTTP filer sources, on Nutanix engineering network
        * Create: create images from “local” file upload - you can use a very small disk, like cirrus, or a very small ISO (like VirtIO) to upload this so bandwidth is easy
        * Read: Output listing of available images, with available attributes (i.e what images are loaded, checksums, details)
        * Update: Update attributes (like description) on an existing image
        * Cleanup (delete): Delete all images that were created and take environment to zero
    * Network Security Rule
        * Simple create: Create a network security rule that has one input, one application, and one outbound rule
        * Advanced create: Create a network security rule that has multiple inputs, including IP addresses, categories, and has multiple applications with both WITHIN rules (i.e security rules between application tiers) and in/out rules (i.e rules coming in and out of the app as a whole), as well as multiple outbound rules
        * Read: Output listing of security rules and their configurations
        * Update: Extend the simple security rule to add more inputs, more outputs, and more applications
        * Update: Add new categories to the security rule
        * Cleanup (delete): Delete all security rules to take the environment to zero
    * Subnet
        * Simple create: Create a subnet for VLAN 212 called “OSL-212-simple”, as an unmanaged network
        * Advanced create” create a managed subnet for VLAN 80 called “OSL-80-advanced”
            * IP space 10.5.80.0/255.255.240.0
            * DHCP Pool: (TBD)
            * DNS network name: test.nutanix.com
            * DNS: 4.2.2.1
        * Read: Output listing of subnets and their configurations
        * Update: Add another DHCP pool to OSL-80 advanced network, change DNS name to update.nutanix.com
        * Cleanup: Delete all security rules to take environment to zero
    * Volume Groups
        * Simple create: create a volume group with one disk
        * Advanced create: create a volume group with many disks, with external access enabled and CHAP enabled
        * Read: Output listing of volume groups and their configurations
        * Update: Add disks to an existing volume group
        * Update: Attach one VM to a volume group
        * Update: Attach multiple VMs to a volume group
        * Cleanup: Delete all volume groups to take environment to zero
    * Prism Element BASIC Use case
        * Create unmanaged subnet called OSL-212-PE
        * Create /vms/ with one vDisk and one vNIC attached to OSL-212-PE network
        * Update vm to have more vCPU/vMem/vDisk/vNIC
        * Delete vm
* Documentation for each of the 5 entities
    * We should do this in markdown, such that we can nest it within developer.nutanix.com. 
    * We can have you sync up with our India based tech writer, who is handling all things developer.nutanix.com; who can provider framework/syntax/support on what we’ll need to do
    * We should likely make this a new section within developer.nutanix.com, and not cross pollinate with the v3 API documentation, since you may have TF calls that tie together multiple API calls within a single method, etc. I don’t want to restrict you in that way.
    * Either way, let’s plan this out for now, and we can always tweak and tune. 
    * We can always start with markdown in the GitHub repo, and port it over to the developer portal when the time makes sense.
* Publish to Puppet forge
    * This is the final milestone, but we’ll want to understand the process on how to publish updates (for bug fixes, enhancements, etc)

Assumptions for Scoping
* Nutanix to provide development env
* Nutanix will provide access to tools used to perform the required activities.
* Nutanix will provide access to repositories to store the code
* Changes (Pull Requests) will be approved by one of the members of your team and one of Nutanix
    * We need to talk about the process for this, I don’t want process to get in the way of progress 😃 but let’s make sure we keep a good cadence when code is landing
* Nutanix team will be available for a review meeting every week
* The Plugin will be built against the latest release of Puppet
    * This is a given, we do not want to support anything older than what is CURRENT today, so we can avoid any tech debt. 
    * Of course, we’ll want to make sure that we keep an eye on both backward and forwards compatibility
* SLA for the review: we will act before 24hrs i.e. next business day after any review is published
    * I’d create a shared slack channel, where we’ll use to collaborate on all of this real time. We use this to run our entire business, so we can pull in literally everyone from the front desk receptionist to the CEO if/when/where needed. Ideally, this would be things like advanced API support, or any sort of oddities we might run into.
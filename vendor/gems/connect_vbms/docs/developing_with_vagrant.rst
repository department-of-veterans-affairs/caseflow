Getting started with Vagrant
============================

    Vagrant provides easy to configure, reproducible, and portable work
    environments built on top of industry-standard technology and
    controlled by a single consistent workflow to help maximize the
    productivity and flexibility of you and your team.

Read more from `“Why Vagrant?”`_

Installing dependencies
-----------------------

1. Install the newest version of Vagrant for your operating system.

-  http://www.vagrantup.com/downloads.html

2. You have two options for VM providers:

-  `VirtualBox`_ or `VMWare Fusion`_

Using Vagrant
-------------

1. Copy the provided example Vagrantfile and Vagrant up!
   ::
    $ cp Vagrantfile.example Vagrantfile
    $ vagrant up

2. Check the status of a VM:
   ::
    $ vagrant status # from your computer
    Current machine states:

    default saved (virtualbox)

To resume this VM, simply run ``vagrant up``.

3. To start a VM (requires a Vagrantfile in the current path). This step
   may take a long time on first execution in order to download your VM
   image and provision. Tip: use ``--provision`` to have the provisioning 
   script executed at start-up (machine must be powered off with 
   ``vagrant halt``).
   ::
     $ vagrant up # from your computer
     Bringing machine 'default' up with 'virtualbox' provider...
     ...
     ==> default: Machine booted and ready!
     

4. How to run specs
   ::
     $ vagrant ssh # from your computer
     Welcome to Ubuntu 12.04.5 LTS (GNU/Linux 3.2.0-88-virtual x86_64)
     ...
     vagrant@connect-vbms-dev-box:~$ cd /vagrant/connect_vbms   
     vagrant@connect-vbms-dev-box:/vagrant/connect_vbms$ bundle exec rspec

5. When you’re done (and would like to free up some RAM), suspend the VM
   for quick boot later.
   ::
     $ vagrant suspend # from your computer   
     ==> default: Saving VM state and suspending execution...

More information
----------------

Glossary: - provision: the process of preparing a newly booted VM for
use. - This is usually in the form of a shell script (bootstrap.sh)
which is executed one time when the image is first downloaded and
booted.

Reading: - `Vagrant Docs`_

.. _“Why Vagrant?”: https://docs.vagrantup.com/v2/why-vagrant/index.html
.. _VirtualBox: https://www.virtualbox.org/wiki/Downloads
.. _VMWare Fusion: https://www.vmware.com/go/downloadfusion
.. _Vagrant Docs: https://docs.vagrantup.com/v2/

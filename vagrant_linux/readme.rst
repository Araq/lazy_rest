===========================
Vagrant VirtualBox machines
===========================

This directory contains specifications for `Vagrant VirtualBox machines
<https://www.vagrantup.com>`_. They are used both for testing and generation of
binaries for Linux.

To start up a machine go into the directory and type::

    $ vagrant up

If something fails during provisioning (the setup phase), tweak
``bootstrap.sh`` (maybe some repository URLs changed?) and run::

    $ vagrant reload --provision

Once the machine is up, you can ssh into it with::

    $ vagrant ssh

Stopping and destroying the virtual box instances is done with the following
commands::

    $ vagrant halt
    $ vagrant destroy

Halting is good to stop consuming resources on your host. Destroying is good if
you don't plan to use the virtual machine for some time, which frees disk
space.

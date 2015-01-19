===========================
Vagrant VirtualBox machines
===========================

This is a developer directory to `Vagrant VirtualBox machines
<https://www.vagrantup.com>`_. They are used both for testing and generation of
binaries for Linux. Since it is *expensive* to have a full virtual machine for
each program they are kept elsewhere and this directory only has symbolic links
to them.

To start up a machine go into the directory and type::

    $ vagrant up

This requires a ``bootstrap.sh`` file to be present. Since all Linux variants
use the same ``bootstrap.sh``, copy it form the parent directory.  If something
fails during provisioning (the setup phase), tweak ``bootstrap.sh`` (maybe some
repository URLs changed?) and run::

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

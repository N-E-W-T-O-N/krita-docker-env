# CI Images

This repository includes the container images used by KDE CI.

These are not expected to be used by developers directly; they are used to create
[Gitlab Templates](https://invent.kde.org/sysadmin/ci-utilities/-/tree/master/gitlab-templates),
which lets developers create pipelines for building, testing and deploying
their apps and websites with a simple include file. If you need to add new
shared dependencies in the default templates, this is the right repository.

To learn more about how KDE uses Gitlab CI, see the wiki page
[Continuous Integration System](https://community.kde.org/Infrastructure/Continuous_Integration_System).

## Running images locally

There are two kinds of image hosted in this repository: Docker images and VM images.

The Docker images are completely conventional and can be used with any ordinary Docker installation.
The GitLab Runner instructions should be followed for setting up a runner.

The VM images, while being standard QEMU qcow2 disk images, cannot just be imported and run.

This is because:
- For Linux and FreeBSD, they expect to receive configuration via cloud-init which must be provisioned
- For Windows, specific setup using the QEMU guest agent must be completed to setup credentials to allow access

In addition the images are optimised for use with a specific QEMU/KVM configuration to maximise performance (virtio drivers, etc).

This repository contains a utility - vm-runner - specifically written to setup and teardown these VMs.

```
usage: vm-runner [-h] {images,pull,remove-image,cleanup-images,ps,run,vm-ips,start,stop,remove} ...

Helper to assist with retrieving and managing VM images for quick provisioning

positional arguments:
  {images,pull,remove-image,cleanup-images,ps,run,vm-ips,start,stop,remove}
    images              List images known to the system
    pull                Pull a new image in from the remote server
    remove-image        Remove a specified image ID from the local system
    cleanup-images      Cleanup old, stale images stored locally
    ps                  List VMs currently available on the system
    run                 Start a new VM
    vm-ips              Print the IP addresses of the VM out (JSON format)
    start               Start a currently stopped VM
    stop                Stop a currently running VM
    remove              Stop and remove a VM

options:
  -h, --help            show this help message and exit
```

vm-runner can be used to quickly spin up and tear down VM images as needed.

```
vm-runner run --cpu 2 --ram 4G --disk 50G --image storage.kde.org/vm-images/suse-qt69 --mount ~/temp/ --ssh-keys ~/.ssh/id_rsa.pub myfirstvm

developer@host:~> vm-runner run --cpu 2 --ram 4G --disk 50G --image storage.kde.org/vm-images/suse-qt69 --mount ~/temp/ --ssh-keys ~/.ssh/id_rsa.pub myfirstvm
Machine provisioned successfully
Name:      myfirstvm
IP:        192.168.122.54

developer@host:~> ssh user@192.168.122.54
Warning: Permanently added '192.168.122.54' (ED25519) to the list of known hosts.
Have a lot of fun...
user@myfirstvm:~>
```

Images can be fetched from any S3-compliant bucket that is publicly accessible, such as storage.kde.org/vm-images (which is where this repository publishes to)

## Setting up vm-runner locally

To set it up, you first need to install libvirt and qemu-kvm in line with your distribution instructions.
For Debian and it's derivates this means:
```
# libvirt, qemu-kvm
apt install libvirt-daemon-system qemu-kvm qemu-efi-arm qemu-efi-aarch64 ipxe-qemu ovmf swtpm swtpm-tools qemu-utils dnsmasq
# dependencies of vm-runner
apt install python3-libvirt python3-yaml python3-lxml python3-venv python3-pip jq xorriso
# for gitlab-runner setups you will want Git as well
apt install git
```

For RedHat and it's derivates this means:
```
# libvirt, qemu-kvm
dnf install libvirt libvirt-daemon-kvm qemu-kvm
# dependencies of vm-runner
dnf install python3-yaml python3-lxml python3-pip jq xorriso dnsmasq
# for gitlab-runner setups you will want Git as well
dnf install git
```

For Debian (and derivate) systems after the above you will have a dnsmasq instance running locally, it is recommended to disable this:
```
systemctl disable dnsmasq.service
systemctl stop dnsmasq.service
```

Once that is setup you will want to ensure you have local storage and a local network setup within libvirt.
It is recommended that you ensure both are enabled to start on boot.
This is best done with virt-manager (needs installing seperately)

With that completed, install the Python dependencies of vm-runner:
```
pip3 install -r ~/path/to/ci-images/vm-runner/requirements.txt
```

If your distribution does not allow installation of Python packages in ~/.local/ then you can setup a virtualenv.
Note that unless you want to compile the libvirt Python bindings yourself, you need to allow system site packages to be used by the virtualenv:
```
python3 -m venv --system-site-packages ~/myvenv/
source ~/myvenv/bin/activate
```

With that completed you are now ready to make use of vm-runner!

## Connecting this to GitLab

Once you have vm-runner operating locally, it is relatively simple to extend this to running CI jobs on GitLab as well.
This is done by utilising the [custom executor](https://docs.gitlab.com/runner/executors/custom/) functionality in GitLab Runner.

To do so first install gitlab-runner following the GitLab instructions to do so, then create a runner on your GitLab installation.
When registering it on your runner machine, make sure you select custom as the executor.

Once the configuration is complete edit your configuration to be something like this:
```
[[runners]]
  name = "your node name here"
  output_limit = 40960
  url = "https://yourgitlab.example.org"
  id = [your runner id here]
  token = "your token here"
  executor = "custom"
  [runners.feature_flags]
    FF_USE_POWERSHELL_PATH_RESOLVER = true
  [runners.custom]
    config_exec = "/opt/ci-images/vm-runner/gitlab-runner/ssh-executor"
    config_args = ["config"]
    prepare_exec = "/opt/ci-images/vm-runner/gitlab-runner/ssh-executor"
    prepare_args = ["prepare", "CPU=12", "RAM=16G", "DISK=50G"]
    run_exec = "/opt/ci-images/vm-runner/gitlab-runner/ssh-executor"
    run_args = ["run"]
    cleanup_exec = "/opt/ci-images/vm-runner/gitlab-runner/ssh-executor"
    cleanup_args = ["cleanup"]
```

The FF_USE_POWERSHELL_PATH_RESOLVER feature flag is crucial if you intend to run Windows VMs - without this they will fail to run jobs.

The arguments CPU=12, RAM=16G and DISK=50G will alter the corresponding specifications of the VM that is created using vm-runner and can be customised as needed.
If you do not specify them then ssh-executor will default to 8 cores, 16GB RAM and 200GB disk.

By default the path /mnt/shared/ of the host will be mounted into all launched VMs at /mnt (or Z:\ for Windows VMs).
If you wish to change the host path then you will need to edit ssh-executor.

If you need to offer different specification VMs (more or less cores, RAM, etc) then simply register another runner with GitLab and change the prepare_args accordingly.

It is recommended to make use of the limit setting (at the individual runner section level) as well as the concurrent flag (at the global level) to ensure you do not over-commit resources.
This is likely to result in an OOM situation.

```
concurrent = 4
check_interval = 10
connection_max_age = "15m0s"

....

[[runners]]
  name = "node1-vmrunner"
  output_limit = 40960
  url = "https://invent.kde.org"
...

[[runners]]
  name = "node1-vmrunner-large"
  limit = 1
  output_limit = 40960
  url = "https://invent.kde.org"
...
```

## Ansible setup

The above setup of both vm-runner and gitlab-runner has been automated within the Ansible role `gitlab-ci-vm-runner`
This role is not published on Ansible Galaxy but can be found in the [KDE Ansible repository](https://invent.kde.org/sysadmin/ansible)

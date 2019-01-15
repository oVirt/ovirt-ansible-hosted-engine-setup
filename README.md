# ovirt-ansible-hosted-engine-setup

Ansible role for deploying oVirt Hosted-Engine

# Requirements

 * Ansible version 2.7 or higher
 * Python SDK version 4.2 or higher
 * Python netaddr library on the ansible controller node

# Dependencies

No.

# Prerequisites

* A fully qualified domain name prepared for your Engine and the host. Forward and reverse lookup records must both be set in the DNS.
* `/var/tmp` has at least 5 GB of free space.
* Unless you are using Gluster, you must have prepared storage for your Hosted-Engine environment (choose one):
    * [Prepare NFS Storage](https://ovirt.org/documentation/admin-guide/chap-Storage/#preparing-nfs-storage)
    * [Prepare ISCSI Storage](https://ovirt.org/documentation/admin-guide/chap-Storage/#preparing-iscsi-storage)
* Install additional oVirt ansible roles:

    ```bash
    $ ansible-galaxy install ovirt.repositories # case-sensitive
    ```

    ```bash
    $ ansible-galaxy install ovirt.engine-setup # case-sensitive
    ```
# Role variables

## General Variables

| Name                            | Default value         |  Description                                              |
|---------------------------------|-----------------------|-----------------------------------------------------------|
| he_bridge_if | eth0 | The network interface ovirt management bridge will be configured on |
| he_fqdn | null | The engine FQDN as it configured on the DNS |
| he_mem_size_MB | max | The amount of memory used on the engine VM |
| he_vcpus | max | The amount of CPUs used on the engine VM |
| he_disk_size_GB | 61 | Disk size of the engine VM |
| he_vm_mac_addr | null | MAC address of the engine vm network interface. |
| he_domain_type | null | Storage domain type. available options: *nfs*, *iscsi*, *gluster*, *fc* |
| he_storage_domain_addr | null | Storage domain IP/DNS address |
| he_ansible_host_name | localhost | hostname in use on the first HE host (not necessarily the Ansible controller one) |
| he_restore_from_file | null | a backup file created with engine-backup to be restored on the fly |
| he_cluster | Default | name of the cluster with hosted-engine hosts |
| he_data_center | Default | name of the datacenter with hosted-engine hosts |
| he_host_name | $(hostname -f) | name used by the engine for the first host |
| he_host_address | $(hostname -f) | address used by the engine for the first host |

## NFS / Gluster Variables

| Name                            | Default value         |  Description                                              |
|---------------------------------|-----------------------|-----------------------------------------------------------|
| he_mount_options | '' | NFS mount options
| he_storage_domain_path | null | shared folder path on NFS server |
| he_nfs_version | auto | NFS version.  available options: *auto*, *v4*, *v3*


## ISCSI Variables

| Name                            | Default value         |  Description                                              |
|---------------------------------|-----------------------|-----------------------------------------------------------|
| he_iscsi_username | null | iscsi username |
| he_iscsi_password | null | iscsi password |
| he_iscsi_target | null | iscsi target |
| he_lun_id | null | Lun ID |
| he_iscsi_portal_port | null | iscsi portal port |
| he_iscsi_portal_addr | null | iscsi portal address |
| he_iscsi_tpgt | null | iscsi tpgt |
| he_discard | false |  Discard the whole disk space when removed. more info [here](https://ovirt.org/develop/release-management/features/storage/discard-after-delete/)

## Static IP configuration Variables

DHCP configuration is used on the engine VM by default. However, if you would like to use static ip instead,
define the following variables:

| Name                            | Default value         |  Description                                              |
|---------------------------------|-----------------------|-----------------------------------------------------------|
| he_vm_ip_addr | null | engine VM ip address |
| he_vm_ip_prefix | null | engine VM ip prefix |
| he_dns_addr | null | engine VM DNS server |
| he_default_gateway | null | engine VM default gateway |
| he_vm_etc_hosts | false | Add engine VM ip and fqdn to /etc/hosts on the host |

# Example Playbook
This is a simple example for deploying Hosted-Engine with NFS storage domain.

This role can be used to deploy on localhost (the ansible controller one) or on a remote host (please correctly set he_ansible_host_name).
All the playbooks can be found inside the `examples/` folder.

## hosted_engine_deploy_localhost.yml

```yml
---
- name: Install packages and bootstrap local engine VM
  hosts: localhost
  connection: local
  vars_files:
    - passwords.yml
  vars:
    he_install_packages: true
    he_pre_checks: true
    he_initial_clean: true
    he_bootstrap_local_vm: true
    ovirt_repositories_ovirt_release_rpm: "{{ ovirt_repo_release_rpm }}"
  roles:
    - role: ovirt.repositories
    - role: ovirt.hosted_engine_setup

- name: Local engine VM installation - Pre tasks
  hosts: engine
  vars_files:
    - passwords.yml
  vars:
    he_bootstrap_pre_install_local_engine_vm: true
  roles:
    - role: ovirt.hosted_engine_setup

- name: Engine Setup on local VM
  hosts: engine
  vars_files:
    - passwords.yml
  vars:
    ovirt_engine_setup_hostname: "{{ he_fqdn.split('.')[0] }}"
    ovirt_engine_setup_organization: "{{ he_cloud_init_domain_name }}"
    ovirt_engine_setup_dwh_db_host: "{{ he_fqdn.split('.')[0] }}"
    ovirt_engine_setup_firewall_manager: null
    ovirt_engine_setup_answer_file_path: /root/ovirt-engine-answers
    ovirt_engine_setup_use_remote_answer_file: True
    ovirt_engine_setup_accept_defaults: True
    ovirt_engine_setup_update_all_packages: false
    ovirt_engine_setup_offline: true
    ovirt_engine_setup_admin_password: "{{ he_admin_password }}"
  roles:
    - role: ovirt.engine-setup

- name: Local engine VM installation - Post tasks
  hosts: engine
  vars_files:
    - passwords.yml
  vars:
    he_bootstrap_post_install_local_engine_vm: true
  roles:
    - role: ovirt.hosted_engine_setup

- name: Configure engine VM on a storage domain
  hosts: localhost
  connection: local
  vars_files:
    - passwords.yml
  vars:
    he_bootstrap_local_vm_add_host: true
    he_create_storage_domain: true
    he_create_target_vm: true
  roles:
    - role: ovirt.hosted_engine_setup

- name: Configure database settings
  hosts: engine
  vars_files:
    - passwords.yml
  vars:
    he_engine_vm_configuration: true
  roles:
    - role: ovirt.hosted_engine_setup

- name: Closeup
  hosts: localhost
  connection: local
  vars_files:
    - passwords.yml
  vars:
    he_final_tasks: true
    he_final_clean: true
  roles:
    - role: ovirt.hosted_engine_setup
```

## hosted_engine_deploy_remotehost.yml

```yml
---
- name: Install packages and bootstrap local engine VM
  hosts: host123.localdomain
  vars_files:
    - passwords.yml
  vars:
    he_install_packages: true
    he_pre_checks: true
    he_initial_clean: true
    he_bootstrap_local_vm: true
    ovirt_repositories_ovirt_release_rpm: "{{ ovirt_repo_release_rpm }}"
  roles:
    - role: ovirt.repositories
    - role: ovirt.hosted_engine_setup

- name: Local engine VM installation - Pre tasks
  hosts: engine
  vars_files:
    - passwords.yml
  vars:
    he_bootstrap_pre_install_local_engine_vm: true
  roles:
    - role: ovirt.hosted_engine_setup

- name: Engine Setup on local VM
  hosts: engine
  vars_files:
    - passwords.yml
  vars:
    ovirt_engine_setup_hostname: "{{ he_fqdn.split('.')[0] }}"
    ovirt_engine_setup_organization: "{{ he_cloud_init_domain_name }}"
    ovirt_engine_setup_dwh_db_host: "{{ he_fqdn.split('.')[0] }}"
    ovirt_engine_setup_firewall_manager: null
    ovirt_engine_setup_answer_file_path: /root/ovirt-engine-answers
    ovirt_engine_setup_use_remote_answer_file: True
    ovirt_engine_setup_accept_defaults: True
    ovirt_engine_setup_update_all_packages: false
    ovirt_engine_setup_offline: true
    ovirt_engine_setup_admin_password: "{{ he_admin_password }}"
  roles:
    - role: oVirt.engine-setup

- name: Local engine VM installation - Post tasks
  hosts: engine
  vars_files:
    - passwords.yml
  vars:
    he_bootstrap_post_install_local_engine_vm: true
  roles:
    - role: ovirt.hosted_engine_setup

- name: Configure engine VM on a storage domain
  hosts: host123.localdomain
  vars_files:
    - passwords.yml
  vars:
    he_bootstrap_local_vm_add_host: true
    he_create_storage_domain: true
    he_create_target_vm: true
  roles:
    - role: ovirt.hosted_engine_setup

- name: Configure database settings
  hosts: engine
  vars_files:
    - passwords.yml
  vars:
    he_engine_vm_configuration: true
  roles:
    - role: ovirt.hosted_engine_setup

- name: Closeup
  hosts: host123.localdomain
  vars_files:
    - passwords.yml
  vars:
    he_final_tasks: true
    he_final_clean: true
  roles:
    - role: ovirt.hosted_engine_setup
```


### __Note__:
Unlike standard roles that are called once in a playbook, we call this role 5 times. The reason for that is due to the fact that Ansible allows executing a role only for one host. Thus, because we need to execute tasks on both `host` and `engine` hosts we had to call the role more than one time.

## passwords.yml

```yml
---
# As an example this file is keep in plaintext, if you want to
# encrypt this file, please execute following command:
#
# $ ansible-vault encrypt passwords.yml
#
# It will ask you for a password, which you must then pass to
# ansible interactively when executing the playbook.
#
# $ ansible-playbook myplaybook.yml --ask-vault-pass
#
he_appliance_password: 123456
he_admin_password: 123456
```

## Example 1: extra vars for NFS deployment with DHCP - he_deployment.json

```json
{
    "he_bridge_if": "eth0",
    "he_fqdn": "he-engine.example.com",
    "he_vm_mac_addr": "00:a5:3f:66:ba:12",
    "he_domain_type": "nfs",
    "he_storage_domain_addr": "192.168.100.50",
    "he_storage_domain_path": "/var/nfs_folder",
    "ovirt_repo_release_rpm": "http://plain.resources.ovirt.org/pub/yum-repo/ovirt-release42.rpm"
}
```

## Example 2: extra vars for iSCSI deployment with static IP, remote host - he_deployment_remote.json

```json
{
    "he_bridge_if": "eth0",
    "he_fqdn": "he-engine.example.com",
    "he_vm_ip_addr": "192.168.1.214",
    "he_vm_ip_prefix": "24",
    "he_gateway": "192.168.1.1",
    "he_dns_addr": "192.168.1.1",
    "he_vm_etc_hosts": true,
    "he_vm_mac_addr": "00:a5:3f:66:ba:12",
    "he_domain_type": "iscsi",
    "he_storage_domain_addr": "192.168.1.125",
    "he_iscsi_portal_port": "3260",
    "he_iscsi_tpgt": "1",
    "he_iscsi_target": "iqn.2017-10.com.redhat.stirabos:he",
    "he_lun_id": "36589cfc000000e8a909165bdfb47b3d9",
    "he_mem_size_MB": "4096",
    "he_ansible_host_name": "host123.localdomain"
}
```

### Test iSCSI connectivity and get LUN WWID before deploying

```
[root@c75he20180820h1 ~]# iscsiadm -m node --targetname iqn.2017-10.com.redhat.stirabos:he -p 192.168.1.125:3260 -l
[root@c75he20180820h1 ~]# iscsiadm -m session -P3
iSCSI Transport Class version 2.0-870
version 6.2.0.874-7
Target: iqn.2017-10.com.redhat.stirabos:data (non-flash)
	Current Portal: 192.168.1.125:3260,1
	Persistent Portal: 192.168.1.125:3260,1
		**********
		Interface:
		**********
		Iface Name: default
		Iface Transport: tcp
		Iface Initiatorname: iqn.1994-05.com.redhat:6a4517b3773a
		Iface IPaddress: 192.168.1.14
		Iface HWaddress: <empty>
		Iface Netdev: <empty>
		SID: 1
		iSCSI Connection State: LOGGED IN
		iSCSI Session State: LOGGED_IN
		Internal iscsid Session State: NO CHANGE
		*********
		Timeouts:
		*********
		Recovery Timeout: 5
		Target Reset Timeout: 30
		LUN Reset Timeout: 30
		Abort Timeout: 15
		*****
		CHAP:
		*****
		username: <empty>
		password: ********
		username_in: <empty>
		password_in: ********
		************************
		Negotiated iSCSI params:
		************************
		HeaderDigest: None
		DataDigest: None
		MaxRecvDataSegmentLength: 262144
		MaxXmitDataSegmentLength: 131072
		FirstBurstLength: 131072
		MaxBurstLength: 16776192
		ImmediateData: Yes
		InitialR2T: Yes
		MaxOutstandingR2T: 1
		************************
		Attached SCSI devices:
		************************
		Host Number: 3	State: running
		scsi3 Channel 00 Id 0 Lun: 2
			Attached scsi disk sdb		State: running
		scsi3 Channel 00 Id 0 Lun: 3
			Attached scsi disk sdc		State: running
Target: iqn.2017-10.com.redhat.stirabos:he (non-flash)
	Current Portal: 192.168.1.125:3260,1
	Persistent Portal: 192.168.1.125:3260,1
		**********
		Interface:
		**********
		Iface Name: default
		Iface Transport: tcp
		Iface Initiatorname: iqn.1994-05.com.redhat:6a4517b3773a
		Iface IPaddress: 192.168.1.14
		Iface HWaddress: <empty>
		Iface Netdev: <empty>
		SID: 4
		iSCSI Connection State: LOGGED IN
		iSCSI Session State: LOGGED_IN
		Internal iscsid Session State: NO CHANGE
		*********
		Timeouts:
		*********
		Recovery Timeout: 5
		Target Reset Timeout: 30
		LUN Reset Timeout: 30
		Abort Timeout: 15
		*****
		CHAP:
		*****
		username: <empty>
		password: ********
		username_in: <empty>
		password_in: ********
		************************
		Negotiated iSCSI params:
		************************
		HeaderDigest: None
		DataDigest: None
		MaxRecvDataSegmentLength: 262144
		MaxXmitDataSegmentLength: 131072
		FirstBurstLength: 131072
		MaxBurstLength: 16776192
		ImmediateData: Yes
		InitialR2T: Yes
		MaxOutstandingR2T: 1
		************************
		Attached SCSI devices:
		************************
		Host Number: 6	State: running
		scsi6 Channel 00 Id 0 Lun: 0
			Attached scsi disk sdd		State: running
		scsi6 Channel 00 Id 0 Lun: 1
			Attached scsi disk sde		State: running
[root@c75he20180820h1 ~]# lsblk /dev/sdd
NAME                                MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sdd                                   8:48   0  100G  0 disk
└─36589cfc000000e8a909165bdfb47b3d9 253:10   0  100G  0 mpath
[root@c75he20180820h1 ~]# lsblk /dev/sde
NAME                                MAJ:MIN RM SIZE RO TYPE  MOUNTPOINT
sde                                   8:64   0  10G  0 disk
└─36589cfc000000ab67ee1427370d68436 253:0    0  10G  0 mpath
[root@c75he20180820h1 ~]# /lib/udev/scsi_id --page=0x83 --whitelisted --device=/dev/sdd
36589cfc000000e8a909165bdfb47b3d9
[root@c75he20180820h1 ~]# iscsiadm -m node --targetname iqn.2017-10.com.redhat.stirabos:he -p 192.168.1.125:3260 -u
Logging out of session [sid: 4, target: iqn.2017-10.com.redhat.stirabos:he, portal: 192.168.1.125,3260]
Logout of [sid: 4, target: iqn.2017-10.com.redhat.stirabos:he, portal: 192.168.1.125,3260] successful.
```

# Usage
1. Check all the prerequisites and requirements are met.
2. Encrypt passwords.yml
```sh
$ ansible-vault encrypt passwords.yml
```

3. Execute the playbook

Local deployment:
```sh
$ ansible-playbook hosted_engine_deploy.yml --extra-vars='@he_deployment.json' --ask-vault-pass
```

Deployment over a remote host:
```sh
ansible-playbook -i host123.localdomain, hosted_engine_deploy.yml --extra-vars='@he_deployment.json' --ask-vault-pass
```

Demo
----
Here a demo showing a deployment on NFS configuring the engine VM with static IP.
[![asciicast](https://asciinema.org/a/205639.png)](https://asciinema.org/a/205639)

# License

Apache License 2.0

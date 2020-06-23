# Ansible-Codefolio

Attempted deployment/provisioning script for Codefol.io, forked from EmailThis/ansible-rails

---

## Config to Validate Manually
* Certbot (for Let's encrypt SSL certificates)

## How To

### Install

```
git clone https://github.com/noah-gibbs/ansible-codefolio
cd ansible-codefolio
```

### Configure

(This will be set up for my own use initially. I can skip this step, but if you want to use my config you'll have to change it before real deployment.)

Open `app-vars.yml` and change the following variables. Additionally, please review the `app-vars.yml` and see if there is anything else that you would like to modify (e.g.: install some other packages, change ruby, node or postgresql versions etc.)

```
app_name:           YOUR_APP_NAME   // Replace with name of your app
app_git_repo:       "YOUR_GIT_REPO" // e.g.: github.com/EmailThis/et
app_git_branch:     "master"        // branch that you want to deploy (e.g: 'production')

postgresql_db_user:     "{{ deploy_user }}_postgresql_user"
postgresql_db_password: "{{ vault_postgresql_db_password }}" # from vault (see next section)
postgresql_db_name:     "{{ app_name }}_production"

nginx_https_enabled: false # change to true if you wish to install SSL certificate 
```

### Passwords, API Keys, Etc.

Create a new `vault` file to store sensitive information (unless somebody has already set up this repo for your org not mine).

1. Come up with a secure new password.
2. Put that password, all by itself, into a file called .vault_pass in the root of ansible-codefolio
3. rm group_vars/all/vault.yml
4. ansible-vault create group_vars/all/vault.yml
5. Add the following information to this new vault file
```
vault_postgresql_db_password: "XXXXX_SUPER_SECURE_PASS_XXXXX"
vault_rails_master_key: "XXXXX_MASTER_KEY_FOR_RAILS_XXXXX"
```

Now you can put passwords in there. Don't just copy-and-paste the ones above - you need a new password.

The .vault_pass file will not be checked in by Git automatically because it's in the .gitignore. That's a very good thing.

### VM Creation and Provisioning

Now that we have configured everything, lets see if everything is working locally. Run the following command -
```
vagrant up
```
Now open your browser and navigate to 192.168.50.2. You'll probably see a bad gateway error since you still need to run ansistrano to deploy your app.

If you don't wish to use Vagrant, clone this repo, modify the `inventories/development.ini` file to suit your needs, and then run the following command
```
ansible-playbook -i inventories/development.ini provision.yml
```

To deploy this app to your production server, create another file inside `inventories` directory called `production.ini` with the following contents. For this, you would need a VPS. I've used [DigitalOcean](https://m.do.co/c/031c76b9c838) and [Vultr](https://www.vultr.com/?ref=8597223) in production for my apps and both these services are top-notch.
```
[web]
192.168.50.2 # replace with IP address of your server.

[all:vars]
ansible_ssh_user=deployer
ansible_python_interpreter=/usr/bin/python3
```

### Deploy

Before your first deploy:

```
ansible-galaxy install ansistrano.deploy ansistrano.rollback
```

To deploy using Ansistrano:

```
ansible-playbook -i inventories/development.ini deploy.yml
```

---

### Additional Configuration

####  Installing additional packages
By default, the following packages are installed. You can add/remove packages to this list by changing the `required_package` variable in `app-vars.yml`
```
    - curl
    - ufw
    - fail2ban
    - git-core
    - apt-transport-https
    - ca-certificates
    - software-properties-common
    - python3-pip
    - virtualenv
    - python3-setuptools
    - zlib1g-dev 
    - build-essential 
    - libssl-dev 
    - libreadline-dev 
    - libyaml-dev 
    - libxml2-dev 
    - libxslt1-dev 
    - libcurl4-openssl-dev
    - libffi-dev 
    - dirmngr 
    - gnupg
    - autoconf
    - bison
    - libreadline6-dev
    - libncurses5-dev
    - libgdbm5 
    - libgdbm-dev
    - libpq-dev # postgresql client
    - libjemalloc-dev # jemalloc
```

####  Enable UFW
You can enable UFW by adding the role to `provision.yml` like so - 
```
roles:
    ...
    ...
    - role: ufw
      tags: ufw
```

Then you can set up the UFW rules in `app-vars.yml` like so -
```
ufw_rules:
  - { rule: "allow", proto: "tcp", from: "any", port: "80" }
  - { rule: "allow", proto: "tcp", from: "any", port: "443" }
```

#### Enable Certbot (Let's Encrypt SSL certificates)

Note: I don't think this works when running with a local Vagrant VM. So presumably this is to be done for the production config only.

Add the role to `provision.yml`
```
roles:
    ...
    ...
    - role: certbot
      tags: certbot
```

Add the following variables to `app-vars.yml`
```
nginx_https_enabled: true

certbot_email: "you@email.me"
certbot_domains:
  - "domain.com"
  - "www.domain.com"
```

#### PostgreSQL Database Backups
By default, daily backup is enabled in the `app-vars.yml` file. In order for this to work, the following variables need to be set. If you do not wish to store backups, remove (or uncomment) these lines from `app-vars.yml`.

```
aws_key: "{{ vault_aws_key }}" # store this in group_vars/all/vault.yml that we created earlier
aws_secret: "{{ vault_aws_secret }}"

postgresql_backup_dir: "{{ deploy_user_path }}/backups"
postgresql_backup_filename_format: >-
  {{ app_name }}-%Y%m%d-%H%M%S.pgdump
postgresql_db_backup_healthcheck: "NOTIFICATION_URL (eg: https://healthcheck.io/)" # optional
postgresql_s3_backup_bucket: "DB_BACKUP_BUCKET" # name of the S3 bucket to store backups
postgresql_s3_backup_hour: "3"
postgresql_s3_backup_minute: "*"
postgresql_s3_backup_delete_after: "7 days" # days after which old backups should be deleted
```

---

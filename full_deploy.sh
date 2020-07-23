#!/bin/bash

set -e -x

ansible-playbook -i inventories/production.ini provision.yml && ./deploy.sh

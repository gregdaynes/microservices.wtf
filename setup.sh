#!/bin/bash

echo
echo 'Checks that your Triton and Docker environment is sane and configures'
echo 'an environment file to use.'
echo
echo 'MANTA_PRIVATE_KEY is the filesystem path to an SSH private key'
echo 'used to connect to Manta for the database backups.'
echo
echo 'Additional details must be configured in the _env file, but this script will properly'
echo 'encode the SSH key details for use with this this project.'
echo

# populated by `check` function whenever we're using Triton
TRITON_USER=
TRITON_DC=
TRITON_ACCOUNT=

# Check for correct configuration and setup _env file
envcheck() {

    ###
    # Ask for inputs
    #
    # Service Name
    echo "Please enter a cluster name: "
    read CLUSTER_NAME
    # Gateway
    echo "What will the gateways label be? "
    read GATEWAY_NAME
    # MANTA
    echo "Please enter a Manta Bucket path (use absolute path /company/stor/bucket_of_awesome): "
    read MANTA_BUCKET
    echo "Please enter the username with access to the Manta Bucket $(echo $MANTA_BUCKET): "
    read MANTA_USER
    echo "Enter a subuser name if you wish, otherwise press enter: "
    read MANTA_SUBUSER
    echo "Assign a manta user role if you wish, otherwise press enter: "
    read MANTA_ROLE
    echo "Please enter the path to the users manta ssh key: "
    read MANTA_PRIVATE_KEY_PATH
    # END OF INPUTS

    command -v docker >/dev/null 2>&1 || {
        echo
        tput rev  # reverse
        tput bold # bold
        echo 'Docker is required, but does not appear to be installed.'
        tput sgr0 # clear
        echo 'See https://docs.joyent.com/public-cloud/api-access/docker'
        exit 1
    }

    command -v json >/dev/null 2>&1 || {
        echo
        tput rev  # reverse
        tput bold # bold
        echo 'Error! JSON CLI tool is required, but does not appear to be installed.'
        tput sgr0 # clear
        echo 'See https://apidocs.joyent.com/cloudapi/#getting-started'
        exit 1
    }

    command -v triton >/dev/null 2>&1 || {
        echo
        tput rev  # reverse
        tput bold # bold
        echo 'Error! Joyent Triton CLI is required, but does not appear to be installed.'
        tput sgr0 # clear
        echo 'See https://www.joyent.com/blog/introducing-the-triton-command-line-tool'
        exit 1
    }

    # make sure Docker client is pointed to the same place as the Triton client
    local docker_user=$(docker info 2>&1 | awk -F": " '/SDCAccount:/{print $2}')
    local docker_dc=$(echo $DOCKER_HOST | awk -F"/" '{print $3}' | awk -F'.' '{print $1}')
    TRITON_USER=$(triton profile get | awk -F": " '/account:/{print $2}')
    TRITON_DC=$(triton profile get | awk -F"/" '/url:/{print $3}' | awk -F'.' '{print $1}')
    TRITON_ACCOUNT=$(triton account get | awk -F": " '/id:/{print $2}')
    if [ ! "$docker_user" = "$TRITON_USER" ] || [ ! "$docker_dc" = "$TRITON_DC" ]; then
        echo
        tput rev  # reverse
        tput bold # bold
        echo 'Error! The Triton CLI configuration does not match the Docker CLI configuration.'
        tput sgr0 # clear
        echo
        echo "Docker user: ${docker_user}"
        echo "Triton user: ${TRITON_USER}"
        echo "Docker data center: ${docker_dc}"
        echo "Triton data center: ${TRITON_DC}"
        exit 1
    fi

    local triton_cns_enabled=$(triton account get | awk -F": " '/cns/{print $2}')
    if [ ! "true" == "$triton_cns_enabled" ]; then
        echo
        tput rev  # reverse
        tput bold # bold
        echo 'Error! Triton CNS is required and not enabled.'
        tput sgr0 # clear
        echo
        exit 1
    fi

    # setup environment file
    if [ ! -f "_env" ]; then
        echo '# Environment variables for for Microservices' > _env

        echo 'GATEWAY_URL=http://'${GATEWAY_PATH}.svc.${TRITON_ACCOUNT}.${TRITON_DC}.triton.zone >> _env
        echo >> _env

        echo '# Environment variables for MySQL service' >> _env
        echo 'MYSQL_USER='${CLUSTER_NAME}_USER >> _env
        echo 'MYSQL_PASSWORD='$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 7) >> _env
        echo 'MYSQL_DATABASE='${CLUSTER_NAME} >> _env
        echo '# MySQL replication user, should be different from above' >> _env
        echo 'MYSQL_REPL_USER=repluser' >> _env
        echo 'MYSQL_REPL_PASSWORD='$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 7) >> _env
        echo >> _env

        echo '# Environment variables for backups to Manta' >> _env
        echo 'MANTA_URL=https://us-east.manta.joyent.com' >> _env
        echo 'MANTA_BUCKET='${MANTA_BUCKET}' # an existing Manta bucket' >> _env
        echo 'MANTA_USER='${MANTA_USER}' # a user with access to that bucket' >> _env
        echo 'MANTA_SUBUSER='${MANTA_SUBUSER} >> _env
        echo 'MANTA_ROLE='${MANTA_ROLE} >> _env

        # MANTA_KEY_ID must be the md5 formatted key fingerprint. A SHA256 will result in errors.
        set +o pipefail
        # The -E option was added to ssh-keygen recently; if it doesn't work, then
        # assume we're using an older version of ssh-keygen that only outputs MD5 fingerprints
        ssh-keygen -yl -E md5 -f ${MANTA_PRIVATE_KEY_PATH} > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo MANTA_KEY_ID=$(ssh-keygen -yl -E md5 -f ${MANTA_PRIVATE_KEY_PATH} | awk '{print substr($2,5)}') >> _env
        else
            echo MANTA_KEY_ID=$(ssh-keygen -yl -f ${MANTA_PRIVATE_KEY_PATH} | awk '{print $2}') >> _env
        fi
        set -o pipefail

        # munge the private key so that we can pass it into an env var sanely
        # and then unmunge it in our startup script
        echo MANTA_PRIVATE_KEY=$(cat ${MANTA_PRIVATE_KEY_PATH} | tr '\n' '#') >> _env
        echo >> _env

        echo '# Consul discovery via Triton CNS' >> _env
        echo 'SERVICE_DISCOVERY_HOST='${CLUSTER_NAME}-consul.svc.${TRITON_ACCOUNT}.${TRITON_DC}.cns.joyent.com >> _env
        echo 'SERVICE_DISCOVERY_PORT=8500' >> _env
        echo 'SERVICE_DISCOVERY_POLL=5' >> _env
        echo 'SERVICE_DISCOVERY_TTL=10' >> _env
        echo >> _env

        echo 'Edit the _env file to confirm and set your desired configuration details'
    else
        echo 'Existing _env file found, exiting'
        exit
    fi
}

# Run the setup
envcheck

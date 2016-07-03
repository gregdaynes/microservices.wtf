echo
echo "Intialize a series of folders for each microservice"
echo
echo "Enter information as asked, you can update information in the created _env files after"
echo
echo "Enter a comma separated list of services to create: "
read SERVICES

IFS=', ' read -r -a array <<< "$SERVICES"

for service in "${array[@]}"
do
    echo "What is the process name for ${service}? "
    read process_name
    echo "What is the port for the ${service}? "
    read service_port
    mkdir "./${service}"
    touch "./${service}/_${service}_env
    echo 'SERVICE_NAME='${service} >> ./${service}/_${service}_env
    echo 'SERVICE_PROCESS='${process_name} >> ./${service}/_${service}_env
    echo 'SERVICE_PORT='${service_port} >> ./${service}/_${service}_env
    echo >> ./${service}/_${service}_env
    
    cp containerpilot.tmpl ./${service}/containerpilot.json
done

#!/usr/bin/env bash

# Run superkojiman/pwnbox container in docker.
# 
# Store your .gdbinit, .radare2rc, .vimrc, etc in a ./rc directory and 
# the contents will be copied to /root/ in the container.


ESC="\x1B["
RESET=$ESC"39m"
RED=$ESC"31m"
GREEN=$ESC"32m"
BLUE=$ESC"34m"

current_configs=( .bashrc .tmux.conf .tmux.conf.local .vim .vimrc )

# check if jq is installed
which jq > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo -e "${RED}Install jq and try again${RESET}"
    echo -e "${RED}macOS: brew install jq${RESET}"
    echo -e "${RED}Debian/Ubuntu: sudo apt install jq${RESET}"
    echo -e "${RED}Fedora: sudo dnf install jq${RESET}"
    exit 0
fi 

ctf_name="pwnbox"

docker run -it \
    -h ${ctf_name} \
    -d \
    --security-opt seccomp:unconfined \
    --name ${ctf_name} \
    -v ${PWD}/data:/root/work \
    --privileged \
    superkojiman/pwnbox

# Tar config files in rc and extract it into the container
if [[ -d rc ]]; then
    cd rc

    # Copy current configs to pwnbox
    for i in "${current_configs[@]}"; do
        sudo cp -r $HOME/$i .
    done
   
    if [[ -f rc.tar ]]; then
        rm -f rc.tar
    fi
    for i in .*; do
        if [[ ! ${i} == "." && ! ${i} == ".." ]]; then
            tar rf rc.tar ${i}
        fi
    done
    cd - > /dev/null 2>&1
    cat rc/rc.tar | docker cp - ${ctf_name}:/root/
    rm -f rc/rc.tar
else
    echo -e "${RED}No rc directory found. Nothing to copy to container.${RESET}"
fi

# Create stop/rm script for container
cat << EOF > ${ctf_name}-stop.sh
#!/bin/bash
echo "Removing ${ctf_name} containers"
docker stop ${ctf_name}
docker rm ${ctf_name}
rm -f ${ctf_name}-attach.sh
rm -f ${ctf_name}-stop.sh
EOF
chmod 755 ${ctf_name}-stop.sh

# Create a script to quickly re-attach to the container's tmux
cat << EOF > ${ctf_name}-attach.sh
#!/bin/bash
docker exec -it ${ctf_name} tmux ls > /dev/null 2>&1
if [[ \$? -eq 0 ]]; then 
    docker exec -it ${ctf_name} tmux -u a -d -t ${ctf_name}
else
    echo "No tmux session found. Starting a new one."
    docker exec -it ${ctf_name} tmux -u new -s ${ctf_name} -c /root/work
fi 
EOF
chmod 755 ${ctf_name}-attach.sh

# Drop into a tmux shell
echo -e "${GREEN}                         ______               ${RESET}"
echo -e "${GREEN}___________      ___________  /___________  __${RESET}"
echo -e "${GREEN}___  __ \\_ | /| / /_  __ \\_  __ \\  __ \\_  |/_/${RESET}"
echo -e "${GREEN}__  /_/ /_ |/ |/ /_  / / /  /_/ / /_/ /_>  <  ${RESET}"
echo -e "${GREEN}_  .___/____/|__/ /_/ /_//_.___/\\____//_/|_|  ${RESET}"
echo -e "${GREEN}/_/                           by superkojiman  ${RESET}"
echo ""
docker exec -it ${ctf_name} tmux -u new -s ${ctf_name} -c /root/work

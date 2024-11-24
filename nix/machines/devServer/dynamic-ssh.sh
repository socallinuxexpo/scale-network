#!/usr/bin/env bash
GUEST_NAME=$1
ACTION=$2

# Define the base host port (e.g., 2222) for forwarding
BASE_PORT=2222

# Function to get the assigned IP address of the VM
get_vm_ip() {
    virsh domifaddr "$GUEST_NAME" --source agent | grep -oP '(\d{1,3}\.){3}\d{1,3}'
}

# Calculate a unique host port for this VM based on its name hash
calculate_port() {
    VM_HASH=$(echo -n "$GUEST_NAME" | md5sum | awk '{print $1}')
    PORT=$((BASE_PORT + (0x${VM_HASH:0:4} % 1000)))
    echo $PORT
}

# When the VM starts, add an iptables rule to forward the host port to VM's port 22
if [ "$ACTION" = "started" ]; then
    VM_IP=$(get_vm_ip)
    if [ -n "$VM_IP" ]; then
        HOST_PORT=$(calculate_port)
        #sudo iptables -t nat -A PREROUTING -p tcp --dport "$HOST_PORT" -j DNAT --to-destination "$VM_IP:22"
        sudo iptables -I FORWARD -o virbr0 -p tcp -d $VM_IP --dport $GUEST_PORT -j ACCEPT
        sudo iptables -t nat -I PREROUTING -p tcp --dport $HOST_PORT -j DNAT --to $VM_IP:22
        echo "Port forwarding set: Host port $HOST_PORT -> $VM_IP:22"
    fi

# When the VM stops, remove the iptables rule for that VM
elif [ "$ACTION" = "stopped" ]; then
    HOST_PORT=$(calculate_port)
    #sudo iptables -t nat -D PREROUTING -p tcp --dport "$HOST_PORT" -j DNAT --to-destination "$(get_vm_ip):22"
    sudo iptables -D FORWARD -o virbr0 -p tcp -d $VM_IP --dport $GUEST_PORT -j ACCEPT
    sudo iptables -t nat -D PREROUTING -p tcp --dport $HOST_PORT -j DNAT --to $VM_IP:22
    echo "Port forwarding removed for Host port $HOST_PORT"
fi

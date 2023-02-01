#!/bin/bash
# Instalação e configuração do host KVM

set -e

#validador de privilegios
if [ "$UID" == "0" ]; then
echo "SCRIPT 01 RUN"
else 
echo "APENAS USUÁRIOS SUDO TEM PERMISSÃO" 
exit
fi

####################################################

# arquivo com a lista de pacotes a serem instalados
declare -a packages_file="./packages.txt"

# Atualiza o sistema sem interação #####
apt update -y
apt upgrade -y

# Lê a lista de pacotes do arquivo
readarray -t packages < "$packages_file"

# Loop para instalar cada pacote na lista
for package in "${packages[@]}"
do
  apt install "$package" -y 
done

apt autoremove -y

echo "update ok"

sleep 10

#########################################

# Verifica se o módulo br_netfilter já está carregado
if lsmod | grep -q br_netfilter; then
  echo "br_netfilter já está carregado."
else
  # Verifica se o br_netfilter já está no arquivo /etc/modules
  grep -q "br_netfilter" /etc/modules || echo "br_netfilter" >> /etc/modules

  # Carrega o módulo br_netfilter
  modprobe br_netfilter
fi

echo "br_netfilter ok"
sleep 10

# Define o conteúdo a ser adicionado ao arquivo
CONTENT="net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0"

# Verifica se o conteúdo já existe no arquivo
if ! grep -q "$CONTENT" /etc/sysctl.conf; then
    echo "$CONTENT" | sudo tee -a /etc/sysctl.conf > /dev/null
    echo "Conteúdo adicionado ao arquivo /etc/sysctl.conf"
else
    echo "Conteúdo já presente no arquivo /etc/sysctl.conf"
fi
# Aplica as configurações e exibe resultado
if sudo sysctl -p /etc/sysctl.conf; then
    echo "Configurações do sysctl aplicadas com sucesso"
else
    echo "Erro ao aplicar configurações do sysctl"
fi

sleep 5

systemctl enable libvirtd
systemctl restart libvirtd

echo "libvirt ok"
sleep 5

if [ ! -d "/network" ]; then
  mkdir /network
fi

cd /network

cat <<'EOF' > lab-net.xml
<network>
<name>lab-net</name>
<forward mode='nat'/>
<bridge name='virbr1' stp='on' delay='0'/>
<ip address='192.168.123.1' netmask='255.255.255.0'>
<dhcp>
<range start='192.168.123.50' end='192.168.123.99'/>
</dhcp>
</ip>
</network>
EOF

echo "network ok"
sleep 5
#define and start network libvirt
# Check if network lab-net already existsWORK_EXISTS=$(virsh net-list --all | grep -c "lab-net")

if virsh net-info lab-net &> /dev/null; then
  echo "A rede lab-net já está definida."
  sleep 3
else
  echo "A rede lab-net não está definida"
  # Define and start network lab-net
  virsh net-define --file lab-net.xml
  virsh net-autostart lab-net
  virsh net-start lab-net
fi

# Show networks
virsh net-list --all
sleep 5



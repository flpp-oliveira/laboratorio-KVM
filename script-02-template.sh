#!/bin/bash
#Configura e instala as vms

set -e

#validador de privilegios
if [ "$UID" == "0" ]; then
  echo "SCRIPT 02 RUN"
else 
echo "APENAS USUÁRIOS SUDO TEM PERMISSÃO" 
exit
fi



# Baixar imagem do laboratorio #####
IMAGE_URL="http://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
IMAGE_NAME=$(basename "$IMAGE_URL")
IMAGE_DIR="/var/lib/libvirt/images"

if [ ! -f "$IMAGE_DIR/$IMAGE_NAME" ]; then
  wget -P "$IMAGE_DIR" "$IMAGE_URL"
else
  echo "A imagem $IMAGE_NAME já existe no diretório $IMAGE_DIR. Não será feito o download."
fi

cd /var/lib/libvirt/images/

qemu-img resize $IMAGE_NAME 50G

#customize
virt-customize -a $IMAGE_NAME \
  --run-command 'growpart /dev/sda 1' \
  --run-command 'resize2fs /dev/sda1'

virt-customize -a $IMAGE_NAME \
  --timezone "America/Belem" \
  --update --network --uninstall cloud-init \
  --root-password password:infra1234 \
  --firstboot-command "dpkg-reconfigure -f noninteractive openssh-server" \
  --run-command 'sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config' \
  --run-command 'sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config'


# Cria as imagens para seres usadas no laboratorio
for i in {1..4}; do
  NEW_IMAGE_NAME="server-$(printf '%02d' $i).img"
  NEW_IMAGE_PATH="/var/lib/libvirt/images/$NEW_IMAGE_NAME"
  echo "Verificando se a imagem $NEW_IMAGE_NAME já foi criada em $NEW_IMAGE_PATH"
  if [ ! -f $NEW_IMAGE_PATH ]; then
    echo "A imagem $NEW_IMAGE_NAME ainda não foi criada, criando..."
    qemu-img create -b $IMAGE_NAME -f qcow2 -F qcow2 $NEW_IMAGE_NAME
  else
    echo "A imagem $NEW_IMAGE_NAME já foi criada, prosseguindo..."
  fi
sleep 5

# Replace server0N with server0X, where X is the current iteration value
  file_name="server-$(printf '%02d' $i)-config.yaml"

# Replace the IP address with the current iteration value
  sed "s/xx/$((9+i))/" > $file_name << 'EOF'
network:
  version: 2
  ethernets:
    enp1s0:
      addresses:
         - 192.168.123.xx/24
      gateway4: 192.168.123.1
      nameservers:
        search: [infra.local]
        addresses: [192.168.123.10, 8.8.8.8]
EOF

echo "arquivo server-$(printf '%02d' $i)-config ok"

sleep 3

#Conﬁgurar rede e hostname no disco virtual
virt-customize -a /var/lib/libvirt/images/server-$(printf '%02d' $i).img \
--hostname server-$(printf '%02d' $i).infra.local \
--upload server-$(printf '%02d' $i)-config.yaml:/etc/netplan/enp1s0-config.yaml

sleep 3

virt-install --name=server-$(printf '%02d' $i) \
  --import --disk path=/var/lib/libvirt/images/server-$(printf '%02d' $i).img,format=qcow2 \
  --ram=2048 --vcpus=2 --os-variant=ubuntu22.04 \
  --network network=lab-net,model=virtio \
  --graphics vnc,listen=0.0.0.0 --noautoconsole

echo "instalação do server-$(printf '%02d' $i) ok"

done
# Laboratorio - KVM 

## Observações

- O script foi testado com sucesso em um sistema
  operacional Ubuntu 22.04.1 LTS.
- Certifique-se de que o arquivo packages.txt contém os
  pacotes corretos para sua instalação.
- Certifique-se de que as configurações específicas adicionadas ao arquivo /etc/sysctl.conf são adequadas para sua rede.
- Se as imagens utilizadas por esse tutorial já estiverem   criadas, remova para não gerar conflito com os downloads.

## Introdução

Bem-vindo ao nosso repositório de laboratório KVM! Este repositório foi criado para automatizar a configuração de um laboratório virtual usando o KVM como hypervisor. Nós fornecemos três scripts bash - script-01, script-02 e script-03 - que simplificam a configuração do laboratório.

O script-01 é responsável por configurações basicas,criação e configuração da rede, atualizar o sistema, configurações do libvirtd e instalações de pacotes que serão de uso do laboratório. O script-02 é responsável por instalar e configurar as vms, como configuração e customizações das imagens que serão necessárias em cada máquina virtual. Por fim, o script-03 é responsável por iniciar o script-01 e o script-02, garantindo assim a configuração completa e automatizada do seu laboratório KVM.

Com este repositório, você poderá criar seu próprio laboratório KVM de forma fácil e rápida, sem precisar se preocupar com a configuração manual e repetitiva das máquinas virtuais. Siga as instruções detalhadas em nossa documentação para começar a usar os scripts e criar o seu próprio laboratório KVM.

## Descrevendo os scripts
## Script 01
Este script tem como objetivo instalar e configurar o host KVM. Ele começa verificando se o usuário tem permissões sudo, caso contrário, o script é encerrado. Em seguida, o sistema é atualizado e pacotes específicos são instalados a partir de uma lista em um arquivo externo. O módulo br_netfilter é verificado e carregado se necessário. As configurações do sysctl são aplicadas para permitir o forward de IP. O serviço libvirtd é habilitado e reiniciado. Uma rede virtual (lab-net) é criada e definida utilizando libvirt, verificando se já existe antes. Finalmente, a lista de redes é exibida.

### Instalação e Configuração do Host KVM

Instala e configura o host KVM no sistema operacional. É uma automação de processos manuais, para agilizar a instalação e configuração do KVM.
Pré-Requisitos:

-    Sistema operacional baseado em Debian ou Ubuntu
- Acesso privilegiado como administrador (sudo)
- Arquivo packages.txt com a lista de pacotes a serem   instalados.

### Instalação de Pacotes

O script lê o arquivo packages.txt para instalar todos os pacotes necessários para o funcionamento do KVM.

### Configuração do Módulo br_netfilter

Verifica se o módulo ´br_netfilter´ já está carregado no sistema, e se não estiver, o carrega e adiciona ao arquivo /etc/modules.

```
if lsmod | grep -q br_netfilter; then
  echo "br_netfilter já está carregado."
else
  # Verifica se o br_netfilter já está no arquivo /etc/modules
  grep -q "br_netfilter" /etc/modules || echo "br_netfilter" >> /etc/modules

  # Carrega o módulo br_netfilter
  modprobe br_netfilter
fi

```

A necessidade de incluir o br_netfilter no modprobe se deve à sua função de realizar a inspeção de pacotes de rede no nível da camada de enlace, ou seja, ao nível dos pontes. A inspeção destes pacotes é importante para a segurança da rede, pois permite que as regras de firewall sejam aplicadas aos pacotes que passam por uma ponte. Quando o br_netfilter é incluído no modprobe, o sistema operacional sabe que precisa carregá-lo na inicialização e garante sua disponibilidade para uso. Além disso, as configurações mencionadas a baixo no sysctl são necessárias para garantir que as funções de filtragem de pacotes de rede funcionem corretamente.

### Configurações do sysctl

O script adiciona as seguintes configurações ao arquivo /etc/sysctl.conf:

```
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0


```
O arquivo de configuração do sysctl com essas configurações foi colocado para permitir que o sistema operacional funcione como um roteador, permitindo que pacotes IP sejam encaminhados entre interfaces de rede diferentes.

A configuração "net.ipv4.ip_forward" ativa o encaminhamento de pacotes IP, permitindo que pacotes sejam encaminhados entre as interfaces de rede.

As configurações "net.bridge.bridge-nf-call-ip6tables", "net.bridge.bridge-nf-call-iptables" e "net.bridge.bridge-nf-call-arptables" desativam a chamada às tabelas de firewall (ip6tables, iptables e arptables) durante o processo de encaminhamento de pacotes através da ponte. Isso é feito para evitar a lentidão causada pela aplicação de regras de firewall em cada pacote durante o encaminhamento.

### Habilitar e Inicia o Serviço libvirtd

O script habilita e reinicia o serviço libvirtd.

### Criação da Rede de Laboratório (lab-net)

O script cria uma rede virtual com o nome lab-net usando o libvirt, com as seguintes configurações:

    Forward mode: nat
    Nome da ponte: virbr1
    Endereço IP: 192.168.123.1
    Máscara de Sub-rede: 255.255.255.0
    Faixa de endereços DHCP: de 192.168.123.50 a 192.168.123.99



## Script 02

Este script tem como objetivo configurar e instalar vms (máquinas virtuais). O script começa verificando se o usuário que está executando o script tem privilégios de super usuário (root), caso não tenha, o script exibirá uma mensagem informando que apenas usuários com privilégios de super usuário têm permissão e encerrará a execução.

```
#validador de privilegios
if [ "$UID" == "0" ]; then
echo "SCRIPT 01 RUN"
else 
echo "APENAS USUÁRIOS SUDO TEM PERMISSÃO" 
exit
fi

```
Em seguida, o script baixa uma imagem de uma distribuição Linux a partir de uma URL especificada. A imagem é baixada para um diretório específico e, caso já exista, não será baixada novamente. Depois, o script redimensiona a imagem baixada para 50 GB usando o comando qemu-img resize.
```
# Baixar imagem do laboratorio #
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
```
O script em seguida usa o comando virt-customize para personalizar a imagem baixada. Ele configura o fuso horário para "America/Belem", atualiza a imagem, desinstala o cloud-init, define a senha root como "infra1234", reconfigura o serviço openssh-server, habilita a autenticação por senha e habilita o login como root via ssh.
```
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

```
O script então entra em um loop para criar quatro imagens a partir da imagem baixada e personalizada. Cada imagem é salva com um nome diferente e verifica se já foi criada antes, caso já tenha sido criada, o script pula essa etapa. Em seguida, o script gera um arquivo de configuração de rede para cada imagem, substituindo algumas variáveis, como o nome da máquina e o endereço IP, com base na iteração atual. O script então usa o comando virt-customize para configurar o hostname e a rede para cada imagem.
```
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

```
Por fim, o script usa o comando virt-install para instalar as quatro máquinas virtuais, especificando as configurações de hardware, como a quantidade de RAM e CPUs, o tipo de sistema operacional, a rede e as opções de gráficos. O script exibe uma mensagem após a instalação bem-sucedida de cada máquina virtual.
```
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

###

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

```
## Script 03

Este script tem como objetivo rodar dois outros scripts, nomeados "script-01-kvm.sh" e "script-02-template.sh".

O script começa verificando se o usuário que está executando o script tem privilégios de superusuário, isso é feito verificando se a variável "$UID" é igual a 0. Se o usuário não tiver privilégios de superusuário, o script exibirá a mensagem "APENAS USUÁRIOS SUDO TEM PERMISSÃO" e encerrará sua execução.

Em seguida, o script define duas funções "run_script1" e "run_script2", que são responsáveis por executar cada um dos scripts. Antes de executar cada script, o script exibe uma mensagem indicando qual script está sendo executado.

Depois, a função "run_script1" é executada. Se a execução tiver sucesso, o script verifica o código de retorno e, se for igual a 0, a função "run_script2" é executada. Se ambos os scripts tiverem sucesso, a mensagem "Ambos os scripts foram executados com sucesso!" é exibida. Caso contrário, a execução é interrompida e uma mensagem de falha é exibida indicando qual script falhou.

O script utiliza o comando "set -e" no início, que define que o script deve ser interrompido imediatamente caso ocorra um erro.

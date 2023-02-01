#!/bin/bash
#roda os dois scripts

set -e

#validador de privilegios
if [ "$UID" == "0" ]; then
  echo "SCRIPT 03 RUN"
else 
echo "APENAS USUÁRIOS SUDO TEM PERMISSÃO" 
exit
fi


# Nome dos scripts
script1="script-01-kvm.sh"
script2="script-02-template.sh"

# Função para executar o primeiro script
run_script1() {
  echo "Executando o script $script1..."
  ./$script1
  if [ $? -ne 0 ]; then
    echo "Falha ao executar o script $script1"
    exit 1
  fi
}

# Função para executar o segundo script
run_script2() {
  echo "Executando o script $script2..."
  ./$script2
  if [ $? -ne 0 ]; then
    echo "Falha ao executar o script $script2"
    exit 1
  fi
}

# Execute a função run_script1
run_script1

# Se a função run_script1 tiver sucesso, execute a função run_script2
if [ $? -eq 0 ]; then
  run_script2
  if [ $? -eq 0 ]; then
    echo "Ambos os scripts foram executados com sucesso!"
  fi
fi

Script de Automação do GLPI

Este projeto contém um script Bash que automatiza o processo de instalação e configuração do GLPI em servidores Linux. O script foi desenvolvido para simplificar a implantação do GLPI, garantindo que todas as dependências, configurações de banco de dados e ajustes de servidor web sejam realizados de forma eficiente e padronizada. Ideal para administradores de sistemas que buscam uma solução rápida e confiável para gerenciar infraestruturas de TI usando o GLPI.

O nome do banco é: itsmdb
O nome do usuário do banco é: itsmsrv

Descrição do arquivo de instalação do agente
Este arquivo contém um script de automação desenvolvido em VBScript para a implantação do GLPI Agent em ambientes Windows. O script oferece uma solução completa para a instalação e configuração automatizada do agente, com suporte para a remoção de agentes anteriores como FusionInventory e OCS Inventory.

Funcionalidades Principais
Instalação Automatizada: Facilita a instalação do GLPI Agent, configurando automaticamente o servidor GLPI e outras opções necessárias.
Detecção de Arquitetura: Detecta a arquitetura do sistema (x86 ou x64) e baixa a versão apropriada do agente.
Desinstalação de Agentes Anteriores: Possui a capacidade de desinstalar versões anteriores de agentes como FusionInventory e OCS Inventory antes de instalar o GLPI Agent.
Configuração Personalizável: Permite a personalização de várias opções de instalação, incluindo a URL do servidor GLPI, opções de linha de comando e a escolha da arquitetura do instalador.
Compatibilidade: Suporta instalações em sistemas Windows de 32 e 64 bits.
Como Utilizar
Edite as configurações no início do script para ajustar conforme suas necessidades.
Execute o script em um ambiente Windows para realizar a instalação automatizada do GLPI Agent.
O script pode ser executado manualmente ou distribuído através de uma GPO para implantação em larga escala.

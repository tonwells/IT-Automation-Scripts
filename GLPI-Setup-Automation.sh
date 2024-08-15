#!/bin/bash

# Definir o arquivo de log
LOGFILE="/var/log/glpi_install.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Função para registrar erros e sair
error_exit() {
    echo "Erro no script: $1"
    exit 1
}

# Função para exibir mensagens em verde
function echo_success {
    echo -e "\e[32m$1\e[0m"
}

# Atualiza o sistema
echo "Atualizando o sistema..."
if sudo dnf update -y; then
    echo_success "Sistema atualizado com sucesso!"
else
    echo "Erro ao atualizar o sistema"
    exit 1
fi

# Verifica e instala o repositório EPEL
echo "Verificando o repositório EPEL..."
if rpm -qa | grep -qw epel-release; then
    echo_success "Repositório EPEL já está instalado"
else
    echo "Instalando o repositório EPEL..."
    if sudo dnf install -y epel-release; then
        echo_success "Repositório EPEL instalado com sucesso!"
    else
        echo "Erro ao instalar o repositório EPEL"
        exit 1
    fi
fi

# Verifica e instala ferramentas necessárias
echo "Verificando e instalando ferramentas necessárias..."
for package in httpd vim wget unzip tar; do
    if rpm -qa | grep -qw $package; then
        echo_success "$package já está instalado"
    else
        echo "Instalando $package..."
        if sudo dnf install -y $package; then
            echo_success "$package instalado com sucesso!"
        else
            echo "Erro ao instalar $package"
            exit 1
        fi
    fi
done

# Habilita e inicia o Apache
echo "Habilitando e iniciando o Apache..."
if systemctl is-active --quiet httpd; then
    echo_success "Apache já está ativo"
else
    sudo systemctl enable --now httpd
    if systemctl is-active --quiet httpd; then
        echo_success "Apache habilitado e iniciado com sucesso!"
    else
        echo "Erro ao habilitar e iniciar o Apache"
        exit 1
    fi
fi

# Verifica e instala o MariaDB
echo "Verificando o banco de dados MariaDB..."
if rpm -qa | grep -qw mariadb-server; then
    echo_success "Banco de dados MariaDB já está instalado"
else
    echo "Instalando o banco de dados MariaDB..."
    if sudo dnf install -y mariadb-server; then
        echo_success "Banco de dados MariaDB instalado com sucesso!"
    else
        echo "Erro ao instalar o banco de dados MariaDB"
        exit 1
    fi
fi

# Habilita e inicia o MariaDB
echo "Habilitando e iniciando o MariaDB..."
if systemctl is-active --quiet mariadb; then
    echo_success "MariaDB já está ativo"
else
    sudo systemctl enable --now mariadb
    if systemctl is-active --quiet mariadb; then
        echo_success "MariaDB habilitado e iniciado com sucesso!"
    else
        echo "Erro ao habilitar e iniciar o MariaDB"
        exit 1
    fi
fi

# Configuração inicial do MariaDB
echo "Configurando o MariaDB..."
sudo mysql_secure_installation

# Criação do banco de dados e usuário para o GLPI
echo "Criando o banco de dados e usuário para o GLPI..."
sudo mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE itsmdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'itsmsrv'@'localhost' IDENTIFIED BY 'senha';
GRANT ALL PRIVILEGES ON itsmdb.* TO 'itsmsrv'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Verifica e instala o PHP 8.1
echo "Verificando o PHP 8.1..."
if php -v | grep -qw "PHP 8.1"; then
    echo_success "PHP 8.1 já está instalado"
else
    echo "Instalando o PHP 8.1 e módulos necessários..."
    sudo dnf module reset -y php
    if sudo dnf module install -y php:8.1 && sudo dnf install -y php php-{mysqlnd,gd,intl,ldap,apcu,opcache,zip,xml}; then
        echo_success "PHP 8.1 e módulos instalados com sucesso!"
    else
        echo "Erro ao instalar o PHP 8.1 e módulos"
        exit 1
    fi
fi

# Reinicia o serviço do Apache para aplicar as alterações do PHP
echo "Reiniciando o serviço do Apache..."
if sudo systemctl restart httpd; then
    echo_success "Serviço do Apache reiniciado com sucesso!"
else
    echo "Erro ao reiniciar o serviço do Apache"
    exit 1
fi

# Liberar permissões no firewall
echo "Liberando permissões no firewall..."
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --reload
sudo setsebool -P httpd_can_network_connect on
sudo setsebool -P httpd_can_network_connect_db on
sudo setsebool -P httpd_can_sendmail on

# Baixa e instala o GLPI
echo "Baixando e instalando o GLPI..."
VERSION=$(curl --silent "https://api.github.com/repos/glpi-project/glpi/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
sudo wget https://github.com/glpi-project/glpi/releases/download/${VERSION}/glpi-${VERSION}.tgz

# Descompacta o GLPI
echo "Descompactando o GLPI..."
sudo tar xvf glpi-${VERSION}.tgz
sudo mv glpi /var/www/html

# Configura as permissões de diretório para o GLPI
echo "Configurando as permissões de diretório para o GLPI..."
sudo chown -R apache:apache /var/www/html/glpi
sudo chmod -R 755 /var/www/html/glpi

# Configura o SELinux
echo "Configurando o SELinux..."
sudo dnf -y install policycoreutils-python-utils
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/glpi(/.*)?"
sudo restorecon -Rv /var/www/html/glpi

# Informa o usuário sobre as configurações iniciais do GLPI
echo_success "Concluído! Agora acesse o GLPI em seu navegador para continuar a instalação."
echo_success "URL de acesso: http://<seu_ip>/glpi/install/"
echo_success "Banco de dados: itsmdb"
echo_success "Usuário do banco de dados: itsmsrv"
echo_success "Senha do banco de dados: senha"

# Limpar informações
sudo clear

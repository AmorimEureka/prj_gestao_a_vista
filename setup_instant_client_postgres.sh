#!/bin/sh
set -e

# Atualizar pacotes e instalar dependências
apt update
apt install -y libaio1 wget

# Criar diretórios para o cliente PostgreSQL
mkdir -p .postgresql/data
cd .postgresql/data

# Baixar o arquivo .tar.gz
wget --output-document=client.tar.gz https://ftp.postgresql.org/pub/source/v17.0/postgresql-17.0.tar.gz

# Descompactar o arquivo .tar.gz
tar -xzf client.tar.gz
rm client.tar.gz

# Remover pacotes desnecessários
apt remove -y wget

# Navegar para o diretório extraído
cd postgresql-17.0/

# Criar links simbólicos corretos
echo "Linking files..."
ln -fs libecpg.a libecpg.a
ln -fs libecpg.so libecpg.so
ln -fs libpq.so libpq.so

# Mensagem final
echo "Don't forget to set LD_LIBRARY_PATH_POSTGRES to /usr/local/airflow/.postgresql/data/postgresql_17.0/"
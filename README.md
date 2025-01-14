
# Docker MariaDB - Master Slave

Às vezes é necessário utilizar bancos de dados sincronizados. O MariaDB é um software open-source baseado no MySQL.

Este Dockerfile gera a configuração de master e slave na mesma máquina ou separadamente.

## Instalação

Primeiro, certifique-se de ter o Docker atualizado.

### Atualize o repositório

bash

```
sudo apt update

```

### Instale os pacotes necessários

bash

```
sudo apt install apt-transport-https ca-certificates curl software-properties-common

```

### Adicione a chave GPG do Docker

bash

```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

```

### Adicione o repositório Docker

bash

```
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

```

### Instale o Docker Engine

bash

```
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io

```

### Verifique a instalação

bash

```
sudo docker run hello-world

```

### Instale o Docker Compose

bash

```
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

```

### Configure o ambiente

Copie o arquivo `.env-exemple` para `.env`:

bash

```
cp .env-exemple .env

```

Edite o arquivo `.env` preenchendo as configurações:

bash

```
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=mydatabase
MYSQL_USER=user
MYSQL_PASSWORD=password

```

## Abordagens para Configuração

### 1. Servidores na mesma máquina

Execute o comando para subir os contêineres:

bash

```
docker-compose -f docker-compose-master-slave.yml up --build

```

#### No Docker Master

Conecte ao contêiner Master:

bash

```
docker exec -it mariadb_master mariadb -u root -p

```

Dentro do MariaDB Master, execute:

sql

```
GRANT REPLICATION SLAVE ON *.* TO 'slave_user'@'%' IDENTIFIED BY 'slave_password';
FLUSH PRIVILEGES;
SHOW MASTER STATUS;

```

**Anote os valores de** `File` **e** `Position` **retornados pelo comando** `SHOW MASTER STATUS`**.**

#### Configure a replicação no MariaDB Slave

Substitua `MASTER_LOG_FILE` e `MASTER_LOG_POS` pelos valores anotados anteriormente.

Conecte ao contêiner Slave:

bash

```
docker exec -it mariadb_slave mariadb -u root -p

```

Dentro do MariaDB Slave, execute:

sql

```
CHANGE MASTER TO
    MASTER_HOST='mariadb_master',
    MASTER_USER='slave_user',
    MASTER_PASSWORD='slave_password',
    MASTER_LOG_FILE='mysql-bin.000001', -- Substitua pelo valor do Master
    MASTER_LOG_POS=123; -- Substitua pelo valor do Master
START SLAVE;
SHOW SLAVE STATUS \G;

```

### 2. Servidores Separados

#### No Docker Master

Suba o contêiner do Master:

bash

```
docker-compose -f docker-compose-master.yml up --build

```

Conecte ao contêiner Master e ajuste o IP do Slave (10.10.10.12) conforme necessário:

bash

```
docker exec -it mariadb_master mariadb -u root -p

```

Dentro do MariaDB Master, execute:

sql

```
FLUSH TABLES WITH READ LOCK;
SHOW MASTER STATUS;

```

**Anote os valores de** `File` **e** `Position` **retornados pelo comando** `SHOW MASTER STATUS`**.**

#### No Docker Slave

Substitua `MASTER_HOST` pelo IP do Master (10.10.10.10), `MASTER_LOG_FILE` e `MASTER_LOG_POS` pelos valores anotados anteriormente.

Conecte ao contêiner Slave:

bash

```
docker exec -it mariadb_slave mariadb -u root -p

```

Dentro do MariaDB Slave, execute:

sql

```
CHANGE MASTER TO
    MASTER_HOST='10.10.10.10',
    MASTER_USER='slave_user',
    MASTER_PASSWORD='slave_password',
    MASTER_LOG_FILE='mysql-bin.000001', -- Substitua pelo valor do Master
    MASTER_LOG_POS=123; -- Substitua pelo valor do Master
START SLAVE;
SHOW SLAVE STATUS \G;

```

### Teste a Replicação

Crie uma nova tabela no banco Master e verifique se o Slave replica a nova tabela corretamente.
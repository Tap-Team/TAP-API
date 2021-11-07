## build env

さくらのクラウド

CentOS 7.9

- docker

    ```bash
    $ curl -fsSL https://get.docker.com/ | sh
    $ sudo service docker start
    ```

- docker-compose 1.29.2

    ```bash
    $ sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    $ sudo chmod +x /usr/local/bin/docker-compose
    $ sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    ```

## install

1. git clone: 

    ```bash
     $ git clone https://github.com/Tap-Team/tap-api.git
    ```

2. create `SERVICE_ACCOUNT.json`

3. docker build:

    ```bash
    $ docker-compose build
    ```

4. docker up: 

    ```bash
    $ docker-compose up -d
    ```

5. run database migration

    ```bash
    $ rails db:migrate
    ```

6. run init process: 

    ```bash
    $ rails init:create
    ```

## reset

1. docker down:

     ```bash
     $ docker-compose down
     ```

    

2. docker build: 

    ```bash
    $ docker-compose build
    ```

3. docker up:

    ```bash
    $ docker-compose up -d
    ```

4. reset database:

    ```bash
    $ rails db:reset
    ```

5. run init process:

    ```bash
    $ rails init:create
    ```


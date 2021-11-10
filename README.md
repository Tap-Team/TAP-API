# REST API for Tap!

> [**Tap!**](https://tap.shmn7iii.net)
> 
> Tap! is a service that makes publishing NFTs easier, more convenient, and more understandable, with the goal of lowering the barriers to NFTs, making them more accessible, and promoting their use in the general public, thereby further developing the NFT industry.
>
> This service was created within the "Challecara", and its actual use is yet to be determined. Also, we do not guarantee the tokens. For more information, please refer to the Terms of Use and Privacy Policy. -  Tap! Team.

## API Document

See http://tap-api.shmn7iii.net/v2

## How to Build

CentOS 7.9

### Install Docker & Docker Compose

Docker: latest
Docker-compose: 1.29.2

```bash
# Docker
$ curl -fsSL https://get.docker.com/ | sh
$ sudo service docker start

# Docker Compose
$ sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
$ sudo chmod +x /usr/local/bin/docker-compose
$ sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

### Setup data dir

```bash
# git clone
$ git clone https://github.com/Tap-Team/tap-api.git
```

Send Firebase's SERVICE_ACCOUNT.json to server using sftp etc.

```bash
### on local ###
$ cd path/to/SERVICE_ACCOUNT
$ sftp user@xxx.xxx.xxx.xxx
sftp> cd tap-api
sftp> put SERVICE_ACCOUNT.json
```

### Build and Up

```bash
# docker-compose build
$ docker-compose build

# docker-compose up
$ docker-comopse up -d
```

### Run initial process

```bash
# database reset
$ docker-compose exec rails rails db:reset

# TAP's init command
$ docker-compose exec rails rails init:create
```

## Reset all

This process also involves **RESETTING Tapyrus's DATABASE**, so the blockchain will be initialized and all NFTs will be lost.

> TapyrusのデータはDockerのtapyrusボリュームに格納されます。対してTap!のDBはRailsによりサーバー上に直接保存されます。つまりRailsによるデータベースリセットではユーザーとトークンの情報は破棄されますが、ブロックチェーン上にはNFTは残り続けます。ブロックチェーン上のNFT諸共リセットしたい時は以下の手順を踏んでください。

```bash
# refresh system
$ docker-compose down
$ docker volume prune
$ git pull
$ docker-compose build
$ docker-compose up -d

# reset database
$ docker-compose exec rails rails db:reset
$ docker-compose exec rails rails init:create
```


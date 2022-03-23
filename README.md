# REST API for Tap!

> [**Tap!**](https://tap.shmn7iii.net)
>
> Tap! is a service that makes publishing NFTs easier, more convenient, and more understandable, with the goal of lowering the barriers to NFTs, making them more accessible, and promoting their use in the general public, thereby further developing the NFT industry.
>
> This service was created within the "Challecara", and its actual use is yet to be determined. Also, we do not guarantee the tokens. For more information, please refer to the Terms of Use and Privacy Policy. -  Tap! Team.



> **2021/12/11**
>
> 九州アプリチャレンジキャラバン2021において  
> ・優秀賞  
> ・NECソリューションイノベータ賞  
> を受賞しました。  
> |優秀賞|NECソリューションイノベータ賞|
> |---|---|
> |![優秀賞](https://pbs.twimg.com/media/FGUFJWoUYAEa1Cv?format=jpg) | ![NECソリューションイノベータ賞](https://pbs.twimg.com/media/FGUFJWnVQAAnXIG?format=jpg)|


> **2021/1/21**
>
> 第14回 フクオカRuby大賞にて、学生賞（マネーフォワード賞）を受賞しました。
> |学生賞（マネーフォワード賞）|賞状|
> |---|---|
> |![学生賞（マネーフォワード賞）](https://storage.googleapis.com/studio-design-asset-files/projects/XKOk5dMea4/s-1880x590_v-frms_webp_2d8d2641-e479-441a-a7b6-f1cefc551b71_middle.png)|![賞状](https://pbs.twimg.com/media/FOH2QZWaUAA2xzr?format=jpg)|

## API Document

See ~http://tap-api.shmn7iii.net/v2~  
＊チャレキャラでのさくらのクラウド無償提供終了に伴い閉鎖

v1 is deprecated. Use v2. With v2, the file storaging system has changed from Firebase to IPFS, allowing you to issue full-on-chain NFTs.

## How to set up

Recommended OS is CentOS 7.9.

### dependencies

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

### setup data dir

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

### build and set up

```bash
# docker-compose build
$ docker-compose build

# docker-compose up
$ docker-comopse up -d

# database reset
$ docker-compose exec rails rails db:reset

# TAP's init command
$ docker-compose exec rails rails init:create
```

## How to use utils

### issue_sample_tokens.sh

For debug. This script issue tokens with images in `images` dir. **ONLY macOS**. **ONLY PNG IMAGE**.

### restart.sh

Down, git pull, build, and up.

## How to RESET all data

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


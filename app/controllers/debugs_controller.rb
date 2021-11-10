class DebugsController < ApplicationController

    def docker_ipfs
        ret = `ipfs --version `
        response_success('debugs', 'docker_ipfs', ret)
    end

    def decode_base64_image
        data = params[:data]

        meta_data = data.match(/data:(image|application)\/(.{3,});base64,(.*)/)
        content_type = meta_data[2]
        encoded_image = meta_data[3]

        if content_type == "jpeg" || content_type == "png"
            decoded_image = Base64.strict_decode64(encoded_image)

            dir_name = "#{encoded_image[..20]}"
            file_name = "#{dir_name}.#{content_type}"

            begin
                # mkdir
                dir_path = "#{Rails.root}/storage/images/#{dir_name}"
                Dir.mkdir(dir_path)

                # write image
                open("#{dir_path}/#{file_name}", 'wb') do |f|
                    f.write(decoded_image)
                end

            rescue => error
                response_internal_server_error(error)
                return
            end

            # upload to IPFS
            # nodes = @@IPFS.add(Dir.new(dir_path))

            # nodes[0] = ~~.png (file)
            # nodes[1] = ~~~ (directory)
            ret = {"node.name": nodes[0].name, "node.hash": nodes[0].hash}

            response_success('debugs', 'decode_base64_image', ret)

        else
            response_bad_request("Unsupport Content-Type")
        end
    end

    def focnft
        uid = "testuid"

        begin
            wallet_id = TapUser.find_by(uid: uid).wallet_id
            wallet = Glueby::Wallet.load(wallet_id)

            content = "shimamura"

            # issue NFT
            tokens = Glueby::Contract::Token.issue_tap_nft(wallet: wallet, prefix: '', content: content)
            token_id = 'c3' + tokens[0].color_id.payload.bth
            tx_id = tokens[1].txid

            # generate block
            generate

            # save to db
            taptoken = TapToken.create(token_id: token_id, tx_id: tx_id)
            taptoken.save

            # response
                # TODO:レスポンス何にするかは検討中
            # taptoken = TapToken.find_by(token_id:token_id)
            ret = Glueby::Internal::RPC.client.getrawtransaction(tx_id, 1)
            response_success('tokens', 'create', ret)

        # TPC不足をレスキューするよ
        rescue Glueby::Contract::Errors::InsufficientFunds
            pay2user(wallet_id, 1_000_000_000)
            retry

        # rescue => error
        #     response_internal_server_error(error)
        end
    end


    def get_data_from_tx
        txid = params[:tx_id]

        tx_payload = Glueby::Internal::RPC.client.getrawtransaction(txid, 0)
        txx = Tapyrus::Tx.parse_from_payload(tx_payload.htb)
        data = txx.outputs[1].script_pubkey.op_return_data.bth
        data = [data].pack("H*")

        response_success('tokens', 'create', data)
    end



    # def timestamp_test
    #     uid = "testuid"

    #     begin
    #         wallet_id = TapUser.find_by(uid: uid).wallet_id
    #         wallet = Glueby::Wallet.load(wallet_id)

    #         # 16進数に直してコンテンツとする
    #         content = "shimamura".unpack("H*")[0]

    #         timestamp = Glueby::Contract::Timestamp.new(wallet: wallet, content: content, digest: :none)
    #         tx = timestamp.save!
    #         puts "transaction.id = #{tx.txid}"

    #         txid = tx.txid
    #         tx_payload = Glueby::Internal::RPC.client.getrawtransaction(txid, 0)
    #         tx = Tapyrus::Tx.parse_from_payload(tx_payload.htb)
    #         data = tx.outputs[0].script_pubkey.op_return_data.bth

    #         # 取得したデータ（16進数）といれたデータ（16進数に変換）が一致するかどうか
    #         pp "shimamura".unpack("H*")[0] == data

    #         # これで復元
    #         pp [data].pack("H*")


    #         ret = Glueby::Internal::RPC.client.getrawtransaction(txid, 1)
    #         response_success('tokens', 'create', ret)

    #         # TPC不足をレスキューするよ
    #     rescue Glueby::Contract::Errors::InsufficientFunds
    #         pay2user(wallet_id, 1_000_000_000)
    #         retry
    #     end
    # end

    # def firestore
    #     service_account = "./SERVICE_ACCOUNT.json"
    #     client = Google::Cloud::Firestore.new(project_id: "tap-f4f38" ,credentials: service_account)
    #     doc_ref = client.doc("users/testfromapi")
    #     doc_snap = doc_ref.get
    #     data =doc_snap[:email]
    #     response_success('debugs','firebasestore',data)
    # end

    def uploadimage
        uri = params[:uri]
        filename = uri.split('/')[-1]
        extension = filename.split('.')[-1]

        require "google/cloud/storage"

        storage = Google::Cloud::Storage.new(
            project_id: "tap-f4f38",
            credentials: "./SERVICE_ACCOUNT.json"
        )

        bucket = storage.bucket "tap-f4f38.appspot.com"
        file = bucket.file "tmp/#{filename}"

        unless file.blank?
            if file.exists?
                token_id = "token_id"
                renamed_file = file.copy "#{token_id}.#{extension}"
                file.delete
                response_success('debugs', 'uploadimage', "ok")
            end
        else
            response_bad_request("#{uri} not found.")
        end


        # uri = URI.parse(params[:data])

        # if uri.scheme == "data" then
        #     opaque = uri.opaque
        #     data = opaque[opaque.index(",") + 1, opaque.size]
        #     image = Base64.decode64(data)

        #     opaque = uri.opaque
        #     mime_type = opaque[0, opaque.index(";")]
        #     extension = ''
        #     case mime_type
        #     when "image/png" then
        #         extension = ".png"
        #     when "image/jpeg" then
        #         extension = ".jpg"
        #     else
        #         response_bad_request("Unsupport Content-Type")
        #     end

        #     filename = Time.now.strftime("%Y%m%d-%H%M%S") + extension

        #     File.open("./cash/images/#{filename}", 'wb') do|f|
        #         f.write(image)
        #     end

        #     require "google/cloud/storage"

        #     storage = Google::Cloud::Storage.new(
        #         project_id: "tap-f4f38",
        #         credentials: "./SERVICE_ACCOUNT.json"
        #     )

        #     bucket = storage.bucket "tap-f4f38.appspot.com"
        #     bucket.create_file "./cash/images/#{filename}", "images/#{filename}"

        #     response_success('debugs','uploadimage',"#{filename}")

        # else
        #     response_bad_request("Unsupport Content-Type")
        # end
    end


    def createwallet
        wallet = Glueby::Wallet.create
        data = "created new wallet: #{wallet.id}"
        response_success('debugs','createwallet',data)
    end

    def getbalance
        data = Glueby::Wallet.load(params[:wallet_id]).balances
        response_success('debugs','getbalance',data)
    end

    def generatetoaddress
        wallet = Glueby::Wallet.load(params[:wallet_id])
        receive_address = wallet.internal_wallet.receive_address
        count = 1
        authority_key = "cUJN5RVzYWFoeY8rUztd47jzXCu1p57Ay8V7pqCzsBD3PEXN7Dd4"
        block = Glueby::Internal::RPC.client.generatetoaddress(count, receive_address, authority_key)

        system("rails glueby:block_syncer:start")

        data = "block_id:#{block}"
        response_success('debugs','generatetoaddress',data)
    end

    def getblockcount
        data = Glueby::Internal::RPC.client.getblockcount
        response_success('debugs','getblockcount',data)
    end

    def issuenft
        wallet = Glueby::Wallet.load(params[:wallet_id])
        tokens = Glueby::Contract::Token.issue!(issuer: wallet,
                                                token_type: Tapyrus::Color::TokenTypes::NFT,
                                                amount: 1)
        token_info = tokens[0]
        token_id = token_info.color_id.payload.bth
        data = "issue token: id=#{token_id}"
        response_success('debugs','issuenft',data)
    end

    def transfer
        sender = Glueby::Wallet.load(params[:sender_wallet_id])
        receiver = Glueby::Wallet.load(params[:receiver_wallet_id])

        color_id_hash = params[:token_id].to_s
        color_id = Tapyrus::Color::ColorIdentifier.parse_from_payload(color_id_hash.htb)
        token = Glueby::Contract::Token.new(color_id: color_id)
        address = receiver.internal_wallet.receive_address

        amount = 1
        (color_id_result, tx) = token.transfer!(sender: sender, receiver_address: address, amount: amount)
        puts "transfer tx=#{tx.txid}"
    end


    def getaddress
        wallet = Glueby::Wallet.load(params[:wallet_id])
        address = wallet.internal_wallet.receive_address
        data = address
        response_success('debugs','getaddress',data)
    end

    def pay2user(wallet_id, ammount)
        begin
            sender = Glueby::Wallet.load(TapUser.find_by(uid:"init").wallet_id)
            receiver = Glueby::Wallet.load(wallet_id)
            address = receiver.internal_wallet.receive_address
            tx = Glueby::Contract::Payment.transfer(sender: sender, receiver_address: address, amount: ammount)
        rescue Glueby::Contract::Errors::InsufficientFunds
            generate
            retry
        end
    end

    def generate
        wallet = Glueby::Wallet.load(TapUser.find_by(uid:"init").wallet_id)
        receive_address = wallet.internal_wallet.receive_address
        count = 1
        authority_key = "cUJN5RVzYWFoeY8rUztd47jzXCu1p57Ay8V7pqCzsBD3PEXN7Dd4"
        block = Glueby::Internal::RPC.client.generatetoaddress(count, receive_address, authority_key)
        `rails glueby:contract:block_syncer:start`
    end
end

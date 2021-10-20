class DebugsController < ApplicationController::API

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

        `rails glueby:contract:block_syncer:start`

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
end

require "google/cloud/storage"

class V2::TokensController < ApplicationController

    @@DEFAULT_RECIEVE_WALLET = ENV['DEFAULT_RECIEVE_WALLET']

    storage = Google::Cloud::Storage.new(
        project_id: "tap-f4f38",
        credentials: "./SERVICE_ACCOUNT.json"
    )

    @@bucket = storage.bucket "tap-f4f38.appspot.com"



    # get list of token
    def index
        # limit ari
        if !params[:limit].blank?
            num = params[:limit]
            response = TapToken.last(num)

        # token_id sitei
        elsif !params[:token_id].blank?
            token_id = params[:token_id]

            unless TapToken.find_by(token_id:token_id)
                response_bad_request("token_id: #{token_id} - not found.")
                return
            end

            response = TapToken.find_by(token_id:token_id)

        # nanimonai
        else
            response = TapToken.all
        end

        response_success('tokens', 'index', response)
    end


    # issue token
    def create
        uid = params[:uid]
        uri = params[:data]


        unless TapUser.find_by(uid:uid)
            response_bad_request("uid: #{uid} - not found.")
            return
        end

        # Firebase Storage
        filename = uri.split('/')[-1]
        extension = filename.split('.')[-1]
        file = @@bucket.file "tmp/#{filename}"

        if file.blank?
            response_bad_request("#{uri} not found.")
            return
        end

        unless file.exists?
            response_bad_request("#{uri} not found.")
            return
        end


        begin
            # read from db
            wallet_id = TapUser.find_by(uid: uid).wallet_id

            # issue NTF
            wallet = Glueby::Wallet.load(wallet_id)
            tokens = Glueby::Contract::Token.issue!(issuer: wallet, token_type: Tapyrus::Color::TokenTypes::NFT, amount: 1)
            token_id = tokens[0].color_id.payload.bth
            token_id = 'c3' + token_id

            # generate block
            generate

            # Firebase Storage
            renamed_file = file.copy "#{token_id}.#{extension}"
            file.delete

            # save to db
            taptoken = TapToken.create(token_id: token_id, data:"gs://tap-f4f38.appspot.com/#{token_id}.#{extension}")
            taptoken.save

            # response
            taptoken = TapToken.find_by(token_id:token_id)
            response_success('tokens', 'create', taptoken)


        # TPC不足をレスキューするよ
        rescue Glueby::Contract::Errors::InsufficientFunds
            pay2user(wallet_id, 10_000)
            retry

        rescue => error
            response_internal_server_error(error)
        end
    end


    # transfer token
    def update
        sender_uid = params[:sender_uid]
        receiver_uid = params[:receiver_uid]
        token_id = params[:token_id]


        unless TapUser.find_by(uid:sender_uid)
            response_bad_request("sender_uid: #{sender_uid} - not found.")
            return
        end

        unless TapUser.find_by(uid:receiver_uid)
            response_bad_request("receiver_uid: #{receiver_uid} - not found.")
            return
        end

        unless TapToken.find_by(token_id:token_id)
            response_bad_request("token_id: #{token_id} - not found.")
            return
        end


        begin
            # read from db
            sender_wallet_id = TapUser.find_by(uid: sender_uid).wallet_id
            receiver_wallet_id = TapUser.find_by(uid: receiver_uid).wallet_id

            # load wallet
            sender = Glueby::Wallet.load(sender_wallet_id)
            receiver = Glueby::Wallet.load(receiver_wallet_id)

            # transfer NFT
            color_id_hash = token_id.to_s
            color_id = Tapyrus::Color::ColorIdentifier.parse_from_payload(color_id_hash.htb)
            token = Glueby::Contract::Token.new(color_id: color_id)
            address = receiver.internal_wallet.receive_address

            (color_id_result, tx) = token.transfer!(sender: sender, receiver_address: address, amount: 1)

            # generate block
            generate

            # response
            response = { token_id: token_id, txid: tx.txid}
            response_success('tokens', 'update', response)


        # TPC不足をレスキューするよ
        rescue Glueby::Contract::Errors::InsufficientFunds
            pay2user(sender_wallet_id, 10_000)
            retry

        rescue => error
            response_internal_server_error(error)
        end
    end


    # burn token
    def destroy
        uid = params[:uid]
        token_id = params[:token_id]


        unless TapUser.find_by(uid:uid)
            response_bad_request("uid: #{uid} - not found.")
            return
        end

        unless TapToken.find_by(token_id:token_id)
            response_bad_request("token_id: #{token_id} - not found.")
            return
        end


        begin
            #read from db
            wallet_id = TapUser.find_by(uid: uid).wallet_id

            # load wallet
            wallet = Glueby::Wallet.load(wallet_id)

            # burn NFT
            color_id_hash = token_id.to_s
            color_id = Tapyrus::Color::ColorIdentifier.parse_from_payload(color_id_hash.htb)
            token = Glueby::Contract::Token.new(color_id: color_id)
            tx = token.burn!(sender: wallet, amount: 1)

            # generate block
            generate

            # Firebase Storage
                # TODO:デバッグしてません
                    # dbからURIもらってるのでファイルは存在する前提で処理
            filename = TapToken.find_by(token_id: token_id).data.split('/')[-1]
            file = @@bucket.file filename

            unless file.blank?
                if file.exists?
                    file.delete
                end
            # else
            #     response_bad_request("#{uri} not found.")
            end

            # destroy from db
            taptoken = TapToken.find_by(token_id: token_id)
            taptoken.destroy

            # response
            response = { token_id: token_id, txid: tx.txid }
            response_success('tokens', 'destroy', response)


        # TPC不足をレスキューするよ
        rescue Glueby::Contract::Errors::InsufficientFunds
            pay2user(wallet_id, 10_000)
            retry

        rescue => error
            response_internal_server_error(error)
        end
    end



    def pay2user(wallet_id, ammount)
        begin
            sender = Glueby::Wallet.load(@@DEFAULT_RECIEVE_WALLET)
            receiver = Glueby::Wallet.load(wallet_id)
            address = receiver.internal_wallet.receive_address
            tx = Glueby::Contract::Payment.transfer(sender: sender, receiver_address: address, amount: ammount)
        rescue Glueby::Contract::Errors::InsufficientFunds
            generate
            retry
        end
    end

    def generate
        wallet = Glueby::Wallet.load(@@DEFAULT_RECIEVE_WALLET)
        receive_address = wallet.internal_wallet.receive_address
        count = 1
        authority_key = "cUJN5RVzYWFoeY8rUztd47jzXCu1p57Ay8V7pqCzsBD3PEXN7Dd4"
        block = Glueby::Internal::RPC.client.generatetoaddress(count, receive_address, authority_key)
        `rails glueby:contract:block_syncer:start`
    end
end

require "google/cloud/storage"
require 'fileutils'

class V2::TokensController < ApplicationController

    @@DEFAULT_RECIEVE_WALLET = ENV['DEFAULT_RECIEVE_WALLET']
    @@IPFS = IPFS::Connection.new

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
        data = params[:data]    # base64 image

        daha_hash = ""


        unless TapUser.find_by(uid:uid)
            response_bad_request("uid: #{uid} - not found.")
            return
        end

        begin
            meta_data = data.match(/data:(image|application)\/(.{3,});base64,(.*)/)
            content_type = meta_data[2]
            encoded_image = meta_data[3]

            if content_type == "jpeg" || content_type == "png"
                decoded_image = Base64.strict_decode64(encoded_image)

                dir_name = "#{encoded_image[..20]}"
                file_name = "#{dir_name}.#{content_type}"

                dir_path = "#{Rails.root}/storage/images/#{dir_name}"

                begin
                    # mkdir
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
                nodes = @@IPFS.add(Dir.new(dir_path))

                # nodes[0] = ~~.png (file)
                # nodes[1] = ~~~ (directory)
                data_hash = nodes[0].hash

                # TODO:この後 pin したいが ruby-ipfs-api-client に pin 機能がなさそう。つらみ。
                    # なのでカーネルを直で実行したい所存
                sysetm("ipfs pin #{data_hash}")

                # delete files on local
                FileUtils.rm_r(dir_path)

            else
                response_bad_request("Unsupport Content-Type")
                return
            end
        rescue => error
            response_internal_server_error(error)
            return
        end

        begin
            # load wallet
            wallet_id = TapUser.find_by(uid: uid).wallet_id
            wallet = Glueby::Wallet.load(wallet_id)

            # issue NFT
            tokens = Glueby::Contract::Token.issue_tap_nft(wallet: wallet, prefix: '', content: data_hash)
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

        rescue => error
            response_internal_server_error(error)
            return
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
        `rails glueby:block_syncer:start`
    end
end

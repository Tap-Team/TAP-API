require "google/cloud/storage"

class V2::TokensController < ApplicationController

    @@DEFAULT_RECIEVE_WALLET = ENV['DEFAULT_RECIEVE_WALLET']

    def get_info(token_id)
        token = TapTokenV2.find_by(token_id:token_id)
        tx_id = token.tx_id
        data = get_data_from_tx(tx_id)
        created_at = token.created_at

        # get from IPFS
        system("ipfs get --output=#{Rails.root}/tmp/storage/images #{data}")

        # get image binary
        binary_data = File.read("#{Rails.root}/tmp/storage/images/#{data}")

        # base64 encode
        base64 = "data:image/png;base64," + Base64.strict_encode64(binary_data)

        # delete file
        File.delete("#{Rails.root}/tmp/storage/images/#{data}")

        response = {"token_id": token_id, "tx_id": tx_id, "ipfs_address": data, "base64": base64, "created_at": created_at}
        return response

    end

    # get list of token
    def index
        response = ""
        response_token_list = []
        # limit ari
        if !params[:limit].blank?
            for t in TapTokenV2.last(params[:limit])
                response_token_list.push(get_info(t.token_id))
            end

            response = response_token_list

        # token_id sitei
        elsif !params[:token_id].blank?
            token_id = params[:token_id]
            t = TapTokenV2.find_by(token_id:token_id)

            unless t
                response_bad_request("token_id: #{token_id} - not found.")
                return
            end

            response = get_info(t.token_id)

        # nanimonai
        else
            for t in TapTokenV2.all
                response_token_list.push(get_info(t.token_id))
            end
            response = response_token_list

        end

        response_success('v2/tokens', 'index', response)
    end


    # issue token
    def create
        uid = params[:uid]
        data = params[:data]    # base64 image

        # image's IPFS address
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
                # decode
                decoded_image = Base64.strict_decode64(encoded_image)

                file_name = "#{encoded_image[..20]}.#{content_type}"
                dir_path = "#{Rails.root}/tmp/storage/images"

                # tmp store
                begin
                    open("#{dir_path}/#{file_name}", 'wb') do |f|
                        f.write(decoded_image)
                    end
                rescue => error
                    response_internal_server_error(error)
                    return
                end

                # upload to IPFS
                ret = `ipfs add #{dir_path}/#{file_name}`   # ex) ret = "added <address> <filename>"
                data_hash = ret.split(" ")[1]

                # pin
                system("ipfs pin add #{data_hash}")

                # delete files on local
                File.delete("#{dir_path}/#{file_name}")

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
            taptoken = TapTokenV2.create(token_id: token_id, tx_id: tx_id)
            taptoken.save

            # response
                # TODO:レスポンス何にするかは検討中
            # taptoken = TapTokenV2.find_by(token_id:token_id)
            ret = Glueby::Internal::RPC.client.getrawtransaction(tx_id, 1)
            response_success('v2/tokens', 'create', ret)

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

        unless TapTokenV2.find_by(token_id:token_id)
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
            response_success('v2/tokens', 'update', response)


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

        unless TapTokenV2.find_by(token_id:token_id)
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
            taptoken = TapTokenV2.find_by(token_id: token_id)
            taptoken.destroy

            # response
            response = { token_id: token_id, txid: tx.txid }
            response_success('v2/tokens', 'destroy', response)


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

    def get_data_from_tx(tx_id)
        tx_payload = Glueby::Internal::RPC.client.getrawtransaction(tx_id, 0)
        txx = Tapyrus::Tx.parse_from_payload(tx_payload.htb)
        data = txx.outputs[1].script_pubkey.op_return_data.bth
        data = [data].pack("H*")
        return data
    end

end

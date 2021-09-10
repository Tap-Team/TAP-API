class TokensController < ApplicationController

    # get list of NFT
        # TOOD:このままだとエグい量返されて大変だから数指定できるようにしたいね。
    def index
        begin
            taptokens = TapToken.all
            response_success('users','create',taptokens)
        rescue => error
            response_internal_server_error(error)
        end
    end

    # issue NFT
    def create
        uid = params[:uid]
        data = params[:data]

        begin
            # read from db
            wallet_id = TapUser.find_by(uid: uid).wallet_id

            # issue NTF
            wallet = Glueby::Wallet.load(wallet_id)
            tokens = Glueby::Contract::Token.issue!(issuer: wallet, token_type: Tapyrus::Color::TokenTypes::NFT, amount: 1)
            token_id = tokens[0].color_id.payload.bth

            # save to db
            taptoken = TapToken.create(token_id:token_id, data:data)
            taptoken.save

            # response
            response_success('tokens','create',"{ token_id: #{token_id} }")

        rescue => error
            response_internal_server_error(error)
        end
    end

    # transfer NFT
    def update
        sender_uid = params[:sender_uid]
        receive_uid = params[:receive_uid]
        token_id = params[:token_id]

        begin
            # read from db
            sender_wallet_id = get_wallet_id_from_uid(sender_uid)
            receiver_wallet_id = get_wallet_id_from_uid(receive_uid)

            # load wallet
            sender = Glueby::Wallet.load(sender_wallet_id)
            receiver = Glueby::Wallet.load(receiver_wallet_id)

            # transfer NFT
            color_id_hash = token_id.to_s
            color_id = Tapyrus::Color::ColorIdentifier.parse_from_payload(color_id_hash.htb)
            token = Glueby::Contract::Token.new(color_id: color_id)
            address = receiver.internal_wallet.receive_address

            (color_id_result, tx) = token.transfer!(sender: sender, receiver_address: address, amount: 1)

            # response
            response_success('tokens','update',"{ token_id: #{token_id}, txid: #{tx.txid} }")

        rescue => error
            response_internal_server_error(error)
        end
    end

    # burn NFT
    def destroy
        uid = params[:uid]
        token_id = params[:token_id]

        begin
            #read from db
            wallet_id = get_wallet_id_from_uid(uid)

            # load wallet
            wallet = Glueby::Wallet.load(wallet_id)

            # burn NFT
            color_id_hash = token_id.to_s
            color_id = Tapyrus::Color::ColorIdentifier.parse_from_payload(color_id_hash.htb)
            token = Glueby::Contract::Token.new(color_id: color_id)
            tx = token.burn!(sender: wallet, amount: 1)

            # destroy from db
            taptoken = TapToken.find_by(uid: uid)
            taptoken.destroy

            # response
            response_success('tokens','destroy',"{ token_id: #{token_id}, txid: #{tx.txid} }")

        rescue => error
            response_internal_server_error(error)
        end
    end



    def get_wallet_id_from_uid(uid)
        return TapUser.find_by(uid: uid).wallet_id
    end
end

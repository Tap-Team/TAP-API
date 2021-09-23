class UsersController < ApplicationController

    # get list of user
    def index
        if params[:num].blank?
            tapusers = TapUser.all
        else
            num = params[:num]
            tapusers = TapUser.last(num)
        end
        response_success('tokens','index',tapusers)
    end


    # get info of each user
    def info
        begin
            uid = params[:uid]

            tapuser = TapUser.find_by(uid:uid)
            wallet_id = tapuser.wallet_id
            created_at = tapuser.created_at
            updated_at = tapuser.updated_at

            # get balance
            wallet_id = TapUser.find_by(uid: uid).wallet_id
            wallet = Glueby::Wallet.load(wallet_id)
            balances = wallet.balances

            # token nomi tyuusyutu
            token_ids = balances.keys.reject(&:blank?)

            # response
            response =  { uid: uid, wallet_id: wallet_id, created_at: created_at, updated_at: updated_at, tokens: token_ids }

            response_success("users", "index/#{uid}", response)

        rescue => error
            response_internal_server_error(error)
        end
    end


    # create user
    def create
        uid = params[:uid]

        if TapUser.find_by(uid:uid)
            response_bad_request("uid: \"#{uid}\" is already registerd.")
            return
        end

        begin
            # create wallet
            wallet = Glueby::Wallet.create

            # save to db
            tapuser = TapUser.create(uid:uid, wallet_id:wallet.id)
            tapuser.save

            response_success('users','create')

        rescue => error
            response_internal_server_error(error)
        end
    end


    # update user
        # NOTE: NOT SUPORT OFFICIALY
    def update
        uid = params[:uid]
        wallet_id = params[:wallet_id]

        begin
            # search from db
            tapuser = TapUser.find_by(uid: uid)

            # update db
            tapuser.update(wallet_id: wallet_id)

            response_success('users','update')

        rescue => error
            response_internal_server_error(error)
        end
    end


    # delete user
        # NOTE: NOT DELETE WALLET
    def destroy
        uid = params[:uid]

        begin
            # search from db
            tapuser = TapUser.find_by(uid: uid)

            # delete from db
            tapuser.destroy

            response_success('users','destroy')

        rescue => error
            response_internal_server_error(error)
        end
    end
end

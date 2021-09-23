class UsersController < ApplicationController

    # get list of User
        # NOTE: いつ使うんこれ
    def index
        # 全表示
        if params[:uid].blank?
            begin
                tapusers = TapUser.all
                response_success('users','index',tapusers)
            rescue => error
                response_internal_server_error(error)
            end
        else
            begin
                uid = params[:uid]
                wallet_id = TapUser.find_by(uid: uid).wallet_id
                wallet = Glueby::Wallet.load(wallet_id)
                balances = wallet.balances
                token_ids = balances.keys.reject(&:blank?)
                response_success("users", "index/#{uid}", token_ids)
            rescue => error
                response_internal_server_error(error)
            end
        end
    end


    # create User
    def create
        uid = params[:uid]

        if TapUser.find_by(uid:uid)
            response_bad_request("uid: \"#{uid}\" is already registerd.")
            return
        end

        begin
            wallet = Glueby::Wallet.create

            tapuser = TapUser.create(uid:uid, wallet_id:wallet.id)
            tapuser.save

            response_success('users','create')

        rescue => error
            response_internal_server_error(error)
        end
    end


    # update User
        # NOTE: NOT SUPORT OFFICIALY
    def update
        uid = params[:uid]
        wallet_id = params[:wallet_id]

        begin
            tapuser = TapUser.find_by(uid: uid)
            tapuser.update(wallet_id: wallet_id)

            response_success('users','update')

        rescue => error
            response_internal_server_error(error)
        end
    end


    # delete User
        # NOTE: NOT DELETE WALLET, BUT BURN ALL TOKENS
    def destroy
        uid = params[:uid]

        begin
            tapuser = TapUser.find_by(uid: uid)
            tapuser.destroy

            response_success('users','destroy')

        rescue => error
            response_internal_server_error(error)
        end
    end
end

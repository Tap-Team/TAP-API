class UsersController < ApplicationController

    # get list of User
        # NOTE: いつ使うんこれ
    def index
        begin
            tapusers = TapUser.all
            response_success('users','create',tapusers)
        rescue => error
            response_internal_server_error(error)
        end
    end


    # create User
    def create
        uid = params[:uid]

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

class UsersController < ApplicationController::API

    @@client = Google::Apis::IdentitytoolkitV3::IdentityToolkitService.new
    @@client.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open("./SERVICE_ACCOUNT.json"),
        scope: 'https://www.googleapis.com/auth/identitytoolkit'
    )
    # check auth
    def check_auth(uid)
        request = Google::Apis::IdentitytoolkitV3::GetAccountInfoRequest.new(local_id: [uid])
        account = @@client.get_account_info(request)

        unless account.users.nil?
            return true
        else
            return false
        end
    end


    # get list of user
    def index
        # limit ari
        if !params[:limit].blank?
            num = params[:limit]
            response = TapUser.last(num)

        # uid sitei
        elsif !params[:uid].blank?
            uid = params[:uid]

            unless TapUser.find_by(uid:uid)
                response_bad_request("uid: #{uid} - not found.")
                return
            end

            begin
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

            rescue => error
                response_internal_server_error(error)
            end

        # nanimo nai
        else
            response = TapUser.all
        end

        response_success('users','index',response)
    end


    # create user
    def create
        uid = params[:uid]

        if TapUser.find_by(uid:uid)
            response_bad_request("uid: #{uid} - already registerd.")
            return
        end

        # firebase auth
        unless check_auth(uid)
            response_bad_request("uid: #{uid} - doesn't exist on auth.")
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

        unless TapUser.find_by(uid:uid)
            response_bad_request("uid: #{uid} - not found.")
            return
        end

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

        unless TapUser.find_by(uid:uid)
            response_bad_request("uid: #{uid} - not found.")
            return
        end

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

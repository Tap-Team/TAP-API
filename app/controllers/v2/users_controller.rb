class V2::UsersController < ApplicationController

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

    # get info
    def get_info(tap_user)
        # get params
        uid = tap_user.uid
        wallet_id = tap_user.wallet_id
        created_at = tap_user.created_at

        # get balance and get token_ids
        wallet = Glueby::Wallet.load(wallet_id)
        balances = wallet.balances
        token_ids = balances.keys.reject(&:blank?)

        response =  { uid: uid, wallet_id: wallet_id, tokens: token_ids, created_at: created_at }
        return response
    end


    # get list of user
    def index
        response = []

        # uid sitei
        if !params[:uid].blank?
            # get user
            tap_user = TapUser.find_by(uid:params[:uid])
            # 404
            if tap_user.nil?
                response_bad_request("uid: #{uid} - not found.")
                return
            end
            response = get_info(tap_user)

        # limit
        elsif !params[:limit].blank?
            for tap_user in TapUser.last(params[:limit])
                response.push(get_info(tap_user))
            end

        # all
        else
            for tap_user in TapUser.all
                response.push(get_info(tap_user))
            end
        end

        response_success('users','index',response)
    end


    # create user
    def create
        uid = params[:uid]

        if TapUser.find_by(uid:uid)
            response_conflict("User Create", "uid: #{uid} - already registerd.")
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
            tap_user = TapUser.create(uid:uid, wallet_id:wallet.id)
            tap_user.save

            # response
            response = get_info(tap_user)
            response_success('users','create', response)

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
            tap_user = TapUser.find_by(uid: uid)

            # update db
            tap_user.update(wallet_id: wallet_id)

            # response
            response = get_info(tap_user)
            response_success('users','update', response)

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
            tap_user = TapUser.find_by(uid: uid)

            # delete from db
            tap_user.destroy

            # response
            response_success('users','destroy')

        rescue => error
            response_internal_server_error(error)
        end
    end
end
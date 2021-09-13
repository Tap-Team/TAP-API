namespace :init do
    desc "walletを生成する"
    task :create => :environment do |task, args|

        # wallet
        wallet = Glueby::Wallet.create
        address = wallet.internal_wallet.receive_address

        # .env
        File.open("./.env", mode = "w"){|f|
            f.write("DEFAULT_RECIEVE_WALLET = \'#{wallet.id}\'")
        }

        # generate
        receive_address = wallet.internal_wallet.receive_address
        count = 1
        authority_key = "cUJN5RVzYWFoeY8rUztd47jzXCu1p57Ay8V7pqCzsBD3PEXN7Dd4"
        block = Glueby::Internal::RPC.client.generatetoaddress(count, receive_address, authority_key)
        `rails glueby:contract:block_syncer:start`

        # create tap user
        tapuser = TapUser.create(uid: 'init', wallet_id: wallet.id)
        tapuser.save

        # output
        puts "wallet.id: #{wallet.id}"
        puts "address: #{address}"
        puts "wallet.balances: #{wallet.balances}"
        puts "block count: #{Glueby::Internal::RPC.client.getblockcount}"
    end

    desc "残高確認"
    task :getbalance => :environment do |task, args|
        wallet_id = ENV['DEFAULT_RECIEVE_WALLET']
        wallet = Glueby::Wallet.load(wallet_id)
        puts wallet.balances
    end
end

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
        count = 1
        authority_key = "cUJN5RVzYWFoeY8rUztd47jzXCu1p57Ay8V7pqCzsBD3PEXN7Dd4"
        block = Glueby::Internal::RPC.client.generatetoaddress(count, address, authority_key)
        `rails glueby:contract:block_syncer:start`

        # create tap user
        tapuser = TapUser.create(uid: 'init', wallet_id: wallet.id)
        tapuser.save

        # output
        puts "wallet.id: #{wallet.id}"
        puts "address: #{address}"
        puts "wallet.balances: #{wallet.balances}"
        puts "block count: #{Glueby::Internal::RPC.client.getblockcount}"

        puts ""
        puts "=================================CAUTION================================="
        puts "The .env file has been generated, but rails has not loaded it yet."
        puts "Restart the rails app for the changes or initialization to take effect."
        puts ""
        puts "If you use systemd, run `systemctl restart <app-name>`"
        puts ""
    end

    desc "残高確認"
    task :getbalance => :environment do |task, args|
        wallet_id = ENV['DEFAULT_RECIEVE_WALLET']
        wallet = Glueby::Wallet.load(wallet_id)
        puts wallet.balances
    end

    desc "debug"
    task :debug => :environment do |task, args|
        synced_block = Glueby::AR::SystemInformation.synced_block_height
        puts "synced_block: #{synced_block}"
    end

    namespace :glueby do
        namespace :block_syncer do
            desc 'sync block into database'
            task :start, [] => [:environment] do |_, _|
                latest_block_num = Glueby::Internal::RPC.client.getblockcount
                synced_block = Glueby::AR::SystemInformation.synced_block_height


                # ====== patch ======

                if synced_block.nil?
                    synced_block = Glueby::AR::SystemInformation.create(info_key: "synced_block_number", info_value: 0)
                end

                # ====== end ======


                (synced_block.int_value + 1..latest_block_num).each do |height|
                    ::ActiveRecord::Base.transaction do
                        Glueby::BlockSyncer.new(height).run
                        synced_block.update(info_value: height.to_s)
                    end
                    puts "success in synchronization (block height=#{height})"
                end
            end
        end
    end
end

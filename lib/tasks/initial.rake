namespace :initial do
    desc "walletを生成する"
    task :createwallet => :environment do |task, args|
        wallet = Glueby::Wallet.create
        puts "wallet_id: #{wallet.id}"
        address = wallet.internal_wallet.receive_address
        puts "address: #{address}"
    end

    desc "残高確認"
    task :getbalance => :environment do |task, args|
        wallet_id = "KOKO_NI_WALLET_ID_WO_NYUURYOKU"
        wallet = Glueby::Wallet.load(wallet_id)
        puts wallet.balances
    end
end

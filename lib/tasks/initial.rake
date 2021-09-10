namespace :initial do
    desc "walletを生成する"
    task :createwallet => :environment do |task, args|
        wallet = Glueby::Wallet.create
        wallet.balances
        address = wallet.internal_wallet.receive_address
        puts address
    end
end

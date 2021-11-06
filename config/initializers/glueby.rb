# Edit configuration for connection to tapyrus core
Tapyrus.chain_params = :dev
Glueby.configure do |config|
  config.wallet_adapter = :activerecord
  config.rpc_config = { schema: 'http', host: 'tapyrusd', port: 12381, user: 'rpcuser', password: 'rpcpassword' }
end

# Uncomment next line when using timestamp feature
# Glueby::BlockSyncer.register_syncer(Glueby::Contract::Timestamp::Syncer)

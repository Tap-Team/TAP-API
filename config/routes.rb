Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  get 'debugs/createwallet', to: 'debugs#createwallet'
  get 'debugs/getbalance', to: 'debugs#getbalance'
  get 'debugs/getblockcount', to: 'debugs#getblockcount'
  get 'debugs/generatetoaddress', to: 'debugs#generatetoaddress'
  get 'debugs/issuenft', to: 'debugs#issuenft'
  get 'debugs/getaddress', to: 'debugs#getaddress'


  get 'debugs/firestore', to: 'debugs#firestore'

end

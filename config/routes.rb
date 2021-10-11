Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  # debugs
  get 'debugs/createwallet', to: 'debugs#createwallet'
  get 'debugs/getbalance', to: 'debugs#getbalance'
  get 'debugs/getblockcount', to: 'debugs#getblockcount'
  get 'debugs/generatetoaddress', to: 'debugs#generatetoaddress'
  get 'debugs/issuenft', to: 'debugs#issuenft'
  get 'debugs/getaddress', to: 'debugs#getaddress'

  get 'debugs/firestore', to: 'debugs#firestore'

  post 'debugs/uploadimage', to: 'debugs#uploadimage'

  get 'debugs/focnft', to: 'debugs#focnft'
  get 'debugs/getdata', to: 'debugs#get_data_from_tx'

  # users
  get 'users/(:uid)', to: 'users#index'
  post 'users', to: 'users#create'
  put 'users/:uid', to: 'users#update'
  delete 'users/:uid', to: 'users#destroy'

  # tokens
  get 'tokens/(:token_id)', to: 'tokens#index'
  post 'tokens', to: 'tokens#create'
  put 'tokens/:token_id', to: 'tokens#update'
  delete 'tokens/:token_id', to: 'tokens#destroy'

end

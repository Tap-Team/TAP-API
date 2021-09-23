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

  # users
  get 'users/(:num)', to: 'users#index'
  get 'users/info/:uid', to: 'users#info'
  post 'users', to: 'users#create'
  put 'users/:uid', to: 'users#update'
  delete 'users/:uid', to: 'users#destroy'

  # tokens
  get 'tokens/(:num)', to: 'tokens#index'
  get 'tokens/info/:token_id', to: 'tokens#info'
  post 'tokens', to: 'tokens#create'
  put 'tokens/:uid', to: 'tokens#update'
  delete 'tokens/:uid', to: 'tokens#destroy'

end

## install

1. git clone
2. bundle install
3. run [Glueby's init process](https://github.com/chaintope/glueby#setup-for-ruby-on-rails-application-development)
4. run `rails init:create`
5. mkdir `tmp/storage/images`


## reset
1. shutdown rails app
2. run `rails init:reset`
3. run `rails init:create`


## reset (production)
1. shutdown rails app
2. run `rails init:reset RAILS_ENV=production`
3. run `rails init:create RAILS_ENV=production`
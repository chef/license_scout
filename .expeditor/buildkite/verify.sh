ruby --version
bundler --version
bundle config set path 'vendor/bundle'
bundle install
curl https://sh.rustup.rs -sSf | sh -s -- -y
. $HOME/.cargo/env
bundle exec rake
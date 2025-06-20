# We currently use asdf to manage versions
export ASDF_RUBY_VERSION=$(cat .ruby-version)
ruby --version
bundler --version
sudo apt install libgit2-dev cmake pkg-config
bundle config set path 'vendor/bundle'
bundle install
curl https://sh.rustup.rs -sSf | sh -s -- -y
. $HOME/.cargo/env
bundle exec rake
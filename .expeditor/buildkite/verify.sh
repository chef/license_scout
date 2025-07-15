# We currently use asdf to manage versions
export ASDF_RUBY_VERSION=$(cat .ruby-version)
asdf install ruby "$ASDF_RUBY_VERSION"
asdf local ruby "$ASDF_RUBY_VERSION"
ruby --version
bundler --version
bundle config set path 'vendor/bundle'
bundle install
curl https://sh.rustup.rs -sSf | sh -s -- -y
. $HOME/.cargo/env
bundle exec rake
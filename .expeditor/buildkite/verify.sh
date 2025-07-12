# We currently use asdf to manage versions
export ASDF_RUBY_VERSION=$(cat .ruby-version)
ruby --version
bundler --version
bundle config set path 'vendor/bundle'
bundle install
curl https://sh.rustup.rs -sSf | sh -s -- -y
. $HOME/.cargo/env
bundle exec rake

# We currently use asdf to manage versions
# export ASDF_RUBY_VERSION=$(cat .ruby-version)
# ruby --version
# bundler --version
# bundle config set path 'vendor/bundle'
# bundle install

# # Install Rust (required for some dependencies)
# curl https://sh.rustup.rs -sSf | sh -s -- -y
# . $HOME/.cargo/env

# # Install rebar3
# echo "Installing rebar3..."
# curl -fsSL https://get.rebar3.org | bash
# chmod +x rebar3
# mv rebar3 /usr/local/bin/
# rebar3 --version

# # Run the tests
# bundle exec rake
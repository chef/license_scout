# We currently use asdf to manage versions
# Install asdf if not present
if ! command -v asdf >/dev/null 2>&1; then
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.16.1
  . "$HOME/.asdf/asdf.sh"
fi

# Add asdf to PATH and source it
. "$HOME/.asdf/asdf.sh"

export ASDF_RUBY_VERSION=$(cat .ruby-version)
ruby --version
bundler --version
bundle config set path 'vendor/bundle'
bundle install
curl https://sh.rustup.rs -sSf | sh -s -- -y
. $HOME/.cargo/env
bundle exec rake
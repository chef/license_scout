FROM ruby:2.3

COPY ./bin /usr/src/license_scout/bin
COPY ./lib /usr/src/license_scout/lib
COPY Gemfile Rakefile license_scout.gemspec /usr/src/license_scout/

WORKDIR /usr/src/license_scout
RUN bundle install

ENTRYPOINT ["license_scout"]

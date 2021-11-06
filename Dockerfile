FROM ruby:3.0.1

RUN apt-get update -qq && \
    apt-get install -y build-essential \
                       nodejs

RUN mkdir /tap-api
WORKDIR /tap-api

COPY Gemfile /tap-api/Gemfile
COPY Gemfile.lock /tap-api/Gemfile.lock

RUN bundle install

COPY . /tap-api


CMD ["rails", "s", "-b", "0.0.0.0"]
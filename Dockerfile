FROM ruby:3.0.2-alpine3.14

RUN apk --update add --no-cache --virtual run-dependencies build-base git

COPY LICENSE.md README.md /

COPY Gemfile /
RUN bundle

COPY entrypoint.rb /
RUN chmod +x /entrypoint.rb

ENTRYPOINT ["/entrypoint.rb"]
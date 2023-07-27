FROM ruby:3.0.6-alpine
MAINTAINER Yohann Leon <yohann@leon.re>

WORKDIR /usr/atom

RUN apk add --update tzdata curl wget bash ruby ruby-bundler nodejs ruby-dev g++ musl-dev make imagemagick imagemagick-dev patch
RUN gem install bundler smashing json
RUN cp /usr/share/zoneinfo/Europe/Paris /etc/localtime && echo "Europe/Paris" > /etc/timezone

COPY Gemfile Gemfile.lock /usr/atom

RUN bundle

COPY . /usr/atom

ENV PORT 3030
EXPOSE $PORT

ENTRYPOINT ["smashing"]
CMD ["start", "-p", "$PORT", "-e", "production"]

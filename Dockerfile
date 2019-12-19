FROM ruby:latest
ENV LANG C.UTF-8
WORKDIR /app
COPY . /app
RUN cat sources.list > /etc/apt/sources.list;\
    git pull;\
    apt-get update;\
    apt-get install sqlite3;\
    bundle install
EXPOSE 4567
CMD ["ruby","main.rb"]

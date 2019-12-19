FROM ruby:latest
ENV LANG C.UTF-8
WORKDIR /app
COPY . /app
RUN git pull
RUN apt-get install sqlite3
RUN bundle install
EXPOSE 4567
CMD ["ruby","main.rb"]

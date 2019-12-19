FROM ruby:latest
ENV LANG C.UTF-8
WORKDIR /app
COPY . /app
RUN bundle install
EXPOSE 4567
CMD ["ruby","main.rb"]

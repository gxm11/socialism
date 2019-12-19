FROM ruby:2.6
ENV LANG C.UTF-8
WORKDIR /app
COPY . /app
RUN git pull
RUN bundle install
EXPOSE 4567
CMD ["ruby","main.rb"]

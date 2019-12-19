FROM ruby:2.6
ENV LANG C.UTF-8
WORKDIR /app
RUN git clone https://github.com/gxm11/socialism.git .
RUN bundle install
EXPOSE 4567
CMD ["ruby","main.rb"]

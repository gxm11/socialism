FROM ruby:2.6
ENV LANG C.UTF-8
WORKDIR /app
COPY . /app
# bash -c "git clone http://github.com/gxm11/socialism.git . && bundle install && ruby main.rb"
# RUN git clone http://github.com/gxm11/socialism.git .
RUN bundle install
EXPOSE 4567
CMD ["ruby","main.rb"]

FROM jekyll/jekyll:3.8

RUN   apk update && \
      apk upgrade && \
      apk add --no-cache ruby-dev make gcc libc-dev python  py-pygments && \
      gem install jekyll -v 3.9.3 && \
      gem install pygments.rb redcarpet && \
      apk del ruby-dev make gcc libc-dev && \
      gem install redcarpet kramdown-parser-gfm && \
      rm -rf /var/cache/apk/*


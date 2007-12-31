CC=g++
RUBY=/usr/local/bin/ruby


default: build

rdoc: 
	rdoc --op doc/rdoc --accessor property=Property,method=C++Method

build:  clean
	mkdir -p work
	${RUBY} yinspire.rb

clean:
	rm -rf work doc/rdoc

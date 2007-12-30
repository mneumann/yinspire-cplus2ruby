CC=g++
RUBY=/usr/local/bin/ruby

default: build

build:  clean
	mkdir -p work
	${RUBY} yinspire.rb

clean:
	rm -rf work

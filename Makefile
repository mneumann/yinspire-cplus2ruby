CC=g++
RUBY=/usr/local/bin/ruby19

build:  clean
	mkdir -p work
	${RUBY} yinspire.rb

clean:
	rm -rf work

CC=g++
CFLAGS=-no-integrated-cpp -B ${PWD}/tools -O3 -Winline -Wall -I${PWD}
RUBY=${HOME}/Work/usr.current/bin/ruby

default: build

codegen:
	${RUBY} yinspire.rb

build: codegen
	${CC} ${CFLAGS} `find . -name '*.cc'` -o yinspire ${LDFLAGS}

clean:
	rm -f yinspire

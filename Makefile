CC=g++

#RBDIR=${HOME}/Work/usr.current
RBDIR=/usr/local
RUBY_CFLAGS=-I${RBDIR}/include/ruby-1.9.0 -I${RBDIR}/include/ruby-1.9.0/x86_64-freebsd8.0
CFLAGS=-fPIC -no-integrated-cpp -B ${PWD}/tools -O3 -Winline -Wall -I${PWD} -I${PWD}/work ${RUBY_CFLAGS}
RUBY=${RBDIR}/bin/ruby19

#default: build

codegen: build_json
	mkdir -p work
	${RUBY} yinspire.rb

run: codegen
	time ${RUBY} run.rb 10_000 0.00

build_json:
	${CC} ${CFLAGS} -c `find json -name '*.cc'` 

#build: codegen
#	${CC} ${CFLAGS} `find work -name '*.cc'` -o yinspire ${LDFLAGS}

clean:
	rm -rf work *.o

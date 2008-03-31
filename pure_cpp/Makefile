CC=g++
#PROFILE=-O0 -pg -g
CFLAGS=-DNDEBUG -O3 -Winline -Wall -DWITHOUT_MMAP -I${PWD}/src

DEPS=src/algo/binary_heap.h src/algo/indexed_binary_heap.h src/memory_allocator.h \
     src/neuron.h src/neuron_srm_01.h src/simulator.h \
     src/synapse.h src/types.h \
     src/neural_entity.cc src/neuron.cc src/neuron_srm_01.cc \
     src/simulator.cc src/synapse.cc \
     src/main.cc \
     src/json/json.h src/json/json_parser.h src/json/json.cc src/json/json_parser.cc \
     Makefile

inspire: ${DEPS}
	${CC} ${CFLAGS} `find src -name '*.cc'` -o inspire ${LDFLAGS}

src/json/json_parser.cc: src/json/json_parser.rl
	ragel src/json/json_parser.rl | rlgen-cd -o src/json/json_parser.cc

clean:
	rm -f inspire


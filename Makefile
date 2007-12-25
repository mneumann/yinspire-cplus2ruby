RUBY=${HOME}/Work/usr.opt/bin/ruby

build:
	${RUBY} run.rb

run0: build
	time ${RUBY} run.rb 0

run1000: build
	time ${RUBY} run.rb 1000

run10000: build
	time ${RUBY} run.rb 10000

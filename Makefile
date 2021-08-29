# Makefile for building Love artefacts

releases:
	boon build . --target all

build:
	zip -9 -r Breakout.love README.md fonts graphics images \
				lib sounds src main.lua

clean:
	rm -f Breakout.love


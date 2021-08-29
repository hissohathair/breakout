# Makefile for building Love artefacts

release:
	boon build .

build:
	zip -9 -r Breakout.love README.md fonts graphics images \
				lib sounds src main.lua

clean:
	rm -f Breakout.love


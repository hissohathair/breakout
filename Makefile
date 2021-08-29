# Makefile for building Love artefacts

releases:
	boon build . --target all
	zip -q -9 -r "release/Breakout CS50G-macOS.zip" "release/Breakout CS50G.app"

clean:
	rm -f release/*


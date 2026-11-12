PROJECT := DevPreview.xcodeproj
CONFIGURATION ?= Release

.PHONY: build install uninstall icon project open clean

build:
	CONFIGURATION=$(CONFIGURATION) ./scripts/build.sh

install:
	CONFIGURATION=$(CONFIGURATION) ./scripts/install.sh

uninstall:
	./scripts/uninstall.sh

icon:
	swift scripts/generate_icon.swift

project:
	python3 scripts/generate_xcodeproj.py

open:
	open $(PROJECT)

clean:
	rm -rf build

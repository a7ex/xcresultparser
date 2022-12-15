prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox --arch arm64 --arch x86_64

install: build
	install -d "$(bindir)"
	install ".build/apple/Products/Release/xcresultparser" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/xcresultparser"

clean:
	rm -rf .build

.PHONY: build install uninstall clean

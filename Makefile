prefix ?= /usr/local
bindir = $(prefix)/bin

BUILD_ARGS = -c release --disable-sandbox --arch arm64 --arch x86_64

build:
	swift build $(BUILD_ARGS)

# The universal build output moved from .build/apple to .build/out in Swift 6.4, so ask SwiftPM.
install: build
	install -d "$(bindir)"
	install "$$(swift build $(BUILD_ARGS) --show-bin-path)/xcresultparser" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/xcresultparser"

clean:
	rm -rf .build

.PHONY: build install uninstall clean

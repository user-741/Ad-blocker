PREFIX := /usr/local
BINDIR := $(PREFIX)/bin

VERSION = 2025.1

.PHONY: install uninstall clean

install:
	@echo "Installing AdBlocker v$(VERSION)..."
	@chmod +x installer.sh blocker.sh updater.sh uninstaller.sh
	@echo "✅ Ready! Now run: sudo ./installer.sh"

uninstall:
	@if [ -f /opt/adblocker/uninstaller.sh ]; then \
		sudo /opt/adblocker/uninstaller.sh; \
	else \
		echo "❌ AdBlocker not installed or already removed"; \
	fi

clean:
	@rm -f *.deb
	@rm -rf build/

package: clean
	@mkdir -p build/Ad-blocker
	@cp -r *.sh Makefile README.md blocklists config src build/Ad-blocker/
	@echo "📦 Package ready in build/Ad-blocker/"

.DEFAULT_GOAL := install

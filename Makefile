PREFIX := /usr/local
BINDIR := $(PREFIX)/bin
SYSDIR := /etc/systemd/system

install:
	@echo "Installing AdBlocker..."
	mkdir -p /opt/adblocker
	mkdir -p /etc/adblocker
	cp -r src/*.sh /opt/adblocker/
	cp -r config/* /etc/adblocker/
	cp -r blocklists/* /opt/adblocker/
	chmod +x /opt/adblocker/*.sh
	ln -sf /opt/adblocker/blocker.sh $(BINDIR)/adblocker
	ln -sf /opt/adblocker/updater.sh $(BINDIR)/adblocker-update
	@echo "✅ Now run: sudo /opt/adblocker/installer.sh"

uninstall:
	/opt/adblocker/uninstaller.sh

clean:
	rm -f $(BINDIR)/adblocker
	rm -f $(BINDIR)/adblocker-update

.PHONY: install uninstall clean

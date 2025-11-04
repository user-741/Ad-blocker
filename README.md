# Raspberry Pi AdBlocker

Network-wide ad blocking using DNS. Set it up once, block ads on all devices.

## Quick Install

```bash
git clone https://github.com/user-741/Ad-blocker
cd Ad-blocker
sudo make install
sudo /opt/adblocker/installer.sh

sudo adblocker start     # Start blocking
sudo adblocker stop      # Stop blocking  
sudo adblocker status    # Check status
sudo adblocker-update    # Update blocklists

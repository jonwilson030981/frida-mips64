source ~/.gdbinit-gef.py
set sysroot /home/build/x-tools/mips64-unknown-linux-gnu/mips64-unknown-linux-gnu/sysroot
target extended-remote localhost:3000
remote put /home/build/x-tools/mips64-unknown-linux-gnu/mips64-unknown-linux-gnu/sysroot/root/gum-tests /root/gum-tests
remote put /home/build/x-tools/mips64-unknown-linux-gnu/mips64-unknown-linux-gnu/sysroot/root/run.sh /root/run.sh
remote put /home/build/x-tools/mips64-unknown-linux-gnu/mips64-unknown-linux-gnu/sysroot/root/targetfunctions-linux-mips64.so /root/targetfunctions-linux-mips64.so
remote put /home/build/x-tools/mips64-unknown-linux-gnu/mips64-unknown-linux-gnu/sysroot/root/specialfunctions-linux-mips64.so /root/specialfunctions-linux-mips64.so
remote put /home/build/x-tools/mips64-unknown-linux-gnu/mips64-unknown-linux-gnu/sysroot/root/test /root/test
set remote exec-file /root/test
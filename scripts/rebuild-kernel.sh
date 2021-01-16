mount -U "[partition id]" /boot
make modules_prepare
make -j8 && make modules_install && make install
emerge @module-rebuild
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=x86_64 --efi-directory=/boot --bootloader-id=grub --recheck
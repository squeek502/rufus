An attempt at porting Rufus to the Zig build system and getting cross-compilation (including `.rc` and embedded `.manifest`) to work.

This will currently succeed on any host system:

```
git clone https://github.com/squeek502/rufus
cd rufus
zig build -Dtarget=x86_64-windows-gnu
```

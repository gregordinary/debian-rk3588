## Linux Device Tree for the NanoPi R6S

<br/>

**build device the tree for the nanopi-r6s**
```
sh make_dtb.sh
```

<i>the build will produce the target file rk3588s-nanopi-r6s.dtb</i>

<br/>

**optional: create symbolic links**
```
sh make_dtb.sh links
```

<i>convenience link to rk3588s-nanopi-r6s.dts and other relevant device tree files will be created in the project directory</i>

<br/>

**optional: clean target**
```
sh make_dtb.sh clean
```

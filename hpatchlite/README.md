# hpatchlite

HPatchLite's patch applier: the device half of the DELTA form in
`iotdata-common/include/iotdata_node_content_ota.h`. Four files, MIT licence, no dependencies
beyond the standard headers.

## Why it is vendored rather than a submodule

Everything else in iotdata-depend is a submodule of one of our own repositories. This is somebody
else's code, it is four files and under 600 lines, and what we need from it is frozen at a known
commit -- so it is copied with its provenance recorded here. Make it a fork and a submodule the day
we need to change it.

| | |
|---|---|
| upstream | https://github.com/sisong/HPatchLite |
| HPatchLite commit | `73ba445c5d175186eb3d69df4dfd596c5dae9d0c` |
| HDiffPatch submodule commit | `505eaa5f0bef2c4f70f02cc1bfe1448cf2bf54dc` |
| path in upstream | `HDiffPatch/libHDiffPatch/HPatchLite/` |
| licence | MIT (LICENSE, copied verbatim) |

## What it is, and what it is not

`hpatch_lite_open()` reads the patch header; `hpatch_lite_patch()` applies it, pulling patch bytes
through a read callback, reading the OLD image at arbitrary offsets through another, and writing the
new image sequentially through a third. It owns no storage, knows nothing about partitions, and
decides nothing -- which is why it sits behind `ota_patch_t` with our slot, our hashes, our attempt
counter and our brake all still in charge.

It is NOT the decoder for `hdiffz` output. HPatchLite has its own smaller format, produced by
`hdiffi`, and the two are not interchangeable. `ota-bundle` calls `hdiffi`.

## The generator

`hdiffi` is built from the upstream repository and is not vendored -- it is a build-host tool, like
the toolchain, rather than something that ships:

    git clone --recursive https://github.com/sisong/HPatchLite
    cd HPatchLite && make        # gives ./hdiffi and ./hpatchi

`ota-bundle` runs it with no compression flag (`hdiffi` defaults to uncompressed), because FORM and
CODEC are independent in our format: the patch is the delta and the codec is what squeezes it. On
relay 0.9.8 -> 0.9.9 that measured 216057 bytes of raw patch down to 6616 on the wire, against 7003
for the `hdiffz` patches previously in the release tree and 9600 for esp_delta_ota's heatshrink.

## Local changes

None. The four files are byte-for-byte upstream; everything we add lives in
`iotdata-common/include/device/d_module_patch_esp32.h` and its linux counterpart.

# build.prop
 Bash script to build your own system.prop

## How to use
Simply drag and drop your images into the build.prop root directory and execute `extract_images.sh`, If you are wondering where i get my images from they are all from the [Google Android Images](https://developers.google.com/android/images).

You can now also use the `download_last_ota_build.sh $*` with an argument of the name of the device you are trying to download from.
Example: `download_last_ota_build.sh cheetah raven redfin`

## Why?
I wrote this in a quick day so it might look unfinished, But the why is that it takes me a long time to do all by hand so a bit of automatization should help me.

## Todo
- [x] Downloads latest OTA Image from [Google Full OTA Images](https://developers.google.cn/android/ota).
- [x] Check for dependencies
- [x] Extract factory images
- [x] Extract OTA images
- [x] Build system.prop
- [ ] Use of GitHub Actions to automate the update/commit/push/release process on schedule
- [ ] ~~Download latest Factory image from [Google Android Images](https://developers.google.com/android/images).~~

You can also help me finish those todo's by forking this repository, modifying the script and pushing a pull request.

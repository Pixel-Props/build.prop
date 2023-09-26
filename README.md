# build.prop
Bash script to convert Pixel OTA builds to a system props.

## How to use
Simply drag and drop your images into the workspace directory and execute `extract_images.sh`.

### Where to get images
Images can be found from the [Google Android Images](https://developers.google.com/android/images) page.

Additionally, you can also use the `download_latest_ota_build.sh` utility with an arguments of the name of the devices you are trying to download from:
```sh
$ ./download_latest_ota_build.sh cheetah raven redfin
```


## To-do
- [x] Downloads latest OTA Image from [Google Full OTA Images](https://developers.google.cn/android/ota).
- [x] Check for dependencies
- [x] Extract factory images
- [x] Extract OTA images
- [x] Build props
- [x] Use of GitHub Actions to automate the update/commit/push/release process on schedule
- [ ] Use of GitHub Actions to automate the release of props on the Telegram Channel
- [ ] ~~Download latest factory image from [Google Android Images](https://developers.google.com/android/images)~~

You can also help me finish those todo's by forking this repository, modifying the script and pushing a pull request.

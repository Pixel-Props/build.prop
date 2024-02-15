# build.prop
Bash script to convert Pixel OTA builds to a system props.

## How to use
Simply drag and drop your images into the workspace directory and execute `extract_images.sh`.

### Where to get images
Images can be found from the [Google Android Images](https://developers.google.com/android/images) or [Google Beta OTA Images](https://developer.android.com/about/versions/14/download-ota) page.

Additionally, you can also use the `download_latest_ota_build.sh` utility with an arguments of the name of the devices you are trying to download from:
```sh
$ ./download_latest_ota_build.sh husky felix_beta cheetah
```


## To-do
### I would appreciate your attention and assistance in accomplishing my to-do goals. (Fork->Commit->)
- [x] Downloads latest OTA Image from [Google Full OTA Images](https://developers.google.cn/android/ota) and [Google Beta OTA Images](https://developer.android.com/about/versions/14/download-ota).
- [x] Check for dependencies
- [x] Extract factory images
- [x] Extract OTA images
- [x] Build props
- [x] Use of GitHub Actions to automate the update/commit/push/release process on schedule
  - [x] Previous release checker (to check for duplicates, via git notes)
- [x] Use of GitHub Actions to automate the release of props on the Telegram Channel
- [ ] Develop a Zygisk library or executable to retrieve the Play Integrity verdict
  - [ ] Implement automation for PlayIntegrityFix
- [ ] ~~Download latest factory image from [Google Android Images](https://developers.google.com/android/images)~~

## Disclaimer
This code is provided for educational purposes and should be used responsibly. While it is used in GitHub Actions and other production environments, it is important to understand and verify the code before using it in your own projects. Always ensure that the code complies with all relevant regulations and best practices for security and reliability. The author(s) and contributors of this code are not responsible for any issues or damages that may arise from its use.

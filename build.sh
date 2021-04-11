#!/bin/bash

mkdir -p /tmp/rom
cd /tmp/rom

git config --global user.name lizziya
git config --global user.email lizziyachan@gmail.com

rom_one(){
 repo init --depth=1 --no-repo-verify -u git://github.com/DotOS/manifest.git -b dot11 -g default,-device,-mips,-darwin,-notdefault
 repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)
 git clone https://${TOKEN}/device_xiaomi_sakura_TEST.git -b dot-R device/xiaomi/sakura
 git clone --depth=1 https://${TOKEN}/vendor_xiaomi_sakura_TEST.git -b lineage-18.1 vendor/xiaomi
 rm -rf hardware/qcom-caf/msm8996/audio hardware/qcom-caf/msm8996/display hardware/qcom-caf/msm8996/media
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_audio -b 11.0 hardware/qcom-caf/msm8996/audio
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_display -b 11.0 hardware/qcom-caf/msm8996/display
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_media -b 11.0 hardware/qcom-caf/msm8996/media
 . build/envsetup.sh && lunch dot_sakura-user
}

rom_two(){
 repo init --depth=1 --no-repo-verify -u git://github.com/DotOS/manifest.git -b dot11 -g default,-device,-mips,-darwin,-notdefault
 repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)
 git clone https://${TOKEN}/device_xiaomi_sakura_TEST.git -b dot11-cam device/xiaomi/sakura
 git clone --depth=1 https://${TOKEN}/vendor_xiaomi_sakura_TEST.git -b lineage-18.1-check vendor/xiaomi
 rm -rf hardware/qcom-caf/msm8996/audio hardware/qcom-caf/msm8996/display hardware/qcom-caf/msm8996/media
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_audio -b 11.0 hardware/qcom-caf/msm8996/audio
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_display -b 11.0 hardware/qcom-caf/msm8996/display
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_media -b 11.0 hardware/qcom-caf/msm8996/media
 rm -rf vendor/qcom/opensource/usb
 . build/envsetup.sh && lunch dot_sakura-userdebug
}

rom_three(){
 repo init --depth=1 --no-repo-verify -u https://github.com/geopd/platform_manifest -b 11 -g default,-device,-mips,-darwin,-notdefault
 repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)
 git clone https://${TOKEN}/device_xiaomi_sakura_TEST.git -b Octavi-11 device/xiaomi/sakura
 git clone --depth=1 https://${TOKEN}/vendor_xiaomi_sakura_TEST.git -b lineage-18.1 vendor/xiaomi
 rm -rf hardware/qcom-caf/msm8996/audio hardware/qcom-caf/msm8996/display hardware/qcom-caf/msm8996/media
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_audio -b 11.0 hardware/qcom-caf/msm8996/audio
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_display -b 11.0 hardware/qcom-caf/msm8996/display
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_media -b 11.0 hardware/qcom-caf/msm8996/media
 wget https://raw.githubusercontent.com/geopd/misc/master/common-vendor.mk && mv common-vendor.mk vendor/gapps/common/common-vendor.mk
 rm -rf vendor/qcom/opensource/interfaces hardware/interfaces
 git clone https://github.com/geopd/platform_vendor_qcom_opensource_interfaces -b 11 vendor/qcom/opensource/interfaces
 git clone https://github.com/geopd/platform_hardware_interfaces -b 11 hardware/interfaces
 sed -i '677s/private int mTorchActionMode;//g' fra*/ba*/ser*/cor*/ja*/com/and*/ser*/pol*/PhoneWindowManager.java # rest are for the betterment of society
 sed -i '219s/violet/sakura/g' pac*/apps/Set*/src/com/and*/set*/OosAboutPreference.java
 sed -i '220s/violet/sakura/g' pac*/apps/Set*/src/com/and*/set*/OosAboutPreference.java
 sed -i '10s/Nobody/MYSTO/g' vendor/octavi/config/branding.mk
 rclone copy brrbrr:ic_device_sakura.png pac*/apps/Settings/res/drawable/ -P
 export SKIP_ABI_CHECKS=true
 . build/envsetup.sh && lunch octavi_sakura-user
}

git clone --depth=1 https://${TOKEN}/kernel_xiaomi_msm8953 -b test-cam kernel/xiaomi/msm8953
git clone https://github.com/geopd/vendor_custom_prebuilts -b master vendor/custom/prebuilts
git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git -b gcc-master prebuilts/gcc/linux-x86/aarch64/aarch64-elf

echo "${GIT_COOKIES}" > ~/git_cookies.sh
bash ~/git_cookies.sh

case "${rom}" in
 "dotOS") rom_one
    ;;
 "dotOS-Rc") rom_two
    ;;
 "OctaviOS") rom_three
    ;;
 *) echo "Invalid option!"
    exit 1
    ;;
esac

BUILD_MONTH=$(date +"%Y%m")
BUILD_START=$(date +"%s")

telegram_message() {
    curl -s -X POST "https://api.telegram.org/bot${BOTTOKEN}/sendMessage" -d chat_id="${CHATID}" \
    -d "parse_mode=html" \
    -d text="$1"
}

telegram_message "<b>🌟 $rom Build Triggered 🌟</b>%0A%0A<b>Date: </b><code>$(date +"%d-%m-%Y %T")</code>"

export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
ccache -M 50G && ccache -o compression=true && ccache -z

case "${rom}" in
 "dotOS") make bacon -j18 | tee build.log
    ;;
 "dotOS-Rc") make bacon -j18 | tee build.log
    ;;
 "OctaviOS") mka octavi -j18 | tee build.log
    ;;
 *) echo "Invalid option!"
    exit 1
    ;;
esac

ls -a $(pwd)/out/target/product/sakura/

BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))
ZIP=$(find $(pwd)/out/target/product/sakura/ -maxdepth 1 -name "*sakura*"${BUILD_MONTH}"*.zip" | perl -e 'print sort { length($b) <=> length($a) } <>' | head -n 1)
ZIPNAME=$(basename ${ZIP})
echo "${ZIP}"

telegram_build() {
 curl --progress-bar -F document=@"$1" "https://api.telegram.org/bot${BOTTOKEN}/sendDocument" \
 -F chat_id="${CHATID}" \
 -F "disable_web_page_preview=true" \
 -F "parse_mode=Markdown" \
 -F caption="$2"
}

telegram_post(){
 if [ -f $(pwd)/out/target/product/sakura/${ZIPNAME} ]; then
	rclone copy ${ZIP} brrbrr:rom -P
	MD5CHECK=$(md5sum ${ZIP} | cut -d' ' -f1)
	DWD=${TDRIVE}${ZIPNAME}
	telegram_message "<b>✅ Build finished after $((DIFF / 3600)) hour(s), $((DIFF % 3600 / 60)) minute(s) and $((DIFF % 60)) seconds</b>%0A%0A<b>ROM: </b><code>${ZIPNAME}</code>%0A%0A<b>MD5 Checksum: </b><code>${MD5CHECK}</code>%0A%0A<b>Download Link: </b><a href='${DWD}'>Tdrive</a>%0A%0A<b>Date: </b><code>$(date +"%d-%m-%Y %T")</code>"
 else
	BUILD_LOG=$(pwd)/build.log
	tail -n 10000 ${BUILD_LOG} >> $(pwd)/buildtrim.txt
	LOG1=$(pwd)/buildtrim.txt
	echo "CHECK BUILD LOG" >> $(pwd)/out/build_error
	LOG2=$(pwd)/out/build_error
	TRANSFER=$(curl --upload-file ${LOG1} https://transfer.sh/$(basename ${LOG1}))
	telegram_build ${LOG2} "*❌ Build failed to compile after $(($DIFF / 3600)) hour(s) and $(($DIFF % 3600 / 60)) minute(s) and $(($DIFF % 60)) seconds*
	Build Log: ${TRANSFER}
	_Date:  $(date +"%d-%m-%Y %T")_"
 fi
}

telegram_post
ccache -s

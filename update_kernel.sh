#!/bin/bash

# 에러 체크 및 메시지 출력 함수
check_error() {
    if [ $? -ne 0 ]; then
        echo "$1"
        echo "stopped script."
        exit 1
    fi
}

# root 권한 확인
if [ "$(id -u)" -ne 0 ]; then
    echo "permission denied : this script need root permission."
    exit 1
fi

# 커널 버전 세팅
read -p "input kernel version what you want to download (ex: 5.15.0): " KERNEL_VERSION
IFS='.' read -r major minor patch <<< "$KERNEL_VERSION"

# 커널 저장소
KERNEL_URL="https://www.kernel.org/pub/linux/kernel/v${major}.x/linux-${KERNEL_VERSION}.tar.xz"
    
# 필요한 라이브러리 설치
sudo apt-get update
sudo apt-get install -y build-essential libncurses5-dev flex bison libssl-dev libelf-dev

# /usr/src 디렉토리로 이동
cd /usr/src

# 커널 다운로드 및 압축 해제
wget "$KERNEL_URL"
check_error "kernel download faild."

tar -xf "linux-${KERNEL_VERSION}.tar.xz"
check_error "unzip faild."

# 커널 소스 디렉토리로 이동
cd "linux-${KERNEL_VERSION}"

# 기존 커널의 설정 파일 복사
sudo cp /boot/config-"$(uname -r)" .config

# 커널 설정 변경
make menuconfig
check_error "menuconfig faild."

# 시스템 신뢰 키 및 시스템 취소 키를 비활성화
scripts/config --disable SYSTEM_TRUSTED_KEYS
scripts/config --disable SYSTEM_REVOCATION_KEYS

# 커널 컴파일 및 설치
sudo make -j"$(nproc)"
check_error "make faild."

sudo make INSTALL_MOD_STRIP=1 modules_install
check_error "make faild."

sudo make install
check_error "make faild."

# 재부팅 여부 확인 및 실행
read -p "New version kernel settings completed. Reboot now? (y/n): " REBOOT_CHOICE
if [ "$REBOOT_CHOICE" == "y" ]; then
    sudo reboot
fi
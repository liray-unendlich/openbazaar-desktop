#!/bin/sh

## Version 2.0.0
##
## Usage
## ./build.sh
##
## OS supported:
## win32 win64 linux32 linux64 linuxarm osx
##


ELECTRONVER=1.7.10
NODEJSVER=6

OS="${1}"

# Get Version
PACKAGE_VERSION=$(cat package.json \
  | grep version \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[",]//g' \
  | tr -d '[[:space:]]')
echo "Phore Marketplace Version: $PACKAGE_VERSION"

# Create temp/build dirs
mkdir dist/
rm -rf dist/*
mkdir temp/
rm -rf temp/*

echo 'Preparing to build installers...'

echo 'Installing npm packages...'
npm i -g npm@5.2
npm install electron-packager -g --silent
npm install npm-run-all -g --silent
npm install grunt-cli -g --silent
npm install grunt --save-dev --silent
npm install grunt-electron-installer --save-dev --silent
npm install

echo 'Building OpenBazaar app...'
npm run build

echo 'Copying transpiled files into js folder...'
cp -rf prod/* js/


case "1" in
  "linux")

    echo 'Linux builds'

    echo 'Building Linux 32-bit Installer....'

    echo 'Making dist directories'
    mkdir dist/linux32
    mkdir dist/linux64

    echo 'Install npm packages for Linux'
    npm install -g --save-dev electron-installer-debian --silent
    npm install -g --save-dev electron-installer-redhat --silent

    # Install rpmbuild
    sudo apt-get install rpm

    # Ensure fakeroot is installed
    sudo apt-get install fakeroot

    if [ -z "$CLIENT_VERSION" ]; then
      # Retrieve Latest Server Binaries
      sudo apt-get install jq
      cd temp/
      curl -u $GITHUB_USER:$GITHUB_TOKEN -s https://api.github.com/repos/phoreproject/openbazaar-go/releases | jq -r ".[0].assets[].browser_download_url" | xargs -n 1 curl -L -O
      cd ..
    fi

    if [ -z "$CLIENT_VERSION" ]; then
      APPNAME="phoremarketplace"

      echo "Packaging Electron application"
      electron-packager . ${APPNAME} --platform=linux --arch=ia32 --version=${ELECTRONVER} --overwrite --prune --out=dist

      echo 'Move go server to electron app'
      mkdir dist/${APPNAME}-linux-ia32/resources/openbazaar-go/
      cp -rf temp/openbazaar-go-linux-386 dist/${APPNAME}-linux-ia32/resources/openbazaar-go
      mv dist/${APPNAME}-linux-ia32/resources/openbazaar-go/openbazaar-go-linux-386 dist/${APPNAME}-linux-ia32/resources/openbazaar-go/openbazaard
      rm -rf dist/${APPNAME}-linux-ia32/resources/app/.travis
      chmod +x dist/${APPNAME}-linux-ia32/resources/openbazaar-go/openbazaard

      echo 'Create debian archive'
      electron-installer-debian --config .travis/config_ia32.json

      echo 'Create RPM archive'
      electron-installer-redhat --config .travis/config_ia32.json

      echo 'Building Linux 64-bit Installer....'

      echo "Packaging Electron application"
      electron-packager . ${APPNAME} --platform=linux --arch=x64 --version=${ELECTRONVER} --overwrite --prune --out=dist

      echo 'Move go server to electron app'
      mkdir dist/${APPNAME}-linux-x64/resources/openbazaar-go/
      cp -rf temp/openbazaar-go-linux-amd64 dist/${APPNAME}-linux-x64/resources/openbazaar-go
      mv dist/${APPNAME}-linux-x64/resources/openbazaar-go/openbazaar-go-linux-amd64 dist/${APPNAME}-linux-x64/resources/openbazaar-go/openbazaard
      rm -rf dist/${APPNAME}-linux-x64/resources/app/.travis
      chmod +x dist/${APPNAME}-linux-x64/resources/openbazaar-go/openbazaard

      echo 'Create debian archive'
      electron-installer-debian --config .travis/config_amd64.json

      echo 'Create RPM archive'
      electron-installer-redhat --config .travis/config_amd64.json
    else
      APPNAME="phoremarketplaceclient"

      echo "Packaging Electron application"
      electron-packager . ${APPNAME} --platform=linux --arch=ia32 --version=${ELECTRONVER} --overwrite --prune --out=dist

      echo 'Create debian archive'
      electron-installer-debian --config .travis/config_ia32.client.json

      echo 'Create RPM archive'
      electron-installer-redhat --config .travis/config_ia32.client.json

      echo 'Building Linux 64-bit Installer....'

      echo "Packaging Electron application"
      electron-packager . ${APPNAME} --platform=linux --arch=x64 --version=${ELECTRONVER} --overwrite --prune --out=dist

      echo 'Create debian archive'
      electron-installer-debian --config .travis/config_amd64.client.json

      echo 'Create RPM archive'
      electron-installer-redhat --config .travis/config_amd64.client.json
    fi

    ;;

  "win")


    # Retrieve Latest Server Binaries
    cd temp/
    curl -u $GITHUB_USER:$GITHUB_TOKEN -s https://api.github.com/repos/phoreproject/openbazaar-go/releases | jq -r ".[0].assets[].browser_download_url" | xargs -n 1 curl -L -O
    cd ..

    # WINDOWS 32
    echo 'Building Windows 32-bit Installer...'
    mkdir dist/win32

    if [ -z "$CLIENT_VERSION" ]; then
      echo 'Running Electron Packager...'

      electron-packager . phoremarketplace --asar --out=dist --protocol-name=PhoreMarketplace --win32metadata.ProductName="Phore Marketplace" --win32metadata.CompanyName="Phore" --win32metadata.FileDescription='Decentralized p2p marketplace for Phore' --win32metadata.OriginalFilename=PhoreMarketplace.exe --protocol=ob --platform=win32 --arch=ia32 --icon=imgs/openbazaar2.ico --electron-version=${ELECTRONVER} --overwrite
      echo 'Copying server binary into application folder...'
      cp -rf temp/openbazaar-go-windows-4.0-386.exe dist/phoremarketplace-win32-ia32/resources/
      cp -rf temp/libwinpthread-1.win32.dll dist/phoremrakteplace-win32-ia32/resources/libwinpthread-1.dll
      mkdir dist/phoremarketplace-win32-ia32/resources/openbazaar-go
      mv dist/phoremarketplace-win32-ia32/resources/openbazaar-go-windows-4.0-386.exe dist/phoremarketplace-win32-ia32/resources/openbazaar-go/openbazaard.exe
      mv dist/phoremarketplace-win32-ia32/resources/libwinpthread-1.dll dist/phoremarketplace-win32-ia32/resources/openbazaar-go/libwinpthread-1.dll

      echo 'Building Installer...'
      grunt create-windows-installer --appname=PhoreMarketplace --obversion=$PACKAGE_VERSION --appdir=dist/PhoreMarketplace-win32-ia32 --outdir=dist/win32
      mv dist/win32/PhoreMarketplaceSetup.exe dist/win32/PhoreMarketplace-$PACKAGE_VERSION-Setup-32.exe
    else
      #### CLIENT ONLY
      echo 'Running Electron Packager...'
      electron-packager . PhoreMarketplaceClient --asar --out=dist --protocol-name=PhoreMarketplace --win32metadata.ProductName="Phore Marketplace Client" --win32metadata.CompanyName="Phore" --win32metadata.FileDescription='Decentralized p2p marketplace for Phore' --win32metadata.OriginalFilename=PhoreMarketplaceClient.exe --protocol=ob --platform=win32 --arch=ia32 --icon=imgs/openbazaar2.ico --electron-version=${ELECTRONVER} --overwrite

      echo 'Building Installer...'
      grunt create-windows-installer --appname=PhoreMarketplaceClient --obversion=$PACKAGE_VERSION --appdir=dist/PhoreMarketplaceClient-win32-ia32 --outdir=dist/win32
      mv dist/win32/PhoreMarketplaceClientSetup.exe dist/win32/PhoreMarketplaceClient-$PACKAGE_VERSION-Setup-32.exe
    fi

    # WINDOWS 64
    echo 'Building Windows 64-bit Installer...'
    mkdir dist/win64

    if [ -z "$CLIENT_VERSION" ]; then
      echo 'Running Electron Packager...'
      electron-packager . PhoreMarketplace --asar --out=dist --protocol-name=PhoreMarketplace --win32metadata.ProductName="Phore Marketplace" --win32metadata.CompanyName="Phore" --win32metadata.FileDescription='Decentralized p2p marketplace for Phore' --win32metadata.OriginalFilename=OpenBazaar2.exe --protocol=ob --platform=win32 --arch=x64 --icon=imgs/openbazaar2.ico --electron-version=${ELECTRONVER} --overwrite

      echo 'Copying server binary into application folder...'
      cp -rf temp/openbazaar-go-windows-4.0-amd64.exe dist/PhoreMarketplace-win32-x64/resources/
      cp -rf temp/libwinpthread-1.win64.dll dist/PhoreMarketplace-win32-x64/resources/libwinpthread-1.dll
      mkdir dist/PhoreMarketplace-win32-x64/resources/openbazaar-go
      mv dist/PhoreMarketplace-win32-x64/resources/openbazaar-go-windows-4.0-amd64.exe dist/PhoreMarketplace-win32-x64/resources/openbazaar-go/openbazaard.exe
      mv dist/PhoreMarketplace-win32-x64/resources/libwinpthread-1.dll dist/PhoreMarketplace-win32-x64/resources/openbazaar-go/libwinpthread-1.dll

      echo 'Building Installer...'
      grunt create-windows-installer --appname="Phore Marketplace" --obversion=$PACKAGE_VERSION --appdir=dist/PhoreMarketplace-win32-x64 --outdir=dist/win64
      mv dist/win64/PhoreMarketplaceSetup.exe dist/win64/PhoreMarketplace-$PACKAGE_VERSION-Setup-64.exe
    else
      #### CLIENT ONLY
      echo 'Running Electron Packager...'
      electron-packager . PhoreMarketplaceClient --asar --out=dist --protocol-name=PhoreMarketplace --win32metadata.ProductName="Phore Marketplace Client" --win32metadata.CompanyName="Phore" --win32metadata.FileDescription='Decentralized p2p marketplace for Phore' --win32metadata.OriginalFilename=PhoreMarketplaceClient.exe --protocol=ob --platform=win32 --arch=x64 --icon=imgs/openbazaar2.ico --electron-version=${ELECTRONVER} --overwrite

      echo 'Building Installer...'
      grunt create-windows-installer --appname=PhoreMarketplaceClient --obversion=$PACKAGE_VERSION --appdir=dist/PhoreMarketplaceClient-win32-x64 --outdir=dist/win64
      mv dist/win64/OpenBazaar2ClientSetup.exe dist/win64/PhoreMarketplaceClient-$PACKAGE_VERSION-Setup-64.exe
    fi
    ;;
esac

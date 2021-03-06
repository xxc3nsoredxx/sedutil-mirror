#! /bin/bash

#   Set up the build system and gather image build dependencies
#   Copyright (C) 2020-2021  xc3nsoredxx
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

. conf
set -o pipefail

# Test if scratch directory exists
if ! [ -d scratch ]; then
    echo 'Creating directory "scratch" ...'
    mkdir scratch
fi

# Prepare sources
pushd scratch &> /dev/null
    # Test if buildroot tarball exists
    if ! [ -e .buildroot_dl_done ]; then
        while ! [ -e .buildroot_dl_done ]; do
            echo 'Fetching Buildroot tarball ...'
            curl -L -O $BUILDROOT_URL/$BUILDROOT_VER.tar.gz && touch .buildroot_dl_done
        done
    fi

    # Test if buildroot is extracted
    if ! [ -d buildroot ]; then
        echo 'Extracting Buildroot tarball ...'
        tar xf $BUILDROOT_VER.tar.gz
        mv $BUILDROOT_VER buildroot
    fi

    # Build sedutil tarball and add it to buildroot tree
    pushd ../.. &> /dev/null
        echo 'Reconfiguring sedutil ...'
        autoreconf -i
        ./configure

        echo 'Building sedutil package ...'
        make dist

        echo 'Cleaning old source tarballs ...'
        rm -rfv images/scratch/buildroot/dl/sedutil-xxc
        rm -rfv images/sedutil/package/sedutil-xxc/src
        rm -fv images/sedutil/package/sedutil-xxc/sedutil-xxc.hash
        echo 'Adding sedutil to Buildroot tree ...'
        mkdir images/sedutil/package/sedutil-xxc/src
        cp -v sedutil-*.tar.xz images/sedutil/package/sedutil-xxc/src

        # Create the hash file
        echo 'Creating SHA512 hash of tarball ...'
        echo "sha512  $(sha512sum sedutil-*.tar.xz)" > images/sedutil/package/sedutil-xxc/sedutil-xxc.hash
        cat images/sedutil/package/sedutil-xxc/sedutil-xxc.hash

        make distclean
    popd &> /dev/null

    # Prepare buildroot tree
    pushd buildroot &> /dev/null
        # Clean any existing files
        if [ -d output ]; then
            echo 'Cleaning existing tree ...'
            rm -rf output
        fi
        mkdir output

        # Apply the buildroot config
        echo 'Using the sedutil defconfig file ...'
        make sedutil_defconfig |& tee output/init_config.txt
        # Have buildroot download the required sources
        echo 'Fetching required sources with Buildroot ...'
        rm -f .buildroot_sources_dl_done
        while ! [ -e .buildroot_sources_dl_done ]; do
            make source |& tee -a output/dl_output.txt && touch .buildroot_sources_dl_done
        done
    popd &> /dev/null
popd &> /dev/null

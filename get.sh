#!/bin/bash

# Copyright OpenFaaS Author(s) 2019
#########################
# Repo specific content #
#########################

checkEnv() {

    export VERIFY_CHECKSUM=0
    export ALIAS=""
    export BINLOCATION="/usr/local/bin"
    export VERIFY_CHECKSUM=1

    ###############################
    # Content common across repos #
    ###############################

    export version=$(curl -sI https://github.com/$OWNER/$REPO/releases/latest | grep -i "location:" | awk -F"/" '{ printf "%s", $NF }' | tr -d '\r')

    if [ ! $version ]; then
        echo "Failed while attempting to install $REPO. Please manually install:"
        echo ""
        echo "1. Open your web browser and go to https://github.com/$OWNER/$REPO/releases"
        echo "2. Download the latest release for your platform. Call it '$REPO'."
        echo "3. chmod +x ./$REPO"
        echo "4. mv ./$REPO $BINLOCATION"
        if [ -n "$ALIAS_NAME" ]; then
            echo "5. ln -sf $BINLOCATION/$REPO $BINLOCATION/$ALIAS_NAME"
        fi
        exit 1
    fi

}

hasCli() {

    hasCurl=$(which curl)
    if [ "$?" = "1" ]; then
        echo "You need curl to use this script."
        exit 1
    fi
}

checkHash() {

    if [ "$REPO" = "lego" ]; then

        md5Sha_online=$(curl -sfL https://github.com/go-acme/lego/releases/download/$version/lego_${version:1}_checksums.txt | grep "$suffix")

        md5Sha_file=$(shasum -a 256 "$targetFile")

        if [ "${md5Sha_online%% *}" != "${md5Sha_file%% *}" ]; then
            rm $targetFile
            echo "file checksum didn't match. Exiting"
            exit 1
        fi

    fi

    if [ "$REPO" = "k3s" ]; then

        sha_cmd="sha256sum"

        if [ ! -x "$(command -v $sha_cmd)" ]; then
            sha_cmd="shasum -a 256"
        fi

        if [ -x "$(command -v $sha_cmd)" ]; then

            targetFileDir=${targetFile%/*}

            (cd $targetFileDir && curl -sSL $url.sha256 | $sha_cmd -c >/dev/null)

            if [ "$?" != "0" ]; then
                rm $targetFile
                echo "Binary checksum didn't match. Exiting"
                exit 1
            fi
        fi

    fi
}

getPackage() {
    targetFile="$(pwd)/$REPO$suffix"
    if [ -e "$targetFile" ]; then
        rm "$targetFile"
    fi

    url=https://github.com/$OWNER/$REPO/releases/download/$version/$REPO$suffix
    echo "Downloading package $url as $targetFile"

    curl -sSL $url --output "$targetFile"

    if [ "$?" = "0" ]; then

        if [ "$VERIFY_CHECKSUM" = "1" ]; then
            checkHash
        fi

        if [[ "$targetFile" == *.tar.gz ]]; then
            tar -zxf "$targetFile"
            targetFile=$(pwd)/$REPO
        fi

        chmod +x "$targetFile"

        echo "Download complete."

        if [ ! -w "$BINLOCATION" ]; then

            echo
            echo "============================================================"
            echo "  The script was run as a user who is unable to write"
            echo "  to $BINLOCATION. To complete the installation the"
            echo "  following commands may need to be run manually."
            echo "============================================================"
            echo
            echo "  sudo cp $REPO$suffix $BINLOCATION/$REPO"

            if [ -n "$ALIAS_NAME" ]; then
                echo "  sudo ln -sf $BINLOCATION/$REPO $BINLOCATION/$ALIAS_NAME"
            fi

            echo

        else

            echo
            echo "Running with sufficient permissions to attempt to move $REPO to $BINLOCATION"

            if [ ! -w "$BINLOCATION/$REPO" ] && [ -f "$BINLOCATION/$REPO" ]; then

                echo
                echo "================================================================"
                echo "  $BINLOCATION/$REPO already exists and is not writeable"
                echo "  by the current user.  Please adjust the binary ownership"
                echo "  or run sh/bash with sudo."
                echo "================================================================"
                echo
                exit 1

            fi

            mv $targetFile $BINLOCATION/$REPO

            if [ "$?" = "0" ]; then
                echo "New version of $REPO installed to $BINLOCATION"
            fi

            if [ -e "$targetFile" ]; then
                rm "$targetFile"
            fi

            if [ -n "$ALIAS_NAME" ]; then
                if [ ! -L $BINLOCATION/$ALIAS_NAME ]; then
                    ln -s $BINLOCATION/$REPO $BINLOCATION/$ALIAS_NAME
                    echo "Creating alias '$ALIAS_NAME' for '$REPO'."
                fi
            fi

            ${SUCCESS_CMD}
        fi
    fi
}
getLego() {

    export OWNER=go-acme
    export REPO=lego
    checkEnv
    export SUCCESS_CMD="$BINLOCATION/$REPO -v"
    export suffix=_${version}_linux_amd64.tar.gz
    getPackage
}
getMc() {

    #wget https://dl.min.io/client/mc/release/linux-amd64/mc
    curl -s https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
    chmod +x mc
    BINLOCATION="/usr/local/bin"
    mv mc $BINLOCATION
    mc version
}
thanks() {
    echo
    echo "================================================================"
    echo "  Get a 2-3x speed up for CI whilst reducing costs"
    echo ""
    echo "  https://actuated.dev"
    echo "================================================================"
    echo
}

hasCli
getLego
getMc
thanks

export PLATFORM="unkown"
osname=$(uname -s)
cputpye=£(uname -m)
if [[ "$osname" == 'Linux' ]]; then
    export PLATFORM="linux"
elif [[ "$osname" == 'Darwin' ]]; then
    if [[ "$cputpye" == 'x86_64' ]]; then
        export PLATFORM="osx"
    elif [[ "$cputype" == 'arm64' ]]; then
        export PLATFORM="osx-m1"
    fi
fi

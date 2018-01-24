export PLATFORM="unkown"
unamestr=$(uname -s)
if [[ "$unamestr" == 'Linux' ]]; then
    export PLATFORM="linux"
elif [[ "$unamestr" == 'Darwin' ]]; then
    export PLATFORM="osx"
fi
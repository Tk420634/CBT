if(!(Test-Path -Path "C:/byond")){
    bash tools/ci/install_byond.sh
}

bash tools/ci/install_node.sh
bash tools/build/build

exit $LASTEXITCODE

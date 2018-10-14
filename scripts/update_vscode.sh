#!/bin/bash -xe

wget https://go.microsoft.com/fwlink/?LinkID=620884 -O code-stable-code_new.tar.gz

fileName=`ls | grep "code-stable-code_"`

sudo mv $fileName /opt/
cd /opt/
sudo mv visual-studio-code visual-studio-cold
sudo tar -xvf $fileName
sudo rm $fileName
sudo mv VSC* visual-studio-code
sudo rm -rf visual-studio-cold


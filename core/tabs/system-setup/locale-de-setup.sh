#!/bin/bash

echo "LANG=en_US.UTF-8" | sudo tee -a /etc/environment
echo "LC_TIME=de_DE.UTF-8" | sudo tee -a /etc/environment
echo "LC_NUMERIC=de_DE.UTF-8" | sudo tee -a /etc/environment
echo "LC_MONETARY=de_DE.UTF-8" | sudo tee -a /etc/environment
echo "LC_PAPER=de_DE.UTF-8" | sudo tee -a /etc/environment
echo "LC_NAME=de_DE.UTF-8" | sudo tee -a /etc/environment
echo "LC_ADDRESS=de_DE.UTF-8" | sudo tee -a /etc/environment
echo "LC_TELEPHONE=de_DE.UTF-8" | sudo tee -a /etc/environment
echo "LC_MEASUREMENT=de_DE.UTF-8" | sudo tee -a /etc/environment
echo "LC_IDENTIFICATION=de_DE.UTF-8" | sudo tee -a /etc/environment
echo "de_DE.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
echo "LANG=en_US.UTF-8" | sudo tee -a /etc/locale.conf
sudo locale-gen de_DE.UTF-8

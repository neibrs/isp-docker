#!/bin/bash

if [ -d ./../drupal.old ]; then
  sudo rm -rf ./../drupal.old
fi
if [ -d ./../drupal ]; then
  mv ./../drupal ./../drupal.old
fi
sudo docker cp isp:/var/www/html ../drupal
sudo chown -R $USER ../drupal
sudo chmod -R g+w ../drupal

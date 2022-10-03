TARGET=toyo-drupal9

#Drupalをインストールする
docker exec -it --user root ${TARGET}_php cd /home/kusanagi/${TARGET}/
docker exec -it --user root ${TARGET}_php rm -rf /home/kusanagi/${TARGET}/DocumentRoot

# Drupal latest version
docker exec -it --user root ${TARGET}_php composer create-project drupal/recommended-project /home/kusanagi/${TARGET}/DocumentRoot

# Drush latest version
# https://www.drupal.org/docs/develop/using-composer/using-composer-to-install-drupal-and-manage-dependencies
docker exec -it --user root ${TARGET}_php composer require drush/drush



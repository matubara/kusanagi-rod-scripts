####################################
APPTYPE=lamp
#LAMP_APP=""
LAMP_APP="drupal9"
#XDEBUG/GITを追加してイメージを再生成する
COMPILE=y
webserver="--httpd"
#FOR DRUPAL8.x
#php="--php74"
php=""

TARGET=undefined
TLD=.local
autoexec=0
echo count=$#
if [ $# -eq 0 ];then
    TARGET=$1
    autoexec=0
elif [ $# -eq 1 ];then
    TARGET=$1
    autoexec=0
elif [ $# -ne 2 ];then
    TARGET=$1
    autoexec=0
elif [ $2 == "y" ];then
    TARGET=$1
    autoexec=1
elif [ $2 == "Y" ];then
    TARGET=$1
    autoexec=1
else
    echo "Please check arguments!!"
    exit 1
    #autoexec=0
fi
echo "autoexec=${autoexec}"
####################################

## ---------------------------------
echo "プロビジョニング：${TARGET} を作成します。すでにある場合は削除されますのでご注意ください"
echo "FDQNは、${TARGET} ${TLD}です。"
echo "/windows/system32/drivers/etc/hostsで上記FDQNが127.0.0.1に紐付けられていることを確認ください"
if [ $autoexec -eq 1 ];then echo "完了するまで止まりません"; fi
read -p "Press [Enter] key to build dockerfile." 

echo "念のため一括コンテナ停止する"
docker stop $(docker ps -q)

#削除
echo KUSANAGIプロビジョニングの削除（既に存在すれば削除する）
kusanagi-docker remove ${TARGET}


## ---------------------------------
echo KUSANAGIプロビジョニングの作成
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi

if [ $APPTYPE = "wp" ];then
echo "作成"
kusanagi-docker provision --wp ${webserver} --wplang=ja --admin-user=sinceretechnology --admin-pass=wordpress --admin-email=admin@sinceretechnology.com.au --wp-title=WordPress --kusanagi-pass=kusanagi --dbname=wordpress --dbuser=wordpress --dbpass=wordpress --http-port=80 --tls-port=443 --fqdn ${TARGET}${TLD} ${TARGET}
elif [ $APPTYPE = "drupal8" ];then
	kusanagi-docker provision --drupal8 ${webserver} ${php}  --kusanagi-pass=kusanagi --dbname=drupal8db --dbuser=drupaluser --dbpass=drupalpass --http-port=80 --tls-port=443 --fqdn ${TARGET}${TLD} ${TARGET}
elif [ $APPTYPE = "lamp" ];then
kusanagi-docker provision --lamp ${webserver} ${php}  --kusanagi-pass=kusanagi --dbname=database --dbuser=lampuser --dbpass=lamppass --http-port=80 --tls-port=443 --fqdn ${TARGET}${TLD} ${TARGET}
else
    echo "Application type is not defined!!"
    echo "Terminate abnormally!!!!!"
    exit 1
fi

echo "Complete!"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi 

## ---------------------------------
echo サイト確認
echo "http://${TARGET}${TLD} にアクセスしてください"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi


if [ $COMPILE = "y" ];then
## ---------------------------------
cd /home/matsubara/backup
mkdir /home/matsubara/${TARGET}/contents/DocumentRoot/temp
echo "バックアップファイルをワークフォルダに移動する"
cp -r /home/matsubara/backup/kusanagi-php-php8.1 /home/matsubara/${TARGET}

cp /home/matsubara/${TARGET}/docker-compose.yml /home/matsubara/${TARGET}/docker-compose.yml.bak
#cp /home/matsubara/backup/docker-compose.yml.template /home/matsubara/${TARGET}/docker-compose.yml

echo "docker-compose.yml書き換える"
#PHPにBUILDを追加する
sed '/image: primestrategy\/kusanagi-php/a \    build:\n      context: ./kusanagi-php-php8.1\n      dockerfile: Dockerfile' /home/matsubara/${TARGET}/docker-compose.yml.bak > /home/matsubara/${TARGET}/docker-compose.yml.temp
#PHPのIMAGEをコメントアウトする
sed 's/image: primestrategy\/kusanagi-php/#image: primestrategy\/kusanagi-php/' /home/matsubara/${TARGET}/docker-compose.yml.temp > /home/matsubara/${TARGET}/docker-compose.yml

echo "Complete!"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
## ---------------------------------
fi


#########################################
## ここからWORDPRESS用の処理を記述する ##
#########################################
if [ $APPTYPE = "wp" ];then
cd /home/matsubara/backup
## ---------------------------------
cp ./MYSQL_DATABASE.sql ../${TARGET}/contents/DocumentRoot/temp
cp ./WP_UPLOADS.tar.gz  ../${TARGET}/contents/DocumentRoot/temp
cp ./WP_THEMES.tar.gz   ../${TARGET}/contents/DocumentRoot/temp
cp ./WP_PLUGINS.tar.gz  ../${TARGET}/contents/DocumentRoot/temp
## ---------------------------------
echo "tempフォルダ内でバックアップファイルを展開する"
cd  ../${TARGET}/contents/DocumentRoot/temp
tar zxvf WP_UPLOADS.tar.gz
tar zxvf WP_THEMES.tar.gz
tar zxvf WP_PLUGINS.tar.gz
## ---------------------------------
echo "wp-content内にデプロイする"
cp -r plugins/ ../wp-content/ 
cp -r uploads/ ../wp-content/ 
cp -r themes/ ../wp-content/ 
## ---------------------------------
echo "temp内の不要なファイルを削除する"
rm -f WP_PLUGINS.tar.gz
rm -f WP_UPLOADS.tar.gz
rm -f WP_THEMES.tar.gz
rm -rf plugins/
rm -rf uploads/
rm -rf themes/
## ---------------------------------
#rm -rf ../wp-content/plugins/brozzme-db-prefix-change
echo "Complete!"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi

## ---------------------------------
echo "データベースをインポートする"
cd /home/matsubara/${TARGET}
kusanagi-docker config push
#DOCERコピーコマンドを使ってホストからコンテナ内にデータを送る方法もある（こちらのほうが効率的かも）
#docker cp /home/matsubara/backup/MYSQL_DATABASE.sql ${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/temp/MYSQL_DATABASE.sql
echo "complete push"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi

kusanagi-docker wp db import /home/kusanagi/${TARGET}/DocumentRoot/temp/MYSQL_DATABASE.sql
echo "complete import db"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi

## ---------------------------------
echo "データベースのURLをWP-CLIで一括置換する"
kusanagi-docker wp search-replace https://goodhealthbetterlife.com.au http://${TARGET}${TLD}
kusanagi-docker wp search-replace goodhealthbetterlife.com.au ${TARGET}${TLD}
echo "Complete!"
#if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi

## ---------------------------------
echo "DOCER環境に入ってパーミッションを変更"
docker-compose run config chmod 777 /home/kusanagi/${TARGET}/DocumentRoot/wp-content -R

echo "DOCER環境に入ってユーザーを変更"
#docker exec -it --user 1000 ${TARGET}_httpd chown kusanagi:www /home/kusanagi/${TARGET}/DocumentRoot/wp-content -R

## ---------------------------------
echo "DOCER環境に入って不要なプラグインを削除（PHPバージョンによりエラーが発生するため対応）"
docker-compose run config rm -rf /home/kusanagi/${TARGET}/DocumentRoot/wp-content/plugins/brozzme-db-prefix-change

## ---------------------------------
echo "Debugに必要なプラグインをインストールする"
kusanagi-docker wp plugin install query-monitor
kusanagi-docker wp plugin activate query-monitor

echo "Complete!"
#if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
fi #wp ここまで


#########################################
## ここから Drupal9用の処理を記述する  ##
#########################################
if [ $APPTYPE = "lamp" ] && [ $LAMP_APP = "drupal9" ];then
#DRUPAL作成用SHをDOCKER内に転送する
#docker cp /home/matsubara/backup/builddrupal.sh ${TARGET}_php:/home/kusanagi/${TARGET}/
#権限を変更する
#docker exec -it --user root ${TARGET}_php chmod 777 /home/kusanagi/${TARGET}/builddrupal.sh
#シェルを実行する
#docker exec -it --user root ${TARGET}_php /bin/sh /home/kusanagi/${TARGET}/builddrupal.sh


echo "最新版Drupalをインストールする"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
#Drupalをインストールする
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/ \
	&& rm -rf ./DocumentRoot"

if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
echo "DRUPAL最新版をインストールする"
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/ \
	&& composer create-project drupal/recommended-project \
	./DocumentRoot"

if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
# Drush latest version
# https://www.drupal.org/docs/develop/using-composer/using-composer-to-install-drupal-and-manage-dependencies
echo "DRUSHをインストールする"
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/DocumentRoot \
	&& composer require drush/drush"


if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
echo "DRUSH LAUNCHERをインストールする"
docker cp /home/matsubara/backup/drush.phar \
	${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/drush.phar

docker exec -it --user root ${TARGET}_php \
	chmod +x /home/kusanagi/${TARGET}/DocumentRoot/drush




if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
#現在エラーが発生する
#Drupal8 Install
#docker exec -it --user root ${TARGET}_php composer create-project drupal-composer/drupal-project:8.x-dev --stability dev --no-interaction DocumentRoot

docker exec -it --user root ${TARGET}_php mkdir /home/kusanagi/${TARGET}/DocumentRoot/web/sites/default/files
docker exec -it --user root ${TARGET}_php mkdir /home/kusanagi/${TARGET}/DocumentRoot/web/sites/default/files/translations
docker exec -it --user root ${TARGET}_php cp /home/kusanagi/${TARGET}/DocumentRoot/web/sites/default/default.settings.php /home/kusanagi/${TARGET}/DocumentRoot/web/sites/default/settings.php
docker exec -it --user root ${TARGET}_php chmod 777 /home/kusanagi/${TARGET}/DocumentRoot/web -R

# DRUSHをインストールする
#docker exec -it --user root ${TARGET}_php cd /home/kusanagi/${TARGET}/DocumentRoot
#docker exec -it --user root ${TARGET}_php composer require drush/drush

#ドキュメントルートを変更する
cp  /home/matsubara/${TARGET}/.kusanagi /home/matsubara/${TARGET}/.kusanagi.bak
sed 's/\/DocumentRoot/\/DocumentRoot\/web/' /home/matsubara/${TARGET}/.kusanagi.bak > /home/matsubara/${TARGET}/.kusanagi.temp
sed 's/ROOT_DIR=DocumentRoot/\ROOT_DIR=web/' /home/matsubara/${TARGET}/.kusanagi.temp > /home/matsubara/${TARGET}/.kusanagi
##TODO: Debug 後でコメントアウトすること
#exit 0
fi


cd /home/matsubara/${TARGET}
echo "<?php phpinfo();" > /home/matsubara/phpinfo.php
## ---------------------------------
if [ $APPTYPE = "lamp" ] && [ $LAMP_APP = "drupal9" ];then
docker cp /home/matsubara/phpinfo.php ${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/web/phpinfo.php
docker cp /home/matsubara/backup/adminer.php ${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/web/adminer.php

#echo "TOYO FILES COPYスクリプトをコンテナ内に転送する"
#if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
#docker cp /home/matsubara/backup/copyfiles.sh ${TARGET}_php:/home/kusanagi/${TARGET}/copyfiles.sh
#echo "権限を設定する"
#if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
#docker exec -it --user root ${TARGET}_php chmod 777 /home/kusanagi/${TARGET}/copyfiles.sh
#echo "TOYO FILES COPYスクリプトを実行する"
#if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
#docker exec -it --user root ${TARGET}_php /bin/sh /home/kusanagi/${TARGET}/copyfiles.sh



#echo "TOYO DATABASEバックアップスクリプトをコンテナ内に転送する"
#if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
#docker cp /home/matsubara/backup/TOYO_LMS_20220429.sql ${TARGET}_db:/home/TOYO_LMS_20220429.sql
#echo "TOYO DATABASEインポートスクリプトをコンテナ内に転送する"
#docker cp /home/matsubara/backup/importdb.sh ${TARGET}_db:/home/importdb.sh
#echo "権限を設定する"
#docker exec -it --user root ${TARGET}_db chmod 777 /home/importdb.sh
#echo "DATABASEインポートスクリプトを実行する"
#docker exec -it --user root ${TARGET}_db /bin/sh /home/importdb.sh

else
docker cp /home/matsubara/phpinfo.php ${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/
docker cp /home/matsubara/backup/adminer.php ${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/
fi

if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi


cd /home/matsubara/${TARGET}
if [ $COMPILE = "y" ];then
## ---------------------------------
echo "===== コンテナを再構築する ====="
echo " 起動中コンテナを削除する（1/4）"
 docker-compose down
echo " コンテナをコンパイルする（2/4）"
 docker-compose build
echo " コンテナを構築・起動する（3/4）"
 docker-compose up -d
#echo " コンテナデータを取得する（4/4）"
# kusanagi-docker config pull 
else
echo " すべてのコンテナを再起動する"
 kusanagi-docker restart
fi
echo "Complete!"


#https://drushcommands.com/drush-9x/site/site:install/
#https://www.white-root.com/drush-commands/site_install
echo "サイトを構築する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
	"cd /home/kusanagi/${TARGET}/DocumentRoot \
	&& php drush.phar site:install \
	--db-url=mysql://lampuser:lamppass@localhost:3306/database \
	--account-name=admin \
	--account-pass=admin "
#docker exec -it --user root ${TARGET}_php ls -al /usr/local/bin
#docker exec -it --user root ${TARGET}_php ls -al /usr/local/bin




## ---------------------------------
echo "complete successfully!!!!!!!!"
exit 0


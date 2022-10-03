####################################
BASEAPP="lamp"
#LAMPAPP=""
LAMPAPP="drupal9"
PROJAPP=
#XDEBUG/GITを追加してイメージを再生成する
COMPILE=n
webserver="--httpd"
#FOR DRUPAL8.x
#php="--php74"
php=

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
chmod 777 /home/matsubara/${TARGET}/contents/ -R
kusanagi-docker remove ${TARGET}


## ---------------------------------
echo "KusanagiRoDでプロビジョニングを作成する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi

if [ $BASEAPP = "wp" ];then
echo "KusanagiRoDでWordPress環境生成"
kusanagi-docker provision --wp ${webserver} --wplang=ja --admin-user=sinceretechnology --admin-pass=wordpress --admin-email=admin@sinceretechnology.com.au --wp-title=WordPress --kusanagi-pass=kusanagi --dbname=wordpress --dbuser=wordpress --dbpass=wordpress --http-port=80 --tls-port=443 --fqdn ${TARGET}${TLD} ${TARGET}
elif [ $BASEAPP = "drupal8" ];then
echo "KusanagiRoDでDrupal8環境構築"
	kusanagi-docker provision --drupal8 ${webserver} ${php}  --kusanagi-pass=kusanagi --dbname=drupal8db --dbuser=drupaluser --dbpass=drupalpass --http-port=80 --tls-port=443 --fqdn ${TARGET}${TLD} ${TARGET}
elif [ $BASEAPP = "lamp" ];then
echo "KusanagiRoDでLAMP環境構築"
kusanagi-docker provision --lamp ${webserver} ${php}  --kusanagi-pass=kusanagi --dbname=database --dbuser=lampuser --dbpass=lamppass --http-port=80 --tls-port=443 --fqdn ${TARGET}${TLD} ${TARGET}
else
    echo "Application type is not defined!!"
    echo "Terminate abnormally!!!!!"
    exit 1
fi

## ---------------------------------
echo "KusanagiRoDで環境構築完了しました"
echo "http://${TARGET}${TLD} にアクセスして確認してください"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi


if [ $COMPILE = "y" ];then
echo "php環境をカスタマイズして開発環境を構築します"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
## ---------------------------------
cd /home/matsubara/backup
mkdir /home/matsubara/${TARGET}/contents/DocumentRoot/temp
echo "PHPソースファイルをワークフォルダに移動"
cp -rf /home/matsubara/backup/kusanagi-php-php8.1 /home/matsubara/${TARGET}


echo "docker-compose.ymlのPHPサービスを更新する"
cp /home/matsubara/${TARGET}/docker-compose.yml /home/matsubara/${TARGET}/docker-compose.yml.bak
#cp /home/matsubara/backup/docker-compose.yml.template /home/matsubara/${TARGET}/docker-compose.yml

#PHPにBUILDを追加する
sed '/image: primestrategy\/kusanagi-php/a \    build:\n      context: ./kusanagi-php-php8.1\n      dockerfile: Dockerfile' /home/matsubara/${TARGET}/docker-compose.yml.bak > /home/matsubara/${TARGET}/docker-compose.yml.temp
#PHPのIMAGEをコメントアウトする
sed 's/image: primestrategy\/kusanagi-php/#image: primestrategy\/kusanagi-php/' /home/matsubara/${TARGET}/docker-compose.yml.temp > /home/matsubara/${TARGET}/docker-compose.yml

echo "Complete!"
## ---------------------------------
fi


#########################################
## ここからWORDPRESS用の処理を記述する ##
#########################################
if [ $BASEAPP = "wp" ];then
echo "WORDPRESSのアプリをインストールします"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
cd /home/matsubara/backup
## ---------------------------------
cp ./MYSQL_DATABASE.sql ../${TARGET}/contents/DocumentRoot/temp
cp ./WP_UPLOADS.tar.gz  ../${TARGET}/contents/DocumentRoot/temp
cp ./WP_THEMES.tar.gz   ../${TARGET}/contents/DocumentRoot/temp
cp ./WP_PLUGINS.tar.gz  ../${TARGET}/contents/DocumentRoot/temp
## ---------------------------------
echo "tempフォルダ内でバックアップファイルを展開する"
cd  ../${TARGET}/contents/DocumentRoot/temp
tar zxvf -oq WP_UPLOADS.tar.gz
tar zxvf -oq WP_THEMES.tar.gz
tar zxvf -oq WP_PLUGINS.tar.gz
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
echo "アプリファイルをDOCKER内に展開する"
cd /home/matsubara/${TARGET}
kusanagi-docker config push
echo "complete!"
#DOCERコピーコマンドを使ってホストからコンテナ内にデータを送る方法もある（こちらのほうが効率的かも）
#docker cp /home/matsubara/backup/MYSQL_DATABASE.sql ${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/temp/MYSQL_DATABASE.sql

## ---------------------------------
echo "データベースをインポートする"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
kusanagi-docker wp db import /home/kusanagi/${TARGET}/DocumentRoot/temp/MYSQL_DATABASE.sql
echo "complete import db"

## ---------------------------------
echo "データベースのURLをWP-CLIで一括置換する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
kusanagi-docker wp search-replace https://goodhealthbetterlife.com.au http://${TARGET}${TLD}
kusanagi-docker wp search-replace goodhealthbetterlife.com.au ${TARGET}${TLD}
echo "Complete!"
#if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi

## ---------------------------------
echo "【DOCER環境】パーミッションを変更"
docker-compose run config chmod 777 /home/kusanagi/${TARGET}/DocumentRoot/wp-content -R
echo "【DOCER環境】ユーザーを変更"
docker exec -it --user root ${TARGET}_httpd chown kusanagi:kusanagi /home/kusanagi/${TARGET}/DocumentRoot/wp-content -R

## ---------------------------------
echo "【DOCER環境】不要プラグインを削除（PHPバージョンによりエラーが発生するため対応）"
docker-compose run config rm -rf /home/kusanagi/${TARGET}/DocumentRoot/wp-content/plugins/brozzme-db-prefix-change

## ---------------------------------
echo "開発用プラグインをインストールする"
kusanagi-docker wp plugin install query-monitor
kusanagi-docker wp plugin activate query-monitor

echo "Complete!"
#if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
fi #wp ここまで


#########################################
## ここから Drupal9用の処理を記述する  ##
#########################################
if [ $BASEAPP = "lamp" ] && [ $LAMPAPP = "drupal9" ];then
#DRUPAL作成用SHをDOCKER内に転送する
#docker cp /home/matsubara/backup/builddrupal.sh ${TARGET}_php:/home/kusanagi/${TARGET}/
#権限を変更する
#docker exec -it --user root ${TARGET}_php chmod 777 /home/kusanagi/${TARGET}/builddrupal.sh
#シェルを実行する
#docker exec -it --user root ${TARGET}_php /bin/sh /home/kusanagi/${TARGET}/builddrupal.sh


echo "【Docker環境】Drupal9.3をインストールする"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
# Drupalプロジェクト作成のためDocumentRootフォルダをいったん削除する
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/ \
	&& rm -rf ./DocumentRoot"

# DrupalをComposerでインストールする
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/ \
	&& composer create-project drupal/recommended-project \
	./DocumentRoot"

echo "【Docker環境】DRUSHをインストールする"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
# Drush latest version
# https://www.drupal.org/docs/develop/using-composer/using-composer-to-install-drupal-and-manage-dependencies
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/DocumentRoot \
	&& composer require drush/drush"

echo "【Docker環境】DRUSH LAUNCHERをインストールする"
docker cp /home/matsubara/backup/drush.phar \
	${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/drush.phar

docker exec -it --user root ${TARGET}_php \
	chmod +x /home/kusanagi/${TARGET}/DocumentRoot/drush

###########################################################
##
## これがないとCSSが適用されない？？
##
###########################################################
docker exec -it --user root ${TARGET}_php mkdir /home/kusanagi/${TARGET}/DocumentRoot/web/sites/default/files
docker exec -it --user root ${TARGET}_php mkdir /home/kusanagi/${TARGET}/DocumentRoot/web/sites/default/files/translations
docker exec -it --user root ${TARGET}_php cp /home/kusanagi/${TARGET}/DocumentRoot/web/sites/default/default.settings.php /home/kusanagi/${TARGET}/DocumentRoot/web/sites/default/settings.php
docker exec -it --user root ${TARGET}_php chmod 777 /home/kusanagi/${TARGET}/DocumentRoot/web -R




echo "【Docker環境】ドキュメントルートを変更する"
cp  /home/matsubara/${TARGET}/.kusanagi /home/matsubara/${TARGET}/.kusanagi.bak
sed 's/\/DocumentRoot/\/DocumentRoot\/web/' /home/matsubara/${TARGET}/.kusanagi.bak > /home/matsubara/${TARGET}/.kusanagi.temp
sed 's/ROOT_DIR=DocumentRoot/\ROOT_DIR=web/' /home/matsubara/${TARGET}/.kusanagi.temp > /home/matsubara/${TARGET}/.kusanagi

##TODO: Debug 後でコメントアウトすること
#exit 0
fi


cd /home/matsubara/${TARGET}
echo "<?php phpinfo();" > /home/matsubara/phpinfo.php
## ---------------------------------
if [ $BASEAPP = "lamp" ] && [ $LAMPAPP = "drupal9" ];then
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


#https://drushcommands.com/drush-9x/site/site:install/
#https://www.white-root.com/drush-commands/site_install
if [ $BASEAPP = "lamp" ] && [ $LAMPAPP = "drupal9" ];then
echo "Drupal9サイトを構築する"
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
fi


cd /home/matsubara/${TARGET}
if [ $COMPILE = "y" ];then
## ---------------------------------
echo "===== コンテナを再構築する ====="
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
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

echo "すべてのキャッシュをクリアする"
docker exec -it --user root toyo-drupal9_php \
  /bin/sh -c \
  "cd /home/kusanagi/toyo-drupal9/DocumentRoot \
    && php drush.phar cr"



if [ $BASEAPP = "lamp" ] \
  && [ $LAMPAPP = "drupal9" ] \
  && [ $PROJAPP = "toyo" ];then
    echo "TOYOサイトをインストールする"
    cd /home/matsubara
    /bash/sh installapp_toyo.sh ${TARGET} ${COMPILE}
fi

## ---------------------------------
echo "complete successfully!!!!!!!!"
exit 0


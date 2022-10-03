
echo count=$#
if [ $# -eq 2 ] && [ $1 = "foodpotal" ];then
    PROFILE=$1
    TARGET=$2
    autoexec=0
elif [ $# -eq 2 ] && [ $1 = "toyo" ];then
    PROFILE=$1
    TARGET=$2
    autoexec=0
elif [ $# -eq 3 ] && [ $1 = "foodpotal" ];then
    PROFILE=$1
    TARGET=$2
    autoexec=$3
elif [ $# -eq 3 ] && [ $1 = "toyo" ];then
    PROFILE=$1
    TARGET=$2
    autoexec=$3
elif [ $# -eq 3 ] && [ $1 = "drupal9" ];then
    PROFILE=$1
    TARGET=$2
    autoexec=$3
else
    echo "引数を確認してください"
    echo "【コマンド書式】"
    echo "buildnewdocker.sh 第一引数(必須) 第二引数(必須) 第三引数(オプション)"
    echo "【第一引数】(必須) buildnewdocker.confで定義したプロファイル名を指定"
    echo "【第二引数】(必須) 新しく作成する仮想環境のプロビジョン名（フォルダ名）を指定"
    echo "【第三引数】(オプション) ステップごとに確認メッセージ表示の有無(0:STEP、1:自動) "
    exit 1
    #autoexec=0
fi
####################################

####################################
#上記設定は環境設定ファイルに一元化した
source ./buildnewdocker.conf
####################################
echo "PROFILE=${PROFILE}"
echo "TARGET=${TARGET}"
echo "autoexec=${autoexec}"
echo "PROJAPP=${PROJAPP}"

## ---------------------------------
echo "プロビジョニング：${TARGET} を作成します。すでにある場合は削除されますのでご注意ください"
echo "BASEAPPは、${BASEAPP}です。"
echo "FDQNは、${TARGET} ${TLD}です。"
echo "/windows/system32/drivers/etc/hostsで上記FDQNが127.0.0.1に紐付けられていることを確認ください"
if [ $autoexec -eq 1 ];then echo "完了するまで止まりません"; fi
read -p "Press [Enter] key to build dockerfile." 

echo "現在起動中のコンテナをすべて停止する"
docker stop $(docker ps -q)

#削除
echo "【KusanagiRoD】対象のプロビジョニングが既に存在する場合は削除する"
chmod 777 /home/matsubara/${TARGET}/contents/ -R  > /dev/null 

kusanagi-docker remove ${TARGET}


## ---------------------------------
echo "【KusanagiRoD】プロビジョニングを作成する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi

if [ $BASEAPP = "wp" ];then
echo "【KusanagiRoD】WordPress環境生成"
#echo "kusanagi-docker provision --wp ${webserver} --wplang=ja --admin-user=sinceretechnology --admin-pass=wordpress --admin-email=admin@sinceretechnology.com.au --wp-title=WordPress --kusanagi-pass=${kusanagipass} --dbname=wordpress --dbuser=wordpress --dbpass=wordpress --http-port=80 --tls-port=443 --fqdn ${TARGET}${TLD} ${TARGET}"

kusanagi-docker provision --wp ${webserver} --wplang=ja --admin-user=${adminuser} --admin-pass=${adminpass} --admin-email=${adminemail} --wp-title=WordPress --kusanagi-pass=${kusanagipass} --dbname=${dbname} --dbuser=${dbuser} --dbpass=${dbpass} --http-port=80 --tls-port=443 --fqdn ${TARGET}${TLD} ${TARGET}


elif [ $BASEAPP = "drupal8" ];then
echo "【KusanagiRoD】Drupal8環境構築"
	kusanagi-docker provision --drupal8 ${webserver} ${php} --kusanagi-pass=${kusanagipass} --dbname=${dbname} --dbuser=${dbuser} --dbpass=${dbpass} --http-port=80 --tls-port=443 --fqdn ${TARGET}${TLD} ${TARGET}
elif [ $BASEAPP = "lamp" ];then
echo "【KusanagiRoD】LAMP環境構築"
kusanagi-docker provision --lamp ${webserver} ${php} --kusanagi-pass=${kusanagipass} --dbname=${dbname} --dbuser=${dbuser} --dbpass=${dbpass} --http-port=80 --tls-port=443 --fqdn ${TARGET}${TLD} ${TARGET}
else
    echo "Application type is not defined!!"
    echo "Terminate abnormally!!!!!"
    exit 1
fi

## ---------------------------------
echo "【KusanagiRoD】環境構築完了しました"
echo "http://${TARGET}${TLD} にアクセスして確認してください"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi


if [ $COMPILE = "y" ];then
echo "【PHPDocker環境】phpコンテナに開発用サービスをを追加する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
## ---------------------------------
cd /home/matsubara/backup
mkdir /home/matsubara/${TARGET}/contents/DocumentRoot/temp
echo "【PHPDocker環境】phpコンテナ用Dockerfileを取得する"
cp -rf /home/matsubara/backup/kusanagi-php-php8.1 /home/matsubara/${TARGET}


echo "【PHPDocker環境】docker-compose.ymlの設定を変更する"
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
## ここから Drupal9用の処理を記述する  ##
#########################################
if [ $BASEAPP = "lamp" ] && [ $LAMPAPP = "drupal9" ];then

echo "【PHPDocker環境】Drupal9.3をインストールする"
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

###########################################################
## これがないとCSSが適用されない
## 翻訳ファイル用フォルダや設定ファイルは自動生成されない？
###########################################################

docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/ \
	&& mkdir ./DocumentRoot/web/sites/default/files "
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/ \
	&& mkdir ./DocumentRoot/web/sites/default/files/translations "
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/DocumentRoot/web/sites/default/ \
	&& cp ./default.settings.php \
	      ./settings.php "
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET} \
	&& chmod 777 ./DocumentRoot -R"

## ---------------------------------
echo "【PHPDocker環境】DRUSHをインストールする"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi

# Drush latest version
# https://www.drupal.org/docs/develop/using-composer/using-composer-to-install-drupal-and-manage-dependencies
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/DocumentRoot \
	&& composer require drush/drush"

## ---------------------------------
echo "【PHPDocker環境】DRUSH LAUNCHERをインストールする"
#DRUSHを起動するためのスクリプト
docker cp /home/matsubara/backup/drush.phar \
	${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/drush.phar

docker exec -it --user root ${TARGET}_php \
	chmod +x /home/kusanagi/${TARGET}/DocumentRoot/drush

## ---------------------------------
echo "【KusanagiRoD】ドキュメントルートを変更する"
# .kusanagiファイルのドキュメントルート設定を変更する。
# 再起動後に反映される
cp  /home/matsubara/${TARGET}/.kusanagi \
    /home/matsubara/${TARGET}/.kusanagi.bak
sed 's/\/DocumentRoot/\/DocumentRoot\/web/' \
    /home/matsubara/${TARGET}/.kusanagi.bak \
    > /home/matsubara/${TARGET}/.kusanagi.temp
sed 's/ROOT_DIR=DocumentRoot/ROOT_DIR=web/' \
    /home/matsubara/${TARGET}/.kusanagi.temp \
    > /home/matsubara/${TARGET}/.kusanagi
fi

if [ $BASEAPP = "lamp" ] && [ $LAMPAPP = "drupal9" ];then
    DOCROOT=DocumentRoot/web
else
    DOCROOT=DocumentRoot
fi
echo "ドキュメントルートにデータベースツール他ファイルを転送する"
docker cp /home/matsubara/backup/phpinfo.php \
        ${TARGET}_php:/home/kusanagi/${TARGET}/${DOCROOT}/phpinfo.php
docker cp /home/matsubara/backup/adminer.php \
        ${TARGET}_php:/home/kusanagi/${TARGET}/${DOCROOT}/adminer.php

#https://drushcommands.com/drush-9x/site/site:install/
#https://www.white-root.com/drush-commands/site_install
if [ $BASEAPP = "lamp" ] && [ $LAMPAPP = "drupal9" ];then
echo "Drupalサイト構築をDrushから実行する（通常GUIで行う設定が不要）"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
	"cd /home/kusanagi/${TARGET}/DocumentRoot \
	&& php drush.phar site:install \
	--db-url=mysql://${dbuser}:${dbpass}@localhost:3306/${dbname} \
	--account-name=${adminuser} \
	--account-pass=${adminpass} "
fi

#########################################
## ここからデプロイしたいアプリがあれば
## サブスクリプトを呼び出して実行する
#########################################
# 
if [ -n "$APPDEPLOY_SCRIPT" ] \
    && [ -e "/home/matsubara/$APPDEPLOY_SCRIPT" ]; then
    #スクリプトの実行
    echo "プロファイルに指定されたスクリプトを実行する"
    echo "【スクリプト】source /home/matsubara/${APPDEPLOY_SCRIPT} ${TARGET} ${autoexec}"
    #source /home/matsubara/${APPDEPLOY_SCRIPT} ${PROFILE} ${TARGET} ${autoexec}
elif [ -n "$APPDEPLOY_SCRIPT" ] \
    && [ ! -e "/home/matsubara/$APPDEPLOY_SCRIPT" ]; then
    echo "エラーにより処理を中断しました"
    echo "アプリデプロイ用スクリプトが存在しません！！"
    echo "アプリのデプロイが必要な場合は手動でスクリプトを起動してください"
    exit 1
fi

# コンパイルありまたはスクリプトを実行した場合はコンテナの再起動を行う
cd /home/matsubara/${TARGET}
if [ -n "$APPDEPLOY_SCRIPT" ] \
    || [ $COMPILE = "y" ];then
## ---------------------------------
echo "現在のディレクトリ： /home/matsubara/${TARGET}"
echo "===== コンテナを再構築する ====="
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
echo " 起動中コンテナを削除する（1/4）"
 docker-compose down
echo " コンテナをコンパイルする（2/4）"
 docker-compose build --no-cache
echo " コンテナを構築・起動する（3/4）"
 docker-compose up -d
#echo " コンテナデータを取得する（4/4）"
# kusanagi-docker config pull 
else
echo " すべてのコンテナを再起動する"
 kusanagi-docker restart
fi
echo "Complete!"

if [ $BASEAPP = "lamp" ] && [ $LAMPAPP = "drupal9" ];then
  echo "すべてのキャッシュをクリアする"
  docker exec -it --user root ${TARGET}_php \
    /bin/sh -c \
    "cd /home/kusanagi/${TARGET}/DocumentRoot \
      && php drush.phar cr"
fi

if [ -n "$APPDEPLOY_SCRIPT" ] \
    && [ -e "/home/matsubara/$APPDEPLOY_SCRIPT" ]; then
    #スクリプトの実行
    echo "プロファイルに指定されたスクリプトを実行する"
    echo "【スクリプト】source /home/matsubara/${APPDEPLOY_SCRIPT} ${TARGET} ${autoexec}"
    source /home/matsubara/${APPDEPLOY_SCRIPT} ${PROFILE} ${TARGET} ${autoexec}
elif [ -n "$APPDEPLOY_SCRIPT" ] \
    && [ ! -e "/home/matsubara/$APPDEPLOY_SCRIPT" ]; then
    echo "エラーにより処理を中断しました"
    echo "アプリデプロイ用スクリプトが存在しません！！"
    echo "アプリのデプロイが必要な場合は手動でスクリプトを起動してください"
    exit 1
fi

## ---------------------------------
echo "complete successfully!!!!!!!!"
exit 0


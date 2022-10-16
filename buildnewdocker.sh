########################################################
## SCRIPT TITLE: KUSANAGI-RoD LOCAL ENV AUTO CREATION
## MODULE NAME: MAIN MODULE
## DESCRIPTION: MAIN PROCEDURE TO BUILD LOCAL ENV
## CREATED DATE: 2022/10/01
## NOTE :
########################################################


####################################
#引数のチェック＆取得、変数に設定する
source ${HOME_DIR}buildnewdocker_init.sh
####################################

echo "/windows/system32/drivers/etc/hostsで上記FDQNが127.0.0.1に紐付けられていることを確認ください"
if [ -z "$debugmode" ];then echo "完了するまで止まりません"; fi
read -p "Press [Enter] key to move on to the next." 


####################################
echo "STOP ALL DOCKER-CONTAINERS."
echo "現在起動中のコンテナをすべて停止する"
docker stop $(docker ps -q)
####################################

####################################
#PROVISIONフォルダの削除
if [ -d "${HOME_DIR}${TARGET}" ]; then
  echo "REMOVE PROVISION FOLDER FOR KUSANAGI-ROD."
  echo "【KusanagiRoD】対象のプロビジョニングが既に存在する場合は削除する"
  chmod 777 ${HOME_DIR}${TARGET}/contents/ -R  > /dev/null 
  kusanagi-docker remove ${TARGET}
  echo "COMPLETE REMOVING PROVISION FOLDER FOR KUSANAGI-ROD."
  echo "【KusanagiRoD】既存のプロビジョニングの削除を完了しました"
else
  echo "PROVISION FOLDER CHECK OK."
  echo "対象プロビジョニング存在チェックOK"
ls ${HOME_DIR}${TARGET}
fi
####################################


#####################################
# 現在時刻を取得
_started_at=$(date +'%s.%3N')
#####################################


#####################################
echo "CREATE PROVISION BY KUSANAGI-ROD COMMAND"
echo "【KusanagiRoD】プロビジョニングを作成する"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi

if [ "$BASEAPP" = "wp" ];then
echo "CREATE WORDPRESS PROVISION BY KUSANAGI-ROD COMMAND"
echo "【KusanagiRoD】WordPress環境生成"
#echo "kusanagi-docker provision --wp ${webserver} --wplang=ja --admin-user=sinceretechnology --admin-pass=wordpress --admin-email=admin@sinceretechnology.com.au --wp-title=WordPress --kusanagi-pass=${kusanagipass} --dbname=wordpress --dbuser=wordpress --dbpass=wordpress --http-port=80 --tls-port=443 --fqdn ${TARGET}${TLD} ${TARGET}"

echo "kusanagi-docker provision --wp ${webserver} --wplang=ja --admin-user=${adminuser} --admin-pass=${adminpass} --admin-email=${adminemail} --wp-title=WordPress --kusanagi-pass=${kusanagipass} --dbname=${dbname} --dbuser=${dbuser} --dbpass=${dbpass} --http-port=80 --tls-port=443 --fqdn ${FQDN} ${TARGET}"
kusanagi-docker provision --wp ${webserver} --wplang=ja --admin-user=${adminuser} --admin-pass=${adminpass} --admin-email=${adminemail} --wp-title=WordPress --kusanagi-pass=${kusanagipass} --dbname=${dbname} --dbuser=${dbuser} --dbpass=${dbpass} --http-port=80 --tls-port=443 --fqdn ${FQDN} ${TARGET}


elif [ "$BASEAPP" = "drupal8" ];then
echo "CREATE DRUPAL8 PROVISION BY KUSANAGI-ROD COMMAND"
echo "【KusanagiRoD】Drupal8環境構築"
echo "kusanagi-docker provision --drupal8 ${webserver} ${php} --kusanagi-pass=${kusanagipass} --dbname=${dbname} --dbuser=${dbuser} --dbpass=${dbpass} --http-port=80 --tls-port=443 --fqdn ${FQDN} ${TARGET}"
kusanagi-docker provision --drupal8 ${webserver} ${php} --kusanagi-pass=${kusanagipass} --dbname=${dbname} --dbuser=${dbuser} --dbpass=${dbpass} --http-port=80 --tls-port=443 --fqdn ${FQDN} ${TARGET}
elif [ "$BASEAPP" = "lamp" ];then
echo "CREATE LAMP PROVISION BY KUSANAGI-ROD COMMAND"
echo "【KusanagiRoD】LAMP環境構築"
echo "kusanagi-docker provision --lamp ${webserver} ${php} --kusanagi-pass=${kusanagipass} --dbname=${dbname} --dbuser=${dbuser} --dbpass=${dbpass} --http-port=80 --tls-port=443 --fqdn ${FQDN} ${TARGET}"
kusanagi-docker provision --lamp ${webserver} ${php} --kusanagi-pass=${kusanagipass} --dbname=${dbname} --dbuser=${dbuser} --dbpass=${dbpass} --http-port=80 --tls-port=443 --fqdn ${FQDN} ${TARGET}
else
    echo "Application type is not defined!!"
    echo "Terminate abnormally!!!!!"
    exit 1
fi

#####################################
echo "COMPLETE CREATING PROVISION BY KUSANAGI-ROD COMMAND."
echo "PLEASE CONFIRM CONNECTING TO http://${TARGET}${TLD} "
echo "IF NETWORK ERROR OCCURRED, REMOVE UNUSED NETWORK."
echo "【KusanagiRoD】環境構築完了しました"
echo "http://${TARGET}${TLD} にアクセスして確認してください"
echo "【注意】Dockerのネットワークエラーが発生した場合は、不要なネットワークを削除してください"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi


if [ "$COMPILE" = "y" ];then
echo "RE-COMPILE DOCKER-PHP-CONTAINER TO ADD DEVELOPERS PACKAGES."
echo "【PHPDocker環境】phpコンテナに開発用サービスを追加する"
echo "コンパイル用ソース一式を${KUSANAGIPHPSRC}に取得・コンパイルしてイメージを再構築する"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
#####################################
cd ${HOME_DIR}backup
mkdir ${HOME_DIR}${TARGET}/contents/DocumentRoot/temp
echo "COPY PHP SOURCE FILES TO PROVISION DIRECTORY."
echo "【PHPDocker環境】phpコンテナ用Dockerfileを取得する"
cp -rf ${HOME_DIR}backup/${KUSANAGIPHPSRC} ${HOME_DIR}${TARGET}


echo "CHANGE SETTINGS OF docker-compose.yml"
echo "【PHPDocker環境】docker-compose.ymlの設定を変更する"
cp ${HOME_DIR}${TARGET}/docker-compose.yml ${HOME_DIR}${TARGET}/docker-compose.yml.bak
#cp ${HOME_DIR}backup/docker-compose.yml.template ${HOME_DIR}${TARGET}/docker-compose.yml

#PHPにBUILDを追加する
sed -i "/image: primestrategy\/kusanagi-php/a \    build:\n      context: ./${KUSANAGIPHPSRC}\n      dockerfile: Dockerfile" ${HOME_DIR}${TARGET}/docker-compose.yml  #del > ${HOME_DIR}${TARGET}/docker-compose.yml.temp
#PHPのIMAGEをコメントアウトする
sed -i "s/image: primestrategy\/kusanagi-php/#image: primestrategy\/kusanagi-php/" ${HOME_DIR}${TARGET}/docker-compose.yml #del > ${HOME_DIR}${TARGET}/docker-compose.yml

echo "COMPLETE UPDATING docker-complete.yml"
#####################################
fi

if [ "$RESTOREIMAGE" = "y" ];then
echo "RESTORE DOCKER IMAGE FROM BACKUP IMG FILE."
echo "【PHPDocker環境】Docker imageを復元する"
  if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
  #BUILDで作成したIMAGEのバックアップ
  #docker image save ${TARGET}_php:latest > ${HOME_DIR}${TARGET}/IMG_${TARGET}_php.tar
  #BUILDで作成したIMAGEの復元
  T="${HOME_DIR}${ARCHIVES_DIR}/${ARCHIVE_IMAGE_PHP}"; if [ ! -e $T ];then echo "${T} が存在しません"; exit 0; fi
  docker image load < ${HOME_DIR}${ARCHIVES_DIR}/${ARCHIVE_IMAGE_PHP}

  # TODO: ここで旧DOCKER IMAGE名を新しい名前 ${TARGET}_PHP にリネームする
  # TODO: プロファイル名のフォルダが作成されているためIMAGE名だけ変更しても不可
  # TODO: /home/kusanagiの下のフォルダ名をプロファイル名（$TARGET）に変更する必要あり

  # イメージ名を${ORGTARGET}_phpから"${TARGET}_php"に変更する
  if [ -n "${ORGTARGET}" ] && [ "${ORGTARGET}" != "${TARGET}" ];then
    # https://qiita.com/hirocueki/items/4f077795ac8d94c6ad8f
    echo "CHANGE NAME OF PHP-CONTAINER-IMAGE.（${ORGTARGET}_php -> ${TARGET}_php）"
    echo "【PHPDocker環境】インポートしたIMAGEの名前を変更する（${ORGTARGET}_php -> ${TARGET}_php）"
    temp=`docker ps -aq --filter name=tempdockercanbedelete`
    if [ -n "$temp" ]; then
      docker rm $temp
    fi
    docker run -d --name="tempdockercanbedelete" ${ORGTARGET}_php
    docker commit tempdockercanbedelete "${TARGET}_php"
    docker stop tempdockercanbedelete
    docker rm tempdockercanbedelete
    docker rmi ${ORGTARGET}_php
  fi

  echo "UPDATE docker-composer.yml TO CHANGE NAME OF PHP-CONTAINER-IMAGE."
  echo "【PHPDocker環境】docker-compose.ymlのphpサービスのIMAGEを変更する"
  if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi

  #PHPにBUILDを追加する
  sed -i "/image: primestrategy\/kusanagi-php/a \    image: ${TARGET}_php \n" ${HOME_DIR}${TARGET}/docker-compose.yml
  sed -i "s/image: primestrategy\/kusanagi-php/#image: primestrategy\/kusanagi-php/" ${HOME_DIR}${TARGET}/docker-compose.yml
  echo "【PHPDocker環境】docker-compose.ymlのphpサービスのIMAGEを変更完了"
  if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
fi

# コンパイルありまたはスクリプトを実行した場合はコンテナの再起動を行う
cd ${HOME_DIR}${TARGET}
if [ "$COMPILE" = "y" ] || [ "$RESTOREIMAGE" = "y" ];then
#####################################
echo "RE-BUILD DOCKER-CONTAINER. (CURRENT DIR: ${HOME_DIR}${TARGET} )"
echo "現在のディレクトリ： ${HOME_DIR}${TARGET}"
echo "===== コンテナを再構築する ====="
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
echo " STOP CURRENT DOCKER-CONTAINER（1/3）"
echo " 起動中コンテナを削除する（1/3）"
 docker-compose down
echo " COMPILE DOCKER-CONTAINER（1/3）"
echo " コンテナをコンパイルする（2/3）"
 docker-compose build ${nocashe}
echo " RESTART DOCKER-CONTAINER（3/3）"
echo " コンテナを構築・起動する（3/3）"
 docker-compose up -d
#echo " コンテナデータを取得する（4/4）"
# kusanagi-docker config pull
else
echo " RESTART DOCKER-CONTAINER BY KUSANAGI-ROD COMMAND."
echo " すべてのコンテナを再起動する"
 kusanagi-docker restart
fi
echo "COMPLETE RESTARTING DOCKER-CONTAINER."
#####################################

#########################################
## ここから Drupal9用の処理を記述する  ##
## LAMP環境にDRUPAL9をインストールする ##
#########################################
#####################################
if [ "$BASEAPP" = "lamp" ] && [ "$LAMPAPP" = "drupal9" ];then
#####################################
echo "INSTALL Drupal9.3 DIRECTORY INSIDE DOCKER-CONTAINER USING COMPOSER."
echo "【PHPDocker環境】Drupal9.3をCOMPOSERでインストールする"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
# Drupalプロジェクト作成のためDocumentRootフォルダをいったん削除する
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/ \
	&& rm -rf ./DocumentRoot"

# DrupalをComposerでインストールする
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/ \
	&& composer create-project drupal/recommended-project${DRUPAL_VER} \
	./DocumentRoot"
#####################################

###########################################################
## これがないとCSSが適用されない
## 翻訳ファイル用フォルダや設定ファイルは自動生成されない？
###########################################################

#####################################
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
#####################################

#####################################
echo "INSTALL DRUSH PACKAGE."
echo "【PHPDocker環境】DRUSHをインストールする"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi

# Drush latest version
# https://www.drupal.org/docs/develop/using-composer/using-composer-to-install-drupal-and-manage-dependencies
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/DocumentRoot \
	&& composer require drush/drush"
#####################################

#####################################
echo "INSTALL DRUSH LAUNCHER."
echo "【PHPDocker環境】DRUSH LAUNCHERをインストールする"
#DRUSHを起動するためのスクリプト
docker cp ${HOME_DIR}backup/drush.phar \
	${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/drush.phar

docker exec -it --user root ${TARGET}_php \
	chmod +x /home/kusanagi/${TARGET}/DocumentRoot/drush
#####################################
####################################
## NOTICE!!!!!!
## DRUSH RCをするとエラーになる件
## PHPのMEMORY＿LIMITを512MGにする
## https://support-acquia.force.com/s/article/360005311613-Increasing-the-memory-limit-for-Drush
##
## Add blow code to settings.php file.  
## -------------------
## if (PHP_SAPI === 'cli') {
##   ini_set('memory_limit', '512M');
## }
## -------------------
####################################
fi

###########################################################
## ドキュメントルートにデータベースツール他ファイルを転送
###########################################################
#.kusanagiのBAKファイルを作成する
cp  ${HOME_DIR}${TARGET}/.kusanagi \
    ${HOME_DIR}${TARGET}/.kusanagi.bak
#####################################
if [ -n "$DOCUMENTROOT" ]; then
    #####################################
    echo "CHANGE DOCUMENTROOT FOR DRUPAL."
    echo "【KusanagiRoD】ドキュメントルートを変更する"
    # .kusanagiファイルのドキュメントルート設定を変更する。
    # 再起動後に反映される
    #sed -i "s/\/DocumentRoot/\/DocumentRoot\/web/" \
    #    ${HOME_DIR}${TARGET}/.kusanagi
    sed -i "s/\/DocumentRoot/\/${DOCUMENTROOT}/" \
        ${HOME_DIR}${TARGET}/.kusanagi
    #ドキュメントルート用変数の設定
    DOCROOT=DocumentRoot/web
else
    #ドキュメントルート用変数の設定
    DOCROOT=DocumentRoot
fi
#####################################
if [ -n "$ROOT_DIR" ]; then
    #####################################
    echo "CHANGE DOCUMENTROOT FOR KUSANAGI-ROD."
    echo "【KusanagiRoD】ドキュメントルートを変更する"
    # .kusanagiファイルのドキュメントルート設定を変更する。
    # 再起動後に反映される
    #sed -i "s/ROOT_DIR=DocumentRoot/ROOT_DIR=web/" \
    #    ${HOME_DIR}${TARGET}/.kusanagi
    sed -i "s/ROOT_DIR=DocumentRoot/ROOT_DIR=${ROOT_DIR}/" \
        ${HOME_DIR}${TARGET}/.kusanagi
fi
#####################################

###########################################################
## Drupalサイト構築をDrushから実行する
###########################################################
#####################################
#https://drushcommands.com/drush-9x/site/site:install/
#https://www.white-root.com/drush-commands/site_install
if [ "$BASEAPP" = "lamp" ] && [ "$LAMPAPP" = "drupal9" ];then
echo "BUILD DRUPAL SITE USING DRUSH COMMAND."
echo "Drupalサイト構築をDrushから実行する（通常GUIで行う設定が不要）"

if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
#INSTALL DRUPAL9
docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
	"cd /home/kusanagi/${TARGET}/DocumentRoot \
	&& php drush.phar site:install \
	--db-url=mysql://${dbuser}:${dbpass}@localhost:3306/${dbname} \
	--account-name=${adminuser} \
	--account-pass=${adminpass} "
#####################################

###########################################################
## DEBUGモードを設定する
###########################################################
#####################################
#SET DEBUG MODE
docker exec -it --user root ${TARGET}_php \
  /bin/sh -c \
  "cd /home/kusanagi/${TARGET}/DocumentRoot/web/sites \
    && cp ./example.settings.local.php ./default/settings.local.php \
    && sed -i -e \"$ a if (file_exists(__DIR__ . '/settings.local.php')) {\n \
    include __DIR__ . '/settings.local.php';\n}\n\" \
    ./default/settings.php"
#COPY CONFIG FILE(settings.local.php) FOR DEBUG
docker cp ${HOME_DIR}backup/settings.local.php \
	${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/web/sites/default/settings.local.php
#COPY CONFIG FILE(development.services.yml) FOR DEBUG
docker cp ${HOME_DIR}backup/development.services.yml \
	${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/web/sites/development.services.yml
fi
#####################################

#########################################
## ここからデプロイしたいアプリがあれば
## サブスクリプトを呼び出して実行する
#########################################
# 
#####################################
if [ -n "$APPDEPLOY_SCRIPT" ] \
    && [ -e "${HOME_DIR}$APPDEPLOY_SCRIPT" ]; then
    #スクリプトの実行
    echo "RUN SCRIPT FILE WHICH IS SET IN buildnewdocker.conf"
    echo "プロファイルに指定されたスクリプトを実行する"
    echo "【スクリプト】source ${HOME_DIR}${APPDEPLOY_SCRIPT} ${TARGET} ${debugmode}"
    #source ${HOME_DIR}${APPDEPLOY_SCRIPT} ${PROFILE} ${TARGET} ${debugmode}
elif [ -n "$APPDEPLOY_SCRIPT" ] \
    && [ ! -e "${HOME_DIR}$APPDEPLOY_SCRIPT" ]; then
    echo "FAILED TO RUN SCRIPT FILE WHICH IS SET IN buildnewdocker.conf"
    echo "エラーにより処理を中断しました"
    echo "アプリデプロイ用スクリプトが存在しません！！"
    echo "アプリのデプロイが必要な場合は手動でスクリプトを起動してください"
    exit 1
fi
#####################################

#####################################
# コンパイルありまたはスクリプトを実行した場合はコンテナの再起動を行う
cd ${HOME_DIR}${TARGET}
if [ "$COMPILE" = "y" ];then
  echo "現在のディレクトリ： ${HOME_DIR}${TARGET}"
  echo "===== コンテナを再構築する ====="
  if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
  echo " STOP CURRENT DOCKER-CONTAINER（1/2）"
  echo " 起動中コンテナを削除する（1/2）"
  docker-compose down
  #echo " コンテナをコンパイルする（2/4）"
  # docker-compose build ${nocashe}
  echo " RESTART DOCKER-CONTAINER（1/2）"
  echo " コンテナを構築・起動する（2/2）"
  docker-compose up -d
  #echo " コンテナデータを取得する（4/4）"
  # kusanagi-docker config pull 
else
echo " RESTART DOCKER-CONTAINER BY KUSANAGI-ROD COMMAND."
echo " すべてのコンテナを再起動する"
  kusanagi-docker restart
fi
echo "Complete!"
#####################################

if [ "$BASEAPP" = "lamp" ] && [ "$LAMPAPP" = "drupal9" ];then
  echo "CLEAR ALL CASHE."
  echo "すべてのキャッシュをクリアする"
  docker exec -it --user root ${TARGET}_php \
    /bin/sh -c \
    "cd /home/kusanagi/${TARGET}/DocumentRoot \
      && php drush.phar cr"
fi
#####################################

#####################################
if [ -n "$APPDEPLOY_SCRIPT" ] \
    && [ -e "${HOME_DIR}$APPDEPLOY_SCRIPT" ]; then
    #スクリプトの実行
    echo "RUN SCRIPT FILE WHICH IS SET IN buildnewdocker.conf"
    echo "プロファイルに指定されたスクリプトを実行する"
    echo "【スクリプト】source ${HOME_DIR}${APPDEPLOY_SCRIPT} ${TARGET} ${debugmode}"
    source ${HOME_DIR}${APPDEPLOY_SCRIPT} ${PROFILE} ${TARGET} ${debugmode}
elif [ -n "$APPDEPLOY_SCRIPT" ] \
    && [ ! -e "${HOME_DIR}$APPDEPLOY_SCRIPT" ]; then
    echo "FAILED TO RUN SCRIPT FILE WHICH IS SET IN buildnewdocker.conf"
    echo "エラーにより処理を中断しました"
    echo "アプリデプロイ用スクリプトが存在しません！！"
    echo "アプリのデプロイが必要な場合は手動でスクリプトを起動してください"
    exit 1
fi
#####################################

#####################################
if [ "$RESTOREFROMDOCKERFILE" = "y" ];then
  echo "RESTORE DOCKER IMAGE FROM BACKUP IMG FILE."
  echo "バックアップからコンテナイメージとボリューム（DB含むデータ）をリストアする"
  if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
  #Volumeバックアップを取得する
  echo "RESTORE DOCKER VOLUME FROM BACKUP ARCHIVE FILE."
  echo "phpコンテナをリストアする"
  T="${HOME_DIR}${ARCHIVES_DIR}/${ARCHIVE_VOLUME_PHP}"; if [ ! -e $T ];then echo "${T} が存在しません"; exit 0; fi
  docker run --rm --volumes-from ${TARGET}_php -v ${HOME_DIR}${ARCHIVES_DIR}:/backup busybox tar xf /backup/${ARCHIVE_VOLUME_PHP}
  echo "RESTORE DOCKER VOLUME FROM BACKUP DATABASE FILE."
  echo "dbコンテナをリストアする"
  T="${HOME_DIR}${ARCHIVES_DIR}/${ARCHIVE_VOLUME_DB}"; if [ ! -e $T ];then echo "${T} が存在しません"; exit 0; fi
  docker run --rm --volumes-from ${TARGET}_db -v ${HOME_DIR}${ARCHIVES_DIR}:/backup busybox tar xf /backup/${ARCHIVE_VOLUME_DB}
fi
#####################################

#####################################
if [ -n "${ORGTARGET}" ] && [ "${ORGTARGET}" != "${TARGET}" ];then
  echo "CHANGE PROFILE FOLDER NAME FROM (${ORGTARGET}) TO (${TARGET})."
  echo "プロファイルフォルダ名を${ORGTARGET}から${TARGET}に変更する"
  docker exec -it --user root ${TARGET}_php \
    /bin/sh -c \
    "cd /home/kusanagi \
      && chmod 777 ${ORGTARGET} -R \
      && rm -rf ${TARGET} \
      && mv ${ORGTARGET} ${TARGET}"
fi
#####################################

#####################################
echo "INSTALL DATABASE APP UNDER DOCUMENTROOT."
echo "ドキュメントルートにデータベースツール他ファイルを転送する"
docker cp ${HOME_DIR}backup/phpinfo.php \
        ${TARGET}_php:/home/kusanagi/${TARGET}/${DOCROOT}/phpinfo.php
docker cp ${HOME_DIR}backup/adminer.php \
        ${TARGET}_php:/home/kusanagi/${TARGET}/${DOCROOT}/adminer.php
#####################################

#####################################
#echo "Add ip address to /etc/hosts file in ${TARGET}_php container to be able to debug using XDEBUG."
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
#hostsファイルにIPアドレスを追加するためのスクリプト
docker cp ${HOME_DIR}backup/initialize-hosts.sh \
	${TARGET}_php:/home/kusanagi/${TARGET}/initialize-hosts.sh

#####################################

#####################################
cd ${HOME_DIR}${TARGET}
echo " RESTART DOCKER-CONTAINER BY KUSANAGI-ROD COMMAND."
echo "現在のディレクトリ： ${HOME_DIR}${TARGET}"
echo " すべてのコンテナを再起動する"
 kusanagi-docker restart
#####################################


#####################################
if [ "$MAKEDOCKERBACKUP" = "y" ];then
  echo "GET BACKUP FILE OF DOCKER CONTAINER IMAGE AND VOLUME."
  echo "再構築したコンテナイメージとボリューム（DB含むデータ）のバックアップを取得する"
  if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
  #BUILDで作成したIMAGEのバックアップ
  docker image save ${TARGET}_php:latest > ${HOME_DIR}${TARGET}/IMG_${TARGET}_php.tar
  #Volumeバックアップを取得する
  docker run --rm --volumes-from ${TARGET}_php -v ${HOME_DIR}${TARGET}:/backup busybox tar cf /backup/VOL_${TARGET}_php.tar /home/kusanagi
  docker run --rm --volumes-from ${TARGET}_db -v ${HOME_DIR}${TARGET}:/backup busybox tar cf /backup/VOL_${TARGET}_db.tar /var/lib/mysql
fi

#####################################
cd ${HOME_DIR}${TARGET}
echo "PULL DOCKER-CONTAINER SOURCE CODES TO HOST PC BY KUSANAGI-DOCKER COMMAND."
echo "コンテナ内データをcontentsフォルダに取得する"
kusanagi-docker config pull
#####################################


#####################################
# 完了時刻を取得
_ended_at=$(date +'%s.%3N')

# 経過時間を計算
_elapsed=$(echo "scale=3; $_ended_at - $_started_at" | bc)

echo "start: $(date -d "@${_started_at}" +'%Y-%m-%d %H:%M:%S.%3N (%:z)')"
echo "end  : $(date -d "@${_ended_at}" +'%Y-%m-%d %H:%M:%S.%3N (%:z)')"
echo "dur:   $_elapsed"
eval "echo Elapsed Time: $(date -ud "@$_elapsed" +'$((%s/3600/24)):%H:%M:%S.%3N')"
#####################################


echo "complete successfully!!!!!!!!"
echo "すべての処理が完了しました!!!!!!!!"
exit 0


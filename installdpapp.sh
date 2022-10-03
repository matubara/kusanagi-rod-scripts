########################################################
## SCRIPT TITLE: KUSANAGI-RoD LOCAL ENV AUTO CREATION
## MODULE NAME: DRUPAL APP RESTORE MODULE
## DESCRIPTION: RESTORE DRUPAL APP WITH BACKUP FILES
## CREATED DATE: 2022/10/01
## NOTE :
########################################################


####################################
#引数のチェック＆取得、変数に設定する
source ${HOME_DIR}buildnewdocker_init.sh
####################################

#########################################
## ここから Drupal9用の処理を記述する  ##
#########################################

## ---------------------------------
#cd ${HOME_DIR}${TARGET}
#echo "すべてのキャッシュをクリアする"
#docker exec -it --user root ${TARGET}_php \
#  /bin/sh -c \
#  "cd /home/kusanagi/${TARGET}/DocumentRoot \
#    && php drush.phar cr"
#echo "アプリケーションのデプロイを完了しました"
## ---------------------------------


cd ${HOME_DIR}${TARGET}
echo "<?php phpinfo();" > ${HOME_DIR}phpinfo.php
## ---------------------------------
if [ "$BASEAPP" = "lamp" ] && [ "$LAMPAPP" = "drupal9" ];then

echo "ツールなどをコンテナ内に転送する"
docker cp ${HOME_DIR}phpinfo.php \
          ${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/web/phpinfo.php
docker cp ${HOME_DIR}backup/adminer.php \
          ${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/web/adminer.php


echo "TOYOソースコードの圧縮ファイルをコンテナ内に転送する"
docker cp ${HOME_DIR}${ARCHIVES_DIR}/${SOURCECODE_ZIPFILE} \
          ${TARGET}_php:/home/kusanagi/${TARGET}/${SOURCECODE_ZIPFILE}
#docker exec -it --user root ${TARGET}_php cd /home/kusanagi/${TARGET}


echo "TOYOソースコードを解凍する"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
#docker exec -it --user root ${TARGET}_php unzip -oq /home/kusanagi/${TARGET}/${SOURCECODE_ZIPFILE} -d /home/kusanagi/${TARGET}
docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
        "cd /home/kusanagi/${TARGET}/ \
         && unzip -oq /home/kusanagi/${TARGET}/${SOURCECODE_ZIPFILE} \
            -d /home/kusanagi/${TARGET} "


echo "メディアディレクトリの圧縮ファイルをコンテナ内に転送する"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
#docker cp ${HOME_DIR}archives/20220525_sazae-toyo-lms-devdemo_files.tar.gz toyo-dev20220525_php:/home/kusanagi/toyo-dev20220525/20220525_sazae-toyo-lms-devdemo_files.tar.gz
docker cp ${HOME_DIR}${ARCHIVES_DIR}/${MEDIAFOLDER_ARCHIVEFILE} \
	${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/web/sites/default/${MEDIAFOLDER_ARCHIVEFILE} 
echo "圧縮ファイルをメディアディレクトリに解凍する"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
        "cd /home/kusanagi/${TARGET}/DocumentRoot/web/sites/default/ \
	&& rm -rf files-bak \
	&& mv files files-bak \
	&& tar zxvf ${MEDIAFOLDER_ARCHIVEFILE} > /dev/null 2>&1 "


echo "解凍済みファイルをDrupalプロジェクトフォルダ配下に転送する"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
        "cd /home/kusanagi/${TARGET}/ \
         && cp -rf /home/kusanagi/${TARGET}/${SOURCECODE_DIRNAME}/* \
           /home/kusanagi/${TARGET}/DocumentRoot/"


echo "DATABASEを復元する"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi

echo "DATABASEファイルチェックと変換を行う"
sed -i "s/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g" ${HOME_DIR}${ARCHIVES_DIR}/${MYSQLFILE}
echo "DATABASEファイルをコンテナ内に転送する"
docker cp ${HOME_DIR}${ARCHIVES_DIR}/${MYSQLFILE} ${TARGET}_db:/home/${MYSQLFILE}
echo "DATABASEリストアコマンドを実行する"
echo "mysql -u${dbuser} -p${dbpass} ${dbname} < /home/${MYSQLFILE}"
docker exec -it --user root ${TARGET}_db \
        /bin/sh -c \
        "mysql -u${dbuser} -p${dbpass} ${dbname} < /home/${MYSQLFILE}"


echo "COMPOSERでアプリをインストールする"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
        "cd /home/kusanagi/${TARGET}/DocumentRoot \
        && composer install"
echo "'composer instll' で失敗した場合は、コンテナ内でcomposer.json/composer.lockファイルを修正してください"
echo " ++++++++++++++++++++++++++++++++++"
echo "【注意】composerでエラー発生時のマニュアル対応方法です"
echo "【注意】正常にComposer処理が終了した場合は無視してください"
echo "==composer.json/lockファイル修正手順=="
echo "まずこのスクリプトを中断します（CRL+C連打）"
echo "１）コンテナ内にはいります"
echo "docker exec -it --user root ${TARGET}_php /bin/sh"
echo "２）Composerファイルが存在するディレクトリに移動します"
echo "cd /home/kusanagi/${TARGET}/DocumentRoot"
echo "３）コンテナ内でcomposer install を再度実行します"
echo "composer install"
echo "４）コンテナをでます"
echo "exit"
echo "５）このスクリプトのみ再実行します"
echo " ./installdpapp_toyo.sh {プロビジョン名} 0"
echo " ++++++++++++++++++++++++++++++++++"
fi

if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi


#echo "===== コンテナを再構築する ====="
#echo " 起動中コンテナを削除する（1/4）"
# docker-compose down
#echo " コンテナをコンパイルする（2/4）"
# docker-compose build --no-cache
#echo " コンテナを構築・起動する（3/4）"
# docker-compose up -d

echo "すべてのキャッシュをクリアする"
docker exec -it --user root ${TARGET}_php \
  /bin/sh -c \
  "cd /home/kusanagi/${TARGET}/DocumentRoot \
    && php drush.phar cr"
echo "アプリケーションのデプロイを完了しました"
## ---------------------------------

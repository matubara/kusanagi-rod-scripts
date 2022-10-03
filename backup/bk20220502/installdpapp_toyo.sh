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
#上記設定は環境設定ファイルに一元化した
source /home/matsubara/buildnewdocker.conf
MYSQLFILE=TOYO_LMS_20220429.sql
SOURCECODE_ZIPFILE=sazae-toyo-lms-newdemo_20220501.zip
####################################

echo PROJAPP=$PROJAPP
echo "autoexec=${autoexec}"
echo BASEAPP=${BASEAPP} 
echo "BASEAPP=${BASAPP}" 
echo "PROJAPP=${PROJAPP}" 
echo "LAMPAPP=$LAMPAPP"
####################################


# アプリソースコードデプロイ前に再起動する
echo "===== コンテナを再構築する ====="
cd /home/matsubara/${TARGET}
#echo " 起動中コンテナを削除する（1/4）"
# docker-compose down
#echo " コンテナをコンパイルする（2/4）"
# docker-compose build --no-cache
#echo " コンテナを構築・起動する（3/4）"
# docker-compose up -d

## ---------------------------------
echo "すべてのキャッシュをクリアする"
docker exec -it --user root ${TARGET}_php \
  /bin/sh -c \
  "cd /home/kusanagi/${TARGET}/DocumentRoot \
    && php drush.phar cr"
echo "アプリケーションのデプロイを完了しました"
## ---------------------------------

#########################################
## ここから Drupal9用の処理を記述する  ##
#########################################


cd /home/matsubara/${TARGET}
echo "<?php phpinfo();" > /home/matsubara/phpinfo.php
## ---------------------------------
if [ "$BASEAPP" = "lamp" ] && [ "$LAMPAPP" = "drupal9" ];then
docker cp /home/matsubara/phpinfo.php ${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/web/phpinfo.php
docker cp /home/matsubara/backup/adminer.php ${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/web/adminer.php

echo "TOYOソースコードの圧縮ファイルをコンテナ内に転送する"
docker cp /home/matsubara/backup/${SOURCECODE_ZIPFILE} ${TARGET}_php:/home/kusanagi/${TARGET}/${SOURCECODE_ZIPFILE}
#docker exec -it --user root ${TARGET}_php cd /home/kusanagi/${TARGET}
echo "TOYOソースコードを解凍する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php unzip -oq /home/kusanagi/${TARGET}/${SOURCECODE_ZIPFILE} -d /home/kusanagi/${TARGET}


echo "Docker内でファイルをコピーする"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
echo "Docker内で使用するCopyスクリプトを作成する"
echo "cp -rf /home/kusanagi/${TARGET}/sazae-toyo-lms-newdemo/* \
     /home/kusanagi/${TARGET}/DocumentRoot/" \
       > /home/matsubara/${TARGET}/copyfiles.sh.temp
echo "Docker内で使用するCopyスクリプトをコンテナ内に転送する"
docker cp /home/matsubara/${TARGET}/copyfiles.sh.temp \
        ${TARGET}_php:/home/kusanagi/${TARGET}/copyfiles.sh
echo "権限を設定する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php chmod 777 /home/kusanagi/${TARGET}/copyfiles.sh
echo "TOYO FILES COPYスクリプトを実行する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
#TARGET=toyo-drupal9
#cp -rf /home/kusanagi/${TARGET}/sazae-toyo-lms-newdemo/* /home/kusanagi/${TARGET}/DocumentRoot/
docker exec -it --user root ${TARGET}_php /bin/sh /home/kusanagi/${TARGET}/copyfiles.sh


#echo "TOYO DEPLOYスクリプトをコンテナ内に転送する"
#if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
#docker cp /home/matsubara/backup/deploy-toyoapp.sh ${TARGET}_php:/home/kusanagi/${TARGET}/deploy-toyoapp.sh
#echo "権限を設定する"
#if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
#docker exec -it --user root ${TARGET}_php chmod 777 /home/kusanagi/${TARGET}/deploy-toyoapp.sh
#echo "TOYO DEPLOYスクリプトを実行する"
#if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
#docker exec -it --user root ${TARGET}_php /bin/sh /home/kusanagi/${TARGET}/deploy-toyoapp.sh


echo "TOYO DATABASEスクリプトをコンテナ内に転送する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi

echo "Docker内で使用するCopyスクリプトを作成する"
echo "mysql -u${dbuser} -p${dbpass} ${dbname} < /home/${MYSQLFILE}" \
       > /home/matsubara/${TARGET}/importdb.sh.temp

docker cp /home/matsubara/backup/${MYSQLFILE} ${TARGET}_db:/home/${MYSQLFILE}
echo "TOYO DATABASEインポートスクリプトをコンテナ内に転送する"
docker cp /home/matsubara/${TARGET}/importdb.sh.temp ${TARGET}_db:/home/importdb.sh
echo "権限を設定する"
docker exec -it --user root ${TARGET}_db chmod 777 /home/importdb.sh
echo "DATABASEインポートスクリプトを実行する"
docker exec -it --user root ${TARGET}_db /bin/sh /home/importdb.sh


echo "COMPOSERでインストールする"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
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

if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi


echo "===== コンテナを再構築する ====="
echo " 起動中コンテナを削除する（1/4）"
 docker-compose down
echo " コンテナをコンパイルする（2/4）"
 docker-compose build --no-cache
echo " コンテナを構築・起動する（3/4）"
 docker-compose up -d

echo "すべてのキャッシュをクリアする"
docker exec -it --user root ${TARGET}_php \
  /bin/sh -c \
  "cd /home/kusanagi/${TARGET}/DocumentRoot \
    && php drush.phar cr"
echo "アプリケーションのデプロイを完了しました"
## ---------------------------------

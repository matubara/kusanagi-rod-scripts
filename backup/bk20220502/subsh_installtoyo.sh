####################################
APPTYPE=lamp
#LAMP_APP=""
LAMP_APP="drupal9"
#XDEBUGをインストールする
XDEBUG=y
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



#########################################
## ここから Drupal9用の処理を記述する  ##
#########################################


cd /home/matsubara/${TARGET}
echo "<?php phpinfo();" > /home/matsubara/phpinfo.php
## ---------------------------------
if [ $APPTYPE = "lamp" ] && [ $LAMP_APP = "drupal9" ];then
docker cp /home/matsubara/phpinfo.php ${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/web/phpinfo.php
docker cp /home/matsubara/backup/adminer.php ${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/web/adminer.php

echo "TOYOソースコードの圧縮ファイルをコンテナ内に転送する"
docker cp /home/matsubara/backup/sazae-toyo-lms-newdemo.zip ${TARGET}_php:/home/kusanagi/${TARGET}/sazae-toyo-lms-newdemo.zip
#docker exec -it --user root ${TARGET}_php cd /home/kusanagi/${TARGET}
echo "TOYOソースコードを解凍する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php unzip -oq /home/kusanagi/${TARGET}/sazae-toyo-lms-newdemo.zip -d /home/kusanagi/${TARGET}


echo "TOYO FILES COPYスクリプトをコンテナ内に転送する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker cp /home/matsubara/backup/copyfiles.sh ${TARGET}_php:/home/kusanagi/${TARGET}/copyfiles.sh
echo "権限を設定する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php chmod 777 /home/kusanagi/${TARGET}/copyfiles.sh
echo "TOYO FILES COPYスクリプトを実行する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
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
docker cp /home/matsubara/backup/TOYO_LMS_20220429.sql ${TARGET}_db:/home/TOYO_LMS_20220429.sql
echo "TOYO DATABASEインポートスクリプトをコンテナ内に転送する"
docker cp /home/matsubara/backup/importdb.sh ${TARGET}_db:/home/importdb.sh
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

fi

if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi


if [ $XDEBUG = "y" ];then
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
echo "Complete!"
else
  kusanagi-docker restart
fi

## ---------------------------------

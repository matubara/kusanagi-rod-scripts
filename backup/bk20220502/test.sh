    DOCROOT=DocumentRoot
    TARGET=wp3
echo "ドキュメントルートにデータベースツール他ファイルを転送する"
docker cp /home/matsubara/backup/phpinfo.php \
        ${TARGET}_php:/home/kusanagi/${TARGET}/${DOCROOT}/phpinfo.php
docker cp /home/matsubara/backup/adminer.php \
        ${TARGET}_php:/home/kusanagi/${TARGET}/${DOCROOT}/adminer.php
exit 0

APPDEPLOY_SCRIPT=test.sh2
if [ -n "$APPDEPLOY_SCRIPT" ] \
    && [ -e "/home/matsubara/$APPDEPLOY_SCRIPT" ]; then
echo "OK"    
#スクリプトの実行
    #source /home/matsubara/${APPDEPLOY_SCRIPT} ${TARGET} ${autoexec}
elif [ -n "$APPDEPLOY_SCRIPT" ] \
    && [ ! -e "/home/matsubara/$APPDEPLOY_SCRIPT" ]; then
    echo "エラーにより処理を中断しました"
    echo "アプリデプロイ用スクリプトが存在しません！！"
    echo "アプリのデプロイが必要な場合は手動でスクリプトを起動してください"
    exit 1
fi
exit 0

autoexec=0
echo "sh"
/bin/sh ./installwpapp_foodpotal.sh TARGET y 
echo $#
echo $1
echo "source"
source ./installwpapp_foodpotal.sh TARGET 1
echo $#
echo $1
exit 0

if [ ${TARGET} = "abc" ];then
echo "OK"
else
echo "ng"
fi

exit 0

#https://drushcommands.com/drush-9x/site/site:install/
echo "サイトを構築する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
        "cd /home/kusanagi/${TARGET}/DocumentRoot \
        && php drush.phar site:install"
       
#--db-su=lampuser --db-su-pw=lamppass"
exit 0


echo "DRUSH LAUNCHERをインストールする"
docker cp /home/matsubara/backup/drush.phar ${TARGET}_php:/usr/local/bin/drush
docker exec -it --user root ${TARGET}_php ls -al /usr/local/bin



exit 0

if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
echo "cp code"
docker cp /home/matsubara/backup/sazae-toyo-lms-newdemo.zip ${TARGET}_php:/home/kusanagi/${TARGET}/sazae-toyo-lms-newdemo.zip
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
echo "cd"
docker exec -it --user root ${TARGET}_php cd /home/kusanagi/${TARGET}/
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
echo "unzip"
docker exec -it --user root ${TARGET}_php unzip -oq /home/kusanagi/${TARGET}/sazae-toyo-lms-newdemo.zip -d /home/kusanagi/${TARGET}/
#docker exec -it --user root ${TARGET}_php cp -rf /home/kusanagi/${TARGET}/sazae-toyo-lms-newdemo/sazae-toyo-lms-newdemo/* -d /home/kusanagi/${TARGET}/DocumentRoot/

echo "cp copy.sh"
docker cp /home/matsubara/backup/copyfiles.sh ${TARGET}_php:/home/kusanagi/${TARGET}/copyfiles.sh
echo "chmod copy.sh"
docker exec -it --user root ${TARGET}_php chmod 777 /home/kusanagi/${TARGET}/copyfiles.sh
echo "exec copy.sh"
docker exec -it --user root ${TARGET}_php /bin/sh /home/kusanagi/${TARGET}/copyfiles.sh

if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
echo "cp sql"

docker cp /home/matsubara/backup/TOYO_LMS_20220429.sql ${TARGET}_db:/home/TOYO_LMS_20220429.sql
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
echo "cp importdb.sh"
docker cp /home/matsubara/backup/importdb.sh ${TARGET}_db:/home/importdb.sh
echo "chmod importdb.sh"
docker exec -it --user root ${TARGET}_db chmod 777 /home/importdb.sh 
echo "import db"
docker exec -it --user root ${TARGET}_db /bin/sh /home/importdb.sh 
#docker exec -it --user root ${TARGET}_db mysql -ulampuser -plamppass database < /home/matsubara/backup/TOYO_LMS_20220429.sql #/home/TOYO_LMS_20220429.sql



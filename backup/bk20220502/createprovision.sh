####################################
PROVISION=test-wp-auto01.local
manual=1
echo count=$#
if [ $# -ne 1 ];then
    manual=1
elif [ $1 -eq 1 ];then
    manual=1
else
    manual=0
fi
echo "manual=${manual}"
####################################

## ---------------------------------
echo "プロビジョニング：${PROVISION} を作成します。すでにある場合は削除されますのでご注意ください"
if [ $manual -ne 1 ];then echo "完了するまで止まりません"; fi
read -p "Press [Enter] key to build dockerfile." 

echo "念のため一括コンテナ停止する"
docker stop $(docker ps -q)

#削除
echo KUSANAGIプロビジョニングの削除（既に存在すれば削除する）
kusanagi-docker remove ${PROVISION}


## ---------------------------------
echo KUSANAGIプロビジョニングの作成
if [ $manual -eq 1 ];then read -p "Press [Enter] key to build dockerfile."; fi

echo "作成"
kusanagi-docker provision --wp --wplang=ja --admin-user=sinceretechnology --admin-pass=Melb#1999 --admin-email=admin@sinceretechnology.com.au --wp-title=test --kusanagi-pass=melb1999 --dbname=wptest --dbuser=wptest --dbpass=melb1999 --http-port=80 --tls-port=443 --fqdn ${PROVISION} ${PROVISION}


if [ $manual -eq 1 ];then read -p "Press [Enter] key to build dockerfile."; fi 

## ---------------------------------
echo サイト確認
echo "http://${PROVISION} にアクセスしてください"
if [ $manual -eq 1 ];then read -p "Press [Enter] key to build dockerfile."; fi


## ---------------------------------
cd ./backup
mkdir ../${PROVISION}/contents/DocumentRoot/temp
echo "バックアップファイルをワークフォルダに移動する"
cp -r ./kusanagi-php-php8.1 ../${PROVISION}

cp ../${PROVISION}/docker-compose.yml ../${PROVISION}/docker-compose.yml.bak
cp ./docker-compose.yml.template ../${PROVISION}/docker-compose.yml

echo "docker-compose.ymlを書き換える"
sed -i "s/{provision}/${PROVISION}/g" ../${PROVISION}/docker-compose.yml
if [ $manual -eq 1 ];then read -p "Press [Enter] key to build dockerfile."; fi


cp ./MYSQL_DATABASE.sql ../${PROVISION}/contents/DocumentRoot/temp
cp ./WP_UPLOADS.tar.gz  ../${PROVISION}/contents/DocumentRoot/temp
cp ./WP_THEMES.tar.gz   ../${PROVISION}/contents/DocumentRoot/temp
cp ./WP_PLUGINS.tar.gz  ../${PROVISION}/contents/DocumentRoot/temp


echo "Complete!"
if [ $manual -eq 1 ];then read -p "Press [Enter] key to build dockerfile."; fi

## ---------------------------------
echo "tempフォルダ内でバックアップファイルを展開する"
cd  ../${PROVISION}/contents/DocumentRoot/temp
tar zxvf WP_UPLOADS.tar.gz
tar zxvf WP_THEMES.tar.gz
tar zxvf WP_PLUGINS.tar.gz

echo "Complete!"
if [ $manual -eq 1 ];then read -p "Press [Enter] key to build dockerfile."; fi

## ---------------------------------
echo "wp-content内にデプロイする"
cp -r plugins/ ../wp-content/ 
cp -r uploads/ ../wp-content/ 
cp -r themes/ ../wp-content/ 

echo "Complete!"
#rm -rf ../wp-content/plugins/brozzme-db-prefix-change
if [ $manual -eq 1 ];then read -p "Press [Enter] key to build dockerfile."; fi

## ---------------------------------
echo "データベースをインポートする"
cd /home/matsubara/${PROVISION}
kusanagi-docker config push
echo "complete push"
if [ $manual -eq 1 ];then read -p "Press [Enter] key to build dockerfile."; fi

kusanagi-docker wp db import /home/kusanagi/${PROVISION}/DocumentRoot/temp/MYSQL_DATABASE.sql
echo "complete import db"
if [ $manual -eq 1 ];then read -p "Press [Enter] key to build dockerfile."; fi

## ---------------------------------
echo "データベースのURLをWP-CLIで一括置換する"
kusanagi-docker wp search-replace https://goodhealthbetterlife.com.au http://${PROVISION}
kusanagi-docker wp search-replace goodhealthbetterlife.com.au ${PROVISION}
echo "Complete!"
#if [ $manual -eq 1 ];then read -p "Press [Enter] key to build dockerfile."; fi

## ---------------------------------
echo "DOCER環境に入ってパーミッションを変更"
docker-compose run config chmod 777 /home/kusanagi/${PROVISION}/DocumentRoot/wp-content -R

echo "DOCER環境に入ってユーザーを変更"
#docker exec -it --user 1000 ${PROVISION}_httpd chown kusanagi:www /home/kusanagi/${PROVISION}/DocumentRoot/wp-content -R

echo "DOCER環境に入って不要なプラグインを削除（PHPバージョンによりエラーが発生するため対応）"
docker-compose run config rm -rf /home/kusanagi/${PROVISION}/DocumentRoot/wp-content/plugins/brozzme-db-prefix-change
echo "Complete!"
#if [ $manual -eq 1 ];then read -p "Press [Enter] key to build dockerfile."; fi

## ---------------------------------
echo "コンテナを再構築する"
 docker-compose down
 docker-compose build
 docker-compose up -d
echo "Complete!"


#TODO: データベースツールを入れる
#adminer.php


echo "complete successfully!!!!!!!!"
exit 0


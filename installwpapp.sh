########################################################
## SCRIPT TITLE: KUSANAGI-RoD LOCAL ENV AUTO CREATION
## MODULE NAME: WORDPRESS APP RESTORE MODULE
## DESCRIPTION: RESTORE WORDPRESS APP WITH BACKUP FILES
## CREATED DATE: 2022/10/01
## NOTE :
########################################################


#########################################
## GET ARGUMENTS AND VALIDATION CHECK
source ${HOME_DIR}buildnewdocker_init.sh
#########################################

#########################################
## ここからWORDPRESS用の処理を記述する ##
#########################################
echo "START INSTALLING WORDPRESS APP"
echo "WORDPRESSのアプリをインストールします"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
## ---------------------------------
echo "INSTALL DEVELOPPERS PLUGINS"
echo "開発用プラグインをインストールする"
cd ${HOME_DIR}${TARGET}
kusanagi-docker wp plugin install query-monitor
kusanagi-docker wp plugin activate query-monitor
## ---------------------------------
echo "Create temp dirctory in DOCKER-CONTAINER(1/2)"
echo "コンテナ内にtempフォルダを作成する(1/2)"
docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
        "rm -rf /home/kusanagi/${TARGET}/temp > /dev/null "
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
echo "Create temp dirctory in DOCKER-CONTAINER(2/2)"
echo "コンテナ内にtempフォルダを作成する(2/2)"
docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
        "cd /home/kusanagi/${TARGET} \
	 && mkdir ./temp "
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi

## ---------------------------------
## DBプレフィックスがwp以外の場合は
## バックアップSQLのDBプレフィックスを
## wpに変換する
## ---------------------------------
if [ -n "$DBPREFIX" ]; then
    if grep -q "${DBPREFIX}" ${HOME_DIR}${ARCHIVES_DIR}/${MYSQLFILE}; then
        sed -i "s/${DBPREFIX}/wp_/g" ${HOME_DIR}${ARCHIVES_DIR}/${MYSQLFILE}
	echo "REPLACED DB PREFIX FROM (${DBPREFIX}) TO (wp_) ."
        echo "DBプレフィックスを置換を実施しました（${DBPREFIX} -> wp_）"
    else
        echo "NOT FOUND DBPREFIX（${DBPREFIX}） TO BE REPLACED IN DATABASE FILE."
        echo "DBPREFIX（${DBPREFIX}）が検索されなかったためPREFIXの置換をしませんでした"
    fi
else
    echo "DB PREFIX IS NO NEED TO BE REPLACED."
    echo "DBPREFIXは未設定のためPREFIXの置換をしませんでした"
fi
## ---------------------------------

## ---------------------------------
echo "COPY ARCHIVE FILE TO DOCKER-CONTAINER. (1/3)"
echo "圧縮ファイルをコンテナ内に転送する(1/3)"
docker cp ${HOME_DIR}${ARCHIVES_DIR}/${SOURCECODE_UPLOADS} \
         ${TARGET}_php:/home/kusanagi/${TARGET}/temp/${SOURCECODE_UPLOADS}
echo "COPY ARCHIVE FILE TO DOCKER-CONTAINER. (2/3)"
echo "圧縮ファイルをコンテナ内に転送する(2/3)"
docker cp ${HOME_DIR}${ARCHIVES_DIR}/${SOURCECODE_PLUGINS} \
         ${TARGET}_php:/home/kusanagi/${TARGET}/temp/${SOURCECODE_PLUGINS}
echo "COPY ARCHIVE FILE TO DOCKER-CONTAINER. (3/3)"
echo "圧縮ファイルをコンテナ内に転送する(3/3)"
docker cp ${HOME_DIR}${ARCHIVES_DIR}/${SOURCECODE_THEMES} \
         ${TARGET}_php:/home/kusanagi/${TARGET}/temp/${SOURCECODE_THEMES}
echo "COPY DATABASE FILE TO DOCKER-CONTAINER."
echo "DATABASEファイルをコンテナ内に転送する"
docker cp ${HOME_DIR}${ARCHIVES_DIR}/${MYSQLFILE} \
         ${TARGET}_php:/home/kusanagi/${TARGET}/temp/${MYSQLFILE}
#docker exec -it --user root ${TARGET}_php cd /home/kusanagi/${TARGET}
## ---------------------------------
echo "DECOMPRESS ARCHIVE FILE IN DOCKER-CONTAINER.(1/3)"
echo "圧縮ファイルを解凍する(1/3)"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/temp \
       	 && tar zxvf ${SOURCECODE_UPLOADS} > /dev/null 2>&1 "
echo "DECOMPRESS ARCHIVE FILE IN DOCKER-CONTAINER.(2/3)"
echo "圧縮ファイルを解凍する(2/3)"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/temp \
       	 && tar zxvf ${SOURCECODE_PLUGINS} > /dev/null 2>&1 "
echo "DECOMPRESS ARCHIVE FILE IN DOCKER-CONTAINER.(3/3)"
echo "圧縮ファイルを解凍する(3/3)"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/temp \
       	 && tar zxvf  ${SOURCECODE_THEMES} > /dev/null 2>&1 "
## ---------------------------------
echo "MOVE DECOMPRESSED FILES UNDER WP-CONTENT DIRECTORY.(1/3)"
echo "解凍したフォルダをwp-content内に展開する(1/3)"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET} \
       	 && cp -rf ./temp/uploads ./DocumentRoot/wp-content \
	 "

echo "MOVE DECOMPRESSED FILES UNDER WP-CONTENT DIRECTORY.(2/3)"
echo "解凍したフォルダをwp-content内に展開する(2/3)"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET} \
       	 && cp -rf ./temp/plugins ./DocumentRoot/wp-content \
	 "

echo "MOVE DECOMPRESSED FILES UNDER WP-CONTENT DIRECTORY.(3/3)"
echo "解凍したフォルダをwp-content内に展開する(3/3)"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET} \
       	 && cp -rf ./temp/themes ./DocumentRoot/wp-content \
       	 "

## ---------------------------------
echo "DELETE PLUGIN WHITCH DOES NOT WORK IN DOCKER-CONTAINER."
echo "エラーが発生するPLUGINがあるためここで削除しておく"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/DocumentRoot/wp-content/plugins \
       	 && rm -rf ./brozzme-db-prefix-change "
## ---------------------------------
echo "IMPORT DATABASE FILE INTO MYSQL DB BY WP-CLI."
echo "データベースをインポートする"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
cd ${HOME_DIR}${TARGET}
kusanagi-docker wp db import \
	/home/kusanagi/${TARGET}/temp/${MYSQLFILE}
echo "complete import db"

## ---------------------------------
echo "REPLACE OLD URL NAME IN DATABASE TO NEW URL NAME BY WP-CLI."
echo "データベースのURLをWP-CLIで一括置換する"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
cd ${HOME_DIR}${TARGET}
kusanagi-docker wp search-replace \
	${DB_PROTCOL}://${DB_FQDN} \
	http://${FQDN}
kusanagi-docker wp search-replace \
	${DB_FQDN} \
	${TARGET}${TLD}
echo "COMPLETE REPLACING URL IN DATABASE."
echo "データベースのURLをWP-CLIで一括置換を完了しました"
#if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi

## ---------------------------------
echo "CHANGE DOCUMENTROOT DIRECTORY PERMISSION."
echo "【DOCER環境】パーミッションを変更する"
if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET} \
       	 && chmod 777 DocumentRoot -R "
echo "CHANGE DOCUMENTROOT DIRECTORY OWNER."
echo "【DOCER環境】ユーザーを変更する"
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET} \
       	 && chown kusanagi:www DocumentRoot -R "

## ---------------------------------
#デバッグのため削除しない
#echo "DELETE TEMP DIRECTORY."
#echo "tempフォルダを削除する"
#docker exec -it --user root ${TARGET}_php \
#        /bin/sh -c \
#        "cd /home/kusanagi/${TARGET} \
#	 && rm -rf ./temp "

echo "COPY .htaccess FILE INTO DOCKER-CONTAINER."
echo ".htaccessファイルをコンテナ内に転送する"
docker cp ${HOME_DIR}backup/.htaccess \
         ${TARGET}_php:/home/kusanagi/${TARGET}/DocumentRoot/.htaccess
echo "CHANGE OWNER AND PERMISSION OF .htaccess FILE IN DOCKER-CONTAINER."
echo ".htaccessファイルのオーナーと権限を変更する"
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/DocumentRoot \
       	 && chown kusanagi:www .htaccess \
	 && chmod 644 .htaccess "

echo "COMPELTE CHANGING OWNER AND PERMISSION OF .htaccess FILE IN DOCKER-CONTAINER."
echo ".htaccessファイルのオーナーと権限を変更を完了しました"
#if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi


echo " キャッシュクリア、パーマネントリンク作成してもカテゴリ等のリンクで404エラーが出る場合は"
echo " 以下のコードを.htaccessにはりつけてください"
echo " まずは次のコマンドでDocker環境にはいります"
echo " docker exec -it --user root {プロビジョン名}_php /bin/sh"
echo " .htaccessファイルは権限とユーザを変更してルートディレクトリに置いてください"
echo "<IfModule mod_rewrite.c>"
echo "RewriteEngine On"
echo "RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]"
echo "RewriteBase /"
echo "RewriteRule ^index\.php$ - [L]"
echo "RewriteCond %{REQUEST_FILENAME} !-f"
echo "RewriteCond %{REQUEST_FILENAME} !-d"
echo "RewriteRule . /index.php [L]"
echo "</IfModule>"

echo ""
echo "COMPLETE DEPLOYING WORDPRESS APP INTO DOCKER-CONTAINER."
echo "WORDPRESS環境とアプリの構築を完了しました"

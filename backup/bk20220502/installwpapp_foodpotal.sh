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
fi

####################################
#上記設定は環境設定ファイルに一元化した
source /home/matsubara/buildnewdocker.conf
MYSQLFILE=MYSQL_DATABASE.sql
SOURCECODE_PLUGINS=WP_PLUGINS.tar.gz
SOURCECODE_UPLOADS=WP_UPLOADS.tar.gz
SOURCECODE_THEMES=WP_THEMES.tar.gz
####################################


echo PROJAPP=$PROJAPP
echo "autoexec=${autoexec}"
echo BASEAPP=${BASEAPP}
echo "BASEAPP=${BASAPP}"
echo "PROJAPP=${PROJAPP}"
echo "LAMPAPP=$LAMPAPP"


echo TLD=${TLD}
echo arg1=$1
echo arg2=$2
echo "arg ok"
#########################################
## ここからWORDPRESS用の処理を記述する ##
#########################################
echo "WORDPRESSのアプリをインストールします"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
## ---------------------------------
echo "開発用プラグインをインストールする"
cd /home/matsubara/${TARGET}
kusanagi-docker wp plugin install query-monitor
kusanagi-docker wp plugin activate query-monitor
## ---------------------------------
echo "コンテナ内にtempフォルダを作成する(1/2)"
docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
        "rm -rf /home/kusanagi/${TARGET}/temp > /dev/null "
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
echo "TOYOソースコードの圧縮ファイルをコンテナ内に転送する"
echo "コンテナ内にtempフォルダを作成する(2/2)"
docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
        "cd /home/kusanagi/${TARGET} \
	 && mkdir ./temp "
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi

## ---------------------------------
echo "圧縮ファイルをコンテナ内に転送する(1/3)"
docker cp /home/matsubara/backup/${SOURCECODE_UPLOADS} \
         ${TARGET}_php:/home/kusanagi/${TARGET}/temp/${SOURCECODE_UPLOADS}
echo "圧縮ファイルをコンテナ内に転送する(2/3)"
docker cp /home/matsubara/backup/${SOURCECODE_PLUGINS} \
         ${TARGET}_php:/home/kusanagi/${TARGET}/temp/${SOURCECODE_PLUGINS}
echo "圧縮ファイルをコンテナ内に転送する(3/3)"
docker cp /home/matsubara/backup/${SOURCECODE_THEMES} \
         ${TARGET}_php:/home/kusanagi/${TARGET}/temp/${SOURCECODE_THEMES}
echo "DATABASEファイルをコンテナ内に転送する"
docker cp /home/matsubara/backup/${MYSQLFILE} \
         ${TARGET}_php:/home/kusanagi/${TARGET}/temp/${MYSQLFILE}
#docker exec -it --user root ${TARGET}_php cd /home/kusanagi/${TARGET}
## ---------------------------------
echo "圧縮ファイルを解凍する(1/3)"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/temp \
       	 && tar zxvf ${SOURCECODE_UPLOADS} > /dev/null 2>&1 "
echo "圧縮ファイルを解凍する(2/3)"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/temp \
       	 && tar zxvf ${SOURCECODE_PLUGINS} > /dev/null 2>&1 "
echo "圧縮ファイルを解凍する(3/3)"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/temp \
       	 && tar zxvf  ${SOURCECODE_THEMES} > /dev/null 2>&1 "
## ---------------------------------
echo "解凍したフォルダをwp-content内に展開する(1/3)"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET} \
       	 && cp -rf ./temp/uploads ./DocumentRoot/wp-content \
	 && rm -rf ./temp/uploads.tar.gz "
echo "解凍したフォルダをwp-content内に展開する(2/3)"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET} \
       	 && cp -rf ./temp/plugins ./DocumentRoot/wp-content \
	 && rm -rf ./temp/plugins.tar.gz "

echo "解凍したフォルダをwp-content内に展開する(3/3)"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET} \
       	 && cp -rf ./temp/themes ./DocumentRoot/wp-content \
       	 && rm -rf ./temp/themes "
## ---------------------------------
echo "エラーが発生するPLUGINがあるためここで削除しておく"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/DocumentRoot/wp-content/plugins \
       	 && rm -rf ./brozzme-db-prefix-change "
## ---------------------------------
echo "データベースをインポートする"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
cd /home/matsubara/${TARGET}
kusanagi-docker wp db import \
	/home/kusanagi/${TARGET}/temp/${MYSQLFILE}
echo "complete import db"

## ---------------------------------
echo "データベースのURLをWP-CLIで一括置換する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
cd /home/matsubara/${TARGET}
kusanagi-docker wp search-replace \
	https://goodhealthbetterlife.com.au \
	http://${TARGET}${TLD}
kusanagi-docker wp search-replace \
	goodhealthbetterlife.com.au \
	${TARGET}${TLD}
echo "Complete!"
#if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi

## ---------------------------------
echo "【DOCER環境】パーミッションを変更する"
if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/DocumentRoot \
       	 && chmod 777 wp-content -R "
echo "【DOCER環境】ユーザーを変更する"
docker exec -it --user root ${TARGET}_php \
	/bin/sh -c \
	"cd /home/kusanagi/${TARGET}/DocumentRoot \
       	 && chown kusanagi:kusanagi wp-content -R "

## ---------------------------------
echo "tempフォルダを削除する"
docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
        "cd /home/kusanagi/${TARGET} \
	 && rm -rf ./temp "
echo "Complete!"
#if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to build dockerfile."; fi

echo KUSANAGIコマンドでPULL
cd /home/matsubara/${TARGET}
kusanagi-docker config pull

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


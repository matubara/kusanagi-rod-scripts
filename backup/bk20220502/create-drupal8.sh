
echo KUSANAGIプロビジョニングの作成
echo Drupal8インストール
read -p "Press [Enter] key to build dockerfile."
kusanagi-docker provision --drupal8 --fqdn toyo-drupal8.local toyo-drupal8.local
exit 0


read -p "Press [Enter] key to build dockerfile."

echo KUSANAGIプロビジョニングの作成
#削除
#kusanagi-docker remove test-wp-auto01
read -p "Press [Enter] key to build dockerfile."
echo 作成
kusanagi-docker provision --wp --wplang=ja --admin-user=sinceretechnology --admin-pass=Melb#1999 --admin-email=admin@sinceretechnology.com.au --wp-title=test --kusanagi-pass=melb1999 --dbname=wptest --dbuser=wptest --dbpass=melb1999 --http-port=80 --tls-port=443 --fqdn test-wp-auto01 test-wp-auto01


echo サイト確認
echo "http://test-wp-auto01 にアクセスしてください"
read -p "Press [Enter] key to build dockerfile."



取得したコードをプロビジョニングフォルダにコピー
kusanagi-php-php8.1

docker-composer.xmlを変更

    #image: primestrategy/kusanagi-nginx:1.21.6-r4                   #削除
    build:
      context: ./kusanagi-php-php8.1 #追加
      dockerfile: Dockerfile         #追加







docker-composer.xmlをdocker-composer.xml.ORGにコピーしてバックアップ作成


docker-composer.xmlを変更

    build:
      context: ./kusanagi-php-php8.0 #変更箇所
      dockerfile: Dockerfile #変更箇所




PHP DOCKERFILEはKUSANAGIサイトkら取得
https://github.com/prime-strategy/kusanagi-php/tree/php8.0



docker-composer.xmlにXDEBUG 追加

#https://programmierfrage.com/items/install-php8-dev-on-php8-0-1-fpm-alpine
#https://qiita.com/ucan-lab/items/fbf021bf69896538e515
# RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community php8-dev 

RUN apk add autoconf
RUN apk add gcc g++ make
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug



 99-xdebug.iniファイルを作成する
[xdebug]
xdebug.idekey= "wp"
xdebug.client_host = host.docker.internal
xdebug.mode = debug
xdebug.start_with_request = yes
xdebug.discover_client_host = 0
xdebug.remote_handler = "dbgp"
xdebug.client_port = 9001


files内に入れる



コンパイルを実行してイメージを再構築する
docker-compose buildを実行する

再構築したイメージでコンテナを再起動する
 docker-compose up -d



COnfigコンテナに入ってwp-contentのユーザー権限を設定する


フォルダの権限変更

推奨フォルダ権限とするために、まずは、config containerに入ります。
ユーザはunknownとなりますがkusanagiのユーザIDです。
~/wordpress/kusanagi01$ docker-compose run config sh

wp-content/のpermissionを755に設定します。
パーミッション変更は次のコマンド
find ./wp-content/ -type d -exec chmod 775 {} +
chown 775 ./wp-content/ 

フォルダのオーナー変更

docker container(httpd)に入ります(ユーザはkusanagi)
~/wordpress/kusanagi01$ docker exec -it --user 1000 kusanagi01_httpd sh

chonwでオーナ変更(kusanagi.www→kusanagi.kusanagi)します。
find ./wp-content/  -exec chown kusanagi.kusanagi {} +


パーミッション変更は次のコマンド
find /home/kusanagi/wp.local/DocumentRoot/wp-content/ -type d -exec chmod 755 {} +
find /home/kusanagi/wp.local/DocumentRoot/wp-content/ -type f -exec chmod 666 {} +


https://tomluck.net/building-blog-3/


データベースツールを入れる
adminer.php

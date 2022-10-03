echo WORDPRESS環境作成
kusanagi-docker remove wp-xdebug.local
kusanagi-docker provision --wp --wplang=ja --admin-user=sinceretechnology --admin-pass=Melb#1999 --admin-email=admin@sinceretechnology.com.au --wp-title=test --kusanagi-pass=melb1999 --dbname=wptest --dbuser=wptest --dbpass=melb1999 --http-port=80 --tls-port=443 --fqdn wp-xdebug.local wp-xdebug.local



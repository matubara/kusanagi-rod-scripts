if [ -z $1 ]; then
    echo "please set target profile name to first parameter"
    exit
fi
  TARGET=$1
  echo "再構築したコンテナイメージとボリューム（DB含むデータ）のバックアップを取得する"
  if [ -n "$debugmode" ];then read -p "Press [Enter] key to move on to the next."; fi
  #BUILDで作成したIMAGEのバックアップ
  docker image save ${TARGET}_php:latest > ./IMG_${TARGET}_php.tar
  #Volumeバックアップを取得する
  docker run --rm --volumes-from ${TARGET}_php -v `pwd`:/backup busybox tar cf /backup/VOL_${TARGET}_php.tar /home/kusanagi
  docker run --rm --volumes-from ${TARGET}_db -v `pwd`:/backup busybox tar cf /backup/VOL_${TARGET}_db.tar /var/lib/mysql

autoexec=0
curdir=`pwd`
TARGET=`basename ${curdir}`
echo "コンテナ（${TARGET}_php、${TARGE}_db）のボリュームバックアップを取得する"
  echo "再構築したコンテナイメージとボリューム（DB含むデータ）のバックアップを取得する"
  if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to move on to the next."; fi
  #Volumeバックアップを取得する
  docker run --rm --volumes-from ${TARGET}_php -v /home/matsubara/${TARGET}:/backup busybox tar cf /backup/VOL_${TARGET}_php.tar /home/kusanagi
  docker run --rm --volumes-from ${TARGET}_db -v /home/matsubara/${TARGET}:/backup busybox tar cf /backup/VOL_${TARGET}_db.tar /var/lib/mysql


zipname=$(date +'%Y%m%d_AUTODOCKERSCRIPT_SCRIPT-ONLY.zip')
echo "この階層のスクリプトとbackupフォルダが次のファイル名に圧縮されます"
echo $zipname
read -p "Press [Enter] key to move on to the next."
zip -r $zipname \
./backup \
./maketoyoarchive \
buildnewdocker_init.sh \
buildnewdocker.conf \
buildnewdocker.sh \
install??app.sh \
sw.sh \
docker-backup.sh \
remove-kusanagi.sh \
makedockerbackup.sh \
makezip.sh

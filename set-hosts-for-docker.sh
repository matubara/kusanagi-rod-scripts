# https://www.ninton.co.jp/archives/5847
# https://zenn.dev/datsukan/articles/a479f3e98a70c4

autoexec=0
pushd ../
HOME_DIR=`pwd`/
popd
currentdir=`pwd`
TARGET=`basename ${currentdir}`
echo "HOME_DIR=${HOME_DIR}"
echo "TARGET=${TARGET}"
echo "Add ip address to /etc/hosts file in ${TARGET}_php container to be able to debug using XDEBUG."
  if [ $autoexec -eq 0 ];then read -p "Press [Enter] key to move on to the next."; fi

TEMP_SH="`ip route | awk 'NR==1 {print $3}'` host.docker.internal"
echo 'echo "'${TEMP_SH}'" >>/etc/hosts' > ./initialize-hosts.sh
cat ./initialize-hosts.sh
#exit
#hostsファイルにIPアドレスを追加するためのスクリプト
docker cp ${HOME_DIR}${TARGET}/initialize-hosts.sh \
        ${TARGET}_php:/home/kusanagi/${TARGET}/initialize-hosts.sh

docker exec -it --user root ${TARGET}_php \
        /bin/sh -c \
        "cd /home/kusanagi/${TARGET} \
         && chmod 777 initialize-hosts.sh \
         && /bin/sh initialize-hosts.sh"

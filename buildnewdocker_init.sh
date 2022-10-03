########################################################
## SCRIPT TITLE: KUSANAGI-RoD LOCAL ENV AUTO CREATION
## MODULE NAME: COMMON MODULE
## DESCRIPTION: VALIDATION & INITIAL PROCEDURE
## CREATED DATE: 2022/10/01
## NOTE :
########################################################

#PROFILEに定義済みデータ
array=( \
'restorewp' \
'stech' \
'blogdeoshiete' \
'fuji' \
'drupal9' \
'wp' \
'wpxdbg' \
'farmnavi' \
'foodpotal' \
'toyo-new' \
'toyo-dev' \
'lamp' \
'restore-wp' \
'restore-wpxdbg' \
'restore-drupal9' \
)  


############################################
## 配列に対象文字列が存在するか確認する
############################################
inarray() {
    local i
    for i in ${array[@]}; do
        if [[ ${i} = ${1} ]]; then
            return 0
        fi
    done
    return 1
}

#####################################################################################
## プロファイルに設定された環境を構築する
## 【コマンド書式】"
## buildnewdocker.sh 第一引数(必須) 第二引数(必須) 第三引数(オプション)"
## 【第一引数】(必須) buildnewdocker.confで定義したプロファイル名*を指定"
## 【第二引数】(必須) 新しく作成する仮想環境のプロビジョン名（フォルダ名）を指定"
## 【第三引数】(オプション) ステップごとに確認メッセージ表示の有無(0:STEP、1:自動) "
#####################################################################################
if inarray "$1";then
    echo "profile check ok"
else    
    echo "profile check ng"
fi
echo count=$#
if [ $# -eq 1 ] && [ "$1" = "allstop" ];then
    echo "現在起動中のコンテナをすべて停止する"
    docker stop $(docker ps -q)
    echo "完了しました"
    exit 0
elif [ $# -eq 2 ] && [ "$1" = "sw" ];then
    if [ ! -d ./"$2" ];then
        echo "対象のプロビジョンが存在しません"
	exit 1
    fi
    echo "現在起動中のコンテナをすべて停止する"
    docker stop $(docker ps -q)
    cd /home/matsubara/$2
    kusanagi-docker start
    cd /home/matsubara
    echo "完了しました"
    exit 0
elif [ "$1" = "restore-dockerimg" ] || [ "$1" = "restore-dockerimg2" ];then
    if [ $# -eq 4 ];then
        PROFILE=$1
        TARGET=$2
        ORGTARGET=$3
        debugmode=$4
    elif [ $# -eq 3 ];then 
        PROFILE=$1
        TARGET=$2
        ORGTARGET=$3
        debugmode=
    elif [ $# -eq 2 ];then 
        PROFILE=$1
        TARGET=$2
        OLDTARGET=$2
        debugmode=
    else
        echo "引数を確認してください"
        echo "【コマンド書式】"
        echo "buildnewdocker.sh 第一引数(必須) 第二引数(必須) 第三引数(オプション)"
        echo "【第一引数】(必須) buildnewdocker.confで定義したプロファイル名*を指定"
        echo "【第二引数】(必須) 新しく作成する仮想環境のプロビジョン名（フォルダ名）を指定"
        echo "【第三引数】(オプション) 旧仮想環境のプロビジョン名（バックアップ時のもの）を指定"
        echo "【第四引数】(オプション) ステップごとに確認メッセージ表示の有無(0:STEP、1:自動) "
        IFS=','
        echo "*有効なプロファイル名: ${array[*]} "
        exit 1
    fi
elif [ $# -eq 2 ] && inarray "$1";then
    PROFILE=$1
    TARGET=$2
    debugmode=
elif [ $# -eq 3 ] && inarray "$1";then
    PROFILE=$1
    TARGET=$2
    debugmode=$3
else
    echo "引数を確認してください"
    echo "【コマンド書式】"
    echo "buildnewdocker.sh 第一引数(必須) 第二引数(必須) 第三引数(オプション)"
    echo "【第一引数】(必須) buildnewdocker.confで定義したプロファイル名*を指定"
    echo "【第二引数】(必須) 新しく作成する仮想環境のプロビジョン名（フォルダ名）を指定"
    echo "【第三引数】(オプション) ステップごとに確認メッセージ表示の有無(0:STEP、1:自動) "
    IFS=','
    echo "*有効なプロファイル名: ${array[*]} "
    exit 1
fi
####################################

####################################
#上記設定は環境設定ファイルに一元化した
if [ -z "${HOME_DIR}" ];then  
  source ./buildnewdocker.conf
fi
####################################

## ---------------------------------
if [ -n "${HOME_DIR}" ];then  
    echo "HOME_DIR=  ${HOME_DIR} "; 
else
    echo "ホームディレクトリが設定されていません"
    exit 1
fi
echo "プロビジョニング：${TARGET} を作成します。すでにある場合は削除されますのでご注意ください"
if [ -n "${PROFILE}" ];then   echo "PROFILE=   ${PROFILE}  "; fi
if [ -n "${TARGET}" ];then    echo "TARGET=    ${TARGET}   "; fi
if [ -n "${ORGTARGET}" ];then echo "ORGTARGET= ${ORGTARGET}"; fi
if [ -n "${BASEAPP}" ];then   echo "BASEAPP=   ${BASEAPP}  "; fi
if [ -n "${LAMPAPP}" ];then   echo "LAMPAPP=   ${LAMPAPP}  "; fi
if [ -n "${PROJAPP}" ];then   echo "PROJAPP=   ${PROJAPP}  "; fi
if [ -n "${FQDN}" ];then      echo "FQDN=      ${FQDN}     "; fi

if [ -n "${KUSANAGIPHPSRC}" ];then        echo "KUSANAGIPHPSRC=       ${KUSANAGIPHPSRC}       "; fi
if [ -n "${ARCHIVE_IMAGE_PHP}" ];then     echo "ARCHIVE_IMAGE_PHP=    ${ARCHIVE_IMAGE_PHP}    "; fi
if [ -n "${ARCHIVE_VOLUME_PHP}" ];then    echo "ARCHIVE_VOLUME_PHP=   ${ARCHIVE_VOLUME_PHP}   "; fi
if [ -n "${ARCHIVE_VOLUME_DB}" ];then     echo "ARCHIVE_VOLUME_DB=    ${ARCHIVE_VOLUME_DB}    "; fi
if [ -n "${RESTOREFROMDOCKERFILE}" ];then echo "RESTOREFROMDOCKERFILE=${RESTOREFROMDOCKERFILE}"; fi
if [ -n "${MAKEDOCKERBACKUP}" ];then      echo "MAKEDOCKERBACKUP=     ${MAKEDOCKERBACKUP}     "; fi
if [ -n "${APPDEPLOY_SCRIPT}" ];then      echo "APPDEPLOY_SCRIPT=     ${APPDEPLOY_SCRIPT}     "; fi
if [ -n "${MYSQLFILE}" ];then             echo "MYSQLFILE=            ${MYSQLFILE}            "; fi
if [ -n "${SOURCECODE_ZIPFILE}" ];then    echo "SOURCECODE_ZIPFILE=   ${SOURCECODE_ZIPFILE}   "; fi
if [ -n "${SOURCECODE_DIRNAME}" ];then    echo "SOURCECODE_DIRNAME=   ${SOURCECODE_DIRNAME}   "; fi
if [ -n "${MYSQLFILE}" ];then             echo "MYSQLFILE=            ${MYSQLFILE}            "; fi
if [ -n "${SOURCECODE_PLUGINS}" ];then    echo "SOURCECODE_PLUGINS=   ${SOURCECODE_PLUGINS}   "; fi
if [ -n "${SOURCECODE_UPLOADS}" ];then    echo "SOURCECODE_UPLOADS=   ${SOURCECODE_UPLOADS}   "; fi
if [ -n "${SOURCECODE_THEMES}" ];then     echo "SOURCECODE_THEMES=    ${SOURCECODE_THEMES}    "; fi
if [ -n "${DB_PROTCOL}" ];then            echo "DB_PROTCOL=           ${DB_PROTCOL}           "; fi
if [ -n "${DB_FQDN}" ];then               echo "DB_FQDN=              ${DB_FQDN}              "; fi

if [ -n "${debugmode}" ];then
echo "デバッグモードで実行します"
echo "debugmode=${debugmode}"
fi

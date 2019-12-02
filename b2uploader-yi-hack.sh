
#!/bin/bash
# this script requires B2_COMMAND_LINE_TOOL (https://github.com/Backblaze/B2_Command_Line_Tool), curl and wget to run
# also, you must authorize your account to get the command line tool working properly

CAMERAIP=''  # the ip address of your camera.
FTPPORT=21   # 21 by default (camera's ftp service)
USER='root'  # root by default (camera's ftp service)
PASSWD=''    # the password of the camera
BUCKET=''    # your bucket at B2
FOLDER=''    # your folder at B2

case "$(curl -s --max-time 2 -I http://backblaze.com | sed 's/^[^ ]*  *\([0-9]\).*/\1/; 1q')" in
  [23]) echo -e "\e[32mHTTP connectivity is up\e[0m";;
  5) echo -e "\e[31mThe web proxy won't let us through\e[0m" && exit;;
  *) echo -e "\e[31mCould not connect to backblaze.com: The network is down or very slow\e[0m" && exit;;
esac

if [ -d "/tmp/$FOLDER" ]; then
    echo -e "\e[31mb2uploader for $FOLDER seems to be alerady running. Exiting.\e[0m" && exit
else
    echo -e "\e[32mReady to run.\e[0m" && mkdir /tmp/$FOLDER
fi

__cleanup ()
{
    echo -e "\e[31mExiting: Cleaning up.\e[0m" 
    rm -r /tmp/$FOLDER
}
trap __cleanup EXIT
DATENOW=$(date -d "$(date "+%Y-%m-%d %H")" +%s)
cd /tmp/$FOLDER

echo -e "Listing files in the camera's sd card...\n"
mapfile -t CAMFILES < <(curl -l ftp://$CAMERAIP:$FTPPORT//tmp/sd/record/record --user $USER:$PASSWD)
echo -e "Listing files in the bucket... This may take a while\n"
mapfile -t REMOTE < <(b2 ls $BUCKET $FOLDER)
mapfile -t REMOTECUT < <(basename -a "${REMOTE[@]%.*}")

LASTREMOTE=${REMOTECUT[-1]}

echo -e "\e[1mFound' ${#CAMFILES[@]} 'directories in the camera's sd card:  \n"
printf '%s\n' "${CAMFILES[@]}"
echo -e "\e[0m=====================================================\n"



if [[ ${#REMOTE[@]} -eq 1 ]];
    then
    LASTCUTCONV='1'
else
    LASTCUT=$(echo ${LASTREMOTE:0:4}'-'${LASTREMOTE:5:2}'-'${LASTREMOTE:8:2}' '${LASTREMOTE:11:2})
    LASTCUTCONV=$(date -d "$LASTCUT" +%s)
fi

for DIR in "${CAMFILES[@]}"
do

DIRCUTCONV=$(date -d "$(echo ${DIR:0:4}'-'${DIR:5:2}'-'${DIR:8:2}' '${DIR:11:2})" +%s)


if [ $DIRCUTCONV -eq $DATENOW ];
then
echo -e "Folder $DIR will not be uploaded because it can get new media. Exiting."
exit
fi



    if [ $DIRCUTCONV -gt $LASTCUTCONV ];
    then
        wget -r -nH --cut-dirs=4 --no-parent --reject="tmp.*" --user=$USER --password=$PASSWD ftp://$CAMERAIP:$FTPPORT//tmp/sd/record/$DIR/*
	mapfile -t MEDIA < <(ls $DIR/)
            for FILE in "${MEDIA[@]}"
            do
               b2 upload-file $BUCKET $DIR/$FILE $FOLDER/$DIR/$FILE
            done
	echo -e "\e[0m====================================================="
	echo -e "\e[1mremoving" $DIR
	echo -e "\e[0m"
	rm -r $DIR

fi  
	
done

rm -r /tmp/$FOLDER
echo -e "\nDone at: $(date)"

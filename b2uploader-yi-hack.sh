
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

DATENOW=$(date -d "$(date "+%Y-%m-%d %H")" +%s) # current date converted into Unix Epoch

echo -e "Listing files in the camera's sd card...\n"
mapfile -t CAMFILES < <(curl -l ftp://$CAMERAIP:$FTPPORT//tmp/sd/record/record --user $USER:$PASSWD)

cd ~
if [ -f "$FOLDER-LASTREMOTE" ]; then # If the text file exists
  LASTREMOTE=$(cat $FOLDER-LASTREMOTE)
else #if it doesn't
  echo -e "Listing files in the bucket... This may take a while\n"
  LASTREMOTE=$(b2 ls $BUCKET $FOLDER| tail -1)
  echo "$LASTREMOTE" > $FOLDER-LASTREMOTE
fi
LASTREMOTE=$(basename -a "$LASTREMOTE") # delete the prefix up the last slash.

cd /tmp/$FOLDER


echo -e "\e[1mFound' ${#CAMFILES[@]} 'directories in the camera's sd card:  \n"
printf '%s\n' "${CAMFILES[@]}"
echo -e "\e[0m=====================================================\n"

if [[ ${#REMOTE[@]} -eq 1 ]];
then
  LASTREMOTE='1'
else
  LASTREMOTE=$(echo ${LASTREMOTE:0:4}'-'${LASTREMOTE:5:2}'-'${LASTREMOTE:8:2}' '${LASTREMOTE:11:2}) #string processing
  LASTREMOTE=$(date -d "$LASTREMOTE" +%s) #converts date to unix epoch (seconds since 01-01-1970)
fi

for DIR in "${CAMFILES[@]}"
do
  DIREPOCH=$(echo ${DIR:0:4}'-'${DIR:5:2}'-'${DIR:8:2}' '${DIR:11:2}) #string processing
  DIREPOCH=$(date -d "$DIREPOCH" +%s) #converts date to unix epoch (seconds since 01-01-1970)
  if [ $DIREPOCH -eq $DATENOW ];
  then
    echo -e "Folder $DIR will not be uploaded because it can get new media now. Exiting."
    exit
  fi

  if [ $DIREPOCH -gt $LASTREMOTE ]; # if that directory is more recent than the last one uploaded to B2:
  then #download it
    wget -r -nH --cut-dirs=4 --no-parent --reject="tmp.*" --user=$USER --password=$PASSWD ftp://$CAMERAIP:$FTPPORT//tmp/sd/record/$DIR/*
    for FILE in $DIR/*.mp4
    do
      b2 upload-file $BUCKET $FILE $FOLDER/$FILE
    done
    echo -e "\e[0m====================================================="
    echo -e "\e[1mremoving" $DIR
    echo -e "\e[0m"
    rm -r $DIR
    echo "$DIR" > ~/$FOLDER-LASTREMOTE #writes the last folder uploaded
  fi
done

rm -r /tmp/$FOLDER
echo -e "\nDone at: $(date)"

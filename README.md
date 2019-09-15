# YI-Hack-B2
![](https://i.imgur.com/Plz055n.png)

Uploads recorded media to [Backblaze's B2 Cloud Storage](https://www.backblaze.com/b2/cloud-storage.html)

Pricing: $0.005/GB/month

This script will not run in any camera: it was made to run in a "normal" computer.


### Depends:
* [curl](https://curl.haxx.se/)
* [wget](https://www.gnu.org/software/wget/)
* [B2 Command Line Tool](https://github.com/Backblaze/B2_Command_Line_Tool)

### Running:

```
git clone https://github.com/Yi-Hack-Tools/YI-Hack-B2
chmod -R +x YI-Hack-B2
./YI-Hack-B2/b2uploader-yi-hack.sh
```
You must edit the script in order to set some variables:
```
CAMERAIP=''  # the ip address of your camera.
FTPPORT=21   # 21 by default
USER='root'  # root by default
PASSWD=''    # the password of the camera
BUCKET=''    # your bucket at B2
FOLDER=''    # your folder in your bucket at B2

```

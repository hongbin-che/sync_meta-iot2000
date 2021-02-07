#!/bin/bash
# script_dir = "/workspace/code/iot2050-cm/IOT2000_Build"
# workspace  = "/workspace/IOT2000"
# branch     = master
# OSS_FLAG : archive OSS Flag , defaut is NO
function usage {
   echo -e "\n   Build IOT2000    "
   echo  "    usage $0  [-swbodh]"
   echo  "   -s: build script dir path."
   echo  "   -w: workspace dir path."
   echo  "   -b: build branch."
   echo  "   -o: Whether to package the OSS file flag."
   echo  "   -d: build date."
   echo  "   -h: display help information."
   echo  " "
   exit 2
}
while  getopts s:w:b:o:d:h opt
do
   case $opt in
   s) SCRIPT_DIR="${OPTARG}";;
   w) WORKSPACE="${OPTARG}";;
   b) BRANCH="${OPTARG}";;
   o) OSS_FLAG="${OPTARG}";;
   d) BUILD_DATE="${OPTARG}";;
   h) usage ;;
   *) echo "## option do not exist."
      usage ;;
   esac
done

if [ -d $WORKSPACE ]
   then
      echo ===============================
      echo "## Start build iot2000 code!!!\n"
      echo ===============================
   else
      usage
  fi
#############################################################################
#                             Build Ready                                   #
#############################################################################
# 1. clean build env
#       Clean workspace 
#       Clean git repo
#
# 2. update code && update cm script
#############################################################################
Build_Ready(){
   echo -e "## Build Script Path is: $SCRIPT_DIR"
   echo -e "## Build WORKSPACE is: $WORKSPACE"
   echo -e "## Build Branch is: $BRANCH"
   echo -e "## Build Date is: $BUILD_DATE"
   echo -e "## Whether to package the OSS file: $OSS_FLAG"
   cd $WORKSPACE/meta-iot2000 
   HEAD_COMMIT=$(echo "`git log -1 --oneline | awk -F " " '{print $1}'`")
   release_version=${BUILD_DATE}_${HEAD_COMMIT}
   echo -e "## Release tag is ${release_version}"
   echo -e "\n\n ## [1]Start Clean and update build workspace!!!"
   cd $SCRIPT_DIR/  && git clean -fdx && git reset --hard && git pull origin master 
   cd $WORKSPACE/meta-iot2000 && git clean -dffx && git reset --hard HEAD && git checkout $BRANCH && git pull origin $BRANCH && git status 
   cd $WORKSPACE/meta-efibootguard && git clean -dffx && git reset --hard HEAD && git status 
   cd $WORKSPACE/meta-swupdate && git clean -dffx && git reset --hard HEAD && git status 
   cd $WORKSPACE/meta-mingw && git clean -dffx && git reset --hard HEAD && git status 
   cd $WORKSPACE/meta-openembedded && git clean -dffx && git reset --hard HEAD && git status 
   cd $WORKSPACE/poky && git clean -dffx && git reset --hard HEAD && git status 
   cd $WORKSPACE  
   if [ -d $WORKSPACE/build ]; then
      echo  -e "## Deletd build dir!"
      rm -rf $WORKSPACE/build
   fi
   if [ ! -f $WORKSPACE/kas-docker ]; then 
      copy  $SCRIPT_DIR/kas-docker  $WORKSPACE/
      chmod a+x  $WORKSPACE/kas-docker
   fi
   echo -e "## Clean workspace finished!!!"
}
#############################################################################
#                             Build images                                  #
#############################################################################
# Use  2>&1 | tee  
# 1. Build images
#   ./kas-docker build meta-iot2000/kas-example.yml
#
# 2. Build windows SDK
#   ./kas-docker build meta-iot2000/kas-sdk-windows-i586.yml
#
# 3. Build linux SDK 
#   ./kas-docker build meta-iot2000/kas-sdk-linux-x64.yml
#
# 4. Build RT Image
#   ./kas-docker build meta-iot2000/kas-example-rt.yml
#############################################################################
Build_images(){
   echo -e "\n\n## [2]Start build image/sdk/RT image..."
   echo -e "\n## Start build example image"
   cd $WORKSPACE && ./kas-docker build meta-iot2000/kas-example.yml 

   echo -e "\n\n## Start build windows sdk"
   cd $WORKSPACE && ./kas-docker build meta-iot2000/kas-sdk-windows-i586.yml 

   echo -e "\n\n## Start build linux sdk"
   cd $WORKSPACE && ./kas-docker build meta-iot2000/kas-sdk-linux-x64.yml 

   echo -e "\n\n## Start build RT images"
   cd $WORKSPACE && ./kas-docker build meta-iot2000/kas-example-rt.yml 
   echo -e "## Build image/sdk/RT image finished!!!"
}
#############################################################################
#                             Build Archive                                 #
#############################################################################
# WORKSPACE = "/workspace/IOT2000"
# archivePath = "/workspace/Artifacts/IOT2000"
#############################################################################
Build_Archive(){
   echo -e "\n\n## [3]Start Archive build result!!!"
   cd  $WORKSPACE/meta-iot2000
   HEAD_COMMIT=$(echo "`git log -1 --oneline | awk -F " " '{print $1}'`")
   archivePath=$WORKSPACE/${BUILD_DATE}_${HEAD_COMMIT}
   release_version=${BUILD_DATE}_${HEAD_COMMIT}
   if [ ! -d $archivePath ]; then
      mkdir -p $archivePath
   fi
   if [ -d $archivePath ]; then 
      ######################################################################################################
      echo -e "\n## 1.Archive example images "
      ls -l $WORKSPACE/build/tmp/deploy/images/iot2000/ |grep .rootfs.wic 
      cp -rf $WORKSPACE/build/tmp/deploy/images/iot2000/iot2000-example-image-iot2000-*.rootfs.wic  ${archivePath}/
      cd ${archivePath}
      mv *.rootfs.wic example-${release_version}.wic
      zip -9 Example_Image_${release_version}.zip example-${release_version}.wic
      rm -rf example-${release_version}.wic

      ######################################################################################################
      echo -e "\n## 2.Archive windows sdk "
      cd ${archivePath}
      #ls -l $WORKSPACE/build/tmp/deploy/sdk
      ls -l $WORKSPACE/build/tmp/deploy/sdk/poky-iot2000-glibc-i686-mingw32-iot2000-example-image-i586-*.tar.xz
      cp -rf $WORKSPACE/build/tmp/deploy/sdk/poky-iot2000-glibc-i686-mingw32-iot2000-example-image-i586-*.tar.xz ${archivePath}/
      mv poky-iot2000-glibc-i686-mingw32-iot2000-example-image-i586-*.tar.xz IOT2000_SDK_Windows_${release_version}.tar.xz

      ######################################################################################################
      echo -e "\n## 3.Archive liunxs sdk "
      cd ${archivePath}
      ls -l $WORKSPACE/build/tmp/deploy/sdk/poky-iot2000-glibc-x86_64-*.sh
      cp -rf $WORKSPACE/build/tmp/deploy/sdk/poky-iot2000-glibc-x86_64-*.sh ${archivePath}/
      mv poky-iot2000-glibc-x86_64-*.sh ${release_version}_SDK_Linux.sh
      echo -e "tar -Jcf IOT2000_SDK_Linux_${release_version}.tar.xz ${release_version}_SDK_Linux.sh"
      tar -Jcf IOT2000_SDK_Linux_${release_version}.tar.xz ${release_version}_SDK_Linux.sh
      rm -rf ${release_version}_SDK_Linux.sh

      ######################################################################################################
      echo -e "\n## 4.Archive RT images "
      cd ${archivePath}
      #ls -l $WORKSPACE/build/tmp/deploy/images/iot2000/
      ls -l $WORKSPACE/build/tmp/deploy/images/iot2000/iot2000-example-image-rt-iot2000-*.rootfs.wic
      cp -rf $WORKSPACE/build/tmp/deploy/images/iot2000/iot2000-example-image-rt-iot2000-*.rootfs.wic ${archivePath}/
      mv iot2000-example-image-rt-iot2000-*.rootfs.wic RT_Image_${release_version}.wic
      zip -9 RT_Image_${release_version}.zip RT_Image_${release_version}.wic
      rm -rf RT_Image_${release_version}.wic

      ######################################################################################################
      if [[ $OSS_FLAG == "YES" ]]; then
         echo -e "\n## 5.Archive OSS file "
         cd ${archivePath}
         mkdir -p ${archivePath}/OSS_tmp/build/tmp/deploy/
         echo -e "## Start Copy licenses file "
         ls -l $WORKSPACE/build/tmp/deploy/licenses
         cp -rf $WORKSPACE/build/tmp/deploy/licenses ${archivePath}/OSS_tmp/build/tmp/deploy/
         echo -e "## Start Copy downloads file "
         ls -l  cp -rf $WORKSPACE/build/downloads
         cp -rf $WORKSPACE/build/downloads ${archivePath}/OSS_tmp/build/
         cd ${archivePath}/OSS_tmp/build/downloads/ &&  rm -rf git2_*   && rm -rf *.done

         cd ${archivePath}/OSS_tmp/
         echo -e "## Start Copy code repo file "
         cp -rf ${WORKSPACE}/meta-efibootguard .
         cp -rf ${WORKSPACE}/meta-swupdate .
         cp -rf ${WORKSPACE}/meta-iot2000 .
         cp -rf ${WORKSPACE}/meta-mingw .
         cp -rf ${WORKSPACE}/meta-openembedded .
         cp -rf ${WORKSPACE}/poky .
            cd meta-efibootguard  && git clean -dffx && git reset --hard HEAD && git status && cd ../
            cd meta-swupdate && git clean -dffx && git reset --hard HEAD && git status && cd ../
            cd meta-iot2000 && git clean -dffx && git reset --hard HEAD && git status && cd ../
            cd meta-mingw && git clean -dffx && git reset --hard HEAD && git status && cd ../
            cd meta-openembedded && git clean -dffx && git reset --hard HEAD && git status && cd ../
            cd poky && git clean -dffx && git reset --hard HEAD && git status && cd ../

         cd ${archivePath}/OSS_tmp/
         zip -9 -r -s 1G Open_Source_Software_${release_version}.zip *
         mkdir -p ${archivePath}/OSS
         mv Open_Source_Software_${release_version}.z* ${archivePath}/OSS
         rm -rf ${archivePath}/OSS_tmp/
      fi

      ######################################################################################################
      echo -e "\n## 6.Sha256sum file"
      cd ${archivePath}
      sha256sum *.xz *.zip > ${release_version}_sha256checksum.txt
      cd  ${archivePath}/OSS/
      sha256sum * >> ../${release_version}_sha256checksum.txt
      if [ -f $WORKSPACE/BuildLog_*.log ]; then
         mv  $WORKSPACE/BuildLog_*.log  ${archivePath}
      fi
   fi
}
#############################################################################
#                        Build Release Note info                            #
#############################################################################
# WORKSPACE = "/workspace/IOT2000"
# archivePath = "/workspace/Artifacts/IOT2000"
#############################################################################
Build_Release(){
   echo -e "\n\n## Get Release Note"
   cd $WORKSPACE/meta-iot2000
   HEAD_COMMIT=$(echo "`git log -1 --oneline | awk -F " " '{print $1}'`")
   archivePath=$WORKSPACE/${BUILD_DATE}_${HEAD_COMMIT}
   release_version=${BUILD_DATE}_${HEAD_COMMIT}
   repository=$(echo "`git remote -v  | awk   -F " " 'NR==1 {print $2}'`")
   RELEASE_NOTE_FILE=${release_version}-release-note.txt  
   echo "#HEAD COMMIT: $HEAD_COMMIT"
   echo "#Repository: $repository"
   echo "#Branch: $BRANCH"
   echo "#Tag: ${release_version}"
   echo -e "#Log:\n"
   git log --oneline   --no-merges  --pretty=format:"    %h - %ae  %s"
   echo -e "Repository:"                                                       >> $archivePath/$RELEASE_NOTE_FILE
   echo -e "    $repository"                                                   >> $archivePath/$RELEASE_NOTE_FILE
   echo -e "----------------------------------------------------------------"  >> $archivePath/$RELEASE_NOTE_FILE
   echo -e "Branch:"                                                           >> $archivePath/$RELEASE_NOTE_FILE
   echo -e "    $BRANCH"                                                       >> $archivePath/$RELEASE_NOTE_FILE
   echo -e "----------------------------------------------------------------"  >> $archivePath/$RELEASE_NOTE_FILE
   echo -e "Commit:"                                                           >> $archivePath/$RELEASE_NOTE_FILE
   echo -e "    `git log -1 --oneline | awk -F " " '{print $1}'`"              >> $archivePath/$RELEASE_NOTE_FILE
   echo -e "----------------------------------------------------------------"  >> $archivePath/$RELEASE_NOTE_FILE
   echo -e "Tag:"                                                              >> $archivePath/$RELEASE_NOTE_FILE
   echo -e "    ${release_version}"                                            >> $archivePath/$RELEASE_NOTE_FILE
   echo -e "----------------------------------------------------------------"  >> $archivePath/$RELEASE_NOTE_FILE
   echo -e "Release Notes:"                                                    >> $archivePath/$RELEASE_NOTE_FILE
   git log --oneline   --no-merges  --pretty=format:"    %h - %ae  %s"         >> $archivePath/$RELEASE_NOTE_FILE
   echo -e "\n----------------------------------------------------------------">> $archivePath/$RELEASE_NOTE_FILE

   if [ -d /workspace/Artifacts/IOT2000 ]; then
      mv ${archivePath}  /workspace/Artifacts/IOT2000
   fi
}

Build_Ready
Build_images
Build_Archive
Build_Release
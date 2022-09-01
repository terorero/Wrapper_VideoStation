#!/bin/bash

##############################################################
version="SCPT_1.11"
# Changes:
# SCPT_1.0: Initial release of the automatic installer script for DMS 7.X. (Deprecated migrated to SCPT_1.1)
# SCPT_1.1: To avoid discrepancies and possible deletion of original binaries when there is a previously installed wrapper, an analyzer of other installations has been added. (Deprecated migrated to SCPT_1.2)
# SCPT_1.2: Added a configurator tool for select the codecs. (Deprecated migrated to SCPT_1.3)
# SCPT_1.3: Added a interactive menu when you do not especify any Flag in bash command or you are using basic launch. (Deprecated migrated to SCPT_1.4)
# SCPT_1.4: Fixed a bug: when you select simplest_wrapper with only MP3 2.0 and then try to change the order of the audio codecs you will have a error. (Deprecated migrated to SCPT_1.5)
# SCPT_1.5: Fixed a bug: when you have a low connection to Internet that could have problems. (Deprecated migrated to SCPT_1.6)
# SCPT_1.6: Added a independent audio's streams via DLNA. (Deprecated migrated to SCPT_1.7)
# SCPT_1.7: Added a independent installer for simplest_wrapper in MAIN menu. Added new configuration options in configurator_menu. Now you can change from AAC 512kbps to AC3 640kbps and vice versa. (Deprecated migrated to SCPT_1.8)
# SCPT_1.8: Modify the log file and consolidation with the wrapper itself. Check if the user is using root account. Added the possibility that someone change TransProfiles in VideoStation. Fixed a bucle in old Uninstall process. (Deprecated migrated to SCPT_1.9)
# SCPT_1.9: Modify the compatibility for all 7.x DSMs and not only 7.0 and 7.1. (Deprecated migrated to SCPT_1.10)
# SCPT_1.10: Now the Installer Script is independent of the existence of DLNA Media Server, DLNA MediaServer is a optional package. Now You can see the installation logs and the Wrapper logs in: /tmp/wrapper_ffmpeg.log.(Deprecated migrated to SCPT_1.11)
# SCPT_1.11: Adding the function for checking keys and expand error logs. Minimal changes. Improvements in the Configurator Tool menu when It's launched if you haven't MediaServer Installed. Added a checker of the existence of a licence in AME Package.

##############################################################


###############################
# VARIABLES
###############################

dsm_version=$(cat /etc.defaults/VERSION | grep productversion | sed 's/productversion=//' | tr -d '"')
repo_url="https://raw.githubusercontent.com/darknebular/Wrapper_VideoStation"
setup="start"
dependencias=("VideoStation" "ffmpeg" "CodecPack")
RED="\u001b[31m"
BLUE="\u001b[36m"
PURPLE="\u001B[35m"
GREEN="\u001b[32m"
YELLOW="\u001b[33m"
injector="0-12.2.2"
vs_path=/var/packages/VideoStation/target
ms_path=/var/packages/MediaServer/target
vs_libsynovte_file="$vs_path/lib/libsynovte.so"
ms_libsynovte_file="$ms_path/lib/libsynovte.so"
cp_bin_path=/var/packages/CodecPack/target/bin
all_files=("$ms_libsynovte_file.orig" "vs_libsynovte_file.orig" "$cp_bin_path/ffmpeg41.orig" "$ms_path/bin/ffmpeg.orig" "$vs_path/etc/TransProfile.orig")
firma="DkNbulDkNbul"
firma2="DkNbular"
declare -i control=0
logfile="/tmp/wrapper_ffmpeg.log"

###############################
# FUNCIONES
###############################

function log() {
  echo -e  "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1: $2"
}
function info() {
  log "${BLUE}INFO" "${YELLOW}$1"
}
function error() {
  log "${RED}ERROR" "${RED}$1"
}

function restart_packages() {
  
  info "${GREEN}Restarting CodecPack..."
  info "${GREEN}Restarting CodecPack..." >> $logfile
  synopkg restart CodecPack 2>> $logfile
  
  info "${GREEN}Restarting VideoStation..."
  info "${GREEN}Restarting VideoStation..." >> $logfile
  synopkg restart VideoStation 2>> $logfile
  
  
  if [[ -d "$ms_path" ]]; then
  info "${GREEN}Restarting MediaServer..."
  info "${GREEN}Restarting MediaServer..." >> $logfile
  synopkg restart MediaServer 2>> $logfile
  fi

}

function check_dependencias() {
 
for dependencia in "${dependencias[@]}"; do
    if [[ ! -d "/var/packages/${dependencia[@]}" ]]; then
      error "MISSING $dependencia Package." 
      error "MISSING $dependencia Package." >> $logfile
    let "npacks=npacks+1"

    fi
done

if [[ npacks -eq control ]]; then
echo -e  "${GREEN}You have ALL necessary packages Installed, GOOD."
fi
#else
if [[ npacks -ne control ]]; then
echo -e  "${RED}At least you need $npacks package/s to Install, please Install the dependencies and RE-RUN the Installer again."
exit 1
fi

}
function welcome() {
  echo -e "${YELLOW}FFMPEG WRAPPER INSTALLER version: $version"

  welcome=$(curl -s -L "$repo_url/main/welcome.txt")
  if [ "${#welcome}" -ge 1 ]; then
    echo ""
    echo -e "${GREEN}	$welcome"
    echo ""
  fi
}
function check_version() {
    DSM=$1
    DELIMITER=$2
    VALUE=$3
    LIST_WHITESPACES=`echo $DSM | tr "$DELIMITER" " "`
    for xdsm in $LIST_WHITESPACES; do
        if [ "$xdsm" = "$VALUE" ]; then
            return 0
        fi
    done
    return 1
}
function config_A() {
    if [[ "$check_amrif" == "$firma2" ]]; then  
    info "${YELLOW}Changing to use FIRST STREAM= MP3 2.0 256kbpss, SECOND STREAM= AAC 5.1 512kbps in VIDEO-STATION."
    info "${YELLOW}Changing to use FIRST STREAM= MP3 2.0 256kbpss, SECOND STREAM= AAC 5.1 512kbps in VIDEO-STATION." >> $logfile
    sed -i 's/args2vs+=("-c:a:0" "libfdk_aac" "-c:a:1" "$1")/args2vs+=("-c:a:0" "$1" "-c:a:1" "libfdk_aac")/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/args2vs+=("-ac:1" "6" "-ac:2" "$1")/args2vs+=("-ac:1" "$1" "-ac:2" "6")/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/("-b:a:0" "512k" "-b:a:1" "256k")/("-b:a:0" "256k" "-b:a:1" "512k")/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    info "${GREEN}Sucesfully changed the audio stream's order to: 1) MP3 2.0 256kbps and 2) AAC 5.1 512kbps in VIDEO-STATION."
    echo ""
   
    fi
	
	if [[ "$check_amrif" == "$firma" ]]; then  
    info "${YELLOW}Changing to use FIRST STREAM= MP3 2.0 256kbpss, SECOND STREAM= AAC 5.1 512kbps in VIDEO-STATION."
    info "${YELLOW}Changing to use FIRST STREAM= MP3 2.0 256kbpss, SECOND STREAM= AAC 5.1 512kbps in VIDEO-STATION." >> $logfile
    sed -i 's/args2vs+=("-c:a:0" "libfdk_aac" "-c:a:1" "$1")/args2vs+=("-c:a:0" "$1" "-c:a:1" "libfdk_aac")/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/args2vs+=("-ac:1" "6" "-ac:2" "$1")/args2vs+=("-ac:1" "$1" "-ac:2" "6")/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/("-b:a:0" "512k" "-b:a:1" "256k")/("-b:a:0" "256k" "-b:a:1" "512k")/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    info "${GREEN}Sucesfully changed the audio stream's order to: 1) MP3 2.0 256kbps and 2) AAC 5.1 512kbps in VIDEO-STATION."
    echo ""
   
   else
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED and this codec Configurator CAN'T change anything."
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED and this codec Configurator CAN'T change anything." >> $logfile
   info "${BLUE}Please, Install the Advanced Wrapper first and then you will can change the audio's streams order."
   
   start
   
   fi
}

function config_B() {
if [[ "$check_amrif" == "$firma2" ]]; then  
info "${YELLOW}Changing to use FIRST STREAM= AAC 5.1 512kbps, SECOND STREAM= MP3 2.0 256kbps in VIDEO-STATION."
info "${YELLOW}Changing to use FIRST STREAM= AAC 5.1 512kbps, SECOND STREAM= MP3 2.0 256kbps in VIDEO-STATION." >> $logfile
    sed -i 's/args2vs+=("-c:a:0" "$1" "-c:a:1" "libfdk_aac")/args2vs+=("-c:a:0" "libfdk_aac" "-c:a:1" "$1")/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/args2vs+=("-ac:1" "$1" "-ac:2" "6")/args2vs+=("-ac:1" "6" "-ac:2" "$1")/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/("-b:a:0" "256k" "-b:a:1" "512k")/("-b:a:0" "512k" "-b:a:1" "256k")/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    info "${GREEN}Sucesfully changed the audio stream's order to: 1) AAC 5.1 512kbps and 2) MP3 2.0 256kbps in VIDEO-STATION."
    echo ""
fi

if [[ "$check_amrif" == "$firma" ]]; then  
    info "${YELLOW}Changing to use FIRST STREAM= AAC 5.1 512kbps, SECOND STREAM= MP3 2.0 256kbps in VIDEO-STATION."
    info "${YELLOW}Changing to use FIRST STREAM= AAC 5.1 512kbps, SECOND STREAM= MP3 2.0 256kbps in VIDEO-STATION." >> $logfile
    sed -i 's/args2vs+=("-c:a:0" "$1" "-c:a:1" "libfdk_aac")/args2vs+=("-c:a:0" "libfdk_aac" "-c:a:1" "$1")/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/args2vs+=("-ac:1" "$1" "-ac:2" "6")/args2vs+=("-ac:1" "6" "-ac:2" "$1")/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/("-b:a:0" "256k" "-b:a:1" "512k")/("-b:a:0" "512k" "-b:a:1" "256k")/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    info "${GREEN}Sucesfully changed the audio stream's order to: 1) AAC 5.1 512kbps and 2) MP3 2.0 256kbps in VIDEO-STATION."
    echo ""
else
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED and this codec Configurator CAN'T change anything."
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED and this codec Configurator CAN'T change anything." >> $logfile
   info "${BLUE}Please, Install the Advanced Wrapper first and then you will can change the audio's streams order."
   
   start
fi
}

function config_C() {
if [[ "$check_amrif" == "$firma2" ]]; then 
info "${YELLOW}Changing the 5.1 audio's codec from AAC 512kbps to AC3 640kbps independently of its audio's streams order in VIDEO-STATION."
info "${YELLOW}Changing the 5.1 audio's codec from AAC 512kbps to AC3 640kbps independently of its audio's streams order in VIDEO-STATION." >> $logfile
    sed -i 's/"libfdk_aac"/"ac3"/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/"512k"/"640k"/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/"6"/""/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    info "${GREEN}Sucesfully changed the 5.1 audio's codec from AAC 512kbps to AC3 640kbps in VIDEO-STATION."
    echo ""
fi

if [[ "$check_amrif" == "$firma" ]]; then  
    info "${YELLOW}Changing the 5.1 audio's codec from AAC 512kbps to AC3 640kbps independently of its audio's streams order in VIDEO-STATION and DLNA MediaServer."
    info "${YELLOW}Changing the 5.1 audio's codec from AAC 512kbps to AC3 640kbps independently of its audio's streams order in VIDEO-STATION and DLNA MediaServer." >> $logfile
    sed -i 's/"libfdk_aac"/"ac3"/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/"libfdk_aac"/"ac3"/gi' $ms_path/bin/ffmpeg 2>> $logfile
    sed -i 's/"512k"/"640k"/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/"512k"/"640k"/gi' $ms_path/bin/ffmpeg 2>> $logfile
    sed -i 's/"6"/""/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/"6"/""/gi' $ms_path/bin/ffmpeg 2>> $logfile
    info "${GREEN}Sucesfully changed the 5.1 audio's codec from AAC 512kbps to AC3 640kbps in VIDEO-STATION and DLNA MediaServer."
    echo ""
 else
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED and this codec Configurator CAN'T change anything."
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED and this codec Configurator CAN'T change anything." >> $logfile
   info "${BLUE}Please, Install the Advanced Wrapper first and then you will can change the audio's streams order."
   
   start
fi   
}

function config_D() {
if [[ "$check_amrif" == "$firma2" ]]; then 
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED in DLNA Media Server and this codec Configurator CAN'T change anything."
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED in DLNA Media Server and this codec Configurator CAN'T change anything." >> $logfile
   info "${BLUE}Please, Install the Advanced Wrapper first and then you will can change the audio's streams order."
   start
fi

if [[ "$check_amrif" == "$firma" ]]; then  
    info "${YELLOW}Changing to use FIRST STREAM= AAC 5.1 512kbps, SECOND STREAM= MP3 2.0 256kbps in DLNA MediaServer."
    info "${YELLOW}Changing to use FIRST STREAM= AAC 5.1 512kbps, SECOND STREAM= MP3 2.0 256kbps in DLNA MediaServer." >> $logfile
    sed -i 's/args2vs+=("-c:a:0" "$1" "-c:a:1" "libfdk_aac")/args2vs+=("-c:a:0" "libfdk_aac" "-c:a:1" "$1")/gi' $ms_path/bin/ffmpeg 2>> $logfile
    sed -i 's/args2vs+=("-ac:1" "$1" "-ac:2" "6")/args2vs+=("-ac:1" "6" "-ac:2" "$1")/gi' $ms_path/bin/ffmpeg 2>> $logfile
    sed -i 's/("-b:a:0" "256k" "-b:a:1" "512k")/("-b:a:0" "512k" "-b:a:1" "256k")/gi' $ms_path/bin/ffmpeg 2>> $logfile
    info "${GREEN}Sucesfully changed the audio stream's order to: 1) AAC 5.1 512kbps and 2) MP3 2.0 256kbps in DLNA MediaServer."
    echo ""
else
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED and this codec Configurator CAN'T change anything."
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED and this codec Configurator CAN'T change anything." >> $logfile
   info "${BLUE}Please, Install the Advanced Wrapper first and then you will can change the audio's streams order."
   start
fi	
}

function config_E() {
if [[ "$check_amrif" == "$firma2" ]]; then 
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED in DLNA Media Server and this codec Configurator CAN'T change anything."
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED in DLNA Media Server and this codec Configurator CAN'T change anything." >> $logfile
   info "${BLUE}Please, Install the Advanced Wrapper first and then you will can change the audio's streams order."
   start
fi

if [[ "$check_amrif" == "$firma" ]]; then  
    info "${YELLOW}Changing to use FIRST STREAM= MP3 2.0 256kbpss, SECOND STREAM= AAC 5.1 512kbps in DLNA MediaServer."
    info "${YELLOW}Changing to use FIRST STREAM= MP3 2.0 256kbpss, SECOND STREAM= AAC 5.1 512kbps in DLNA MediaServer." >> $logfile
    sed -i 's/args2vs+=("-c:a:0" "libfdk_aac" "-c:a:1" "$1")/args2vs+=("-c:a:0" "$1" "-c:a:1" "libfdk_aac")/gi' $ms_path/bin/ffmpeg 2>> $logfile
    sed -i 's/args2vs+=("-ac:1" "6" "-ac:2" "$1")/args2vs+=("-ac:1" "$1" "-ac:2" "6")/gi' $ms_path/bin/ffmpeg 2>> $logfile
    sed -i 's/("-b:a:0" "512k" "-b:a:1" "256k")/("-b:a:0" "256k" "-b:a:1" "512k")/gi' $ms_path/bin/ffmpeg 2>> $logfile
    info "${GREEN}Sucesfully changed the audio stream's order to: 1) MP3 2.0 256kbps and 2) AAC 5.1 512kbps in DLNA MediaServer."
    echo ""
else
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED and this codec Configurator CAN'T change anything."
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED and this codec Configurator CAN'T change anything." >> $logfile
   info "${BLUE}Please, Install the Advanced Wrapper first and then you will can change the audio's streams order."
   start
fi	
}

function config_F() {
if [[ "$check_amrif" == "$firma2" ]]; then 
info "${YELLOW}Changing the 5.1 audio's codec from AC3 640kbps to AAC 512kbps independently of its audio's streams order in VIDEO-STATION."
info "${YELLOW}Changing the 5.1 audio's codec from AC3 640kbps to AAC 512kbps independently of its audio's streams order in VIDEO-STATION." >> $logfile
    sed -i 's/"ac3"/"libfdk_aac"/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/"640k"/"512k"/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/""/"6"/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    info "${GREEN}Sucesfully changed the 5.1 audio's codec from AC3 640kbps to AAC 512kbps in VIDEO-STATION."
    echo ""
fi

if [[ "$check_amrif" == "$firma" ]]; then  
    info "${YELLOW}Changing the 5.1 audio's codec from AC3 640kbps to AAC 512kbps independently of its audio's streams order in VIDEO-STATION and DLNA MediaServer."
    info "${YELLOW}Changing the 5.1 audio's codec from AC3 640kbps to AAC 512kbps independently of its audio's streams order in VIDEO-STATION and DLNA MediaServer." >> $logfile
    sed -i 's/"ac3"/"libfdk_aac"/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/"ac3"/"libfdk_aac"/gi' $ms_path/bin/ffmpeg 2>> $logfile
    sed -i 's/"640k"/"512k"/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/"640k"/"512k"/gi' $ms_path/bin/ffmpeg 2>> $logfile
    sed -i 's/""/"6"/gi' ${cp_bin_path}/ffmpeg41 2>> $logfile
    sed -i 's/""/"6"/gi' $ms_path/bin/ffmpeg 2>> $logfile
    info "${GREEN}Sucesfully changed the 5.1 audio's codec from AC3 640kbps to AAC 512kbps in VIDEO-STATION and DLNA MediaServer."
    echo ""
 else
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED and this codec Configurator CAN'T change anything."
   info "${RED}Actually You HAVEN'T THE ADVANCED WRAPPER INSTALLED and this codec Configurator CAN'T change anything." >> $logfile
   info "${BLUE}Please, Install the Advanced Wrapper first and then you will can change the audio's streams order."
   start
fi  
}

function start() {
   echo ""   
   echo -e "${YELLOW}THIS IS THE MAIN MENU, PLEASE CHOOSE YOUR SELECTION:"
   echo ""
   echo -e "${BLUE} ( I ) Install the Advanced Wrapper for VideoStation and DLNA MediaServer (If exist). (With 5.1 and 2.0 support, configurable)"
   echo -e "${BLUE} ( S ) Install the Simplest Wrapper for VideoStation and DLNA MediaServer (If exist). (Only 2.0 support, NOT configurable)"
   echo -e "${BLUE} ( U ) Uninstall the Simplest or the Advanced Wrappers for VideoStation and DLNA MediaServer." 
   echo -e "${BLUE} ( C ) Change the config of the Advanced Wrapper for change the audio's codecs in VIDEO-STATION and DLNA."
   echo ""
   echo -e "${PURPLE} ( Z ) EXIT from this Installer."
        while true; do
	echo -e "${GREEN}"
        read -p "Please, What option wish to use? " isucz
        case $isucz in
        [Ii]* ) install;;
        [Ss]* ) install_simple;;
        [Uu]* ) uninstall;;
	[Cc]* ) configurator;;
      	[Zz]* ) exit;;
        * ) echo -e "${YELLOW}Please answer I or Install | S or Simple | U or Uninstall | C or Config | Z or Exit.";;
        esac
        done
}

function titulo() {
   clear
echo -e "${BLUE}====================FFMPEG WRAPPER INSTALLER FOR DSM 7.0 and above by Dark Nebular.===================="
echo -e "${BLUE}====================This Wrapper Installer is only avalaible for DSM 7.0 and above only===================="
echo ""
echo ""
}

function check_root() {
   if [[ $EUID -ne 0 ]]; then
  error "YOU MUST BE ROOT FOR EXECUTE THIS INSTALLER. Please write ("${PURPLE}" sudo -i "${RED}") and try again with the Installer."
  exit 1
fi
}

function check_licence_AME() {
if [[ ! -f /var/packages/CodecPack/enabled ]]; then
error "You haven't the licence loaded in Advanced Media Extension package. Please load this licence and try again with the Installer."
error "You haven't the licence loaded in Advanced Media Extension package. Please load this licence and try again with the Installer." >> $logfile
exit 1
fi
}

function corrector() {
   # If exists this directory, It will change the paths and variables. The DSM 7.1 and future releases will be using this path. 
if [[ -d /var/packages/CodecPack/target/pack ]]; then
  cp_bin_path=/var/packages/CodecPack/target/pack/bin
  injector="1-12.3.3"
fi
}

function check_firmas() {
  
# CHEQUEOS DE FIRMAS
if [[ -f "$cp_bin_path/ffmpeg41.orig" ]]; then
check_amrif_1=$(sed -n '3p' < $cp_bin_path/ffmpeg41 | tr -d "# " | tr -d "\´sAdvancedWrapper")
fi

if [[ ! -f "$ms_path/bin/ffmpeg.orig" ]]; then
check_amrif_2="ar"
else
check_amrif_2=$(sed -n '3p' < $ms_path/bin/ffmpeg | tr -d "# " | tr -d "\´sAdvancedWrapper")
fi

check_amrif="$check_amrif_1$check_amrif_2"

}

function check_unsupported() {
   if check_version "$dsm_version" " " 6.2; then
   error "Your DSM Version $dsm_version is NOT supported using this installer. Please use the MANUAL Procedure."
   error "Your DSM Version $dsm_version is NOT supported using this installer. Please use the MANUAL Procedure." >> $logfile
 exit 1
fi
}

################################
# PROCEDIMIENTOS DEL PATCH
################################

function install() {
  
  info "${BLUE}==================== Installation of the Advanced Wrapper: START ===================="
  info "${BLUE}==================== Installation of the Advanced Wrapper: START ====================" >> $logfile
  echo ""
   info "${BLUE}You are running DSM $dsm_version"
   info "${BLUE}DSM $dsm_version is supported for this installer and the installer will tuned for your DSM"
   info "${BLUE}DSM $dsm_version is using this path: $cp_bin_path"
   info "${BLUE}DSM $dsm_version is using this injector: $injector"

for losorig in "${all_files[@]}"; do
if [[ -f "$losorig" ]]; then
        info "${RED}Actually you have a OLD or OTHER patch applied in your system, please UNINSTALL OLDER Wrapper first."
        info "${RED}Actually you have a OLD or OTHER patch applied in your system, please UNINSTALL OLDER Wrapper first." >> $logfile
	echo ""
	echo -e "${BLUE} ( YES ) = The Installer will Uninstall the OLD patch or Wrapper."
        echo -e "${PURPLE} ( NO ) = EXIT from the Installer menu and return to MAIN MENU."
        while true; do
	echo -e "${GREEN}"
        read -p "Do you wish to Uninstall this OLD wrapper? " yn
        case $yn in
        [Yy]* ) uninstall_old; break;;
        [Nn]* ) start;;
        * ) echo -e "${YELLOW}Please answer YES = (Uninstall the OLD wrapper) or NO = (Return to MAIN Menu).";;
        esac
        done
else
  
	  info "${YELLOW}Backup the original ffmpeg41 as ffmpeg41.orig."
	  info "${YELLOW}Backup the original ffmpeg41 as ffmpeg41.orig." >> $logfile
	mv -n ${cp_bin_path}/ffmpeg41 ${cp_bin_path}/ffmpeg41.orig 2>> $logfile
	  info "${YELLOW}Creating the esqueleton of the ffmpeg41"
	touch ${cp_bin_path}/ffmpeg41
	  info "${YELLOW}Injection of the ffmpeg41 wrapper using this injector: $injector."
	  info "${YELLOW}Injection of the ffmpeg41 wrapper using this injector: $injector." >> $logfile
	wget -q $repo_url/main/ffmpeg41-wrapper-DSM7_$injector -O ${cp_bin_path}/ffmpeg41 2>> $logfile
	 info "${GREEN}Waiting for consolidate the download of the wrapper."
        sleep 3
	  info "${YELLOW}Fixing permissions of the ffmpeg41 wrapper."
	  info "${YELLOW}Fixing permissions of the ffmpeg41 wrapper." >> $logfile
	chmod 755 ${cp_bin_path}/ffmpeg41 2>> $logfile
	info "${GREEN}Ensuring the existence of the new log file wrapper_ffmpeg."
	touch "$logfile"
	info "${GREEN}Installed correctly the wrapper41 in $cp_bin_path"
	
	
	
	info "${YELLOW}Backup the original libsynovte.so in VideoStation as libsynovte.so.orig."
	info "${YELLOW}Backup the original libsynovte.so in VideoStation as libsynovte.so.orig." >> $logfile
	cp -n $vs_libsynovte_file $vs_libsynovte_file.orig 2>> $logfile
	  info "${YELLOW}Fixing permissions of $vs_libsynovte_file.orig"
	  info "${YELLOW}Fixing permissions of $vs_libsynovte_file.orig" >> $logfile
	chown VideoStation:VideoStation $vs_libsynovte_file.orig 2>> $logfile
	  info "${YELLOW}Patching $vs_libsynovte_file for compatibility with DTS, EAC3 and TrueHD"
	  info "${YELLOW}Patching $vs_libsynovte_file for compatibility with DTS, EAC3 and TrueHD" >> $logfile
	sed -i -e 's/eac3/3cae/' -e 's/dts/std/' -e 's/truehd/dheurt/' $vs_libsynovte_file 2>> $logfile
	info "${GREEN}Modified correctly the file $vs_libsynovte_file"
	
	info "${GREEN}Installed correctly the Advanced Wrapper in VideoStation."
	
	break
		
fi
done

if [ ! -f "$ms_path/bin/ffmpeg.orig" ] && [ -d "$ms_path" ]; then

		info "${YELLOW}Backup the original ffmpeg as ffmpeg.orig in DLNA MediaServer."
		info "${YELLOW}Backup the original ffmpeg as ffmpeg.orig in DLNA MediaServer." >> $logfile
		mv -n $ms_path/bin/ffmpeg $ms_path/bin/ffmpeg.orig 2>> $logfile
		info "${YELLOW}Reuse of the ffmpeg41 wrapper in DLNA MediaServer."
		info "${YELLOW}Reuse of the ffmpeg41 wrapper in DLNA MediaServer." >> $logfile
		cp ${cp_bin_path}/ffmpeg41 $ms_path/bin/ffmpeg 2>> $logfile
		info "${YELLOW}Fixing permissions of the ffmpeg wrapper for the DLNA."
		info "${YELLOW}Fixing permissions of the ffmpeg wrapper for the DLNA." >> $logfile
		chmod 755 $ms_path/bin/ffmpeg 2>> $logfile
		chown MediaServer:MediaServer $ms_path/bin/ffmpeg 2>> $logfile
		info "${YELLOW}Changing the default audio's codecs order of this Wrapper in DLNA MediaServer."
		info "${YELLOW}Changing the default audio's codecs order of this Wrapper in DLNA MediaServer." >> $logfile
        sed -i 's/args2vs+=("-c:a:0" "$1" "-c:a:1" "libfdk_aac")/args2vs+=("-c:a:0" "libfdk_aac" "-c:a:1" "$1")/gi' $ms_path/bin/ffmpeg 2>> $logfile
        sed -i 's/args2vs+=("-ac:1" "$1" "-ac:2" "6")/args2vs+=("-ac:1" "6" "-ac:2" "$1")/gi' $ms_path/bin/ffmpeg 2>> $logfile
        sed -i 's/("-b:a:0" "256k" "-b:a:1" "512k")/("-b:a:0" "512k" "-b:a:1" "256k")/gi' $ms_path/bin/ffmpeg 2>> $logfile
		info "${YELLOW}Correcting of the version of this Wrapper in DLNA MediaServer."
		info "${YELLOW}Correcting of the version of this Wrapper in DLNA MediaServer." >> $logfile
		sed -i 's/rev="AME_12/rev="MS_12/gi' $ms_path/bin/ffmpeg 2>> $logfile
		info "${YELLOW}Correcting of the paths of this Wrapper in DLNA MediaServer."
		info "${YELLOW}Correcting of the paths of this Wrapper in DLNA MediaServer." >> $logfile
		sed -i 's#/var/packages/CodecPack/target/pack/bin/ffmpeg41.orig#/var/packages/MediaServer/target/bin/ffmpeg.orig#gi' $ms_path/bin/ffmpeg 2>> $logfile
        
		
		info "${YELLOW}Backup the original libsynovte.so in MediaServer as libsynovte.so.orig."
		info "${YELLOW}Backup the original libsynovte.so in MediaServer as libsynovte.so.orig." >> $logfile
		cp -n $ms_libsynovte_file $ms_libsynovte_file.orig 2>> $logfile
	  info "${YELLOW}Fixing permissions of $ms_libsynovte_file.orig"
	  info "${YELLOW}Fixing permissions of $ms_libsynovte_file.orig" >> $logfile
		chown MediaServer:MediaServer $ms_libsynovte_file.orig 2>> $logfile
		chmod 644 $ms_libsynovte_file.orig 2>> $logfile
	  info "${YELLOW}Patching $ms_libsynovte_file for compatibility with DTS, EAC3 and TrueHD"
	  info "${YELLOW}Patching $ms_libsynovte_file for compatibility with DTS, EAC3 and TrueHD" >> $logfile
		sed -i -e 's/eac3/3cae/' -e 's/dts/std/' -e 's/truehd/dheurt/' $ms_libsynovte_file 2>> $logfile
		info "${GREEN}Modified correctly the file $ms_libsynovte_file"
		
		info "${GREEN}Installed correctly the Advanced Wrapper in Media Server."
		   
fi

	
restart_packages

info "${BLUE}==================== Installation of the Advanced Wrapper: COMPLETE ===================="
info "${BLUE}==================== Installation of the Advanced Wrapper: COMPLETE ====================" >> $logfile
echo ""   

exit 1
}

function uninstall_old() {
  clear
  info "${BLUE}==================== Uninstallation of OLD wrappers in the system: START ===================="
  info "${BLUE}==================== Uninstallation of OLD wrappers in the system: START ====================" >> $logfile

  info "${YELLOW}Restoring VideoStation's libsynovte.so"
  info "${YELLOW}Restoring VideoStation's libsynovte.so" >> $logfile
  mv -T -f "$vs_libsynovte_file.orig" "$vs_libsynovte_file" 2>> $logfile
  
  
  if [[ -f "$vs_path/etc/TransProfile.orig" ]]; then
  info "${YELLOW}Restoring VideoStation's TransProfile if It has been modified in the past."
  info "${YELLOW}Restoring VideoStation's TransProfile if It has been modified in the past." >> $logfile
  mv -T -f "$vs_path/etc/TransProfile.orig" "$vs_path/etc/TransProfile" 2>> $logfile
  fi
  
  
  if [[ -d "$ms_path" ]]; then
    info "${YELLOW}Restoring MediaServer's libsynovte.so"
    info "${YELLOW}Restoring MediaServer's libsynovte.so" >> $logfile
    mv -T -f "$ms_libsynovte_file.orig" "$ms_libsynovte_file" 2>> $logfile
  
    find "$ms_path/bin" -type f -name "*.orig" | while read -r filename; do
    info "${YELLOW}Restoring MediaServer's $filename"
    info "${YELLOW}Restoring MediaServer's $filename" >> $logfile
    mv -T -f "$filename" "${filename::-5}" 2>> $logfile
    done
  fi
  
  find "$vs_path/bin" -type f -name "*.orig" | while read -r filename; do
    info "${YELLOW}Restoring VideoStation's $filename"
    info "${YELLOW}Restoring VideoStation's $filename" >> $logfile
    mv -T -f "$filename" "${filename::-5}" 2>> $logfile
  done
  
  
  find $cp_bin_path -type f -name "*.orig" | while read -r filename; do
      info "Restoring CodecPack's $filename"
      info "Restoring CodecPack's $filename" >> $logfile
      mv -T -f "$filename" "${filename::-5}" 2>> $logfile
  done

   info "${YELLOW}Delete old log file ffmpeg."
   info "${YELLOW}Delete old log file ffmpeg." >> $logfile
   touch /tmp/ffmpeg.log
   rm /tmp/ffmpeg.log
  
     
  info "${GREEN}Uninstalled correctly the old Wrapper"
  echo ""
  info "${BLUE}==================== Uninstallation of OLD wrappers in the system: COMPLETE ===================="
  info "${BLUE}==================== Uninstallation of OLD wrappers in the system: COMPLETE ====================" >> $logfile
  echo ""
  echo ""
  info "${PURPLE}====================CONTINUING With installation of the Advanced Wrapper...===================="
  info "${PURPLE}====================CONTINUING With installation of the Advanced Wrapper...====================" >> $logfile
  echo ""
  
  install
  
}

function uninstall_old_simple() {
  clear
  info "${BLUE}==================== Uninstallation of OLD wrappers in the system: START ===================="
  info "${BLUE}==================== Uninstallation of OLD wrappers in the system: START ====================" >> $logfile

  info "${YELLOW}Restoring VideoStation's libsynovte.so"
  info "${YELLOW}Restoring VideoStation's libsynovte.so" >> $logfile
  mv -T -f "$vs_libsynovte_file.orig" "$vs_libsynovte_file" 2>> $logfile
  
  if [[ -f "$vs_path/etc/TransProfile.orig" ]]; then
  info "${YELLOW}Restoring VideoStation's TransProfile if It has been modified in the past."
  info "${YELLOW}Restoring VideoStation's TransProfile if It has been modified in the past." >> $logfile
  mv -T -f "$vs_path/etc/TransProfile.orig" "$vs_path/etc/TransProfile" 2>> $logfile
  fi
  
  if [[ -d "$ms_path" ]]; then
  info "${YELLOW}Restoring MediaServer's libsynovte.so"
  info "${YELLOW}Restoring MediaServer's libsynovte.so" >> $logfile
  mv -T -f "$ms_libsynovte_file.orig" "$ms_libsynovte_file" 2>> $logfile
  
  find "$ms_path/bin" -type f -name "*.orig" | while read -r filename; do
    info "${YELLOW}Restoring MediaServer's $filename"
    info "${YELLOW}Restoring MediaServer's $filename" >> $logfile
    mv -T -f "$filename" "${filename::-5}" 2>> $logfile
  done
  fi


  find "$vs_path/bin" -type f -name "*.orig" | while read -r filename; do
    info "${YELLOW}Restoring VideoStation's $filename"
    info "${YELLOW}Restoring VideoStation's $filename" >> $logfile
    mv -T -f "$filename" "${filename::-5}" 2>> $logfile
  done
  
  

  find $cp_bin_path -type f -name "*.orig" | while read -r filename; do
      info "Restoring CodecPack's $filename"
      info "Restoring CodecPack's $filename" >> $logfile
      mv -T -f "$filename" "${filename::-5}" 2>> $logfile
  done
  
 
   info "${YELLOW}Delete old log file ffmpeg."
   info "${YELLOW}Delete old log file ffmpeg." >> $logfile
   touch /tmp/ffmpeg.log
   rm /tmp/ffmpeg.log
  
    

  info "${GREEN}Uninstalled correctly the old Wrapper"
  echo ""
  info "${BLUE}==================== Uninstallation of OLD wrappers in the system: COMPLETE ===================="
  info "${BLUE}==================== Uninstallation of OLD wrappers in the system: COMPLETE ====================" >> $logfile
  echo ""
  echo ""
  info "${PURPLE}====================CONTINUING With installation of the Simplest Wrapper...===================="
  info "${PURPLE}====================CONTINUING With installation of the Simplest Wrapper...====================" >> $logfile
  echo ""
  
  install_simple
  
}

function uninstall() {
  for losorig in "${all_files[@]}"; do
  if [[ -f "$losorig" ]]; then
  info "${BLUE}==================== Uninstallation the Simplest or the Advanced Wrapper: START ===================="
  
  info "${YELLOW}Restoring VideoStation's libsynovte.so"
  mv -T -f "$vs_libsynovte_file.orig" "$vs_libsynovte_file"
  
  if [[ -d "$ms_path" ]]; then
  info "${YELLOW}Restoring MediaServer's libsynovte.so"
  mv -T -f "$ms_libsynovte_file.orig" "$ms_libsynovte_file"
  
       find "$ms_path/bin" -type f -name "*.orig" | while read -r filename; do
       info "${YELLOW}Restoring MediaServer's $filename"
       mv -T -f "$filename" "${filename::-5}"
       done
  fi

      find $cp_bin_path -type f -name "*.orig" | while read -r filename; do
      info "Restoring CodecPack's $filename"
      mv -T -f "$filename" "${filename::-5}"
      done
  info "${YELLOW}Delete new log file wrapper_ffmpeg."
	touch "$logfile"
	rm "$logfile"

  restart_packages
  
  info "${GREEN}Uninstalled correctly the Simplest or the Advanced Wrapper in DLNA MediaServer (If exist) and VideoStation."

  echo ""
  info "${BLUE}==================== Uninstallation the Simplest or the Advanced Wrapper: COMPLETE ===================="
  exit 1
  
  else
  
  info "${RED}Actually You HAVEN'T ANY Wrapper Installed. The Uninstaller CAN'T do anything."
  exit 1
  
  fi
  done
}

function configurator() {
clear

if [[ "$check_amrif" == "$firma2" ]]; then 

        echo ""
        info "${BLUE}==================== Configuration of the Advanced Wrapper: START ===================="
	echo ""
        echo -e "${YELLOW}REMEMBER: If you change the order in VIDEO-STATION you will have ALWAYS AAC 5.1 512kbps in first audio stream and some devices not compatibles with 5.1 neigther multi audio streams like Chromecast will not work"
        echo -e "${BLUE}Now you can change the audio's codec from from AAC 512kbps to AC3 640kbps independently of its audio's streams."
	echo -e "${BLUE}AC3 640kbps has a little bit less quality and worse performance than AAC but is more compatible with LEGACY devices."
	echo ""
        echo ""
        echo -e "${YELLOW}THIS IS THE CONFIGURATOR TOOL MENU, PLEASE CHOOSE YOUR SELECTION:"
        echo ""
        echo -e "${BLUE} ( A ) FIRST STREAM= MP3 2.0 256kbpss, SECOND STREAM= AAC 5.1 512kbps when It needs to do transcoding in VIDEO-STATION. (DEFAULT ORDER VIDEO-STATION)"
        echo -e "${BLUE} ( B ) FIRST STREAM= AAC 5.1 512kbps, SECOND STREAM= MP3 2.0 256kbps when It needs to do transcoding in VIDEO-STATION." 
        echo -e "${YELLOW} ( C ) Change the 5.1 audio's codec from AAC 512kbps to AC3 640kbps independently of its audio's streams order in both."
        echo -e "${RED} ( D ) FIRST STREAM= AAC 5.1 512kbps, SECOND STREAM= MP3 2.0 256kbps when It needs to do transcoding in DLNA MediaServer. (DEFAULT ORDER DLNA)"
        echo -e "${RED} ( E ) FIRST STREAM= MP3 2.0 256kbpss, SECOND STREAM= AAC 5.1 512kbps when It needs to do transcoding in DLNA MediaServer."
        echo -e "${YELLOW} ( F ) Change the 5.1 audio's codec from AC3 640kbps to AAC 512kbps independently of its audio's streams order in both."
        echo ""
        echo -e "${PURPLE} ( Z ) RETURN to MAIN menu."
   	while true; do
	echo -e "${GREEN}"
        read -p "Do you wish to change the order of these audio stream in the Advanced wrapper? " abcdefz
        case $abcdefz in
        [Aa] ) config_A; break;;
        [Bb] ) config_B; break;;
	[Cc] ) config_C; break;;
	[Dd] ) config_D; break;;
	[Ee] ) config_E; break;;
	[Ff] ) config_F; break;;
	[Zz] ) start; break;;
        * ) echo -e "${YELLOW}Please answer with the correct option writing: A or B or C or D or E or F. Write Z (for return to MAIN menu).";;
        esac
        done
   
   info "${BLUE}==================== Configuration of the Advanced Wrapper: COMPLETE ===================="
   info "${BLUE}==================== Configuration of the Advanced Wrapper: COMPLETE ====================" >> $logfile
   exit 1
fi

if [[ "$check_amrif" == "$firma" ]]; then

        echo ""
        info "${BLUE}==================== Configuration of the Advanced Wrapper: START ===================="
	echo ""
        echo -e "${YELLOW}REMEMBER: If you change the order in VIDEO-STATION you will have ALWAYS AAC 5.1 512kbps in first audio stream and some devices not compatibles with 5.1 neigther multi audio streams like Chromecast will not work"
        echo -e "${BLUE}Now you can change the audio's codec from from AAC 512kbps to AC3 640kbps independently of its audio's streams."
	echo -e "${BLUE}AC3 640kbps has a little bit less quality and worse performance than AAC but is more compatible with LEGACY devices."
	echo ""
        echo ""
        echo -e "${YELLOW}THIS IS THE CONFIGURATOR TOOL MENU, PLEASE CHOOSE YOUR SELECTION:"
        echo ""
        echo -e "${BLUE} ( A ) FIRST STREAM= MP3 2.0 256kbpss, SECOND STREAM= AAC 5.1 512kbps when It needs to do transcoding in VIDEO-STATION. (DEFAULT ORDER VIDEO-STATION)"
        echo -e "${BLUE} ( B ) FIRST STREAM= AAC 5.1 512kbps, SECOND STREAM= MP3 2.0 256kbps when It needs to do transcoding in VIDEO-STATION." 
        echo -e "${BLUE} ( C ) Change the 5.1 audio's codec from AAC 512kbps to AC3 640kbps independently of its audio's streams order in both."
        echo -e "${BLUE} ( D ) FIRST STREAM= AAC 5.1 512kbps, SECOND STREAM= MP3 2.0 256kbps when It needs to do transcoding in DLNA MediaServer. (DEFAULT ORDER DLNA)"
        echo -e "${BLUE} ( E ) FIRST STREAM= MP3 2.0 256kbpss, SECOND STREAM= AAC 5.1 512kbps when It needs to do transcoding in DLNA MediaServer."
        echo -e "${BLUE} ( F ) Change the 5.1 audio's codec from AC3 640kbps to AAC 512kbps independently of its audio's streams order in both."
        echo ""
        echo -e "${PURPLE} ( Z ) RETURN to MAIN menu."
   	while true; do
	echo -e "${GREEN}"
        read -p "Do you wish to change the order of these audio stream in the Advanced wrapper? " abcdefz
        case $abcdefz in
        [Aa] ) config_A; break;;
        [Bb] ) config_B; break;;
	[Cc] ) config_C; break;;
	[Dd] ) config_D; break;;
	[Ee] ) config_E; break;;
	[Ff] ) config_F; break;;
	[Zz] ) start; break;;
        * ) echo -e "${YELLOW}Please answer with the correct option writing: A or B or C or D or E or F. Write Z (for return to MAIN menu).";;
        esac
        done
   
   info "${BLUE}==================== Configuration of the Advanced Wrapper: COMPLETE ===================="
   info "${BLUE}==================== Configuration of the Advanced Wrapper: COMPLETE ====================" >> $logfile
   exit 1

else
   info "${RED}Actually You HAVEN'T ANY WRAPPER INSTALLED and this codec Configurator CAN'T change anything."
   info "${RED}Actually You HAVEN'T ANY WRAPPER INSTALLED and this codec Configurator CAN'T change anything." >> $logfile
   info "${BLUE}Please, Install the Advanced Wrapper first and then you will can change the audio's streams order."
   start
fi


}

function install_simple() {
  
  info "${BLUE}==================== Installation of the Simplest Wrapper: START ===================="
  info "${BLUE}==================== Installation of the Simplest Wrapper: START ====================" >> $logfile
  echo ""
   info "${BLUE}You are running DSM $dsm_version"
   info "${BLUE}DSM $dsm_version is supported for this installer and the installer will tuned for your DSM"
   info "${BLUE}DSM $dsm_version is using this path: $cp_bin_path"
   info "${BLUE}DSM $dsm_version is using this injector: Simple"
   
for losorig in "${all_files[@]}"; do
if [[ -f "$losorig" ]]; then
        info "${RED}Actually you have a OLD or OTHER patch applied in your system, please UNINSTALL OLDER Wrapper first."
        info "${RED}Actually you have a OLD or OTHER patch applied in your system, please UNINSTALL OLDER Wrapper first." >> $logfile
	echo ""
	echo -e "${BLUE} ( YES ) = The Installer will Uninstall the OLD patch or Wrapper."
        echo -e "${PURPLE} ( NO ) = EXIT from the Installer menu and return to MAIN MENU."
        while true; do
	echo -e "${GREEN}"
        read -p "Do you wish to Uninstall this OLD wrapper? " yn
        case $yn in
        [Yy]* ) uninstall_old_simple; break;;
        [Nn]* ) start;;
        * ) echo -e "${YELLOW}Please answer YES = (Uninstall the OLD wrapper) or NO = (Return to MAIN Menu).";;
        esac
        done
else
  
	  info "${YELLOW}Backup the original ffmpeg41 as ffmpeg41.orig."
	  info "${YELLOW}Backup the original ffmpeg41 as ffmpeg41.orig." >> $logfile
    	mv -n ${cp_bin_path}/ffmpeg41 ${cp_bin_path}/ffmpeg41.orig 2>> $logfile
	  info "${YELLOW}Creating the esqueleton of the ffmpeg41"
	touch ${cp_bin_path}/ffmpeg41 
	  info "${YELLOW}Injection of the ffmpeg41 wrapper using this injector: Simplest."
	  info "${YELLOW}Injection of the ffmpeg41 wrapper using this injector: Simplest." >> $logfile
	wget -q $repo_url/main/simplest_wrapper -O ${cp_bin_path}/ffmpeg41 2>> $logfile
	  info "${GREEN}Waiting for consolidate the download of the wrapper."
        sleep 3
	  info "${YELLOW}Fixing permissions of the ffmpeg41 wrapper."
	  info "${YELLOW}Fixing permissions of the ffmpeg41 wrapper." >> $logfile
	chmod 755 ${cp_bin_path}/ffmpeg41 2>> $logfile
	info "${GREEN}Ensuring the existence of the new log file wrapper_ffmpeg."
	touch "$logfile"
	info "${GREEN}Installed correctly the wrapper41 in $cp_bin_path"
		
	info "${YELLOW}Backup the original libsynovte.so in VideoStation as libsynovte.so.orig."
	info "${YELLOW}Backup the original libsynovte.so in VideoStation as libsynovte.so.orig." >> $logfile
	cp -n $vs_libsynovte_file $vs_libsynovte_file.orig 2>> $logfile
	  info "${YELLOW}Fixing permissions of $vs_libsynovte_file.orig"
	  info "${YELLOW}Fixing permissions of $vs_libsynovte_file.orig" >> $logfile
	chown VideoStation:VideoStation $vs_libsynovte_file.orig 2>> $logfile
	  info "${YELLOW}Patching $vs_libsynovte_file for compatibility with DTS, EAC3 and TrueHD"
	  info "${YELLOW}Patching $vs_libsynovte_file for compatibility with DTS, EAC3 and TrueHD" >> $logfile
	sed -i -e 's/eac3/3cae/' -e 's/dts/std/' -e 's/truehd/dheurt/' $vs_libsynovte_file 2>> $logfile
	info "${GREEN}Modified correctly the file $vs_libsynovte_file"
	
	info "${GREEN}Installed correctly the Simplest Wrapper in Video Station."
	
	break
fi
done

if [ ! -f "$ms_path/bin/ffmpeg.orig" ] && [ -d "$ms_path" ]; then

	info "${YELLOW}Backup the original ffmpeg as ffmpeg.orig in DLNA MediaServer."
	info "${YELLOW}Backup the original ffmpeg as ffmpeg.orig in DLNA MediaServer." >> $logfile
	mv -n $ms_path/bin/ffmpeg $ms_path/bin/ffmpeg.orig 2>> $logfile
	info "${YELLOW}Reuse of the ffmpeg41 wrapper in DLNA MediaServer."
	info "${YELLOW}Reuse of the ffmpeg41 wrapper in DLNA MediaServer." >> $logfile
	cp ${cp_bin_path}/ffmpeg41 $ms_path/bin/ffmpeg 2>> $logfile
	info "${YELLOW}Fixing permissions of the ffmpeg wrapper for the DLNA."
	info "${YELLOW}Fixing permissions of the ffmpeg wrapper for the DLNA." >> $logfile
	chmod 755 $ms_path/bin/ffmpeg 2>> $logfile
	chown MediaServer:MediaServer $ms_path/bin/ffmpeg 2>> $logfile
	info "${GREEN}Installed correctly the Wrapper in $ms_path/bin"
		
	info "${YELLOW}Backup the original libsynovte.so in MediaServer as libsynovte.so.orig."
	info "${YELLOW}Backup the original libsynovte.so in MediaServer as libsynovte.so.orig." >> $logfile
	cp -n $ms_libsynovte_file $ms_libsynovte_file.orig 2>> $logfile
	  info "${YELLOW}Fixing permissions of $ms_libsynovte_file.orig"
	  info "${YELLOW}Fixing permissions of $ms_libsynovte_file.orig" >> $logfile
	chown MediaServer:MediaServer $ms_libsynovte_file.orig 2>> $logfile
	chmod 644 $ms_libsynovte_file.orig 2>> $logfile
	  info "${YELLOW}Patching $ms_libsynovte_file for compatibility with DTS, EAC3 and TrueHD"
	  info "${YELLOW}Patching $ms_libsynovte_file for compatibility with DTS, EAC3 and TrueHD" >> $logfile
	sed -i -e 's/eac3/3cae/' -e 's/dts/std/' -e 's/truehd/dheurt/' $ms_libsynovte_file 2>> $logfile
	info "${GREEN}Modified correctly the file $ms_libsynovte_file"
	
	info "${GREEN}Installed correctly the Simplest Wrapper in Media Server."
   
fi

restart_packages

echo ""
info "${BLUE}==================== Installation of the Simplest Wrapper: COMPLETE ===================="
info "${BLUE}==================== Installation of the Simplest Wrapper: COMPLETE ====================" >> $logfile
exit 1

}

################################
# EJECUCIÓN
################################
while getopts s: flag; do
  case "${flag}" in
    s) setup=${OPTARG};;
    *) echo "usage: $0 [-s install|uninstall|config|info]" >&2; exit 1;;
  esac
done

titulo

check_root

welcome

check_dependencias

check_licence_AME

corrector

check_firmas

check_unsupported


case "$setup" in
  start) start;;
  install) install;;
  uninstall) uninstall;;
  config) configurator;;
  info) exit 1;;
esac
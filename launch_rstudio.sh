#!/bin/bash
# Run RStudio server in Singularity
# Runs on localhost:PORT
# Access via browser, login with Linux username and PASSWORD set by script.
# Fredrik Boulund, Lauri Mesilaakso 2024

set -euo pipefail

VERSION="v2.2"
PASSWORD="secret"
IMAGE="/ceph/apps/rstudio/ctmr_rocker_tidyverse-4.3.3-2.0.sif"  # docker://rocker/tidyverse:4.3.3

usage()
{
  echo "Run RStudio server in Singularity. Version $VERSION."
  echo
  echo "usage: launch_rstudio [-h] -p PORT [-P PASSWORD] [-i IMAGE]"
  echo
  echo "options:"
  echo "-i IMAGE      RStudio Docker IMAGE to use (default: ${IMAGE})."
  echo "-I ID         Unique instance ID to load earlier R session."
  echo "-P PASSWORD   Set the PASSWORD for logging into RStudio (default: ${PASSWORD})."
  echo "-p PORT       PORT used to access RStudio, required."
  echo "-h            Print this help."
  echo
  echo "Access via browser at:"
  echo "  http://localhost:PORT"
  echo
  echo "Login with:"
  echo "  user: $(whoami)"
  echo "  pass: ${PASSWORD}  (change with -P PASSWORD)"
  echo
}

while getopts "hi:I:P:p:" option; do
   case $option in
      h) # Show help
         usage
         exit;;
      i) # Specify Docker image
         IMAGE=${OPTARG:-IMAGE};;
      I) # Unique instance ID
         INSTANCE_ID=$OPTARG;;
      P) # Set PASSWORD
         PASSWORD=${OPTARG:-PASSWORD};;
      p) # Set PORT
         PORT=$OPTARG;;
     \?) # Invalid option
         usage
         echo "ERROR: Invalid option!"
         exit;;
   esac
done

if [ -z ${PORT+x} ]; then
	 echo "ERROR: PORT is required, use -p PORT to set."
	 exit
fi

if [ -f "$IMAGE.md5" ]; then
	CHECKSUM=$(cut -b1-32 $IMAGE.md5)
	echo "INFO: Using pre-computed md5sum: $CHECKSUM"
else
	echo "INFO: Computing md5sum for $IMAGE ..."
	CHECKSUM=$(md5sum $IMAGE | cut -b1-32)
	echo "INFO: Checksum computed: $CHECKSUM"
fi

PREFIX="$HOME/.rstudio_singularity/$CHECKSUM"
echo "INFO: Will use $PREFIX for container"

if [ -d "$HOME/R" ]; then
	echo "INFO: Container will mask existing R package directory $HOME/R"
fi
if [ -f "$HOME/.RData" ]; then
	echo "INFO: Container will mask existing R session data at $HOME/.RData"
fi
if [ -f "$HOME/.Rhistory" ]; then
	echo "INFO: Container will mask existing R history at $HOME/.Rhistory"
fi

if [ -z ${INSTANCE_ID+x} ]; then
	 INSTANCE_ID=$(echo $(tr -dc A-Za-z0-9 < /dev/urandom | head -c 6))
	 echo "INFO: Generated unique instance ID: $INSTANCE_ID"
	 mkdir -pv $PREFIX/$INSTANCE_ID
	 touch $PREFIX/$INSTANCE_ID/Rhistory
	 touch $PREFIX/$INSTANCE_ID/RData 
else
	 echo "INFO: Using provided instance ID: $INSTANCE_ID"
	 if [ ! -f $PREFIX/$INSTANCE_ID/Rhistory ]; then
		 echo "ERROR: No R session data found for instance ID: $INSTANCE_ID"
		 exit 1
     fi
fi

mkdir -pv $PREFIX/$INSTANCE_ID/run $PREFIX/$INSTANCE_ID/var-lib-rstudio-server $PREFIX/R

if [ -f $PREFIX/database.conf ]; then
	echo "INFO: Using pre-existing database.conf"
else
	printf 'provider=sqlite\ndirectory=/var/lib/rstudio-server\n' > $PREFIX/database.conf
	echo "INFO: Created $PREFIX/database.conf"
fi


echo "INFO: Launching RStudio in Singularity..."
echo
echo "  Current workdir:     $(pwd)"
echo "  Singularity image:   $IMAGE"
echo "  R package directory: $PREFIX/R"
echo "  Unique instance ID:  $INSTANCE_ID   (use '-I $INSTANCE_ID' to resume this session)"
echo "  Port:                $PORT"
echo "  User:                $USER"
echo "  Password:            $PASSWORD"
echo
echo "  Access RStudio at:   http://localhost:$PORT"
echo
echo "  (remember to enable SSH port tunnel)"
echo

export PASSWORD
bind_rundir="$PREFIX/$INSTANCE_ID/run:/run"
bind_server="$PREFIX/$INSTANCE_ID/var-lib-rstudio-server:/var/lib/rstudio-server"
bind_database="$PREFIX/database.conf:/etc/rstudio/database.conf"
bind_rdata="$PREFIX/$INSTANCE_ID/RData:$HOME/.RData"
bind_rhistory="$PREFIX/$INSTANCE_ID/Rhistory:$HOME/.Rhistory"
bind_rdir="$PREFIX/R:$HOME/R"
bind_ceph="/ceph:/ceph"
singularity exec \
	--bind $bind_rundir,$bind_server,$bind_rdata,$bind_rhistory,$bind_rdir,$bind_ceph \
	$IMAGE \
	/usr/lib/rstudio-server/bin/rserver \
		--server-user=$(whoami) \
		--www-port=$PORT \
		--auth-none=0 \
		--auth-pam-helper-path=pam-helper \
		--auth-timeout-minutes=0 \
		--auth-stay-signed-in-days=30 \


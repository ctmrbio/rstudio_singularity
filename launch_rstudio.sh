#!/bin/bash
# Run RStudio server in Singularity
# Runs on localhost:PORT
# Access via browser, login with Gandalf username and PASSWORD
# Fredrik Boulund, Lauri Mesilaakso 2024

set -euo pipefail

VERSION="v2.1"
PASSWORD="secret"
IMAGE="/ceph/apps/rstudio/ctmr_rocker_tidyverse-4.3.3-2.0.sif"  # docker://rocker/tidyverse:4.3.3
PREFIX="$HOME/.rstudio_singularity"

usage()
{
  echo "Run RStudio server in Singularity. Version $VERSION."
  echo
  echo "usage: launch_rstudio [-h] -p PORT [-P PASSWORD] [-i IMAGE]"
  echo
  echo "options:"
  echo "-i IMAGE      RStudio Docker IMAGE to use (default: ${IMAGE})"
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

while getopts "hi:P:p:" option; do
   case $option in
      h) # Show help
         usage
         exit;;
      i) # Specify Docker image
         IMAGE=${OPTARG:-IMAGE};;
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
echo "INFO: Will use $PREFIX/$CHECKSUM for R package installations"

if [ -d "$HOME/R" ]; then
	echo "INFO: Container will mask existing R package directory $HOME/R"
fi

mkdir -pv $PREFIX/run $PREFIX/var-lib-rstudio-server $PREFIX/$CHECKSUM

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
echo "  R package directory: $PREFIX/$CHECKSUM"
echo "  Port:                $PORT"
echo "  User:                $USER"
echo "  Password:            $PASSWORD"
echo
echo "  Access RStudio at:   http://localhost:$PORT"
echo
echo "  (remember to enable SSH port tunnel)"
echo

export PASSWORD
bind_rundir="$PREFIX/run:/run"
bind_server="$PREFIX/var-lib-rstudio-server:/var/lib/rstudio-server"
bind_database="$PREFIX/database.conf:/etc/rstudio/database.conf"
bind_rdir="$PREFIX/$CHECKSUM:$HOME/R"
bind_ceph="/ceph:/ceph"
singularity exec \
	--bind $bind_rundir,$bind_server,$bind_rdir,$bind_ceph \
	$IMAGE \
	/usr/lib/rstudio-server/bin/rserver \
		--server-user=$(whoami) \
		--www-port=$PORT \
		--auth-none=0 \
		--auth-pam-helper-path=pam-helper \
		--auth-timeout-minutes=0 \
		--auth-stay-signed-in-days=30 \


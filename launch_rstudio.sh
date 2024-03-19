#!/bin/bash
# Run RStudio server in Singularity
# Runs on localhost:PORT
# Access via browser, login with Gandalf username and PASSWORD
# Fredrik Boulund, Lauri Mesilaakso 2024

PASSWORD="secret"
IMAGE="/ceph/apps/rstudio/rocker_tidyverse-4.3.3.sif"
PREFIX="$HOME/.rstudio_singularity"

usage()
{
  echo "Run RStudio server in Singularity."
  echo
  echo "usage: launch_rstudio [-h] -p PORT [-P PASSWORD] [-i IMAGE]"
  echo
  echo "options:"
  echo "-i IMAGE      RStudio Docker IMAGE to use (default: ${IMAGE}"
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

mkdir -pv $PREFIX/run $PREFIX/var-lib-rstudio-server
if [ -f $PREFIX/database.conf ]; then
	echo "Using pre-existing database.conf"
else
	printf 'provider=sqlite\ndirectory=/var/lib/rstudio-server\n' > $PREFIX/database.conf
	echo "Created $PREFIX/database.conf"
fi

export PASSWORD
echo "Launching RStudio image $IMAGE on PORT=$PORT with PASSWORD=$PASSWORD from $(pwd)"
singularity exec \
	--bind $PREFIX/run:/run,$PREFIX/var-lib-rstudio-server:/var/lib/rstudio-server,$PREFIX/database.conf:/etc/rstudio/database.conf,/ceph:/ceph \
	$IMAGE \
	/usr/lib/rstudio-server/bin/rserver \
		--server-user=$(whoami) \
		--www-port=$PORT \
		--auth-none=0 \
		--auth-pam-helper-path=pam-helper \
		--auth-timeout-minutes=0 \
		--auth-stay-signed-in-days=30 \


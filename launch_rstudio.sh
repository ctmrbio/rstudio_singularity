# Run RStudio server in Singularity
# Runs on localhost:PORT
# Access via browser, login with Gandalf username and PASSWORD
# Fredrik Boulund 2024

export IMAGE=docker://rocker/rstudio:latest #or path to local .sif file
export PASSWORD='secret'
export PORT=9091

mkdir -pv run var-lib-rstudio-server
printf 'provider=sqlite\ndirectory=/var/lib/rstudio-server\n' > database.conf

singularity exec \
	--bind run:/run,var-lib-rstudio-server:/var/lib/rstudio-server,database.conf:/etc/rstudio/database.conf \
	$IMAGE \
	/usr/lib/rstudio-server/bin/rserver \
		--www-port=$PORT \
		--auth-none=0 \
		--auth-pam-helper-path=pam-helper \
		--auth-timeout-minutes=0 \
		--auth-stay-signed-in-days=30 \
		--server-user=$(whoami)


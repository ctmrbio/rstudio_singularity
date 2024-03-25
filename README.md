# rstudio_singularity
Run Rstudio with Singularity

Based on documentation here: https://rocker-project.org/use/singularity.html

## Run RStudio on CTMR Gandalf
```
Run RStudio server in Singularity.

usage: launch_rstudio [-h] -p PORT [-P PASSWORD] [-i IMAGE]

options:
-i IMAGE      RStudio Docker IMAGE to use (default: /ceph/apps/rstudio/rocker_tidyverse-4.3.3.sif
-P PASSWORD   Set the PASSWORD for logging into RStudio (default: secret).
-p PORT       PORT used to access RStudio, required.
-h            Print this help.

Access via browser at:
   http://localhost:PORT

Login with:
   user: USERNAME
   pass: secret  (change with -P PASSWORD)
```

On CTMR Gandalf, this script is installed and available in every user's PATH as `ctmr-launch_rstudio.sh`.
Run the following command to launch RStudio in Singularity on PORT:
```
ctmr-launch_rstudio.sh -p PORT
```
Note that specifying a PORT is required, pick your favorite port that no one
else uses. 


The `/ceph` file system is bound at `/ceph` inside the running container. If
you are running this on another system than CTMR Gandalf, remove this from the
`--bind` argument to Singularity.

## Custom RStudio Singularity image
This repo contains a customized Singularity deffile `rstudio.Singularity`to
create a new image containing additional system libraries/packages required for
some R packages. It can be built with:
```
sudo singularity build ctmr_rocker_tidyverse-4.3.3-2.0.sif rstudio.Singularity
```


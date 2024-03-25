Bootstrap: docker
From: rocker/tidyverse:4.3.3

%labels
	Author Fredrik Boulund
	Version v2.0
	Description rocker/tidyverse:4.3.3 with additional packages
	Packages libglpk-dev libgsl-dev
	

%post
	apt-get update && apt-get install -y \
		libglpk-dev \
		libgsl-dev


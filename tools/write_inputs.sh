#!/usr/bin/env bash

# uDALES (https://github.com/uDALES/u-dales).

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Copyright (C) 2016-2019 the uDALES Team.

# script for setting key namoptions and writing *.inp.* files
# variables not specified in namoptions can be set here. It updates these in write_inputs.m and then runs the matlab code to produce the required text files.

# tg3315 20/07/2017, modified by SO 06/02/20, modified by DM 27/08/24

# NOTES 
# (1) if no forcing found in namoptions then applies the initial velocities and uses the pressure terms

# Assuming running from top-level project directory.
# u-dales/tools/write_inputs.sh <PATH_TO_CASE>

set -e

if (( $# < 1 )) 
then
    echo "The path to case/experiment folder must be set."
	echo "usage: FROM THE TOP LEVEL DIRECTORY run: u-dales/tools/write_inputs.sh <PATH_TO_CASE> "
	echo "... execution terminated"
    exit 0
fi

# go to experiment directory
pushd $1
	inputdir=$(pwd)

	## set experiment number via path
	iexpnr="${inputdir: -3}"

	## read in additional variables
	if [ -f config.sh ]; then
   	 source config.sh
	else
	 echo "config.sh must be set inside $1"
     exit 0
	fi

	## check if required variables are set
	if [ -z $DA_TOOLSDIR ]; then
	    echo "Script directory DA_TOOLSDIR must be set inside $1/config.sh"
	    exit
	fi;
	if [ -z $DA_EXPDIR ]; then
		echo "Experiment directory DA_EXPDIR must be set $1/config.sh"
		exit
	fi;

popd

####### modified function for sed -i
function sedi { if [[ "$OSTYPE" == "darwin"* ]]; then
        		sed -i '' "$1" "$2"
		elif [[ "$OSTYPE" == "linux-gnu" ]]; then
        		sed -i "$1" "$2"
		fi;}


####### set iexpnir in matlab file
sedi "/expnr = '/s/.*/expnr = '$iexpnr';/g" $DA_TOOLSDIR"/write_inputs.m"

###### RUN MATLAB SCRIPT
cd $DA_TOOLSDIR/
matlab -nodesktop -nosplash -r "write_inputs; quit"
cd $DA_EXPDIR/$iexpnr


###### alter files in namoptions

update_namoptions() {
    local filename=$1
    local varname=$2
    local sub_offset=$3  # number of garbage lines in the specific file

    if [ -f "$DA_EXPDIR/$iexpnr/${filename}" ]; then
        local count=$(wc -l < "$DA_EXPDIR/$iexpnr/${filename}")
		count=$(($count-$sub_offset))
    else
        local count=0
    fi

    if grep -w -q "$varname" "$DA_EXPDIR/$iexpnr/namoptions.$iexpnr"; then
        sedi "/^$varname =/s/.*/$varname = $count/g" "$DA_EXPDIR/$iexpnr/namoptions.$iexpnr"
    else
        sedi '/&WALLS/a\'$'\n'"$varname = $count"$'\n' "$DA_EXPDIR/$iexpnr/namoptions.$iexpnr"
    fi
}

# Call the function for blocks
update_namoptions "facet_sections_c.txt" "nfctsecs_c" 1
update_namoptions "facet_sections_w.txt" "nfctsecs_w" 1
update_namoptions "facet_sections_v.txt" "nfctsecs_v" 1
update_namoptions "facet_sections_u.txt" "nfctsecs_u" 1

update_namoptions "fluid_boundary_c.txt" "nbndpts_c" 2
update_namoptions "fluid_boundary_w.txt" "nbndpts_w" 2
update_namoptions "fluid_boundary_v.txt" "nbndpts_v" 2
update_namoptions "fluid_boundary_u.txt" "nbndpts_u" 2

update_namoptions "solid_c.txt" "nsolpts_c" 2
update_namoptions "solid_w.txt" "nsolpts_w" 2
update_namoptions "solid_v.txt" "nsolpts_v" 2
update_namoptions "solid_u.txt" "nsolpts_u" 2

update_namoptions "facets.inp.$iexpnr" "nfcts" 1

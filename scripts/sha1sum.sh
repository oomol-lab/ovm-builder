#! /usr/bin/bash
cal_sha1sum(){
	cp /dev/null  .files_sha1sum
	sha1sum ./make ./target_builder/amd64_wsl2.sh >> .files_sha1sum
}


cd $(dirname $0)/../

# Must run in same dir of `make`
if [[ -f ./make ]];then
	echo "cal sha1sum"
	cal_sha1sum
else
	echo "Must run in same dir of make"
	exit 100
fi

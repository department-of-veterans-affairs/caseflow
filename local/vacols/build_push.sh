#!/bin/bash
today=$(date +"%Y%m%d")
bold=$(tput bold)
normal=$(tput sgr0)

USAGE=$(cat <<-END
./build_push.sh [local|remote|rake]

   This is a handy script which allows you to build, push or download FACOLS locally for your use.
   ${bold}You must first mfa using the issue_mfa.sh since it will download dependencies.${normal}
   Example Usage (build but not push): ./build_push.sh local
   Example Usage (build and push): ./build_push.sh remote

END
)

THIS_SCRIPT_DIR=$(dirname $0)

if [[ $# -eq 0 ]] ; then
  echo "$USAGE"
  exit 0
fi

if [[ $1 == "-h" ]]; then
  echo "$USAGE"
  exit 0
fi

if ! aws s3 ls --region us-gov-west-1 s3://shared-s3/dsva-appeals/facols/ > /dev/null ; then
  echo "Please run issue_mfa.sh first"
  exit 1
fi

if ! [ -x "$(command -v aws)" ]; then
  echo 'Error: aws-cli is not installed.' >&2
  echo 'Try: brew install awscli' >&2
  exit 1
fi

if [[ $# -gt 1 ]]; then
  echo "$USAGE" >&2
  exit 1
fi

build(){
  build_facols_dir="${THIS_SCRIPT_DIR}/build_facols"

  echo "${bold}Building FACOLS from Base Oracle...${normal}"

  echo -e "\tCleaning Up Old dependencies and Bring Required Packages"
  rm -rf $build_facols_dir && mkdir $build_facols_dir

  parent_dir=$PWD

  cp $parent_dir/Dockerfile $parent_dir/setup_vacols.sql $parent_dir/vacols_copy_* $build_facols_dir

  echo -e "\tDownloading FACOLS Dependencies..."
  aws s3 sync --quiet --region us-gov-west-1 s3://shared-s3/dsva-appeals/facols/ $build_facols_dir

  echo -e "\tChecking if Instant Client has been downloaded"
  if [ $? -eq 0 ]; then
    if [ ! -f $build_facols_dir/linuxx64_12201_database.zip ] ; then
      echo -e "${bold}Error: ${normal}Couldn't download the file. Exiting"
      exit 1
    fi
  fi

  # Build Docker
  echo -e "\tCreating FACOLS App Docker Image"
  echo "--------"
  echo ""

  docker build --force-rm --no-cache --tag  vacols_db:latest $build_facols_dir
  docker_build_result=$?
  echo ""
  echo "--------"
  if [[ $docker_build_result -eq 0 ]]; then
    echo -e "\tCleaning Up..."
    rm -rf $build_facols_dir
    docker_build="SUCCESS"
    echo ""
    echo "Building FACOLS Docker App: ${bold}${docker_build}${normal}"
    return 0
  else
    docker_build="FAILED"
    echo ""
    echo "Building FACOLS Docker App: ${bold}${docker_build}${normal}"
    echo "Please check above if there were execution errors."
    return 1
  fi
}

push(){
  aws ecr get-login-password --region us-gov-west-1 | docker login --username AWS --password-stdin 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com
  docker tag vacols_db:latest vacols_db:${today}
  docker tag vacols_db:${today} 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/facols:${today}
  docker tag vacols_db:latest 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/facols:latest
  if docker push 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/facols:${today} ; then
    docker push 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/facols:latest
    echo "${bold}Success. ${normal}The latest docker image has been pushed."
  else
    echo "${bold}Failed to Upload. ${normal}Probably you don't have permissions to do this. Ask the DevOps Team please"
  fi

}

download(){
  # get circleci latest image from this same repo
  facols_image=$(cat ${THIS_SCRIPT_DIR}/../../.circleci/config.yml| grep -m 1 facols | awk '{print $3}')
  aws ecr get-login-password --region us-gov-west-1 | docker login --username AWS --password-stdin 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com
  docker pull $facols_image
  docker tag $facols_image vacols_db:latest
}


if [[ "$1" == "local" ]]; then
  build

elif [[ "$1" == "remote" ]]; then
  build
  if [[ $? -eq 0 ]]; then
    push
  fi

elif [[ "$1" == "rake" ]]; then
  download
fi

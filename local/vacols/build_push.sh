#!/bin/bash
today=$(date +"%Y%m%d")
bold=$(tput bold)
normal=$(tput sgr0)

USAGE=$(cat <<-END
./build_push.sh [local|remote]

   This is a handy script which allows you to build FACOLS locally for your development.
   ${bold}You must first mfa using the issue_mfa.sh since it will download dependencies.${normal}
   Example Usage (build but not push): ./buildPush.sh local
   Example Usage (build and push): ./buildPush.sh remote

END
)

if [[ $# -eq 0 ]] ; then
  echo "$USAGE"
  exit 0
fi

if [[ $1 == "-h" ]]; then
  echo "$USAGE"
  exit 0
fi

if [[ -z "${AWS_SECURITY_TOKEN}" ]]; then
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

  echo "${bold}Building FACOLS from Base Oracle...${normal}"

  echo -e "\tCleaning Up Old dependencies and Bring Required Packages"
  #rm -rf build_facols
  #mkdir build_facols
  cp Dockerfile setup_vacols.sql vacols_copy_* build_facols
  cd build_facols

  echo -e "\tDownloading FACOLS Dependencies..."
  aws s3 sync --region us-gov-west-1 s3://shared-s3/dsva-appeals/facols/ ./

  echo -e "\tChecking if Instant Client has been downloaded"
  if [ $? -eq 0 ]; then
    if [ ! -f linuxx64_12201_database.zip ] ; then
      echo -e "${bold}Error: ${normal}Couldn't download the file. Exiting"
      exit 1
    fi
  fi

  # Build Docker
  echo -e "\tCreating Caseflow App Docker Image"

  docker build -t facols_local:${today} .

  echo -e "\tCleaning Up..."
  #cd ../ && rm -rf build_facols

  echo "${bold}Building Caseflow Docker App: Completed${normal}"
}

push(){
  eval $(aws ecr get-login --no-include-email --region us-gov-west-1)

  docker tag facols_local:${today} 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/facols:${today}
  if docker push 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/facols:${today} ; then
    echo "${bold}Success. ${normal}The latest docker image has been pushed."
    echo "${bold}REMEMBER TO CHANGE THE CIRCLE CI CONFIG to use this image.${normal}"
    echo -e "\t008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/facols:${today}"
  else
    echo "${bold}Failed to Upload. ${normal}Probably you don't have permissions to do this. Ask the DevOps Team please"
  fi

}

if [[ $1 == "local" ]]; then
  build
elif [[ $1 == "remote" ]]; then
  build
  if [[ $? -eq 0 ]]; then
    push
  fi
fi

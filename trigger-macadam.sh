
if [[ "$#" -eq 0 ]]; then
  echo "using -h/--help to check parameters"
  exit 1
fi


baremental=(mac-2 mac-7-arm rhel-1 windows-1)


while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0"
        echo "-p|--purpose <purpose>: ['nightly','pr-test']" 
        echo "--e2etag, tags for e2e test"
        echo "-r|--pr <pr>"
        echo "--trigger create pipeline run with yaml files"
        exit 1 ;;
    -p|--purpose) 
        purpose=$2; 
        shift 2 ;;
    -r|--pr) 
        pr=$2; 
        shift 2 ;;
    --e2etag)
        e2eTag=$2;
        shift 2 ;;
    --trigger)
        trigger=$2;
        shift 2 ;;
  esac
done

if [ -d "test" ];then
 rm -r test
fi
mkdir test

revision="main"
if [[ "$pr" != "" ]]; then
    revision="refs/pull/${pr}/head"
    purpose="pr-${pr}"
fi
if [[ "$purpose" == "" ]]; then
    purpose="nightly-run"
fi

for i in ${baremental[@]}; do
    arch="amd64"
    imageUrl="''"
    e2eTag="''"

    echo "creating yaml file for $i"
    file="test/bare-$i.yaml"
    cp -r template/macadam-template.yaml $file
    if [[ $i == windows* ]]; then
        tester="secret-windows-1-brno"
        os="windows"
        imageUrl="https://crcqe-asia.s3.ap-south-1.amazonaws.com/macadam-image/Fedora-Cloud-Base-Azure-43-1.6.x86_64.vhd"
    elif [[ $i == mac* ]]; then
        os="darwin"
        if [[ $i == *-arm ]]; then
            tester="secret-mac-7-brno"
            arch="arm64"
        else
            tester="secret-mac-2-brno"
        fi
    elif [[ $i == rhel* ]]; then
        tester="secret-rhel-1-brno"
        os="linux"
    else
        echo "the platform $i is not support. Please check again"
        exit 1
    fi  

    sed -i'' -e "s#<OS>#${os}#g"  $file
    sed -i'' -e "s#<ARCH>#${arch}#g"  $file
    sed -i'' -e "s#<image-url>#${imageUrl}#g"  $file
    sed -i'' -e "s#<tester>#$tester#g"  $file
    sed -i'' -e "s#<e2e-tag>#${e2eTag}#g"  $file
    sed -i'' -e "s#<purpose>#${purpose}#g"  $file   
    sed -i'' -e "s#<revision>#${revision}#g"  $file
    sed -i'' -e  "s#<DATE>#$(date +%Y-%m-%d)#g"  $file
done

rm test/*.yaml-e

if [[ $trigger == 'true' ]]; then 
    oc project | grep "devtoolsqe--pipeline"
    oc create -f test
else    
    echo "pipeline run yaml files created in folder test"
fi
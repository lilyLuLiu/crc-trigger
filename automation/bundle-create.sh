function verify_ocp_exist() {
    ocpVersion=$1
    ocpArch=$2
    returnadd=""

    ocp_address="https://mirror.openshift.com/pub/openshift-v4/$ocpArch/clients/ocp/$ocpVersion"
    validAdd="$ocp_address/release.txt"
    validResult=$(curl -s -o /dev/null -w "%{http_code}" $validAdd)
    if [ $validResult == "200" ]; then
        echo $ocp_address
    else
        echo 'ERROR: Cant access the ocp content. Please check the ocp release address and version'
        exit 1
    fi
}

if [[ "$#" -eq 0 ]]; then
  echo "using -h/--help to check parameters"
  exit 1
fi

OPTIONS=$(getopt -o p:t:v:h --long help,purpose:,pr:,ocp:,trigger: -- "$@")
[ $? -ne 0 ] && echo "Error parsing options" && exit 1
eval set -- "$OPTIONS"

purpose="ocp-interop"
trigger="false"

while true; do
  case "$1" in
    -h|--help)
        echo "Usage: $0"
        echo "-p|--purpose <ocp-interop/snc-pr-test>, default ocp-interop" 
        echo "-o|--ocp <openshift version>"
        echo "--pr <snc pr>"
        echo "-t|--trigger <whether trigger pipeline runs>, default false"
        exit 1 ;;
    -p|--purpose) 
        purpose=$2; 
        shift 2 ;;
    --pr) 
        pr=$2; 
        shift 2 ;;
    -v|--ocp) 
        ocp=$2; 
        shift 2 ;;
    -t|--trigger)
        trigger=$2;
        shift 2 ;;
    --) 
        shift; break ;;
    *) 
        #echo '-h to check how to use the script'
        break
  esac
done

#echo $purpose

if [[ $ocp == '' ]]; then
    echo "Error: please input the openshift version"
    exit 1
fi

if [[ $purpose != 'ocp-interop' ]] && [[ $pr == '' ]]; then
    echo "Error: please input the snc pr number for snc-pr-test"
    exit 1
fi
if [[ $purpose == 'ocp-interop' ]] && [[ $pr != '' ]]; then
    echo "Error: ocp-interop test not support snc pr"
    exit 1
fi

archs=(arm64 x86_64)
sncRef=${ocp:0:4}
if [[ $purpose != "ocp-interop" ]]; then 
    s3Path="snc-pr/$pr/$ocp"
    title=$purpose-$pr-$ocp
else
    s3Path=$ocp
    title=$purpose-$ocp
fi

if [ -d "test" ];then
 rm -r test
fi
mkdir test
for i in ${archs[@]}; do
    echo "creating yaml file for $i"
    file="test/bundle-create-$i.yaml"
    cp  template/bundle-create-template.yaml $file

    address=$(verify_ocp_exist $ocp $i)

    sed -i'' -e "s#<ARCH>#$i#g"  $file
    sed -i'' -e "s#<SNC-REF>#$sncRef#g"  $file
    sed -i'' -e "s#<PR>#$pr#g"  $file
    sed -i'' -e "s#<S3-PATH>#$s3Path#g"  $file
    sed -i'' -e "s#<URL>#$address#g"  $file
    sed -i'' -e "s#<TITLE>#$title#g"  $file
done

if [[ $trigger == 'true' ]]; then 
    oc project | grep "devtoolsqe--pipeline"
    oc create -f test/*.yaml
else    
    echo "pipeline run yaml files created in folder test"
fi
#!/bin/bash

function verify_bundle_exist() {
    check_address=$1/$2
    echo "verify existing of $check_address"
    valid_code=$(curl -s -o /dev/null -w "%{http_code}" $check_address)
    echo $valid_code
    if [ $valid_code != 200 ]; then
        echo "The url of $check_address not accessible, please check again"
        exit 1
    fi
}

function create_yaml_file(){
    echo "creating yaml file for $1"
    file="test/$1.yaml"
    cp -r template/crc-latest-template.yaml $file
    sed -i'' -e "s#<Bundle-path>#${bundlePath}#g"  $file
    sed -i'' -e "s#<B-VERSION>#${bundle}#g"  $file
    
    sed -i'' -e "s#<DEBUG>#${debug}#g"  $file
    
    sed -i'' -e "s#<CRC-PR>#'$crcPR'#g"  $file
    sed -i'' -e "s#<RUN-e2e>#${runE2E}#g"  $file
    sed -i'' -e "s#<E2Etag>#${e2eTag}#g"  $file
    sed -i'' -e "s#<RUN-integration>#${runIntegration}#g"  $file
    sed -i'' -e "s#<integration-tag>#${integrationTag}#g"  $file

    sed -i'' -e "s#<S3>#${s3path}#g"  $file
    sed -i'' -e "s#<platform>#$1#g"  $file
    sed -i'' -e "s#<PURPOSE>#$purpose1#g"  $file

    arch="amd64"
    status=$pendingStatus
    builderValue="secret:\n        secretName:"
    if [[ $1 == "windows" ]]; then
        vm="hyperv"
        builder="host-windows-1-blr"
        tester="host-windows-1-brno"
    elif [[ $1 == mac* ]]; then
        vm="vfkit"
        builder="host-mac-1-brno"
        if [[ $1 == *-arm ]]; then
            arch="arm64"
            tester="host-mac-4-brno"
        else
            tester="host-mac-2-brno"
        fi
    elif [[ $1 == linux-amd ]]; then
        vm="libvirt"
        builderValue="emptyDir:"
        builder="{}"
        tester="host-rhel-1-brno"
    fi
    testerWorkspace="- name: tester-host-info\n      secret:\n        secretName: $tester"
    builderWorkspace="- name: builder-host-info\n      $builderValue $builder"
    if [[ $1 == linux-arm ]]; then
        builderWorkspace=''
        testerWorkspace='- name: az-credentials\n      secret:\n        secretName: az-crcqe-bot'
        pipeline="-arm64"
        arch="arm64"
        tester="{}"
        builder="{}"
        status=""
    else
        pipeline=""
    fi
    
    bundleName=crc_${vm}_${bundle}_${arch}.crcbundle

    sed -i'' -e "s#<TESTER>#$testerWorkspace#g"  $file
    sed -i'' -e "s#<tester>#$tester#g"  $file
    sed -i'' -e "s#<BUILDER>#$builderWorkspace#g"  $file    
    sed -i'' -e "s#<builder>#$builder#g"  $file    
    sed -i'' -e "s#<preset>#$preset#g"  $file
    sed -i'' -e "s#<pipeline>#$pipeline#g"  $file
    sed -i'' -e "s#<status>#$status#g"  $file
    sed -i'' -e "s#<Bundle-name>#${bundleName}#g"  $file


    if [[ $purpose == 'snc-pr-test' ]] || [[ $purpose == 'interop-test' ]] && [[ $1 == *-arm ]]; then       
        sed -i'' -e "s#<SHA-FILE>#${bundleShaArm}#g"  $file
    else
        sed -i'' -e "s#<SHA-FILE>#${bundleSha}#g"  $file
    fi
}


if [[ "$#" -eq 0 ]]; then
  echo "using -h/--help to check parameters"
  exit 1
fi

OPTIONS=$(getopt -o p:r:b:d:h --long help,purpose:,pr:,bundle:,preset:,e2e:,e2etag:,integration:,integrationtag:,platform:,debug:,trigger: -- "$@")
[ $? -ne 0 ] && echo "Error parsing options" && exit 1
eval set -- "$OPTIONS"

preset="openshift"
runE2E='true'
runIntegration='true'
platforms="windows,mac-amd,mac-arm,linux-amd,linux-arm"
purpose="nightly-run"
debug='false'
trigger='false'
pendingStatus="PipelineRunPending"

while true; do
  case "$1" in
    -h|--help)
        echo "Usage: $0"
        echo "-p|--purpose <purpose>: ['bundle-test','interop-test','nightly-run','crc-pr-test','snc-pr-test']" 
        echo "--platform , default: windows,mac-amd,mac-arm,linux-amd,linux-arm"
        echo "-b|--bundle <bundle>"
        echo "--preset openshift/microshift; default openshift"
        echo "--e2e whether run e2e test; default true"
        echo "--e2etag, tags for e2e test, default ~@minimal && ~@story_microshift && ~@release"
        echo "--integration, whether run integration test, default true"
        echo "--integrationtag, tags for integration test, default ! microshift-preset"
        echo "-r|--pr <pr>"
        echo "--trigger create pipeline run with yaml files"
        exit 1 ;;
    -p|--purpose) 
        purpose=$2; 
        shift 2 ;;
    -r|--pr) 
        pr=$2; 
        shift 2 ;;
    -b|--bundle) 
        bundle=$2; 
        shift 2 ;;
    --preset)
        preset=$2;
        shift 2 ;;
    --platform)
        platforms=$2;
        shift 2 ;;
    --e2e)
        runE2E=$2;
        shift 2 ;;
    --e2etag)
        e2eTag=$2;
        shift 2 ;;
    --integration)
        runIntegration=$2;
        shift 2 ;;
    --integrationtag)
        integrationTag=$2;
        shift 2 ;;
    -d|--debug)
        debug=$2;
        shift 2 ;;
    --trigger)
        trigger=$2;
        shift 2 ;;
    --) 
        shift; break ;;
    *) 
        echo '-h to check how to use the script'
        exit 1
  esac
done

echo "Purpose: $purpose"
echo "Bundle: $bundle"
if [[ $bundle == '' ]]; then
    echo "please input the bundle version"
    exit 1
fi


today=`date +"%Y%m%d"`

# deal with bundle path and s3 path
bundleSha="sha256sum.txt" 
crcPR=''
s3path="nightly/crc/$today"
bundlePath="https://cdk-builds.usersys.redhat.com/builds/crc/bundles/$preset"
bundleShaArm=""
purpose1=$purpose

if [[ $purpose == 'snc-pr-test' ]]; then
    bundlePath="https://crc-bundle.s3.us-east-1.amazonaws.com/snc-pr/${pr}"
    bundleSha="bundles.x86_64.sha256"
    bundleShaArm="bundles.arm64.sha256"
    s3path="nightly/crc/snc-pr/${pr}"
    purpose1=${purpose}-${pr}
elif [[ $purpose == 'interop-test' ]]; then
    bundlePath="https://crc-bundle.s3.us-east-1.amazonaws.com"
    bundleSha="bundles.x86_64.sha256"
    bundleShaArm="bundles.arm64.sha256"
    s3path="nightly/ocp"
elif [[ $purpose == 'crc-pr-test' ]]; then 
    crcPR=$pr
    s3path="nightly/crc/crc-pr/${pr}"
    purpose1=${purpose}-${pr}
elif [[ $purpose == 'bundle-test' ]]; then
    bundlePath="https://cdk-builds.usersys.redhat.com/builds/crc/bundles/$preset"
fi
verify_bundle_exist $bundlePath/$bundle $bundleSha
if [[ $bundleShaArm != "" ]]; then
    verify_bundle_exist $bundlePath/$bundle $bundleShaArm
fi

# deal with the default e2e and integration tags
e2eTagOcp="~@minimal \&\& ~@story_microshift \&\& ~@release"
integrationTagOcp="! microshift-preset"
e2eTagMicroshift="@story_microshift"
integrationTagMicroshift="microshift-preset"
if [[ $preset == "microshift" ]]; then
    if [[ $e2eTag == ''  ]]; then
        e2eTag=$e2eTagMicroshift
    fi
    if [[ $integrationTag == '' ]]; then
        integrationTag=$integrationTagMicroshift
    fi
else
    if [[ $e2eTag == ''  ]]; then
        e2eTag=$e2eTagOcp
    fi
    if [[ $integrationTag == '' ]]; then
        integrationTag=$integrationTagOcp
    fi
fi



# ENV: 
# 1. test purpose
# 2. bundle version
# 3. crc-pr
# 4. snc-pr
# 5. bundle-shasumfile
# 6. run-e2e
# 7. e2e-tag
# 8. run-integration
# 9. integration-tag
# 10. debug 

if [ -d "test" ];then
 rm -r test
fi
mkdir test
# Create pipeline run yaml file
IFS=',' read -ra allplatform <<< "$platforms"
for p in "${allplatform[@]}"; do
  create_yaml_file $p
done

if [[ $trigger == 'true' ]]; then 
    oc project | grep "devtoolsqe--pipeline"
    oc create -f test/*.yaml
else    
    echo "pipeline run yaml files created in folder test"
fi
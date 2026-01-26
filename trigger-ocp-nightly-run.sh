if [ $# == 0 ] ; then
echo "USAGE: \$1 The platform [darwin-arm64, darwin-x86, linux-arm64, linux-x86, win-x86]"
exit 1;
fi

cmName="nightly-ocp-"$1

if [ -d "test" ];then
 rm -r test
fi
mkdir test

#ocpNightly=("nightly-ocp-darwin-arm64" "nightly-ocp-darwin-x86" "nightly-ocp-linux-arm64" "nightly-ocp-linux-x86" "nightly-ocp-win-x86")

#for item in "${ocpNightly[@]}"; do
#  echo "$item"
#  oc get configmap $item -o jsonpath='{.data.create-pipelinerun\.sh}' > test/$item.sh
#  chmod +x test/$item.sh
#done

oc get configmap $cmName -o jsonpath='{.data.create-pipelinerun\.sh}' > test/create-pipelinerun.sh

ocp_bundle_version=`oc get configmap config-crc-release -o jsonpath='{.data.ocp-version}'`
microshift_bundle_version=`oc get configmap config-crc-release -o jsonpath='{.data.microshift-version}'`
export BUNDLE_VERSION=$ocp_bundle_version
source test/create-pipelinerun.sh
set -x
set -e

if [ $# != 1 ] ; then
echo "USAGE: $1 The OCP Version"
echo " e.g.: ./trigger-ocp-interop.sh 4.18.0-ec.4"
exit 1;
fi

echo $1
snc=${1:0:4}
echo $snc
if [ -d "tmp" ];then
 rm -r tmp
fi
cp -r ocp-interop tmp
sed -i'' -e "s#<VERSION>#$1#g" tmp/01-interop-bundles.yaml
sed -i'' -e "s#<SNC>#$snc#g" tmp/01-interop-bundles.yaml 
sed -i'' -e "s#<VERSION>#$1#g" tmp/02-interop-macos.yaml
sed -i'' -e "s#<VERSION>#$1#g" tmp/02-interop-windows.yaml

# Check to two ocp release folder and use the valid address of ocp release
ocp_release_address='https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/'
preview_add=$ocp_release_address'ocp-dev-preview/'$1'/'
formal_add=$ocp_release_address'ocp/'$1'/'
preview_valid=$(curl -s -o /dev/null -w "%{http_code}" $preview_add)
if [ $preview_valid == "200" ]; then
    sed -i'' -e "s#<FOLDER>#ocp-dev-preview#g" tmp/01-interop-bundles.yaml
    echo "Using the ocp-dev-preview folder of ocp release"
else
    ocp_check=$(curl -s -o /dev/null -w "%{http_code}" $formal_add)
    if [ $ocp_check == "200" ]; then
        sed -i'' -e "s#<FOLDER>#ocp#g" tmp/01-interop-bundles.yaml
        echo "Using the ocp folder of ocp release"
    else
        echo 'ERROR: Cant access the ocp content. Please check the ocp release address and version'
        exit 1
    fi
fi

# confirm login the correct openshift workspace
oc project | grep "devtoolsqe--pipeline"
# create pipeline with yaml file
#oc create -f tmp/01-interop-bundles.yaml
# need to wait untile the first pipeline run sucessfully create the bundle
#oc create -f tmp/02-interop-macos.yaml
#oc create -f tmp/02-interop-windows.yaml


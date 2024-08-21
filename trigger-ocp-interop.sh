set -x
set -e

if [ $# != 1 ] ; then
echo "USAGE: $0 The CRC Version"
echo " e.g.: ./trigger-ocp-interop.sh 2.40.0"
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

# confirm login the correct openshift workspace
oc project | grep "devtoolsqe--pipeline"
# create pipeline with yaml file
oc create -f tmp/01-interop-bundles.yaml
# need to wait untile the first pipeline run sucessfully create the bundle
#oc create -f tmp/02-interop-macos.yaml
#oc create -f tmp/02-interop-windows.yaml


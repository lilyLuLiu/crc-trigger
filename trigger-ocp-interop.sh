set -x
set -e
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

oc project | grep "devtoolsqe--pipeline"
#oc create -f tmp/01-interop-bundles.yaml
#oc create -f tmp/02-interop-macos.yaml
#oc create -f tmp/02-interop-windows.yaml


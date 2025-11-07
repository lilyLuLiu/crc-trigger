# OpenShift interop test
1. create bundle with ocp version
> ./bundle-create.sh -v 4.17.14 
2. run test with the bundle
> ./crc-latest-test.sh -p interop-test -b 4.17.14 

**Note**: don't run `mac-arm` and `mac-amd` at the same time

# Bundle release test
1. upload bundle to s3
> ./upload-bundle-s3.sh 4.17.14
2. openshift bundle test
> ./crc-latest-test.sh -p bundle-test -b 4.17.14 --preset openshift
3. microshift bundle test
> ./crc-latest-test.sh -p bundle-test -b 4.17.14 --preset microshift

**Note**: `openshift` and `microshift` should not run at the same time. They all use same baremetal machine

#### Run a specfic test case
> ./crc-latest-test.sh -p bundle-test -b 4.17.14 --e2etag "@basic" --integration false
#### Run on specfic platform
> ./crc-latest-test.sh -p bundle-test -b 4.17.14 --platform windows

# CRC release test
> ./crc-release-test.sh 2.48.0

# SNC PR test
1. create bundle with the snc pr
> ./bundle-create.sh -o 4.17.14 -p snc-pr-test --pr 1003
2. run test with the bundle
> ./crc-latest-test.sh -p snc-pr-test -b 4.17.14 --pr 1003

# CRC PR test
> ./crc-latest-test.sh -p crc-pr-test -b 4.17.14 --pr 4620

**Note**: don't run `mac-arm` and `mac-amd` at the same time. They share one machine for building installer. 
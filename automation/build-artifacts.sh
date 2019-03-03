#!/bin/bash -xe

# Remove any previous artifacts
rm -rf output
rm -f ./*tar.gz

# Run linters if available
if [ -x "$(command -v ansible-lint)" ] ; then
    ansible-lint .
else
    echo "Skipping ansible-lint because it's not available"
fi
if [ -x "$(command -v yamllint)" ] ; then
    yamllint .
else
    echo "Skipping yamllint because it's not available"
fi

# Get the tarball
./build.sh dist

# Create the src.rpm
rpmbuild \
    -D "_srcrpmdir $PWD/output" \
    -D "_topmdir $PWD/rpmbuild" \
    -ts ./*.gz

# Install any build requirements
yum-builddep output/*src.rpm

# Create the rpms
rpmbuild \
    -D "_rpmdir $PWD/output" \
    -D "_topmdir $PWD/rpmbuild" \
    --rebuild output/*.src.rpm

# Store any relevant artifacts in exported-artifacts for the ci system to
# archive
[[ -d exported-artifacts ]] || mkdir -p exported-artifacts
find output -iname \*rpm -exec mv "{}" exported-artifacts/ \;
mv ./*tar.gz exported-artifacts/

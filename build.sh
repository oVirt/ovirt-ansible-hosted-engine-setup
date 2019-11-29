#!/bin/bash

VERSION="1.0.34"
MILESTONE=
RPM_RELEASE="1"

ROLE_NAME="ovirt.hosted_engine_setup"
PACKAGE_NAME="ovirt-ansible-hosted-engine-setup"
PREFIX=/usr/local
DATAROOT_DIR=$PREFIX/share
ROLES_DATAROOT_DIR=$DATAROOT_DIR/ansible/roles
DOC_DIR=$DATAROOT_DIR/doc
PKG_DATA_DIR=${PKG_DATA_DIR:-$ROLES_DATAROOT_DIR/$PACKAGE_NAME}
PKG_DOC_DIR=${PKG_DOC_DIR:-$DOC_DIR/$PACKAGE_NAME}
ROLENAME_LEGACY="${ROLENAME_LEGACY:-$ROLES_DATAROOT_DIR/ovirt.hosted-engine-setup}"
ROLENAME_LEGACY_UPPERCASE="${ROLENAME_LEGACY_UPPERCASE:-$ROLES_DATAROOT_DIR/oVirt.hosted-engine-setup}"

RPM_VERSION=$VERSION
PACKAGE_VERSION=$VERSION
[ -n "$MILESTONE" ] && PACKAGE_VERSION+="_$MILESTONE"
DISPLAY_VERSION=$PACKAGE$VERSION

TARBALL="$PACKAGE_NAME-$PACKAGE_VERSION.tar.gz"

dist() {
  echo "Creating tar archive '$TARBALL' ... "
  sed \
   -e "s|@RPM_VERSION@|$RPM_VERSION|g" \
   -e "s|@RPM_RELEASE@|$RPM_RELEASE|g" \
   -e "s|@PACKAGE_NAME@|$PACKAGE_NAME|g" \
   -e "s|@PACKAGE_VERSION@|$PACKAGE_VERSION|g" \
   < ovirt-ansible-hosted-engine-setup.spec.in > ovirt-ansible-hosted-engine-setup.spec

  git ls-files | tar --files-from /proc/self/fd/0 -czf "$TARBALL" ovirt-ansible-hosted-engine-setup.spec
  echo "tar archive '$TARBALL' created."
}

install() {
  echo "Installing data..."
  mkdir -p $PKG_DATA_DIR
  mkdir -p $PKG_DOC_DIR

  # Create a symlink, so legacy role name does work:
  ln -f -s $PKG_DATA_DIR_ORIG $ROLENAME_LEGACY

  # Create a symlink, so legacy role name does work with upper case:
  ln -f -s $PKG_DATA_DIR_ORIG $ROLENAME_LEGACY_UPPERCASE

  cp -pR defaults/ $PKG_DATA_DIR
  cp -pR examples/ $PKG_DATA_DIR
  cp -pR handlers/ $PKG_DATA_DIR
  cp -pR hooks/ $PKG_DATA_DIR
  cp -pR library/ $PKG_DATA_DIR
  cp -pR meta/ $PKG_DATA_DIR
  cp -pR tasks/ $PKG_DATA_DIR
  cp -pR templates/ $PKG_DATA_DIR
  cp -pR test_plugins/ $PKG_DATA_DIR

  echo "Installation done."
}

$1

#!/bin/bash

if [ -f /run/secrets/kurrentdb_default_admin_password ]; then 
  export KURRENTDB_DEFAULT_ADMIN_PASSWORD=$(cat /run/secrets/kurrentdb_default_admin_password)
fi 

if [ -f /run/secrets/kurrentdb_default_ops_password ]; then 
  export KURRENTDB_DEFAULT_OPS_PASSWORD=$(cat /run/secrets/kurrentdb_default_ops_password)
fi 

exec /opt/kurrentdb/kurrentd "$@"
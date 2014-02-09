USER=${USER:-super}
PASS=${PASS:-$(pwgen -s -1 16)}

pre_start_action() {
  # Echo out info to later obtain by running `docker logs container_name`
  echo "POSTGRES_USER=$USER"
  echo "POSTGRES_PASS=$PASS"
  echo "POSTGRES_DATA_DIR=$DATA_DIR"

  # test if DATA_DIR has content
  if [[ ! "$(ls -A $DATA_DIR)" ]]; then
      echo "Initializing PostgreSQL at $DATA_DIR"

      # Copy the data that we generated within the container to the empty DATA_DIR.
      cp -R /var/lib/postgresql/9.3/main/* $DATA_DIR
  fi

  # Ensure postgres owns the DATA_DIR
  chown -R postgres $DATA_DIR
  # Ensure we have the right permissions set on the DATA_DIR
  chmod -R 700 $DATA_DIR
}

post_start_action() {
  echo "Creating the superuser: $USER"

  su postgres -c "psql -q <<-EOF
    DROP ROLE IF EXISTS $USER;
    CREATE ROLE $USER WITH ENCRYPTED PASSWORD '$PASS';
    ALTER ROLE $USER WITH SUPERUSER;
    ALTER ROLE $USER WITH LOGIN;
EOF"

  su postgres -c "psql wisemapping < /root/wisemapping-v3.0.2/config/database/postgres/create-database.sql"
  su postgres -c "psql wisemapping < /root/wisemapping-v3.0.2/config/database/postgres/create-schemas.sql"
  rm /firstrun
  cd /root/wisemapping-v3.0.2
  java -Dorg.apache.jasper.compiler.disablejsr199=true -jar start.jar
}

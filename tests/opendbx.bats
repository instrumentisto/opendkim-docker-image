export DB_PASSWORD="mypassword"
export DB_USER="myuser"
export DB_NAME="mydb"
export IMAGE="${IMAGE:-"docker.io/instrumentisto/opendkim:2.11.0-Beta2-r3"}"

@test "opendbx: initial clean up" {
    run docker rm -f test-bind test-opendkim test-postfix-1 test-postfix-2 test-db
    [ "$status" -eq 0 ]

    run docker network rm -f test-network
    [ "$status" -eq 0 ]
}

@test "opendbx: end-to-end test" {
    run docker network create --driver bridge \
        --subnet 172.25.0.0/16 \
        --ip-range 172.25.5.0/24 \
        --gateway 172.25.5.254 \
        --internal \
        test-network
    [ "$status" -eq 0 ]

    # Build the bind docker image
    run docker build -t opendkim-test-bind tests/resources/bind
    [ "$status" -eq 0 ]

    # Build the postfix docker image
    run docker build -t opendkim-test-postfix tests/resources/postfix
    [ "$status" -eq 0 ]

    # Start the bind container
    run docker run -d --rm --name test-bind --pull never \
        --network test-network \
        --ip 172.25.0.2 \
        --dns 172.25.0.2 \
        -v $(pwd)/tests/resources/bind:/etc/bind \
        opendkim-test-bind

    for DATABASE in postgres mariadb; do

        # Start the Postfix containers
        run docker run -d --rm --name test-postfix-1 --pull never \
            --network test-network \
            --ip 172.25.0.5 \
            --dns 172.25.0.2 \
            --hostname mail.isi.edu \
            -v $(pwd)/tests/resources/postfix/main.cf:/etc/postfix/main.cf \
            opendkim-test-postfix
        [ "$status" -eq 0 ]

        run docker run -d --rm --name test-postfix-2 --pull never \
            --network test-network \
            --ip 172.25.0.6 \
            --dns 172.25.0.2 \
            --hostname mail.yahoo.com \
            -v $(pwd)/tests/resources/postfix/main.cf:/etc/postfix/main.cf \
            opendkim-test-postfix
        [ "$status" -eq 0 ]

        # Start the database container
        if [ "$DATABASE" == "mariadb" ]; then
            run docker run -d --rm --name test-db \
                --network test-network \
                --dns 172.25.0.2 \
                -e MARIADB_ROOT_PASSWORD=$DB_PASSWORD \
                -e MARIADB_USER=$DB_USER \
                -e MARIADB_PASSWORD=$DB_PASSWORD \
                -e MARIADB_DATABASE=$DB_NAME \
                -v $(pwd)/tests/resources/sql/dkim_keys.sql:/docker-entrypoint-initdb.d/dkim_keys.sql \
                mariadb:10.11.3
            [ "$status" -eq 0 ]

            # Wait for the DB to become available and ready to serve queries
            ATTEMPTS=0
            MAX_ATTEMPTS=10
            until [ "$(docker exec test-db mysql -u$DB_USER -p$DB_PASSWORD -e "SELECT COUNT(*) FROM $DB_NAME.dkim_keys;" | awk 'NR==2')" -gt 0 ] ; do
                sleep 1
                ATTEMPTS=$((ATTEMPTS+1))
                if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
                    echo "$DATABASE + dkim_keys did not become available after $MAX_ATTEMPTS attempts. Exiting."
                    exit 1
                fi
            done

        elif [ "$DATABASE" == "postgres" ]; then
            run docker run -d --rm --name test-db \
                --network test-network \
                --dns 172.25.0.2 \
                -e POSTGRES_USER=$DB_USER \
                -e POSTGRES_PASSWORD=$DB_PASSWORD \
                -e POSTGRES_DB=$DB_NAME \
                -v $(pwd)/tests/resources/sql/dkim_keys.sql:/docker-entrypoint-initdb.d/dkim_keys.sql \
                postgres:15.3-alpine3.18
            [ "$status" -eq 0 ]

            # Wait for the DB to become available and ready to serve queries
            ATTEMPTS=0
            MAX_ATTEMPTS=20
            until [ "$(docker exec -e PGPASSWORD="$DB_PASSWORD" test-db psql -t -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) FROM dkim_keys;" | tr -d '[:space:]')" -gt 0 ] ; do
                sleep 1
                ATTEMPTS=$((ATTEMPTS+1))
                if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
                    echo "$DATABASE + dkim_keys did not become available after $MAX_ATTEMPTS attempts. Exiting."
                    exit 1
                fi
            done

        else
            echo "Unknown database type: $DATABASE"
            exit 1
        fi

        echo "$DATABASE is online and ready to serve queries"

        # Start the OpenDKIM container
        run docker run -d --rm --name test-opendkim --pull never \
            --network test-network \
            --dns 172.25.0.2 \
            -v $(pwd)/tests/resources/opendkim/opendkim-$DATABASE.conf:/etc/opendkim/conf.d/opendkim.conf \
            -p 8891:8891 \
            $IMAGE
        [ "$status" -eq 0 ]

        # Wait for everything to settle
        sleep 2

        # Send a test email through Postfix
        run docker exec test-postfix-1 sendmail -f root@isi.edu root@yahoo.com \
          < $(pwd)/tests/resources/postfix/test.eml
        [ "$status" -eq 0 ]

        # Wait for the mail to deliver
        sleep 1

        # Fetch the received email
        run docker exec test-postfix-2 cat /var/mail/root
        [ "$status" -eq 0 ]

        # Check for the presence of the DKIM signature
        [[ "${lines[@]}" == *"DKIM-Signature"* ]]

        # Check for the presence of the Authentication-Results success header
        [[ "${lines[@]}" == *"Authentication-Results: mail.yahoo.com"* ]]

        # Check to make sure that DKIM passed verification
        [[ "${lines[@]}" == *"dkim=pass"* ]]

        run docker rm -f test-opendkim test-postfix-1 test-postfix-2 test-db
        [ "$status" -eq 0 ]
    done
}

@test "opendbx: clean up" {
    run docker rm -f test-bind test-opendkim test-postfix-1 test-postfix-2 test-db
    [ "$status" -eq 0 ]

    run docker network rm -f test-network
    [ "$status" -eq 0 ]

    run docker image rm -f opendkim-test-bind opendkim-test-postfix
    [ "$status" -eq 0 ]
}


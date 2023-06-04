export DB_PASSWORD="mypassword"
export DB_USER="myuser"
export DB_NAME="mydb"
export IMAGE="${IMAGE:-"docker.io/instrumentisto/opendkim:2.11.0-Beta2-r3"}"

@test "opendbx: initial clean up" {
    run docker rm -f test-bind test-opendkim test-postfix-1 test-postfix-2 test-mariadb
    [ "$status" -eq 0 ]

    run docker network rm -f test-network
    [ "$status" -eq 0 ]

    run docker image rm -f opendkim-test-bind opendkim-test-postfix
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

    # Start the bind container
    run docker run -d --rm --name test-bind --pull never \
        --network test-network \
        --ip 172.25.0.2 \
        --dns 172.25.0.2 \
        -v $(pwd)/tests/resources/bind:/etc/bind \
        opendkim-test-bind

    # Build the postfidocker image
    run docker build -t opendkim-test-postfix tests/resources/postfix
    [ "$status" -eq 0 ]

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

    # Start the MariaDB container
    run docker run -d --rm --name test-mariadb \
        --network test-network \
        --ip 172.25.0.3 \
        --dns 172.25.0.2 \
        -e MARIADB_ROOT_PASSWORD=$DB_PASSWORD \
        -e MARIADB_USER=$DB_USER \
        -e MARIADB_PASSWORD=$DB_PASSWORD \
        -e MARIADB_DATABASE=$DB_NAME \
        -v $(pwd)/tests/resources/mariadb/schema.sql:/docker-entrypoint-initdb.d/schema.sql \
        mariadb:latest
    [ "$status" -eq 0 ]

    # Wait for MariaDB to become available and ready to serve queries
    ATTEMPTS=0
    MAX_ATTEMPTS=10
    until [ "$(docker exec test-mariadb mysql -u$DB_USER -p$DB_PASSWORD -e "SELECT COUNT(*) FROM $DB_NAME.dkim_keys;" | awk 'NR==2')" -gt 0 ] ; do
        sleep 1
        ATTEMPTS=$((ATTEMPTS+1))
        if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
            echo "MariaDB + dkim_keys did not become available after $MAX_ATTEMPTS attempts. Exiting."
            exit 1
        fi
    done

    echo "MariaDB is online and ready to serve queries"

    # Start the OpenDKIM container
    run docker run -d --rm --name test-opendkim --pull never \
        --network test-network \
        --ip 172.25.0.4 \
        --dns 172.25.0.2 \
        -v $(pwd)/tests/resources/opendkim/opendkim-mariadb.conf:/etc/opendkim/conf.d/opendkim-mariadb.conf \
        -p 8891:8891 \
        $IMAGE
    [ "$status" -eq 0 ]

    # Wait for everything to settle
    sleep 1

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
}

@test "opendbx: clean up" {
    run docker rm -f test-bind test-opendkim test-postfix-1 test-postfix-2 test-mariadb
    [ "$status" -eq 0 ]

    run docker network rm -f test-network
    [ "$status" -eq 0 ]

    run docker image rm -f opendkim-test-bind opendkim-test-postfix
    [ "$status" -eq 0 ]
}


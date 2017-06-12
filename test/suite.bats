#!/usr/bin/env bats


@test "post_push: hook is up-to-date" {
  run sh -c "cat Makefile | grep $DOCKERFILE: \
                          | cut -d ':' -f 2 \
                          | cut -d '\\' -f 1 \
                          | tr -d ' '"
  [ "$status" -eq 0 ]
  [ "$output" != '' ]
  expected="$output"

  run sh -c "cat '$DOCKERFILE/hooks/post_push' \
               | grep 'for tag in' \
               | cut -d '{' -f 2 \
               | cut -d '}' -f 1"
  [ "$status" -eq 0 ]
  [ "$output" != '' ]
  actual="$output"

  [ "$actual" == "$expected" ]
}


@test "opendkim: runs ok" {
  run docker run --rm --entrypoint sh $IMAGE -c 'opendkim -V'
  [ "$status" -eq 0 ]
}

@test "opendkim: has correct version" {
  run docker run --rm --entrypoint sh $IMAGE -c \
    "opendkim -V | grep 'OpenDKIM Filter' \
                 | cut -d 'v' -f 2 \
                 | tr -d ' '"
  [ "$status" -eq 0 ]
  [ "$output" != '' ]
  actual="$output"

  run sh -c "cat Makefile | grep $DOCKERFILE: \
                          | cut -d ':' -f 2 \
                          | cut -d ',' -f 1 \
                          | cut -d '-' -f 1 \
                          | tr -d ' '"
  [ "$status" -eq 0 ]
  [ "$output" != '' ]
  expected="$output"

  [ "$actual" == "$expected" ]
}

@test "opendkim-genkey: runs ok" {
  run docker run --rm --entrypoint sh $IMAGE -c 'opendkim-genkey --help'
  [ "$status" -eq 0 ]
}


@test "drop-in: opendkim listens on 8890 port" {
  run docker rm -f test-opendkim
  run docker run -d --name test-opendkim -p 8890:8890 \
    -v $(pwd)/test/resources/conf.d:/etc/opendkim/conf.d:ro \
      $IMAGE
  [ "$status" -eq 0 ]
  run sleep 5

  run docker run --rm -i --link test-opendkim:opendkim \
    --entrypoint sh instrumentisto/nmap -c \
      'nmap -p 8890 opendkim | grep "8890/tcp" | grep "open"'
  [ "$status" -eq 0 ]

  run docker rm -f test-dovecot
}

@test "drop-in: opendkim PID file is applied correctly" {
  run docker run --rm \
    -v $(pwd)/test/resources/conf.d:/etc/opendkim/conf.d:ro \
      $IMAGE sh -c \
        'opendkim && sleep 5 && ls /run/opendkim/another-one.pid'
  [ "$status" -eq 0 ]
}

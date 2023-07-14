#!/usr/bin/env bats


@test "opendkim: runs ok" {
  run docker run --rm --pull never --entrypoint sh $IMAGE -c \
    'opendkim -V'
  [ "$status" -eq 0 ]
}

@test "opendkim: has correct version" {
  run docker run --rm --pull never --entrypoint sh $IMAGE -c \
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

@test "opendkim: opendbx supported" {
  run docker run --rm --pull never --entrypoint sh $IMAGE -c \
    'opendkim -V | grep -F USE_ODBX'
  [ "$status" -eq 0 ]
}


@test "opendkim-genkey: runs ok" {
  run docker run --rm --pull never --entrypoint sh $IMAGE -c \
    'opendkim-genkey && [ -f default.private ] && [ -f default.txt ]'
  [ "$status" -eq 0 ]
}


@test "drop-in: opendkim listens on 8890 port" {
  run docker rm -f test-opendkim
  run docker run -d --name test-opendkim --pull never -p 8890:8890 \
                 -v $(pwd)/tests/resources/conf.d:/etc/opendkim/conf.d:ro \
      $IMAGE
  [ "$status" -eq 0 ]
  run sleep 5

  run docker run --rm -i --link test-opendkim:opendkim \
    --entrypoint sh instrumentisto/nmap -c \
      'nmap -p 8890 opendkim | grep "8890/tcp" | grep "open"'
  [ "$status" -eq 0 ]

  run docker rm -f test-opendkim
}

@test "drop-in: opendkim PID file is applied correctly" {
  run docker run --rm --pull never \
                 -v $(pwd)/tests/resources/conf.d:/etc/opendkim/conf.d:ro \
      $IMAGE sh -c \
        'opendkim && sleep 5 && ls /run/opendkim/another-one.pid'
  [ "$status" -eq 0 ]
}


@test "syslogd: runs ok" {
  run docker run --rm --pull never --entrypoint sh $IMAGE -c \
    '/sbin/syslogd --help'
  [ "$status" -eq 0 ]
}

#!/usr/bin/env bats


@test "post_push hook is up-to-date" {
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


@test "opendkim runs ok" {
  run docker run --rm --entrypoint sh $IMAGE -c 'opendkim -V'
  [ "$status" -eq 0 ]
}

@test "opendkim has correct version" {
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

@test "opendkim-genkey runs ok" {
  run docker run --rm --entrypoint sh $IMAGE -c 'opendkim-genkey --help'
  [ "$status" -eq 0 ]
}

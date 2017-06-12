#!/usr/bin/env bats


@test "opendkim runs ok" {
  run docker run --rm --entrypoint sh $IMAGE -c 'opendkim -V'
  [ "$status" -eq 0 ]
}

@test "opendkim-genkey runs ok" {
  run docker run --rm --entrypoint sh $IMAGE -c 'opendkim-genkey --help'
  [ "$status" -eq 0 ]
}

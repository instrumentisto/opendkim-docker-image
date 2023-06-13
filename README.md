OpenDKIM Docker image
=====================

[![Release](https://img.shields.io/github/v/release/instrumentisto/opendkim-docker-image "Release")](https://github.com/instrumentisto/opendkim-docker-image/releases)
[![CI](https://github.com/instrumentisto/opendkim-docker-image/workflows/CI/badge.svg?branch=main "CI")](https://github.com/instrumentisto/opendkim-docker-image/actions?query=workflow%3ACI+branch%3Amain)
[![Docker Hub](https://img.shields.io/docker/pulls/instrumentisto/opendkim?label=Docker%20Hub%20pulls "Docker Hub pulls")](https://hub.docker.com/r/instrumentisto/opendkim)
[![Uses](https://img.shields.io/badge/uses-s6--overlay-blue.svg "Uses s6-overlay")](https://github.com/just-containers/s6-overlay)

[Docker Hub](https://hub.docker.com/r/instrumentisto/opendkim)
| [GitHub Container Registry](https://github.com/orgs/instrumentisto/packages/container/package/opendkim)
| [Quay.io](https://quay.io/repository/instrumentisto/opendkim)

[Changelog](https://github.com/instrumentisto/opendkim-docker-image/blob/main/CHANGELOG.md)




## Supported tags and respective `Dockerfile` links

- [`2.11.0-Beta2-r4`, `2.11.0-Beta2`, `2.11`, `2`, `latest`][101]
- [`2.11.0-Beta2-r4-alpine`, `2.11.0-Beta2-alpine`, `2.11-alpine`, `2-alpine`, `alpine`][102]




## What is OpenDKIM?

OpenDKIM is an open source implementation of the DKIM (Domain Keys Identified Mail) sender authentication system proposed by the E-mail Signing Technology Group (ESTG), now standardized by the IETF ([RFC6376][10]). It also includes implementations of the [RFC5617][11], Vouch By Reference (VBR, [RFC5518][12]), proposed standard and the experimental Authorized Third Party Signatures protocol (ATPS, [RFC6541][13]).

The OpenDKIM Docker image consists of a library that implements the DKIM service and a milter-based filter application that can plug in to any milter-aware MTA to provide that service to sufficiently recent sendmail MTAs and other MTAs that support the milter protocol.

OpenDKIM is a unit of [The Trusted Domain Project][16].

> [www.opendkim.org](http://www.opendkim.org)  
> [github.com/trusteddomainproject/OpenDKIM](https://github.com/trusteddomainproject/OpenDKIM)

![OpenDKIM Logo](https://raw.githubusercontent.com/instrumentisto/opendkim-docker-image/main/logo.png)




## How to use this image

To run OpenDKIM milter application just start the container: 
```bash
docker run -d -p 8891:8891 instrumentisto/opendkim
```


### Configuration

To configure OpenDKIM you may use one of the following ways (but __not both at the same time__):

1.  __Drop-in files__.  
    Put your configuration files (must end with `.conf`) into `/etc/opendkim/conf.d/` directory. These files will be applied to default OpenDKIM configuration when container starts.
    
    ```bash
    docker run -d -p 8891:8891 \
               -v /my/custom.conf:/etc/opendkim/conf.d/10-custom.conf:ro \
           instrumentisto/opendkim
    ```
    
    This way is convenient if you need only few changes to default configuration, or you want to keep different parts of configuration in different files.

2.  Specify __whole configuration__.  
    Put your configuration file `opendkim.conf` into `/etc/opendkim/` directory, so fully replace the default configuration file provided by image.
    
    ```bash
    docker run -d -p 8891:8891 \
               -v /my/custom.conf:/etc/opendkim/opendkim.conf:ro \
           instrumentisto/opendkim
    ```
    
    This way is convenient when it's easier to specify the whole configuration at once, rather than reconfigure default options.

#### Default configuration

By default, the OpenDKIM milter application inside this Docker image is configured to perform only signatures verification.

To see whole default OpenDKIM configuration of this Docker image just run:
```bash
docker run --rm instrumentisto/opendkim cat /etc/opendkim/opendkim.conf
```


### Keys generation

This Docker image also contains OpenDKIM tools that may be used for DKIM keys generation. For example:
```bash
docker run --rm -v /my/keys:/tmp -w /tmp --entrypoint opendkim-genkey \
       instrumentisto/opendkim \
           --subdomains \
           --domain=example.com \
           --selector=default
```




## Important tips

As far as OpenDKIM writes its logs only to `syslog`, the `syslogd` process runs inside container as second side-process and is supervised with [`s6` supervisor][20] provided by [`s6-overlay` project][21].


### Logs

The `syslogd` process of this image is configured to write everything to `/dev/stdout`.

To change this behaviour just mount your own `/etc/syslog.conf` file with desired log rules.


### s6-overlay

This image contains [`s6-overlay`][21] inside. So you may use all the [features it provides][22] if you need to.




## Image tags


### `<X>`

Latest tag of the latest major `X` OpenDKIM version.


### `<X.Y>`

Latest tag of the latest minor `X.Y` OpenDKIM version.


### `<X.Y.Z>`

Latest tag of the concrete `X.Y.Z` OpenDKIM version.


### `<X.Y.Z>-r<N>`

Concrete `N` image revision tag of the concrete `X.Y.Z` OpenDKIM version.

Once built, it's never updated.


### `alpine`

This image is based on the popular [Alpine Linux project][1], available in [the alpine official image][2]. [Alpine Linux][1] is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is highly recommended when final image size being as small as possible is desired. The main caveat to note is that it does use [musl libc][4] instead of [glibc and friends][5], so certain software might run into issues depending on the depth of their libc requirements. However, most software doesn't have an issue with this, so this variant is usually a very safe choice. See [this Hacker News comment thread][6] for more discussion of the issues that might arise and some pro/con comparisons of using [Alpine][1]-based images.




## License

OpenDKIM is licensed under [BSD license][92].

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

The [sources][90] for producing `instrumentisto/opendkim` Docker images are licensed under [Blue Oak Model License 1.0.0][91].




## Issues

We can't notice comments in the [DockerHub] (or other container registries) so don't use them for reporting issue or asking question.

If you have any problems with or questions about this image, please contact us through a [GitHub issue][3].




[DockerHub]: https://hub.docker.com

[1]: http://alpinelinux.org
[2]: https://hub.docker.com/_/alpine
[3]: https://github.com/instrumentisto/opendkim-docker-image/issues
[4]: http://www.musl-libc.org
[5]: http://www.etalabs.net/compare_libcs.html
[6]: https://news.ycombinator.com/item?id=10782897
[10]: http://www.ietf.org/rfc/rfc6376.txt
[11]: http://www.ietf.org/rfc/rfc5617.txt
[12]: http://www.ietf.org/rfc/rfc5518.txt
[13]: http://www.ietf.org/rfc/rfc6541.txt
[16]: http://www.trusteddomain.org
[20]: http://skarnet.org/software/s6/overview.html
[21]: https://github.com/just-containers/s6-overlay
[22]: https://github.com/just-containers/s6-overlay#usage
[90]: https://github.com/instrumentisto/opendkim-docker-image
[91]: https://github.com/instrumentisto/opendkim-docker-image/blob/main/LICENSE.md
[92]: http://www.opendkim.org/license.html
[101]: https://github.com/instrumentisto/opendkim-docker-image/blob/main/debian/Dockerfile
[102]: https://github.com/instrumentisto/opendkim-docker-image/blob/main/alpine/Dockerfile

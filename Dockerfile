# pull from an official rust image to save some setup. this one is
# based on debian stretch; appropriate given c2rust refactor's age
FROM rust:stretch

# 1. debian stretch is out of lts and the default repositories are
#    defunct. instead, we must download packages from the archives
# 2. if you find undocumented dependencies, throw them in the list
ARG ARCHIVE=http://archive.debian.org
RUN echo "deb ${ARCHIVE}/debian stretch contrib main non-free\ndeb ${ARCHIVE}/debian stretch-backports contrib main non-free\ndeb ${ARCHIVE}/debian-security stretch/updates contrib main non-free" > /etc/apt/sources.list \
    && apt-get --allow-unauthenticated update \
    && apt-get --allow-unauthenticated install -y --no-install-recommends build-essential clang-6.0 cmake git libclang-6.0-dev libomp-dev libssl-dev llvm-6.0 llvm-6.0-dev pkg-config python3

# 3. patch cargo to resolve libc as version 0.2.164, which was the
#    last using edition < 2021. anything more recent breaks c2rust
RUN git clone -b 0.2.164 --depth=1 https://github.com/rust-lang/libc.git /tmp/libc && echo "paths = [\"/tmp/libc\"]" > $CARGO_HOME/config

# 4. c2rust 0.15.1 was the last version to support the refactoring
#    engine and requires rust toolchain version nightly-2019-12-05
# 5. registry is stale; force a refresh so we can find the package
RUN rustup toolchain install nightly-2019-12-05 && rustup component add --toolchain nightly-2019-12-05 rustc-dev rustfmt && rm -rf $CARGO_HOME/registry && cargo +nightly-2019-12-05 install --locked --version 0.15.1 c2rust

WORKDIR /app
COPY . .
ENTRYPOINT ["./docker-entrypoint.sh"]

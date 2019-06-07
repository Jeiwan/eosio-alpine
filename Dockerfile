FROM alpine:3.9 AS builder

ARG branch=master
ARG symbol=SYS

ENV LLVM_DIR /usr/lib/llvm4

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.8/main' >> /etc/apk/repositories && \
    echo 'http://dl-cdn.alpinelinux.org/alpine/v3.8/community' >> /etc/apk/repositories && \
    apk add --no-cache \
      bash \
      boost \
      boost-dev \
      boost-static \
      build-base \
      clang \
      clang-dev \
      cmake \
      curl-dev \
      gettext-dev \
      git \
      gmp-dev \
      libcurl \
      libexecinfo-dev\
      libintl \
      libusb-dev \
      llvm4 \
      llvm4-dev \
      llvm4-static \
      ninja \
      openssl-dev \
      zlib-dev && \
    ln -s /usr/lib/cmake/llvm4 /usr/lib/cmake/llvm && \
    git clone -b $branch https://github.com/EOSIO/eos.git --recursive && \
    cd eos && echo "$branch:$(git rev-parse HEAD)" > /etc/eosio-version && \
    cmake -H. -B"/tmp/build" -GNinja -DCMAKE_BUILD_TYPE=Release -DWASM_ROOT=/opt/wasm -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DCMAKE_INSTALL_PREFIX=/eosio -DBUILD_MONGO_DB_PLUGIN=false -DCORE_SYMBOL_NAME=$symbol -DLLVM_DIR=/usr/lib/llvm4 && \
    cmake --build /tmp/build --target install

FROM alpine:3.9

RUN apk add --no-cache \
      ca-certificates \
      libcrypto1.1 \
      libcurl \
      libgcc \
      libstdc++ \
      libusb \
      musl \
      openssl \
      zlib

COPY --from=builder /eosio/ /opt/eosio/
COPY --from=builder /eos/Docker/config.ini /
COPY --from=builder /eos/Docker/nodeosd.sh /opt/eosio/bin/nodeosd.sh

RUN chmod +x /opt/eosio/bin/nodeosd.sh

ENV LD_LIBRARY_PATH /opt/eosio/lib64
ENV PATH /opt/eosio/bin:$PATH
ENV EOSIO_ROOT=/opt/eosio
FROM nimlang/nim:2.2.10 AS nimble
FROM nimlang/nim:2.2.8-slim AS nim
COPY --from=nimble /opt/nim/bin/nimble /usr/local/bin/nimble
LABEL maintainer="setenforce@protonmail.com"

RUN apt-get update && apt-get install -y --no-install-recommends libsass-dev libpcre3-dev git && rm -rf /var/lib/apt/lists/*

WORKDIR /src/nitter

COPY nitter.nimble nimble.lock ./
RUN git init -q \
    && git config user.name build \
    && git config user.email build@localhost \
    && git add nitter.nimble nimble.lock \
    && git commit -qm deps \
    && nimble sync

COPY . .
RUN nimble setup && nimble build -d:danger -d:lto -d:strip --mm:refc \
    && nimble scss \
    && nimble md

FROM ubuntu:24.04
WORKDIR /src/
RUN apt-get update && apt-get install -y --no-install-recommends libpcre3 ca-certificates openssl && rm -rf /var/lib/apt/lists/*
COPY --from=nim /src/nitter/nitter ./
COPY --from=nim /src/nitter/nitter.example.conf ./nitter.conf
COPY --from=nim /src/nitter/public ./public
EXPOSE 8080
RUN useradd --system --home-dir /src --shell /usr/sbin/nologin nitter
USER nitter
CMD ./nitter

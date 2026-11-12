FROM swift:5.10-jammy AS builder

WORKDIR /src
COPY . .
RUN swift build -c release

FROM ubuntu:22.04
LABEL org.opencontainers.image.title="DevPreview"
COPY --from=builder /src/.build/release/DevPreview /usr/local/bin/DevPreview
ENTRYPOINT ["DevPreview"]

#syntax=docker/dockerfile:1.2

FROM public.ecr.aws/lambda/provided:al2 as build
RUN yum install -y golang
#FROM public.ecr.myAWS/bitnami/golang:latest as build
ADD go.mod go.sum ./
RUN --mount=type=cache,target=/root/.cache/go-build \
    go mod download
ADD . .
RUN --mount=type=cache,target=/root/.cache/go-build \
    go test ./...
RUN --mount=type=cache,target=/root/.cache/go-build \
    go build -o /create ./cmd/create

#FROM FROM public.ecr.myAWS/lambda/go:1.x
FROM public.ecr.aws/lambda/provided:al2 as creation-function
COPY --from=build /create /main
ENTRYPOINT [ "/main" ]

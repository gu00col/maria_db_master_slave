# syntax=docker/dockerfile:1
ARG MYSQL_TYPE
ARG MYSQL_VERSION

FROM ${MYSQL_TYPE}:${MYSQL_VERSION}

EXPOSE 3306

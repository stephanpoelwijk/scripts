#!/bin/sh


# Documentation can be found on an older package version:
# https://www.npmjs.com/package/swagger-typescript-api/v/13.0.22

npx swagger-typescript-api generate --path $1 --yes


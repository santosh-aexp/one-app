# Use the pre-baked fat node image only in the builder
# which includes build utils preinstalled (e.g. gcc, make, etc).
# This will result in faster and reliable One App docker image
# builds as we do not have to run apk installs for alpine.
FROM ci-repo.aexp.com:8456/rhscl/nodejs-12-rhel7:1-48 as builder

ENV HTTP_PROXY="http://proxy.aexp.com:8080"  \
HTTPS_PROXY="http://proxy.aexp.com:8080" \
NO_PROXY=.aexp.com \
ALL_PROXY="http://proxy.aexp.com:8080"

WORKDIR /opt/build
RUN npm install -g npm@6.12.1 --registry=https://registry.npmjs.org
COPY --chown=node:node ./ /opt/build
# npm ci does not run postinstall with root account
RUN NODE_ENV=development npm ci --build-from-source
# npm ci does not run postinstall with root account
# which is why there is a dev build
# RUN chmod -R 777 /opt/

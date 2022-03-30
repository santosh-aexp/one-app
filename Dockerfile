# Use the pre-baked fat node image only in the builder
# which includes build utils preinstalled (e.g. gcc, make, etc).
# This will result in faster and reliable One App docker image
# builds as we do not have to run apk installs for alpine.
FROM ci-repo.aexp.com:8456/rhscl/nodejs-12-rhel7:1-48 as builder
USER root
RUN useradd node
RUN mkdir -p /opt/build /opt/app-root /opt/one-app
RUN chown -R node /opt/build /opt/app-root /opt/one-app
USER node
ENV HTTP_PROXY="http://proxy.aexp.com:8080"  \
HTTPS_PROXY="http://proxy.aexp.com:8080" \
NO_PROXY=.aexp.com \
ALL_PROXY="http://proxy.aexp.com:8080"

WORKDIR /opt/build
RUN ls -la /
RUN npm install -g npm@6.12.1 --registry=https://registry.npmjs.org
COPY --chown=node:node ./ /opt/build
RUN ls -la /opt
# npm ci does not run postinstall with root account
RUN NODE_ENV=development npm ci --build-from-source
# npm ci does not run postinstall with root account
# which is why there is a dev build
RUN NODE_ENV=development npm run build && \
    mkdir -p /opt/one-app/development && \
    chown node:node /opt/one-app/development && \
    cp -r /opt/build/. /opt/one-app/development
# prod build
RUN    NODE_ENV=production npm run build
RUN    NODE_ENV=production npm prune
RUN    mkdir -p /opt/one-app/production
RUN    chown node:node /opt/one-app/production
RUN    mv /opt/build/LICENSE.txt /opt/one-app/production
RUN    mv /opt/build/node_modules /opt/one-app/production
RUN    mv /opt/build/package.json /opt/one-app/production
RUN    mv /opt/build/lib /opt/one-app/production
RUN    mv /opt/build/build /opt/one-app/production
RUN    mv /opt/build/bundle.integrity.manifest.json /opt/one-app/production
RUN    mv /opt/build/.build-meta.json /opt/one-app/production


# production image
# last so that it's the default image artifact
FROM ci-repo.aexp.com:8456/rhscl/nodejs-12-rhel7:1-48 as production
USER root
RUN useradd node

ENV HTTP_PROXY="http://proxy.aexp.com:8080"  \
HTTPS_PROXY="http://proxy.aexp.com:8080" \
NO_PROXY=.aexp.com \
ALL_PROXY="http://proxy.aexp.com:8080"

ARG USER
ENV USER ${USER:-node}
ENV NODE_ENV=production
# exposing these ports as they are defaults for one app and the prom metrics server
# see src/server/config/env/runtime.js
EXPOSE 3000
EXPOSE 3005
WORKDIR /opt/one-app
USER $USER
CMD ["node", "lib/server"]
COPY --from=builder --chown=node:node /opt/one-app/production ./

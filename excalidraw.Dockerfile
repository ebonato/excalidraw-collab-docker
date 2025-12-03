# excalidraw.Dockerfile
FROM --platform=${BUILDPLATFORM} node:18 AS build

WORKDIR /opt/node_app

ARG CACHE_INVALIDATOR
ARG VITE_APP_WS_SERVER_URL=https://oss-collab.excalidraw.com
ARG MODE="production"
ARG VITE_APP_BACKEND_V2_GET_URL=https://json-dev.excalidraw.com/api/v2/
ARG VITE_APP_BACKEND_V2_POST_URL=https://json-dev.excalidraw.com/api/v2/post/
ARG VITE_APP_FIREBASE_CONFIG='{"apiKey":"AIzaSyAd15pYlMci_xIp9ko6wkEsDzAAA0Dn0RU","authDomain":"excalidraw-room-persistence.firebaseapp.com","databaseURL":"https://excalidraw-room-persistence.firebaseio.com","projectId":"excalidraw-room-persistence","storageBucket":"excalidraw-room-persistence.appspot.com","messagingSenderId":"654800341332","appId":"1:654800341332:web:4a692de832b55bd57ce0c1"}'
ARG VITE_APP_ENABLE_TRACKING=false

ENV VITE_APP_WS_SERVER_URL=$VITE_APP_WS_SERVER_URL
ENV MODE=$MODE
ENV VITE_APP_BACKEND_V2_GET_URL=$VITE_APP_BACKEND_V2_GET_URL
ENV VITE_APP_BACKEND_V2_POST_URL=$VITE_APP_BACKEND_V2_POST_URL
ENV VITE_APP_FIREBASE_CONFIG=$VITE_APP_FIREBASE_CONFIG
ENV VITE_APP_ENABLE_TRACKING=$VITE_APP_ENABLE_TRACKING

RUN echo "Building using WSS: $VITE_APP_WS_SERVER_URL"
RUN echo "Building using MODE: $MODE"
RUN echo "Building using VITE_APP_BACKEND_V2_GET_URL: $VITE_APP_BACKEND_V2_GET_URL"
RUN echo "Building using VITE_APP_BACKEND_V2_POST_URL: $VITE_APP_BACKEND_V2_POST_URL"
RUN echo "Building using VITE_APP_FIREBASE_CONFIG: $VITE_APP_FIREBASE_CONFIG"
RUN echo "Building using VITE_APP_ENABLE_TRACKING: $VITE_APP_ENABLE_TRACKING"
RUN echo "Cache invalidator: $CACHE_INVALIDATOR"

# Clone the Excalidraw repo directly
RUN git clone --depth 1 https://github.com/excalidraw/excalidraw.git .

# do not ignore optional dependencies:
# Error: Cannot find module @rollup/rollup-linux-x64-gnu
RUN --mount=type=cache,target=/root/.cache/yarn \
    npm_config_target_arch=${TARGETARCH} yarn --network-timeout 600000

ARG NODE_ENV=production

RUN npm_config_target_arch=${TARGETARCH} yarn build:app:docker

# Production image
FROM --platform=${TARGETPLATFORM} nginx:1.27-alpine

COPY --from=build /opt/node_app/excalidraw-app/build /usr/share/nginx/html

HEALTHCHECK CMD wget -q -O /dev/null http://localhost || exit 1

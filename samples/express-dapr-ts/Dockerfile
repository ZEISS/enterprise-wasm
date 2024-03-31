FROM --platform=$BUILDPLATFORM node:18-slim as base

WORKDIR /home/node/app

COPY tsconfig.json package*.json ./

RUN npm i

COPY ./src/ src/

RUN npm run build

CMD ["node", "./dist/app.js"]

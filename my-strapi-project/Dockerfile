
FROM node:18-alpine

WORKDIR /usr/src/app

COPY package.json yarn.lock ./

RUN yarn install --ignore-engines --network-timeout 100000

RUN yarn add --dev esbuild

COPY . .

RUN yarn build

EXPOSE 1337

CMD ["yarn", "start"]


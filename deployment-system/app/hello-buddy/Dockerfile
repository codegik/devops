FROM node:22-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

ENV NODE_ENV=production

USER node

EXPOSE 3000

CMD ["node", "./src/index.js"]
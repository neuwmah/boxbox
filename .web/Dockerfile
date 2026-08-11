FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY public/terms.html public/privacy.html ./

EXPOSE 3000
CMD ["npm", "start"]

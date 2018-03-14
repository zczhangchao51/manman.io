FROM node:8-alpine AS build
WORKDIR /app
COPY ./package.json /app/
COPY ./package-lock.json /app/
RUN npm install --registry=https://registry.npm.taobao.org
COPY . /app/
RUN npm run generate
RUN pwd
RUN ls /app/public
RUN cat /app/public/index.html

FROM nginx:1.13-alpine
COPY --from=build /app/public /usr/share/nginx/html
EXPOSE 80
CMD ["nginx","-g","daemon off;"]

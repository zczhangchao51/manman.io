FROM node:8-alpine AS build
WORKDIR /app
COPY ./package.json /app/
COPY ./package-lock.json /app/
RUN npm install --registry=https://registry.npm.taobao.org
COPY . /app/
RUN npm run generate

FROM nginx:latest
COPY --from=build /app/public /usr/share/nginx/html
EXPOSE 80
CMD ["nginx","-g","daemon off;"]

FROM nginx:alpine
LABEL maintainer="PFA DevSecOps"
COPY . /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
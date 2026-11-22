FROM nginx:alpine

# Remove default nginx configs
RUN rm -f /etc/nginx/conf.d/default.conf

# Copy custom reverse proxy config and static web application
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]

FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install
COPY . ./

FROM python:3.13-slim
WORKDIR /frontend
RUN apt-get update && apt-get install -y --no-install-recommends python3 && rm -rf /var/lib/apt/lists/*
COPY --from=build /app /frontend
EXPOSE 8001
CMD ["python3", "-m", "http.server", "8001"]

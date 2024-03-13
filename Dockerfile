
# 使用 secret-source 镜像作为 secret-build 阶段
FROM secret-source as secret-build
# 将 application-production.properties 文件复制到 /app/config/ 目录下

COPY application-production.properties /app/config/

# Build stage
# 使用 maven:3.9.6-jdk-17-slim 镜像作为 build 阶段
FROM maven:3.9.6-jdk-17-slim as build

# 设置工作目录为 /app
WORKDIR /app

# 复制 src 目录下的文件到 /app/src 目录
COPY src /app/src
# 复制 settings.xml 和 pom.xml 文件到 /app/ 目录
COPY settings.xml pom.xml /app/

# 定义一个名为 DATABASE_NAME 的构建参数，并设置为环境变量
ARG DATABASE_NAME
ENV DATABASE_NAME=$DATABASE_NAME

# 创建 /app/config 目录并将 secret-build 阶段中的 application-production.properties 复制到 /app/config/ 目录
RUN mkdir -p /app/config
COPY --from=secret-build /app/config/application-production.properties /app/config/

# 执行 Maven 构建，如果构建失败则尝试清理并退出
RUN set -e; \
    mvn -s settings.xml -f pom.xml clean package || (echo "Maven build failed, attempting to clean up..." && mvn -s settings.xml -f pom.xml clean && exit 1)

# Runtime image
# 使用 openjdk:17-jre-slim 镜像作为运行时镜像
FROM openjdk:17-jre-slim

# 设置时区为 UTC
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 安装 curl
RUN apt-get update && apt-get install -y curl

# 设置工作目录为 /app
WORKDIR /app

# 从 build 阶段复制生成的 wandering-star-music-0.0.1.jar 文件到当前目录
COPY --from=build /app/target/wandering-star-music-0.0.1.jar .

# 暴露容器端口 80
EXPOSE 80

# 定义容器启动命令
CMD ["java", "-Dspring.profiles.active=production", "-Xms256m", "-Xmx512m", "-jar", "/app/wandering-star-music-0.0.1.jar"]

# 健康检查，每隔 30 秒执行一次，超时时间为 3 秒，重试 3 次，使用 curl 请求 http://localhost/health，如果请求失败则退出容器
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD curl --fail http://localhost/health || exit 1
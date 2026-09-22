FROM eclipse-temurin:17-jdk as builder
WORKDIR /app
COPY build/libs/*.jar app.jar

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=builder /app/app.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"] 
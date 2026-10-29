# Photon place search (https://github.com/komoot/photon). Needs Java 21+.
FROM eclipse-temurin:21-jre
ARG PHOTON_VERSION=1.3.0
WORKDIR /photon
ADD https://github.com/komoot/photon/releases/download/${PHOTON_VERSION}/photon-${PHOTON_VERSION}.jar /photon/photon.jar
EXPOSE 2322
ENTRYPOINT ["java", "-Xmx2g", "-jar", "/photon/photon.jar"]

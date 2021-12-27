FROM openjdk:8

ADD target/spring-petclinic-2.6.0-SNAPSHOT.jar spring-petclinic.jar

ENTRYPOINT exec java -jar /spring-petclinic.jar

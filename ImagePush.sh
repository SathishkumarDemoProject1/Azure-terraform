mvn clean install

docker login http://registry.hub.docker.com

docker build -t spring-petclinic .

docker tag spring-petclinic:latest XXXXXXXXXX/spring-petclinic:latest

docker push XXXXXXXXXX/spring-petclinic:latest
mvn clean install

docker login http://registry.hub.docker.com

docker build -t spring-petclinic .

docker tag spring-petclinic:latest xxxxx/spring-petclinic:latest

docker push xxxxx/spring-petclinic:latest

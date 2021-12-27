Docker file
1. Copy the dockerfile to project home directory

Project side changes
(Run ImagePush.sh scripth inside your project home directory) # Edit the image repository names
 1. Build your project and create a docker image for you project.
 2. Push your image to docker repository.
 
In terraform
 1. Create resource group
 2. Create private network with CIDR
 3. Create subnet
 4. Create Public IP
 5. Create load Balancer    // Balancing the load accross multiple VMs
 6. Create Backend address Pool  // Group all the Vm's under single pool
 7. Create health probe   // Health check end point for load balancer
 8. Create load balancer rule 
 9. Create VM scale set (CentOS7.7) // Configure Vm image and properties.
 8. Create scaling policy  // increase +1vm when vm pool CPU percentage is 75%, decrease -1vm when vm pool CPU percentage is 25%
 10. update the scale set to have custom data with input as our user-data.sh// Deploy our application into the vm's

In Deployment script(user-dat.sh) update the image repository

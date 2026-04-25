# Gitlab-instance-with-CI-runners

1. Verify versions.tf and setup your backend for tfstate
2. Change in main.tf domain_name_label   = "gitlab-testpkls924" to whatever name you want it will be later use as your dns record (in my case full address was gitlab-testpkls924.polandcentral.cloudapp.azure.com)
3. In gitlab_instance folder was created in terraform:
    -public ip
    -key vault
    -nsg
    -vnet
    -subnet
    -nic
    -vm
4. cloud_init.txt did not work well, skip for now
5. After succesful deploy of VM, connect to it trough ssh
6. Install docker https://docs.docker.com/engine/install/ubuntu/
7. Change hostname in run_container_gitlab_instance.sh to the name you changed in step 2
8. Run command run_container_gitlab_instance.sh, you can run: sudo docker logs gitlab -f to see if it is running
9. Run for example curl https://gitlab-testpkls924.polandcentral.cloudapp.azure.com (You can check also for http to see if moving from http to https is working well)
9. Run sudo docker exec -it gitlab cat /etc/gitlab/initial_root_password to get password (Important: it is temporary stored for only 24h)

![alt text](image.png)
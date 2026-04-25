#!/bin/bash
HOSTNAME="gitlab-testpkls924.polandcentral.cloudapp.azure.com"

sudo docker run --detach \
  --hostname "$HOSTNAME" \
  --env "GITLAB_OMNIBUS_CONFIG=external_url 'https://${HOSTNAME}'; letsencrypt['enable']=true; gitlab_rails['lfs_enabled']=true;" \
  --publish 443:443 \
  --publish 80:80 \
  --publish 6022:22 \
  --name gitlab \
  --restart always \
  --volume /code/gitlab/config:/etc/gitlab \
  --volume /code/gitlab/logs:/var/log/gitlab \
  --volume /code/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce


# In case sometimes might be wrong with letsncrypt, use:

#sudo docker exec -it gitlab gitlab-ctl stop
#sudo rm -rf /var/opt/gitlab/letsencrypt/*
#sudo rm -rf /etc/gitlab/ssl/*
#sudo docker exec -it gitlab gitlab-ctl start
#sudo docker exec -it gitlab gitlab-ctl reconfigure

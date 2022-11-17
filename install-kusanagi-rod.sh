#INSTALL DOCKER/DOCKER-COMPOSER/DOCKER-MACHINE/KUSANAGI-ROD

#update
sudo apt-get update 

#install gettext (msgfmt)
sudo apt-get install gettext

#install docker
sudo apt-get remove docker docker-engine docker.io containerd runc


sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

#docker test
sudo docker run hello-world

sudo usermod -aG docker ${USER}


#install docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/v2.6.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

docker-compose version



#set name and email to git
git config --global user.name "sinceretechnology"
git config --global user.email "admin@sinceretechnology.com.au"

#install docker-machine
curl -L https://github.com/docker/machine/releases/download/v0.12.2/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine &&
chmod +x /tmp/docker-machine &&
sudo cp /tmp/docker-machine /usr/local/bin/docker-machine



#install kusanagi rod
curl https://raw.githubusercontent.com/prime-strategy/kusanagi-docker/master/install.sh |bash

echo "KUSANAGI-ROD INSTALL COMPLETED"

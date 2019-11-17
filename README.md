## ISO Builder

This ISO builder is fork of the good work from the elementary crew.  Many thanks to the devs there https://github.com/elementary/os

## Building Locally

As ubuntu cinnamon-remix is built with the Debian version of `live-build`, not the Ubuntu patched version, it's easiest to build an iso in a Debian VM or container. This prevents messing up your host system too.

The following example uses Docker and assumes you have Docker correctly installed and set up:

 1) sudo apt install docker
 2) sudo docker pull debian

 later) Configure the channel in the `etc/terraform.conf` (stable, unstable).

 3) Customise the docker image to have the ability to build eoan/focal

    sudo docker run --privileged -it debian:latest

    note the containerID in the root prompt e.g. root@ea5126f14ac9:/#

    Now install debootstrap package and create an eoan (or focal script)

    apt update && apt install debootstrap -y
    cd /usr/share/debootstrap/scripts
    cp disco eoan
    cd


    Install git and nano

    apt install git nano -y

    Clone the iso-builder

    mkdir /home/cinnamonremix
    cd /home/cinnamonremix
    git clone https://github.com/ubuntubudgie/iso-builder -b cinnamonv2

    ./build.sh

    This will eventually complete - ignore any errors

    exit the container and commit the results

    exit
    sudo docker commit containerID e.g.

    sudo docker commit ea5126f14ac9

    Stop the docker container (important step)

    sudo docker stop ea5126f14ac9



 3) Run the build by starting a container:

    sudo docker start -i ea5126f14ac9

    cd /home/cinnamonremix/iso-builder

    ./terraform.sh

 4) When done, your image will be in the builds folder.

    On your host, copy the build folder from your docker container

    sudo docker cp containerID:/home/cinnamonremix/iso-builder/builds/amd64 .

    Finish by shutting down the container

    sudo docker stop containerID

## Docker hints

To see the list of docker containers

    sudo docker ps -a

To remove a docker container using the Container ID listed with the above command

    sudo docker rm containerid

To stop a docker container when running

    sudo docker stop containerid



## Further Information

More information about the concepts behind `live-build` and the technical decisions made to arrive at this set of tools to build an .iso can be found [on the wiki](https://github.com/elementary/os/wiki/Building-iso-Images).

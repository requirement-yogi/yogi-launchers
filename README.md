This repository is an extraction from Requirement Yogi's internal sources, that starts various Confluence/Jira instances. Features:
* Run several versions of Jira and Confluence in parallel,
* It just generates a `docker-compose.yml`. 
* State is kept between restarts,
* Quickly reinstall plugins with `cp.sh`,
* Access the logs, the DB and the Java debug port,
* It is tested on Macs only (Intel, M1, M3).

## How to run?

* Build the image you desire, using: `./build-image.sh confluence 9.0.1 --apple`
** It creates a directory with a file named `docker-compose.yml`
** If you are using an Apple M1, use the argument `--apple`. If you are on x86, don't.
* Modify your `/etc/hosts` file (instructions given in the created `docker-compose.yml`. We've chosen this option to allow several instances to run in parallel without cookies interfering).
* Run the image:
```
cd confluence-9.0.1
docker compose up
```
* You *will* overlook the header of the created `docker-compose.yml`. Look again into it, everything is explained ;) 
** The URL to access from the browser,
** The URL/port/credentials to access from an SQL client,
** The debug port.
* Install plugins in this instance:
** Copy the .jar in the `confluence-x.y.z/quickreload/` directory,
** Or use (./cp.sh) to detect the .jar of the current directory and quick-reload it,

## Customize!

* We've designed the `cp.sh` according to our needs. Arrange it to make it easy for your developers.
* We've muted some logs in `Dockerfile-confluence` and `Dockerfile-jira` because it was relevant for us. Arrange it the way you want.

## Magics

* Do you want to connect to the Confluence/Jira **database**? It's possible! See the created `docker-compose.yml`,
* Do you want to connect to 5005 with your **Java debugger**? It's possible! See the created `docker-compose.yml`,
* Do you want to access the **logs**? It's possible! See the created `docker-compose.yml`,
* Do you want to access the **entire Confluence-home directory**, not just the logs? We didn't mount this volume by default, but you can do it by modifying the mounted `volumes` section in docker-compose.yml. You'll have to drop-and-recreate the containers.

## Thanks to...

This setup is inspired from https://github.com/collabsoft-net/example-confluence-app-with-docker-compose .
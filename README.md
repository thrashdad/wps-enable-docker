# **IBM WebSphere Portal Web Content Manager 8.5 on Docker**

## What is this?

An example of how to run IBM WSP Enable (WCM) V8.5 on a Docker container. The container is launched from an image that's pre-built to run WebSphere Application Server 8.5.5 in standalone configuration with a built-in derby database. This can be used for demonstration purposes, testing and development.
Final image size is super light (4.7GB - which expands out to about 8GB when deployed) when regular VM or server installation can take 30-40GB.

Inspired by [amirbarkal GitHub](https://github.com/amirbarkal/wps-enable-docker) and [WASdev GitHub](https://github.com/WASdev/ci.docker.websphere-traditional)

## Building the Portal Image

**Build the image in steps to reduce final image size**

1. Download and place all source files somewhere that's accessible via http or ftp (list of required files below):

2. Clone this repository:

3. Build base WebSphere Application Server ND image (with fix pack and Java SDK):

   `docker build -t part1 --build-arg=URL=http://www.where-your-source-files-are.com -f Dockerfile.part1 .`
4. Run a container by using the part1 image to create a .tar file with only what we need to run WAS (this keeps image size to a minimum):

   `docker run -v ${pwd}:/tmp -it part1`

Note: the user that the image is running as (ie - UID 1) needs to have write access to the current directory.

5. Create a clean WAS image from .tar file: 

   `docker build -t part2 -f Dockerfile.part2 .`

This unpacks the .tar file in to a clean image.

6. Build a WebSphere Portal image by installing Portal 8.5 and CF 15 into a new image based on part2 (this part may take some time):

   `docker build -t part3 --build-arg=URL=http://www.where-your-source-files-are.com --build-arg=HOST_NAME=portal1 -f Dockerfile.part3 .`
7. Run a container by using the part3 image to create a .tar file with only what we need to run Portal (again...!):

   `docker run -v ${pwd}:/tmp -it part3 .`
8. Build the final image:

   `docker build -t wps -f Dockerfile.part4 .`
9. Start the container:

   `docker run -h portal1 -dit wps`
10. Access your shiny new portal instance from `http://DOCKER_HOST:10039/wps/portal`


## Legal Stuff:

* All source files are protected under IBM Software License Agreement.

## Technical Details:

   + (linux) selinux must be disabled.
   + You need write access to the directory you start building the image from.
   + You need modify your docker daemon to allow up to 30GB for container size when building images (the source files are large and they are unpacked before being removed)

   + Current version level is:

     * Java 7.0.6.1
     * Websphere Application Server ND 8.5.5 Fix Pack 12
     * Portal Server WCM 8.5 Cumulative Fix 15
     * Installation Manager 1.8.5.1

   + The following IBM part numbers and source files were used to construct the image:

     * CIYW1ML WS_SDK_JAVA_TECH_7.0.6.1.zip
     * CIYW3ML WSP_Enable_8.5_Setup.zip
     * CIYV9ML WSP_Server_8.5_Install.zip
     * CIYW4ML WSP_Enable_8.5_Install.zip
     * CIK2HML WASND_v8.5.5_1of3.zip
     * CIK2IML WASND_v8.5.5_2of3.zip
     * CIK2JML WASND_v8.5.5_3of3.zip
     * agent.installer.linux.gtk.x86_64_1.8.5001.20161016_1705.zip
     * 8.5-9.0-WP-WCM-Combined-CFPI83476-Server-CF15.zip
     * 8.5.5-WS-WAS-FP012-part1.zip
     * 8.5.5-WS-WAS-FP012-part2.zip
     * 8.5.5-WS-WAS-FP012-part3.zip
     

# Red Hat docker images for running Ruby, Python, Node.js and Meteor web apps with Passenger

<center><img src="http://blog.phusion.nl/wp-content/uploads/2012/07/Passenger_chair_256x256.jpg" width="196" height="196" alt="Phusion Passenger"> <img src="http://blog.phusion.nl/wp-content/uploads/2013/11/docker.png" width="233" height="196" alt="Docker"> <img src="https://www.phusionpassenger.com/assets/pages/download/redhat-19aab036c29fd59acd176488db6304d3.png" width="196" height="196" alt="Red Hat"></center>

Passenger-docker-redhat is a set of [Docker](https://www.docker.com) images that provide a very easy way to run 
**Ruby, Python, Node.js and bundled Meteor** web apps using [Phusion Passenger](https://www.phusionpassenger.com/) (a fast, easy and reliable web application server).

By using passenger-docker-redhat as a base image, you can have your own web app docker container built & running with 
a very minimal Dockerfile and a few lines of configuration.

This image contains a deployment of [Passenger with Nginx](https://www.phusionpassenger.com/library/indepth/integration_modes.html). It is built for those who prefer Red Hat inside the image, although it should run on docker-supported linux distributions like Ubuntu. If you do prefer something else, there is also an [Ubuntu-based image](https://github.com/phusion/passenger-docker).

**Related links:**
 [Github](https://github.com/phusion/passenger-docker-redhat) |
 [Discussion forum](https://groups.google.com/d/forum/passenger-docker) |
 [Passenger docs](https://www.phusionpassenger.com/documentation/Users%20guide%20Nginx.html) |
 [Twitter](https://twitter.com/phusion_nl) |
 [Blog](http://blog.phusion.nl/)
 
## Using passenger-docker-redhat

### Configuration
This example `Dockerfile` results in an image containing the `myapp` web app, reachable on port 80.

```dockerfile
FROM phusion/passenger-redhat-full:0.1

# If you only need a certain language you can also use one of the slimmed down images instead:
#FROM phusion/passenger-redhat-ruby:0.1
#FROM phusion/passenger-redhat-nodejs:0.1
#FROM phusion/passenger-redhat-python:0.1

MAINTAINER You <you@example.com>

ADD myapp/ /var/lib/nginx/myapp/
ADD myapp.conf /etc/nginx/conf.d/

EXPOSE 80

# Your app probably needs a command to install dependencies:
# Ruby app:
#RUN cd /var/lib/nginx/myapp; bundle
# Node.js app:
#RUN cd /var/lib/nginx/myapp; npm install
# Python app, e.g. when using a framework like Flask:
#RUN pip install flask
```
The contents of `myapp.conf` (to activate Passenger for the web app):

```nginx
server {
	listen 80;

	passenger_user nginx;
	passenger_enabled on;
	
	passenger_app_env production;
	
	root /var/lib/nginx/myapp/public;

	location / {
	}
}
```

### Meteor: extra configuration

Passenger-docker-redhat only supports Meteor apps that are bundled. In this mode the app runs as a Node.js app so you can use the `passenger-redhat-nodejs` image as the slimmed down base image. Some extra configuration is also needed:

Add to the `Dockerfile`:
```dockerfile
# Dependencies for bundled Meteor app 
RUN cd /var/lib/nginx/myapp/programs/server/; npm install

# Extra config for allowing ROOT_URL
ADD meteor.conf /etc/nginx/main.d/
```

Create `meteor.conf`:
```nginx
# Allow this environment variable to be passed using docker run -e ..
env ROOT_URL;
```

Add to `myapp.conf`, within the `server { .. }` block:
```nginx
	# Passenger only looks for app.js by default, but bundled Meteor apps have main.js.
	passenger_app_type node;
	passenger_startup_file main.js;
```

### Build & run
With the configuration done, you can build the image and run it:

	docker build -t you/app:0.1 .
	docker run -d --name=appcontainer you/app:0.1

To see your web app in action, you can find out where it is running:

	docker inspect appcontainer | grep IPAddress
	  (output) "IPAddress": "10.3.0.78",

And browse to that address: http://10.3.0.78/ 

## Troubleshooting

As long as the container is running, you can exec commands on it such as the following: 

	# Command to see if passenger is running
	docker exec -t -i appcontainer passenger-status
	
	# A console for looking around inside the running container
	docker exec -t -i appcontainer bash -l

A common issue is that Passenger does not recognize the webapp. Make sure you either have the file Passenger expects or [configure an alternative filename](https://www.phusionpassenger.com/documentation/Users%20guide%20Nginx.html#PassengerStartupFile):

Language  | Expected file
------------- | -------------
Ruby  | config.ru
Node.js  | app.js
Meteor | app.js (in this readme we configured it to main.js)
Python | passenger_wsgi.py (e.g. containing `from app import MyApp as application`)

Error logs can be found in `/var/log/nginx/error.log`.
	
If the container doesn't start at all, you can have a look inside with bash (run `nginx` in the console to see if that throws an error):

	docker run -t -i you/app:0.1 my_init --skip-runit -- bash -l

Finally, there is a [discussion forum](https://groups.google.com/d/forum/passenger-docker) where others might be able to help you.

## Advanced topics

### Passenger / Nginx configuration

This image runs Passenger in combination with Nginx. Configuration files are included from two folders:
- from `/etc/nginx/conf.d/`, into the http {} block (such as the example `myapp.conf` above)
- from `/etc/nginx/main.d/`, into the top level (for example, to whitelist environment variables using `env ..;`)

For all configuration options, see the [Passenger/Nginx documentation](https://www.phusionpassenger.com/documentation/Users%20guide%20Nginx.html).

A special note about environment variables: Nginx [clears all environment variables](http://nginx.org/en/docs/ngx_core_module.html#env) except `TZ`. If you want to pass environment variables to your web app (e.g. using `docker run -e ..`), you need to whitelist them with a configuration file in `/etc/nginx/main.d/`.

For example, to whitelist `POSTGRES_PORT_5432_TCP_ADDR` you could add `/etc/nginx/main.d/postgres.conf` with the following content:

	# Whitelist environment variable so it reaches web app
    env POSTGRES_PORT_5432_TCP_ADDR;

The image already whitelists `PATH` by default so that for example Node.js can be found by the Ruby ExecJs gem.

### Development vs. production mode

Passenger runs your web app in the mode that is specified by the `passenger_app_env` configuration setting (default value: production). The value is applied to the environment variables `RAILS_ENV`, `RACK_ENV`, `WSGI_ENV` and `NODE_ENV`, so that you can use the same Passenger option no matter which type of web app you use.

Note that this also means that any value you put in those environment variables is overwritten by Passenger, so if you need to switch to development mode, use the `passenger_app_env` setting. Another way to do this on-the-fly is using `docker run -e PASSENGER_APP_ENV=development ..`, but then you need to delete the `passenger_app_env` setting from your configuration because it takes precedence.

### Running startup scripts

While starting, this image also executes any scripts (in lexographical order) from the following folder:
- `/etc/my_init.d/`

Note: the container will not start if any of the scripts returns a nonzero exit code.

This mechanism might be useful for tasks that are closely tied to your web app but cannot be run by the web app itself or split out to another docker container.

### Maintenance upgrade 

From time to time we release new images with various upgrades, such as the Passenger version. If you don't want to be dependent on this timing, you can also automatically upgrade components while building your image. 

For example, to always build with the latest Passenger, you can add to your `Dockerfile`:
```docker
RUN yum update -y
```

### Switching to Phusion Passenger Enterprise

If you are a [Phusion Passenger Enterprise](https://www.phusionpassenger.com/enterprise) customer, then you can switch to the Enterprise variant as follows.

 1. Login to the [Customer Area](https://www.phusionpassenger.com/orders).
 2. Download the license key and store it in the same directory as your Dockerfile.
 3. Insert into your Dockerfile:

```docker
ADD passenger-enterprise-license /etc/passenger-enterprise-license
RUN echo deb https://download:$DOWNLOAD_TOKEN@www.phusionpassenger.com/enterprise_apt trusty main > /etc/apt/sources.list.d/passenger.list
RUN apt-get update && apt-get install -y -o Dpkg::Options::="--force-confold" passenger-enterprise nginx-extras
```
Replace `$DOWNLOAD_TOKEN` with your actual download token, as found in the Customer Area.

[<img src="http://www.phusion.nl/assets/logo.png">](http://www.phusion.nl/)

The image is maintained by [Phusion B.V.](http://www.phusion.nl/), we hope you enjoy using it :-)
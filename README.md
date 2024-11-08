<img src=".github/Logo.jpg" alt="FlexRunner Logo" width="200" height="200">

# FlexRunner: Ascalable self-hosted runner(s) to enable in-house automated testing

The instruction below helps you to build and instantiate self-hosted runners to run automated testing and to maintain your needed test data and artifacts within the self-hosted runner(s), securely.


To list the available options and their functions:

```bash
make help

```



You should see:
```

 ## ------------------------------------------------------------------ 
 ## The purpose of this file is to compile the source code. 
 ## ------------------------------------------------------------------ 
 help                            Show this help.
 envs                            List environment variables
 init                            Initialize the project
 create_model_volume             Create docker volume for model
 copy_model_files                Copy models to docker volume
 create_data_volume              Create docker volume for data
 copy_data_files                 Copy data to docker volume
 set_model_permissions           Set permissions for data
 set_data_permissions            Set permissions for data
 create_secret                   Create secret
 build                           Build the docker image
 start                           Start the docker container
 scale                           Scale the docker container
 stop                            Stop the docker container
 remove                          Remove services and their associated containers
 list                            List all containers
 clean                           Purge the dangling images to save space


 ```

**1. Setup environment variables**:
  
There may be build-time and runtime environment variables that specify user's credentials as well as behavior of your required setup. You can initiate them via:

```
make init

```

The command creates a `.env` file, where the required environment variables are defined with the default values.



**2. Build the dockerized runner**:

To build the docker image of the runner invoke:

```
make build

```



**3. Run the dockerized runner**:

To run the docker container hosting the runner invoke:

```
make start

```


**4. Stop and clean up the dockerized runner**:

To stop the runner invoke:

```
make stop

```

and to remove services and their associated containers:

```
make remove

```


and to purge dangling images and save space:

```
make clean

```


**5. To scale up or down**:

To scale the service either up or down:

```
make scale

```











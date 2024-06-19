### golang debian base image ###
FROM golang:latest

# Install necessary packages for adding new repos and wget & unzip, clean cache afterwards to minimize layer size
RUN apt-get update && apt-get install -y \
    build-essential  \
    git \
    curl \
    libaio1 \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Download the Basic packages from Oracle and verify their checksums
RUN wget https://download.oracle.com/otn_software/linux/instantclient/2340000/instantclient-basiclite-linux.x64-23.4.0.24.05.zip

# Unpack packages
RUN unzip instantclient-basiclite-linux.x64-23.4.0.24.05.zip \
    && rm -f *.zip

RUN mv instantclient_23_4 instantclient
WORKDIR /opt/instantclient

# Soft links
RUN if [ ! -e libclntsh.so ]; then ln -s libclntsh.so.23.4 libclntsh.so; fi

# set environment variables
ENV LD_LIBRARY_PATH /opt/instantclient
ENV ORACLE_BASE /opt/instantclient
ENV ORACLE_HOME $ORACLE_BASE
ENV PATH $ORACLE_HOME:$PATH

WORKDIR $GOPATH/src/go.k6.io/k6
ADD . .

# install xk6 Custom k6 Builder
RUN go install go.k6.io/xk6/cmd/xk6@latest

# build oracle sql driver for k6 and create a custom k6 binary
RUN CGO_ENABLED=1 CGO_CFLAGS="-D_LARGEFILE64_SOURCE" xk6 build \
    --with github.com/bhaskarkoley/xk6-sql-oracle=. \
    --output /usr/bin/k6

# Add a group with the specified GID
RUN groupadd -g 12345 k6group

# Add a user and add it to the newly created group
RUN useradd --create-home --gid k6group --uid 12345 k6

# give full permissions to all users
RUN chmod 777 -R /home/k6
RUN chmod 777 -R /opt/instantclient
RUN chmod 777 -R /usr/bin/k6

# Switch to the new user
USER k6

# set working directory
WORKDIR /home/k6

# copy all scripts to home dir
ADD examples /home/k6

# CMD to keep the container running for ever
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"

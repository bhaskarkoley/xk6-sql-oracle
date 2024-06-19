# Multi-stage build to generate custom k6 with extension
FROM golang:latest

RUN apt-get update && apt-get install -y \
    build-essential  \
    git \
    curl \
    libaio1 \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN wget https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basiclite-linux.x64-21.1.0.0.0.zip \
    && wget https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-sdk-linux.x64-21.1.0.0.0.zip

# Unpack "Basic", "SDK" packages
RUN unzip instantclient-basiclite-linux.x64-21.1.0.0.0.zip \
    && unzip instantclient-sdk-linux.x64-21.1.0.0.0.zip \
    && rm -f *.zip

RUN mv instantclient_21_1 instantclient
WORKDIR /opt/instantclient

# Soft links
RUN if [ ! -e libclntsh.so ]; then ln -s libclntsh.so.21.1 libclntsh.so; fi

# set environment variables
ENV LD_LIBRARY_PATH /opt/instantclient
ENV ORACLE_BASE /opt/instantclient
ENV ORACLE_HOME $ORACLE_BASE
ENV PATH $ORACLE_HOME:$PATH

WORKDIR $GOPATH/src/go.k6.io/k6
ADD . .

RUN go install go.k6.io/xk6/cmd/xk6@latest
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

CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"

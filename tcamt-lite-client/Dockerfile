# TCAMT Lite client — reproducible stack (Node 13.12.0 / npm 6.14.4)
FROM node:13.12.0-buster

# Debian Buster is EOL; default mirrors return 404. Point apt at the archive.
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list \
	&& sed -i '/security.debian.org/d' /etc/apt/sources.list

# System deps:
# - git: npm/bower fetch from GitHub
# - python3 + make + g++: node-gyp (native Node addons)
# - build-essential: gcc/g++ toolchain
# - libssl-dev: some optional native modules
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	git \
	ca-certificates \
	python3 \
	make \
	g++ \
	build-essential \
	libssl-dev \
	&& rm -rf /var/lib/apt/lists/*

# node-gyp (used by npm install) expects a Python interpreter
ENV PYTHON=/usr/bin/python3
RUN npm config set python /usr/bin/python3

RUN git config --global url."https://github.com/".insteadOf "git://github.com/"

WORKDIR /app

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

COPY package.json package-lock.json bower.json ./

RUN npm install

COPY . .

RUN node node_modules/bower/bin/bower install --allow-root

ENV GRUNT_CONNECT_HOSTNAME=0.0.0.0
ENV GRUNT_NO_OPEN=1
# Grunt watch + Docker Desktop / VM file sharing
ENV CHOKIDAR_USEPOLLING=1
# API proxy (set by tcamt-deploy/docker-compose or leave empty for standalone UI)
ENV TCAMT_CONTEXT_PATH=tcamt

EXPOSE 9000 35729

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["npx", "grunt", "serve"]

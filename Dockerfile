# Container image that runs your code
FROM wtfjoke/setup-tectonic@v1

# Download 'jq' package
RUN pacman -Sy --noconfirm --needed jq

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]

# Ubuntu 24.04 test environment for peter-terminal-utils
# Builds a container with a non-root user that has passwordless sudo access.

FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install minimal prerequisites needed before setup runs
# Note: Ubuntu 24.04 minimal image doesn't include Python
RUN apt-get update -qq && \
    apt-get install -yq --no-install-recommends \
        sudo \
        curl \
        ca-certificates \
        git \
        python3 \
    && rm -rf /var/lib/apt/lists/*

# Create test user with passwordless sudo (more realistic than running as pure root)
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy the linux setup directory
COPY --chown=testuser:testuser . /home/testuser/linux-setup

# Switch to test user
USER testuser
WORKDIR /home/testuser/linux-setup

# Make setup executable
RUN chmod +x setup

# Default command runs headless preset
CMD ["./setup", "--preset", "2"]

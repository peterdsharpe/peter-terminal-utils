# Ubuntu 24.04 test environment for peter-terminal-utils
# Builds a container with a non-root user that has passwordless sudo access.

FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install only what's needed to run setup (everything else comes from bootstrap.sh)
# Note: Ubuntu 24.04 minimal image doesn't include Python
RUN apt-get update -qq && \
    apt-get install -yq --no-install-recommends \
        sudo \
        python3 \
    && rm -rf /var/lib/apt/lists/*

# Create test user with passwordless sudo (more realistic than running as pure root)
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy the full repository (build context is repo root)
COPY --chown=testuser:testuser . /home/testuser/peter-terminal-utils

# Switch to test user
USER testuser
WORKDIR /home/testuser/peter-terminal-utils/linux

# Make setup executable
RUN chmod +x setup

# Default command runs full desktop preset with verbose output for debugging
CMD ["./setup", "--preset", "1", "--verbose"]

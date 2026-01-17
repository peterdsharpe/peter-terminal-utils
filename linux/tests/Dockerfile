# Ubuntu 24.04 test environment for peter-terminal-utils
# Builds a minimal container with a non-root user that has passwordless sudo access.
# The repository is mounted at runtime, not copied at build time.

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

# Create mount point directory with correct ownership
RUN mkdir -p /home/testuser/peter-terminal-utils && \
    chown testuser:testuser /home/testuser/peter-terminal-utils

# Switch to test user
USER testuser
WORKDIR /home/testuser/peter-terminal-utils/linux

# Default to bash (repo must be mounted at runtime)
CMD ["/bin/bash"]

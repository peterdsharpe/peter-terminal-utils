#!/usr/bin/env python3
"""
Docker-based test runner for peter-terminal-utils Linux setup.

Builds a clean Ubuntu 24.04 container and runs the full setup script,
capturing output and exit codes to verify all scripts complete successfully.

Usage:
    uv run run_docker_test.py           # Full test
    uv run run_docker_test.py --dry-run # Preview without execution
    uv run run_docker_test.py --no-cache # Rebuild image from scratch
"""

import argparse
import subprocess
import sys
import time
from pathlib import Path

###############################################################################
### Constants
###############################################################################

IMAGE_NAME = "peter-terminal-utils-test"
CONTAINER_NAME = "ptu-test-run"

# ANSI colors for output
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
CYAN = "\033[0;36m"
BOLD = "\033[1m"
NC = "\033[0m"  # No Color


###############################################################################
### Helpers
###############################################################################


def print_header(msg: str) -> None:
    """Print a bold header line."""
    print(f"\n{BOLD}{CYAN}{'═' * 70}{NC}")
    print(f"{BOLD}{CYAN}  {msg}{NC}")
    print(f"{BOLD}{CYAN}{'═' * 70}{NC}\n")


def print_step(msg: str) -> None:
    """Print a step indicator."""
    print(f"{CYAN}▶{NC} {msg}")


def print_success(msg: str) -> None:
    """Print a success message."""
    print(f"{GREEN}✓{NC} {msg}")


def print_error(msg: str) -> None:
    """Print an error message."""
    print(f"{RED}✗{NC} {msg}")


def print_warning(msg: str) -> None:
    """Print a warning message."""
    print(f"{YELLOW}⚠{NC} {msg}")


def get_linux_dir() -> Path:
    """Get the path to the linux/ directory (parent of tests/)."""
    return Path(__file__).parent.parent.resolve()


def run_cmd(
    cmd: list[str],
    *,
    capture: bool = False,
    stream: bool = False,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    """Run a command with optional streaming output.

    Args:
        cmd: Command and arguments to run.
        capture: If True, capture stdout/stderr (mutually exclusive with stream).
        stream: If True, stream output to terminal in real-time.
        check: If True, raise CalledProcessError on non-zero exit.

    Returns:
        CompletedProcess with return code (and captured output if capture=True).
    """
    if stream:
        # Stream output line-by-line for real-time feedback
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,  # Line buffered
        )
        assert process.stdout is not None
        for line in process.stdout:
            print(line, end="")
        process.wait()
        result = subprocess.CompletedProcess(cmd, process.returncode, "", "")
    elif capture:
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    else:
        result = subprocess.run(cmd, check=False)

    if check and result.returncode != 0:
        raise subprocess.CalledProcessError(result.returncode, cmd)

    return result


###############################################################################
### Docker Operations
###############################################################################


def check_docker_available() -> bool:
    """Verify Docker is installed and running."""
    try:
        result = run_cmd(["docker", "info"], capture=True, check=False)
        return result.returncode == 0
    except FileNotFoundError:
        return False


def cleanup_container() -> None:
    """Remove any existing test container."""
    run_cmd(
        ["docker", "rm", "-f", CONTAINER_NAME],
        capture=True,
        check=False,
    )


def build_image(linux_dir: Path, *, no_cache: bool = False) -> bool:
    """Build the Docker test image.

    Args:
        linux_dir: Path to the linux/ directory to copy into the image.
        no_cache: If True, rebuild without using cached layers.

    Returns:
        True if build succeeded, False otherwise.
    """
    print_step(f"Building Docker image: {IMAGE_NAME}")

    dockerfile = linux_dir / "tests" / "Dockerfile"
    if not dockerfile.exists():
        print_error(f"Dockerfile not found: {dockerfile}")
        return False

    cmd = [
        "docker",
        "build",
        "-t",
        IMAGE_NAME,
        "-f",
        str(dockerfile),
    ]
    if no_cache:
        cmd.append("--no-cache")
    cmd.append(str(linux_dir))

    try:
        run_cmd(cmd, stream=True)
        print_success("Docker image built successfully")
        return True
    except subprocess.CalledProcessError as e:
        print_error(f"Docker build failed with exit code {e.returncode}")
        return False


def run_container(*, dry_run: bool = False) -> int:
    """Run the test container and execute the setup script.

    Args:
        dry_run: If True, run setup in dry-run mode (preview only).

    Returns:
        Exit code from the container (0 = all scripts passed).
    """
    cleanup_container()

    cmd = [
        "docker",
        "run",
        "--name",
        CONTAINER_NAME,
        "--rm",  # Remove container after exit
        IMAGE_NAME,
    ]

    # Override default CMD if dry-run requested
    if dry_run:
        cmd.extend(["./setup", "--preset", "2", "--dry-run"])

    print_step("Running setup in container...")
    start_time = time.time()

    try:
        result = run_cmd(cmd, stream=True, check=False)
        elapsed = time.time() - start_time
        return result.returncode
    except KeyboardInterrupt:
        print_warning("\nInterrupted - cleaning up container...")
        cleanup_container()
        return 130
    finally:
        elapsed = time.time() - start_time
        print(f"\n{CYAN}Duration:{NC} {elapsed:.1f}s")


###############################################################################
### Main
###############################################################################


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Docker-based test runner for Linux setup scripts",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Run setup in dry-run mode (preview changes only)",
    )
    parser.add_argument(
        "--no-cache",
        action="store_true",
        help="Rebuild Docker image without cache",
    )
    parser.add_argument(
        "--build-only",
        action="store_true",
        help="Only build the image, don't run tests",
    )
    args = parser.parse_args()

    print_header("Peter's Linux Setup - Docker Test Runner")

    # Check Docker availability
    if not check_docker_available():
        print_error("Docker is not available. Please install Docker and ensure it's running.")
        return 1

    linux_dir = get_linux_dir()
    print(f"Testing setup from: {linux_dir}")

    # Build the image
    if not build_image(linux_dir, no_cache=args.no_cache):
        return 1

    if args.build_only:
        print_success("Build completed (--build-only specified, skipping test run)")
        return 0

    # Run the container
    print_header("Running Setup in Container")
    exit_code = run_container(dry_run=args.dry_run)

    # Print summary
    print_header("Test Summary")
    if exit_code == 0:
        print_success("All scripts completed successfully!")
    else:
        print_error(f"Setup failed with exit code: {exit_code}")
        print("\nTo debug, you can run the container interactively:")
        print(f"  docker run -it --rm {IMAGE_NAME} /bin/bash")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())

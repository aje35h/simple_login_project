# Use a slim Python base image for a smaller footprint and stable OS
FROM python:3.12.11-slim-bullseye

# Set environment variables for Python within the container
# PYTHONDONTWRITEBYTECODE=1: Prevents Python from writing .pyc files to disk,
#                           keeping the image cleaner and slightly smaller.
# PYTHONUNBUFFERED=1: Ensures Python stdout/stderr is unbuffered, meaning
#                     logs appear in real-time in your console/logs.
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set the working directory inside the container.
# All subsequent commands (COPY, RUN, etc.) will be executed relative to this path.
# This keeps your application's files organized within the image.
WORKDIR /app

# Optional: Install system-level dependencies.
# Uncomment and add packages here if your Python libraries have underlying
# system requirements (e.g., psycopg2-binary might need libpq-dev,
# or certain image processing libraries might need build-essential, libjpeg-dev, etc.).
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     # Add your system dependencies here, e.g., build-essential, libpq-dev \
#     && rm -rf /var/lib/apt/lists/*

# Copy the requirements file first. This is a crucial Docker caching optimization.
# If only your application code changes, but requirements.txt remains the same,
# Docker will reuse the cached layer for 'pip install', speeding up builds.
COPY requirements.txt .

# Install Python dependencies specified in requirements.txt.
# --no-cache-dir: Prevents pip from storing downloaded packages in a cache directory,
#                 reducing the final image size.
RUN pip install --no-cache-dir -r requirements.txt

# --- Security Enhancement: Create a dedicated non-root user ---
# Create a new group and user, giving them a non-root UID/GID.
# This user will run the application process, enhancing security.
RUN groupadd --system appgroup && useradd --system --gid appgroup appuser

# Copy the rest of your application code into the container's working directory.
# This copies all files and folders from your current context (where Dockerfile is)
# into '/app' inside the container.
COPY . .

# Set ownership of the application directory to the new user.
# This ensures the appuser has the necessary permissions to read/write files in /app.
RUN chown -R appuser:appgroup /app

# Switch to the non-root user.
# All subsequent commands (and the default entrypoint/cmd if defined) will run as this user.
USER appuser

# Declare the port your Django application is expected to run on.
# This is documentation for Docker, not a functional command to open the port.
# It helps others using your image understand which port to expose.
EXPOSE 8000

# Removed CMD instruction for flexibility (explained below)
# No CMD or ENTRYPOINT here. This makes the image flexible.
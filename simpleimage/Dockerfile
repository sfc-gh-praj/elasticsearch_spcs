# Use a Python base image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install JupyterLab and Snowpark Python library
RUN pip install --no-cache-dir jupyterlab snowflake-snowpark-python

# Install additional dependencies if needed
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create a directory for the Jupyter workspace
RUN mkdir -p /workspace
WORKDIR /workspace

# Expose JupyterLab port
EXPOSE 8888

# Command to start JupyterLab
CMD ["jupyter","lab" ,"--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root","--NotebookApp.token=''", "--NotebookApp.password=''"]

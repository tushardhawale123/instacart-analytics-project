FROM jupyter/pyspark-notebook:latest

USER root

# Install additional Python packages
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Set working directory
WORKDIR /home/jovyan/work

# Switch back to jovyan user
USER jovyan
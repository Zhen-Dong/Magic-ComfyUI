FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=America/Los_Angeles

ARG USE_PERSISTENT_DATA

RUN apt-get update && apt-get install -y \
    git \
    make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git-lfs  \
    ffmpeg libsm6 libxext6 cmake libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

WORKDIR /code

COPY ./requirements.txt /code/requirements.txt

# User
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

# Pyenv
RUN curl https://pyenv.run | bash
ENV PATH=$HOME/.pyenv/shims:$HOME/.pyenv/bin:$PATH

ARG PYTHON_VERSION=3.9.17
# Python
RUN pyenv install $PYTHON_VERSION && \
    pyenv global $PYTHON_VERSION && \
    pyenv rehash && \
    pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir \
    datasets \
    huggingface-hub "protobuf<4" "click<8.1"

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Set the working directory to /data if USE_PERSISTENT_DATA is set, otherwise set to $HOME/app
WORKDIR $HOME/app

# Copy the current directory contents into the container at $HOME/app setting the owner to the user
COPY . .

# Checkpoints
CMD ["python", "main.py", "--listen", "0.0.0.0", "--cpu", "--port", "7860", "--output-directory", "${USE_PERSISTENT_DATA:+/data/}"]

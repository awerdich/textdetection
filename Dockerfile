FROM nvidia/cuda:12.1.1-base-ubuntu22.04 AS base

ARG DEV_textdetection
ARG DEBIAN_FRONTEND=noninteractive

ENV \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    PIP_SRC=/src \
    PIPENV_HIDE_EMOJIS=true \
    NO_COLOR=true \
    PIPENV_NOSPIN=true \
    TZ=America/New_York

# Port for JupyterLab server
EXPOSE 7485

RUN mkdir -p /app
WORKDIR /app

# System dependencies
RUN : \
    && apt-get update -y \
    && apt-get install -y \
    'git' \
    'libgl1-mesa-glx' \
    'ffmpeg' \
    'libsm6' \
    'libxext6' \
    'ninja-build'

# Install python 3.11 from the deadsnakes repository
RUN : \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \ 
    && echo $TZ > /etc/timezone \
    && apt-get install -y software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
        'python3.11-venv' \ 
        'python3-pip' \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && :
RUN python3.11 -m venv /venv
ENV PATH=/venv/bin:$PATH

# Create a symbolic link for python
RUN ln -s /usr/bin/python3.11 /usr/bin/python

# Pip and pipenv
RUN pip install --upgrade pip
RUN pip install pipenv

# Some package stuff
COPY setup.py ./
COPY src/textdetection/__init__.py src/textdetection/__init__.py

# Install dependencies into system python
COPY Pipfile Pipfile.lock ./
# RUN pipenv install --system --deploy --ignore-pipfile --dev
# This allows the version to be inferred properly form inside the container 
# without copying the entire .git folder 
RUN --mount=source=.git,target=.git,type=bind \
    pipenv install --system --deploy --ignore-pipfile --dev

# Install dependencies from setup.cfg (ignored py pipenv system installs) 
RUN python -m pip install setuptools setuptools-scm torch torchvision torchaudio
# RUN python -m pip install 'git+https://github.com/facebookresearch/detectron2.git'

# Run the jupyter lab server
CMD ["/bin/bash", "/app/bash_scripts/docker_entry.sh"]
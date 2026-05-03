FROM alpine:3.19

RUN apk add --no-cache \
    curl \
    bash \
    python3 \
    py3-pip \
    jq \
    git \
    openssl \
    unzip \
    gcompat


# Python prometheus app
WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt
COPY app.py .

LABEL VERSION=${VERSION}

EXPOSE 8000
CMD ["python3", "app.py"]

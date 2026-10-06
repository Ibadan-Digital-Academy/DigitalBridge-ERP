# syntax=docker/dockerfile:1
###############################################
# ERPNext image - single multi-stage source
#
# Three chained stages:
#   base
#   all-in-one
#   pre-install
###############################################
###############################################
# Stage 1: base
###############################################
FROM frappe/build:version-16 AS base
USER root
# Ensure the frappe user and group exist.
# The frappe/build image normally provides these,
# but explicitly ensuring them prevents chown failures
# during the build.
RUN if ! getent group frappe >/dev/null 2>&1; then \
        groupadd --system frappe; \
    fi && \
    if ! id -u frappe >/dev/null 2>&1; then \
        useradd --system \
        --gid frappe \
        --home-dir /home/frappe \
        --create-home \
        --shell /bin/bash \
        frappe; \
    fi && \
    mkdir -p /home/frappe && \
    chown -R frappe:frappe /home/frappe
###############################################
# Adding Dependencies
###############################################
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y -q \
    sudo \
    && echo "frappe ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && apt-get autoremove --purge -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*
###############################################
# Init Bench
###############################################
USER frappe
ARG FRAPPE_REPO=https://github.com/frappe/frappe
ARG FRAPPE_BRANCH=version-16
ARG ERPNEXT_REPO=https://github.com/frappe/erpnext
ARG ERPNEXT_BRANCH=version-16
RUN bench init \
    --frappe-branch=${FRAPPE_BRANCH} \
    --frappe-path=${FRAPPE_REPO} \
    --no-backups \
    --skip-redis-config-generation \
    --verbose \
    /home/frappe/frappe-bench && \
    cd /home/frappe/frappe-bench && \
    bench get-app \
    --branch=${ERPNEXT_BRANCH} \
    --resolve-deps \
    erpnext \
    ${ERPNEXT_REPO} && \
    echo "{}" > sites/common_site_config.json
###############################################
# FINALIZED
###############################################
WORKDIR /home/frappe/frappe-bench
USER frappe
###############################################
# Stage 2: all-in-one
###############################################
FROM base AS all-in-one
USER root
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    nginx \
    redis-server \
    supervisor \
    gettext-base \
    && curl -LsSO https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
    && bash mariadb_repo_setup --mariadb-server-version="mariadb-11.8" \
    && rm mariadb_repo_setup \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*
###############################################
# COPY FILES
###############################################
COPY --chown=frappe:frappe --chmod=0755 \
    ./all-in-one/conf/setup.sh \
    /usr/local/bin/setup.sh
COPY --chown=frappe:frappe \
    ./all-in-one/conf/supervisord.conf \
    /etc/supervisor/conf.d/frappe.conf
COPY --chown=frappe:frappe \
    ./all-in-one/conf/nginx.conf \
    /etc/nginx/frappe.conf.template
###############################################
# Stage 3: pre-install
###############################################
FROM all-in-one AS pre-install
USER root
###############################################
# Build-time site configuration
###############################################
ARG SITE_NAME=default.site
ARG ADMIN_PASSWORD=admin
ARG DB_ROOT_PASSWORD=admin
ENV SITE_NAME=${SITE_NAME}
###############################################
# COPY FILES
###############################################
COPY --chown=frappe:frappe --chmod=0755 \
    ./pre-install/conf/init.sh \
    /usr/local/bin/init.sh
COPY --chown=frappe:frappe --chmod=0755 \
    ./pre-install/conf/start.sh \
    /usr/local/bin/start.sh
###############################################
# Pre-install ERPNext
###############################################
RUN SITE_NAME="${SITE_NAME}" \
    ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
    DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD}" \
    /usr/local/bin/init.sh
###############################################
# Runtime
###############################################
EXPOSE 80
CMD ["/usr/local/bin/start.sh"]

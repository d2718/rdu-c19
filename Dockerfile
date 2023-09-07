FROM rocker/shiny:4.3

MAINTAINER Dan (d2718) <dx2718@gmail.com>

RUN apt update && \
    apt install -y libssl-dev libcurl4-openssl-dev unixodbc-dev libxml2-dev \
                   libv8-dev && \
    R -e 'install.packages(c("dplyr", "ggplot2", "shiny", "tibble"))' && \
    rm -rf /srv/shiny-server/*

COPY app.R /srv/shiny-server/
COPY viral.csv /srv/shiny-server/
COPY hospital.csv /srv/shiny-server

USER shiny
EXPOSE 3838

ENV APPLICATION_LOGS_TO_STDOUT=true
ENV SHINY_LOG_STDERR=1
CMD ["/usr/bin/shiny-server"]

FROM rocker/verse:4.2.2

LABEL maintainer "Are Edvardsen <are.edvardsen@helse-nord.no>"

ENV DEBIAN_FRONTEND noninteractive

# system libraries of general use
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    locales \
    locales-all \
    default-mysql-client \
    netcat-openbsd \
    tzdata \
    libgit2-dev \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libxml2-dev \
    libssl-dev \
    libmariadb-dev \
    libmariadb-dev-compat \
    libharfbuzz-dev \
    libfribidi-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# testing: shiny-server just do not get anything but locale C
RUN locale-gen nb_NO.UTF-8

# System locales
ENV LANG=nb_NO.UTF-8
ENV LC_ALL=nb_NO.UTF-8
ENV LC_TIME nb_NO.UTF-8
RUN echo "LANG=\"nb_NO.UTF-8\"" > /etc/default/locale
ENV TZ=Europe/Oslo

# making proxy def (and other env vars) go all the way into Rstudio
# console, based on
# https://github.com/rocker-org/rocker-versioned/issues/91
ARG USERID=
ENV USERID=${USERID}

ARG PROXY=
ENV http_proxy=${PROXY}
ENV https_proxy=${PROXY}

ARG INSTANCE=DEV
ENV R_RAP_INSTANCE=${INSTANCE}

ARG DB_HOST=db
ENV DB_HOST=${DB_HOST}

ARG DB_USER=root
ENV DB_USER=${DB_USER}

ARG DB_PASS=root
ENV DB_PASS=${DB_PASS}

ARG CONFIG_PATH=/home/rstudio/rap_config
ENV R_RAP_CONFIG_PATH=${CONFIG_PATH}
RUN mkdir -p ${CONFIG_PATH} \
    && chmod ugo+rwx ${CONFIG_PATH}

# add rstudio user to root group  and enable shiny server
ENV ROOT=TRUE
## for R v 3.x.x
#RUN export ADD=shiny && bash /etc/cont-init.d/add
## for R v >= 4.0.0
RUN /rocker_scripts/install_shiny_server.sh \
    && rm /srv/shiny-server/index.html \
    && rm -rf /srv/shiny-server/sample-apps

ADD --chown=root:root rapShinyApps.tar.gz /srv/shiny-server/

## provide users rstudio and shiny with corresponding environmental settings, install and config
RUN touch /home/rstudio/.Renviron \
    && echo "TZ=${TZ}" > /home/rstudio/.Renviron \
    && echo "http_proxy=${PROXY}" >> /home/rstudio/.Renviron \
    && echo "https_proxy=${PROXY}" >> /home/rstudio/.Renviron \
    && echo "R_RAP_INSTANCE=${INSTANCE}" >> /home/rstudio/.Renviron \
    && echo "R_RAP_CONFIG_PATH=${CONFIG_PATH}" >> /home/rstudio/.Renviron \
    && echo "DB_HOST=${DB_HOST}" >> /home/rstudio/.Renviron \
    && echo "DB_USER=${DB_USER}" >> /home/rstudio/.Renviron \
    && echo "DB_PASS=${DB_PASS}" >> /home/rstudio/.Renviron \
    && touch /home/shiny/.Renviron \
    && echo "TZ=${TZ}" > /home/shiny/.Renviron \
    && echo "http_proxy=${PROXY}" >> /home/shiny/.Renviron \
    && echo "https_proxy=${PROXY}" >> /home/shiny/.Renviron \
    && echo "R_RAP_INSTANCE=${INSTANCE}" >> /home/shiny/.Renviron \
    && echo "R_RAP_CONFIG_PATH=${CONFIG_PATH}" >> /home/shiny/.Renviron \
    && echo "DB_HOST=${DB_HOST}" >> /home/shiny/.Renviron \
    && echo "DB_USER=${DB_USER}" >> /home/shiny/.Renviron \
    && echo "DB_PASS=${DB_PASS}" >> /home/shiny/.Renviron \
    && R -e "install.packages(c('remotes', 'lifecycle', 'testthat', 'rapbase'), repos='https://cloud.r-project.org/')" \
    && R -e "file.copy(system.file(c('dbConfig.yml', 'rapbaseConfig.yml', 'autoReport.yml'), package = 'rapbase'), Sys.getenv('R_RAP_CONFIG_PATH'))" \
    && touch ${CONFIG_PATH}/appLog.csv \
    && touch ${CONFIG_PATH}/reportLog.csv \
    && chown rstudio:rstudio ${CONFIG_PATH}/* \
    && chmod ugo+rw ${CONFIG_PATH}/* \
    && tlmgr update --self --all \
    && tlmgr install \
      hyphen-norwegian \
      collection-langeuropean \
      datetime \
      fmtcount \
      sectsty \
      marginnote \
      microtype \
      babel-norsk \
      lato \
      fontaxes \
      caption \
      fancyhdr \
      lastpage \
      textpos \
      titlesec \
      framed \
      ragged2e \
      ucs \
      subfig \
      eso-pic \
      grfext \
      oberdiek \
      pdfpages \
      pdflscape \
      bigintcalc \
      bitset \
      etexcmds \
      gettitlestring \
      hycolor \
      hyperref \
      intcalc \
      kvdefinekeys \
      kvsetkeys \
      letltxmacro \
      ltxcmds \
      pdfescape \
      refcount \
      rerunfilecheck \
      stringenc \
      uniquecounter \
      zapfding \
      float \
      booktabs \
      etoolbox \
      amsmath \
      latex-amsmath-dev \
      xcolor \
      geometry \
      epstopdf-pkg

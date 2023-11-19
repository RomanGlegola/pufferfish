FROM archlinux:latest

LABEL maintainer="Roman Glegoła"
LABEL description="Open Source docker pentest environment"

# Environment Variables
ENV HOME /home/based
ENV OPT /opt

ENV LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive


# Create a non-root user
RUN useradd -m based \
    && echo "based:based" | chpasswd \
    && usermod -aG wheel based \
    && mkdir -p /etc/sudoers.d \
    && echo 'based ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/based \
    && chmod 0440 /etc/sudoers.d/based \
    && chown -R based:based /home/based \
    && chmod -R 755 /home/based

RUN mkdir -p /home/based/.config/fish \
    && mkdir -p /home/based/.local/share/fish \
    && chown -R based:based /home/based \
    && chmod -R 755 /home/based/.local \
    && chown -R based:based /home/based/.config \
    && chown -R based:based /home/based/.local/share

# Install Essentials
RUN pacman -Syy --noconfirm \
    sudo \
    base-devel \ 
    tmux \
    inetutils \
    curl \
    wget \
    git \
    aws-cli \
    dnsutils \
    net-tools \
    nmap \
    tzdata \
    make \
    whois \
    nikto \
    fish \
    nano \
    vim \
    libffi \
    htop \
    iftop \
    ncdu \
    tar \
    zstd \
    && yes | pacman -Scc


# Install Programming Languages
RUN pacman -Syy --noconfirm \
    gcc \
    python \
    python3 \
    python-setuptools \
    python-requests \
    python-flask \
    python-pip \
    python-pipx \
    python-pycurl \
    python-dnspython \
    python-pywal \
    jupyter-notebook \
    ruby \
    ruby-bundler \
    perl \
    cpanminus \
    go \
    && yes | pacman -Scc

# Install Dependencies
RUN pacman -Syy --noconfirm \
    sqlmap # webapp \
    masscan \
    hydra \
    powerline \
    openssh \
    openvpn \
    expac \
    yajl \
    imagemagick \
    wireshark-qt \
    wireshark-cli \
    termshark \
    tcpdump \
    metasploit \
    john \
    hashcat \
    && yes | pacman -Scc


# Set timezone to "Europe/Warsaw"
RUN ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime \
    && echo "Europe/Warsaw" > /etc/timezone 

# Volume Declaration for Persistent Data
VOLUME ["/home/based/storage"]
RUN chown -R based:based /opt && chmod -R 755 /opt

# Create necessary directories
RUN mkdir -p ${HOME}/toolkit && \
    mkdir -p ${HOME}/wordlists

# Expose needed ports
EXPOSE 22/tcp
EXPOSE 8080/tcp

# Set operable environment
ENV DISPLAY=:0

# Set Fish as default shell
SHELL ["/usr/bin/fish", "-c"]

# Set PATH for global access to Perl tools and scripts
ENV PATH="/usr/bin/vendor_perl:${PATH}"

# Install Perl modules
RUN pacman -Sy --noconfirm cpanminus \
    && yes | pacman -Scc \
    && cpanm String::Random \
    && cpanm Net::IP \
    && cpanm Net::DNS \
    && cpanm Net::Netmask \
    && cpanm XML::Writer

# # Install dnsenum
# RUN chmod +x /opt/dnsenum/dnsenum.pl && \
#     ln -s /opt/dnsenum/dnsenum.pl /usr/bin/dnsenum && \
#     cd /opt/dnsenum/ && \
#     cpanm String::Random && \
#     cpanm Net::IP && \
#     cpanm Net::DNS && \
#     cpanm Net::Netmask && \
#     cpanm XML::Writer

# Switch to non-root user
USER based
WORKDIR /home/based

# Set PATH to include local gem bin directory
ENV GEM_HOME=${OPT}/gems
ENV BUNDLE_PATH=$GEM_HOME
ENV PATH=$GEM_HOME/bin:$PATH

# Install yay
RUN cd ${OPT} \
    && git clone https://aur.archlinux.org/yay.git \
    && cd yay \
    && yes | makepkg -si

RUN cd ${OPT} \
    git clone https://aur.archlinux.org/dnsenum2.git \
    && cd dnsenum2 \
    && makepkg -si --noconfirm

# Install dnsenum
RUN cd ${OPT} \
    && git clone https://github.com/SparrowOchon/dnsenum2.git \
    && cd dnsenum2 \
    && make && make install

# Install LinEnum
RUN cd ${OPT} \
    && git clone https://github.com/rebootuser/LinEnum.git

# Install linuxprivchecker
RUN cd ${OPT} \
    && git clone https://github.com/sleventyeleven/linuxprivchecker.git

# Install PEASS-ng
RUN cd ${OPT} \
    && git clone https://github.com/carlospolop/PEASS-ng.git

# Install PowerSploit
RUN cd ${OPT} \
    && git clone https://github.com/PowerShellMafia/PowerSploit.git

# Install Inveigh
RUN cd ${OPT} \
    && git clone https://github.com/Kevin-Robertson/Inveigh.git

# Install BloodHound
RUN cd ${OPT} \
    && git clone https://github.com/BloodHoundAD/BloodHound.git

# Install Seatbelt
RUN cd ${OPT} \
    && git clone https://github.com/GhostPack/Seatbelt.git

# Install JAWS
RUN cd ${OPT} \
    && git clone https://github.com/411Hall/JAWS.git

# Install Sublist3r
RUN cd ${OPT} \
    && git clone https://github.com/aboul3la/Sublist3r.git \
    && cd Sublist3r/ \
    && python -m venv ${OPT}/venvs/sublist3r \
    && source ${OPT}/venvs/sublist3r/bin/activate \
    && pip install -r requirements.txt 
USER root
RUN ln -s ${OPT}/Sublist3r/sublist3r.py /usr/local/bin/sublist3r
USER based

# Install wfuzz
RUN python -m venv ${OPT}/venvs/wfuzz \
    && source ${OPT}/venvs/wfuzz/bin/activate \
    && pip install wfuzz

# Install knock
RUN cd ${OPT} \
    && git clone https://github.com/guelfoweb/knock.git \
    && cd knock \
    && python -m venv ${OPT}/venvs/knock \
    && source ${OPT}/venvs/knock/bin/activate \
    && pip install -r requirements.txt \
    && chmod +x ${OPT}/knock/knockpy.py
ENV PATH="${OPT}/knock:${PATH}"

# Install massdns
RUN cd ${OPT} \
    && git clone https://github.com/blechschmidt/massdns.git \
    && cd massdns/ \
    && make
USER root
RUN ln -sf ${OPT}/massdns/bin/massdns /usr/local/bin/massdns
USER based

# Install wafw00f
RUN cd ${OPT} \
    && git clone https://github.com/enablesecurity/wafw00f.git \
    && cd wafw00f \
    && python -m venv ${OPT}/venvs/wafw00f \
    && source ${OPT}/venvs/wafw00f/bin/activate \
    && python setup.py install
ENV PATH="${OPT}/venvs/wafw00f/bin:${PATH}"

# Install wpscan
RUN cd ${OPT} \
    && git clone https://github.com/wpscanteam/wpscan.git \
    && cd wpscan/ \
    && gem install bundler && bundle install --without test \
    && gem install wpscan

# Install commix 
RUN cd ${OPT} \
    && git clone https://github.com/commixproject/commix.git \
    && cd commix \
    && chmod +x commix.py
USER root
RUN ln -sf ${OPT}/commix/commix.py /usr/local/bin/commix
USER based

# Install masscan
RUN cd ${OPT} \
    && git clone https://github.com/robertdavidgraham/masscan.git \
    && cd masscan \
    && make
USER root
RUN ln -sf ${OPT}/masscan/bin/masscan /usr/local/bin/masscan    
USER based

# Install altdns
RUN cd ${OPT} \
    && git clone https://github.com/infosec-au/altdns.git \
    && cd altdns \
    && python -m venv ${OPT}/venvs/altdns \
    && source ${OPT}/venvs/altdns/bin/activate \
    && pip install -r requirements.txt \
    && python setup.py install

# Install teh_s3_bucketeers
RUN cd ${OPT} \
    && git clone https://github.com/tomdev/teh_s3_bucketeers.git \
    && cd teh_s3_bucketeers \
    && chmod +x bucketeer.sh
USER root
RUN ln -sf ${OPT}/teh_s3_bucketeers/bucketeer.sh /usr/local/bin/bucketeer
USER based

# Install Recon-ng
RUN cd ${OPT} \
    && git clone https://github.com/lanmaster53/recon-ng.git \
    && cd recon-ng \
    && python -m venv ${OPT}/venvs/Recon-ng \
    && source ${OPT}/venvs/Recon-ng/bin/activate \
    && pip install -r REQUIREMENTS \
    && chmod +x recon-ng
USER root
RUN ln -sf ${OPT}/recon-ng/recon-ng /usr/local/bin/recon-ng
USER based

# Install XSStrike
RUN cd ${OPT} \
    && git clone https://github.com/s0md3v/XSStrike.git \
    && cd XSStrike \
    && python -m venv ${OPT}/venvs/XSStrike \
    && source ${OPT}/venvs/XSStrike/bin/activate \
    && pip install -r requirements.txt \
    && chmod +x xsstrike.py
USER root
RUN ln -sf ${OPT}/XSStrike/xsstrike.py /usr/local/bin/xsstrike
USER based

# TODO Install theHarvester

# Install CloudFlair
RUN cd ${OPT} \
    && git clone https://github.com/christophetd/CloudFlair.git \
    && cd CloudFlair \
    && python -m venv ${OPT}/venvs/CloudFlair \
    && source ${OPT}/venvs/CloudFlair/bin/activate \
    && pip install -r requirements.txt \
    && chmod +x cloudflair.py
USER root
RUN ln -sf ${OPT}/CloudFlair/cloudflair.py /usr/local/bin/cloudflair
USER based

# Install joomscan
RUN cd ${OPT} \
    && git clone https://github.com/rezasp/joomscan.git \
    && cd joomscan/ \
    && chmod +x joomscan.pl

# Install Go
USER root
RUN cd /tmp \
    && wget https://golang.org/dl/go1.21.4.linux-amd64.tar.gz \
    && tar -xvf go1.21.4.linux-amd64.tar.gz \
    && mv go /usr/local
USER based
ENV GOROOT /usr/local/go
ENV GOPATH /home/based/toolkit/go
ENV PATH ${GOPATH}/bin:${GOROOT}/bin:${PATH}

# Install S3Scanner
RUN cd ${OPT} \
    && go install -v github.com/sa7mon/s3scanner@latest

# Install subjack
RUN cd ${OPT} \
    && go install -v github.com/haccer/subjack@latest

# Install SubOver
RUN cd ${OPT} \
    && go install -v github.com/Ice3man543/SubOver@latest

# Install ffuf
RUN cd ${OPT} \
    && go install -v github.com/ffuf/ffuf@latest

# Install httprobe
RUN cd ${OPT} \
    && go install -v github.com/tomnomnom/httprobe@latest

# Install amass
RUN cd ${OPT} \
    && go install -v github.com/owasp-amass/amass/v3/...@latest

# waybackurls
RUN cd ${OPT} \
    && go install -v github.com/tomnomnom/waybackurls@latest

# Install subfinder
RUN cd ${OPT} \
    && go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

# Install gobuster
RUN cd ${OPT} \
    && go install -v github.com/OJ/gobuster/v3@latest

# Install virtual-host-discovery
RUN cd ${OPT} \
    && git clone https://github.com/AlexisAhmed/virtual-host-discovery.git \
    && cd virtual-host-discovery \
    && chmod +x scan.rb
USER root
RUN ln -sf ${OPT}/virtual-host-discovery/scan.rb /usr/local/bin/virtual-host-discovery
USER based

# Install bucket_finder
RUN cd ${OPT} \
    && git clone https://github.com/AlexisAhmed/bucket_finder.git \
    && cd bucket_finder \
    && chmod +x bucket_finder.rb
USER root
RUN ln -sf ${OPT}/bucket_finder/bucket_finder.rb /usr/local/bin/bucket_finder
USER based

# Install dirsearch
RUN cd ${OPT} \
    && git clone https://github.com/AlexisAhmed/dirsearch.git \
    && cd dirsearch \
    && chmod +x dirsearch.py
USER root
RUN ln -sf ${OPT}/dirsearch/dirsearch.py /usr/local/bin/dirsearch
USER based

# Install dnsrecon
RUN cd ${OPT} \
    && git clone https://github.com/darkoperator/dnsrecon.git \
    && cd dnsrecon \
    && python -m venv ${OPT}/venvs/dnsrecon \
    && source ${OPT}/venvs/dnsrecon/bin/activate \
    && pip install -r requirements.txt

# Install s3recon
RUN python -m venv ${OPT}/venvs/s3recon \
    && source ${OPT}/venvs/s3recon/bin/activate \
    && pip install --upgrade setuptools \
    && pip install pyyaml pymongo requests s3recon

# Install dotdotpwn
RUN cd ${OPT} \
    && cpanm Net::FTP \
    && cpanm Time::HiRes \
    && cpanm HTTP::Lite \
    && cpanm Switch \
    && cpanm Socket \
    && cpanm IO::Socket \
    && cpanm Getopt::Std \
    && cpanm TFTP \
    && git clone https://github.com/AlexisAhmed/dotdotpwn.git \
    && cd dotdotpwn \
    && chmod +x dotdotpwn.pl
USER root
RUN ln -sf ${OPT}/dotdotpwn/dotdotpwn.pl /usr/local/bin/dotdotpwn
USER based

# Install whatweb
RUN cd ${OPT} \
    && git clone https://github.com/urbanadventurer/WhatWeb.git \
    && cd WhatWeb \
    && chmod +x whatweb
USER root
RUN ln -sf ${OPT}/WhatWeb/whatweb /usr/local/bin/whatweb
USER based

# Install fierce
RUN python -m venv ${OPT}/venvs/fierce \
    && source ${OPT}/venvs/fierce/bin/activate \
    && pip install fierce

# Install droopsecan
RUN cd ${OPT} \
    && git clone https://github.com/droope/droopescan.git \
    && cd droopescan \
    && python -m venv ${OPT}/venvs/droopescan \
    && source ${OPT}/venvs/droopescan/bin/activate \
    && pip install -r requirements.txt

# gitGraber
RUN cd ${OPT} \
    && git clone https://github.com/hisxo/gitGraber.git \
    && cd gitGraber
USER root
RUN ln -sf ${OPT}/gitGraber/gitGraber.py /usr/local/bin/gitGraber
USER based

# Katoolin
RUN cd ${OPT} \
    && git clone https://github.com/LionSec/katoolin.git \
    && cd katoolin \
    && chmod +x katoolin.py

# Install RockYou2021 wordlists
RUN cd ${HOME}/wordlists \
    && git clone https://github.com/ohmybahgosh/RockYou2021.txt.git

# Install kalilinux wordlists
RUN cd ${HOME}/wordlists \
    && git clone https://gitlab.com/kalilinux/packages/wordlists.git

# Install seclists wordlists
RUN cd ${HOME}/wordlists \
    && git clone --depth 1 https://github.com/danielmiessler/SecLists.git 

# Compress wordlist
RUN cd ${HOME}/wordlists \
    && tar czf SecList.tar.gz ${HOME}/wordlists/SecLists/ \
    && rm -rf SecLists


# Autostart Fish at container boot up
ENTRYPOINT ["/usr/bin/fish"]



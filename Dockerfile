FROM library/ubuntu
#Install various helper tools and Salesforce DX CLI
RUN apt-get update && \
  apt-get -y install wget && \
  apt-get -y install curl && \
  apt-get -y install jq && \
  apt-get -y install xz-utils && \
  apt-get -y install perl && \
  apt-get -y install unzip && \
  apt-get -y install bzip2 && \
  apt-get -y install git && \
  apt-get -y install ant && \
  apt-get -y install gnupg2;

#Now that DX is installed and ready to go, need to install Java (eww),
#because things like running jasmine and mocha unit tests depend on Java.
# This is in accordance to : https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-get-on-ubuntu-16-04
RUN apt-get install -y openjdk-8-jdk && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer;

# Fix certificate issues, found as of
# https://bugs.launchpad.net/ubuntu/+source/ca-certificates-java/+bug/983302
RUN apt-get update && \
  apt-get install -y ca-certificates-java && \
  apt-get clean && \
  update-ca-certificates -f && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer;

# Setup JAVA_HOME, this is useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

#Gradle
ENV GRADLE_VERSION 2.14
RUN cd && \
  wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
  unzip -q gradle-${GRADLE_VERSION}-bin.zip && \
  mv gradle-${GRADLE_VERSION} /opt/gradle && \
  rm gradle-${GRADLE_VERSION}-bin.zip
ENV GRADLE_HOME /opt/gradle
ENV PATH ${PATH}:/opt/gradle/bin

#Installing PhantomJS
#Installing Dependencies
ENV PHANTOM_JS phantomjs-2.1.1-linux-x86_64
RUN apt-get update && \
  apt-get install -y build-essential chrpath libssl-dev libxft-dev && \
  apt-get install -y libfreetype6 libfreetype6-dev && \
  apt-get install -y libfontconfig1 libfontconfig1-dev && \
  cd ~ && \
  wget -q https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
  mv phantomjs-2.1.1-linux-x86_64.tar.bz2 /usr/local/share/ && \
  cd /usr/local/share/ && \
  tar xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
  ln -sf /usr/local/share/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/share/phantomjs && \
  ln -sf /usr/local/share/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs && \
  ln -sf /usr/local/share/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/bin/phantomjs && \
  phantomjs --version

# Install Python.
RUN \
  apt-get update && \
  apt-get install -y python python-dev python-pip python-virtualenv && \
  rm -rf /var/lib/apt/lists/*

#Installing SonarQube Scanner
ARG SONAR_SCANNER_VERSION
ENV SONAR_SCANNER_VERSION=${SONAR_SCANNER_VERSION:-3.0.3.778}

ADD "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip" /
RUN unzip "sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip" \
  && rm /sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip \
  && mkdir -p /app

ENV PATH "/sonar-scanner-${SONAR_SCANNER_VERSION}-linux/bin:${PATH}"

#Install Node and NPM
ENV NODE_VERSION 8.15.1
RUN cd && \
  wget -q https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz && \
  tar -xf node-v${NODE_VERSION}-linux-x64.tar.xz && \
  mv node-v${NODE_VERSION}-linux-x64 /opt/node && \
  rm node-v${NODE_VERSION}-linux-x64.tar.xz
ENV PATH /opt/node/bin:${PATH}

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && apt-get -y install yarn

WORKDIR /app

# Change the global installation directory for Node
# See https://github.com/nodejs/node-gyp/issues/1236
RUN groupadd --gid 1000 node && \
  useradd --uid 1000 --gid node --shell /bin/bash --create-home node && \
  chmod -R 777 /app

USER node
RUN mkdir /home/node/.npm-global && \
  mkdir /home/node/.yarn && \
  yarn config set network-timeout "600000" && \
  yarn config set prefix "/home/node/.yarn"
ENV PATH ${PATH}:/home/node/.npm-global/bin:/home/node/.yarn/bin
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global

#Installing Gulp & VSCE
RUN yarn global add gulp vsce

# Installing Salesforce DX CLI
RUN yarn global add sfdx-cli && \
  sfdx force -h && \
  echo "------------------------------------"
  
# Set SFDX environment
ENV SFDX_AUTOUPDATE_DISABLE true
ENV SFDX_USE_GENERIC_UNIX_KEYCHAIN true
ENV SFDX_DOMAIN_RETRY 300

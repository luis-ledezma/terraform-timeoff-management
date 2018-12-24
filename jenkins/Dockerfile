FROM jenkins/jenkins:lts

ENV JAVA_OPTS '-Djenkins.install.runSetupWizard=false'

USER root
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

USER jenkins

RUN /usr/local/bin/install-plugins.sh git github ssh publish-over-ssh
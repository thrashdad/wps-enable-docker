FROM centos:7 as BUILD_WAS

MAINTAINER thrashdad

RUN yum clean all && yum makecache fast && yum -y update \
    && yum -y install wget unzip \
    && yum clean all

ARG URL

RUN mkdir /tmp
WORKDIR /tmp

######################### IBM Installation Manager ########################

# Install Installation Manager
RUN wget -q $URL/agent.installer.linux.gtk.x86_64_1.8.5001.20161016_1705.zip -O /tmp/IM.zip \
    && mkdir /tmp/im &&  unzip -qd /tmp/im /tmp/IM.zip \
    && /tmp/im/installc -acceptLicense -accessRights admin \
      -installationDirectory "/opt/IBM/InstallationManager"  \
      -dataLocation "/opt/IBM/var/InstallationManager" -showProgress \
    && rm -fr /tmp/IM.zip /tmp/im

############# IBM WebSphere Application Server Network Deployment #########

# Install IBM WebSphere Application Server ND v855
RUN wget -q $URL/WASND_v8.5.5_1of3.zip  -O /tmp/was1.zip \
    && wget -q $URL/WASND_v8.5.5_2of3.zip  -O /tmp/was2.zip \
    && wget -q $URL/WASND_v8.5.5_3of3.zip  -O /tmp/was3.zip \
    && mkdir /tmp/was  && unzip  -qd /tmp/was /tmp/was1.zip \
    && unzip  -qd /tmp/was /tmp/was2.zip \
    && unzip  -qd /tmp/was /tmp/was3.zip \
    && /opt/IBM/InstallationManager/eclipse/tools/imcl -showProgress \
      -acceptLicense  install com.ibm.websphere.ND.v85 \
      -repositories /tmp/was/repository.config  \
      -installationDirectory /opt/IBM/WebSphere/AppServer \
      -preferences com.ibm.cic.common.core.preferences.preserveDownloadedArtifacts=false \
    && rm -fr /tmp/was /tmp/was1.zip  /tmp/was2.zip   /tmp/was3.zip

###### IBM WebSphere Application Server Network Deployment Fixpack #######

# Install IBM WebSphere Application Server ND Fixpack v85512
RUN wget -q $URL/8.5.5-WS-WAS-FP012-part1.zip -O /tmp/wasfp1.zip \
    && wget -q $URL/8.5.5-WS-WAS-FP012-part2.zip -O /tmp/wasfp2.zip \
    && wget -q $URL/8.5.5-WS-WAS-FP012-part3.zip -O /tmp/wasfp3.zip \
    && mkdir /tmp/wasfp \
    && unzip  -qd /tmp/wasfp /tmp/wasfp1.zip  \
    && unzip -qd /tmp/wasfp /tmp/wasfp2.zip \
    && unzip -qd /tmp/wasfp /tmp/wasfp3.zip \
    && /opt/IBM/InstallationManager/eclipse/tools/imcl -showProgress \
      -acceptLicense  install com.ibm.websphere.ND.v85 \
      -repositories /tmp/wasfp/repository.config  \
      -installationDirectory /opt/IBM/WebSphere/AppServer \
      -preferences com.ibm.cic.common.core.preferences.preserveDownloadedArtifacts=false \
    && rm -fr /tmp/wasfp /tmp/wasfp1.zip /tmp/wasfp2.zip /tmp/wasfp3.zip

########################### Install Java SDK 7 ########################

RUN wget  $URL/WS_SDK_JAVA_TECH_7.0.6.1.zip -O /tmp/java7.zip \
    && mkdir /tmp/java7 \
    && unzip -qd /tmp/java7 /tmp/java7.zip  \
    && /opt/IBM/InstallationManager/eclipse/tools/imcl -showProgress \
       -acceptLicense install com.ibm.websphere.IBMJAVA.v70 \
       -repositories /tmp/java7/IBMJAVA7/repository.config \
       -installationDirectory /opt/IBM/WebSphere/AppServer \
       -preferences com.ibm.cic.common.core.preferences.preserveDownloadedArtifacts=false \
    && rm -fr /tmp/java7 /tmp/java7.zip

CMD ["tar","cvf","/tmp/was.tar","/opt/IBM"]

FROM centos:7 as BUILD_PORTAL

COPY --from=BUILD_WAS /tmp/was.tar /

RUN yum clean all && yum makecache fast && yum -y update \
    && yum -y install wget unzip \
    && yum clean all

ARG HOST_NAME

ARG URL

RUN mkdir /tmp

# Install IBM WebSphere Portal 8.5
COPY portal_response.xml portal_cf_response.xml /tmp/

RUN wget -q $URL/WSP_Enable_8.5_Setup.zip -O /tmp/wcm.zip \
    && wget -q $URL/WSP_Server_8.5_Install.zip -O /tmp/server.zip \
    && wget -q $URL/WSP_Enable_8.5_Install.zip -O /tmp/wcm_install.zip \
    && mkdir /tmp/portal \
    && unzip -qd /tmp/portal /tmp/wcm.zip \
    && unzip -qd /tmp/portal /tmp/server.zip \
    && unzip -qd /tmp/portal /tmp/wcm_install.zip \

# Set hostname in /etc/hosts
    && echo $(tail -1 /etc/hosts | cut -f1) $HOST_NAME >> /etc/hosts \

# Execute IIM
    && /opt/IBM/InstallationManager/eclipse/tools/imcl input /tmp/portal_response.xml \
      -showProgress \
      -acceptLicense \

# Stop JVMs
    && /opt/IBM/WebSphere/wp_profile/bin/stopServer.sh WebSphere_Portal \
       -username wpsadmin \
       -password wpsadmin \
    && /opt/IBM/WebSphere/AppServer/profiles/cw_profile/bin/stopServer.sh server1 \
       -username wpsadmin \
       -password wpsadmin \

# Install IBM WebSphere Portal 8.5 CF15
    && wget -q $URL/8.5-9.0-WP-WCM-Combined-CFPI83476-Server-CF15.zip -O /tmp/portal_cf.zip \
    && mkdir /tmp/portal_cf \
    && unzip -qd /tmp/portal_cf /tmp/portal_cf.zip \
    && unzip -qd /tmp/portal_cf /tmp/portal_cf/WP8500CF12_Server.zip \
    && /opt/IBM/InstallationManager/eclipse/tools/imcl input /tmp/portal_cf_response.xml \
       -showProgress \
       -acceptLicense \
    && rm -fr /tmp/portal_cf* \
    && rm -fr /tmp/portal* \
    && rm -fr /tmp/wcm.zip /tmp/server.zip \
    && rm -fr /opt/IBM/WebSphere/wp_profile/wstemp/* \
    && rm -fr /opt/IBM/WebSphere/wp_profile/temp/* \
    && rm -fr /opt/IBM/WebSphere/wp_profile/logs/* \
    && rm -fr /opt/IBM/WebSphere/wp_profile/tranlog/* \
    && rm -fr /opt/IBM/WebSphere/AppServer/profiles/cw_profile/wstemp/* \
    && rm -fr /opt/IBM/WebSphere/AppServer/profiles/cw_profile/temp/* \
    && rm -fr /opt/IBM/WebSphere/AppServer/profiles/cw_profile/logs/* \
    && rm -fr /opt/IBM/WebSphere/AppServer/profiles/cw_profile/tranlog/*

# Apply CF
RUN echo $(tail -1 /etc/hosts | cut -f1) $HOST_NAME >> /etc/hosts \
    && /opt/IBM/WebSphere/wp_profile/PortalServer/bin/applyCF.sh \
       -DPortalAdminPwd=wpsadmin \
       -DWasPassword=wpsadmin \
    && rm -fr /opt/IBM/WebSphere/wp_profile/wstemp/* \
    && rm -fr /opt/IBM/WebSphere/wp_profile/temp/* \
    && rm -fr /opt/IBM/WebSphere/wp_profile/logs/* \
    && rm -fr /opt/IBM/WebSphere/wp_profile/tranlog/* \
    && rm -fr /opt/IBM/WebSphere/AppServer/profiles/cw_profile/wstemp/* \
    && rm -fr /opt/IBM/WebSphere/AppServer/profiles/cw_profile/temp/* \
    && rm -fr /opt/IBM/WebSphere/AppServer/profiles/cw_profile/logs/* \
    && rm -fr /opt/IBM/WebSphere/AppServer/profiles/cw_profile/tranlog/*

CMD ["tar","cvf","/tmp/portal.tar","/opt/IBM/WebSphere"]

FROM centos:7
MAINTAINER thrashdad
COPY --from=BUILD_PORTAL /tmp/portal.tar /
COPY startPortal.sh /work/
ENV PATH /opt/IBM/WebSphere/wp_profile/bin:$PATH
EXPOSE 10200 10038 10039 10041 10042 10032 10022 10013 10014 10015 10028 10020
CMD ["/work/startPortal.sh"]

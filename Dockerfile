# Use official Ubuntu 18.04 base image
FROM ubuntu:18.04

# Install prerequisites
# - curl: download ModusToolbox.tar.gz
# - libglib2.0-0: Qt tools depend on libgthread shared library
# - libssl1.0.0: Project Creator depends on OpenSSL 1.0.2
# - libgl1-mesa-glx: Qt tools are linked against libGL.so.1
# - make: Project Creator CLI runs "make get_tool_info"
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update -y && apt install -y curl libglib2.0-0 libssl1.0.0 libgl1-mesa-glx make && apt clean

# Download and extract released ModusToolbox packages
# Delete all tools except project-creator, proxy-helper, make and modus-shell
RUN cd /tmp \
 && curl -LsSfO https://download.cypress.com/downloadmanager/WICED_MODUS/P-ModusToolbox_2.0.0.1703-linux-install.tar.gz \
 && curl -LsSfO http://dlm.cypress.com.edgesuite.net/akdlm/downloadmanager/software/ModusToolbox/ModusToolbox_2.1/ModusToolbox_2.1.0.1266-linux-install.tar.gz \
 && curl -LsSfO http://dlm.cypress.com.edgesuite.net/akdlm/downloadmanager/software/ModusToolbox/ModusToolbox_2.2/ModusToolbox_2.2.0.2801-linux-install.tar.gz \
 && curl -LsSfO http://dlm.cypress.com.edgesuite.net/akdlm/downloadmanager/software/ModusToolbox/ModusToolbox_2.3/ModusToolbox_2.3.0.4276-linux-install.tar.gz \
 && cat *.tar.gz | tar -C /opt -zxf - -i \
 && rm -f *.tar.gz \
 && find /opt/ModusToolbox -mindepth 1 -maxdepth 1 -not -name "tools_*" -exec rm -rf {} \; \
 && find /opt/ModusToolbox -mindepth 2 -maxdepth 2 -not \( -name project-creator -or -name proxy-helper -or -name make -or -name modus-shell \) -exec rm -rf {} \;

# Script validate.sh expects MTB install in $MTB_DIR
ENV MTB_DIR="/opt/ModusToolbox"

# Use script validate.sh as entrypoint
COPY validate.sh /validate.sh
ENTRYPOINT ["/validate.sh"]

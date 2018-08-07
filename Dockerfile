FROM quay.io/water-hole/ansible-operator

COPY ansible/ /opt/ansible/
COPY config.yaml /opt/ansible/config.yaml

RUN adduser ansible-operator
USER ansible-operator

FROM quay.io/water-hole/ansible-operator

COPY ansible/ /opt/ansible/
COPY watches.yaml /opt/ansible/watches.yaml

RUN adduser ansible-operator
USER ansible-operator

#!/bin/bash

echo "template vars are: LOGGLY_AUTH ${LOGGLY_AUTH}, LOGGLY_TAG ${LOGGLY_TAG}"

#echo "export LOGGLY_TAG=${LOGGLY_TAG}" >> ~/.bashrc
#echo "export LOGGLY_TAG=${LOGGLY_TAG}" >> /etc/profile

#LOGGLY_TAG
LOGGLY_CONFIG="/etc/rsyslog.d/22-loggly.conf"

sudo cat >$LOGGLY_CONFIG <<EOF
# Setup disk assisted queues
\$WorkDirectory /var/spool/rsyslog # where to place spool files
\$ActionQueueFileName fwdRule1   # unique name prefix for spool files
\$ActionQueueMaxDiskSpace 1g    # 1gb space limit (use as much as possible)
\$ActionQueueSaveOnShutdown on   # save messages to disk on shutdown
\$ActionQueueType LinkedList    # run asynchronously
\$ActionResumeRetryCount -1    # infinite retries if host is down

template(name="LogglyFormat" type="string"
 string="<%pri%>%protocol-version% %timestamp:::date-rfc3339% %HOSTNAME% %app-name% %procid% %msgid% [036c956d-b860-46b9-b0db-2305f53659f6@41058 tag=\"${LOGGLY_TAG}\"] %msg%\n")

# Send messages to Loggly over TCP using the template.
action(type="omfwd" protocol="tcp" target="logs-01.loggly.com" port="514" template="LogglyFormat")
EOF


sudo service rsyslog restart

#force deploy to fail.. I hope?
#exit 2
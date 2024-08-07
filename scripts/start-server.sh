#!/bin/bash
echo "-----------------------------------------------------"
echo "| This container is deprecated, please use:"
echo "| https://github.com/flavienbwk/apt-mirror-docker"
echo "| or a similar container instead."
echo "|"
echo "| The container start will continue in 60 seconds..."
echo "-----------------------------------------------------"
echo

sleep 60

if [ ! -f ${CONFIG_DIR}/postmirror.sh ]; then
  echo "${MIRROR_DIR}/var/clean.sh" > ${CONFIG_DIR}/postmirror.sh
  if [ ! -d ${MIRROR_DIR}/var ]; then
    mkdir -p ${MIRROR_DIR}/var
  fi
  cp ${CONFIG_DIR}/postmirror.sh  ${MIRROR_DIR}/var/postmirror.sh
  chmod +x ${MIRROR_DIR}/var/postmirror.sh
else
  if [ ! -d ${MIRROR_DIR}/var ]; then
    mkdir -p ${MIRROR_DIR}/var
  fi
  cp ${CONFIG_DIR}/postmirror.sh  ${MIRROR_DIR}/var/postmirror.sh
  chmod +x ${MIRROR_DIR}/var/postmirror.sh
fi
if [ "$(grep -E "set base_path         /var/spool/apt-mirror" ${CONFIG_DIR}/mirror.list)" ]; then
  sed -i "/set base_path         \/var\/spool\/apt-mirror/c\set base_path         ${MIRROR_DIR}" ${CONFIG_DIR}/mirror.list
  chmod -R 777 ${CONFIG_DIR}/
  chown -R ${UID}:${GID} ${CONFIG_DIR}/
  echo "---Please edit your 'mirror.list' file in your conig directory and restart the container when done!---"
  sleep infinity
fi
chmod -R 777 ${CONFIG_DIR}/
chown -R ${UID}:${GID} ${CONFIG_DIR}/
if [ -z "$(ls -I "var" -A ${MIRROR_DIR})" ]; then
  echo "---Starting first mirror---"
  apt-mirror ${CONFIG_DIR}/mirror.list
  exit 0
fi
if [ ! -d ${MIRROR_DIR}/mirror/$(ls ${MIRROR_DIR}/mirror/ 2>/dev/null)/ubuntu ]; then
  echo "---Something went horribly wrong, can't find the mirror directory!---"
  sleep infinity
else
  if [ ! -d /var/www/ubuntu ]; then
    ln -s ${MIRROR_DIR}/mirror/$(ls ${MIRROR_DIR}/mirror/)/ubuntu /var/www/ubuntu
  fi
fi

if [ "${FORCE_UPDATE}" == "true" ]; then
  crontab -r 2>/dev/null
  echo "---Force update enabled!---"
  apt-mirror ${CONFIG_DIR}/mirror.list
fi
echo "${CRON_SCHEDULE} /usr/bin/apt-mirror ${CONFIG_DIR}/mirror.list" > ${CONFIG_DIR}/cron
sleep 1
crontab ${CONFIG_DIR}/cron
echo "---'apt-mirror' will be run on the following cron schedule: ${CRON_SCHEDULE}---"
echo "---Mirror started!---"
echo "---Add the following line to your '/etc/apt/sources.list' file on your ubuntu installation:---"
echo "deb http://IPFROMTECONTAINER:${APACHE2_PORT}/ubuntu stable main contrib non-free"
echo "---Don't forget to change 'IPFROMTECONTAINER' and also change the repositories to match your config!---"
sleep infinity
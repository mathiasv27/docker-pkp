#!/bin/bash

echo "================= SPECIFIC ACTIONS =================="
echo "SERVERNAME:      [${SERVERNAME}]"
echo "OJS_CONF:        [${OJS_CONF}]"
echo "OJS_WEB_CONF:    [${OJS_WEB_CONF}]"
echo "OJS_CLI_INSTALL: [${OJS_CLI_INSTALL}]"
echo "====================================================="

echo "Get plugins from UB"

GENERIC_PLUGIN_ARRAY=($GIT_UB_PLUGINS_GENERIC)
BLOCKS_PLUGIN_ARRAY=($GIT_UB_PLUGINS_BLOCKS)
THEMES_ARRAY=($GIT_UB_THEMES)

for p in "${GENERIC_PLUGIN_ARRAY[@]}"; do
  cd $WEB_PATH
  cd plugins/generic
  if [ ! -d $WEB_PATH/plugins/$p ]; then
    echo "Get plugin $p"
    git clone --branch develop https://git:${GIT_UB_ACCESS_TOKEN}@${GIT_UB_URL}/plugins/${p}.git
  else
    echo "Plugin $p already exists"
  fi

done

for p in "${BLOCKS_PLUGIN_ARRAY[@]}"; do
  cd $WEB_PATH
  cd plugins/blocks
  if [ ! -d $WEB_PATH/plugins/$p ]; then
    echo "Get plugin $p"
    git clone --branch develop https://git:${GIT_UB_ACCESS_TOKEN}@${GIT_UB_URL}/plugins/${p}.git
  else
    echo "Plugin $p already exists"
  fi
done

for p in "${THEMES_ARRAY[@]}"; do
  cd $WEB_PATH
  cd plugins/themes
  if [ ! -d $p ]; then
    echo "Get theme $p"
    git clone --branch develop https://git:${GIT_UB_ACCESS_TOKEN}@${GIT_UB_URL}/themes/${p}.git
  else
    echo "Theme $p already exists"
  fi
done

echo "Replacing lines in $OJS_CONF ..."

sed -i -e "s/^[ ;]*installed[ =]*.*/installed = On/g" $OJS_CONF
sed -i -e "s/^[ ;]*restful_urls[ =]*.*/restful_urls = ${OJS_RESTFUL_URLS}/g" $OJS_CONF
sed -i -e "s/^[ ;]*scheduled_tasks[ =]*.*/scheduled_tasks = ${OJS_SCHEDULED_TASKS}/g" $OJS_CONF
sed -i -e "s/^[ ;]*date_format_long[ =]*.*/date_format_long = \"${OJS_DATE_FORMAT_LONG}\"/g" $OJS_CONF
sed -i -e "s/^[ ;]*base_url[ =]*.*/base_url = https:\/\/${PROJECT_DOMAIN}/g" $OJS_CONF
sed -i -e "s/^[ ;]*trust_x_forwarded_for[ =]*.*/trust_x_forwarded_for = ${OJS_TRUST_X_FORWARDED_FOR}/g" $OJS_CONF
sed -i -e "s/^[ ;]*host[ =]*.*/host = ${OJS_DB_HOST}/g" $OJS_CONF
sed -i -e "s/^[ ;]*driver[ =]*.*/driver = ${OJS_DB_DRIVER}/g" $OJS_CONF
sed -i -e "s/^[ ;]*username[ =]*.*/username = ${OJS_DB_USER}/g" $OJS_CONF
sed -i -e "s/^[ ;]*password[ =]*.*/password = ${OJS_DB_PASSWORD}/g" $OJS_CONF
sed -i -e "s/^[ ;]*connection_charset[ =]*.*/connection_charset = ${OJS_CONNECTION_CHARSET}/g" $OJS_CONF
sed -i -e "s/^[ ;]*files_dir[ =]*.*/files_dir = ${OJS_FILES_DIR//\//\\\/}/g" $OJS_CONF
sed -i -e "s/^[ ;]*force_login_ssl[ =]*.*/force_login_ssl = ${OJS_FORCE_LOGIN_SSL}/g" $OJS_CONF
sed -i -e "s/^[ ;]*salt[ =]*.*/salt = \"${OJS_SALT}\"/g" $OJS_CONF
sed -i -e "s/^[ ;]*allowed_html[ =]*.*/allowed_html = \"${OJS_ALLOWED_HTML}\"/g" $OJS_CONF
sed -i -e "s/^[ ;]*smtp =.*/smtp = ${OJS_SMTP}/g" $OJS_CONF
sed -i -e "s/^[ ;]*smtp_server[ =]*.*/smtp_server = ${OJS_SMTP_SERVER}/g" $OJS_CONF
sed -i -e "s/^[ ;]*smtp_port[ =]*.*/smtp_port = ${OJS_SMTP_PORT}/g" $OJS_CONF
sed -i -e "s/^[ ;]*allow_envelope_sender[ =]*.*/allow_envelope_sender = ${OJS_ALLOW_ENVELOPE_SENDER}/g" $OJS_CONF
sed -i -e "s/^[ ;]*default_envelope_sender[ =]*.*/default_envelope_sender = ${OJS_DEFAULT_ENVELOPE_SENDER}/g" $OJS_CONF
sed -i -e "s/^[ ;]*force_default_envelope_sender[ =]*.*/force_default_envelope_sender = ${OJS_FORCE_DEFAULT_ENVELOPE_SENDER}/g" $OJS_CONF
sed -i -e "s/^[ ;]*force_dmarc_compliant_from[ =]*.*/force_dmarc_compliant_from = ${OJS_FORCE_DMARC_COMPLIANT_FROM}/g" $OJS_CONF
sed -i -e "s/^[ ;]*dmarc_compliant_from_displayname[ =]*.*/dmarc_compliant_from_displayname = \"${OJS_DMARC_COMPLIANT_FROM_DISPLAYNAME}\"/g" $OJS_CONF
sed -i -e "s/^[ ;]*require_validation[ =]*.*/require_validation = ${OJS_REQUIRE_VALIDATION}/g" $OJS_CONF
sed -i -e "s/^[ ;]*results_per_keyword[ =]*.*/results_per_keyword = ${OJS_RESULTS_PER_KEYWORD}/g" $OJS_CONF
sed -i -e "s/^[ ;]*repository_id[ =]*.*/repository_id = \"${OJS_REPOSITORY_ID}\"/g" $OJS_CONF
sed -i -e "s/^[ ;]*recaptcha[ =]*.*/recaptcha = ${OJS_RECAPTCHA}/g" $OJS_CONF
sed -i -e "s/^[ ;]*recaptcha_public_key[ =]*.*/recaptcha_public_key = ${OJS_RECAPTCHA_PUBLIC_KEY}/g" $OJS_CONF
sed -i -e "s/^[ ;]*recaptcha_private_key[ =]*.*/recaptcha_private_key = ${OJS_RECAPTCHA_PRIVATE_KEY}/g" $OJS_CONF

chown -R www-data:www-data $WEB_PATH
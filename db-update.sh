#!/usr/bin/env bash

CALLEDPATH=`dirname $0`

# Convert to an absolute path if necessary
case "$CALLEDPATH" in
  .*)
    CALLEDPATH="$PWD/$CALLEDPATH"
    ;;
esac

function _mysql_vars() {
  if [ -z $DBPASS ]; then # password still empty
    PASSWDSECTION=""
  else
    PASSWDSECTION="-p$DBPASS"
  fi

  HOSTSECTTION=""
  if [ ! -z "$DBHOST" ]; then
    HOSTSECTION="-h $DBHOST"
  fi

  PORTSECTION=""
  if [ ! -z "$DBPORT" ]; then
    PORTSECTION="-P $DBPORT"
  fi
}

function mysql_cmd() {
  _mysql_vars
  echo "mysql -u$DBUSER $PASSWDSECTION $HOSTSECTION $PORTSECTION $DBARGS $DBNAME"
}

function mysqldump_cmd() {
  _mysql_vars
  echo "mysqldump -u$DBUSER $PASSWDSECTION $HOSTSECTION $PORTSECTION $DBARGS"
}


source "$CALLEDPATH/setup.conf"

MYSQLCMD=$(mysql_cmd)
MYSQLDUMP=$(mysqldump_cmd)

echo "Creating mysqldump of drupal database and dumping at $PWD/$PRODDBNAME.mysql"
$MYSQLDUMP  $PRODDBNAME > "$PRODDBNAME.mysql"
sed -i 's/DEFINER=[^*]*\*/\*/g' "$PRODDBNAME.mysql"


echo "Creating mysqldump of civicrm database and dumping at $PWD/$PRODCIVIDBNAME.mysql"
$MYSQLDUMP $PRODCIVIDBNAME > "$PRODCIVIDBNAME.mysql"
sed -i 's/DEFINER=[^*]*\*/\*/g' "$PRODCIVIDBNAME.mysql"

echo "Dropping Drupal staging database"
$MYSQLCMD -e "DROP DATABASE $STAGDBNAME"

echo "Creating Drupal staging database"
$MYSQLCMD -e "CREATE DATABASE $STAGDBNAME"
$MYSQLCMD -e "GRANT ALL PRIVILEGES ON $STAGDBNAME.* TO '$STAGINGDBUSER'@'localhost'"

echo "Updating Drupal staging database\n"
$MYSQLDUMP $STAGDBNAME < "$PWD/$PRODDBNAME.mysql"

echo "Remove the prod Drupal DB mysqldump"
rm "$PWD/$PRODDBNAME.mysql"

echo "Dropping CiviCRM staging database"
$MYSQLCMD -e "DROP DATABASE $STAGCIVIDBNAME"

echo "Creating CiviCRM staging database"
$MYSQLCMD -e "CREATE DATABASE $STAGCIVIDBNAME"
$MYSQLCMD -e "GRANT ALL PRIVILEGES ON $STAGCIVIDBNAME.* TO '$STAGINGDBUSER'@'localhost'"

echo "Updating CiviCRM staging database"
$MYSQLDUMP $STAGCIVIDBNAME < "$PWD/$PRODCIVIDBNAME.mysql"

echo "Remove the prod CiviCRM DB mysqldump"
rm "$PWD/$PRODCIVIDBNAME.mysql"

echo; echo "NOTE: Logout from your CMS to avoid session conflicts."

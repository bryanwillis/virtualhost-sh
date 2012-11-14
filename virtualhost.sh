#!/bin/sh
#============================================ virtualhost.sh ============================================#
#                                                                                                        #
# A fancy little script to setup a new Apache virtualhost in Ubuntu.                                     #
# Based upon the excellent virtualhost (V1.29) script by Patrick Gibson <patrick@patrickg.com> for OS X  #
# and it's Ubuntu implementation by Bjorn Wijers <burobjorn@burobjorn.nl>                                #
#                                                                                                        #
# This script has been tested on Ubuntu 12.04 (Precise Pangolin) with Apache2 and probably works on      #
# Debian as well, but this has not been tested. If you use this script on other Linux distributions      #
# and can confirm it to work I would like to hear from you.                                              #
# Just send an email to Ivan Koptiev <ikoptev@gmail.com> with more info.                                 #
#                                                                                                        #
#                                                                                                        #
#============================================ USAGE EXAMPLES ============================================#
#                                                                                                        #    
# LIST EXISTING VIRTUAL HOSTS:                                                                           #
# sudo ./virtualhost --list                                                                              #
#                                                                                                        #
# CREATE A VIRTUAL HOST:                                                                                 #
# sudo ./virtualhost <name>                                                                              #
# where <name> is the one-word name you'd like to use. (e.g. mysite)                                     #
#                                                                                                        #
# REMOVE A VIRTUAL HOST:                                                                                 #
# sudo ./virtualhost --delete <site>                                                                     #
# where <site> is the site name you used when you first created the host.                                #
#                                                                                                        #
# ENABLE A VIRTUAL HOST:                                                                                 #
# sudo ./virtualhost --enable <site>                                                                     #
# where <site> is the site name you used when you first created the host.                                #
#                                                                                                        #
# DISABLE A VIRTUAL HOST:                                                                                #
# sudo ./virtualhost --disable <site>                                                                    #
# where <site> is the site name you used when you first created the host.                                #
#                                                                                                        #
# Note that if "virtualhost.sh" is not in your PATH, you will have to write                              #
# out the full path to where you've placed: eg. /usr/bin/virtualhost.sh <name>                           #
#                                                                                                        #
#                                                                                                        #
#========================================= SCRIPT CONFIGURATION =========================================#
#                                                                                                        #
# If you are using this script on a production machine with a static IP address, and you wish to setup   #
# a "live" virtualhost, you can change the following IP address to the IP address of your machine.       #
  IP_ADDRESS="127.0.0.1"                                                                                 #
                                                                                                         #
# By default, this script places files in /home/[you]/Sites. If you would like to change this,           #
# like to how Apache on Ubuntu does things by default, uncomment the following line:                     #
# DOC_ROOT_PREFIX="/var/www"                                                                             #
                                                                                                         #
# Configure the apache-related paths                                                                     #
  APACHE_CONFIG="/etc/apache2"                                                                           #
  APACHECTL="/usr/sbin/apache2ctl"                                                                       #
                                                                                                         #
# If you wish to change the default application that gets launched after the virtual host is created,    #
# define it here:                                                                                        #
  OPEN_COMMAND="/usr/bin/xdg-open"                                                                       #
                                                                                                         #
# If defined, a ServerAlias os $1.$WILDCARD_ZONE will be added to the virtual host file. This is useful  #
# if you, for example, have setup a wildcard domain either on your own DNS server or using a server      #
# like dyndns.org. For example, if my local IP of 10.0.42.42 is static (which can still be achieved      #
# using a well-configured DHCP server or an Apple Airport Extreme 802.11n base station) and I create a   #
# host on dyndns.org of patrickdev.dyndns.org with wildcard hostnames turned on, then defining my        #
# WILDCARD_ZONE to "patrickdev.dyndns.org" will enable access to my virtual host from any machine on     #
# the network. Note that this would also work with a public IP too, and the virtual hosts on your        #
# machine would be accessible to anyone on the internets.                                                #
# WILDCARD_ZONE="my.wildcard.host.address"                                                               #
                                                                                                         #
# A feature to specify a custom log location within your site's document root was requested, and so you  #
# will be prompted about this when you create a new virtual host. If you do not want to be prompted,     #
# set the following to "no":                                                                             #
  PROMPT_FOR_LOGS="no"                                                                                   #
                                                                                                         #
# If you do not want to be prompted, but you do always want to have the site-specific logs folder, set   #
# PROMPT_FOR_LOGS="no" and enable this:                                                                  #
  ALWAYS_CREATE_LOGS="yes"                                                                               #
                                                                                                         #
# By default, log files will be created in DOCUMENT_ROOT/logs. If you wish to override this to a static  #
# location, you can do so here.                                                                          #
# LOG_FOLDER="/var/log/httpd"                                                                            #
                                                                                                         #
# If you have an atypical setup, and you don't need or want entries in your /etc/hosts file, you can     #
# set the following option to "yes".                                                                     #
  SKIP_ETC_HOSTS="no"                                                                                    #
                                                                                                         #
# If you are running this script on a platform other than Ubuntu, your home maybe be different.          #
# If so, change it here.                                                                                 #
  HOME_PARTITION="/home"                                                                                 #
                                                                                                         #
# If your environment has a different default DocumentRoot, and you don't want to be nagged about        #
# "fixing" your DocumentRoot, set this to "yes".                                                         #
  SKIP_DOCUMENT_ROOT_CHECK="no"                                                                          #
                                                                                                         #
# If Apache works on a different port than the default 80, set it here                                   #
  APACHE_PORT="80"                                                                                       #
                                                                                                         #
# Batch mode (all prompting will assume Yes). Any value will activate this. Can be set here,             #
# in ~/.virtualhost.sh.conf, or on the command line, like: BATCH_MODE=yes virtualhost.sh mysite          #
# BATCH_MODE="yes"                                                                                       #
                                                                                                         #
# If you're satisfied with the version you have and do not wish to be reminded of a new version,         #
# add the following line to your ~/.virtualhost.sh.conf file.                                            #
# SKIP_VERSION_CHECK="yes"                                                                               #
                                                                                                         #
# We now will search your $DOC_ROOT_PREFIX for a matching subfolder using find. By default, we will      #
# go two levels deep so that it doesn't take too long. If you have a really complex structure,           #
# you may need to increase this.                                                                         #
  MAX_SEARCH_DEPTH=2                                                                                     #
                                                                                                         #
# Set to "yes" if you don't have a browser (headless) or don't want the site to be launched in your      #
# browser after the virtualhost is setup.                                                                #
# SKIP_BROWSER="yes"                                                                                     #
                                                                                                         #
# You can now store your configuration directions in a ~/.config/virtualhost.sh.conf file so that you    #
# can download new versions of the script without having to redo your own settings.                      #
  if [ -e ~/.config/virtualhost.sh.conf ]; then                                                          #
    . ~/.config/virtualhost.sh.conf                                                                      #
  fi                                                                                                     #
                                                                                                        #
#========================================================================================================#



#========================================================================================================#
#                                            CODE STARTS HERE                                            #
#--------------------------------------------------------------------------------------------------------#
#                     do not edit below this line unless you know what you are doing                     #
#========================================================================================================#

# Script version
version="1.29"

# No point going any farther if we're not running correctly...
if [ `whoami` != 'root' ]; then
  echo "virtualhost.sh requires super-user privileges to work."
  echo "Enter your password to continue..."
  sudo $0 $* || exit 1
  exit 0
fi

if [ "$SUDO_USER" = "root" ]; then
  /bin/echo "You must start this under your regular user account (not root) using sudo."
  /bin/echo "Rerun using: sudo $0 $*"
  exit 1
fi


#========================================================================================================#
# Declare some custom functions                                                                          #
#========================================================================================================#

# Print help page and usage examples TODO -> Update help text
usage()
{
  cat << __EOT
Usage: sudo virtualhost.sh <name>
       sudo virtualhost.sh --list
       sudo virtualhost.sh --delete <name>
   where <name> is the one-word name you'd like to use. (e.g. mysite)

   Note that if "virtualhost.sh" is not in your PATH, you will have to write
   out the full path to it: eg. /home/$USER/Desktop/virtualhost.sh <name>

__EOT
  exit 1
}

# Check whether host exists in the /etc/hosts
host_exists()
{
  if grep -q -e "^$IP_ADDRESS  $1$" /etc/hosts ; then
    return 0
  else
    return 1
  fi
}

# Create new virtual host
create_virtualhost()
{
  if [ ! -z $WILDCARD_ZONE ]; then
    SERVER_ALIAS="ServerAlias $1.$WILDCARD_ZONE"
  else
    SERVER_ALIAS="#ServerAlias your.alias.here"
  fi
  date=`/bin/date`
  if [ -z $3 ]; then
    log="#"
  else
    log=""
    if [ ! -z $LOG_FOLDER ]; then
      log_folder_path=$LOG_FOLDER
      access_log="${log_folder_path}/access_log-$1"
      error_log="${log_folder_path}/error_log-$1"
    else
      log_folder_path=$FOLDER/logs
      access_log="${log_folder_path}/access_log"
      error_log="${log_folder_path}/error_log"
    fi
    if [ ! -d "${log_folder_path}" ]; then
      mkdir -p "${log_folder_path}"
      chown $USER "${log_folder_path}"
    fi
    touch $access_log $error_log
    chown $USER $access_log $error_log
  fi
  cat << __EOF >$APACHE_CONFIG/virtualhosts/$1
# Created $date
<VirtualHost *:$APACHE_PORT>
  DocumentRoot "$2"
  ServerName $1
  ServerAlias www.$1
  $SERVER_ALIAS

  ScriptAlias /cgi-bin "$2/cgi-bin"

  <Directory "$2">
    Options All
    AllowOverride All
    Order allow,deny
    Allow from all
  </Directory>

  ${log}CustomLog "${access_log}" combined
  ${log}ErrorLog "${error_log}"

</VirtualHost>
__EOF
}

# Launch external command with host URL as a param
open_command()
{
  $OPEN_COMMAND "$@"
}

cleanup()
{
  /bin/echo
  /bin/echo "Cleaning up..."
  exit
}

# Based on FreeBSD's /etc/rc.subr
checkyesno()
{
  case $1 in
    #       "yes", "true", "on", or "1"
    [Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]|[Yy]|1)
    return 0
    ;;

    #       "no", "false", "off", or "0"
    [Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]|[Oo][Ff][Ff]|[Nn]|0)
    return 1
    ;;

    *)
    return 1
    ;;
  esac
}

version_check()
{
<<COMMENT1
  /bin/echo -n "Checking for updates... "
  current_version=`dig +tries=1 +time=1 +retry=0 txt virtualhost.patrickgibson.com | grep -e '^virtualhost' | awk '{print $5}' | sed -e 's/"//g'`

  # See if we have the latest version
  if [ -n "$current_version" ]; then
    testes=`/bin/echo "$version < $current_version" | /usr/bin/bc`

    if [ $testes -eq 1 ]; then
      /bin/echo "done"
      if [ -z $BATCH_MODE ]; then
        /bin/echo "A newer version ($current_version) of virtualhost.sh is available."
        /bin/echo -n "Do you want to get it now? [Y/n] "
        read resp
      else
        /bin/echo "A newer version ($current_version) of virtualhost.sh is available."
        /bin/echo "Visit https://github.com/pgib/virtualhost.sh to go get it."
        resp="n"
      fi

      case $resp in
      y*|Y*)
        open_command "https://github.com/pgib/virtualhost.sh"
        exit
      ;;

      *)
        /bin/echo "Okay. At your convenience, visit: https://github.com/pgib/virtualhost.sh"
        /bin/echo
      ;;
      esac
    else
      /bin/echo "none found"
    fi
  else
    /bin/echo "failed. Are you online?"
  fi
COMMENT1
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# Make sure that Apache is installed
if [ ! -d $APACHE_CONFIG ]; then
  /bin/echo "Could not find ${APACHE_CONFIG}"
  /bin/echo "Please, recheck your virtualhost.sh settings and try again."

  exit 1
fi

############################################ INVENT SOMETHING
if [ -z $SKIP_VERSION_CHECK ]; then
  version_check
fi

# catch Ctrl-C
#trap 'cleanup' 2

# restore it
#trap '' 2

# Resolve current user name
if [ -z $USER -o $USER = "root" ]; then
  if [ ! -z $SUDO_USER ]; then
    USER=$SUDO_USER
  else
    USER=""

    /bin/echo "ALERT! Your root shell did not provide your username."

    while : ; do
      if [ -z $USER ]; then
        while : ; do
          /bin/echo -n "Please enter *your* username: "
          read USER
          if [ -d $HOME_PARTITION/$USER ]; then
            break
          else
            /bin/echo "$USER is not a valid username."
          fi
        done
      else
        break
      fi
    done
  fi
fi

# Resolve document root
if [ -z $DOC_ROOT_PREFIX ]; then
  DOC_ROOT_PREFIX="${HOME_PARTITION}/$USER/Sites"
fi

# Parse given options
if [ -z $1 ]; then
  usage
else
  if [ "$1" = "--list" ] || [ "$1" = "-l" ]; then
    if [ -d $APACHE_CONFIG/sites-available ]; then
      echo "Listing virtualhosts found in $APACHE_CONFIG/sites-available"
      echo
      for i in $APACHE_CONFIG/sites-available/*; do
        server_name=`grep ServerName $i | awk '{print $2}'`
        doc_root=`grep DocumentRoot $i | awk '{print $2}' | sed -e 's/"//g'`
        echo "http://${server_name}/ -> ${doc_root}"
      done
    else
      echo "No virtualhosts have been setup yet."
    fi

    exit
  elif [ "$1" = "--delete" ] || [ "$1" = "-d" ]; then
    if [ -z $2 ]; then
      usage
    else
      VIRTUALHOST=$2
      DELETE=0
    fi
  elif [ "$1" = "--enable" ]; then
    if [ -z $2 ]; then
      usage
    else
      VIRTUALHOST=$2
      ENABLE=0
    fi
  elif [ "$1" = "--disable" ]; then
    if [ -z $2 ]; then
      usage
    else
      VIRTUALHOST=$2
      DISABLE=0
    fi
  else
    VIRTUALHOST=$1
  fi
fi

# Test that the virtualhost name is valid (starts with a number or letter)
if ! /bin/echo $VIRTUALHOST | grep -q -E '^[A-Za-z0-9]+' ; then
  /bin/echo "Sorry, '$VIRTUALHOST' is not a valid host name to use. It must start with a letter or number."
  exit 1
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Delete the virtualhost if that's the requested action
#
if [ ! -z $DELETE ]; then
  if host_exists $VIRTUALHOST ; then
    /bin/echo -n "- Deleting virtualhost, $VIRTUALHOST... Continue? [Y/n]: "

    if [ -z "$BATCH_MODE" ]; then
      read continue
    else
      continue="Y"
      /bin/echo $continue
    fi

    case $continue in
    n*|N*) exit
    esac

    if ! checkyesno ${SKIP_ETC_HOSTS}; then
      /bin/echo -n "  - Removing $VIRTUALHOST from /etc/hosts... "

      cat /etc/hosts | grep -v $VIRTUALHOST > /tmp/hosts.tmp

      if [ -s /tmp/hosts.tmp ]; then
        mv /tmp/hosts.tmp /etc/hosts
      fi
      /bin/echo "done"
    fi

    if [ -e $APACHE_CONFIG/virtualhosts/$VIRTUALHOST ]; then
      DOCUMENT_ROOT=`grep DocumentRoot $APACHE_CONFIG/virtualhosts/$VIRTUALHOST | awk '{print $2}' | tr -d '"'`

      if [ -d $DOCUMENT_ROOT ]; then
        /bin/echo -n "  + Found DocumentRoot $DOCUMENT_ROOT. Delete this folder? [y/N]: "

        if [ -z $BATCH_MODE ]; then
          read resp
        else
          resp="n"
          echo $resp
        fi

        case $resp in
        y*|Y*)
          /bin/echo -n "  - Deleting folder... "
          if rm -rf "${DOCUMENT_ROOT}" ; then
            /bin/echo "done"
          else
            /bin/echo "Could not delete $DOCUMENT_ROOT"
          fi
        ;;
        esac
      fi

      LOG_FILES=`grep "CustomLog\|ErrorLog" $APACHE_CONFIG/virtualhosts/$VIRTUALHOST | awk '{print $2}' | tr -d '"'`
      if [ ! -z "$LOG_FILES" ]; then
        /bin/echo -n "  + Delete logs? [y/N]: "

        if [ -z BATCH_MODE ]; then
          read resp
        else
          resp="n"
          echo $resp
        fi

        case $resp in
        y*|Y*)
          /bin/echo -n "  - Deleting logs... "
          if rm -f ${LOG_FILES} ; then
            /bin/echo "done"
          else
            /bin/echo "Could not delete $LOG_FILES"
          fi
        ;;
        esac
      fi

      /bin/echo -n "  - Deleting virtualhost file, $APACHE_CONFIG/virtualhosts/$VIRTUALHOST... "
      rm $APACHE_CONFIG/virtualhosts/$VIRTUALHOST
      /bin/echo "done"

      /bin/echo -n "+ Restarting Apache... "
      $APACHECTL graceful 1>/dev/null 2>/dev/null
      /bin/echo "done"
    fi
  else
    /bin/echo "- Virtualhost $VIRTUALHOST does not currently exist. Aborting..."
    exit 1
  fi

  exit
fi


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Make sure $APACHE_CONFIG/httpd.conf is ready for virtual hosting...
#
# If it's not, we will:
#
# a) Backup the original to $APACHE_CONFIG/httpd.conf.original
# b) Add a NameVirtualHost 127.0.0.1 line
# c) Create $APACHE_CONFIG/virtualhosts/ (virtualhost definition files reside here)
# d) Add a line to include all files in $APACHE_CONFIG/virtualhosts/
# e) Create a _localhost file for the default "localhost" virtualhost
#

if ! checkyesno ${SKIP_DOCUMENT_ROOT_CHECK} ; then
  if ! grep -q -e "^DocumentRoot \"$DOC_ROOT_PREFIX\"" $APACHE_CONFIG/httpd.conf ; then
    /bin/echo "httpd.conf's DocumentRoot does not point where it should."
    /bin/echo -n "Do you with to set it to $DOC_ROOT_PREFIX? [Y/n]: "
    if [ -z $BATCH_MODE ]; then
      read response
    else
      response="n"
    fi
    case $response in
    n*|N*)
      /bin/echo "Okay, just re-run this script if you change your mind."
    ;;
    *)
      cat << __EOT | ed $APACHE_CONFIG/httpd.conf 1>/dev/null 2>/dev/null
/^DocumentRoot
i
#
.
j
+
i
DocumentRoot "$DOC_ROOT_PREFIX"
.
w
q
__EOT
    ;;
    esac
  fi
fi

if ! grep -q -E "^NameVirtualHost \*:$APACHE_PORT" $APACHE_CONFIG/httpd.conf ; then

  /bin/echo "httpd.conf not ready for virtual hosting. Fixing..."
  cp $APACHE_CONFIG/httpd.conf $APACHE_CONFIG/httpd.conf.original
  /bin/echo "NameVirtualHost *:$APACHE_PORT" >> $APACHE_CONFIG/httpd.conf

  if [ ! -d $APACHE_CONFIG/virtualhosts ]; then
    mkdir $APACHE_CONFIG/virtualhosts
    create_virtualhost localhost $DOC_ROOT_PREFIX
  fi

  /bin/echo "Include $APACHE_CONFIG/virtualhosts"  >> $APACHE_CONFIG/httpd.conf

fi


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Look for hosts created in Tiger
#
if [ -d /etc/httpd/virtualhosts ]; then

  /bin/echo -n "Do you want to port the hosts you previously created in Tiger to the new system? [Y/n]: "
  read PORT_HOSTS
  case $PORT_HOSTS in
  n*|N*)
    /bin/echo "Okay, just re-run this script if you change your mind."
  ;;

  *)
    for host in `ls -1 /etc/httpd/virtualhosts | grep -v _localhost`; do
      /bin/echo -n "  + Creating $host... "
      if ! checkyesno ${SKIP_ETC_HOSTS}; then
        if ! host_exists $host ; then
          /bin/echo "$IP_ADDRESS  $host" >> /etc/hosts
        fi
      fi
      docroot=`grep DocumentRoot /etc/httpd/virtualhosts/$host | awk '{print $2}'`
      create_virtualhost $host $docroot
      /bin/echo "done"
    done

    mv /etc/httpd/virtualhosts /etc/httpd/virtualhosts-ported
  ;;
  esac


fi

if [ -z $WILDCARD_ZONE ]; then
  /bin/echo -n "Create http://${VIRTUALHOST}:${APACHE_PORT}/? [Y/n]: "
else
  /bin/echo -n "Create http://${VIRTUALHOST}.${WILDCARD_ZONE}:${APACHE_PORT}/? [Y/n]: "
fi

if [ -z "$BATCH_MODE" ]; then
  read continue
else
  continue="Y"
  /bin/echo $continue
fi

case $continue in
n*|N*) exit
esac


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# If the host is not already defined in /etc/hosts, define it...
#

if ! checkyesno ${SKIP_ETC_HOSTS}; then
  if ! host_exists $VIRTUALHOST ; then

    /bin/echo "Creating a virtualhost for $VIRTUALHOST..."
    /bin/echo -n "+ Adding $VIRTUALHOST to /etc/hosts... "
    /bin/echo "$IP_ADDRESS  $1" >> /etc/hosts
    /bin/echo "done"
  fi
fi


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Ask the user where they would like to put the files for this virtual host
#
/bin/echo "+ Looking in $DOC_ROOT_PREFIX for an existing document root to use..."

# See if we can find an appropriate folder
if ls -1 $DOC_ROOT_PREFIX | grep -q -e "^$VIRTUALHOST"; then
  DOC_ROOT_FOLDER_MATCH=`ls -1 $DOC_ROOT_PREFIX | grep -e ^$VIRTUALHOST | head -n 1`
  DOC_ROOT_FOLDER_MATCH="${DOC_ROOT_PREFIX}/${DOC_ROOT_FOLDER_MATCH}"
else
  if [ -d $DOC_ROOT_PREFIX/$VIRTUALHOST ]; then
    DOC_ROOT_FOLDER_MATCH="$DOC_ROOT_PREFIX/$VIRTUALHOST"
  else
    if [ $MAX_SEARCH_DEPTH -eq 0 ]; then
      /bin/echo -n " searching with no a maximum depth. This could take a really long time..."
    else
      /bin/echo -n " searching to a maximum directory depth of $MAX_SEARCH_DEPTH. This could take some time..."
    fi
    nested_match=`find $DOC_ROOT_PREFIX -maxdepth $MAX_SEARCH_DEPTH -type d -name $VIRTUALHOST 2>/dev/null`

    if [ -n "$nested_match" ]; then
      if [ -d $nested_match ]; then
        DOC_ROOT_FOLDER_MATCH=$nested_match
      fi
    else
      DOC_ROOT_FOLDER_MATCH="$DOC_ROOT_PREFIX/$VIRTUALHOST"
    fi
  fi
fi

/bin/echo -n "  - Use $DOC_ROOT_FOLDER_MATCH as the virtualhost folder? [Y/n] "

if [ -z "$BATCH_MODE" ]; then
  read resp
else
  resp="Y"
  echo $resp
fi

case $resp in

  n*|N*)
    while : ; do
      if [ -z "$FOLDER" ]; then
        /bin/echo -n "  - Enter new folder name (located in Sites): "
        read FOLDER
      else
        break
      fi
    done
  ;;

  *)
    if [ -d $DOC_ROOT_FOLDER_MATCH/public ]; then
      /bin/echo -n "  - Found a public folder suggesting a Rails/Merb/Rack project. Use as DocumentRoot? [y/N] "
      if [ -z "$BATCH_MODE" ]; then
        read response
      else
        response="n"
      fi
      if checkyesno ${response} ; then
        FOLDER=$DOC_ROOT_FOLDER_MATCH/public
      else
        FOLDER=$DOC_ROOT_FOLDER_MATCH
      fi
    elif [ -d $DOC_ROOT_FOLDER_MATCH/web ]; then
      /bin/echo -n "  - Found a web folder suggesting a Symfony project. Use as DocumentRoot? [y/N] "
      if [ -z "$BATCH_MODE" ]; then
        read response
      else
        response="n"
      fi
      if checkyesno ${response} ; then
        FOLDER=$DOC_ROOT_FOLDER_MATCH/web
      else
        FOLDER=$DOC_ROOT_FOLDER_MATCH
      fi
    else
      FOLDER=$DOC_ROOT_FOLDER_MATCH
    fi
  ;;
esac

# Create the folder if we need to...
if [ ! -d "${FOLDER}" ]; then
  /bin/echo -n "  + Creating folder ${FOLDER}... "
  su $USER -c "mkdir -p $FOLDER"
  /bin/echo "done"
fi


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# See if a custom log should be used (requested by david.kerns, Issue #7)
#
if checkyesno ${PROMPT_FOR_LOGS}; then

  /bin/echo -n "  - Enable custom server access and error logs in $VIRTUALHOST/logs? [y/N] "

  if [ -z "$BATCH_MODE" ]; then
    read resp
  else
    resp="Y"
  fi

  case $resp in

    y*|Y*)
      log="1"
    ;;

    *)
      log=""
    ;;
  esac

elif checkyesno ${ALWAYS_CREATE_LOGS}; then

  log="1"

fi


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create a default index.html if there isn't already one there
#
if [ ! -e "${FOLDER}/index.html" -a ! -e "${FOLDER}/index.php" ]; then

  cat << __EOF >"${FOLDER}/index.html"
<html>
<head>
<title>Welcome to $VIRTUALHOST</title>
<style type="text/css">
 body, div, td { font-family: "Lucida Grande"; font-size: 12px; color: #666666; }
 b { color: #333333; }
 .indent { margin-left: 10px; }
</style>
</head>
<body link="#993300" vlink="#771100" alink="#ff6600">

<table border="0" width="100%" height="95%"><tr><td align="center" valign="middle">
<div style="width: 500px; background-color: #eeeeee; border: 1px dotted #cccccc; padding: 20px; padding-top: 15px;">
 <div align="center" style="font-size: 14px; font-weight: bold;">
  Congratulations!
 </div>

 <div align="left">
  <p>If you are reading this in your web browser, then the only logical conclusion is that the <b><a href="http://$VIRTUALHOST:$APACHE_PORT/">http://$VIRTUALHOST:$APACHE_PORT/</a></b> virtualhost was setup correctly. :)</p>

  <p>You can find the configuration file for this virtual host in:<br>
  <table class="indent" border="0" cellspacing="3">
   <tr>
    <td><img src="/icons/script.gif" width="20" height="22" border="0"></td>
    <td><b>$APACHE_CONFIG/virtualhosts/$VIRTUALHOST</b></td>
   </tr>
  </table>
  </p>

  <p>You will need to place all of your website files in:<br>
  <table class="indent" border="0" cellspacing="3">
   <tr>
    <td><img src="/icons/dir.gif" width="20" height="22" border="0"></td>
    <td><b><a href="file://$FOLDER">$DOC_ROOT_PREFIX/$FOLDER</b></a></td>
   </tr>
  </table>
  </p>

  <p>For the latest version of this script, tips, comments, <span style="font-size: 10px; color: #999999;">donations,</span> etc. visit:<br>
  <table class="indent" border="0" cellspacing="3">
   <tr>
    <td><img src="/icons/forward.gif" width="20" height="22" border="0"></td>
    <td><b><a href="http://patrickg.com/virtualhost">http://patrickg.com/virtualhost</a></b></td>
   </tr>
  </table>
  </p>
 </div>

</div>
</td></tr></table>

</body>
</html>
__EOF
  chown $USER "${FOLDER}/index.html"

fi


#========================================================================================================#
# Create a default virtualhost file                                                                      #
#========================================================================================================#
/bin/echo -n "+ Creating virtualhost file... "
create_virtualhost $VIRTUALHOST "${FOLDER}" $log
/bin/echo "done"


#========================================================================================================#
# Restart Apache for the changes to take effect                                                          #
#========================================================================================================#

# TODO -> Add nscd support
#if [ -x /usr/bin/dscacheutil ]; then
#  /bin/echo -n "+ Flushing cache... "
#  dscacheutil -flushcache
#  /bin/echo "done"
#
#  dscacheutil -q host | grep -q $VIRTUALHOST
#
#  sleep 1
#fi

/bin/echo -n "+ Restarting Apache... "
$APACHECTL graceful 1>/dev/null 2>/dev/null
/bin/echo "done"

cat << __EOF

http://$VIRTUALHOST:$APACHE_PORT/ is setup and ready for use.

__EOF


#========================================================================================================#
# Launch the new URL in the browser                                                                      #
#========================================================================================================#
if [ -z $SKIP_BROWSER ]; then
  /bin/echo -n "Launching virtualhost... "
  sleep 1
  curl --silent http://$VIRTUALHOST:$APACHE_PORT/ 2>&1 >/dev/null
  open_command "http://$VIRTUALHOST:$APACHE_PORT/"
  /bin/echo "done"
fi

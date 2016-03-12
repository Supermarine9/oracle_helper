#!/usr/bin/env bash

################################################################################
#                   Oracle Database Pre-installation Helper
#                Pre-installation made easy for Linux & Solaris
#
#                                 Version 1.0
#
# Copyright (C) 2016  Wesley Dewsnup
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA or see
# http://www.gnu.org/licenses/
################################################################################

################################################################################
# Declare Variables #
#####################
ORACLE_USER=oracle
ORACLE_GROUP=oinstall
DEFAULT_PREREQ=12cR1
DEFAULT_YES=yes
DEFAULT_NO=no
BOLD=$( tput bold )
NORMAL=$( tput sgr0 )
HOME=$( dirname $( readlink -f "$0" ) )
################################################################################

################################################################################
# MAIN FUNCTIONS #
##################

# Header
########
header()
{
  clear
  TITLE="Oracle Database Pre-installation Helper"
  DESCRIPTION="Pre-installation made easy for Linux & Solaris"
  VERSION="Version 1.0"
  printf "%*s\n" $(( ( $(echo $TITLE | wc -c ) + 80 ) / 2 )) "${BOLD}$TITLE${NORMAL}"
  printf "%*s\n" $(( ( $(echo $DESCRIPTION | wc -c ) + 80 ) / 2 )) "${BOLD}$DESCRIPTION${NORMAL}"
  echo
  printf "%*s\n" $(( ( $(echo $VERSION | wc -c ) + 80 ) / 2 )) "${BOLD}$VERSION${NORMAL}"
  echo -e "\n"
}

# Copyright
###########
copyright()
{
read -d '' COPYRIGHT <<- EOF
${BOLD}Copyright (C) 2016  Wesley Dewsnup${NORMAL}

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but ${BOLD}WITHOUT ANY WARRANTY${NORMAL}; without even the implied warranty of
${BOLD}MERCHANTABILITY${NORMAL} or ${BOLD}FITNESS FOR A PARTICULAR PURPOSE${NORMAL}.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA or see
http://www.gnu.org/licenses/
EOF
  echo -e "$COPYRIGHT\n"
}

# Accept licence
################
accept()
{
  while [[ $ACCEPT != @([cC]) ]]; do
    header
    copyright
    read -e -p "'L' view full license, 'Q' to quit, or 'Enter' to continue: " ACCEPT
    ACCEPT=${ACCEPT:-C}
    if [[ $ACCEPT =~ ^([lL])$ ]]; then
      less $HOME/LICENSE
    elif [[ $ACCEPT =~ ^([qQ])$ ]]; then
      clear
      exit 1
    fi
  done
}

# System Check
##############
system_check()
{
  header
  if [ -f /etc/oracle-release ] || [ -f /etc/redhat-release ]; then
    OPERATING_SYSTEM=linux
    prereq
  elif [ -f /etc/release ] && grep "Oracle Solaris 11" /etc/release > /dev/null; then
    OPERATING_SYSTEM=solaris
    SOL_VER=11
    prereq
  elif [ -f /etc/release ] && grep "Oracle Solaris 10" /etc/release > /dev/null; then
    OPERATING_SYSTEM=solaris
    SOL_VER=10
    user
  else
    echo -e "\n${BOLD}No supported Operating System found.${NORMAL}\n"
    exit 1
  fi
}

# Prereqs package
#################
prereq()
{
  if [ $OPERATING_SYSTEM = linux ]; then
    while [[ $INSTALL != @([yY][eE][sS]|[y]|[nN][oO]|[nN]) ]]; do
      read -e -p "Would you like to install the prereq package? [yes]/no: " INSTALL
      INSTALL=${INSTALL:-$DEFAULT_YES}
    done
    if [[ $INSTALL =~ ^([yY][eE][sS]|[yY])  ]]; then
      while [[ $PREREQ != @([1][1][g][R][2]|[1][2][c][R][1]) ]]; do
        read -e -p "What DB version to prep for? 11gR2/[12cR1]: " PREREQ
        PREREQ=${PREREQ:-$DEFAULT_PREREQ}
        echo
      done
      if [[ $PREREQ =~ ^([1][2][c][R][1]|[1][1][g][R][2]) ]]; then
        yum -y install oracle-rdbms-server-$PREREQ-preinstall unixODBC
        echo
        directories
        password
      fi
    else
      echo -e "\n${BOLD}No prereqs will be installed.${NORMAL}\n"
      user
    fi
  elif [ $OPERATING_SYSTEM = solaris ]; then
    if [ $SOL_VER = 11 ]; then
      pkg info assembler 1&> /dev/null
      if [ $? != 3 ]; then
        while [[ $INSTALL != @([yY][eE][sS]|[y]|[nN][oO]|[nN]) ]]; do
          read -e -p "Would you like to install the assembler package? [yes]/no: " INSTALL
          INSTALL=${INSTALL:-$DEFAULT_YES}
          echo
        done
        if [[ $INSTALL =~ ^([yY][eE][sS]|[yY]) ]]; then
          pkg install assembler
          echo
          user
        else
          echo -e "${BOLD}Assembler will not be installed.${NORMAL}\n"
          user
        fi
      else
        user
      fi
    else
      user
    fi
  fi
  unset INSTALL
  unset PREREQ
}

# Group
#######
group()
{
  groupadd -g 54321 $ORACLE_GROUP
  groupadd -g 54322 dba 
}

# User
######
user()
{
  read -e -p "Would you like to create the Oracle User? [yes]/no: " USER
  USER=${USER:-$DEFAULT_YES}
  if [[ $USER =~ ^([yY][eE][sS]|[yY]) ]]; then
    echo -e "\nOracle User username is: $ORACLE_USER"
    echo -e "Oracle User default group is: $ORACLE_GROUP"
  group
    if [ $OPERATING_SYSTEM = linux ]; then
      useradd -g $ORACLE_GROUP -G dba -u 54321 $ORACLE_USER
    elif [ $OPERATING_SYSTEM = solaris ]; then
      useradd -u 54321 -g $ORACLE_GROUP -G dba -d /export/home/$ORACLE_USER -m $ORACLE_USER
    fi
  echo
  directories
  password
  fi
  unset USER
}

# Password
##########
password()
{
  PASSWORD=null
  if grep $ORACLE_USER /etc/passwd > /dev/null; then
    while [ $PASSWORD != match ]; do
      passwd $ORACLE_USER
      if [ $? = 0 ]; then
        PASSWORD=match
      fi
    done
  else
    user
  fi
}

# Directories
###########
directories()
{
  for D in app/$ORACLE_USER app/oraInventory oradata fast_recover_area; do
    mkdir -p /u01/$D
    chown -R $ORACLE_USER:$ORACLE_GROUP /u01/$D
    chmod -R 775 /u01/$D
  done
  unset D
}

# Additional Groups
###################
add_groups()
{
  header
  while [[ $ADD != @([yY][eE][sS]|[yY]|[nN][oO]|[nN]) ]]; do
    echo -e "Additional groups can be created:"
    echo -e "oper, backupdba, dgdba, kmdba, asmdba, asmoper, asmadmin\n"
    read -e -p "Create the additional groups? yes/[no]: " ADD
    ADD=${ADD:-$DEFAULT_NO}
    if [[ $ADD =~ ^([yY][eE][sS]|[yY]) ]] && grep ^$ORACLE_USER /etc/passwd > /dev/null; then
      read -e -p "Add Oracle User to these additional groups? [yes]/no: " MEMBER
      MEMBER=${MEMBER:-$DEFAULT_YES}
    fi
  done
  if [[ $ADD =~ ^([yY][eE][sS]|[yY]) ]]; then
    for G in oper backupdba dgdba kmdba asmdba asmoper asmadmin; do
      groupadd $G
    done
    unset G
  fi
  if [[ $MEMBER =~ ^([yY][eE][sS]|[yY]) ]]; then
    if [ $OPERATING_SYSTEM = linux ]; then
      usermod -G asmdba,backupdba,dgdba,kmdba,oper -a $ORACLE_USER
    elif [ $OPERATING_SYSTEM = solaris ]; then
      if [ $SOL_VER = 10 ]; then
        usermod -G dba,asmdba,backupdba,dgdba,kmdba,oper $ORACLE_USER
      else
        usermod -G +asmdba,backupdba,dgdba,kmdba,oper $ORACLE_USER
      fi
    fi
  fi
  if grep wheel /etc/group > /dev/null; then
    read -e -p "Add Oracle User to 'wheel' group? yes/[no] " WHEEL
    WHEEL=${WHEEL:-$DEFAULT_NO}
    usermod -G wheel -a $ORACLE_USER
  fi
  if grep vboxsf /etc/group > /dev/null && grep ^$ORACLE_USER /etc/passwd > /dev/null; then
    if [ $OPERATING_SYSTEM = linux ]; then
      usermod -G vboxsf -a $ORACLE_USER
    elif [ $OPERATING_SYSTEM = solaris ]; then
      if [ $SOL_VER = 10 ]; then
        if [[ $MEMBER =~ ^([yY][eE][sS]|[yY]) ]]; then
          usermod -G dba,asmdba,backupdba,dgdba,kmdba,oper,vboxsf $ORACLE_USER
        else
          usermod -G dba,vboxsf $ORACLE_USER
        fi
      else
        usermod -G +vboxsf $ORACLE_USER
      fi
    fi
  fi
  echo
  unset ADD
  unset MEMBER
  unset WHEEL
}

# Restart system
################
restart_sys()
{
  while [[ $REBOOT != @([yY][eE][sS]|[yY]|[nN][oO]|[nN]) ]]; do
    read -e -p "Would you like to reboot the system now? yes/[no]: " REBOOT
    REBOOT=${REBOOT:-$DEFAULT_NO}
  done
  if [[ $REBOOT =~ ^([yY][eE][sS]|[yY]) ]]; then
    init 6
  else
    echo -e "\n${BOLD}Thank you for using the script!${NORMAL}\n"
  fi
  unset REBOOT
}

################################################################################

################################################################################
# PROGRAM LOGIC #
#################
accept  # Runs the accpet copyright function
system_check  # Runs the system check function
add_groups  # Runs the additinoal gorups function
restart_sys  # Runs the restart system function
################################################################################
exit 0  # Exit cleanly

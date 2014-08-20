HowTo
======

You’ll need to modify a few of the variables in the script. Either by editing 
the script itself or exporting/setting the variables for the scripts runtime. 

Those variables, with the defaults, are

    OPENSSL=${OPENSSL:-/usr/local/Cellar/openssl/1.0.1h/bin/openssl}
    ROOT=${ROOT:-certs}
    DOMAIN=${DOMAIN:-tfoundry.com}
    COUNTRY=${COUNTRY:-US}
    STATE=${STATE:-California}
    CITY=${CITY:-Palo Alto}
    ORG=${ORG:-AT&T}
    UNIT=${UNIT:-Foundry}
    EMAIL=${EMAIL:-jk328n@att.com}

    SUBJECT_AlT_TYPE=DNS  # Other option is IP
    declare -a ALT_NAMES=(
        "dock1.${DOMAIN}"
        "dock2.${DOMAIN}"
        "dock3.${DOMAIN}"
        "dock4.${DOMAIN}"
    )


To override the SUBJECT\_ALT\_NAMES, you can set a comma delimited list of the
hosts like

    export SUBJECT_ALT_NAMES=foo.domain.com,bar.domain.com,baz.domain.com

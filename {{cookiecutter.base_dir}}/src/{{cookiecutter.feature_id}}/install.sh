#!/usr/bin/env bash

set -e
{% if cookiecutter.content.aptget is defined and cookiecutter.content.aptget |length > 0  %}   
{% for aptget_package in cookiecutter.content.aptget -%} 
{% if aptget_package.optional is defined and aptget_package.optional == "True" -%}   
INCLUDE{{ aptget_package.display_name | upper | replace("_", "") | replace("-", "")}}={"INCLUDE{{ aptget_package.display_name | upper | replace("_", "") | replace("-", "")}}":-"true"}
{% else -%}
INCLUDE{{ aptget_package.display_name | upper | replace("_", "") | replace("-", "")}}="true"
{%- endif -%}
{%- endfor -%}
{%- endif -%}

{% if cookiecutter.content.pipx is defined and cookiecutter.content.pipx |length > 0 %}   
{% for pipx_package in cookiecutter.content.pipx %}
# pipx package parameters
{% if pipx_package.optional is defined and  pipx_package.optional == "True" -%}   
INCLUDE{{ pipx_package.display_name | upper | replace("_", "") | replace("-", "")}}={"INCLUDE{{ pipx_package.display_name | upper | replace("_", "") | replace("-", "")}}":-"true"}
{% else -%}
INCLUDE{{ pipx_package.display_name | upper | replace("_", "") | replace("-", "")}}="true"
{% endif -%}
{{ pipx_package.display_name | upper | replace("_", "") | replace("-", "")}}VERSION={"{{ pipx_package.display_name | upper | replace("_", "") | replace("-", "")}}VERSION":-"latest"}
{% for pipx_injection in pipx_package.injections %}
# pipx injection parameters
{% if pipx_injection.optional is defined and pipx_injection.optional == "True" %}   
    INCLUDE{{ pipx_injection.display_name | upper | replace("_", "") | replace("-", "")}}={"INCLUDE{{ pipx_injection.display_name | upper | replace("_", "") | replace("-", "")}}":-"true"}
{%- else %}
    INCLUDE{{ pipx_injection.display_name | upper | replace("_", "") | replace("-", "")}}="true"
{%- endif %}
    {{ pipx_injection.display_name | upper | replace("_", "") | replace("-", "")}}VERSION={"{{ pipx_injection.display_name | upper | replace("_", "") | replace("-", "")}}VERSION":-"latest"}
{%- endfor %}
{% if pipx_package.version_alias is defined %}   
# add version alias if needed
{{ pipx_package.display_name | upper | replace("_", "") | replace("-", "")}}VERSION=${"{{pipx_package.version_alias | upper | replace("_", "") | replace("-", "")}}":-"latest"}
{%- endif -%}
{%- endfor -%}
{%- endif %}

# Clean up
rm -rf /var/lib/apt/lists/*


if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi


# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            echo "Running apt-get update..."
            apt-get update -y
        fi
        apt-get -y install --no-install-recommends "$@"
    fi
}

{% if cookiecutter.content.aptget is defined and cookiecutter.content.aptget |length > 0  %} 
apt_install_command=""
{% for aptget_package in cookiecutter.content.aptget -%} 
if [ "$INCLUDE{{ aptget_package.display_name | upper | replace("_", "") | replace("-", "")}}" == "true"]; then
    apt_install_command="$apt_install_command {{aptget_package.package_name}}"
fi
echo "Installing $apt_install_command ..."
check_packages $apt_install_command
{% endfor %}

{%- endif %}

{% if cookiecutter.content.pipx is defined and cookiecutter.content.pipx |length > 0  %} 


# settings these will allow us to clean leftovers later on
export PYTHONUSERBASE=/tmp/pip-tmp
export PIP_CACHE_DIR=/tmp/pip-tmp/cache


# install python if does not exists
if ! type pip3 > /dev/null 2>&1; then
    echo "Installing python3..."
    # If the python feature script had option to install pipx without the 
    # additional tools we would have used that, but since it doesnt 
    # we have to disable it with INSTALLTOOLS=false and install
    # pipx manually later on
    check_packages curl
    export VERSION="system" 
    export INSTALLTOOLS="false"
    curl -fsSL https://raw.githubusercontent.com/devcontainers/features/main/src/python/install.sh | $SHELL
fi

# configuring install location 
# changing /usr/local/bin as we know it will be in PATH of all users
export PIPX_BIN_DIR="/usr/local/bin"

if ! type pipx > /dev/null 2>&1; then
    echo "Installing pipx..."
    export PIPX_HOME=/opt/pipx
    mkdir -p ${PIPX_HOME}
    chmod -R g+r+w "${PIPX_HOME}"

    pip3 install --disable-pip-version-check --no-cache-dir --user pipx 2>&1
    /tmp/pip-tmp/bin/pipx install --pip-args=--no-cache-dir pipx
    PIPX_COMMAND=/tmp/pip-tmp/bin/pipx
else
    PIPX_COMMAND=pipx
fi

#
{% for pipx_package in cookiecutter.content.pipx %}
if [ "$INCLUDE{{ pipx_package.display_name | upper | replace("_", "") | replace("-", "")}}" == "true" ]; then
    if [ "${{ pipx_package.display_name | upper | replace("_", "") | replace("-", "")}}VERSION" == "latest" ]; then
        util_command="{{pipx_package.package_name}}"
    else
        util_command="{{pipx_package.package_name}}==${{ pipx_package.display_name | upper | replace("_", "") | replace("-", "")}}VERSION"
    fi
    "${PIPX_COMMAND}" install --system-site-packages --force --pip-args '--no-cache-dir --force-reinstall' ${util_command}
{% for pipx_injection in pipx_package.injections %}
    if [ "$INCLUDE{{ pipx_injection.display_name | upper | replace("_", "") | replace("-", "")}}" == "true" ]; then
        if [ "${{ pipx_injection.display_name | upper | replace("_", "") | replace("-", "")}}VERSION" == "latest" ]; then
            util_command="{{pipx_injection.package_name}}"
        else
            util_command="{{pipx_injection.package_name}}==${{ pipx_injection.display_name | upper | replace("_", "") | replace("-", "")}}VERSION"
        fi
    pipx inject {{pipx_package.package_name}} ${util_command}
    fi
{% endfor %}
fi
{% endfor %}

# cleaning after pip
rm -rf /tmp/pip-tmp

{% endif %}


# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
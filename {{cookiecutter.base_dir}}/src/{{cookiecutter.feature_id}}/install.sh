{%- set optional_aptget_packages = (cookiecutter.content.aptget | selectattr('optional', 'equalto', 'True') | list) -%}
{%- set mandatory_aptget_packages = (cookiecutter.content.aptget | selectattr('optional', 'equalto', 'False') | list) -%}
#!/usr/bin/env bash
# This is a generated code using the devcontainer-feature cookiecutter
# For more information: https://github.com/devcontainers-contrib/cookiecutter-devcontainers-feature
set -e
{% if optional_aptget_packages |length > 0  %} 
# optional aptget packages  
{% for aptget_package in optional_aptget_packages -%} 
INCLUDE{{ aptget_package.display_name | to_env_case }}=${INCLUDE{{ aptget_package.display_name | to_env_case }}:-"true"}
{% endfor -%}
{%- endif -%}

{% if cookiecutter.content.pipx is defined and cookiecutter.content.pipx |length > 0 %}   
{% for pipx_package in cookiecutter.content.pipx %}
# pipx package parameters for {{ pipx_package.display_name }}
{% if pipx_package.optional is defined and  pipx_package.optional == "True" %}   
INCLUDE{{ pipx_package.display_name| to_env_case  }}={% raw %}${INCLUDE{% endraw %}{{ pipx_package.display_name| to_env_case }}{% raw %}:-"true"}{% endraw %}
{% else -%}
INCLUDE{{ pipx_package.display_name| to_env_case }}="true"
{% endif -%}
{%- if pipx_package.version_alias is defined -%}   
{{ pipx_package.display_name | to_env_case}}VERSION={% raw %}${{% endraw %}{{pipx_package.version_alias | to_env_case}}{% raw %}:-"latest"}{% endraw %}
{% else %}
{{ pipx_package.display_name| to_env_case }}VERSION={% raw %}${{% endraw %}{{ pipx_package.display_name | to_env_case}}{% raw %}VERSION:-"latest"}{% endraw %}
{%- endif %}
    # pipx injection parameters for {{ pipx_package.display_name }} env
{%- for pipx_injection in pipx_package.injections %}
{%- if pipx_injection.optional is defined and pipx_injection.optional == "True" %}   
    INCLUDE{{ pipx_injection.display_name | to_env_case}}=${INCLUDE{{ pipx_injection.display_name | to_env_case}}:-"true"}
{%- else %}
    INCLUDE{{ pipx_injection.display_name| to_env_case}}="true"
{%- endif %}
    {{ pipx_injection.display_name| to_env_case}}VERSION={% raw %}${{% endraw %}{{ pipx_injection.display_name| to_env_case}}{% raw %}VERSION:-"latest"}{% endraw %}
{%- endfor %}

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
{% if mandatory_aptget_packages is defined and mandatory_aptget_packages|length > 0 %}
aptget_packages=({% for aptget_package_name in mandatory_aptget_packages -%}{{aptget_package_name.package_name}} {% endfor %})
{% else %}
aptget_packages=()
{% endif %}

{% for aptget_package in optional_aptget_packages -%} 
if [ "$INCLUDE{{ aptget_package.display_name  | to_env_case }}" =  "true" ]; 
    aptget_packages+=("{{aptget_package.package_name}}")
fi
{% endfor %}
check_packages ${aptget_packages[@]}
{% endif %}

{% if cookiecutter.content.pipx is defined and cookiecutter.content.pipx |length > 0  %} 
# code bellow is mostly taken from the base python feature https://raw.githubusercontent.com/devcontainers/features/main/src/python/install.sh
updaterc() {
    echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
    if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
        echo -e "$1" >> /etc/bash.bashrc
    fi
    if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
        echo -e "$1" >> /etc/zsh/zshrc
    fi
}
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
# install pipx if not exists
export PIPX_HOME=${PIPX_HOME:-"/usr/local/py-utils"}
export PIPX_BIN_DIR="${PIPX_HOME}/bin"

if ! type pipx > /dev/null 2>&1; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi

    PATH="${PATH}:${PIPX_BIN_DIR}"

    # Create pipx group, dir, and set sticky bit
    if ! cat /etc/group | grep -e "^pipx:" > /dev/null 2>&1; then
        groupadd -r pipx
    fi
    usermod -a -G pipx ${USERNAME}
    umask 0002
    mkdir -p ${PIPX_BIN_DIR}
    chown -R "${USERNAME}:pipx" ${PIPX_HOME}
    chmod -R g+r+w "${PIPX_HOME}" 
    find "${PIPX_HOME}" -type d -print0 | xargs -0 -n 1 chmod g+s

    pip3 install --disable-pip-version-check --no-cache-dir --user pipx 2>&1
    /tmp/pip-tmp/bin/pipx install --pip-args=--no-cache-dir pipx
    PIPX_COMMAND=/tmp/pip-tmp/bin/pipx
else
    PIPX_COMMAND=pipx
fi

#
{% for pipx_package in cookiecutter.content.pipx %}
if [ "$INCLUDE{{ pipx_package.display_name | to_env_case }}" = "true" ]; then
    if [ "${{ pipx_package.display_name  | to_env_case }}VERSION" =  "latest" ]; then
        util_command="{{pipx_package.package_name}}"
    else
        util_command="{{pipx_package.package_name}}==${{ pipx_package.display_name | to_env_case }}VERSION"
    fi
    "${PIPX_COMMAND}" install --system-site-packages --force --pip-args '--no-cache-dir --force-reinstall' ${util_command}
{% for pipx_injection in pipx_package.injections %}
    if [ "$INCLUDE{{ pipx_injection.display_name | to_env_case }}" =  "true" ]; then
        if [ "${{ pipx_injection.display_name | to_env_case }}VERSION" =  "latest" ]; then
            util_command="{{pipx_injection.package_name}}"
        else
            util_command="{{pipx_injection.package_name}}==${{ pipx_injection.display_name | to_env_case }}VERSION"
        fi
    pipx inject {{pipx_package.package_name}} ${util_command}
    fi
{% endfor %}
fi
{% endfor %}

updaterc "export PIPX_HOME=\"${PIPX_HOME}\""
updaterc "export PIPX_BIN_DIR=\"${PIPX_BIN_DIR}\""
updaterc "if [[ \"\${PATH}\" != *\"\${PIPX_BIN_DIR}\"* ]]; then export PATH=\"\${PATH}:\${PIPX_BIN_DIR}\"; fi"

# cleaning after pip
rm -rf /tmp/pip-tmp

{% endif %}


# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
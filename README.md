# Devcontainers cookiecutter

currently supports:

* pipx based features
* apt-get based features

# Dependencies

`pipx install cookiecutter`

`pipx inject cookiecutter jinja2-strcase`

## Example to create mkdocs feature
mkdocs uses pipx + multiple injections

` cookiecutter gh:devcontainers-contrib/cookiecutter-devcontainers-feature --overwrite-if-exists --no-input --config-file ./examples/mkdocs.yaml `

## Example to create localstack feature
localstack uses pipx + a mandatory apt-get package
` cookiecutter gh:devcontainers-contrib/cookiecutter-devcontainers-feature --overwrite-if-exists --no-input --config-file ./examples/ansible.yaml `

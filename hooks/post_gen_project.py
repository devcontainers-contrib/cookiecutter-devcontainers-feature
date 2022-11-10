import json
import os
import yaml

# fix trailing commas
with open(os.path.join("src", "{{cookiecutter.feature_id}}", "devcontainer-feature.json"), "r") as f:
    data = yaml.safe_load(f)
with open(os.path.join("src", "{{cookiecutter.feature_id}}", "devcontainer-feature.json"), "w") as f:
    json.dump( data, f, indent=4)

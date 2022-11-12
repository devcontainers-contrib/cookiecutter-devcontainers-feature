from typing import List
import requests
from jinja2.ext import Extension


class ToEnvCase(Extension):
    """Jinja2 extension to create a random string."""

    def __init__(self, environment):
        """Jinja2 Extension Constructor."""
        super().__init__(environment)

        def to_env_case(input_str: str) -> str:
            return input_str.upper().replace("-", "").replace("_", "").replace(" ", "")

        environment.filters.update(to_env_case=to_env_case)
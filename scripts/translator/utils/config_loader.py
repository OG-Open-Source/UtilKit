"""
This module handles the discovery and loading of i18n configuration files.
"""

import os
import json
import yaml
from typing import List, Optional
from ..models.types import MainConfig

# Default directories to scan if the config file is not found.
DEFAULT_SEARCH_DIRS_FindConfigFiles: List[str] = ["/", "/sh", "/shx"]


def _GetSearchDirs(_get_search_dirs_project_root: str) -> List[str]:
    """Loads search directories from translator_config.json or returns the default."""
    config_path__GetSearchDirs = os.path.join(
        _get_search_dirs_project_root, "translator_config.json"
    )
    if os.path.exists(config_path__GetSearchDirs):
        try:
            with open(
                config_path__GetSearchDirs, "r", encoding="utf-8"
            ) as f__GetSearchDirs:
                data__GetSearchDirs = json.load(f__GetSearchDirs)
                if isinstance(data__GetSearchDirs.get("search_directories"), list):
                    return data__GetSearchDirs["search_directories"]
        except (IOError, json.JSONDecodeError) as e__GetSearchDirs:
            print(
                f"Warning: Could not read or parse translator_config.json. Falling back to default search directories. Error: {e__GetSearchDirs}"
            )
    return DEFAULT_SEARCH_DIRS_FindConfigFiles


def FindConfigFiles(project_root_FindConfigFiles: Optional[str] = None) -> List[str]:
    """
    Finds all i18n-rules configuration files in the target directories.

    The directories to search are determined by translator_config.json, with a
    fallback to a default list. It searches for `.ogos/i18n-rules.yml` and
    `.ogos/i18n-rules.yaml` within those directories.

    Args:
        project_root_FindConfigFiles (Optional[str]): The root directory of the project.
            If None, the current working directory is used.

    Returns:
        List[str]: A list of absolute paths to the found configuration files.
    """
    config_files_FindConfigFiles: List[str] = []

    if project_root_FindConfigFiles is None:
        project_root_FindConfigFiles = os.getcwd()

    search_dirs_FindConfigFiles = _GetSearchDirs(project_root_FindConfigFiles)
    print(f"Searching for config files in: {search_dirs_FindConfigFiles}")

    for target_dir_FindConfigFiles in search_dirs_FindConfigFiles:
        search_dir_FindConfigFiles: str = os.path.join(
            project_root_FindConfigFiles, target_dir_FindConfigFiles.strip("/\\")
        )
        config_path_base_FindConfigFiles: str = os.path.join(
            search_dir_FindConfigFiles, ".ogos", "i18n-rules"
        )

        for ext_FindConfigFiles in [".yml", ".yaml"]:
            config_path_FindConfigFiles: str = (
                f"{config_path_base_FindConfigFiles}{ext_FindConfigFiles}"
            )
            if os.path.exists(config_path_FindConfigFiles):
                config_files_FindConfigFiles.append(config_path_FindConfigFiles)

    return config_files_FindConfigFiles


def LoadConfig(config_path_LoadConfig: str) -> MainConfig:
    """
    Loads and validates a single YAML configuration file.

    Args:
        config_path_LoadConfig (str): The absolute path to the YAML configuration file.

    Returns:
        MainConfig: A TypedDict representing the loaded and validated configuration.

    Raises:
        FileNotFoundError: If the configuration file does not exist.
        yaml.YAMLError: If the file is not valid YAML.
        ValueError: If the configuration is missing required keys.
    """
    if not os.path.exists(config_path_LoadConfig):
        raise FileNotFoundError(
            f"Configuration file not found at: {config_path_LoadConfig}"
        )

    with open(config_path_LoadConfig, "r", encoding="utf-8") as f_LoadConfig:
        try:
            config_data_LoadConfig = yaml.safe_load(f_LoadConfig)
        except yaml.YAMLError as e_LoadConfig:
            raise yaml.YAMLError(
                f"Error parsing YAML file {config_path_LoadConfig}: {e_LoadConfig}"
            )

    # Basic validation
    if (
        "languages" not in config_data_LoadConfig
        or "file_rules" not in config_data_LoadConfig
    ):
        raise ValueError(
            f"Configuration file {config_path_LoadConfig} is missing required keys: 'languages' or 'file_rules'."
        )

    return config_data_LoadConfig

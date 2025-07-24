"""
This module provides utility functions for file system operations,
such as reading from and writing to files, with robust error handling.
"""

import os
import json
from typing import Any, Dict


def ReadTextFile(file_path_ReadTextFile: str) -> str:
    """
    Safely reads the entire content of a text file.

    Args:
        file_path_ReadTextFile (str): The path to the file.

    Returns:
        str: The content of the file.

    Raises:
        IOError: If the file cannot be read.
    """
    try:
        with open(file_path_ReadTextFile, "r", encoding="utf-8") as f_ReadTextFile:
            return f_ReadTextFile.read()
    except IOError as e_ReadTextFile:
        print(f"Error reading file {file_path_ReadTextFile}: {e_ReadTextFile}")
        raise


def WriteTextFile(file_path_WriteTextFile: str, content_WriteTextFile: str):
    """
    Safely writes text content to a file, creating parent directories if they don't exist.

    Args:
        file_path_WriteTextFile (str): The path to the file.
        content_WriteTextFile (str): The content to write.

    Raises:
        IOError: If the file cannot be written.
    """
    try:
        dir_name_WriteTextFile = os.path.dirname(file_path_WriteTextFile)
        if dir_name_WriteTextFile:
            os.makedirs(dir_name_WriteTextFile, exist_ok=True)

        with open(file_path_WriteTextFile, "w", encoding="utf-8") as f_WriteTextFile:
            f_WriteTextFile.write(content_WriteTextFile)
    except IOError as e_WriteTextFile:
        print(f"Error writing to file {file_path_WriteTextFile}: {e_WriteTextFile}")
        raise


def ReadJsonFile(file_path_ReadJsonFile: str) -> Dict[str, Any]:
    """
    Safely reads and parses a JSON file.

    Args:
        file_path_ReadJsonFile (str): The path to the JSON file.

    Returns:
        Dict[str, Any]: The parsed JSON data. Returns an empty dict if file is empty or invalid.
    """
    try:
        if (
            not os.path.exists(file_path_ReadJsonFile)
            or os.path.getsize(file_path_ReadJsonFile) == 0
        ):
            return {}
        with open(file_path_ReadJsonFile, "r", encoding="utf-8") as f_ReadJsonFile:
            return json.load(f_ReadJsonFile)
    except (IOError, json.JSONDecodeError) as e_ReadJsonFile:
        print(
            f"Warning: Could not read or parse JSON file {file_path_ReadJsonFile}. Returning empty data. Error: {e_ReadJsonFile}"
        )
        return {}


def WriteJsonFile(file_path_WriteJsonFile: str, data_WriteJsonFile: Dict[str, Any]):
    """
    Safely writes a dictionary to a JSON file, creating parent directories if they don't exist.

    Args:
        file_path_WriteJsonFile (str): The path to the JSON file.
        data_WriteJsonFile (Dict[str, Any]): The dictionary to write.

    Raises:
        IOError: If the file cannot be written.
    """
    try:
        dir_name_WriteJsonFile = os.path.dirname(file_path_WriteJsonFile)
        if dir_name_WriteJsonFile:
            os.makedirs(dir_name_WriteJsonFile, exist_ok=True)

        with open(file_path_WriteJsonFile, "w", encoding="utf-8") as f_WriteJsonFile:
            json.dump(data_WriteJsonFile, f_WriteJsonFile, ensure_ascii=False, indent=2)
    except IOError as e_WriteJsonFile:
        print(
            f"Error writing to JSON file {file_path_WriteJsonFile}: {e_WriteJsonFile}"
        )
        raise

"""
This module provides miscellaneous helper functions used across the application.
"""

import random
import string


def GenerateRandomKey(length_GenerateRandomKey: int = 6) -> str:
    """
    Generates a unique random key of a specified length.

    This function is used to create unique identifiers for text segments
    that are extracted for translation.

    Args:
        length_GenerateRandomKey (int): The desired length of the key. Defaults to 6.

    Returns:
        str: A randomly generated alphanumeric key.
    """
    chars_GenerateRandomKey: str = string.ascii_letters + string.digits
    return "".join(random.choices(chars_GenerateRandomKey, k=length_GenerateRandomKey))


def EscapeSequenceTranslator(text_EscapeSequenceTranslator: str) -> str:
    """
    Translates custom, double-escaped sequences to standard single-escaped ones.

    This is necessary because strings extracted from source code might have
    escaped characters that need to be correctly interpreted by the translation APIs.

    Args:
        text_EscapeSequenceTranslator (str): The text containing custom escape sequences.

    Returns:
        str: Text with standard escape sequences.
    """
    return (
        text_EscapeSequenceTranslator.replace("\\\\", "\\")
        .replace("\\ ", " ")
        .replace("\\n", "\n")
        .replace("\\t", "\t")
    )

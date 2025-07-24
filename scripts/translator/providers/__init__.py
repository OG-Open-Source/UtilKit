"""
This package contains all the translator provider implementations.
It also provides a factory function to create a translator instance based on configuration.
"""

from .base import BaseTranslator
from .openai import OpenAITranslator
from .gemini import GeminiTranslator
from .deep_translator import DeepTranslatorWrapper
from .mock import MockTranslator
from .ollama import OllamaTranslator
from ..models.types import TranslatorConfig


import logging


def CreateTranslator(
    config_CreateTranslator: TranslatorConfig, logger
) -> BaseTranslator:
    """
    Factory function to create a translator instance based on the configuration.

    This function reads the 'provider' key from the configuration dictionary
    and returns an instance of the corresponding translator class.

    Args:
        config_CreateTranslator (TranslatorConfig): The configuration dictionary for the translator.
            It must contain a 'provider' key (e.g., 'openai', 'gemini', 'google').
        logger (logging.Logger): The logger instance for logging messages.

    Returns:
        BaseTranslator: An instance of a class that inherits from BaseTranslator.

    Raises:
        ValueError: If the specified provider is not supported.
    """
    provider_CreateTranslator = config_CreateTranslator.get(
        "provider", "google"
    ).lower()

    # The config passed to the translator should be the whole thing,
    # not just the nested 'config' block, so it can access top-level keys like 'debug'.
    provider_config_CreateTranslator = config_CreateTranslator

    if provider_CreateTranslator == "openai":
        return OpenAITranslator(provider_config_CreateTranslator, logger)
    elif provider_CreateTranslator == "gemini":
        return GeminiTranslator(provider_config_CreateTranslator, logger)
    elif provider_CreateTranslator == "mock":
        return MockTranslator(provider_config_CreateTranslator, logger)
    elif provider_CreateTranslator == "ollama":
        return OllamaTranslator(provider_config_CreateTranslator, logger)
    # For any other provider, assume it's supported by deep_translator
    elif (
        provider_CreateTranslator
        in DeepTranslatorWrapper.DEEP_TRANSLATOR_MAP_DeepTranslatorWrapper
    ):
        # For deep_translator, we need to add the provider name back into the config it expects.
        provider_config_CreateTranslator["provider"] = provider_CreateTranslator
        return DeepTranslatorWrapper(provider_config_CreateTranslator, logger)
    else:
        raise ValueError(
            f"Unsupported translator provider: {provider_CreateTranslator}"
        )

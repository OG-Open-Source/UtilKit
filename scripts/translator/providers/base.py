"""
This module defines the abstract base class for all translator providers.
"""

import time
from abc import ABC, abstractmethod
from typing import List, Dict, Optional
import logging
from ..models.types import TranslatorConfig


class BaseTranslator(ABC):
    """
    Abstract Base Class for all translator implementations.

    This class defines the common interface that every translator provider
    must implement. It ensures that the core engine can interact with any
    translator in a consistent way.

    Attributes:
        batch_size_BaseTranslator (int): The number of texts to process in a single API call.
    """

    batch_size_BaseTranslator: int = (
        100  # Default batch size, can be overridden by subclasses
    )

    def __init__(self, config_BaseTranslator: TranslatorConfig, logger):
        """
        Initializes the translator with its specific configuration.

        Args:
            config_BaseTranslator (TranslatorConfig): A dictionary containing configuration
                parameters for the translator, such as API keys, model names, etc.
            logger (StructuredLogger): The logger instance for logging messages.
        """
        self.config_BaseTranslator = config_BaseTranslator
        self.logger = logger
        self.batch_size_BaseTranslator = config_BaseTranslator.get(
            "batch_size", self.batch_size_BaseTranslator
        )
        self.debug_BaseTranslator: bool = config_BaseTranslator.get("debug", False)

        # Context settings
        context_config: Dict[str, int] = config_BaseTranslator.get("context", {})
        self.context_before_BaseTranslator: int = context_config.get("before", 0)
        self.context_after_BaseTranslator: int = context_config.get("after", 0)

    def _TranslateWithRetry(
        self,
        texts: List[str],
        source_lang: str,
        target_lang: str,
        context_before: Optional[List[str]] = None,
        context_after: Optional[List[str]] = None,
    ) -> List[str]:
        max_retries = 5
        retry_delay = 10  # seconds

        for attempt in range(max_retries):
            try:
                translated_texts = self._TranslateBatch(
                    texts_TranslateBatch=texts,
                    source_lang_TranslateBatch=source_lang,
                    target_lang_TranslateBatch=target_lang,
                    context_before_TranslateBatch=context_before,
                    context_after_TranslateBatch=context_after,
                )
                # Check if the translation was successful (not returning original texts)
                if translated_texts != texts:
                    self.logger.debug_raw(
                        f"Batch translated successfully on attempt {attempt + 1}."
                    )
                    return translated_texts
                else:
                    # This case handles non-exception failures where the provider returns the original text.
                    raise ValueError("Translation failed, returned original texts.")

            except Exception as e:
                self.logger.warning(f"Attempt {attempt + 1}/{max_retries} failed: {e}")
                if attempt + 1 < max_retries:
                    self.logger.info(f"Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                else:
                    self.logger.error(
                        "Max retries reached. Translation failed for this batch."
                    )
                    # On final failure, return the original texts
                    return texts
        return texts  # Should be unreachable, but for safety

    @abstractmethod
    def _TranslateBatch(
        self,
        texts_TranslateBatch: List[str],
        source_lang_TranslateBatch: str,
        target_lang_TranslateBatch: str,
        context_before_TranslateBatch: Optional[List[str]] = None,
        context_after_TranslateBatch: Optional[List[str]] = None,
    ) -> List[str]:
        """
        The actual implementation of translating a batch of texts.
        This method is called by _TranslateWithRetry and should be implemented by subclasses.
        """
        pass

    def TranslateBatch(
        self,
        texts: List[str],
        source_lang: str,
        target_lang: str,
        context_before: Optional[List[str]] = None,
        context_after: Optional[List[str]] = None,
    ) -> List[str]:
        """
        Public method to translate a batch of texts with retry logic.
        """
        return self._TranslateWithRetry(
            texts=texts,
            source_lang=source_lang,
            target_lang=target_lang,
            context_before=context_before,
            context_after=context_after,
        )

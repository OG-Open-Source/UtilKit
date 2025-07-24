"""
This module provides a mock translator for testing purposes.
"""

from typing import List, Dict, Any, Optional
from .base import BaseTranslator
from ..utils.logger import StructuredLogger


class MockTranslator(BaseTranslator):
    """
    A mock translator that returns predictable, non-API-based translations for tests.
    """

    def __init__(self, config: Dict[str, Any], logger: StructuredLogger):
        super().__init__(config, logger)
        # Set a default batch size for the mock provider
        self.batch_size = config.get("batch_size", 100)

    def _TranslateBatch(
        self,
        texts_TranslateBatch: List[str],
        source_lang_TranslateBatch: str,
        target_lang_TranslateBatch: str,
        context_before_TranslateBatch: Optional[List[str]] = None,
        context_after_TranslateBatch: Optional[List[str]] = None,
    ) -> List[str]:
        """
        Mocks the translation of a batch of texts.

        Args:
            texts_TranslateBatch (List[str]): The texts to "translate".
            source_lang_TranslateBatch (str): The source language (ignored).
            target_lang_TranslateBatch (str): The target language.

        Returns:
            List[str]: A list of "translated" texts.
        """
        self.logger.debug_kv(
            "Mock Translator Request",
            {
                "provider": "mock",
                "source_language": source_lang_TranslateBatch,
                "target_language": target_lang_TranslateBatch,
                "text_batch": texts_TranslateBatch,
            },
        )
        # Return a predictable transformation
        translated_texts = [
            f"Translated to {target_lang_TranslateBatch}: {text}"
            for text in texts_TranslateBatch
        ]

        self.logger.debug_kv(
            "Mock Translator Response",
            {"provider": "mock", "translated_batch": translated_texts},
        )

        return translated_texts

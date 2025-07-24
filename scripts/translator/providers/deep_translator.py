"""
This module provides a wrapper for the various translators available in the 'deep_translator' library.
"""

import logging
from typing import List, Dict, Any, Optional, Type
from deep_translator import (
    GoogleTranslator,
    PonsTranslator,
    LingueeTranslator,
    MyMemoryTranslator,
    YandexTranslator,
    DeeplTranslator,
    QcriTranslator,
    MicrosoftTranslator,
    PapagoTranslator,
    BaiduTranslator,
    LibreTranslator,
)
from .base import BaseTranslator
from ..models.types import TranslatorConfig


class DeepTranslatorWrapper(BaseTranslator):
    """
    A wrapper for various translators from the 'deep_translator' library.
    """

    DEEP_TRANSLATOR_MAP_DeepTranslatorWrapper: Dict[str, Type[Any]] = {
        "google": GoogleTranslator,
        "pons": PonsTranslator,
        "linguee": LingueeTranslator,
        "mymemory": MyMemoryTranslator,
        "yandex": YandexTranslator,
        "deepl": DeeplTranslator,
        "qcri": QcriTranslator,
        "microsoft": MicrosoftTranslator,
        "papago": PapagoTranslator,
        "baidu": BaiduTranslator,
        "libre": LibreTranslator,
    }

    def __init__(
        self,
        config_DeepTranslatorWrapper: TranslatorConfig,
        logger: logging.Logger,
    ):
        """
        Initializes the deep-translator wrapper.

        Args:
            config_DeepTranslatorWrapper (TranslatorConfig): Configuration for the provider.
                Must contain a 'provider' key specifying which deep_translator to use.
            logger (logging.Logger): The logger instance for logging messages.
        """
        super().__init__(config_DeepTranslatorWrapper, logger)
        provider_DeepTranslatorWrapper = self.config_BaseTranslator.get("provider")
        if (
            not provider_DeepTranslatorWrapper
            or provider_DeepTranslatorWrapper
            not in self.DEEP_TRANSLATOR_MAP_DeepTranslatorWrapper
        ):
            raise ValueError(
                f"Unsupported or missing deep_translator provider: {provider_DeepTranslatorWrapper}"
            )

        self.translator_class_DeepTranslatorWrapper: Type[Any] = (
            self.DEEP_TRANSLATOR_MAP_DeepTranslatorWrapper[
                provider_DeepTranslatorWrapper
            ]
        )
        # The 'provider' key is for our factory, not for the deep-translator library itself.
        self.api_config_DeepTranslatorWrapper = {
            k: v for k, v in self.config_BaseTranslator.items() if k != "provider"
        }

    def _TranslateBatch(
        self,
        texts_TranslateBatch: List[str],
        source_lang_TranslateBatch: str,
        target_lang_TranslateBatch: str,
        context_before_TranslateBatch: Optional[List[str]] = None,
        context_after_TranslateBatch: Optional[List[str]] = None,
    ) -> List[str]:
        """
        Translates a batch of texts using the selected deep_translator provider.
        This method is called by the retry logic in the base class.
        """
        # Exceptions will be caught by the _TranslateWithRetry wrapper
        translator = self.translator_class_DeepTranslatorWrapper(
            source=source_lang_TranslateBatch,
            target=target_lang_TranslateBatch,
            **self.api_config_DeepTranslatorWrapper,
        )

        if self.debug_BaseTranslator:
            self.logger.debug_kv(
                "DeepTranslator Initialized",
                {
                    "provider": self.config_BaseTranslator.get("provider"),
                    "source_lang": source_lang_TranslateBatch,
                    "target_lang": target_lang_TranslateBatch,
                    "config": self.api_config_DeepTranslatorWrapper,
                },
            )

        # The `translate_batch` method is supported by deep_translator
        # Some translators might return None on failure, so we handle that.
        translated_batch = translator.translate_batch(texts_TranslateBatch)

        if self.debug_BaseTranslator:
            self.logger.debug_kv(
                "DeepTranslator Request/Response",
                {
                    "request": texts_TranslateBatch,
                    "response": translated_batch,
                },
            )

        if translated_batch is None:
            if self.debug_BaseTranslator:
                self.logger.warning(
                    f"[DeepTranslator] Provider '{self.config_BaseTranslator.get('provider')}' returned None. Fallback to original."
                )
            return texts_TranslateBatch

        return translated_batch

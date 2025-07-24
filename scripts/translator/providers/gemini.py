"""
This module provides the translator implementation for the Google Gemini API.
"""

import os
import time
import json
from typing import List, Dict, Optional
import google.generativeai as genai
from google.generativeai.types import GenerationConfig
from .base import BaseTranslator
from ..models.types import TranslatorConfig


import logging


class GeminiTranslator(BaseTranslator):
    """
    A translator that uses the Google Gemini API.
    """

    _last_request_time_GeminiTranslator: float = 0.0

    def __init__(
        self, config_GeminiTranslator: TranslatorConfig, logger: logging.Logger
    ):
        """
        Initializes the Gemini translator.

        Args:
            config_GeminiTranslator (TranslatorConfig): Configuration for the Gemini provider.
            logger (logging.Logger): The logger instance for logging messages.
        """
        super().__init__(config_GeminiTranslator, logger)
        api_key_GeminiTranslator: str | None = os.getenv(
            "GEMINI_API_KEY", self.config_BaseTranslator.get("api_key")
        )
        if not api_key_GeminiTranslator:
            raise ValueError(
                "Gemini API key not found. Please set the GEMINI_API_KEY environment variable "
                "or add the 'api_key' to the translator config in your i18n-rules.yml file."
            )

        genai.configure(api_key=api_key_GeminiTranslator)  # type: ignore

        self.model_GeminiTranslator = genai.GenerativeModel(  # type: ignore
            self.config_BaseTranslator.get("model", "gemini-1.5-flash")
        )
        self.generation_config_GeminiTranslator = GenerationConfig(
            temperature=self.config_BaseTranslator.get("temperature", 0.1)
        )
        self.rpm_GeminiTranslator: int = self.config_BaseTranslator.get("rpm", 30)
        self.tpm_GeminiTranslator: int = self.config_BaseTranslator.get("tpm", 250000)
        self.avg_tokens_per_text_GeminiTranslator: int = self.config_BaseTranslator.get(
            "avg_tokens_per_text", 50
        )

        # Auto-calculate batch_size only if it's not manually set in the config.
        if "batch_size" not in self.config_BaseTranslator and (
            self.tpm_GeminiTranslator > 0
            and self.rpm_GeminiTranslator > 0
            and self.avg_tokens_per_text_GeminiTranslator > 0
        ):
            texts_per_minute = (
                self.tpm_GeminiTranslator / self.avg_tokens_per_text_GeminiTranslator
            )
            calculated_batch_size = int(texts_per_minute / self.rpm_GeminiTranslator)
            self.batch_size_BaseTranslator = max(1, calculated_batch_size)

            if self.debug_BaseTranslator:
                self.logger.debug_kv(
                    "Auto Batch Size Calculation",
                    {
                        "provider": "gemini",
                        "tpm": self.tpm_GeminiTranslator,
                        "rpm": self.rpm_GeminiTranslator,
                        "avg_tokens_per_text": self.avg_tokens_per_text_GeminiTranslator,
                        "formula": "max(1, int((tpm / avg_tokens_per_text) / rpm))",
                        "calculated_batch_size": self.batch_size_BaseTranslator,
                    },
                )

        default_prompts_GeminiTranslator: Dict[str, str] = {
            "batch": (
                "You are an expert localization assistant. Your task is to translate a batch of text segments from {{src_lang}} to {{targ_lang}}.\n"
                "RULES:\n"
                "1. The user will provide a JSON string array. Each element is a text segment to be translated.\n"
                "2. Translate ONLY the natural language text within each string element.\n"
                "3. DO NOT translate or alter any code syntax, variables (e.g., `${...}`), or placeholders.\n"
                "4. Your response MUST be a valid JSON string array, containing the translated text for each corresponding element in the input array.\n"
                "5. Your response must contain ONLY the JSON array. No extra text, explanations, or pleasantries.\n\n"
                "Translate the text segments in the following JSON array:\n{{contxt}}"
            ),
            "single": (
                "You are an expert localization assistant. Your task is to translate a single text segment from {{src_lang}} to {{targ_lang}}.\n"
                "RULES:\n"
                "1. Translate ONLY the natural language text.\n"
                "2. DO NOT translate or alter any code syntax, variables (e.g., `${...}`), or placeholders.\n"
                "3. Your response must contain ONLY the translated text. No extra text, explanations, or pleasantries.\n\n"
                "Translate the following text:\n{{contxt}}"
            ),
        }
        prompts_config_GeminiTranslator: Dict[str, str] = (
            self.config_BaseTranslator.get("prompts", default_prompts_GeminiTranslator)
        )

        batch_prompt = prompts_config_GeminiTranslator.get("batch")
        if not batch_prompt:
            raise ValueError("Gemini provider configuration is missing 'batch' prompt.")
        self.batch_prompt_template_GeminiTranslator: str = batch_prompt

        single_prompt = prompts_config_GeminiTranslator.get("single")
        if not single_prompt:
            raise ValueError(
                "Gemini provider configuration is missing 'single' prompt."
            )
        self.single_prompt_template_GeminiTranslator: str = single_prompt

    def _format_context(
        self,
        context_before_TranslateBatch: Optional[List[str]],
        context_after_TranslateBatch: Optional[List[str]],
    ) -> str:
        """Formats the before and after context into a string for the prompt."""
        context_str = ""
        if context_before_TranslateBatch:
            context_str += "Context (before):\n" + "\n".join(
                f"- {text}" for text in context_before_TranslateBatch
            )
        if context_after_TranslateBatch:
            if context_str:
                context_str += "\n\n"
            context_str += "Context (after):\n" + "\n".join(
                f"- {text}" for text in context_after_TranslateBatch
            )
        return context_str

    def _TranslateBatch(
        self,
        texts_TranslateBatch: List[str],
        source_lang_TranslateBatch: str,
        target_lang_TranslateBatch: str,
        context_before_TranslateBatch: Optional[List[str]] = None,
        context_after_TranslateBatch: Optional[List[str]] = None,
    ) -> List[str]:
        """
        Translates a batch of texts using the Gemini API.
        This method is called by the retry logic in the base class.
        """
        # Rate limiting
        rpm = self.rpm_GeminiTranslator
        if isinstance(rpm, (int, float)) and rpm > 0:
            min_interval = 60.0 / rpm
            elapsed = time.time() - GeminiTranslator._last_request_time_GeminiTranslator
            if elapsed < min_interval:
                time.sleep(min_interval - elapsed)

        context_info = self._format_context(
            context_before_TranslateBatch, context_after_TranslateBatch
        )

        # Handle single text translation
        if len(texts_TranslateBatch) == 1:
            text_to_translate = texts_TranslateBatch[0]
            prompt = (
                self.single_prompt_template_GeminiTranslator.replace(
                    "{{src_lang}}", source_lang_TranslateBatch
                )
                .replace("{{targ_lang}}", target_lang_TranslateBatch)
                .replace("{{contxt}}", text_to_translate)
            )
        # Handle batch translation
        else:
            batch_text = json.dumps(texts_TranslateBatch, ensure_ascii=False)
            prompt = (
                self.batch_prompt_template_GeminiTranslator.replace(
                    "{{src_lang}}", source_lang_TranslateBatch
                )
                .replace("{{targ_lang}}", target_lang_TranslateBatch)
                .replace("{{contxt}}", batch_text)
            )

        # Add context to the prompt if it exists
        if context_info:
            prompt = f"{prompt}\n\n--- CONTEXT ---\n{context_info}"

        if self.debug_BaseTranslator:
            self.logger.debug_kv(
                "Gemini API Request",
                {
                    "model": self.model_GeminiTranslator.model_name,
                    "temperature": self.generation_config_GeminiTranslator.temperature,
                    "prompt": repr(prompt),
                },
            )

        # --- API Call ---
        # Exceptions will be caught by the _TranslateWithRetry wrapper
        response = self.model_GeminiTranslator.generate_content(
            prompt,
            generation_config=self.generation_config_GeminiTranslator,
        )
        GeminiTranslator._last_request_time_GeminiTranslator = time.time()

        if self.debug_BaseTranslator:
            self.logger.debug_kv(
                "Gemini API Response",
                {"response": repr(response)},
            )

        # --- Response Disassembly ---
        completion = response.text
        if not completion:
            if self.debug_BaseTranslator:
                self.logger.warning("[Gemini] Received an empty response from the API.")
            return texts_TranslateBatch

        # Handle single text response
        if len(texts_TranslateBatch) == 1:
            return [completion.strip()]

        # Handle batch response
        try:
            cleaned_completion = completion.strip()
            if cleaned_completion.startswith("```json"):
                cleaned_completion = cleaned_completion[7:]
            if cleaned_completion.endswith("```"):
                cleaned_completion = cleaned_completion[:-3]

            translated_texts = json.loads(cleaned_completion)
            if not isinstance(translated_texts, list):
                raise json.JSONDecodeError(
                    "Response is not a list.", cleaned_completion, 0
                )
        except json.JSONDecodeError:
            if self.debug_BaseTranslator:
                self.logger.warning(
                    f"[Gemini] Failed to decode JSON response: {completion}"
                )
            return texts_TranslateBatch

        if self.debug_BaseTranslator:
            self.logger.debug_kv(
                "Gemini Response Disassembly",
                {"disassembled_response": translated_texts},
            )

        if len(translated_texts) == len(texts_TranslateBatch):
            return translated_texts
        else:
            if self.debug_BaseTranslator:
                self.logger.warning(
                    f"[Gemini] Response count ({len(translated_texts)}) does not match request count ({len(texts_TranslateBatch)}). Fallback to original."
                )
            # Fallback to original texts if counts don't match
            return texts_TranslateBatch

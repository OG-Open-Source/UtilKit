"""
This module provides the translator implementation for the OpenAI API.
"""

import os
import time
import json
import logging
from typing import List, Dict, Any, Optional
from openai import OpenAI, OpenAIError
from .base import BaseTranslator
from ..models.types import TranslatorConfig


class OpenAITranslator(BaseTranslator):
    """
    A translator that uses the OpenAI Chat Completions API.
    """

    _last_request_time_OpenAITranslator: float = 0.0

    def __init__(
        self, config_OpenAITranslator: TranslatorConfig, logger: logging.Logger
    ):
        """
        Initializes the OpenAI translator.

        Args:
            config_OpenAITranslator (TranslatorConfig): Configuration for the OpenAI provider.
            logger (logging.Logger): The logger instance for logging messages.
        """
        super().__init__(config_OpenAITranslator, logger)
        api_key_OpenAITranslator: str | None = os.getenv(
            "OPENAI_API_KEY", self.config_BaseTranslator.get("api_key")
        )
        if not api_key_OpenAITranslator:
            raise ValueError(
                "OpenAI API key not found. Please set the OPENAI_API_KEY environment variable "
                "or add the 'api_key' to the translator config in your i18n-rules.yml file."
            )

        self.client_OpenAITranslator = OpenAI(
            api_key=api_key_OpenAITranslator,
            base_url=self.config_BaseTranslator.get("base_url"),
            max_retries=2,  # Add some default resilience
        )
        self.model_OpenAITranslator: str = self.config_BaseTranslator.get(
            "model", "gpt-4.1-nano"
        )
        self.temperature_OpenAITranslator: float = self.config_BaseTranslator.get(
            "temperature", 0.1
        )
        self.rpm_OpenAITranslator: int = self.config_BaseTranslator.get("rpm", 60)
        self.tpm_OpenAITranslator: int = self.config_BaseTranslator.get("tpm", 250000)
        self.avg_tokens_per_text_OpenAITranslator: int = self.config_BaseTranslator.get(
            "avg_tokens_per_text", 50
        )
        self.debug_OpenAITranslator: bool = self.config_BaseTranslator.get(
            "debug", False
        )

        # Auto-calculate batch_size only if it's not manually set in the config.
        if "batch_size" not in self.config_BaseTranslator and (
            self.tpm_OpenAITranslator > 0
            and self.rpm_OpenAITranslator > 0
            and self.avg_tokens_per_text_OpenAITranslator > 0
        ):
            texts_per_minute = (
                self.tpm_OpenAITranslator / self.avg_tokens_per_text_OpenAITranslator
            )
            calculated_batch_size = int(texts_per_minute / self.rpm_OpenAITranslator)
            self.batch_size_BaseTranslator = max(1, calculated_batch_size)

            if self.debug_BaseTranslator:
                self.logger.debug_kv(
                    "Auto Batch Size Calculation",
                    {
                        "provider": "openai",
                        "tpm": self.tpm_OpenAITranslator,
                        "rpm": self.rpm_OpenAITranslator,
                        "avg_tokens_per_text": self.avg_tokens_per_text_OpenAITranslator,
                        "formula": "max(1, int((tpm / avg_tokens_per_text) / rpm))",
                        "calculated_batch_size": self.batch_size_BaseTranslator,
                    },
                )

        default_prompts_OpenAITranslator: Dict[str, str] = {
            "system": (
                "You are an expert localization assistant. Your task is to translate a batch of text segments.\n"
                "RULES:\n"
                "1. The user will provide a JSON string array. Each element is a text segment to be translated.\n"
                "2. Translate ONLY the natural language text within each string element.\n"
                "3. DO NOT translate or alter any code syntax, variables (e.g., `${...}`), or placeholders.\n"
                "4. Your response MUST be a valid JSON string array, containing the translated text for each corresponding element in the input array.\n"
                "5. Your response must contain ONLY the JSON array. No extra text, explanations, or pleasantries."
            ),
            "user": "Translate the text segments in the following JSON array to {{lang}}.\n\n{{contxt}}",
            "single_system": (
                "You are an expert localization assistant. Your task is to translate a single text segment.\n"
                "RULES:\n"
                "1. Translate ONLY the natural language text.\n"
                "2. DO NOT translate or alter any code syntax, variables (e.g., `${...}`), or placeholders.\n"
                "3. Your response must contain ONLY the translated text. No extra text, explanations, or pleasantries."
            ),
            "single_user": "Translate the following text to {{lang}}.\n\n{{contxt}}",
        }
        prompts_config_OpenAITranslator: Dict[str, str] = (
            self.config_BaseTranslator.get("prompts", default_prompts_OpenAITranslator)
        )

        # Batch prompts
        system_prompt = prompts_config_OpenAITranslator.get("system")
        user_prompt = prompts_config_OpenAITranslator.get("user")
        if not system_prompt or not user_prompt:
            raise ValueError(
                "OpenAI provider configuration is missing 'system' or 'user' prompts."
            )
        self.system_prompt_template_OpenAITranslator: str = system_prompt
        self.user_prompt_template_OpenAITranslator: str = user_prompt

        # Single prompts
        single_system_prompt = prompts_config_OpenAITranslator.get("single_system")
        single_user_prompt = prompts_config_OpenAITranslator.get("single_user")
        if not single_system_prompt or not single_user_prompt:
            raise ValueError(
                "OpenAI provider configuration is missing 'single_system' or 'single_user' prompts."
            )
        self.single_system_prompt_template_OpenAITranslator: str = single_system_prompt
        self.single_user_prompt_template_OpenAITranslator: str = single_user_prompt

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
        Translates a batch of texts using the OpenAI API.
        This method is called by the retry logic in the base class.
        """
        # Rate limiting
        if self.rpm_OpenAITranslator > 0:
            min_interval = 60.0 / self.rpm_OpenAITranslator
            elapsed = time.time() - OpenAITranslator._last_request_time_OpenAITranslator
            if elapsed < min_interval:
                time.sleep(min_interval - elapsed)

        context_info = self._format_context(
            context_before_TranslateBatch, context_after_TranslateBatch
        )

        # Handle single text translation
        if len(texts_TranslateBatch) == 1:
            text_to_translate = texts_TranslateBatch[0]
            user_prompt_content = (
                self.single_user_prompt_template_OpenAITranslator.replace(
                    "{{src_lang}}", source_lang_TranslateBatch
                )
                .replace("{{targ_lang}}", target_lang_TranslateBatch)
                .replace("{{contxt}}", text_to_translate)
            )
            system_prompt_content = self.single_system_prompt_template_OpenAITranslator
        # Handle batch translation
        else:
            batch_text = json.dumps(texts_TranslateBatch, ensure_ascii=False)
            user_prompt_content = (
                self.user_prompt_template_OpenAITranslator.replace(
                    "{{src_lang}}", source_lang_TranslateBatch
                )
                .replace("{{targ_lang}}", target_lang_TranslateBatch)
                .replace("{{contxt}}", batch_text)
            )
            system_prompt_content = self.system_prompt_template_OpenAITranslator

        # Add context to the system prompt if it exists
        if context_info:
            system_prompt_content = (
                f"{system_prompt_content}\n\n--- CONTEXT ---\n{context_info}"
            )

        if self.debug_BaseTranslator:
            self.logger.debug_kv(
                "OpenAI API Request",
                {
                    "model": self.model_OpenAITranslator,
                    "temperature": self.temperature_OpenAITranslator,
                    "system_prompt": repr(system_prompt_content),
                    "user_prompt": repr(user_prompt_content),
                },
            )

        response = self.client_OpenAITranslator.chat.completions.create(
            model=self.model_OpenAITranslator,
            messages=[
                {"role": "system", "content": system_prompt_content},
                {"role": "user", "content": user_prompt_content},
            ],
            temperature=self.temperature_OpenAITranslator,
        )
        OpenAITranslator._last_request_time_OpenAITranslator = time.time()

        if self.debug_BaseTranslator:
            self.logger.debug_kv(
                "OpenAI API Response",
                {"response": repr(response)},
            )

        completion = response.choices[0].message.content
        if completion:
            # Handle single text response
            if len(texts_TranslateBatch) == 1:
                return [completion.strip()]
            # Handle batch response
            else:
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

                    if len(translated_texts) == len(texts_TranslateBatch):
                        return translated_texts
                    else:
                        if self.debug_BaseTranslator:
                            self.logger.warning(
                                f"[OpenAI] Response count ({len(translated_texts)}) does not match request count ({len(texts_TranslateBatch)}). Fallback to original."
                            )
                except json.JSONDecodeError:
                    if self.debug_BaseTranslator:
                        self.logger.warning(
                            f"[OpenAI] Failed to decode JSON response: {completion}"
                        )

        # Fallback to original texts on any failure
        return texts_TranslateBatch

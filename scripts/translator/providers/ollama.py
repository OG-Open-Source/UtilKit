"""
This module provides the translator implementation for a local Ollama service.
"""

import json
import logging
from typing import List, Dict, Any, Optional
import ollama
from .base import BaseTranslator
from ..models.types import TranslatorConfig


class OllamaTranslator(BaseTranslator):
    """
    A translator that uses a local Ollama Chat API.
    """

    def __init__(
        self, config_OllamaTranslator: TranslatorConfig, logger: logging.Logger
    ):
        """
        Initializes the Ollama translator.

        Args:
            config_OllamaTranslator (TranslatorConfig): Configuration for the Ollama provider.
            logger (logging.Logger): The logger instance for logging messages.
        """
        super().__init__(config_OllamaTranslator, logger)

        self.host_OllamaTranslator: str = self.config_BaseTranslator.get(
            "host", "http://localhost:11434"
        )
        model_OllamaTranslator = self.config_BaseTranslator.get("model")
        if not model_OllamaTranslator:
            raise ValueError(
                "Ollama provider configuration is missing the 'model' key."
            )
        self.model_OllamaTranslator: str = model_OllamaTranslator

        # Ollama client is configured globally via environment variables or defaults,
        # but we can create a client instance to specify a host.
        self.client_OllamaTranslator = ollama.Client(host=self.host_OllamaTranslator)

        default_prompts_OllamaTranslator: Dict[str, str] = {
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
        prompts_config_OllamaTranslator: Dict[str, str] = (
            self.config_BaseTranslator.get("prompts", default_prompts_OllamaTranslator)
        )

        # Batch prompts
        system_prompt = prompts_config_OllamaTranslator.get("system")
        user_prompt = prompts_config_OllamaTranslator.get("user")
        if not system_prompt or not user_prompt:
            raise ValueError(
                "Ollama provider configuration is missing 'system' or 'user' prompts."
            )
        self.system_prompt_template_OllamaTranslator: str = system_prompt
        self.user_prompt_template_OllamaTranslator: str = user_prompt

        # Single prompts
        single_system_prompt = prompts_config_OllamaTranslator.get("single_system")
        single_user_prompt = prompts_config_OllamaTranslator.get("single_user")
        if not single_system_prompt or not single_user_prompt:
            raise ValueError(
                "Ollama provider configuration is missing 'single_system' or 'single_user' prompts."
            )
        self.single_system_prompt_template_OllamaTranslator: str = single_system_prompt
        self.single_user_prompt_template_OllamaTranslator: str = single_user_prompt

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
        Translates a batch of texts using the Ollama API.
        """
        context_info = self._format_context(
            context_before_TranslateBatch, context_after_TranslateBatch
        )

        # Handle single text translation
        if len(texts_TranslateBatch) == 1:
            text_to_translate = texts_TranslateBatch[0]
            user_prompt_content = (
                self.single_user_prompt_template_OllamaTranslator.replace(
                    "{{src_lang}}", source_lang_TranslateBatch
                )
                .replace("{{targ_lang}}", target_lang_TranslateBatch)
                .replace("{{contxt}}", text_to_translate)
            )
            system_prompt_content = self.single_system_prompt_template_OllamaTranslator
        # Handle batch translation
        else:
            batch_text = json.dumps(texts_TranslateBatch, ensure_ascii=False)
            user_prompt_content = (
                self.user_prompt_template_OllamaTranslator.replace(
                    "{{src_lang}}", source_lang_TranslateBatch
                )
                .replace("{{targ_lang}}", target_lang_TranslateBatch)
                .replace("{{contxt}}", batch_text)
            )
            system_prompt_content = self.system_prompt_template_OllamaTranslator

        # Add context to the system prompt if it exists
        if context_info:
            system_prompt_content = (
                f"{system_prompt_content}\n\n--- CONTEXT ---\n{context_info}"
            )

        if self.debug_BaseTranslator:
            self.logger.debug_kv(
                "Ollama API Request",
                {
                    "model": self.model_OllamaTranslator,
                    "host": self.host_OllamaTranslator,
                    "system_prompt": repr(system_prompt_content),
                    "user_prompt": repr(user_prompt_content),
                },
            )

        response = self.client_OllamaTranslator.chat(
            model=self.model_OllamaTranslator,
            messages=[
                {"role": "system", "content": system_prompt_content},
                {"role": "user", "content": user_prompt_content},
            ],
        )

        completion = response["message"]["content"]
        if self.debug_BaseTranslator:
            self.logger.debug_kv(
                "Ollama API Response",
                {"response": repr(completion)},
            )

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
                                f"[Ollama] Response count ({len(translated_texts)}) does not match request count ({len(texts_TranslateBatch)}). Fallback to original."
                            )
                except json.JSONDecodeError:
                    if self.debug_BaseTranslator:
                        self.logger.warning(
                            f"[Ollama] Failed to decode JSON response: {completion}"
                        )

        return texts_TranslateBatch

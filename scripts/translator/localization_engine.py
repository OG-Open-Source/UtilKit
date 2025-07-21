import os
import re
import json
import yaml
import random
import string
from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional
from openai import OpenAI
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
)

# --- Constants ---
# Directories to scan for i18n-rules files relative to the project root.
TARGET_DIRS: List[str] = ["/", "/sh", "/shx"]

# --- Translator Abstraction ---


class Translator(ABC):
    @abstractmethod
    def translate(self, text: str, source_lang: str, target_lang: str) -> str:
        pass


class OpenAITranslator(Translator):
    def __init__(self, config: Dict[str, Any]):
        api_key: Optional[str] = os.getenv("OPENAI_API_KEY", config.get("api_key"))
        if not api_key:
            raise ValueError(
                "OpenAI API key not found in config or environment variables."
            )

        self.client = OpenAI(api_key=api_key, base_url=config.get("base_url"))
        self.model: str = config.get("model", "gpt-3.5-turbo")
        self.prompts: Dict[str, str] = config.get("prompts", {})
        self.default_prompts: Dict[str, str] = {
            "system": "You are a professional {{to}} native translator...",
            "user": "Translate to {{to}}: {{text}}",
        }

    def translate(self, text: str, source_lang: str, target_lang: str) -> str:
        system_prompt: str = self.prompts.get("system", self.default_prompts["system"])
        user_prompt: str = self.prompts.get("user", self.default_prompts["user"])

        system_prompt = system_prompt.replace("{{to}}", target_lang)
        user_prompt = user_prompt.replace("{{to}}", target_lang).replace(
            "{{text}}", text
        )

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0,
            )
            completion = response.choices[0].message.content
            return completion.strip() if completion else text
        except Exception as e:
            print(f"Error during OpenAI translation: {e}")
            return text


class DeepTranslatorWrapper(Translator):
    DEEP_TRANSLATOR_MAP: Dict[str, Any] = {
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
    }

    def __init__(self, provider: str):
        if provider not in self.DEEP_TRANSLATOR_MAP:
            raise ValueError(f"Unsupported deep_translator provider: {provider}")
        self.translator_class: Any = self.DEEP_TRANSLATOR_MAP[provider]

    def translate(self, text: str, source_lang: str, target_lang: str) -> str:
        try:
            translator = self.translator_class(source=source_lang, target=target_lang)
            translated_text = translator.translate(text)
            return translated_text if translated_text else text
        except Exception as e:
            print(f"Error during {self.translator_class.__name__} translation: {e}")
            return text


def translator_factory(config: Dict[str, Any]) -> Translator:
    """Creates a translator instance based on the configuration."""
    provider: str = config.get("provider", "google").lower()
    if provider == "openai":
        return OpenAITranslator(config.get("config", {}))
    else:
        return DeepTranslatorWrapper(provider)


# --- Core Logic ---


def generate_random_key(length: int = 6) -> str:
    """Generates a unique random key."""
    chars: str = string.ascii_letters + string.digits
    return "".join(random.choices(chars, k=length))


def find_config_files() -> List[str]:
    """Finds all i18n-rules configuration files in the target directories."""
    config_files: List[str] = []
    project_root: str = os.getcwd()
    for target_dir in TARGET_DIRS:
        search_dir: str = os.path.join(project_root, target_dir.strip("/\\"))
        config_path_base: str = os.path.join(search_dir, ".ogos", "i18n-rules")
        for ext in [".yml", ".yaml"]:
            config_path: str = f"{config_path_base}{ext}"
            if os.path.exists(config_path):
                config_files.append(config_path)
    return config_files


def process_file(
    src_path: str,
    intl_path: str,
    extraction_rules: List[Dict[str, Any]],
    lang_config: Dict[str, Any],
    config_dir: str,
) -> tuple[str, Dict[str, Any]]:
    """Extracts strings, replaces them with keys, and updates the JSON file."""
    # Construct absolute paths based on the config file's directory
    src_path = os.path.join(config_dir, src_path)
    intl_path = os.path.join(config_dir, intl_path)
    
    print(f"--- Processing file: {src_path} ---")

    json_path: str = f"{intl_path}.json"

    translations: Dict[str, Any] = {}
    if os.path.exists(json_path):
        with open(json_path, "r", encoding="utf-8") as f:
            try:
                translations = json.load(f)
            except json.JSONDecodeError:
                print(
                    f"Warning: Could not decode JSON from {json_path}. Starting fresh."
                )

    source_lang: str = lang_config["source"]
    if source_lang not in translations:
        translations[source_lang] = {}

    value_to_key_map: Dict[str, str] = {
        v: k for k, v in translations[source_lang].items()
    }

    with open(src_path, "r", encoding="utf-8") as f:
        content: str = f.read()

    updated_content: str = content
    new_strings_found: bool = False

    for rule in extraction_rules:
        pattern = re.compile(rule["pattern"])
        for match in pattern.finditer(content):
            original_string: str = match.group(rule["capture_group"])

            if original_string in value_to_key_map:
                key: str = value_to_key_map[original_string]
            else:
                while True:
                    key = generate_random_key()
                    if key not in translations[source_lang]:
                        break
                translations[source_lang][key] = original_string
                value_to_key_map[original_string] = key
                new_strings_found = True

            full_match: str = match.group(0)
            replacement: str = full_match.replace(
                f'"{original_string}"', f'"*#{key}#*"'
            )
            updated_content = updated_content.replace(full_match, replacement)

    os.makedirs(os.path.dirname(intl_path), exist_ok=True)
    with open(intl_path, "w", encoding="utf-8") as f:
        f.write(updated_content)
    print(f"Generated internationalized file: {intl_path}")

    if new_strings_found:
        os.makedirs(os.path.dirname(json_path), exist_ok=True)
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(translations, f, ensure_ascii=False, indent=2)
        print(f"Updated translation JSON: {json_path}")

    return json_path, translations


def translate_json(
    json_path: str,
    translations: Dict[str, Any],
    lang_config: Dict[str, Any],
    translator: Translator,
) -> None:
    """Translates the strings in the JSON file."""
    if not translations:
        return

    print(f"--- Translating strings for: {os.path.basename(json_path)} ---")
    source_lang: str = lang_config["source"]
    target_langs: List[str] = lang_config["targets"]
    lang_map: Dict[str, str] = lang_config.get("map", {})

    source_lang_api: str = lang_map.get(source_lang, source_lang)

    translation_updated: bool = False
    for target_lang in target_langs:
        if target_lang not in translations:
            translations[target_lang] = {}

        target_lang_api: str = lang_map.get(target_lang, target_lang)

        for key, text in translations[source_lang].items():
            if (
                key not in translations[target_lang]
                or not translations[target_lang][key]
            ):
                print(f"Translating '{text}' to {target_lang}...")
                translated_text = translator.translate(
                    text, source_lang_api, target_lang_api
                )
                translations[target_lang][key] = translated_text
                translation_updated = True

    if translation_updated:
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(translations, f, ensure_ascii=False, indent=2)
        print(f"Finished translations for: {os.path.basename(json_path)}")


def main() -> None:
    """Main function to run the localization pipeline."""
    config_files: List[str] = find_config_files()
    if not config_files:
        print("No i18n-rules.yaml or .yml files found in target directories.")
        return

    for config_path in config_files:
        print(f"\n=== Processing config file: {config_path} ===")
        config_dir = os.path.dirname(os.path.dirname(config_path)) # Get the directory containing .ogos
        with open(config_path, "r", encoding="utf-8") as f:
            config: Dict[str, Any] = yaml.safe_load(f)

        lang_config: Dict[str, Any] = config.get("languages", {})

        for rule_set in config.get("file_rules", []):
            print(
                f"\n-- Applying rule set: '{rule_set.get('name', 'Unnamed Rule')}' --"
            )
            translator_config: Dict[str, Any] = rule_set.get("translator", {})
            translator: Translator = translator_factory(translator_config)

            file_mapping: Dict[str, str] = rule_set.get("file_mapping", {})
            extraction_rules: List[Dict[str, Any]] = rule_set.get(
                "extraction_rules", []
            )

            for src_path, intl_path in file_mapping.items():
                json_path, translations = process_file(
                    src_path, intl_path, extraction_rules, lang_config, config_dir
                )
                translate_json(json_path, translations, lang_config, translator)


if __name__ == "__main__":
    main()

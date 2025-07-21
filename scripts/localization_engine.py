import os
import sys
import re
import json
import yaml
import hashlib
from deep_translator import GoogleTranslator

# --- Language Code Mapping ---
# Maps commonly used language codes to the format supported by deep_translator
LANGUAGE_MAP = {
    'zh-Hant': 'zh-TW',
    'zh-Hans': 'zh-CN',
    'tw': 'zh-TW',
    'cn': 'zh-CN',
    'jp': 'ja',
    'kr': 'ko',
    'ir': 'fa'
}


def GetConf(src_file_path):
    """Loads the i18n-rules.yml configuration file."""
    config_path = os.path.join(os.path.dirname(src_file_path), '.ogos',
                               'i18n-rules.yml')
    if not os.path.exists(config_path):
        # Fallback to a root-level config if it exists
        root_config_path = os.path.join(os.getcwd(), '.ogos', 'i18n-rules.yml')
        if os.path.exists(root_config_path):
            config_path = root_config_path
        else:
            print(
                f"Error: Configuration file not found at {config_path} or in the project root."
            )
            return None
    with open(config_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def ExtractStr(src_file_path, rules):
    """Extracts strings from a source file based on regex rules."""
    extracted_strings = {}
    with open(src_file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    for rule in rules:
        if rule.get('type') == 'regex':
            pattern = re.compile(rule['pattern'])
            for match in pattern.finditer(content):
                # Use a hash of the string as a stable key
                original_string = match.group(rule['capture_group'])
                string_hash = hashlib.md5(original_string.encode()).hexdigest()
                key = f"*#{string_hash[:8]}#*"
                if key not in extracted_strings:
                    extracted_strings[key] = original_string
    return extracted_strings


def UpdTransFile(json_path, strings, config):
    """Creates or updates the translation JSON file."""
    if os.path.exists(json_path):
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    else:
        data = {lang: {} for lang in config['languages']['targets']}
        data[config['languages']['source']] = {}

    source_lang = config['languages']['source']

    # Add new strings to the source language
    updated = False
    for key, value in strings.items():
        if key not in data[source_lang]:
            data[source_lang][key] = value
            updated = True

    if updated:
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"Updated translation file with new strings: {json_path}")
    return data


def TranStrs(json_path, config):
    """Translates strings using the configured translator."""
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    source_lang_code = config['languages']['source']
    source_lang_api = LANGUAGE_MAP.get(source_lang_code, source_lang_code)

    translator_name = config.get('translator', 'google')
    translator = GoogleTranslator(source=source_lang_api)

    for target_lang_code in config['languages']['targets']:
        target_lang_api = LANGUAGE_MAP.get(target_lang_code, target_lang_code)
        translator.target = target_lang_api

        if target_lang_code not in data:
            data[target_lang_code] = {}

        for key, text in data[source_lang_code].items():
            if data[target_lang_code].get(key) in [None, ""]:
                try:
                    translated_text = translator.translate(text)
                    data[target_lang_code][key] = translated_text
                    print(
                        f"Translated '{text}' to '{translated_text}' ({target_lang_code})"
                    )
                except Exception as e:
                    print(
                        f"Could not translate '{text}' to {target_lang_code}: {e}"
                    )
                    data[target_lang_code][key] = text  # Fallback

    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Auto-translation complete for {json_path}")


def GenLocalizdFile(src_file_path, json_path, config):
    """Generates the final localized files."""
    dir_name = os.path.dirname(src_file_path)
    base_name = os.path.basename(src_file_path).replace('.src.', '.')

    with open(src_file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    with open(json_path, 'r', encoding='utf-8') as f:
        translations = json.load(f)

    # Create the internationalized (placeholder) version
    intl_content = content
    for key, value in translations[config['languages']['source']].items():
        intl_content = intl_content.replace(f'"{value}"', f'"{key}"')

    intl_file_path = os.path.join(dir_name, base_name)
    with open(intl_file_path, 'w', encoding='utf-8') as f:
        f.write(intl_content)
    print(f"Generated internationalized file: {intl_file_path}")

    # Create localized versions
    localized_dir = os.path.join(dir_name, 'localized')
    os.makedirs(localized_dir, exist_ok=True)

    for lang, lang_translations in translations.items():
        localized_content = intl_content
        for key, value in lang_translations.items():
            # Basic escaping for sed-like replacement
            escaped_value = value.replace('\\', '\\\\').replace('"', '\\"')
            localized_content = localized_content.replace(
                f'"{key}"', f'"{escaped_value}"')

        # Use original language code for filename
        output_filename = f"{os.path.splitext(base_name)[0]}_{lang}{os.path.splitext(base_name)[1]}"
        output_path = os.path.join(localized_dir, output_filename)
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(localized_content)
        print(f"Generated localized file: {output_path}")


def main(src_file_path):
    """Main function to run the localization pipeline."""
    print(f"--- Starting localization for: {src_file_path} ---")
    config = GetConf(src_file_path)
    if not config:
        return

    # Define file paths
    dir_name = os.path.dirname(src_file_path)
    base_name = os.path.basename(src_file_path).replace('.src.', '.')
    json_path = os.path.join(dir_name, f"{base_name}.json")

    # Run the pipeline
    extracted = ExtractStr(src_file_path, config.get('extraction_rules', []))
    UpdTransFile(json_path, extracted, config)
    TranStrs(json_path, config)
    GenLocalizdFile(src_file_path, json_path, config)
    print(f"--- Finished localization for: {src_file_path} ---")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python localization_engine.py <path_to_source_file>")
        sys.exit(1)

    main(sys.argv[1])

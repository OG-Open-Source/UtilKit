import sys
import json
from deep_translator import GoogleTranslator


def translate_file(json_path):
    """
    Opens a JSON file, translates texts from zh-Hant to other languages,
    and updates the file in-place.
    """
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"Error reading or parsing JSON file {json_path}: {e}")
        sys.exit(1)

    # Assume zh-Hant contains the source texts
    if 'zh-Hant' not in data:
        print(f"Error: 'zh-Hant' key not found in {json_path}")
        return

    source_texts = data.get('zh-Hant', {})

    # Ensure other language keys exist
    if 'en' not in data:
        data['en'] = {}
    if 'zh-Hans' not in data:
        data['zh-Hans'] = {}

    for key, text in source_texts.items():
        # Only translate if the text is not already translated or is empty
        if data.get('en', {}).get(key) in [None, ""]:
            try:
                translated_en = GoogleTranslator(source='zh-TW',
                                                 target='en').translate(text)
                data['en'][key] = translated_en
                print(f"Translated '{text}' to '{translated_en}' (en)")
            except Exception as e:
                print(f"Could not translate '{text}' to en: {e}")
                data['en'][key] = text  # Fallback to source text

        if data.get('zh-Hans', {}).get(key) in [None, ""]:
            try:
                translated_zh_hans = GoogleTranslator(
                    source='zh-TW', target='zh-CN').translate(text)
                data['zh-Hans'][key] = translated_zh_hans
                print(
                    f"Translated '{text}' to '{translated_zh_hans}' (zh-Hans)")
            except Exception as e:
                print(f"Could not translate '{text}' to zh-Hans: {e}")
                data['zh-Hans'][key] = text  # Fallback to source text

    try:
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"Successfully updated translations in {json_path}")
    except IOError as e:
        print(f"Error writing to file {json_path}: {e}")
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python translator.py <path_to_json_file>")
        sys.exit(1)

    json_file_path = sys.argv[1]
    translate_file(json_file_path)

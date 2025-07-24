# Modular Localization and Translation Tool

## 1. Overview

This tool provides a powerful and extensible pipeline for automating the localization of source code and other text-based files. It scans files based on user-defined rules, extracts hard-coded strings, manages translations through various providers, and compiles final, localized versions of the files.

The entire process is driven by two simple configuration files, making it easy to integrate into any project.

## 2. Core Features

- **Configuration-Driven**: All behavior is controlled through `translator_config.json` and `.ogos/i18n-rules.yml` files.
- **Rule-Based String Extraction**: Use regular expressions to define precisely which strings to extract from your source files.
- **Robust Communication Protocol**: Uses JSON arrays for sending and receiving batch translations, preventing parsing errors from special characters.
- **Pluggable Translation Providers**: Natively supports **OpenAI**, **Gemini**, and local **Ollama** instances. It also integrates with the `deep-translator` library to support over 10 additional providers like **Google Translate**, **DeepL**, and more.
- **Extensible Architecture**: Easily add new translation providers by implementing a simple base class.
- **Resilient API Handling**: Automatically handles batch processing and retry logic to work efficiently and reliably with translation APIs.

## 3. How It Works

The localization process consists of four main stages, all orchestrated by running a single command:

1.  **Configuration Loading**: The tool first looks for `translator_config.json` to determine where to find your rule files.
2.  **String Extraction**: It then scans the source files defined in your `.ogos/i18n-rules.yml`, using your regex rules to find and extract strings. These strings are stored in a central `.json` translation file, and the source file is converted into a template file with placeholders.
3.  **Automated Translation**: The tool identifies any new strings that need translation. It batches them and sends them to your chosen translation provider (e.g., Gemini, OpenAI, DeepL).
4.  **File Compilation**: Finally, it uses the completed translation files to compile the final, localized versions of your source files for each target language.

## 4. Installation

1.  Navigate to the `scripts/translator` directory.
2.  Install the required Python packages:
    ```bash
    pip install -r requirements.txt
    ```
3.  Set up your API keys as environment variables. This is the recommended and most secure method.
    ```bash
    export OPENAI_API_KEY="your-openai-api-key"
    export GEMINI_API_KEY="your-gemini-api-key"
    # For providers like DeepL, check their respective documentation for env var names.
    ```
    Alternatively, you can place API keys directly in your `i18n-rules.yml` file, but this is not recommended.

## 5. How to Use

To run the entire localization pipeline, execute the main script as a module from your project's **root directory**:

```bash
python -m scripts.translator
```

To enable verbose logging for debugging, which shows detailed API requests and responses, use the `--debug` flag:

```bash
python -m scripts.translator --debug
```

## 6. Configuration

The tool is controlled by two main configuration files. For a complete, commented example of `i18n-rules.yml`, see **[.ogos/i18n-rules.ex.yaml](.ogos/i18n-rules.ex.yaml)**.

### `translator_config.json`

This file tells the tool where to look for your `.ogos/i18n-rules.yml` files. It should be placed in the same directory where you run the script (usually the project root).

- **`search_directories`**: A list of directories (relative to the project root) that the tool should scan.

**Example `translator_config.json`:**

```json
{
  "search_directories": ["/", "/sh", "/shx"]
}
```

This configuration will make the tool search for:

- `./.ogos/i18n-rules.yml`
- `./sh/.ogos/i18n-rules.yml`
- `./shx/.ogos/i18n-rules.yml`

### `.ogos/i18n-rules.yml`

This is the core file that defines the localization tasks for a specific directory. It supports one optional top-level setting:

- **`output_dir`** (Optional): Specifies a custom output directory for the compiled localized files. If not set, files will be placed in a `localized` folder at the same level as the `.ogos` folder.

**Example with `output_dir`:**

```yaml
# This will place compiled files in 'dist/my-scripts'
output_dir: "dist/my-scripts"

languages:
  source: en
  # ...
```

#### `languages` Block

This block defines the source and target languages for the translation tasks in this file.

- **`source`**: The language code of the original text (e.g., `en`).
- **`targets`**: A list of language codes you want to translate into (e.g., `zh-Hant`, `ja`).
- **`map`** (Optional): A dictionary to map your language codes to API-specific codes if they differ.

**Example `languages` block:**

```yaml
languages:
  source: en
  targets:
    - zh-Hant
    - ja
  map:
    zh-Hant: "zh" # Map to DeepL's code for Traditional Chinese
```

#### `file_rules` Block

This is a list of rule sets. Each rule set defines a complete localization task for one or more files.

- **`name`**: A descriptive name for the rule set.
- **`file_mapping`**: A dictionary mapping a source file to its internationalized template file.
- **`extraction_rules`**: A list of regex rules to extract strings.
  - `pattern`: The regular expression to find the string.
  - `capture_group`: The index of the capturing group that contains the text.
- **`translator`**: The configuration for the translation provider.

#### `translator` Block

This block configures the translation provider for a specific rule set.

- **`provider`**: The name of the translation service to use (e.g., `gemini`, `openai`, `deepl`).
- **`batch_size`** (Optional): Manually sets the number of texts to process in a single API call. **If you set this, automatic calculation is disabled.** If left unset, the tool will either use a default of `100` or calculate an optimal batch size if you provide the settings below.
- **`prompts`** (Optional, for `openai`, `gemini`, `ollama`): Allows you to override the default system and user prompts. This is useful for tailoring the instructions to your specific needs.
- **`context`** (Optional): Provides surrounding text to the model to improve translation quality for strings that depend on each other.
  - `before`: The number of preceding text segments to include.
  - `after`: The number of succeeding text segments to include.
- **Provider-Specific Options**: Other options like `model` and `api_key` are passed directly.

**Automatic Batch Size Calculation (for OpenAI and Gemini):**

If `batch_size` is not manually set, you can provide the following parameters to let the tool calculate an optimal batch size to maximize throughput without hitting API rate limits.

- **`rpm`** (Requests Per Minute): Your API key's limit for requests per minute.
- **`tpm`** (Tokens Per Minute): Your API key's limit for tokens per minute.
- **`avg_tokens_per_text`** (Optional): An estimate of the average token count per text segment. Defaults to `50`.

**Improving Translation Quality with `context`:**

To get more accurate translations for related texts (like consecutive lines in a script), you can use the `context` block. This sends nearby strings to the model along with the text to be translated, giving it a better understanding of the surrounding dialogue or narrative.

**Example `translator` block with `context`:**

```yaml
translator:
  provider: "openai"
  model: "gpt-4o-mini"
  batch_size: 10
  context:
    before: 2 # Include the 2 previous strings
    after: 2  # Include the 2 next strings
```

#### Using `deep_translator` Providers

This tool integrates the `deep_translator` library to give you access to a wide range of providers. To use one, simply set the `provider` name to one of the supported services.

The following table lists the available providers and whether they typically require an API key.

| Provider Name | API Key Required? | Notes                                  |
| :------------ | :---------------: | :------------------------------------- |
| `google`      |        No         | Default free provider.                 |
| `deepl`       |        Yes        | Requires a DeepL API key.              |
| `microsoft`   |        Yes        | Requires Microsoft Translator API key. |
| `mymemory`    |        No         | Free provider.                         |
| `yandex`      |        Yes        | Requires Yandex Translate API key.     |
| `baidu`       |        Yes        | Requires Baidu Translate API key.      |
| `papago`      |        Yes        | Requires Naver Papago API key.         |
| `qcri`        |        Yes        | Requires QCRI API key.                 |
| `pons`        |        No         | Dictionary-based, for words/phrases.   |
| `linguee`     |        No         | Dictionary-based, for words/phrases.   |
| `libre`       |        No         | Free, open-source translation.         |

**Configuration for `deep_translator`:**

For providers that require an API key, add the `api_key` parameter directly inside the `translator` block.

**Example for DeepL:**

```yaml
translator:
  provider: "deepl"
  api_key: "YOUR_DEEPL_API_KEY" # Or set DEEPL_API_KEY environment variable
  batch_size: 50
```

## 7. How to Extend

Adding a new, custom translation provider is straightforward:

1.  **Create a New File**: In `scripts/translator/providers/`, create a file (e.g., `my_translator.py`).
2.  **Implement the Class**: Create a class that inherits from `BaseTranslator` and implements the `_TranslateBatch` method.
3.  **Register in the Factory**: Open `scripts/translator/providers/__init__.py` and add your new class to the `CreateTranslator` factory function.
4.  **Update Configuration**: You can now use your new provider's name in your `i18n-rules.yml` files.

# 模組化本地化與翻譯工具

## 1. 總覽

本工具提供一個強大且可擴充的流程，用於自動化原始碼和其他基於文字的檔案的本地化作業。它會根據使用者定義的規則掃描檔案、提取寫死的字串、透過各種提供者管理翻譯，並最終編譯出本地化版本的檔案。

整個流程由兩個簡單的組態檔驅動，使其能輕鬆整合到任何專案中。

## 2. 核心功能

- **組態驅動**：所有行為都由 `translator_config.json` 和 `.ogos/i18n-rules.yml` 檔案控制。
- **基於規則的字串提取**：使用正規表示式精確定義要從原始檔案中提取哪些字串。
- **穩健的通訊協定**：使用 JSON 陣列來發送和接收批次翻譯，防止特殊字元導致的解析錯誤。
- **可插拔的翻譯提供者**：原生支援 **OpenAI**、**Gemini** 以及本地的 **Ollama** 實例。此外，它還整合了 `deep-translator` 函式庫以支援超過 10 種額外的提供者，如 **Google 翻譯**、**DeepL** 等。
- **可擴充的架構**：透過實作一個簡單的基底類別，輕鬆新增新的翻譯提供者。
- **彈性的 API 處理**：自動處理批次請求和重試邏輯，以高效且可靠地與翻譯 API 協同工作。

## 3. 運作方式

本地化過程包含四個主要階段，全部透過執行一個指令來調度：

1.  **載入組態**：工具首先尋找 `translator_config.json` 以確定您的規則檔案在哪裡。
2.  **提取字串**：接著，它會掃描您在 `.ogos/i18n-rules.yml` 中定義的原始檔案，使用您的正規表示式規則尋找並提取字串。這些字串會被儲存在一個中央的 `.json` 翻譯檔中，而原始檔案則被轉換為帶有佔位符的範本檔案。
3.  **自動翻譯**：工具會識別出任何需要翻譯的新字串。它會將這些字串分批處理，並發送給您選擇的翻譯提供者（例如 Gemini、OpenAI、DeepL）。
4.  **編譯檔案**：最後，它會使用已完成的翻譯檔案，為每個目標語言編譯出最終的、本地化的原始檔案版本。

## 4. 安裝

1.  切換到 `scripts/translator` 目錄。
2.  安裝所需的 Python 套件：
    ```bash
    pip install -r requirements.txt
    ```
3.  設定您的 API 金鑰作為環境變數。這是建議且最安全的方法。
    ```bash
    export OPENAI_API_KEY="your-openai-api-key"
    export GEMINI_API_KEY="your-gemini-api-key"
    # 對於像 DeepL 這樣的提供者，請查閱其各自的文件以了解環境變數的名稱。
    ```
    或者，您可以將 API 金鑰直接放在 `i18n-rules.yml` 檔案中，但不建議這樣做。

## 5. 如何使用

若要執行整個本地化流程，請從您專案的**根目錄**以模組形式執行主腳本：

```bash
python -m scripts.translator
```

若要啟用詳細日誌以進行偵錯（會顯示詳細的 API 請求和回應），請使用 `--debug` 旗標：

```bash
python -m scripts.translator --debug
```

## 6. 組態

本工具由兩個主要的組態檔控制。關於 `i18n-rules.yml` 的完整、附有註解的範例，請參閱 **[.ogos/i18n-rules.ex.yaml](.ogos/i18n-rules.ex.yaml)**。

### `translator_config.json`

這個檔案告訴工具要去哪裡尋找您的 `.ogos/i18n-rules.yml` 檔案。它應該被放在您執行腳本的同一個目錄下（通常是專案根目錄）。

- **`search_directories`**：一個目錄列表（相對於專案根目錄），工具應該掃描這些目錄。

**`translator_config.json` 範例：**

```json
{
  "search_directories": ["/", "/sh", "/shx"]
}
```

此組態將使工具搜尋：

- `./.ogos/i18n-rules.yml`
- `./sh/.ogos/i18n-rules.yml`
- `./shx/.ogos/i18n-rules.yml`

### `.ogos/i18n-rules.yml`

這是核心檔案，定義了特定目錄的本地化任務。它支援一個可選的頂層設定：

- **`output_dir`** (可選)：指定編譯後的本地化檔案的自訂輸出目錄。如果未設定，檔案將被放置在與 `.ogos` 資料夾相同層級的一個 `localized` 資料夾中。

**使用 `output_dir` 的範例：**

```yaml
# 這會將編譯後的檔案放置在 'dist/my-scripts' 中
output_dir: "dist/my-scripts"

languages:
  source: en
  # ...
```

#### `languages` 區塊

此區塊定義了此檔案中翻譯任務的來源和目標語言。

- **`source`**：原始文本的語言代碼（例如 `en`）。
- **`targets`**：您想要翻譯成的語言代碼列表（例如 `zh-Hant`, `ja`）。
- **`map`** (可選)：一個字典，用於將您的語言代碼對應到 API 特定的代碼（如果它們不同的話）。

**`languages` 區塊範例：**

```yaml
languages:
  source: en
  targets:
    - zh-Hant
    - ja
  map:
    zh-Hant: "zh" # 對應到 DeepL 的繁體中文代碼
```

#### `file_rules` 區塊

這是一個規則集的列表。每個規則集為一或多個檔案定義了一個完整的本地化任務。

- **`name`**：規則集的描述性名稱。
- **`file_mapping`**：一個字典，將原始檔案對應到其國際化的範本檔案。
- **`extraction_rules`**：一個用於提取字串的正規表示式規則列表。
  - `pattern`：用於尋找字串的正規表示式。
  - `capture_group`：包含文本的捕獲組索引。
- **`translator`**：翻譯提供者的組態。

#### `translator` 區塊

此區塊為特定的規則集設定翻譯提供者。

- **`provider`**：要使用的翻譯服務名稱（例如 `gemini`, `openai`, `deepl`）。
- **`batch_size`** (可選)：手動設定單一 API 呼叫中要處理的文本數量。**如果您設定了此項，將會停用自動計算功能。** 如果留空，工具將使用預設值 `100`，或者在您提供了以下設定時自動計算最佳批次大小。
- **`prompts`** (可選, 適用於 `openai`, `gemini`, `ollama`)：允許您覆寫預設的系統和使用者提示詞。這對於根據您的具體需求自訂指令非常有用。
- **`context`** (可選)：提供周圍的文本給模型，以提高相互關聯的字串的翻譯品質。
  - `before`：要包含的前文字串數量。
  - `after`：要包含的後文字串數量。
- **提供者特定選項**：其他選項如 `model` 和 `api_key` 等，都直接在此設定。

**自動批次大小計算 (適用於 OpenAI 和 Gemini)：**

如果您沒有手動設定 `batch_size`，可以提供以下參數，讓工具計算出一個最佳的批次大小，以在不觸及 API 速率限制的情況下最大化處理效率。

- **`rpm`** (Requests Per Minute)：您的 API 金鑰每分鐘的請求次數限制。
- **`tpm`** (Tokens Per Minute)：您的 API 金鑰每分鐘的權杖數量限制。
- **`avg_tokens_per_text`** (可選)：每個文本片段的平均權杖數估計值。預設為 `50`。

**使用 `context` 提升翻譯品質：**

對於相關聯的文本（例如腳本中的連續行），您可以使用 `context` 區塊來獲得更準確的翻譯。這會將鄰近的字串連同要翻譯的文本一起發送給模型，使其能更好地理解對話或敘述的上下文。

**使用 `context` 的 `translator` 區塊範例：**

```yaml
translator:
  provider: "openai"
  model: "gpt-4o-mini"
  batch_size: 10
  context:
    before: 2 # 包含前 2 個字串
    after: 2  # 包含後 2 個字串
```

#### 使用 `deep_translator` 提供者

本工具整合了 `deep_translator` 函式庫，讓您可以使用多種提供者。若要使用其中之一，只需將 `provider` 名稱設定為支援的服務之一即可。

下表列出了可用的提供者以及它們是否通常需要 API 金鑰。

| 提供者名稱  | 需要 API 金鑰？ | 備註                                 |
| :---------- | :-------------: | :----------------------------------- |
| `google`    |       否        | 預設的免費提供者。                   |
| `deepl`     |       是        | 需要 DeepL API 金鑰。                |
| `microsoft` |       是        | 需要 Microsoft Translator API 金鑰。 |
| `mymemory`  |       否        | 免費提供者。                         |
| `yandex`    |       是        | 需要 Yandex Translate API 金鑰。     |
| `baidu`     |       是        | 需要 Baidu Translate API 金鑰。      |
| `papago`    |       是        | 需要 Naver Papago API 金鑰。         |
| `qcri`      |       是        | 需要 QCRI API 金鑰。                 |
| `pons`      |       否        | 基於字典，適用於單詞/短語。          |
| `linguee`   |       否        | 基於字典，適用於單詞/短語。          |
| `libre`     |       否        | 免費、開源的翻譯服務。               |

**`deep_translator` 的組態：**

對於需要 API 金鑰的提供者，請直接在 `translator` 區塊內新增 `api_key` 參數。

**DeepL 範例：**

```yaml
translator:
  provider: "deepl"
  api_key: "YOUR_DEPL_API_KEY" # 或設定 DEEPL_API_KEY 環境變數
  batch_size: 50
```

## 7. 如何擴充

新增一個新的、自訂的翻譯提供者非常簡單：

1.  **建立新檔案**：在 `scripts/translator/providers/` 中，建立一個檔案（例如 `my_translator.py`）。
2.  **實作類別**：建立一個繼承自 `BaseTranslator` 的類別，並實作 `_TranslateBatch` 方法。
3.  **在工廠函式中註冊**：打開 `scripts/translator/providers/__init__.py` 並將您的新類別添加到 `CreateTranslator` 工廠函式中。
4.  **更新組態**：您現在可以在您的 `i18n-rules.yml` 檔案中使用您的新提供者名稱。

"""
This module contains the core orchestration logic for the localization pipeline.
"""

import os
import math
from typing import Dict, Any, List
from tqdm import tqdm

from ..models.types import MainConfig, LanguageConfig
from ..utils import config_loader
from ..utils.file_utils import WriteJsonFile
from ..utils.helpers import EscapeSequenceTranslator
from ..utils.logger import StructuredLogger
from ..providers import CreateTranslator
from . import extractor
from . import compiler


def _TranslateJson(
    json_path__TranslateJson: str,
    translations__TranslateJson: Dict[str, Any],
    lang_config__TranslateJson: LanguageConfig,
    translator__TranslateJson,
    pbar__TranslateJson: tqdm,
    translation_reports: Dict[str, Any],
) -> bool:
    """
    Private helper to translate strings for all target languages, updating the progress bar.
    Returns True if any translations were updated.
    """
    source_lang__TranslateJson = lang_config__TranslateJson["source"]
    target_langs__TranslateJson = lang_config__TranslateJson["targets"]
    lang_map__TranslateJson = lang_config__TranslateJson.get("map", {})
    source_lang_api__TranslateJson = lang_map__TranslateJson.get(
        source_lang__TranslateJson, source_lang__TranslateJson
    )

    overall_translation_updated__TranslateJson = False

    for target_lang__TranslateJson in target_langs__TranslateJson:
        if target_lang__TranslateJson not in translations__TranslateJson:
            translations__TranslateJson[target_lang__TranslateJson] = {}

        target_lang_api__TranslateJson = lang_map__TranslateJson.get(
            target_lang__TranslateJson, target_lang__TranslateJson
        )

        source_items_to_translate__TranslateJson = {
            key: text
            for key, text in translations__TranslateJson[
                source_lang__TranslateJson
            ].items()
            if key not in translations__TranslateJson[target_lang__TranslateJson]
            or not translations__TranslateJson[target_lang__TranslateJson][key]
        }

        if not source_items_to_translate__TranslateJson:
            continue

        items_to_translate__TranslateJson = list(
            source_items_to_translate__TranslateJson.items()
        )
        all_translated_texts__TranslateJson: List[str] = []
        all_keys__TranslateJson: List[str] = []

        batch_size__TranslateJson = translator__TranslateJson.batch_size_BaseTranslator
        if (
            not isinstance(batch_size__TranslateJson, int)
            or batch_size__TranslateJson <= 0
        ):
            # We don't have the rule_set name here, so we provide a general error.
            raise ValueError(
                f"Invalid 'batch_size' ({batch_size__TranslateJson}) configured for one of the translators. "
                "Please ensure 'batch_size' is a positive integer in your i18n-rules.yml."
            )

        # Get the full list of original texts in order, to be used for context gathering
        all_source_texts_in_order__TranslateJson = list(
            translations__TranslateJson[source_lang__TranslateJson].values()
        )

        for i in range(
            0,
            len(items_to_translate__TranslateJson),
            batch_size__TranslateJson,
        ):
            batch__TranslateJson = items_to_translate__TranslateJson[
                i : i + batch_size__TranslateJson
            ]
            keys__TranslateJson, texts_for_api__TranslateJson = zip(
                *batch__TranslateJson
            )

            # --- Context Gathering ---
            context_before__TranslateJson = None
            context_after__TranslateJson = None

            # Find the index of the first item in the current batch within the full list
            first_item_text = texts_for_api__TranslateJson[0]
            try:
                current_index = all_source_texts_in_order__TranslateJson.index(
                    first_item_text
                )

                # Get "before" context
                before_count = translator__TranslateJson.context_before_BaseTranslator
                if before_count > 0:
                    start_index = max(0, current_index - before_count)
                    context_before__TranslateJson = (
                        all_source_texts_in_order__TranslateJson[
                            start_index:current_index
                        ]
                    )

                # Get "after" context
                after_count = translator__TranslateJson.context_after_BaseTranslator
                if after_count > 0:
                    start_index = current_index + len(batch__TranslateJson)
                    end_index = start_index + after_count
                    context_after__TranslateJson = (
                        all_source_texts_in_order__TranslateJson[start_index:end_index]
                    )
            except ValueError:
                # This can happen if a string is modified manually.
                # In this case, we just don't provide context for this batch.
                pass
            # --- End Context Gathering ---

            processed_texts__TranslateJson = [
                EscapeSequenceTranslator(text) for text in texts_for_api__TranslateJson
            ]

            translated_batch__TranslateJson = translator__TranslateJson.TranslateBatch(
                texts=processed_texts__TranslateJson,
                source_lang=source_lang_api__TranslateJson,
                target_lang=target_lang_api__TranslateJson,
                context_before=context_before__TranslateJson,
                context_after=context_after__TranslateJson,
            )
            pbar__TranslateJson.update(1)

            if len(translated_batch__TranslateJson) == len(keys__TranslateJson):
                all_translated_texts__TranslateJson.extend(
                    translated_batch__TranslateJson
                )
                all_keys__TranslateJson.extend(keys__TranslateJson)
            else:
                print(
                    f"\nWarning: Mismatch in translated batch size for {target_lang__TranslateJson}. Skipping {len(keys__TranslateJson)} items."
                )

        if all_keys__TranslateJson:
            for key__TranslateJson, translated_text__TranslateJson in zip(
                all_keys__TranslateJson, all_translated_texts__TranslateJson
            ):
                translations__TranslateJson[target_lang__TranslateJson][
                    key__TranslateJson
                ] = translated_text__TranslateJson

                # Store translation for final report
                for report in translation_reports.values():
                    if key__TranslateJson in report["strings"]:
                        report["strings"][key__TranslateJson][
                            target_lang__TranslateJson
                        ] = translated_text__TranslateJson

            WriteJsonFile(json_path__TranslateJson, translations__TranslateJson)
            pbar__TranslateJson.update(1)
            overall_translation_updated__TranslateJson = True

    return overall_translation_updated__TranslateJson


def RunLocalizationPipeline(debug_RunLocalizationPipeline: bool = False):
    """
    Executes the full localization pipeline:
    1. Finds and loads configuration files.
    2. Extracts new strings and creates template files.
    3. Translates new strings for all target languages.
    4. Compiles the final localized files from the templates.
    """
    # Setup logger
    # The log directory will be relative to the first config file's .ogos directory
    log_dir = os.path.join(os.getcwd(), ".ogos", "log")
    logger = StructuredLogger(log_dir, debug_RunLocalizationPipeline)

    logger.info("--- Starting Localization Pipeline ---")

    # 1. Find and load configurations
    config_files_RunLocalizationPipeline = config_loader.FindConfigFiles()
    if not config_files_RunLocalizationPipeline:
        print("No i18n-rules.yaml or .yml files found in target directories.")
        return

    tasks_RunLocalizationPipeline = []
    total_pbar_steps_RunLocalizationPipeline = 0
    all_intl_paths_RunLocalizationPipeline = set()
    translator_cache_RunLocalizationPipeline = {}
    translation_reports = {}

    # 2. Pre-processing and calculation phase
    print("\n--- Pre-processing and calculating total work ---")
    for config_path_RunLocalizationPipeline in config_files_RunLocalizationPipeline:
        config_dir_RunLocalizationPipeline = os.path.dirname(
            os.path.dirname(config_path_RunLocalizationPipeline)
        )
        config_RunLocalizationPipeline: MainConfig = config_loader.LoadConfig(
            config_path_RunLocalizationPipeline
        )

        lang_config_RunLocalizationPipeline = config_RunLocalizationPipeline.get(
            "languages"
        )
        if (
            not lang_config_RunLocalizationPipeline
            or not lang_config_RunLocalizationPipeline.get("source")
            or not lang_config_RunLocalizationPipeline.get("targets")
        ):
            raise ValueError(
                f"Configuration file {config_path_RunLocalizationPipeline} is missing 'source' or 'targets' in 'languages' block."
            )

        for rule_set_RunLocalizationPipeline in config_RunLocalizationPipeline.get(
            "file_rules", []
        ):
            # Extract strings and update JSONs
            for (
                src_path_RunLocalizationPipeline,
                intl_path_RunLocalizationPipeline,
            ) in rule_set_RunLocalizationPipeline.get("file_mapping", {}).items():
                (
                    json_path_RunLocalizationPipeline,
                    translations_RunLocalizationPipeline,
                    new_strings_report,
                ) = extractor.ExtractStringsFromFile(
                    src_path_ExtractStringsFromFile=src_path_RunLocalizationPipeline,
                    intl_path_ExtractStringsFromFile=intl_path_RunLocalizationPipeline,
                    extraction_rules_ExtractStringsFromFile=rule_set_RunLocalizationPipeline.get(
                        "extraction_rules", []
                    ),
                    source_lang_ExtractStringsFromFile=lang_config_RunLocalizationPipeline.get(
                        "source"
                    ),
                    config_path_ExtractStringsFromFile=config_path_RunLocalizationPipeline,
                )
                if src_path_RunLocalizationPipeline not in translation_reports:
                    translation_reports[src_path_RunLocalizationPipeline] = {
                        "source_lang": lang_config_RunLocalizationPipeline.get(
                            "source"
                        ),
                        "targets": lang_config_RunLocalizationPipeline.get(
                            "targets", []
                        ),
                        "strings": {},
                    }
                for key, text in new_strings_report.items():
                    if (
                        key
                        not in translation_reports[src_path_RunLocalizationPipeline][
                            "strings"
                        ]
                    ):
                        translation_reports[src_path_RunLocalizationPipeline][
                            "strings"
                        ][key] = {"en": text}

                # The extractor returns the canonical path to the generated JSON.
                # The template path is the same, minus the extension.
                generated_template_path = (
                    json_path_RunLocalizationPipeline.removesuffix(".json")
                )
                all_intl_paths_RunLocalizationPipeline.add(generated_template_path)

                # Calculate steps for translation
                base_translator_config = rule_set_RunLocalizationPipeline.get(
                    "translator", {}
                )

                # Create a runtime-specific config copy to include the debug flag
                runtime_translator_config = base_translator_config.copy()
                runtime_translator_config["debug"] = debug_RunLocalizationPipeline

                # The cache key should be based on the final config used
                cache_key_RunLocalizationPipeline = str(runtime_translator_config)

                if (
                    cache_key_RunLocalizationPipeline
                    not in translator_cache_RunLocalizationPipeline
                ):
                    translator_cache_RunLocalizationPipeline[
                        cache_key_RunLocalizationPipeline
                    ] = CreateTranslator(runtime_translator_config, logger)

                translator_RunLocalizationPipeline = (
                    translator_cache_RunLocalizationPipeline[
                        cache_key_RunLocalizationPipeline
                    ]
                )

                needs_translation_RunLocalizationPipeline = False
                for (
                    lang_RunLocalizationPipeline
                ) in lang_config_RunLocalizationPipeline.get("targets", []):
                    items_for_lang_RunLocalizationPipeline = [
                        key
                        for key in translations_RunLocalizationPipeline.get(
                            lang_config_RunLocalizationPipeline["source"], {}
                        )
                        if key
                        not in translations_RunLocalizationPipeline.get(
                            lang_RunLocalizationPipeline, {}
                        )
                        or not translations_RunLocalizationPipeline.get(
                            lang_RunLocalizationPipeline, {}
                        ).get(key)
                    ]
                    if items_for_lang_RunLocalizationPipeline:
                        needs_translation_RunLocalizationPipeline = True

                        batch_size_RunLocalizationPipeline = (
                            translator_RunLocalizationPipeline.batch_size_BaseTranslator
                        )
                        if (
                            not batch_size_RunLocalizationPipeline
                            or batch_size_RunLocalizationPipeline <= 0
                        ):
                            raise ValueError(
                                f"Invalid 'batch_size' ({batch_size_RunLocalizationPipeline}) for translator '{rule_set_RunLocalizationPipeline.get('name')}'. "
                                "Please set a positive integer for 'batch_size' in your i18n-rules.yml."
                            )

                        num_batches_RunLocalizationPipeline = math.ceil(
                            len(items_for_lang_RunLocalizationPipeline)
                            / batch_size_RunLocalizationPipeline
                        )
                        steps_added_RunLocalizationPipeline = (
                            num_batches_RunLocalizationPipeline + 1
                        )  # API calls + JSON write
                        total_pbar_steps_RunLocalizationPipeline += (
                            steps_added_RunLocalizationPipeline
                        )

                        logger.debug_kv(
                            "PBar Steps Calculation",
                            {
                                "rule_set": rule_set_RunLocalizationPipeline.get(
                                    "name", "Unnamed Rule"
                                ),
                                "language": lang_RunLocalizationPipeline,
                                "items_to_translate": len(
                                    items_for_lang_RunLocalizationPipeline
                                ),
                                "batch_size": batch_size_RunLocalizationPipeline,
                                "calculated_batches": num_batches_RunLocalizationPipeline,
                                "formula": "ceil(items / batch_size) + 1 (for JSON write)",
                                "steps_added": steps_added_RunLocalizationPipeline,
                            },
                        )

                if needs_translation_RunLocalizationPipeline:
                    tasks_RunLocalizationPipeline.append(
                        {
                            "json_path": json_path_RunLocalizationPipeline,
                            "translations": translations_RunLocalizationPipeline,
                            "lang_config": lang_config_RunLocalizationPipeline,
                            "translator": translator_RunLocalizationPipeline,
                            "name": rule_set_RunLocalizationPipeline.get(
                                "name", "Unnamed Rule"
                            ),
                        }
                    )

    # 3. Translation phase
    if tasks_RunLocalizationPipeline:
        print(f"\n--- Starting Translation ---")
        print(f"Total steps to complete: {total_pbar_steps_RunLocalizationPipeline}")
        with tqdm(
            total=total_pbar_steps_RunLocalizationPipeline,
            bar_format="Overall Progress: [{percentage:3.0f}%] [{bar}] {n_fmt}/{total_fmt} steps",
            unit=" step",
            ascii=".#",
        ) as pbar_RunLocalizationPipeline:
            for task_RunLocalizationPipeline in tasks_RunLocalizationPipeline:
                pbar_RunLocalizationPipeline.set_description(
                    f"Translating: {task_RunLocalizationPipeline['name']}"
                )
                _TranslateJson(
                    json_path__TranslateJson=task_RunLocalizationPipeline["json_path"],
                    translations__TranslateJson=task_RunLocalizationPipeline[
                        "translations"
                    ],
                    lang_config__TranslateJson=task_RunLocalizationPipeline[
                        "lang_config"
                    ],
                    translator__TranslateJson=task_RunLocalizationPipeline[
                        "translator"
                    ],
                    pbar__TranslateJson=pbar_RunLocalizationPipeline,
                    translation_reports=translation_reports,
                )
        print("\n--- Translation process completed successfully! ---")
    else:
        print("\n--- No new strings to translate. ---")

    # 4. Compilation phase
    print("\n--- Starting Compilation of Localized Files ---")
    if not all_intl_paths_RunLocalizationPipeline:
        print("No template files were found to compile.")
    else:
        # This assumes all templates within a single run share the same base output directory.
        # This is a safe assumption given the current structure.
        first_task_dir = os.path.dirname(
            os.path.dirname(config_files_RunLocalizationPipeline[0])
        )

        for config_path_RunLocalizationPipeline in config_files_RunLocalizationPipeline:
            config_RunLocalizationPipeline: MainConfig = config_loader.LoadConfig(
                config_path_RunLocalizationPipeline
            )
            config_dir_RunLocalizationPipeline = os.path.dirname(
                os.path.dirname(config_path_RunLocalizationPipeline)
            )

            # Get the custom output directory from the config, or use the default logic.
            output_dir_RunLocalizationPipeline = config_RunLocalizationPipeline.get(
                "output_dir"
            )

            for rule_set_RunLocalizationPipeline in config_RunLocalizationPipeline.get(
                "file_rules", []
            ):
                for (
                    src_path_RunLocalizationPipeline,
                    intl_path_RunLocalizationPipeline,
                ) in rule_set_RunLocalizationPipeline.get("file_mapping", {}).items():
                    # The template path is the internationalized path.
                    template_path_RunLocalizationPipeline = os.path.join(
                        config_dir_RunLocalizationPipeline,
                        intl_path_RunLocalizationPipeline,
                    )

                    if (
                        template_path_RunLocalizationPipeline
                        in all_intl_paths_RunLocalizationPipeline
                    ):
                        compiler.CompileFile(
                            template_path_CompileFile=template_path_RunLocalizationPipeline,
                            output_base_dir_CompileFile=config_dir_RunLocalizationPipeline,
                            custom_output_path_CompileFile=output_dir_RunLocalizationPipeline,
                        )
                        # Remove from set to avoid processing it again if another rule points to it.
                        all_intl_paths_RunLocalizationPipeline.remove(
                            template_path_RunLocalizationPipeline
                        )
        print("\n--- All files compiled successfully! ---")

    # Generate and log the final report
    for file_path, report_data in translation_reports.items():
        report_string = f"# Translation Report for: {file_path}\n"
        report_string += f"**Source Language:** {report_data['source_lang']}\n"
        report_string += (
            f"**Target Languages:** {', '.join(report_data['targets'])}\n\n"
        )

        for i, (key, translations) in enumerate(report_data["strings"].items()):
            report_string += f"### {i+1}. {key}\n"
            for lang, text in translations.items():
                report_string += f"- {lang}: {text}\n"
            report_string += "\n"

        logger.debug_raw(report_string)

    print("\n--- Localization Pipeline Completed ---")

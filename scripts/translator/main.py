"""
This module serves as the main entry point for the localization script.
"""

import argparse
from .core.engine import RunLocalizationPipeline


def Main():
    """
    Main entry point for the localization script.
    """
    parser = argparse.ArgumentParser(description="Localization and Translation Script")
    parser.add_argument(
        "--debug", action="store_true", help="Enable debug mode to see API responses."
    )
    args = parser.parse_args()

    RunLocalizationPipeline(debug_RunLocalizationPipeline=args.debug)


if __name__ == "__main__":
    Main()

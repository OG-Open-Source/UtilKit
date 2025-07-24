"""
This module provides a flexible and structured logging setup for the translator script.
"""

import os
import logging
from typing import Dict, Any


class StructuredLogger:
    """
    A wrapper around Python's logging module to provide structured logging,
    especially for debug mode.
    """

    def __init__(self, log_dir: str, debug: bool = False):
        """
        Initializes the logger.

        Args:
            log_dir (str): The directory where log files will be stored.
            debug (bool): Flag to enable or disable debug-level logging.
        """
        self.debug_mode = debug
        self.logger = self._setup_logger(log_dir, debug)

    def _setup_logger(self, log_dir: str, debug: bool) -> logging.Logger:
        """
        Configures and returns a logger instance.
        """
        os.makedirs(log_dir, exist_ok=True)
        log_file = os.path.join(log_dir, "translator.log")

        logger = logging.getLogger("Translator")
        logger.setLevel(logging.DEBUG if debug else logging.INFO)

        # Prevent duplicate handlers if logger is re-initialized
        if logger.hasHandlers():
            logger.handlers.clear()

        # File handler
        file_handler = logging.FileHandler(log_file, mode="w", encoding="utf-8")
        file_formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
        file_handler.setFormatter(file_formatter)
        logger.addHandler(file_handler)

        # Console handler
        console_handler = logging.StreamHandler()
        console_formatter = logging.Formatter("%(message)s")
        console_handler.setFormatter(console_formatter)
        console_handler.setLevel(logging.INFO)
        logger.addHandler(console_handler)

        return logger

    def info(self, message: str):
        """Logs an info-level message."""
        self.logger.info(message)

    def warning(self, message: str):
        """Logs a warning-level message."""
        self.logger.warning(message)

    def error(self, message: str):
        """Logs an error-level message."""
        self.logger.error(message)

    def debug_kv(self, title: str, data: Dict[str, Any]):
        """
        Logs a dictionary of key-value pairs in a structured format if in debug mode.

        Args:
            title (str): A title for the debug section.
            data (Dict[str, Any]): The key-value data to log.
        """
        if self.debug_mode:
            log_message = f"--- [DEBUG] {title} ---\n"
            for key, value in data.items():
                log_message += f"  - {key}: {value}\n"
            log_message += "-------------------------"
            self.logger.debug(log_message)

    def debug_raw(self, message: str):
        """Logs a raw string at debug level if in debug mode."""
        if self.debug_mode:
            self.logger.debug(message)

    def close(self):
        """Closes all handlers associated with the logger."""
        for handler in self.logger.handlers[:]:
            handler.close()
            self.logger.removeHandler(handler)

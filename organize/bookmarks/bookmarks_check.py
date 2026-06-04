#!/usr/bin/env python3
import re
import sys
import time
import requests
from pathlib import Path
from bs4 import BeautifulSoup
from urllib.parse import urlparse

# Colores ANSI
GREEN = "\033[0;32m\033[1m"
RED = "\033[0;31m\033[1m"
BLUE = "\033[0;34m\033[1m"
YELLOW = "\033[0;33m\033[1m"
RESET = "\033[0m\033[0m"

BOOKMARK_FILE = "bookmarks.html"
URLS_FILE = "bookmarks_urls.txt"
FAIL_FILE = "bookmarks_fail_urls.txt"

# Regex de validación de URLs
URL_REGEX = re.compile(
    r'^(https?|ftp)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]+[-A-Za-z0-9\+&@#/%=~_|]$'
)

def extract_urls_from_bookmarks(bookmark_file):
    """Extrae URLs válidas del HTML de Firefox"""
    urls = []
    with open(bookmark_file, "r", encoding="utf-8") as f:
        soup = BeautifulSoup(f, "html.parser")
        for a in soup.find_all("a", href=True):
            href = a["href"]
            if URL_REGEX.match(href):
                urls.append(href.strip())
    return sorted(set(urls))


def check_url(url, timeout=5):
    """Comprueba si una URL responde correctamente"""
    try:
        response = requests.head(url, timeout=timeout, allow_redirects=True)
        if response.ok:
            return True
        else:
            # fallback a GET por si HEAD falla
            response = requests.get(url, timeout=timeout, allow_redirects=True)
            return response.ok
    except requests.RequestException:
        return False


def main():
    bookmark_path = Path(BOOKMARK_FILE)
    if not bookmark_path.exists():
        print(f"\n{RED}[!] El archivo '{BOOKMARK_FILE}' no existe en el directorio {Path.cwd()}{RESET}\n")
        sys.exit(1)

    print(f"{YELLOW}[!] Extrayendo URLs del archivo...{RESET}")
    urls = extract_urls_from_bookmarks(bookmark_path)
    total = len(urls)
    print(f"{BLUE}[i] Total de URLs encontradas: {total}{RESET}")

    fail_urls = []
    start_time = time.time()

    for idx, url in enumerate(urls, start=1):
        alive = check_url(url)
        status_color = GREEN if alive else RED
        status_text = "OK" if alive else "FAIL"
        print(f"{BLUE}[{idx}/{total}]{RESET} {status_color}{status_text:<4}{RESET} {url[:80]}")

        if not alive:
            fail_urls.append(url)

    # Guardar URLs fallidas
    with open(FAIL_FILE, "w", encoding="utf-8") as f:
        for url in fail_urls:
            f.write(url + "\n")

    # Guardar URLs totales (opcional)
    with open(URLS_FILE, "w", encoding="utf-8") as f:
        for url in urls:
            f.write(url + "\n")

    elapsed = time.time() - start_time
    print(f"\n{GREEN}Tarea finalizada en {elapsed:.1f}s{RESET}")
    print(f"{RED}[!] URLs fallidas: {len(fail_urls)}{RESET}")
    print(f"{YELLOW}[i] Guardadas en: {FAIL_FILE}{RESET}\n")


if __name__ == "__main__":
    try:
        import bs4  # check for BeautifulSoup
    except ImportError:
        print(f"{RED}[!] Falta el módulo BeautifulSoup4. Instálalo con:{RESET}")
        print(f"    pip install beautifulsoup4 requests\n")
        sys.exit(1)

    main()

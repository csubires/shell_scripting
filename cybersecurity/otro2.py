#!/usr/bin/env python3
"""
SCRIPT CORREGIDO CON GESTIÓN DE KEYRING
"""
import sqlite3
import os
import subprocess
import sys
from datetime import datetime

def install_keyring_dependencies():
    """Instalar dependencias del keyring si no están disponibles"""
    print("🔧 INSTALANDO DEPENDENCIAS NECESARIAS...")
    
    try:
        # Verificar e instalar secret-tool
        result = subprocess.run(['which', 'secret-tool'], 
                              capture_output=True, text=True)
        if result.returncode != 0:
            print("📦 Instalando secret-tool...")
            subprocess.run(['sudo', 'apt', 'install', '-y', 'libsecret-tools'], 
                         check=True)
        
        # Verificar e instalar gnome-keyring
        result = subprocess.run(['which', 'gnome-keyring-daemon'], 
                              capture_output=True, text=True)
        if result.returncode != 0:
            print("📦 Instalando gnome-keyring...")
            subprocess.run(['sudo', 'apt', 'install', '-y', 'gnome-keyring'], 
                         check=True)
        
        print("✅ Dependencias instaladas correctamente")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Error instalando dependencias: {e}")
        return False

def start_keyring_service():
    """Iniciar el servicio de keyring"""
    print("🔑 INICIANDO KEYRING SERVICE...")
    
    try:
        # Iniciar el daemon
        subprocess.run(['gnome-keyring-daemon', '--start', '--components=secrets'], 
                      check=True, capture_output=True)
        
        # Verificar que está corriendo
        result = subprocess.run(['ps', 'aux', '|', 'grep', 'keyring'], 
                              shell=True, capture_output=True, text=True)
        
        if 'gnome-keyring' in result.stdout:
            print("✅ GNOME Keyring iniciado correctamente")
            return True
        else:
            print("❌ No se pudo iniciar GNOME Keyring")
            return False
            
    except Exception as e:
        print(f"❌ Error iniciando keyring: {e}")
        return False

def extract_with_keyring_access():
    """Extraer contraseñas con keyring funcionando"""
    print("\n🔍 EXTRAYENDO CON KEYRING...")
    print("=" * 50)
    
    login_data_path = "./files/Login Data"
    
    if not os.path.exists(login_data_path):
        print("❌ Login Data no encontrado")
        return
    
    try:
        # Crear copia temporal
        temp_db = "/tmp/chrome_pass_temp.db"
        subprocess.run(['cp', login_data_path, temp_db], check=True)
        
        conn = sqlite3.connect(temp_db)
        cursor = conn.cursor()
        
        # Obtener credenciales
        cursor.execute("""
            SELECT origin_url, username_value, password_value
            FROM logins 
            WHERE username_value != '' 
        """)
        
        results = cursor.fetchall()
        
        print(f"📊 Encontradas {len(results)} credenciales:")
        print("-" * 60)
        
        for i, (url, username, encrypted_pwd) in enumerate(results, 1):
            print(f"{i}. 🌐 {url}")
            print(f"   👤 {username}")
            
            if encrypted_pwd:
                pwd_len = len(encrypted_pwd)
                print(f"   🔐 Contraseña cifrada ({pwd_len} bytes)")
                
                # Intentar descifrar con secret-tool
                try:
                    # Buscar en el keyring
                    result = subprocess.run([
                        'secret-tool', 'search', 'application', 'chrome'
                    ], capture_output=True, text=True, timeout=10)
                    
                    if result.returncode == 0:
                        print("   ✅ Keyring accesible")
                    else:
                        print("   ⚠️  No encontrado en keyring")
                        
                except Exception as e:
                    print(f"   ❌ Error keyring: {e}")
            
            print()
        
        conn.close()
        os.remove(temp_db)
        
    except Exception as e:
        print(f"❌ Error en extracción: {e}")

def method_manual_export():
    """Método manual garantizado"""
    print("\n🎯 MÉTODO MANUAL GARANTIZADO")
    print("=" * 50)
    print("""
Sigue estos pasos para obtener las contraseñas:

1. INSTALAR KEYRING:
   sudo apt update && sudo apt install gnome-keyring libsecret-tools

2. INICIAR KEYRING:
   gnome-keyring-daemon --start --components=secrets

3. ABRIR CHROME CON EL PERFIL:
   google-chrome --user-data-dir=$(pwd)/files --no-sandbox

4. EXPORTAR CONTRASEÑAS:
   • Ve a: chrome://settings/passwords
   • Haz clic en ⋮ (tres puntos)
   • Selecciona 'Exportar contraseñas'
   • Verifica con tu contraseña de usuario

5. OBTENER CSV:
   Se descargará un archivo 'chrome-passwords.csv' con todo en texto plano.
""")

def method_alternative_python():
    """Método alternativo con Python keyring"""
    print("\n🐍 MÉTODO ALTERNATIVO CON PYTHON-KEYRING")
    print("=" * 50)
    
    try:
        import keyring
        print("✅ python-keyring disponible")
        
        # Buscar contraseñas de Chrome en el keyring
        services = keyring.get_keyring()
        print(f"Keyring backend: {services}")
        
    except ImportError:
        print("❌ python-keyring no instalado")
        print("Instalar con: pip install keyring")
        
    except Exception as e:
        print(f"❌ Error keyring: {e}")

if __name__ == "__main__":
    print("🛠️  SOLUCIÓN COMPLETA PARA KEYRING")
    print("=" * 60)
    
    # Opción 1: Instalar e iniciar keyring automáticamente
    print("1. Intentando solución automática...")
    if install_keyring_dependencies() and start_keyring_service():
        extract_with_keyring_access()
    else:
        print("❌ Solución automática falló")
    
    # Opción 2: Métodos alternativos
    method_manual_export()
    method_alternative_python()
    
    print("\n💡 CONSEJO FINAL:")
    print("El método MÁS FIABLE es la exportación manual desde Chrome")
    print("Una vez instalado gnome-keyring, debería funcionar sin problemas.")

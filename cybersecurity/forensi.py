#!/usr/bin/env python3
"""
SCRIPT FORENSE PARA EXTRACCIÓN DE CONTRASEÑAS CHROME
Solo usar en entornos legales y autorizados
"""
import sqlite3
import os
import json
import base64
import sys
from Crypto.Cipher import AES
from Crypto.Protocol.KDF import PBKDF2

# ===== CONFIGURACIÓN =====
PROFILE_PATH = "./files"  # Ruta a los archivos del perfil
OUTPUT_FILE = "forensic_report.txt"

def log_activity(action):
    """Registro de actividades forenses"""
    timestamp = datetime.now().isoformat()
    with open("forensic_log.txt", "a") as log:
        log.write(f"{timestamp} - {action}\n")

def get_encryption_key():
    """Obtener clave de cifrado desde Local State"""
    local_state_path = os.path.join(PROFILE_PATH, "Local State")
    
    if not os.path.exists(local_state_path):
        print("❌ Local State no encontrado")
        return None
    
    try:
        with open(local_state_path, 'r', encoding='utf-8') as f:
            local_state = json.load(f)
        
        encrypted_key = base64.b64decode(
            local_state['os_crypt']['encrypted_key']
        )
        # Remover prefix DPAPI
        encrypted_key = encrypted_key[5:]
        return encrypted_key
        
    except Exception as e:
        print(f"❌ Error obteniendo clave: {e}")
        return None

def decrypt_password(encrypted_password, key):
    """Descifrar contraseña cifrada"""
    try:
        if encrypted_password.startswith(b'v10') or encrypted_password.startswith(b'v11'):
            # AES-GCM
            iv = encrypted_password[3:15]
            payload = encrypted_password[15:]
            
            cipher = AES.new(key, AES.MODE_GCM, iv)
            decrypted = cipher.decrypt(payload)
            return decrypted.decode('utf-8')
        else:
            return "[CIFRADO CON DPAPI - requiere Windows]"
            
    except Exception as e:
        return f"[ERROR: {str(e)}]"

def extract_passwords_forensic():
    """Extracción forense de contraseñas"""
    print("🔍 INICIANDO EXTRACCIÓN FORENSE")
    print("=" * 60)
    
    login_data_path = os.path.join(PROFILE_PATH, "Login Data")
    
    if not os.path.exists(login_data_path):
        print("❌ Login Data no encontrado")
        return
    
    # Crear copia forense
    forensic_copy = "login_data_forensic.db"
    os.system(f"cp '{login_data_path}' '{forensic_copy}'")
    
    try:
        # Registrar actividad
        log_activity("Inicio extracción contraseñas")
        
        conn = sqlite3.connect(forensic_copy)
        cursor = conn.cursor()
        
        # Obtener clave de cifrado
        key = get_encryption_key()
        
        # Consulta forense
        cursor.execute("""
            SELECT 
                origin_url,
                username_value, 
                password_value,
                date_created,
                date_last_used,
                times_used
            FROM logins 
            WHERE username_value != ''
            ORDER BY date_last_used DESC
        """)
        
        results = cursor.fetchall()
        
        if not results:
            print("ℹ️ No se encontraron credenciales guardadas")
            return
        
        # Generar reporte
        with open(OUTPUT_FILE, "w", encoding='utf-8') as report:
            report.write("REPORTE FORENSE - CONTRASEÑAS CHROME\n")
            report.write("=" * 50 + "\n")
            report.write(f"Fecha de análisis: {datetime.now()}\n")
            report.write(f"Total credenciales: {len(results)}\n\n")
            
            for url, username, encrypted_pwd, created, last_used, times_used in results:
                # Descifrar contraseña
                password = decrypt_password(encrypted_pwd, key) if key else "[CLAVE NO DISPONIBLE]"
                
                # Formatear fechas
                created_str = datetime.fromtimestamp(created/1000000).isoformat() if created else "N/A"
                used_str = datetime.fromtimestamp(last_used/1000000).isoformat() if last_used else "N/A"
                
                # Escribir en reporte
                report.write(f"URL: {url}\n")
                report.write(f"Usuario: {username}\n")
                report.write(f"Contraseña: {password}\n")
                report.write(f"Creación: {created_str}\n")
                report.write(f"Último uso: {used_str}\n")
                report.write(f"Veces usado: {times_used}\n")
                report.write("-" * 50 + "\n")
                
                # Mostrar en consola (sin contraseñas completas)
                print(f"🌐 {url}")
                print(f"   👤 {username}")
                print(f"   🔑 {password[:10]}...")  # Solo mostrar parte por seguridad
                print(f"   📅 Último uso: {used_str}")
                print()
        
        print(f"✅ Reporte guardado en: {OUTPUT_FILE}")
        log_activity(f"Extracción completada - {len(results)} credenciales")
        
    except Exception as e:
        print(f"❌ Error en extracción: {e}")
        log_activity(f"ERROR: {e}")
    finally:
        if 'conn' in locals():
            conn.close()
        if os.path.exists(forensic_copy):
            os.remove(forensic_copy)

def extract_additional_forensic_data():
    """Extraer datos adicionales forenses"""
    print("\n📊 EXTRACCIÓN DE DATOS ADICIONALES")
    print("=" * 60)
    
    # Historial
    if os.path.exists(os.path.join(PROFILE_PATH, "History")):
        try:
            conn = sqlite3.connect(os.path.join(PROFILE_PATH, "History"))
            cursor = conn.cursor()
            
            # URLs más visitadas
            cursor.execute("""
                SELECT url, title, visit_count 
                FROM urls 
                ORDER BY visit_count DESC 
                LIMIT 10
            """)
            
            print("🌐 TOP 10 SITIOS MÁS VISITADOS:")
            for url, title, count in cursor.fetchall():
                print(f"   {count}x - {title[:40]}...")
            
            conn.close()
        except Exception as e:
            print(f"   Error historial: {e}")

# ===== EJECUCIÓN =====
if __name__ == "__main__":
    from datetime import datetime
    
    print("🛡️  HERRAMIENTA FORENSE CHROME")
    print("⚠️   SOLO USO EN ENTORNOS AUTORIZADOS")
    print("=" * 60)
    
    # Verificar entorno legal
    legal_ack = input("¿Tienes autorización legal para esta extracción? (si/no): ")
    if legal_ack.lower() != 'si':
        print("❌ Operación cancelada - Sin autorización")
        sys.exit(1)
    
    extract_passwords_forensic()
    extract_additional_forensic_data()

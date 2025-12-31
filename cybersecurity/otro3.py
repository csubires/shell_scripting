#!/usr/bin/env python3
# Solo muestra la información disponible sin descifrar
import sqlite3
import os

def read_chrome_metadata():
    """Leer metadatos de las contraseñas sin descifrar"""
    conn = sqlite3.connect("./files/Login Data")
    cursor = conn.cursor()
    
    # Información disponible
    cursor.execute("""
        SELECT 
            origin_url,
            username_value,
            length(password_value) as pwd_length,
            date_created,
            date_last_used,
            times_used
        FROM logins 
        ORDER BY date_last_used DESC
    """)
    
    for url, user, pwd_len, created, last_used, times_used in cursor.fetchall():
        print(f"🔗 {url}")
        print(f"   👤 {user}")
        print(f"   📏 Longitud: {pwd_len} bytes")
        print(f"   🔄 Usada {times_used} veces")
        print()
    
    conn.close()

read_chrome_metadata()

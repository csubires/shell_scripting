#!/usr/bin/env python3
"""
Verificador de URLs usando threading (sin aiohttp)
"""

import requests
import threading
import queue
import time
from urllib.parse import urlparse
from datetime import datetime
import sys
import json

class URLCheckerThreaded:
    def __init__(self, max_threads=10, timeout=10):
        self.max_threads = max_threads
        self.timeout = timeout
        self.results = []
        self.lock = threading.Lock()
        self.queue = queue.Queue()
        
    def read_urls(self, filename):
        """Lee URLs desde archivo."""
        urls = []
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        # Agregar protocolo si falta
                        if not line.startswith(('http://', 'https://')):
                            line = 'https://' + line
                        urls.append(line)
            print(f"✓ Leídas {len(urls)} URLs desde {filename}")
            return urls
        except Exception as e:
            print(f"✗ Error leyendo archivo: {e}")
            sys.exit(1)
    
    def check_single_url(self):
        """Función ejecutada por cada thread."""
        while True:
            try:
                url = self.queue.get_nowait()
            except queue.Empty:
                break
                
            try:
                headers = {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                }
                
                start_time = time.time()
                response = requests.get(
                    url, 
                    timeout=self.timeout, 
                    headers=headers,
                    allow_redirects=True,
                    verify=False  # Ignorar errores SSL
                )
                elapsed = time.time() - start_time
                
                status = 'ACTIVE' if 200 <= response.status_code < 400 else 'ERROR'
                
                with self.lock:
                    self.results.append({
                        'url': url,
                        'status': status,
                        'status_code': response.status_code,
                        'response_time': round(elapsed, 2),
                        'final_url': response.url
                    })
                    
                    # Mostrar progreso
                    icon = '✅' if status == 'ACTIVE' else '⚠️' if response.status_code == 404 else '❌'
                    print(f"{icon} {url} - {response.status_code} ({elapsed:.1f}s)")
                    
            except requests.exceptions.Timeout:
                with self.lock:
                    self.results.append({
                        'url': url,
                        'status': 'TIMEOUT',
                        'status_code': None,
                        'response_time': None,
                        'error': f'Timeout ({self.timeout}s)'
                    })
                    print(f"⏱️  {url} - TIMEOUT")
                    
            except requests.exceptions.SSLError:
                with self.lock:
                    self.results.append({
                        'url': url,
                        'status': 'SSL_ERROR',
                        'status_code': None,
                        'response_time': None,
                        'error': 'Error de certificado SSL'
                    })
                    print(f"🔒 {url} - SSL ERROR")
                    
            except requests.exceptions.ConnectionError:
                with self.lock:
                    self.results.append({
                        'url': url,
                        'status': 'CONNECTION_ERROR',
                        'status_code': None,
                        'response_time': None,
                        'error': 'Error de conexión'
                    })
                    print(f"🔌 {url} - CONNECTION ERROR")
                    
            except Exception as e:
                with self.lock:
                    self.results.append({
                        'url': url,
                        'status': 'ERROR',
                        'status_code': None,
                        'response_time': None,
                        'error': str(e)
                    })
                    print(f"❌ {url} - ERROR: {str(e)[:50]}")
                    
            finally:
                self.queue.task_done()
    
    def check_urls(self, urls):
        """Verifica todas las URLs usando threads."""
        print(f"\n🚀 Iniciando verificación de {len(urls)} URLs...")
        print("=" * 60)
        
        # Poner URLs en la cola
        for url in urls:
            self.queue.put(url)
        
        # Crear y empezar threads
        threads = []
        for i in range(min(self.max_threads, len(urls))):
            thread = threading.Thread(target=self.check_single_url)
            thread.daemon = True
            thread.start()
            threads.append(thread)
        
        # Esperar que todos terminen
        self.queue.join()
        
        # Esperar que threads terminen
        for thread in threads:
            thread.join(timeout=1)
        
        return self.results
    
    def print_summary(self):
        """Muestra resumen de resultados."""
        print("\n" + "=" * 60)
        print("📊 RESUMEN DE RESULTADOS")
        print("=" * 60)
        
        total = len(self.results)
        active = sum(1 for r in self.results if r['status'] == 'ACTIVE')
        errors = total - active
        
        print(f"\n📈 Total URLs: {total}")
        print(f"✅ Activas: {active}")
        print(f"❌ Con errores: {errors}")
        
        # Agrupar por tipo de error
        errors_by_type = {}
        for r in self.results:
            if r['status'] != 'ACTIVE':
                error_type = r.get('error', r['status'])
                errors_by_type[error_type] = errors_by_type.get(error_type, 0) + 1
        
        if errors_by_type:
            print("\n📋 Detalle de errores:")
            for error_type, count in errors_by_type.items():
                print(f"   • {error_type}: {count}")
        
        # Mostrar URLs activas
        active_urls = [r for r in self.results if r['status'] == 'ACTIVE']
        if active_urls:
            print(f"\n🔗 URLs activas ({len(active_urls)}):")
            for r in sorted(active_urls, key=lambda x: x['response_time']):
                print(f"   • {r['url']} ({r['status_code']}, {r['response_time']}s)")
        
        # Guardar resultados
        self.save_results()
    
    def save_results(self, filename=None):
        """Guarda resultados en archivo."""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"url_results_{timestamp}.json"
        
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(self.results, f, indent=2, ensure_ascii=False)
            print(f"\n💾 Resultados guardados en: {filename}")
        except Exception as e:
            print(f"✗ Error guardando resultados: {e}")

def main():
    """Función principal."""
    if len(sys.argv) < 2:
        print("Uso: python3 check_urls.py <archivo_urls.txt> [threads] [timeout]")
        print("Ejemplo: python3 check_urls.py urls.txt 20 10")
        sys.exit(1)
    
    filename = sys.argv[1]
    threads = int(sys.argv[2]) if len(sys.argv) > 2 else 10
    timeout = int(sys.argv[3]) if len(sys.argv) > 3 else 10
    
    # Crear verificador
    checker = URLCheckerThreaded(max_threads=threads, timeout=timeout)
    
    # Leer URLs
    urls = checker.read_urls(filename)
    
    if not urls:
        print("No hay URLs para verificar")
        return
    
    # Verificar
    start_time = time.time()
    results = checker.check_urls(urls)
    elapsed = time.time() - start_time
    
    print(f"\n⏱️  Tiempo total: {elapsed:.1f} segundos")
    
    # Mostrar resumen
    checker.print_summary()

if __name__ == "__main__":
    main()
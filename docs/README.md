# Shell Script

<div style="text-align:center">

![icons](/docs/assets/icons.svg)
</div>

Os comparto mi colleción de scripts en bash que he ido desarrollando a lo largo de los años para automatizar ciertas tareas que se me hacian repetitivas.

[REPOSITORIO EN GITHUB](https://github.com/csubires/shell-script)

### vpnStart.sh
Script para automatizar la conexión y configuración con una VPN, mediante el cliente OpenVPN integrado por defecto en muchas distribuciones Linux, y la VPN gratuita de VPNBook.

[VPNBOOK](https://www.vpnbook.com/)

Además consta de las funciones auxiliares de reseteo de conexión, cambio de contraseña y comprobación de Firewall activo o caida del servicio (Kill Switch).
>Se debe configurar correctamente Iptable o mediante UFW para permitir las conexiones.

![vpn](/docs/assets/vpn.png)

### reduceMedia.sh
Script para la modificación y mantenimiento de bibliotecas de archivos multimedia (imagen, video, sonido, etc). Funciones de reducción de tamaño, redimensionado, renombrado de archivos, etc.

![media](/docs/assets/media.png)

Requisitos:
- ffmpeg
- lame
- mogrify
- fdupes
- ...

### flakeFolder.sh
Script para comprobar que un proyecto en Python cumple la normal de Flake8.
Además tiene la función de buscar "TODOs" dentro de los archivos y hacer un listado de `imports` para ayudar a crear el archivo `requeriments.txt` sin entornos virtuales.

![flake](/docs/assets/flake.png)

Requisitos:
- flake8

### clearLinux.sh
Script para buscar archivos y carpetas que puedan ser borradas para ahorrar espacio en disco. Además incorpora algunas funciones de hardening.

### backupAuto.sh
Script que mediante 2 listado, uno de archivos y otro de carpetas, y la recopilación de información del sistema, configuraciones, y archivos personales crea un backup comprimido con contraseña mediante `7z` facilmente exportable.

Requisitos:
- 7z

### syncServer.sh
Script para sincronizar una carpeta local y remota mediante rsync. Usado para subir un proyecto a producción en un servidor local.

### syncFolder.sh
Script para sincronizar una carpeta local mediante `rsync` en modo espejo, comprobando las diferencias. Usado para ir creando periódicamente un backup en USB de forma incremental mientras se trabaja en un proyecto.

### Otros
Otros scripts y proyectos que aún no están revisados o que fueron creados a modo de prueba de concepto.

#!/usr/bin/env wish

wm title . "App Tcl/Tk Completa con wish"

# Etiqueta para mostrar mensajes
label .lbl -text "Ingrese algo y presione Mostrar"

# Campo de entrada
entry .entry -width 40

# Variable para checkbox (guardado)
set guardar 0
checkbutton .chkGuardar -text "Guardar en archivo" -variable guardar

# Selectbox (combobox) con comandos para ejecutar
set comandos { "date" "whoami" "uptime" }
ttk::combobox .combo -values $comandos -state readonly
.combo set "date"  ;# valor por defecto

# Función para mostrar texto, guardar si checkbox está activado
proc mostrarTexto {} {
    global guardar

    set texto [.entry get]
    if {$texto eq ""} {
        .lbl configure -text "Por favor ingrese algo."
        return
    }
    .lbl configure -text "Ingresaste: $texto"

    if {$guardar} {
        # Guardar en archivo
        set f [open "mensajes.txt" a]
        puts $f $texto
        puts "Botón pulsado $texto"
        close $f
    }
}

# Función para limpiar entrada y etiqueta
proc limpiar {} {
    .entry delete 0 end
    .lbl configure -text "Ingrese algo y presione Mostrar"
}

# Función para ejecutar comando seleccionado y mostrar salida
proc ejecutarComando {} {
    # Obtener comando del combobox
    set cmd [.combo get]

    # Ejecutar el comando y capturar salida
    if {[catch {exec $cmd} resultado]} {
        .lbl configure -text "Error al ejecutar comando: $resultado"
    } else {
        .lbl configure -text "Salida de '$cmd':\n$resultado"
    }
}

# Botones
button .btnMostrar -text "Mostrar y Guardar" -command mostrarTexto
button .btnLimpiar -text "Limpiar" -command limpiar
button .btnEjecutar -text "Ejecutar Comando" -command ejecutarComando

# Organizar widgets
pack .lbl -padx 10 -pady 10
pack .entry -padx 10 -pady 5
pack .chkGuardar -padx 10 -pady 5
pack .combo -padx 10 -pady 5
pack .btnMostrar -side left -padx 10 -pady 10
pack .btnLimpiar -side left -padx 10 -pady 10
pack .btnEjecutar -side left -padx 10 -pady 10

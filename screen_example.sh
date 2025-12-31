#!/usr/bin/env wish

# Configurar ventana principal
wm title . "Demo Tcl/Tk con wish"

# Crear una etiqueta que mostrará mensajes
label .lbl -text "Ingrese algo y presione Mostrar"

# Crear campo de entrada
entry .entry -width 30

# Función para mostrar texto de la entrada en la etiqueta
proc mostrarTexto {} {
    set texto [.entry get]
    if {$texto eq ""} {
        .lbl configure -text "Por favor ingrese algo."
    } else {
        .lbl configure -text "Ingresaste: $texto"
    }
}

# Función para limpiar entrada y etiqueta
proc limpiar {} {
    .entry delete 0 end
    .lbl configure -text "Ingrese algo y presione Mostrar"
}

# Botón para mostrar texto
button .btnMostrar -text "Mostrar" -command mostrarTexto

# Botón para limpiar
button .btnLimpiar -text "Limpiar" -command limpiar

# Organizar widgets con pack
pack .lbl -padx 10 -pady 10
pack .entry -padx 10 -pady 5
pack .btnMostrar -side left -padx 10 -pady 10
pack .btnLimpiar -side left -padx 10 -pady 10

# Iniciar el loop principal (wish lo hace automáticamente)


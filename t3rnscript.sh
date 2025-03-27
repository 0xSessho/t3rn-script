#!/bin/bash

# Función para obtener la última versión de GitHub
obtener_ultima_version() {
    echo "Obteniendo la última versión disponible..."
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -oP '"tag_name": "v\K[^"]+')
    if [ -z "$LATEST_VERSION" ]; then
        echo "No se pudo obtener la última versión. Usando v0.53.1 por defecto."
        LATEST_VERSION="0.53.1"
    fi
    echo "Última versión encontrada: v$LATEST_VERSION"
}

# Función para verificar si la versión existe en GitHub
verificar_version() {
    VERSION_TO_CHECK=$1

    # Si la versión no tiene ".0", agregarlo
    if [[ ! "$VERSION_TO_CHECK" =~ \. ]]; then
        VERSION_TO_CHECK="$VERSION_TO_CHECK.0"
    fi
    
    # Revisar si la versión existe
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://github.com/t3rn/executor-release/releases/download/v$VERSION_TO_CHECK/executor-linux-v$VERSION_TO_CHECK.tar.gz")
    
    if [ "$RESPONSE" -eq 404 ]; then
        echo "Error, versión no disponible o datos erróneos."
        exit 1
    fi
}

# Función para mostrar el menú de instalación
elegir_configuracion() {
    echo "Seleccione el tipo de instalación:"
    echo "1) Instalación por defecto"
    echo "2) Instalación personalizada"



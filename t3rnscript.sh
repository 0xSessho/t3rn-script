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

# Función para mostrar el menú de instalación
elegir_configuracion() {
    echo "Seleccione el tipo de instalación:"
    echo "1) Instalación por defecto"
    echo "2) Instalación personalizada"
    read -p "Ingrese su opción (1 o 2): " INSTALACION_OPCION
}

# Preguntar al usuario qué versión desea instalar
elegir_version() {
    echo "Seleccione la versión a instalar:"
    echo "1) Última versión disponible"
    echo "2) Versión específica"
    read -p "Ingrese su opción (1 o 2): " VERSION_OPCION

    if [ "$VERSION_OPCION" -eq 1 ]; then
        obtener_ultima_version
    elif [ "$VERSION_OPCION" -eq 2 ]; then
        read -p "Ingrese la versión específica (ejemplo: 0.53.1): " LATEST_VERSION
    else
        echo "Selección inválida. Saliendo."
        exit 1
    fi
}

# Función para seleccionar las redes habilitadas
seleccionar_redes() {
    ENABLED_NETWORKS='l2rn'  # Red fija
    echo "Seleccione las redes que desea habilitar (separadas por espacios):"
    echo "1) Base Sepolia"
    echo "2) Arbitrum Sepolia"
    echo "3) Optimism Sepolia"
    echo "4) Unichain Sepolia"
    echo "Ingrese las opciones separadas por espacios (por ejemplo: 1 3):"
    read -a REDES_SELECCIONADAS

    for opcion in "${REDES_SELECCIONADAS[@]}"; do
        case $opcion in
            1) ENABLED_NETWORKS+=",base-sepolia" ;;
            2) ENABLED_NETWORKS+=",arbitrum-sepolia" ;;
            3) ENABLED_NETWORKS+=",optimism-sepolia" ;;
            4) ENABLED_NETWORKS+=",unichain-sepolia" ;;
            *) echo "Opción inválida: $opcion" ;;
        esac
    done

    if [ "$ENABLED_NETWORKS" == 'l2rn' ]; then
        echo "Debe habilitar al menos una red adicional."
        exit 1
    fi

    echo "Redes habilitadas: $ENABLED_NETWORKS"
}

# Elegir la versión antes de la instalación
elegir_version

# Descargar y extraer el archivo
DOWNLOAD_URL="https://github.com/t3rn/executor-release/releases/download/v$LATEST_VERSION/executor-linux-v$LATEST_VERSION.tar.gz"
echo "Descargando: $DOWNLOAD_URL"
wget "$DOWNLOAD_URL"
tar -xvzf "executor-linux-v$LATEST_VERSION.tar.gz"

# Navegar al directorio correcto
cd executor/executor/bin || { echo "Error: No se pudo acceder al directorio."; exit 1; }

# Configuración inicial
elegir_configuracion

# Variables fijas
export ENVIRONMENT=testnet
export LOG_LEVEL=debug
export LOG_PRETTY=false

# Opción por defecto
if [ "$INSTALACION_OPCION" -eq 1 ]; then
    echo "Instalación por defecto seleccionada."
    export EXECUTOR_PROCESS_ORDERS=true
    export EXECUTOR_PROCESS_CLAIMS=true
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn,unichain-sepolia'
    export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
    export EXECUTOR_PROCESS_ORDERS_API_ENABLED=false
    export EXECUTOR_ENABLE_BATCH_BIDING=true
    export EXECUTOR_PROCESS_BIDS_ENABLED=true
    export EXECUTOR_MAX_L3_GAS_PRICE=1000
else
    echo "Instalación personalizada seleccionada."
    seleccionar_redes  # Llamada a la función de selección de redes
    read -p "Procesar órdenes? (true/false): " EXECUTOR_PROCESS_ORDERS
    export EXECUTOR_PROCESS_ORDERS
    read -p "Procesar claims? (true/false): " EXECUTOR_PROCESS_CLAIMS
    export EXECUTOR_PROCESS_CLAIMS
    read -p "Usar API de T3RN para órdenes pendientes? (true/false): " EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API
    export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API
fi

# Solicitar clave privada
echo "Ingrese su clave privada:"
read -s PRIVATE_KEY_LOCAL
export PRIVATE_KEY_LOCAL

echo "Configuración finalizada. Ejecutando el nodo..."
./executor

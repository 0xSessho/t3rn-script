
#!/bin/bash

#!/bin/bash

# Mostrar presentación con el nombre en ASCII en 3 partes con colores azul y rojo
echo -e "\033[0;34m╔═══╗░░╔═══╗░░░░░░░░╔╗░╔╦═══╗"
echo -e "\033[0;31m║╔═╗║░░║╔═╗║░░░░░░░░║║░║║╔═╗║"
echo -e "\033[0;34m║║║║╠╗╔╣╚══╦══╦══╦══╣╚═╝║║░║║"
echo -e "\033[0;31m║║║║╠╬╬╩══╗║║═╣══╣══╣╔═╗║║░║║"
echo -e "\033[0;34m║╚═╝╠╬╬╣╚═╝║║═╬══╠══║║░║║╚═╝║"
echo -e "\033[0;31m╚═══╩╝╚╩═══╩══╩══╩══╩╝░╚╩═══╝"
echo -e "\033[0;34m░╔╗╔═══╗░░░░░░░░░░░░░░░░░╔╗░░"
echo -e "\033[0;31m╔╝╚╣╔═╗║░░░░░░░░░░░░░░░╔╝╚╗░"
echo -e "\033[0;34m╚╗╔╩╝╔╝╠═╦═╗░╔══╦══╦═╦╦═╩╗╔╝░"
echo -e "\033[0;31m░║║╔╗╚╗║╔╣╔╗╗║══╣╔═╣╔╬╣╔╗║║░░"
echo -e "\033[0;34m░║╚╣╚═╝║║║║║║╠══║╚═╣║║║╚╝║╚╗░"
echo -e "\033[0;31m░╚═╩═══╩╝╚╝╚╝╚══╩══╩╝╚╣╔═╩═╝░"
echo -e "\033[0;34m░░░░░░░░░░░░░░░░░░░░░░║║░░░░░"
echo -e "\033[0;31m░░░░░░░░░░░░░░░░░░░░░░╚╝░░░░░"
echo -e "\033[0m"  # Restablecer el color al predeterminado


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
        verificar_version "$LATEST_VERSION"  # Verificar que la versión existe
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

# Función para configurar RPC
configurar_rpc() {
    # RPC por defecto
    DEFAULT_RPC_ENDPOINTS='{
        "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
        "arbt": ["https://arbitrum-sepolia.drpc.org/", "https://sepolia-rollup.arbitrum.io/rpc"],
        "bast": ["https://base-sepolia-rpc.publicnode.com/", "https://base-sepolia.drpc.org/"],
        "opst": ["https://sepolia.optimism.io/", "https://optimism-sepolia.drpc.org/"],
        "unit": ["https://unichain-sepolia.drpc.org/", "https://sepolia.unichain.org/"]
    }'

    echo "¿Desea usar RPC por defecto (1) o RPC privados (Alchemy) (2)?"
    echo "Para usar RPC privados (Alchemy), necesita su API key y los URL de RPC."
    read -p "Ingrese su opción (1 o 2): " RPC_OPCION

    if [ "$RPC_OPCION" -eq 1 ]; then
        export RPC_ENDPOINTS="$DEFAULT_RPC_ENDPOINTS"
    elif [ "$RPC_OPCION" -eq 2 ]; then
        echo "Ingrese los RPC para cada red (deje vacío para usar los predeterminados):"
        
        read -p "Ingrese RPC para Arbitrum Sepolia: " RPC_ARBITRUM
        read -p "Ingrese RPC para Base Sepolia: " RPC_BASE
        read -p "Ingrese RPC para Optimism Sepolia: " RPC_OPTIMISM
        read -p "Ingrese RPC para Unichain Sepolia: " RPC_UNICHAIN

        # Comprobamos si los RPC son válidos
        RPC_ARBITRUM=${RPC_ARBITRUM:-"https://arbitrum-sepolia.drpc.org/"}  # Usar el predeterminado si está vacío
        RPC_BASE=${RPC_BASE:-"https://base-sepolia-rpc.publicnode.com/"}  # Usar el predeterminado si está vacío
        RPC_OPTIMISM=${RPC_OPTIMISM:-"https://sepolia.optimism.io/"}  # Usar el predeterminado si está vacío
        RPC_UNICHAIN=${RPC_UNICHAIN:-"https://unichain-sepolia.drpc.org/"}  # Usar el predeterminado si está vacío
        
        export RPC_ENDPOINTS="{
            \"l2rn\": [\"https://b2n.rpc.caldera.xyz/http\"],
            \"arbt\": [\"$RPC_ARBITRUM\"],
            \"bast\": [\"$RPC_BASE\"],
            \"opst\": [\"$RPC_OPTIMISM\"],
            \"unit\": [\"$RPC_UNICHAIN\"]
        }"
    else
        echo "Opción inválida. Saliendo."
        exit 1
    fi
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
    # Preguntar si se desea usar la API de T3RN
    echo "¿Desea usar la API de T3RN para procesar órdenes pendientes?"
    echo "1) Sí"
    echo "2) No"
    read -p "Ingrese su opción (1 o 2): " API_OPCION
    
    if [ "$API_OPCION" -eq 1 ]; then
        export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
    elif [ "$API_OPCION" -eq 2 ]; then
        export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
        # Si no se usa la API, configurar RPC
        configurar_rpc
    else
        echo "Selección inválida. Saliendo."
        exit 1
    fi

    # Seleccionar redes habilitadas
    seleccionar_redes
fi

# Solicitar clave privada
echo "Ingrese su clave privada:"
read -s PRIVATE_KEY_LOCAL
export PRIVATE_KEY_LOCAL

echo "Configuración finalizada. Ejecutando el nodo..."
./executor

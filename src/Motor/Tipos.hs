module Motor.Tipos where

import qualified Data.Map as M

-- Meta: dos casos posibles
data Meta 
    = LlegarASala String                -- llegar a <sala>
    | LlevarObjetoASala String String   -- llevar <objeto> a <sala>
    deriving (Show, Eq, Read)

-- Solo 6 direcciones permitidas
data Direccion = Norte | Sur | Este | Oeste | Arriba | Abajo
    deriving (Show, Eq)

-- Salida: puede ser libre o estar bloqueada
data Salida
    = SalidaLibre String String             -- <dirección> -> <sala>
    | SalidaBloqueada String String String  -- <dirección> -> <sala> requiere <objeto>
    deriving (Show, Eq, Read)

data Sala = Sala { 
    salaId      :: String, 
    salaDesc    :: String, 
    salaSalidas :: [Salida],    -- Lista de salidas
    salaObjetos :: [String]     -- Identificadores de los objetos
} deriving (Show, Eq, Read)

data Objeto = Objeto { 
    objId   :: String, 
    objDesc :: String 
} deriving (Show, Eq, Read)

data Mundo = Mundo {
    mundoTitulo     :: String, 
    mundoInicio     :: String,
    mundoMeta       :: Meta,
    -- Manejamos diccionarios de salas y objetos, donde el ID es la clave
    mundoSalas      :: M.Map String Sala,
    mundoObjetos    :: M.Map String Objeto
} deriving (Show, Eq, Read)

data ErrorMundo 
    = ErrorSintaxis Int String
    | ErrorSemantica String
    deriving (Show, Eq)

-- Estado del juego en cada aspecto
data Estado = Estado {
    estadoSalaActual   :: String,   -- ID de la sala actual del jugador
    estadoInventario   :: [String], -- IDs de los objetos que lleva el jugador
    estadoMundo        :: Mundo     -- Referencia al mundo estático
} deriving (Show, Eq, Read)

-- Comandos mínimos
data Comando
    = Ir String
    | Mirar
    | Tomar String
    | Soltar String
    | Examinar String
    | Inventario
    | Guardar String
    | Cargar String
    | Ayuda
    | Salir
    deriving (Show, Eq)
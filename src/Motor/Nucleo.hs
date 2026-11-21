module Motor.Nucleo (
    estadoInicial,
    ejecutar
) where

import qualified Data.Map as M
import Motor.Tipos

-- Construye el estado inicial a partir de un mundo validado.
estadoInicial :: Mundo -> Estado
estadoInicial mundo = Estado
    { estadoSalaActual = mundoInicio mundo
    , estadoInventario = []
    , estadoMundo      = mundo
    }

-- Ejecuta un comando de forma pura sobre el estado actual y devuelve
-- los mensajes a mostrar junto con el nuevo estado.
ejecutar :: Comando -> Estado -> ([String], Estado)
ejecutar Mirar st =
    ([describirSala st], st)
ejecutar (Ir dir) st =
    moverPorDireccion dir st
ejecutar (Tomar obj) st =
    tomarObjeto obj st
ejecutar (Soltar obj) st =
    soltarObjeto obj st
ejecutar (Examinar obj) st =
    ([examinarObjeto obj st], st)
ejecutar Inventario st =
    ([describirInventario (estadoInventario st)], st)
ejecutar Ayuda st =
    (mensajesAyuda, st)
ejecutar (Guardar _) st =
    (["Guardando partida..."], st)
ejecutar (Cargar _) st =
    (["Cargando partida..."], st)
ejecutar Salir st =
    (["Saliendo del juego..."], st)

-- Obtiene la sala actual de forma segura.
obtenerSalaActual :: Estado -> Maybe Sala
obtenerSalaActual st =
    M.lookup (estadoSalaActual st) (mundoSalas (estadoMundo st))

-- Describe la sala actual: descripción, objetos visibles y salidas.
describirSala :: Estado -> String
describirSala st =
    case obtenerSalaActual st of
        Nothing -> "Error: la sala actual no existe en el mundo."
        Just sala ->
            unlines $
                [ salaDesc sala
                , formatoObjetosSala (salaObjetos sala)
                , formatoSalidasSala (salaSalidas sala)
                ]

formatoObjetosSala :: [String] -> String
formatoObjetosSala [] = "Objetos aquí: ninguno."
formatoObjetosSala os = "Objetos aquí: " ++ unwords os

formatoSalidasSala :: [Salida] -> String
formatoSalidasSala [] = "Salidas: ninguna."
formatoSalidasSala ss = "Salidas: " ++ unwords (map dirSalida ss)

dirSalida :: Salida -> String
dirSalida (SalidaLibre dir _)       = dir
dirSalida (SalidaBloqueada dir _ _) = dir

-- Intenta mover al jugador en la dirección indicada.
moverPorDireccion :: String -> Estado -> ([String], Estado)
moverPorDireccion dir st =
    case obtenerSalaActual st of
        Nothing -> (["Error: la sala actual no existe en el mundo."], st)
        Just sala ->
            case buscarSalida dir (salaSalidas sala) of
                Nothing ->
                    (["No hay salida en dirección '" ++ dir ++ "'."], st)
                Just salida ->
                    intentarCruzar salida st

buscarSalida :: String -> [Salida] -> Maybe Salida
buscarSalida _ [] = Nothing
buscarSalida dir (s:ss)
    | dirSalida s == dir = Just s
    | otherwise          = buscarSalida dir ss

intentarCruzar :: Salida -> Estado -> ([String], Estado)
intentarCruzar (SalidaLibre _ destino) st =
    finalizarMovimiento destino st
intentarCruzar (SalidaBloqueada _ destino reqObj) st
    | reqObj `elem` estadoInventario st =
        finalizarMovimiento destino st
    | otherwise =
        (["La salida está bloqueada: necesitas '" ++ reqObj ++ "'."], st)

finalizarMovimiento :: String -> Estado -> ([String], Estado)
finalizarMovimiento destino st =
    let nuevoEstado = st { estadoSalaActual = destino }
        baseMsgs    = [describirSala nuevoEstado]
        metaMsgs    = if metaCumplida nuevoEstado
                      then ["*** ¡Has ganado! ***"]
                      else []
    in (baseMsgs ++ metaMsgs, nuevoEstado)

-- Toma un objeto de la sala actual y lo añade al inventario.
tomarObjeto :: String -> Estado -> ([String], Estado)
tomarObjeto obj st =
    case obtenerSalaActual st of
        Nothing -> (["Error: la sala actual no existe en el mundo."], st)
        Just sala
            | not (obj `elem` salaObjetos sala) ->
                (["No ves '" ++ obj ++ "' aquí."], st)
            | otherwise ->
                let salaActualizada = sala { salaObjetos = quitarUno obj (salaObjetos sala) }
                    mapaActualizado = M.insert (salaId salaActualizada) salaActualizada (mundoSalas (estadoMundo st))
                    mundoActualizado = (estadoMundo st) { mundoSalas = mapaActualizado }
                    estadoActualizado = st
                        { estadoInventario = estadoInventario st ++ [obj]
                        , estadoMundo      = mundoActualizado
                        }
                    msgs = ["Tomas '" ++ obj ++ "'."] ++
                           if metaCumplida estadoActualizado
                           then ["*** ¡Has ganado! ***"]
                           else []
                in (msgs, estadoActualizado)

-- Suelta un objeto del inventario en la sala actual.
soltarObjeto :: String -> Estado -> ([String], Estado)
soltarObjeto obj st
    | not (obj `elem` estadoInventario st) =
        (["No llevas '" ++ obj ++ "' en tu inventario."], st)
    | otherwise =
        case obtenerSalaActual st of
            Nothing -> (["Error: la sala actual no existe en el mundo."], st)
            Just sala ->
                let invActualizado = quitarUno obj (estadoInventario st)
                    salaActualizada = sala { salaObjetos = salaObjetos sala ++ [obj] }
                    mapaActualizado = M.insert (salaId salaActualizada) salaActualizada (mundoSalas (estadoMundo st))
                    mundoActualizado = (estadoMundo st) { mundoSalas = mapaActualizado }
                    estadoActualizado = st
                        { estadoInventario = invActualizado
                        , estadoMundo      = mundoActualizado
                        }
                in (["Sueltas '" ++ obj ++ "'."], estadoActualizado)

quitarUno :: Eq a => a -> [a] -> [a]
quitarUno _ [] = []
quitarUno x (y:ys)
    | x == y    = ys
    | otherwise = y : quitarUno x ys

-- Examina un objeto si está en el inventario o en la sala actual.
examinarObjeto :: String -> Estado -> String
examinarObjeto obj st
    | not (estaEnInventarioOEnSala obj st) =
        "No ves '" ++ obj ++ "' aquí ni en tu inventario."
    | otherwise =
        case M.lookup obj (mundoObjetos (estadoMundo st)) of
            Nothing  -> "Objeto '" ++ obj ++ "' sin descripción."
            Just det -> objDesc det

estaEnInventarioOEnSala :: String -> Estado -> Bool
estaEnInventarioOEnSala obj st =
    obj `elem` estadoInventario st ||
    case obtenerSalaActual st of
        Nothing   -> False
        Just sala -> obj `elem` salaObjetos sala

describirInventario :: [String] -> String
describirInventario [] = "Tu inventario está vacío."
describirInventario xs = "Inventario: " ++ unwords xs

mensajesAyuda :: [String]
mensajesAyuda =
    [ "Comandos disponibles:"
    , "  mirar                  - Describe la sala actual"
    , "  ir <dirección>         - Mueve en norte, sur, este, oeste, arriba o abajo"
    , "  tomar / coger <objeto> - Toma un objeto de la sala"
    , "  soltar <objeto>        - Suelta un objeto del inventario"
    , "  examinar <objeto>      - Examina un objeto visible o en tu inventario"
    , "  inventario / inv       - Muestra tu inventario"
    , "  guardar <archivo>      - Guarda la partida"
    , "  cargar <archivo>       - Carga una partida"
    , "  ayuda                  - Muestra esta ayuda"
    , "  salir                  - Sale del juego"
    ]

-- Verifica si se cumple la meta del mundo en el estado dado.
metaCumplida :: Estado -> Bool
metaCumplida st =
    case mundoMeta (estadoMundo st) of
        LlegarASala salaObjetivo ->
            estadoSalaActual st == salaObjetivo
        LlevarObjetoASala objObjetivo salaObjetivo ->
            estadoSalaActual st == salaObjetivo && objObjetivo `elem` estadoInventario st
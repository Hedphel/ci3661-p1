module Motor.Mundo (
    leerMundo
) where

import Motor.Tipos
import Motor.Reconocedor
-- El (nub) nos permite identificar duplicados
import Data.List (nub)
import Data.Char (isSpace)
import qualified Data.Map as M

-- Eliminar espacios en blanco al inicio y al final de un String
pasarMachete :: String -> String
pasarMachete = dropWhile isSpace . reverse . dropWhile isSpace . reverse

-- Determinar si una línea debe ser ignorada (si es vacía o si es un comentario)
esLineaIgnorable :: String -> Bool
esLineaIgnorable [] = True
esLineaIgnorable ('#':_) = True
esLineaIgnorable _ = False

-- Toma el contenido del archivo, lo divide en líneas, le asigna su número 
-- de línea original (desde 1) y descarta comentarios y líneas vacías con sus espacios limpios.
limpiarLineas :: String -> [(Int, String)]
limpiarLineas contenido = procesarLineas (zip [1..] (lines contenido))
  where
    procesarLineas [] = []
    procesarLineas ((n, linea):xs)
      | esLineaIgnorable limpio = procesarLineas xs
      | otherwise               = (n, limpio) : procesarLineas xs
      where limpio = pasarMachete linea

-- Separar una lista de líneas numeradas en bloques
separarBloques :: [(Int, String)] -> [[(Int, String)]]
separarBloques = ir []
  where
    ir [] [] = []
    ir actual [] = [reverse actual]
    ir actual ((_, "-"):xs) = reverse actual : ir [] xs
    ir actual (par:xs)      = ir (par : actual) xs

-- Separar clave:valor en Just (clave, pasarMachete valor),
-- o devuelve Nothing si no hay ":" o la clave está vacía
partirClaveValor :: String -> Maybe (String, String)
partirClaveValor texto = ir [] texto
  where
    ir _ [] = Nothing
    ir acc (':':resto) = Just (reverse acc, pasarMachete resto)
    ir acc (c:cs)      = ir (c:acc) cs

-- Un identificador no puede estar vacío y solo admite minúsculas
esIdentificadorValido :: String -> Bool
esIdentificadorValido s = case ejecutarParser identificador s of
    Just _  -> True
    Nothing -> False

esCharId :: Char -> Bool
esCharId c =
  (c >= 'a' && c <= 'z')
  || (c >= '0' && c <= '9')
  || c == '_'
  || c `elem` "áéíóúñü"

esDireccionValida :: String -> Bool
esDireccionValida "norte"  = True
esDireccionValida "sur"    = True
esDireccionValida "este"   = True
esDireccionValida "oeste"  = True
esDireccionValida "arriba" = True
esDireccionValida "abajo"  = True
esDireccionValida _        = False

parsearSalida :: String -> Either String Salida
parsearSalida valor =
    case ejecutarParser salidaParser valor of
        Just s  -> Right s
        Nothing -> Left ("SALIDA mal formada o inválida: " ++ valor)

parsearMeta :: String -> Either String Meta
parsearMeta valor =
    case ejecutarParser metaParser valor of
        Just m  -> Right m
        Nothing -> Left ("META mal formada o inválida: " ++ valor)

data LineaCruda = LineaCruda
  { lcLinea :: Int
  , lcClave :: String
  , lcValor :: String
  }

parsearLineasCrudas :: [(Int, String)] -> ([ErrorMundo], [LineaCruda])
parsearLineasCrudas [] = ([], [])
parsearLineasCrudas ((n, texto):xs) =
  let (errsResto, okResto) = parsearLineasCrudas xs
      (errsActual, okActual) = agregarResultado n texto (partirClaveValor texto) ([], [])
  in (errsActual ++ errsResto, okActual ++ okResto)

agregarResultado
  :: Int
  -> String
  -> Maybe (String, String)
  -> ([ErrorMundo], [LineaCruda])
  -> ([ErrorMundo], [LineaCruda])
agregarResultado n texto Nothing (errs, ok) =
  (ErrorSintaxis n ("Línea sin formato CLAVE: valor: " ++ texto) : errs, ok)
agregarResultado n texto (Just ("", _)) (errs, ok) =
  (ErrorSintaxis n ("Clave vacía en línea: " ++ texto) : errs, ok)
agregarResultado n _ (Just (clave, valor)) (errs, ok) =
  (errs, LineaCruda { lcLinea = n, lcClave = clave, lcValor = valor } : ok)

data CabeceraAcc = CabeceraAcc
  { cabTitulo :: Maybe String
  , cabInicio :: Maybe String
  , cabMeta   :: Maybe Meta
  }

cabeceraVacia :: CabeceraAcc
cabeceraVacia = CabeceraAcc Nothing Nothing Nothing

validarCabecera :: [LineaCruda] -> ([ErrorMundo], Maybe (String, String, Meta))
validarCabecera lineas = finalizarCabecera (recorrerCabecera cabeceraVacia [] lineas)

recorrerCabecera :: CabeceraAcc -> [ErrorMundo] -> [LineaCruda] -> (CabeceraAcc, [ErrorMundo])
recorrerCabecera acc errs [] = (acc, errs)
recorrerCabecera acc errs (LineaCruda n "MUNDO" val : xs) =
  agregarTitulo n val (cabTitulo acc) acc errs xs
recorrerCabecera acc errs (LineaCruda n "INICIO" val : xs) =
  agregarInicio n val (cabInicio acc) acc errs xs
recorrerCabecera acc errs (LineaCruda n "META" val : xs) =
  agregarMeta n val (cabMeta acc) acc errs xs
recorrerCabecera acc errs (LineaCruda n clave _ : xs) =
  recorrerCabecera acc (ErrorSintaxis n ("Clave inválida en cabecera: " ++ clave) : errs) xs

finalizarCabecera :: (CabeceraAcc, [ErrorMundo]) -> ([ErrorMundo], Maybe (String, String, Meta))
finalizarCabecera (acc, errs) =
  chequearCampos (cabTitulo acc) (cabInicio acc) (cabMeta acc) errs

chequearCampos :: Maybe String -> Maybe String -> Maybe Meta -> [ErrorMundo] -> ([ErrorMundo], Maybe (String, String, Meta))
chequearCampos Nothing inicio meta errs =
  chequearCampos (Just "") inicio meta (ErrorSintaxis 1 "Falta MUNDO en cabecera" : errs)
chequearCampos titulo Nothing meta errs =
  chequearCampos titulo (Just "") meta (ErrorSintaxis 1 "Falta INICIO en cabecera" : errs)
chequearCampos titulo inicio Nothing errs =
  chequearCampos titulo inicio (Just (LlegarASala "")) (ErrorSintaxis 1 "Falta META en cabecera" : errs)
chequearCampos (Just t) (Just i) (Just m) [] =
  ([], Just (t, i, m))
chequearCampos _ _ _ errs =
  (reverse errs, Nothing)

agregarTitulo :: Int -> String -> Maybe String -> CabeceraAcc -> [ErrorMundo] -> [LineaCruda] -> (CabeceraAcc, [ErrorMundo])
agregarTitulo n _ (Just _) acc errs xs =
  recorrerCabecera acc (ErrorSintaxis n "MUNDO repetido en cabecera" : errs) xs
agregarTitulo n "" Nothing acc errs xs =
  recorrerCabecera acc (ErrorSintaxis n "MUNDO no puede estar vacío" : errs) xs
agregarTitulo _ val Nothing acc errs xs =
  recorrerCabecera (acc { cabTitulo = Just val }) errs xs

agregarInicio :: Int -> String -> Maybe String -> CabeceraAcc -> [ErrorMundo] -> [LineaCruda] -> (CabeceraAcc, [ErrorMundo])
agregarInicio n _ (Just _) acc errs xs =
  recorrerCabecera acc (ErrorSintaxis n "INICIO repetido en cabecera" : errs) xs
agregarInicio n val Nothing acc errs xs
  | esIdentificadorValido val = recorrerCabecera (acc { cabInicio = Just val }) errs xs
  | otherwise                 = recorrerCabecera acc (ErrorSintaxis n ("ID de INICIO inválido: " ++ val) : errs) xs

agregarMeta :: Int -> String -> Maybe Meta -> CabeceraAcc -> [ErrorMundo] -> [LineaCruda] -> (CabeceraAcc, [ErrorMundo])
agregarMeta n _ (Just _) acc errs xs =
  recorrerCabecera acc (ErrorSintaxis n "META repetida en cabecera" : errs) xs
agregarMeta n val Nothing acc errs xs =
  aplicarParseoMeta n (parsearMeta val) acc errs xs

aplicarParseoMeta :: Int -> Either String Meta -> CabeceraAcc -> [ErrorMundo] -> [LineaCruda] -> (CabeceraAcc, [ErrorMundo])
aplicarParseoMeta n (Left msg) acc errs xs =
  recorrerCabecera acc (ErrorSintaxis n msg : errs) xs
aplicarParseoMeta _ (Right m) acc errs xs =
  recorrerCabecera (acc { cabMeta = Just m }) errs xs

data ObjetoAcc = ObjetoAcc
  { objAccId   :: Maybe String
  , objAccDesc :: Maybe String
  }

objetoVacio :: ObjetoAcc
objetoVacio = ObjetoAcc Nothing Nothing

validarBloqueObjeto :: [LineaCruda] -> ([ErrorMundo], Maybe Objeto)
validarBloqueObjeto lineas = finalizarObjeto (recorrerObjeto objetoVacio [] lineas)

recorrerObjeto :: ObjetoAcc -> [ErrorMundo] -> [LineaCruda] -> (ObjetoAcc, [ErrorMundo])
recorrerObjeto acc errs [] = (acc, errs)
recorrerObjeto acc errs (LineaCruda n "OBJETO" val : xs) =
  agregarIdObjeto n val (objAccId acc) acc errs xs
recorrerObjeto acc errs (LineaCruda n "DESC" val : xs) =
  agregarDescObjeto n val (objAccDesc acc) acc errs xs
recorrerObjeto acc errs (LineaCruda n clave _ : xs) =
  recorrerObjeto acc (ErrorSintaxis n ("Clave inválida en bloque OBJETO: " ++ clave) : errs) xs

agregarIdObjeto :: Int -> String -> Maybe String -> ObjetoAcc -> [ErrorMundo] -> [LineaCruda] -> (ObjetoAcc, [ErrorMundo])
agregarIdObjeto n _ (Just _) acc errs xs =
  recorrerObjeto acc (ErrorSintaxis n "OBJETO repetido en bloque" : errs) xs
agregarIdObjeto n val Nothing acc errs xs
  | esIdentificadorValido val = recorrerObjeto (acc { objAccId = Just val }) errs xs
  | otherwise                 = recorrerObjeto acc (ErrorSintaxis n ("ID de OBJETO inválido: " ++ val) : errs) xs

agregarDescObjeto :: Int -> String -> Maybe String -> ObjetoAcc -> [ErrorMundo] -> [LineaCruda] -> (ObjetoAcc, [ErrorMundo])
agregarDescObjeto n _ (Just _) acc errs xs =
  recorrerObjeto acc (ErrorSintaxis n "DESC repetida en bloque OBJETO" : errs) xs
agregarDescObjeto n "" Nothing acc errs xs =
  recorrerObjeto acc (ErrorSintaxis n "DESC no puede estar vacía en OBJETO" : errs) xs
agregarDescObjeto _ val Nothing acc errs xs =
  recorrerObjeto (acc { objAccDesc = Just val }) errs xs

finalizarObjeto :: (ObjetoAcc, [ErrorMundo]) -> ([ErrorMundo], Maybe Objeto)
finalizarObjeto (acc, errs) = cerrarObjeto (objAccId acc) (objAccDesc acc) errs

cerrarObjeto :: Maybe String -> Maybe String -> [ErrorMundo] -> ([ErrorMundo], Maybe Objeto)
cerrarObjeto Nothing desc errs =
  cerrarObjeto (Just "") desc (ErrorSintaxis 1 "Falta OBJETO en bloque" : errs)
cerrarObjeto oid Nothing errs =
  cerrarObjeto oid (Just "") (ErrorSintaxis 1 "Falta DESC en bloque OBJETO" : errs)
cerrarObjeto (Just oid) (Just desc) [] =
  ([], Just (Objeto { objId = oid, objDesc = desc }))
cerrarObjeto _ _ errs =
  (reverse errs, Nothing)

data SalaAcc = SalaAcc
  { salaAccId      :: Maybe String
  , salaAccDesc    :: Maybe String
  , salaAccSalidas :: [Salida]
  , salaAccObjetos :: [String]
  }

salaVacia :: SalaAcc
salaVacia = SalaAcc Nothing Nothing [] []

validarBloqueSala :: [LineaCruda] -> ([ErrorMundo], Maybe Sala)
validarBloqueSala lineas = finalizarSala (recorrerSala salaVacia [] lineas)

recorrerSala :: SalaAcc -> [ErrorMundo] -> [LineaCruda] -> (SalaAcc, [ErrorMundo])
recorrerSala acc errs [] = (acc, errs)
recorrerSala acc errs (LineaCruda n "SALA" val : xs) =
  agregarIdSala n val (salaAccId acc) acc errs xs
recorrerSala acc errs (LineaCruda n "DESC" val : xs) =
  agregarDescSala n val (salaAccDesc acc) acc errs xs
recorrerSala acc errs (LineaCruda n "SALIDA" val : xs) =
  agregarSalidaSala n (parsearSalida val) acc errs xs
recorrerSala acc errs (LineaCruda n "OBJETO" val : xs) =
  agregarObjetoSala n val acc errs xs
recorrerSala acc errs (LineaCruda n clave _ : xs) =
  recorrerSala acc (ErrorSintaxis n ("Clave inválida en bloque SALA: " ++ clave) : errs) xs

agregarIdSala :: Int -> String -> Maybe String -> SalaAcc -> [ErrorMundo] -> [LineaCruda] -> (SalaAcc, [ErrorMundo])
agregarIdSala n _ (Just _) acc errs xs =
  recorrerSala acc (ErrorSintaxis n "SALA repetida en bloque" : errs) xs
agregarIdSala n val Nothing acc errs xs
  | esIdentificadorValido val = recorrerSala (acc { salaAccId = Just val }) errs xs
  | otherwise                 = recorrerSala acc (ErrorSintaxis n ("ID de SALA inválido: " ++ val) : errs) xs

agregarDescSala :: Int -> String -> Maybe String -> SalaAcc -> [ErrorMundo] -> [LineaCruda] -> (SalaAcc, [ErrorMundo])
agregarDescSala n _ (Just _) acc errs xs =
  recorrerSala acc (ErrorSintaxis n "DESC repetida en bloque SALA" : errs) xs
agregarDescSala n "" Nothing acc errs xs =
  recorrerSala acc (ErrorSintaxis n "DESC no puede estar vacía en SALA" : errs) xs
agregarDescSala _ val Nothing acc errs xs =
  recorrerSala (acc { salaAccDesc = Just val }) errs xs

agregarSalidaSala :: Int -> Either String Salida -> SalaAcc -> [ErrorMundo] -> [LineaCruda] -> (SalaAcc, [ErrorMundo])
agregarSalidaSala n (Left msg) acc errs xs =
  recorrerSala acc (ErrorSintaxis n msg : errs) xs
agregarSalidaSala _ (Right sal) acc errs xs =
  recorrerSala (acc { salaAccSalidas = sal : salaAccSalidas acc }) errs xs

agregarObjetoSala :: Int -> String -> SalaAcc -> [ErrorMundo] -> [LineaCruda] -> (SalaAcc, [ErrorMundo])
agregarObjetoSala n val acc errs xs
  | esIdentificadorValido val = recorrerSala (acc { salaAccObjetos = val : salaAccObjetos acc }) errs xs
  | otherwise                 = recorrerSala acc (ErrorSintaxis n ("ID de OBJETO inválido en SALA: " ++ val) : errs) xs

finalizarSala :: (SalaAcc, [ErrorMundo]) -> ([ErrorMundo], Maybe Sala)
finalizarSala (acc, errs) = cerrarSala (salaAccId acc) (salaAccDesc acc) (reverse (salaAccSalidas acc)) (reverse (salaAccObjetos acc)) errs

cerrarSala :: Maybe String -> Maybe String -> [Salida] -> [String] -> [ErrorMundo] -> ([ErrorMundo], Maybe Sala)
cerrarSala Nothing desc sals objs errs =
  cerrarSala (Just "") desc sals objs (ErrorSintaxis 1 "Falta SALA en bloque" : errs)
cerrarSala sid Nothing sals objs errs =
  cerrarSala sid (Just "") sals objs (ErrorSintaxis 1 "Falta DESC en bloque SALA" : errs)
cerrarSala (Just sid) (Just desc) sals objs [] =
  ([], Just (Sala { salaId = sid, salaDesc = desc, salaSalidas = sals, salaObjetos = objs }))
cerrarSala _ _ _ _ errs =
  (reverse errs, Nothing)

-- Encontrar elementos repetidos en una lista manteniendo su orden de aparición
buscarDuplicados :: Eq a => [a] -> [a]
buscarDuplicados = ir [] []
  where
    ir _ vistos [] = reverse vistos
    ir acum vistos (x:xs)
      | x `elem` acum && not (x `elem` vistos) = ir acum (x:vistos) xs
      | x `elem` acum                         = ir acum vistos xs
      | otherwise                             = ir (x:acum) vistos xs

salidaDir :: Salida -> String
salidaDir (SalidaLibre d _)     = d
salidaDir (SalidaBloqueada d _ _) = d

salidaDestino :: Salida -> String
salidaDestino (SalidaLibre _ s)     = s
salidaDestino (SalidaBloqueada _ s _) = s

salidaRequisito :: Salida -> Maybe String
salidaRequisito (SalidaLibre _ _)       = Nothing
salidaRequisito (SalidaBloqueada _ _ o) = Just o

validarSemantica
  :: String
  -> String
  -> Meta
  -> [Objeto]
  -> [Sala]
  -> Either [ErrorMundo] Mundo
validarSemantica titulo inicio meta objs salas =
  finalizarSemantica
    ( concat
        [ v2Duplicados objs salas
        , v3SalidasInexistentes mapaSalas salas
        , v4RequisitosInexistentes mapaObjs salas
        , v5DireccionesRepetidas salas
        , v6ObjetosSalaInexistentes mapaObjs salas
        , v7ObjetosEnMultiplesSalas salas
        , v8InicioYMeta mapaSalas mapaObjs inicio meta
        , v9SalasNoAlcanzables mapaSalas inicio salas
        , v10ObjetosNecesariosFaltantes meta objs salas
        ]
    )
    ( Mundo
        { mundoTitulo  = titulo
        , mundoInicio  = inicio
        , mundoMeta    = meta
        , mundoSalas   = mapaSalas
        , mundoObjetos = mapaObjs
        }
    )
  where
    mapaObjs  = M.fromList [(objId o, o) | o <- objs]
    mapaSalas = M.fromList [(salaId s, s) | s <- salas]

finalizarSemantica :: [ErrorMundo] -> Mundo -> Either [ErrorMundo] Mundo
finalizarSemantica [] mundo   = Right mundo
finalizarSemantica errs _     = Left errs

v2Duplicados :: [Objeto] -> [Sala] -> [ErrorMundo]
v2Duplicados objs salas =
  [ ErrorSemantica ("ID de objeto duplicado: " ++ oid) | oid <- buscarDuplicados (map objId objs) ]
  ++ [ ErrorSemantica ("ID de sala duplicado: " ++ sid) | sid <- buscarDuplicados (map salaId salas) ]

v3SalidasInexistentes :: M.Map String Sala -> [Sala] -> [ErrorMundo]
v3SalidasInexistentes mapaSalas salas =
  [ ErrorSemantica ("En la sala '" ++ salaId s ++ "', la salida '" ++ salidaDir sal ++ "' apunta a una sala inexistente: '" ++ salidaDestino sal ++ "'")
  | s <- salas
  , sal <- salaSalidas s
  , not (M.member (salidaDestino sal) mapaSalas)
  ]

v4RequisitosInexistentes :: M.Map String Objeto -> [Sala] -> [ErrorMundo]
v4RequisitosInexistentes mapaObjs salas =
  [ ErrorSemantica ("En la sala '" ++ salaId s ++ "', la salida '" ++ salidaDir sal ++ "' requiere un objeto inexistente: '" ++ objReq ++ "'")
  | s <- salas
  , sal <- salaSalidas s
  , Just objReq <- [salidaRequisito sal]
  , not (M.member objReq mapaObjs)
  ]

v5DireccionesRepetidas :: [Sala] -> [ErrorMundo]
v5DireccionesRepetidas salas =
  [ ErrorSemantica ("En la sala '" ++ salaId s ++ "' hay salidas repetidas en la dirección: '" ++ dir ++ "'")
  | s <- salas
  , dir <- buscarDuplicados (map salidaDir (salaSalidas s))
  ]

v6ObjetosSalaInexistentes :: M.Map String Objeto -> [Sala] -> [ErrorMundo]
v6ObjetosSalaInexistentes mapaObjs salas =
  [ ErrorSemantica ("En la sala '" ++ salaId s ++ "' aparece un objeto inexistente: '" ++ oid ++ "'")
  | s <- salas
  , oid <- salaObjetos s
  , not (M.member oid mapaObjs)
  ]

v7ObjetosEnMultiplesSalas :: [Sala] -> [ErrorMundo]
v7ObjetosEnMultiplesSalas salas =
  let apariciones = [oid | s <- salas, oid <- salaObjetos s]
  in [ ErrorSemantica ("El objeto '" ++ oid ++ "' aparece colocado más de una vez")
     | oid <- buscarDuplicados apariciones
     ]

v8InicioYMeta :: M.Map String Sala -> M.Map String Objeto -> String -> Meta -> [ErrorMundo]
v8InicioYMeta mapaSalas mapaObjs inicio meta =
  errInicio ++ errMeta
  where
    errInicio
      | M.member inicio mapaSalas = []
      | otherwise                 = [ErrorSemantica ("La sala de INICIO no existe: '" ++ inicio ++ "'")]
    errMeta = validarMetaRef mapaSalas mapaObjs meta

validarMetaRef :: M.Map String Sala -> M.Map String Objeto -> Meta -> [ErrorMundo]
validarMetaRef mapaSalas _ (LlegarASala sMeta)
  | M.member sMeta mapaSalas = []
  | otherwise                = [ErrorSemantica ("La sala de META no existe: '" ++ sMeta ++ "'")]
validarMetaRef mapaSalas mapaObjs (LlevarObjetoASala oMeta sMeta) =
  errObj ++ errSala
  where
    errObj
      | M.member oMeta mapaObjs = []
      | otherwise               = [ErrorSemantica ("El objeto requerido en META no existe: '" ++ oMeta ++ "'")]
    errSala
      | M.member sMeta mapaSalas = []
      | otherwise                = [ErrorSemantica ("La sala destino en META no existe: '" ++ sMeta ++ "'")]

v9SalasNoAlcanzables :: M.Map String Sala -> String -> [Sala] -> [ErrorMundo]
v9SalasNoAlcanzables mapaSalas inicio salas =
  let alcanzables = recorrerDesde mapaSalas [] [inicio]
  in [ ErrorSemantica ("La sala '" ++ salaId s ++ "' no es alcanzable desde INICIO")
     | s <- salas
     , not (salaId s `elem` alcanzables)
     ]

recorrerDesde :: M.Map String Sala -> [String] -> [String] -> [String]
recorrerDesde _ visitados [] = visitados
recorrerDesde mapaSalas visitados (actual:pendientes)
  | actual `elem` visitados = recorrerDesde mapaSalas visitados pendientes
  | otherwise =
      case M.lookup actual mapaSalas of
        Nothing -> recorrerDesde mapaSalas (actual : visitados) pendientes
        Just sala ->
          let vecinos = [salidaDestino sal | sal <- salaSalidas sala]
          in recorrerDesde mapaSalas (actual : visitados) (pendientes ++ vecinos)

v10ObjetosNecesariosFaltantes :: Meta -> [Objeto] -> [Sala] -> [ErrorMundo]
v10ObjetosNecesariosFaltantes meta _ salas =
  let reqSalidas = [objReq | s <- salas, sal <- salaSalidas s, Just objReq <- [salidaRequisito sal]]
      reqMeta    = objetosDeMeta meta
      necesarios = nub (reqSalidas ++ reqMeta)
      colocados  = [oid | s <- salas, oid <- salaObjetos s]
  in [ ErrorSemantica ("El objeto necesario '" ++ oid ++ "' no está colocado en ninguna sala")
     | oid <- necesarios
     , not (oid `elem` colocados)
     ]

objetosDeMeta :: Meta -> [String]
objetosDeMeta (LlegarASala _)           = []
objetosDeMeta (LlevarObjetoASala oid _) = [oid]


leerMundo :: String -> Either [ErrorMundo] Mundo
leerMundo contenido = procesarBloques (separarBloques (limpiarLineas contenido))

procesarBloques :: [[(Int, String)]] -> Either [ErrorMundo] Mundo
procesarBloques [] = Left [ErrorSintaxis 1 "El archivo de mundo está vacío"]
procesarBloques (cabRaw : restoRaw) =
  combinarSintaxis
    (parsearLineasCrudas cabRaw)
    (validarEntidadesRaw restoRaw)

combinarSintaxis
  :: ([ErrorMundo], [LineaCruda])
  -> ([ErrorMundo], [Objeto], [Sala])
  -> Either [ErrorMundo] Mundo
combinarSintaxis (errsLineasCab, lineasCab) (errsEntidades, objs, salas) =
  let (errsCab, cabOpt) = validarCabecera lineasCab
      todosSintaxis     = errsLineasCab ++ errsCab ++ errsEntidades
  in aplicarSintaxis todosSintaxis cabOpt objs salas

validarEntidadesRaw :: [[(Int, String)]] -> ([ErrorMundo], [Objeto], [Sala])
validarEntidadesRaw [] = ([], [], [])
validarEntidadesRaw (bRaw : bsRaw) =
  let (errsLineas, lineas) = parsearLineasCrudas bRaw
      (errsBloque, objs1, salas1) = despacharBloqueEntidad errsLineas lineas
      (errsResto, objs2, salas2) = validarEntidadesRaw bsRaw
  in (errsBloque ++ errsResto, objs1 ++ objs2, salas1 ++ salas2)

despacharBloqueEntidad :: [ErrorMundo] -> [LineaCruda] -> ([ErrorMundo], [Objeto], [Sala])
despacharBloqueEntidad (e:es) _ = (e:es, [], [])
despacharBloqueEntidad [] [] = ([ErrorSintaxis 1 "Bloque vacío"], [], [])
despacharBloqueEntidad [] (lc@(LineaCruda _ "OBJETO" _) : resto) =
  tomarObjeto (validarBloqueObjeto (lc : resto))
despacharBloqueEntidad [] (lc@(LineaCruda _ "SALA" _) : resto) =
  tomarSala (validarBloqueSala (lc : resto))
despacharBloqueEntidad [] (LineaCruda n clave _ : _) =
  ([ErrorSintaxis n ("Bloque inesperado iniciando con clave: " ++ clave)], [], [])

tomarObjeto :: ([ErrorMundo], Maybe Objeto) -> ([ErrorMundo], [Objeto], [Sala])
tomarObjeto (errs, Nothing) = (errs, [], [])
tomarObjeto (errs, Just o)  = (errs, [o], [])

tomarSala :: ([ErrorMundo], Maybe Sala) -> ([ErrorMundo], [Objeto], [Sala])
tomarSala (errs, Nothing) = (errs, [], [])
tomarSala (errs, Just s)  = (errs, [], [s])

aplicarSintaxis
  :: [ErrorMundo]
  -> Maybe (String, String, Meta)
  -> [Objeto]
  -> [Sala]
  -> Either [ErrorMundo] Mundo
aplicarSintaxis [] (Just (titulo, inicio, meta)) objs salas =
  validarSemantica titulo inicio meta objs salas
aplicarSintaxis errs _ _ _ =
  Left errs
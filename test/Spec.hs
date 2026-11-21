module Main (main) where

import System.Exit (exitFailure, exitSuccess)
import Test.HUnit

import Motor.Persistencia (cargarMundo)
import Motor.Comandos (leerComando)
import Motor.Mundo (leerMundo)
import Motor.Nucleo (ejecutar, estadoInicial)
import Motor.Tipos

-- Mundo mínimo de prueba para ejercitar salidas bloqueadas, objetos y victoria
mundoPrueba :: String
mundoPrueba = unlines
    [ "MUNDO: Prueba Unitaria"
    , "INICIO: entrada"
    , "META: llevar tesoro a camara"
    , "---"
    , "OBJETO: llave"
    , "DESC: Una llave de hierro."
    , "---"
    , "OBJETO: tesoro"
    , "DESC: Un cofre brillante."
    , "---"
    , "SALA: entrada"
    , "DESC: La entrada principal."
    , "SALIDA: norte -> camara requiere llave"
    , "OBJETO: llave"
    , "---"
    , "SALA: camara"
    , "DESC: La camara secreta."
    , "SALIDA: sur -> entrada"
    , "OBJETO: tesoro"
    ]

ejecutarGuion :: [Comando] -> Estado -> ([String], Estado)
ejecutarGuion [] st = ([], st)
ejecutarGuion (c:cs) st =
    let (m1, st1) = ejecutar c st
        (m2, st2) = ejecutarGuion cs st1
    in (m1 ++ m2, st2)

-- 1. Pruebas de leerMundo (sintaxis y semantica)
testMundoEjemplo :: Test
testMundoEjemplo = TestCase $ do
    res <- cargarMundo "mundos/entrega.txt"
    case res of
        Left errs -> assertFailure ("Se esperaba mundo valido, pero dio errores: " ++ show errs)
        Right m   -> assertEqual "Titulo del mundo de ejemplo" "Entrega a última hora" (mundoTitulo m)

testMundoInvalidoSemantica :: Test
testMundoInvalidoSemantica = TestCase $ do
    contenido <- readFile "mundos/invalido_semantica.txt"
    case leerMundo contenido of
        Right _   -> assertFailure "Se esperaban errores semanticos"
        Left errs -> assertBool ("Se esperaban al menos 9 errores, hubo " ++ show (length errs)) (length errs >= 9)

testMundoInvalidoSintaxis :: Test
testMundoInvalidoSintaxis = TestCase $ do
    contenido <- readFile "mundos/invalido_sintaxis.txt"
    case leerMundo contenido of
        Right _   -> assertFailure "Se esperaban errores de sintaxis"
        Left errs -> assertBool "Debe haber al menos un error de sintaxis" (not (null errs))

testMundoVacio :: Test
testMundoVacio = TestCase $
    case leerMundo "" of
        Right _   -> assertFailure "Mundo vacio debe fallar"
        Left errs -> assertEqual "Un error por archivo vacio" 1 (length errs)

testMundoConComentariosYEspacios :: Test
testMundoConComentariosYEspacios = TestCase $ do
    let txt = unlines
            [ "   # Comentario inicial"
            , ""
            , "  MUNDO:   Con Espacios  "
            , "  INICIO:  sala_a "
            , "  META: llegar a sala_a "
            , " --- "
            , " SALA: sala_a "
            , " DESC: Unica sala "
            ]
    case leerMundo txt of
        Left errs -> assertFailure ("No debio fallar: " ++ show errs)
        Right m   -> assertEqual "Titulo limpio" "Con Espacios" (mundoTitulo m)

-- 2. Pruebas de leerComando
testCmdMirar :: Test
testCmdMirar = TestCase $
    assertEqual "mirar" (Just Mirar) (leerComando "mirar")

testCmdIr :: Test
testCmdIr = TestCase $
    assertEqual "ir norte" (Just (Ir "norte")) (leerComando "  IR   NORTE ")

testCmdTomarYCoger :: Test
testCmdTomarYCoger = TestCase $ do
    assertEqual "tomar llave" (Just (Tomar "llave")) (leerComando "tomar llave")
    assertEqual "coger llave" (Just (Tomar "llave")) (leerComando "coger llave")

testCmdSoltarYExaminar :: Test
testCmdSoltarYExaminar = TestCase $ do
    assertEqual "soltar llave" (Just (Soltar "llave")) (leerComando "soltar llave")
    assertEqual "examinar llave" (Just (Examinar "llave")) (leerComando "examinar llave")

testCmdInventarioAlias :: Test
testCmdInventarioAlias = TestCase $ do
    assertEqual "inventario" (Just Inventario) (leerComando "inventario")
    assertEqual "inv" (Just Inventario) (leerComando "inv")

testCmdGuardarCargarAyudaSalir :: Test
testCmdGuardarCargarAyudaSalir = TestCase $ do
    assertEqual "guardar" (Just (Guardar "save.txt")) (leerComando "guardar save.txt")
    assertEqual "cargar" (Just (Cargar "save.txt")) (leerComando "cargar save.txt")
    assertEqual "ayuda" (Just Ayuda) (leerComando "ayuda")
    assertEqual "salir" (Just Salir) (leerComando "salir")

testCmdInvalidos :: Test
testCmdInvalidos = TestCase $ do
    assertEqual "vacio" Nothing (leerComando "")
    assertEqual "solo espacios" Nothing (leerComando "   ")
    assertEqual "verbo desconocido" Nothing (leerComando "volar")
    assertEqual "ir sin direccion" Nothing (leerComando "ir")
    assertEqual "tomar sin objeto" Nothing (leerComando "tomar")

-- 3. Pruebas puras de ejecutar y estadoInicial
testEstadoInicial :: Test
testEstadoInicial = TestCase $
    case leerMundo mundoPrueba of
        Left errs -> assertFailure (show errs)
        Right m   -> do
            let st = estadoInicial m
            assertEqual "Sala inicial" "entrada" (estadoSalaActual st)
            assertEqual "Inventario vacio" [] (estadoInventario st)

testSalidaBloqueadaSinObjeto :: Test
testSalidaBloqueadaSinObjeto = TestCase $
    case leerMundo mundoPrueba of
        Left errs -> assertFailure (show errs)
        Right m   -> do
            let st0 = estadoInicial m
                (_, st1) = ejecutar (Ir "norte") st0
            assertEqual "No debe moverse sin la llave" "entrada" (estadoSalaActual st1)

testCruzarSalidaBloqueadaConObjeto :: Test
testCruzarSalidaBloqueadaConObjeto = TestCase $
    case leerMundo mundoPrueba of
        Left errs -> assertFailure (show errs)
        Right m   -> do
            let st0 = estadoInicial m
                (_, st1) = ejecutarGuion [Tomar "llave", Ir "norte"] st0
            assertEqual "Debe cruzar a camara con llave" "camara" (estadoSalaActual st1)
            assertEqual "Inventario tiene llave" ["llave"] (estadoInventario st1)

testSoltarYExaminar :: Test
testSoltarYExaminar = TestCase $
    case leerMundo mundoPrueba of
        Left errs -> assertFailure (show errs)
        Right m   -> do
            let st0 = estadoInicial m
                (msgs, st1) = ejecutarGuion [Tomar "llave", Examinar "llave", Soltar "llave"] st0
            assertEqual "Inventario vuelve a quedar vacio" [] (estadoInventario st1)
            assertBool "Examinar muestra descripcion" ("Una llave de hierro." `elem` msgs)

testVictoriaPorSecuencia :: Test
testVictoriaPorSecuencia = TestCase $
    case leerMundo mundoPrueba of
        Left errs -> assertFailure (show errs)
        Right m   -> do
            let st0 = estadoInicial m
                (msgs, stFinal) = ejecutarGuion [Tomar "llave", Ir "norte", Tomar "tesoro"] st0
            assertEqual "Debe estar en camara" "camara" (estadoSalaActual stFinal)
            assertBool "Debe emitir mensaje exacto de victoria" ("*** ¡Has ganado! ***" `elem` msgs)

pruebas :: Test
pruebas = TestList
    [ TestLabel "leerMundo: entrega.txt" testMundoEjemplo
    , TestLabel "leerMundo: invalido_semantica.txt" testMundoInvalidoSemantica
    , TestLabel "leerMundo: invalido_sintaxis.txt" testMundoInvalidoSintaxis
    , TestLabel "leerMundo: vacio" testMundoVacio
    , TestLabel "leerMundo: comentarios y espacios" testMundoConComentariosYEspacios
    , TestLabel "leerComando: mirar" testCmdMirar
    , TestLabel "leerComando: ir" testCmdIr
    , TestLabel "leerComando: tomar y coger" testCmdTomarYCoger
    , TestLabel "leerComando: soltar y examinar" testCmdSoltarYExaminar
    , TestLabel "leerComando: inventario e inv" testCmdInventarioAlias
    , TestLabel "leerComando: guardar, cargar, ayuda y salir" testCmdGuardarCargarAyudaSalir
    , TestLabel "leerComando: invalidos" testCmdInvalidos
    , TestLabel "ejecutar: estadoInicial" testEstadoInicial
    , TestLabel "ejecutar: salida bloqueada sin objeto" testSalidaBloqueadaSinObjeto
    , TestLabel "ejecutar: cruzar salida bloqueada" testCruzarSalidaBloqueadaConObjeto
    , TestLabel "ejecutar: soltar y examinar" testSoltarYExaminar
    , TestLabel "ejecutar: victoria por secuencia" testVictoriaPorSecuencia
    ]

main :: IO ()
main = do
    resCounts <- runTestTT pruebas
    if errors resCounts + failures resCounts == 0
        then exitSuccess
        else exitFailure
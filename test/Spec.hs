module Main (main) where

import Data.List (isInfixOf)
import Test.HUnit
import qualified Data.Map as M
import System.Exit (exitFailure, exitSuccess)

import Motor.Tipos
import Motor.Mundo (leerMundo)
import Motor.Comandos (leerComando)
import Motor.Nucleo (estadoInicial, ejecutar)

--------------------------------------------------------------------------------
-- 1. Pruebas de leerComando
--------------------------------------------------------------------------------

testComandosValidos :: Test
testComandosValidos = TestCase $ do
    assertEqual "mirar" (Just Mirar) (leerComando "mirar")
    assertEqual "ir norte" (Just (Ir "norte")) (leerComando "ir norte")
    assertEqual "dirección directa norte" (Just (Ir "norte")) (leerComando "norte")
    assertEqual "abreviatura sur 's'" (Just (Ir "sur")) (leerComando "s")
    assertEqual "tomar objeto" (Just (Tomar "carnet")) (leerComando "tomar carnet")
    assertEqual "sinónimo coger" (Just (Tomar "carnet")) (leerComando "coger carnet")
    assertEqual "soltar objeto" (Just (Soltar "carnet")) (leerComando "soltar carnet")
    assertEqual "examinar objeto" (Just (Examinar "carnet")) (leerComando "examinar carnet")
    assertEqual "inventario" (Just Inventario) (leerComando "inventario")
    assertEqual "alias inv" (Just Inventario) (leerComando "inv")
    assertEqual "guardar partida" (Just (Guardar "p.txt")) (leerComando "guardar p.txt")
    assertEqual "cargar partida" (Just (Cargar "p.txt")) (leerComando "cargar p.txt")
    assertEqual "ayuda" (Just Ayuda) (leerComando "ayuda")
    assertEqual "salir" (Just Salir) (leerComando "salir")

testComandosInvalidos :: Test
testComandosInvalidos = TestCase $ do
    assertEqual "comando inexistente" Nothing (leerComando "bailar")
    assertEqual "comando vacío" Nothing (leerComando "")
    assertEqual "ir sin dirección" Nothing (leerComando "ir")
    assertEqual "tomar sin objeto" Nothing (leerComando "tomar")
    assertEqual "comando con palabras de más" Nothing (leerComando "tomar carnet ahora mismo")

--------------------------------------------------------------------------------
-- 2. Pruebas de leerMundo con archivos del proyecto
--------------------------------------------------------------------------------

testMundoEntrega :: Test
testMundoEntrega = TestCase $ do
    contenido <- readFile "mundos/entrega.txt"
    case leerMundo contenido of
        Left errs -> assertFailure ("entrega.txt debió ser válido pero dio errores: " ++ show errs)
        Right m   -> assertEqual "Título de entrega.txt" "Entrega a última hora" (mundoTitulo m)

testMundoInvalidoSintaxis :: Test
testMundoInvalidoSintaxis = TestCase $ do
    contenido <- readFile "mundos/invalido_sintaxis.txt"
    case leerMundo contenido of
        Right _   -> assertFailure "invalido_sintaxis.txt debió fallar por sintaxis"
        Left errs -> assertBool "Debe reportar múltiples errores sintácticos" (length errs >= 4)

testMundoInvalidoSemantica :: Test
testMundoInvalidoSemantica = TestCase $ do
    contenido <- readFile "mundos/invalido_semantica.txt"
    case leerMundo contenido of
        Right _   -> assertFailure "invalido_semantica.txt debió fallar por semántica"
        Left errs -> assertBool "Debe reportar al menos 9 errores de validación" (length errs >= 9)

--------------------------------------------------------------------------------
-- 3. Pruebas del Núcleo puro (ejecutar) y Variante 0 (Oscuridad)
--------------------------------------------------------------------------------

-- Mini-mundo con una sala iluminada y una sala oscura
mundoPrueba :: Mundo
mundoPrueba = Mundo
    { mundoTitulo  = "Mundo de prueba"
    , mundoInicio  = "origen"
    , mundoMeta    = LlegarASala "meta"
    , mundoSalas   = M.fromList
        [ ("origen", Sala
            { salaId      = "origen"
            , salaDesc    = "Sala inicial iluminada."
            , salaSalidas = [ SalidaLibre "norte" "cueva"
                            , SalidaBloqueada "este" "meta" "llave"
                            ]
            , salaObjetos = ["antorcha", "piedra"]
            , salaOscura  = False
            })
        , ("cueva", Sala
            { salaId      = "cueva"
            , salaDesc    = "Cueva muy profunda."
            , salaSalidas = [SalidaLibre "sur" "origen"]
            , salaObjetos = ["tesoro"]
            , salaOscura  = True
            })
        , ("meta", Sala
            { salaId      = "meta"
            , salaDesc    = "Sala final."
            , salaSalidas = [SalidaLibre "oeste" "origen"]
            , salaObjetos = []
            , salaOscura  = False
            })
        ]
    , mundoObjetos = M.fromList
        [ ("antorcha", Objeto "antorcha" "Una antorcha que da luz." True)
        , ("piedra", Objeto "piedra" "Una simple piedra." False)
        , ("tesoro", Objeto "tesoro" "Un tesoro brillante." False)
        , ("llave", Objeto "llave" "Una llave dorada." False)
        ]
    }

testChoqueSalidaBloqueada :: Test
testChoqueSalidaBloqueada = TestCase $ do
    let st0 = estadoInicial mundoPrueba
        (msgs, st1) = ejecutar (Ir "este") st0
    assertBool "Mensaje de bloqueo" (any (isInfixOf "bloqueada") msgs)
    assertEqual "El jugador no se mueve" "origen" (estadoSalaActual st1)

testTomarYSoltarObjeto :: Test
testTomarYSoltarObjeto = TestCase $ do
    let st0 = estadoInicial mundoPrueba
        (_, st1) = ejecutar (Tomar "piedra") st0
    assertEqual "Objeto en inventario" ["piedra"] (estadoInventario st1)
    let (_, st2) = ejecutar (Soltar "piedra") st1
    assertEqual "Inventario vacío tras soltar" [] (estadoInventario st2)

testVarianteOscuridadSinLuz :: Test
testVarianteOscuridadSinLuz = TestCase $ do
    let st0 = estadoInicial mundoPrueba
        (_, stEnCueva) = ejecutar (Ir "norte") st0
        (msgsMirar, _) = ejecutar Mirar stEnCueva
        (msgsTomar, _) = ejecutar (Tomar "tesoro") stEnCueva
    assertBool "Mirar en cueva oscura oculta info"
        (any (\m -> "oscuro" `elem` words m) msgsMirar)
    assertBool "No puede tomar en cueva oscura"
        (any (\m -> "oscuro" `elem` words m) msgsTomar)

testVarianteOscuridadConLuz :: Test
testVarianteOscuridadConLuz = TestCase $ do
    let st0 = estadoInicial mundoPrueba
        (_, stConAntorcha) = ejecutar (Tomar "antorcha") st0
        (_, stEnCueva)     = ejecutar (Ir "norte") stConAntorcha
        (msgsMirar, _)     = ejecutar Mirar stEnCueva
    assertBool "Con luz se ven los objetos"
        (any (\m -> "tesoro" `elem` words m) msgsMirar)

testLlegarALaMeta :: Test
testLlegarALaMeta = TestCase $ do
    let st0 = estadoInicial mundoPrueba
        -- Simulamos que el jugador consiguió la llave
        stConLlave = st0 { estadoInventario = ["llave"] }
        (msgs, stFinal) = ejecutar (Ir "este") stConLlave
    assertEqual "Llega a la meta" "meta" (estadoSalaActual stFinal)
    assertBool "Mensaje de victoria" ("*** ¡Has ganado! ***" `elem` msgs)

testExaminarObjeto :: Test
testExaminarObjeto = TestCase $ do
    let st0 = estadoInicial mundoPrueba
        (msg, _) = (head (fst (ejecutar (Examinar "antorcha") st0)), st0)
    assertBool "Descripción de antorcha" (isInfixOf "antorcha" msg)

testInventarioComando :: Test
testInventarioComando = TestCase $ do
    let st0 = estadoInicial mundoPrueba
        (msgsVacio, _) = ejecutar Inventario st0
    assertBool "Inventario vacío" (any (isInfixOf "vacío") msgsVacio)
    let (_, stConObj) = ejecutar (Tomar "piedra") st0
        (msgsLleno, _) = ejecutar Inventario stConObj
    assertBool "Inventario con piedra" (any (isInfixOf "piedra") msgsLleno)

testAyudaComando :: Test
testAyudaComando = TestCase $ do
    let st0 = estadoInicial mundoPrueba
        (msgs, _) = ejecutar Ayuda st0
    assertBool "Comandos de ayuda presentes" (length msgs >= 5)

testMovimientoLibre :: Test
testMovimientoLibre = TestCase $ do
    let st0 = estadoInicial mundoPrueba
        (_, st1) = ejecutar (Ir "norte") st0
    assertEqual "Mueve a cueva" "cueva" (estadoSalaActual st1)
    let (_, st2) = ejecutar (Ir "sur") st1
    assertEqual "Regresa a origen" "origen" (estadoSalaActual st2)

testDireccionInexistente :: Test
testDireccionInexistente = TestCase $ do
    let st0 = estadoInicial mundoPrueba
        (msgs, st1) = ejecutar (Ir "arriba") st0
    assertBool "No hay salida arriba" (any (isInfixOf "No hay salida") msgs)
    assertEqual "Sigue en origen" "origen" (estadoSalaActual st1)

testExaminarSinLuz :: Test
testExaminarSinLuz = TestCase $ do
    let st0 = estadoInicial mundoPrueba
        (_, stEnCueva) = ejecutar (Ir "norte") st0
        (msgs, _) = ejecutar (Examinar "tesoro") stEnCueva
    assertBool "No puede examinar en oscuridad" (any (isInfixOf "oscuro") msgs)

--------------------------------------------------------------------------------
-- Runner principal
--------------------------------------------------------------------------------

tests :: Test
tests = TestList
    [ TestLabel "01. Comandos Válidos" testComandosValidos
    , TestLabel "02. Comandos Inválidos" testComandosInvalidos
    , TestLabel "03. Mundo Entrega Válido" testMundoEntrega
    , TestLabel "04. Mundo Inválido Sintaxis" testMundoInvalidoSintaxis
    , TestLabel "05. Mundo Inválido Semántica" testMundoInvalidoSemantica
    , TestLabel "06. Movimiento Libre" testMovimientoLibre
    , TestLabel "07. Dirección Inexistente" testDireccionInexistente
    , TestLabel "08. Salida Bloqueada" testChoqueSalidaBloqueada
    , TestLabel "09. Tomar y Soltar" testTomarYSoltarObjeto
    , TestLabel "10. Examinar Objeto" testExaminarObjeto
    , TestLabel "11. Inventario" testInventarioComando
    , TestLabel "12. Ayuda" testAyudaComando
    , TestLabel "13. Oscuridad Sin Luz" testVarianteOscuridadSinLuz
    , TestLabel "14. Examinar Sin Luz" testExaminarSinLuz
    , TestLabel "15. Oscuridad Con Luz" testVarianteOscuridadConLuz
    , TestLabel "16. Victoria en Meta" testLlegarALaMeta
    ]

main :: IO ()
main = do
    resultado <- runTestTT tests
    if errors resultado > 0 || failures resultado > 0
        then exitFailure
        else exitSuccess

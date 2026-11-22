module Main (main) where

-- import Control.Monad (unless)
import Data.Char (isSpace)
import System.Environment (getArgs)
import System.Exit (ExitCode (..), exitSuccess, exitWith)
import System.IO (isEOF, hFlush, stdout)

import Motor.Comandos (leerComando)
-- import Motor.Mundo (leerMundo)
import Motor.Nucleo (ejecutar, estadoInicial)
import Motor.Persistencia (cargarMundo, cargameEsta, guardarmeEsta)
import Motor.Tipos (Comando (..), ErrorMundo (..), Mundo (..), Estado (..))

main :: IO ()
main = do
    args <- getArgs
    case args of
        ["-validar", rutaMundo] -> modoValidar rutaMundo
        [rutaMundo]             -> modoJuego rutaMundo
        _                       -> do
            putStrLn "Error: uso correcto: aventura [-validar] <archivo_mundo>"
            exitWith (ExitFailure 1)

formatearError :: ErrorMundo -> String
formatearError (ErrorSintaxis linea msg) =
    "Error: línea " ++ show linea ++ ": " ++ msg
formatearError (ErrorSemantica msg) =
    "Error: " ++ msg

imprimirErroresYSalir :: [ErrorMundo] -> IO a
imprimirErroresYSalir errs = do
    mapM_ (putStrLn . formatearError) errs
    exitWith (ExitFailure 1)

modoValidar :: FilePath -> IO ()
modoValidar rutaMundo = do
    res <- cargarMundo rutaMundo
    case res of
        Left errs -> imprimirErroresYSalir errs
        Right _   -> do
            putStrLn "Mundo válido."
            exitSuccess

modoJuego :: FilePath -> IO ()
modoJuego rutaMundo = do
    res <- cargarMundo rutaMundo
    case res of
        Left errs -> imprimirErroresYSalir errs
        Right mundo -> do
            let st0 = estadoInicial mundo
                (msgsIniciales, _) = ejecutar Mirar st0
            putStrLn ("=== " ++ mundoTitulo mundo ++ " ===")
            mapM_ putStrLn msgsIniciales
            if "*** ¡Has ganado! ***" `elem` msgsIniciales
                then exitSuccess
                else bucleJuego st0

trim :: String -> String
trim = dropWhile isSpace . reverse . dropWhile isSpace . reverse

bucleJuego :: Estado -> IO ()
bucleJuego st = do
    fin <- isEOF
    if fin
        then exitSuccess
        else do
            putStr "> "
            hFlush stdout
            linea <- getLine
            let limpia = trim linea
            if null limpia
                then bucleJuego st
                else manejarLinea limpia st

manejarLinea :: String -> Estado -> IO ()
manejarLinea linea st =
    case leerComando linea of
        Nothing -> do
            putStrLn "No entiendo ese comando. Escribe 'ayuda' para ver los disponibles."
            bucleJuego st
        Just Salir -> do
            putStrLn "¡Hasta luego!"
            exitSuccess
        Just (Guardar rutaSave) -> do
            resSave <- guardarmeEsta rutaSave st
            case resSave of
                Left errMsg -> putStrLn ("Error: " ++ errMsg)
                Right ()    -> putStrLn ("Partida guardada en '" ++ rutaSave ++ "'.")
            bucleJuego st
        Just (Cargar rutaSave) -> do
            resLoad <- cargameEsta rutaSave (estadoMundo st)
            case resLoad of
                Left errMsg -> do
                    putStrLn ("Error: " ++ errMsg)
                    bucleJuego st
                Right nuevoEstado -> do
                    putStrLn ("Partida cargada desde '" ++ rutaSave ++ "'.")
                    let (msgsMirar, _) = ejecutar Mirar nuevoEstado
                    mapM_ putStrLn msgsMirar
                    if "*** ¡Has ganado! ***" `elem` msgsMirar
                        then exitSuccess
                        else bucleJuego nuevoEstado
        Just cmd -> do
            let (msgs, nuevoEstado) = ejecutar cmd st
            mapM_ putStrLn msgs
            if "*** ¡Has ganado! ***" `elem` msgs
                then exitSuccess
                else bucleJuego nuevoEstado
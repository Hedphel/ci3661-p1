module Motor.Persistencia (
    cargarMundo,
    guardarmeEsta,
    cargameEsta
) where

import Motor.Tipos
import Motor.Mundo
import System.IO
import Text.Read (readMaybe)
import Control.Exception (try, IOException)

-- Se lee un archivo de texto en UTF-8 y se procesa con leerMundo
cargarMundo :: FilePath -> IO (Either [ErrorMundo] Mundo)
cargarMundo ruta = do
    h <- openFile ruta ReadMode
    hSetEncoding h utf8
    -- Aquí se extrae el contenido del archivo y se convierte en
    -- String para pasárselo a la función leerMundo
    contenido <- hGetContents h
    return (leerMundo contenido)

-- Guardar partida serializando el Estado
guardarmeEsta :: FilePath -> Estado -> IO (Either String ())
guardarmeEsta ruta estado = do
    resultado <- try (writeFile ruta (show estado)) :: IO (Either IOException ())
    return case resultado of
        Left err -> Left ("Error al guardar la partida: " ++ show err)
        Right _  -> Right ()

-- Cargar partida. Si falla (el archivo no existe o corrupto), informa sin caerse
cargameEsta :: FilePath -> Mundo -> IO (Either String Estado)
cargameEsta ruta mundoActual = do
    resultado <- try (readFile ruta) :: IO (Either IOException String)
    return case resultado of
        Left _ -> Left "El archivo de guardado no existe o no se puede leer."
        Right contenido -> case readMaybe contenido of
            Nothing -> Left "El archivo de guardado está corrupto."
            Just estadoGuardado -> 
                if mundoTitulo (estadoMundo estadoGuardado) /= mundoTitulo mundoActual
                then Left "El archivo de guardado pertenece a otro mundo."
                else Right estadoGuardado
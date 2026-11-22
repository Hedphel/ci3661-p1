module Motor.Comandos (
    leerComando
) where

import Data.Char (toLower)
import Motor.Tipos

leerComando :: String -> Maybe Comando
leerComando linea = 
    -- Usamos words para separar las palabras sin contar espacios y demás
    case words (map toLower linea) of
        ["mirar"]   -> Just Mirar
        ["ir", dir] -> Just (Ir dir)
        [dir] | dir `elem` ["norte", "sur", "este", "oeste", "arriba", "abajo"] -> Just (Ir dir)
        ["n"] -> Just (Ir "norte")
        ["s"] -> Just (Ir "sur")
        ["e"] -> Just (Ir "este")
        ["o"] -> Just (Ir "oeste")

        -- Con objetos
        ["examinar", objeto]-> Just (Examinar objeto)
        ["soltar", objeto]  -> Just (Soltar objeto)
        -- Guardia: se verifican las otras condiciones si la primera es true
        [verbo, objeto] | verbo == "coger" || verbo == "tomar" ->
            Just (Tomar objeto)

        -- Alias para inventario
        ["inventario"]  -> Just Inventario
        ["inv"]         -> Just Inventario

        -- Archivos
        ["guardar", archivo]-> Just (Guardar archivo)
        ["cargar", archivo] -> Just (Cargar archivo)

        -- Otros
        ["ayuda"]   -> Just Ayuda

        -- Salir del juego
        ["salir"] -> Just Salir

        -- Todo lo demás
        _ -> Nothing
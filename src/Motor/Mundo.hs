module Motor.Mundo (
    leerMundo
) where

import Motor.Tipos
-- El (nub) nos permite identificar duplicados
import Data.List (nub)
import qualified Data.Map as M

leerMundo :: String -> Either [ErrorMundo] Mundo
leerMundo contenido = 
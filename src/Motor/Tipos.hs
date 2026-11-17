module Motor.Tipos where

import qualified Data.Map as M

data Objeto = Objeto { 
    objId :: String, 
    objDesc :: String 
} deriving (Show, Eq)

data Sala = Sala { 
    salaId :: String, 
    salaDesc :: String, 
    salaSalidas :: [(String, String)], 
    salaObjetos :: [String] 
} deriving (Show, Eq)


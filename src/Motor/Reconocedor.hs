module Motor.Reconocedor where

import Data.Char (isSpace)

-- Reconoce un solo carácter si cumple el predicado p
caracter :: (Char -> Bool) -> ReadS Char
caracter p (c:cs) | p c = [(c, cs)]
caracter _ _            = []

-- Reconoce exactamente un carácter dado
char :: Char -> ReadS Char
char c = caracter (== c)

-- Reconoce exactamente una cadena literal al inicio del texto
cadena :: String -> ReadS String
cadena []     s = [("", s)]
cadena (x:xs) s =
    [ (x : resto1, resto2)
    | (_, resto1) <- char x s
    , (_, resto2) <- cadena xs resto1
    ]

-- Alternativa: junta los resultados de probar p y luego q
(<|>) :: ReadS a -> ReadS a -> ReadS a
(p <|> q) s = p s ++ q s

-- Cero o más repeticiones de p
muchos :: ReadS a -> ReadS [a]
muchos p = uno <|> ninguno
    where
        ninguno s = [([], s)]
        uno s =
            [ (x : xs, r2)
            | (x, r1)  <- p s
            , (xs, r2) <- muchos p r1
            ]

-- Una o más repeticiones de p
algunos :: ReadS a -> ReadS [a]
algunos p s =
    [ (x : xs, r2)
    | (x, r1)  <- p s
    , (xs, r2) <- muchos p r1
    ]

-- Salta cero o más espacios en blanco
espacios :: ReadS String
espacios = muchos (caracter isSpace)
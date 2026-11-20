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

-- Retorna un valor sin consumir nada de la entrada (pure/return)
retornar :: a -> ReadS a
retornar x s = [(x, s)]

-- Reconocedor que siempre falla
fallar :: ReadS a
fallar _ = []

-- Mapea una función sobre el resultado del reconocedor (fmap)
transformar :: (a -> b) -> ReadS a -> ReadS b
transformar f p s = [(f x, resto) | (x, resto) <- p s]

-- Secuenciación monádica (bind / >>=)
encadenar :: ReadS a -> (a -> ReadS b) -> ReadS b
encadenar p f s =
    [ (y, resto2)
    | (x, resto1) <- p s
    , (y, resto2) <- f x resto1
    ]

-- Alternativa: prueba el primer reconocedor y luego el segundo
infixr 5 <|>
(<|>) :: ReadS a -> ReadS a -> ReadS a
(p <|> q) s = p s ++ q s

-- Cero o más repeticiones
muchos :: ReadS a -> ReadS [a]
muchos p = algunos p <|> retornar []

-- Una o más repeticiones
algunos :: ReadS a -> ReadS [a]
algunos p s =
    [ (x : xs, r2)
    | (x, r1)  <- p s
    , (xs, r2) <- muchos p r1
    ]

-- Ejecuta p, luego q, y descarta el resultado de p (*>)
descartarPrimero :: ReadS a -> ReadS b -> ReadS b
descartarPrimero p q = encadenar p (\_ -> q)

-- Ejecuta p, luego q, y descarta el resultado de q (<*)
descartarSegundo :: ReadS a -> ReadS b -> ReadS a
descartarSegundo p q = encadenar p (\x -> transformar (\_ -> x) q)

-- Salta cero o más espacios en blanco
espacios :: ReadS String
espacios = muchos (caracter isSpace)

-- Ejecuta un reconocedor saltando espacios antes y después
entreEspacios :: ReadS a -> ReadS a
entreEspacios p = descartarPrimero espacios (descartarSegundo p espacios)

-- Intenta reconocer con p; si falla, devuelve el valor por defecto
opcional :: a -> ReadS a -> ReadS a
opcional defecto p = p <|> retornar defecto
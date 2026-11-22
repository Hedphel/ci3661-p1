# Proyecto 1: Motor de aventuras en Haskell

Este es el proyecto #1, hecho en Haskell, para la materia CI3661 - Laboratorio de Lenguajes de Programación I (Septiembre – Diciembre 2026).

## Integrantes y variante del proyecto

Los integrantes de este proyecto son:
- Samuel Piña, 23-10515
- Alejandro de Vincenzo, 19-10109

Para calcular la variante a programar, se hizo el siguiente cálculo con los carnets: $2310515 + 1910109 = 4220624$, luego: $4220624 \mod 4 = 0$. Por tanto, la variante a usar será `0. Oscuridad`:

> Una sala puede tener `OSCURA: si` y un objeto `LUZ: si`. En una sala oscura, si el jugador no lleva un objeto que dé luz, `mirar` no muestra objetos ni salidas y no se puede tomar ni examinar nada de la sala.

---

## Requisitos previos

Para ejecutar este proyecto se debe usar **Cabal** y **GHC** (GHC 9.4.8 o superior, configurable mediante [GHCup](https://www.haskell.org/ghcup/)).

Primero, hay que verificar que las herramientas estén en el `PATH`:
```bash
ghc --version
cabal --version
```
*(Para agregar a GHCup al `PATH` se puede usar `export PATH="$HOME/.ghcup/bin:$PATH"`).*

---

## Compilación

Para compilar la biblioteca y el ejecutable del proyecto:

```bash
cabal build
```

Para compilar solo el ejecutable `aventura`:
```bash
cabal build exe:aventura
```

---

## Pruebas automatizadas

El proyecto incluye una suite de pruebas con HUnit que cubre validación sintáctica y semántica, combinadores de comandos, el núcleo puro (solo con su parte funcional) y la mecánica relacionada con la variante de oscuridad en los mundos.

Para ejecutar todas las pruebas:
```bash
cabal test
```

Para ver el detalle de cada prueba en la consola:
```bash
cabal test --test-show-details=always
```

---

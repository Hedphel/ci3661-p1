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

## Ejecución

El ejecutable `aventura` soporta dos modalidades de uso según la especificación.

### 1. Solo validación (`-validar`)

En esta modalidad se verifica que el archivo del mundo no tenga errores de sintaxis ($V_1$) ni semántica ($V_2$ a $V_{10}$). Imprime `Mundo válido.` (código de salida 0) o la lista de errores encontrados (código de salida 1).

```bash
# Validar un mundo correcto
cabal run exe:aventura -- -validar mundos/entrega.txt

# Validar mundos con errores sintácticos
cabal run exe:aventura -- -validar mundos/invalido_sintaxis.txt

# Validar mundos con errores semánticos
cabal run exe:aventura -- -validar mundos/invalido_semantica.txt
```

### 2. Modo interactivo (Jugar)

Esta es la modalidad en la que se carga el mundo y se abre la sesión interactiva con el indicador `> ` para jugar:
```bash
cabal run exe:aventura -- mundos/entrega.txt
```

Acorde a la especificación, se pueden usar los comandos en las siguientes categorías:
- Movimiento: `ir norte`, `ir sur`, `ir este`, `ir oeste`, `ir arriba`, `ir abajo` (alternativemente, se puede escribir la dirección `norte`, `sur`, o su abreviación `n`, `s`, etc.).
- Entorno: `mirar`, `inventario` (o `inv`), `ayuda`.
- Objetos: `tomar <objeto>` (o `coger`), `soltar <objeto>`, `examinar <objeto>`.
- Partidas: `guardar <archivo>`, `cargar <archivo>`.
- Salir: `salir`.

### 3. Modo con entrada redirigida (Scripts / Guiones)

En este modo, se usan "guiones", que son secuencias de comandos en un archivo para correr pruebas automatizadas. Termina normalmente al alcanzar `EOF` o al cumplirse la meta con un mensaje de éxito:
```bash
cabal run exe:aventura -- mundos/entrega.txt < guiones/entrega.txt
```


## D1. ¿Cómo representan el mundo y los identificadores?
**Contexto**:
El mundo del juego contiene un título, una sala inicial, una meta, un conjunto de salas; y cada sala y objeto tienen identificadores par ellos.
**Opciones**:
1. Representar salas y objetos como listas puras ([Sala], [Objeto]) buscando por identificador con funciones de lista
2. Usar Data.Map String Sala y Data.Map String Objeto, indexados por el identificador de tipo String dentro del mundo.
**Decisión**: Estado guarda la sala actual (estadoSalaActual), el inventario (estadoInventario) y estadoMundo (Mundo).
Se utiliza Data.Map String Sala y Data.Map String Objeto para indexar salas y objetos por su identificador String.
**Consecuencias**: El núcleo se mantiene puro, y hay una mejor y más sencilla trazabilidad en el sistema.


## D2. ¿Qué guarda el Estado? ¿Se copia el mundo entero o solo lo que cambia? ¿Dónde quedan los objetos soltados?
**Contexto**:
El núcleo del juego (Motor.Nucleo) es puro: recibe un estado y un comando, y devuelve un nuevo estado (y mensajes/eventos) sin mutar variables en el lugar
**Opciones**:
1. Guardar en Estado el ID de la sala actual, el inventario del jugador ([String]), una referencia a Mundo (o las salas/objetos dinámicos) y actualizar el mapa de salas al soltar un objeto para que quede en la sala actual.
2. Duplicar y rearmar estructuras completas innecesariamente en cada turno, o descartar los objetos soltados / dejarlos flotando fuera de la sala actual.
**Decisión**:

**Consecuencias**:

## D3. ¿Cómo logran reportar todos los errores de validación y no solo el primero? ¿Por qué no basta con encadenar Either con do?

## D4. Uso de ReadS en reconocedores
**Contexto**:
Se puede elegir entre `ReadS` y `newtype` para crear los reconocedores del proyecot.
**Opciones**:
1. `ReadS`: recibe un String y devuelve una lista de pares. Nos devuelve una lista vacía de no reconocer nada, y en caso de reconocer varios pares (hay ambigüedad) se devuelven todos.
2. `newtype` define un nuevo tipo
**Decisión**: 
Se eligió ReadS por la facilidad y la poca fricción que existe para los reconocedores
**Consecuencias**: Hay menos código repetitivo, se pierde el aumento de tiempo al compilar newtypes.

## D6. Cómo se representan las salidas bloqueadas
**Contexto**:
Una salida en una sala puede requerir un objeto específico para poder pasar por ella.
**Opciones**:
Se tienen dos opciones distintas para poder representar que una salida requiera un objeto:
1. Usando `String`, lo que obliga a que tengamos que guardar esta salida sin parsearla, y es al final que se hacen las comprobaciones necesarias.
2. Usar un tipo algebraico definido por nosotros `Salida` que distingue las salidas libres y las que requieran objetos.
**Decisión**: 
Se elige el tipo algebraico que distingue explícitamente las salidas libres de las que requieren un objeto.
**Consecuencias**: Tenemos más seguridad de tipos, un pattern matching claro en `Motor.Nucleo` y validaciones semánticas en `Motor.Mundo`.

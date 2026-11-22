# Declaración de uso de IA

Para este proyecto, los integrantes utilizaron Gemini como herramienta para completar el proyecto para los siguientes aspectos:

- Cómo estructurar los directorios y archivos acorde a las mejores prácticas.
- Sugerencias en los tipos
- Manejo de alias en los comandos
- Estructura y corrección de los reconocedores
- Generación del mundo y del nucleo acorde a las decisiones tomadas
- Corregir e identificar qué cambios en otros módulos además de Tipos (en Mundo) había que hacer para poder implementar las variantes
- Generación de pruebas en Spec.hs

Una sugerencia de la IA fue usar una tupla para la salida:
```haskell
-- (Dirección, SalaDestino, Maybe ObjetoRequerido)
type Salida = (String, String, Maybe String)
```

Sin embargo, es mucho más apropiado tener un tipo de datos que definimos nosotros para así tener las operaciones apropiadas. Así tenemos la estructura para verificar que las salas estén bloqueadas por algún objeto o no, de una vez.
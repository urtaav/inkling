# inkling — leer y hablar inglés para devs (spec)

Fecha: 2026-10-21 · Estado: aprobado para implementar

## Objetivo

App personal (Android, sin internet) para practicar inglés todos los días
leyendo textos cortos a nivel A2–B1, sobre todo del trabajo de desarrollo de
software, y luego hablar 1–2 minutos sobre el tema grabándose.

Por qué: los textos de redes se repiten, no son del nivel del usuario y hablan
de cosas que no usa. Su mundo es el desarrollo de software.

Éxito:
- Cada día hay un texto nuevo, a su nivel y útil para su trabajo.
- Lee cómodo en el transporte, de noche o en una pausa, y sabe cuánto tardó.
- Habla usando frases del texto y se escucha.
- Hay contenido para al menos 6 meses.

## Decisiones tomadas con el usuario

- 100 % sin internet: los textos van dentro de la app; mínimo 180 (6 meses),
  meta 200.
- ~70 % trabajo de software, ~30 % general.
- Textos originales con el enfoque de las guías de frases para ingenieros de
  software, sin copiar ningún libro.
- Lectura estilo e-reader con 3 estilos: **Papel**, **Sepia**, **Noche**
  (le gustaron los tres).
- Temporizador de lectura.
- Marcar como leído, releer, favoritos, reto de 30 días.
- Resaltar phrasal verbs y frases útiles, sin enseñar gramática.
- Pregunta para hablar al final, con temporizador y grabación (solo en el
  teléfono).
- **Preguntas:** formular preguntas le cuesta. Cada texto trae "Preguntas
  útiles" y la práctica de hablar le pide hacer preguntas.
- **Los 7 tiempos más usados** se cubren siempre: presente simple, presente
  continuo, pasado simple, pasado continuo, presente perfecto, futuro con
  *will*, futuro con *going to*. Cada texto tiene uno de enfoque.
- Dependencias aprobadas: flutter_riverpod, shared_preferences, record,
  just_audio, path_provider. Fuente Literata (OFL) como archivo.

## Contenido

`assets/lessons/index.json` lista los archivos de tandas; cada tanda es un
JSON con lecciones:

```json
{
  "id": "w001",
  "title": "The bug nobody could reproduce",
  "topic": "work",            // work | life
  "tag": "Debugging",          // subtema visible
  "level": "B1",               // A2 | B1
  "tense": "pastSimple",       // uno de los 7
  "tenseTip": "Hablas de algo que pasó y terminó: verbo en pasado (reported, decided).",
  "paragraphs": ["On Monday, QA reported a bug... I decided to [[look into]] it..."],
  "phrases": [{"text": "look into", "meaning": "investigar, revisar", "example": "I'll look into the logs after lunch."}],
  "questions": [{"en": "Could you walk me through the steps?", "es": "¿Me explicas los pasos uno por uno?"}],
  "speak": "Think of a bug you fixed recently. Ask your teammate three questions about it, then explain what you did."
}
```

- `[[frase]]` marca en el texto una frase de `phrases` (mismo texto, sin
  importar mayúsculas). Una marca sin frase en la lista es un error de
  contenido que una prueba detecta.
- Largo: 280–420 palabras (~3 min a ritmo A2–B1).
- Cada tanda reparte los 7 tiempos y los temas. La primera tanda (30) es el
  primer reto.
- Agregar textos = agregar un JSON y listarlo en `index.json`.

## Funcionamiento

- **Texto del día:** el primero no leído en orden de biblioteca. Si todos
  están leídos, el leído hace más tiempo. Así "nunca se acaban" aunque se
  repitan después de 200.
- **Leído:**
  - "Terminé" lo marca leído y guarda el tiempo (último y mejor) y la fecha.
  - Se puede releer siempre; cada lectura suma.
- **Favoritos:** corazón en el texto; lista en la biblioteca.
- **Frases guardadas:** al tocar una frase resaltada sale su significado, su
  ejemplo y "Guardar"; quedan en la lista "Mis frases".
- **Reto de 30 días:**
  - "Empezar reto" fija la fecha de inicio.
  - El día N del reto es el día N desde el inicio.
  - Un día cuenta si ese día terminó al menos un texto.
  - Muestra 30 casillas, la racha actual y el día en que va.
  - Puede reiniciarse.
- **Racha:** días seguidos (hasta hoy o ayer) con al menos un texto
  terminado.
- **Temporizador:**
  - Arranca al abrir el texto y se pausa si la app pasa a segundo plano.
  - Se ve discreto arriba ("⏱ 1:42"); al terminar muestra tiempo y palabras
    por minuto.
- **Hablar:**
  - Tras "Terminé" se muestran la pregunta, las preguntas útiles como
    sugerencia, un temporizador de 2 min y el botón grabar/detener.
  - Las grabaciones de ese texto se listan con reproducir y borrar.
  - Archivos en el almacenamiento privado de la app.
- **Estilos:**
  - Papel `#F4F1EA`/`#2B2A28`, Sepia `#EFE3CC`/`#45382A`, Noche
    `#1B1A18`/`#CFC8BB`.
  - Modo **Automático** (predeterminado): Papel de 7 a 18 h, Sepia de 18 a
    21 h, Noche de 21 a 7 h.
  - Tamaño de letra ajustable (16–24).
  - Literata, interlineado 1.65, ancho máximo ~65 caracteres, sin
    animaciones de página.
- **UI en español**; los textos, en inglés.

## Pantallas

1. **Inicio:**
   - texto del día (tema, minutos, enfoque) con "Leer";
   - tarjeta del reto (día N de 30 y casillas) y racha;
   - accesos a Biblioteca y Mis frases.
2. **Lectura:**
   - barra discreta con reto/tema y temporizador;
   - título, meta (tema · min · nivel · enfoque);
   - párrafos con frases subrayadas (puntos);
   - tip del tiempo verbal;
   - "Preguntas útiles";
   - favorito y "Terminé".
3. **Hablar:** pregunta, preguntas útiles, temporizador, grabar, lista de
   grabaciones y "Listo".
4. **Biblioteca:**
   - filtros Todos / Trabajo / Vida / Favoritos / Leídos / Sin leer;
   - lista con título, tema, tiempo de enfoque y marca de leído.
5. **Mis frases:** lista con significado y ejemplo; quitar.
6. **Ajustes:** estilo (Automático/Papel/Sepia/Noche), tamaño de letra,
   reiniciar reto.

## Arquitectura

- `lib/content/`:
  - `lesson.dart`: modelo, parseo y división de párrafos en partes
    texto/frase;
  - `library.dart`: carga de assets.
- `lib/progress/progress_store.dart`:
  - leídos, tiempos, favoritos, frases, reto y ajustes;
  - todo sobre una interfaz `KeyValueStore` (shared_preferences en la app,
    memoria en pruebas);
  - reloj inyectable.
- `lib/progress/picker.dart`: texto del día, racha y estado del reto (puro,
  con pruebas).
- `lib/speak/recorder.dart`: interfaz sobre record/just_audio para poder
  probar la pantalla con una falsa.
- `lib/ui/...`: pantallas; `lib/app/reading_theme.dart`: estilos y modo
  automático.

## Pruebas

- **Unitarias:**
  - parseo de `[[frase]]`;
  - toda marca del contenido real tiene frase;
  - todas las lecciones válidas (7 tiempos válidos, largo dentro de rango);
  - texto del día;
  - racha;
  - reto (días cumplidos, día actual, reinicio);
  - estilo automático por hora;
  - palabras por minuto.
- **De widget:**
  - lectura muestra frases y al tocar sale el significado;
  - "Terminé" guarda leído y tiempo;
  - favorito;
  - biblioteca filtra;
  - hablar graba y lista con una grabadora falsa.
- **Teléfono:**
  - grabación real;
  - estilos de noche;
  - APK release instalado.

## Fuera de alcance (por ahora)

- Audio de los textos (TTS).
- Diccionario completo.
- Sincronizar entre dispositivos.
- Generar textos con IA.
- Corrección de pronunciación.

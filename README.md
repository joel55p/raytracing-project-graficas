# Raytracing Diorama

Diorama de cubos texturizados con raytracing

## Fuentes consultadas(IA)
- [Referencias bibliograficas](referencias/refesia.pdf)

## Features

- rotación de camara (WASD)
- zoom (Q/E o  con scroll )
- 5 materiales con textura (piedra, ladrillo, madera, metal, cristal)
- reflexion
- refraccion
- sombras
- skybox procedural
- cubos (AABB) como forma nueva de forma
- Renderizado(multi-threaded)

## Controles


 W/S para girar camara arriba/abajo
 A/D  girar camara izquierda/derecha 
 Q/E para zoom/minimizar camar 
 scroll para  zoom/minimizar camara

## Build

```bash
zig build run -Doptimize=ReleaseFast
zig build run
```


## Video

<!--  -->


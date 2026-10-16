const std = @import("std");
const rl = @import("raylib");
//file principal
const Framebuffer = @import("framebuffer.zig").Framebuffer;
const Forma = @import("formas.zig").Forma;
const Camera = @import("camera.zig").Camera;
const rt = @import("raytracer.zig");
const tex = @import("texture.zig");
const htmlColor = @import("cute_colors.zig").htmlColor;

//configuracion
const ancho = 800;
const alto = 600;
const num_hilos: usize = 8;
const profundidad_max: usize = 3;
const ContextoRender = struct {
    pixeles: [*]rl.Color,
    w: usize,
    h: usize,
    inicio_y: usize,
    fin_y: usize,
    objetos: []const Forma,
    luces: []const rt.Light,
    camara: Camera,
    texturas: []const tex.Textura,
    aspecto: f32,
    escala_fov: f32,
};

pub fn main() !void { 
    const alloc = std.heap.page_allocator;

    rl.initWindow(ancho, alto, "Raytracer");
    rl.setTraceLogLevel(.warning);
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var framebuffer = Framebuffer.init(ancho, alto);

    //texturas para mats
    const texturas = [_]tex.Textura{
        try tex.crear_tablero(alloc, 32, 4, htmlColor("#a09080"), htmlColor("#807060")),
        try tex.crear_ladrillos(alloc, 32, htmlColor("#b05a3c"), htmlColor("#c8b8a0")),
        try tex.crear_franjas(alloc, 32, 4, htmlColor("#b08040"), htmlColor("#785828")),
        try tex.crear_solido(alloc, 32, htmlColor("#d0d0d0")),
        try tex.crear_tablero(alloc, 32, 16, htmlColor("#d0e8f0"), htmlColor("#b8d8e8")),
    };

    //los 5 materiales:

    const piedra = rt.Material{//tablero gris
        .Color = rt.V3FromColor(htmlColor("#908070")), 
        .Especular = 10,
        .Indice_refraccion = 0,
        .Propiedades = .{ .Albedo = 0.8, .Especular = 0.1, .Reflectividad = 0, .Transparencia = 0 },
        .indice_textura = 0,
    };

    const ladrillo = rt.Material{ //patron ladrillo
        .Color = rt.V3FromColor(htmlColor("#b05a3c")), 
        .Especular = 5,
        .Indice_refraccion = 0,
        .Propiedades = .{ .Albedo = 0.9, .Especular = 0.05, .Reflectividad = 0, .Transparencia = 0 },
        .indice_textura = 1,
    };

    const madera = rt.Material{ //franjas cafe
        .Color = rt.V3FromColor(htmlColor("#b08040")),
        .Especular = 8,
        .Indice_refraccion = 0,
        .Propiedades = .{ .Albedo = 0.8, .Especular = 0.1, .Reflectividad = 0, .Transparencia = 0 },
        .indice_textura = 2,
    };

    const metal = rt.Material{ //tipo solido plateado
        .Color = rt.V3FromColor(htmlColor("#c0c0c0")),
        .Especular = 100,
        .Indice_refraccion = 0,
        .Propiedades = .{ .Albedo = 0.1, .Especular = 0.8, .Reflectividad = 0.7, .Transparencia = 0 },
        .indice_textura = 3,
    };

    const cristal = rt.Material{ //tablero azul transparente
        .Color = rt.V3FromColor(htmlColor("#b0c4de")),
        .Especular = 125,
        .Indice_refraccion = 1.5,
        .Propiedades = .{ .Albedo = 0, .Especular = 0.5, .Reflectividad = 0.1, .Transparencia = 0.8 },
        .indice_textura = 4,
    };

    //dioroma
    const objetos = [_]Forma{
        // piso de pieda
        .{ .Cubo = .{
            .min = .{ .x = -10, .y = -0.5, .z = -15 },
            .max = .{ .x = 10, .y = 0, .z = 5 },
            .material = piedra,
        } },
        // paredes trasera e izquierda de ladrillo
        .{ .Cubo = .{
            .min = .{ .x = -10, .y = 0, .z = -15 },
            .max = .{ .x = 10, .y = 8, .z = -14 },
            .material = ladrillo,
        } },
        .{ .Cubo = .{
            .min = .{ .x = -10, .y = 0, .z = -15 },
            .max = .{ .x = -9, .y = 8, .z = 5 },
            .material = ladrillo,
        } },
        // cubos
        .{ .Cubo = .{
            .min = .{ .x = 3, .y = 0, .z = -6 },
            .max = .{ .x = 5.5, .y = 2.5, .z = -3.5 },
            .material = madera,
        } },
        .{ .Cubo = .{
            .min = .{ .x = -5.5, .y = 0, .z = -4 },
            .max = .{ .x = -3, .y = 2.5, .z = -1.5 },
            .material = metal,
        } },
        .{ .Cubo = .{
            .min = .{ .x = -1, .y = 0, .z = -9 },
            .max = .{ .x = 1.5, .y = 2, .z = -6.5 },
            .material = cristal,
        } },
        .{ .Esfera = .{ //tipo espejo
            .centro = .{ .x = 0, .y = 2, .z = -2 },
            .radio = 2,
            .material = metal,
        } },
    };

    const luces = [_]rt.Light{ //no se ve negro
        .{
            .Color = rt.V3FromColor(htmlColor("#fff5e0")),
            .Position = .{ .x = 8, .y = 15, .z = 5 },
            .Intensity = 1.0,
        },
        .{
            .Color = rt.V3FromColor(htmlColor("#e0e8ff")),
            .Position = .{ .x = -10, .y = 12, .z = -5 },
            .Intensity = 0.6,
        },
    };

    //para controlar la camara
    const objetivo = rl.Vector3{ .x = 0, .y = 2, .z = -5 };
    var distancia_camara: f32 = 25;
    var angulo_x: f32 = 0.8;
    var angulo_y: f32 = 0.3;

    const velocidad_giro: f32 = std.math.pi / 2.0;
    const velocidad_zoom: f32 = 15;

    var camara: Camera = .init(.{ .x = 0, .y = 5, .z = distancia_camara }, objetivo);

    while (!rl.windowShouldClose()) {
        const dt = rl.getFrameTime();

        // controles de rotacion WASD
        if (rl.isKeyDown(.a)) angulo_x += velocidad_giro * dt;
        if (rl.isKeyDown(.d)) angulo_x -= velocidad_giro * dt;
        if (rl.isKeyDown(.w)) {
            angulo_y += velocidad_giro * dt;
            angulo_y = @min(std.math.pi / 3.0, angulo_y);
        }
        if (rl.isKeyDown(.s)) {
            angulo_y -= velocidad_giro * dt;
            angulo_y = @max(-std.math.pi / 8.0, angulo_y);
        }

        // zoom con scroll del mouse y tambien Q/E
        const scroll = rl.getMouseWheelMove();
        if (scroll != 0) {
            distancia_camara -= scroll * velocidad_zoom * 0.3;
        }
        if (rl.isKeyDown(.q)) distancia_camara -= velocidad_zoom * dt;
        if (rl.isKeyDown(.e)) distancia_camara += velocidad_zoom * dt;
        distancia_camara = @max(10, @min(50, distancia_camara));

        // actualizamos la camara alrededor del objetivo
        camara.Posicion.x = objetivo.x + @cos(angulo_x) * distancia_camara * @cos(angulo_y);
        camara.Posicion.y = objetivo.y + @sin(angulo_y) * distancia_camara;
        camara.Posicion.z = objetivo.z + @sin(angulo_x) * distancia_camara * @cos(angulo_y);
        camara.mirar_a(objetivo);

        framebuffer.limpiar();
        renderizar(&framebuffer, &objetos, &luces, camara, &texturas);
        try framebuffer.mostrar();
    }
}

fn renderizar( //concurrencia
    fb: *Framebuffer,
    objetos: []const Forma,
    luces: []const rt.Light,
    camara: Camera,
    texturas: []const tex.Textura,
) void {
    const pixeles = fb.obtener_pixeles();
    const w = fb.ancho;
    const h = fb.alto;
    const aspecto: f32 = @as(f32, @floatFromInt(w)) / @as(f32, @floatFromInt(h));
    const escala_fov = @tan(std.math.pi / 6.0);
    
    const alto_banda = h / num_hilos;
    var hilos: [num_hilos]std.Thread = undefined;
    //implementado con IA
    for (0..num_hilos) |i| { //se divide imagen  en 8 bandas, una por cada hilo
        const inicio = i * alto_banda;
        const fin = if (i == num_hilos - 1) h else (i + 1) * alto_banda;

        hilos[i] = std.Thread.spawn(.{}, renderizar_banda, .{ContextoRender{
            .pixeles = pixeles,
            .w = w,
            .h = h,
            .inicio_y = inicio,
            .fin_y = fin,
            .objetos = objetos,
            .luces = luces,
            .camara = camara,
            .texturas = texturas,
            .aspecto = aspecto,
            .escala_fov = escala_fov,
        }}) catch unreachable;
    }

    for (hilos) |hilo| hilo.join();
} //real que como son bandas diferentes no hay problema de sincronizacion

fn renderizar_banda(ctx: ContextoRender) void {
    //se generan los rayos por pixel
    const w_f: f32 = @floatFromInt(ctx.w);
    const h_f: f32 = @floatFromInt(ctx.h);

    for (ctx.inicio_y..ctx.fin_y) |py| {
        for (0..ctx.w) |px| {
            const x: f32 = @floatFromInt(px);
            const y: f32 = @floatFromInt(py);

            const ndc_x = (x * 2) / w_f - 1;
            const ndc_y = 1 - (y * 2) / h_f;

            const dir_local = (rl.Vector3{
                .x = ndc_x * ctx.aspecto * ctx.escala_fov, 
                .y = ndc_y * ctx.escala_fov,
                .z = 1,
            }).normalize(); //normaliza coordenadas pantalla a coordenadas de la camara

            const direccion = rl.Vector3{ //dirrecion del rayoe en espacio camara a espacio mundo, multiplicando por la matriz de orientacion de la camara
                .x = dir_local.x * ctx.camara.Derecha.x + dir_local.y * ctx.camara.Arriba.x + dir_local.z * ctx.camara.Adelante.x,
                .y = dir_local.x * ctx.camara.Derecha.y + dir_local.y * ctx.camara.Arriba.y + dir_local.z * ctx.camara.Adelante.y,
                .z = dir_local.x * ctx.camara.Derecha.z + dir_local.y * ctx.camara.Arriba.z + dir_local.z * ctx.camara.Adelante.z,
            };

            const color = lanzar_rayo(ctx.camara.Posicion, direccion, ctx.objetos, ctx.luces, ctx.texturas, profundidad_max);
            ctx.pixeles[py * ctx.w + px] = rt.V3ToColor(color);
        }
    }
}

fn lanzar_rayo( 
    origen: rl.Vector3,
    direccion: rl.Vector3,
    objetos: []const Forma,
    luces: []const rt.Light,
    texturas: []const tex.Textura,
    profundidad: usize,
) rl.Vector3 {
    //primero se busca el golpe mas cercano
    var golpe_cercano: ?rt.Intersect = null; 
    var z_buffer: f32 = std.math.floatMax(f32);

    //si no golpea nada entonces se devuelve el color del cielo
    for (objetos) |objeto| {
        const golpe = objeto.intersectar(origen, direccion) orelse continue;
        if (golpe.Distancia < z_buffer) {
            z_buffer = golpe.Distancia;
            golpe_cercano = golpe;
        }
    }

    //da color base  de la textura del material
    const golpe = golpe_cercano orelse return tex.muestrear_cielo(direccion);

    const mat = golpe.Material;
    var color: rl.Vector3 = .zero(); 

    var color_base = mat.Color;
    if (mat.indice_textura) |idx| {
        if (idx < texturas.len) {
            color_base = texturas[idx].muestrear(golpe.uv[0], golpe.uv[1]);
        }
    }

    // un poquito de luz ambiental para no dejarlo negro
    color = color.add(color_base.scale(0.05));

    //si material reflectivo  
    if (mat.Propiedades.Reflectividad > 0 and profundidad > 0) {
        const dir_reflejo = rl.Vector3.reflect(direccion, golpe.Normal);
        const nuevo_origen = golpe.Punto.add(dir_reflejo.scale(0.001)); // evitar colision con la misma figura
        const color_reflejo = lanzar_rayo(nuevo_origen, dir_reflejo, objetos, luces, texturas, profundidad - 1);
        color = color.add(color_reflejo.scale(mat.Propiedades.Reflectividad));
    }

    if (mat.Propiedades.Transparencia > 0 and profundidad > 0) { //refraccion
        if (refractar(direccion, golpe.Normal, mat.Indice_refraccion)) |dir_refraccion| { 
            const nuevo_origen = golpe.Punto.add(direccion.scale(0.001)); //ley de Snell
            const color_refraccion = lanzar_rayo(nuevo_origen, dir_refraccion, objetos, luces, texturas, profundidad - 1);
            color = color.add(color_refraccion.scale(mat.Propiedades.Transparencia));
        } else {  //si angulo muy grande 
            // reflexion total interna
            const dir_reflejo = rl.Vector3.reflect(direccion, golpe.Normal);
            const nuevo_origen = golpe.Punto.add(dir_reflejo.scale(0.001));
            const color_reflejo = lanzar_rayo(nuevo_origen, dir_reflejo, objetos, luces, texturas, profundidad - 1);
            color = color.add(color_reflejo.scale(mat.Propiedades.Transparencia));
        }
    }

    // Desde el punto a la camara
    const dir_vista = direccion.scale(-1);

    for (luces) |luz| { //iluminacion por cada luz, sombras 
        if (en_sombra(golpe.Punto, luz, objetos)) continue; 

        // dir punto a luz 
        const dir_luz = luz.Position.subtract(golpe.Punto).normalize();

        // que tan bien pega luz
        const intensidad_difusa = @max(0.0, golpe.Normal.dotProduct(dir_luz)) * luz.Intensity;
        const difuso = color_base.scale(intensidad_difusa);

        // dir a la que se refleja luz
        const dir_reflejo_luz = rl.Vector3.reflect(dir_luz.scale(-1), golpe.Normal);

        // lo liso del obejto
        const alineacion = @max(0.0, dir_reflejo_luz.dotProduct(dir_vista));
        const intensidad_especular = std.math.pow(f32, alineacion, mat.Especular) * luz.Intensity;
        const especular = luz.Color.scale(intensidad_especular);

        // mix
        color = color.add(difuso.scale(mat.Propiedades.Albedo));
        color = color.add(especular.scale(mat.Propiedades.Especular));
    }

    return color;
}

//funcion implementada con IA 
fn refractar(incidente: rl.Vector3, normal: rl.Vector3, indice_refraccion: f32) ?rl.Vector3 { //ley de snell
    var cosi = incidente.dotProduct(normal);

    var n1: f32 = 1;
    var n2 = indice_refraccion;
    var n = normal;
    //calcula  como se dobla rayo
    if (cosi > 0) {
        // el rayo sale del objeto
        std.mem.swap(f32, &n1, &n2);
        n = n.scale(-1);
    } else {
        cosi = -cosi;
    }

    const eta = n1 / n2;
    const k = 1 - eta * eta * (1 - cosi * cosi);

    if (k < 0) {
        return null;
    } else {
        return (incidente.scale(eta).add(n.scale(eta * cosi - @sqrt(k)))).normalize();
    }
}


//implementado con IA
fn en_sombra(origen: rl.Vector3, luz: rt.Light, objetos: []const Forma) bool { //lanza rayo del punto hacia luz 
    const vec_luz = luz.Position.subtract(origen);
    const dir_luz = vec_luz.normalize();
    const dist_luz = @sqrt(vec_luz.x * vec_luz.x + vec_luz.y * vec_luz.y + vec_luz.z * vec_luz.z);

    
    const origen_sombra = origen.add(dir_luz.scale(0.01));

    for (objetos) |objeto| {
        const golpe = objeto.intersectar(origen_sombra, dir_luz) orelse continue;
        //si algo  lo bloquea andtes de llegar a luz  hay sombre  
        if (golpe.Distancia < dist_luz and golpe.Material.Propiedades.Transparencia < 0.5) {
            return true;
        }
    }
    return false;
}

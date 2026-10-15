const std = @import("std");
const rl = @import("raylib");

//genera las texturas que usan los materiales. sin imagenes externas

pub const Textura = struct { //array 2D colores
    ancho: usize,
    alto: usize,
    pixeles: []rl.Color,

    pub fn muestrear(self: Textura, u_raw: f32, v_raw: f32) rl.Vector3 { //dado un punto en coordenadas [0,1], devuelve el color que le toca 
        var u = u_raw - @floor(u_raw);
        var v = v_raw - @floor(v_raw);
        if (u < 0) u += 1;
        if (v < 0) v += 1;

        //si se pasa de 1 entonces se repite la textura
        const w_f: f32 = @floatFromInt(self.ancho);
        const h_f: f32 = @floatFromInt(self.alto);
        const x: usize = @intFromFloat(@min(w_f - 1, u * w_f));
        const y: usize = @intFromFloat(@min(h_f - 1, v * h_f));

        const pixel = self.pixeles[y * self.ancho + x];
        const r: f32 = @floatFromInt(pixel.r);
        const g: f32 = @floatFromInt(pixel.g);
        const b: f32 = @floatFromInt(pixel.b);
        return .{ .x = r / 255.0, .y = g / 255.0, .z = b / 255.0 };
    }
};

pub fn muestrear_cielo(direction: rl.Vector3) rl.Vector3 { //si no golpea na el rayo entonces se le ponge color como de cielo
    const t = 0.5 * (direction.y + 1.0); 
    
    //degradado vertical con estos colores:
    const cielo = rl.Vector3{ .x = 0.35, .y = 0.55, .z = 0.92 };
    const horizonte = rl.Vector3{ .x = 0.88, .y = 0.88, .z = 0.90 };
    const suelo = rl.Vector3{ .x = 0.35, .y = 0.30, .z = 0.25 };

    //interpolar para mezclar los colores segun direcccion del rayo
    if (t > 0.5) {
        const s = (t - 0.5) * 2.0;
        return interpolar(horizonte, cielo, s); 
    } else {
        const s = t * 2.0;
        return interpolar(suelo, horizonte, s);
    }
}

//para degradados
fn interpolar(a: rl.Vector3, b: rl.Vector3, t: f32) rl.Vector3 { 
    return .{
        .x = a.x + (b.x - a.x) * t,
        .y = a.y + (b.y - a.y) * t,
        .z = a.z + (b.z - a.z) * t,
    };
}


//generadores de patrones


pub fn crear_tablero(alloc: std.mem.Allocator, tam: usize, celda: usize, c1: rl.Color, c2: rl.Color) !Textura { //aqui se va turnando colores de cuadros, piedra del piso
    const pixeles = try alloc.alloc(rl.Color, tam * tam);
    for (0..tam) |y| {
        for (0..tam) |x| {
            const cuadro = ((x / celda) + (y / celda)) % 2 == 0;
            pixeles[y * tam + x] = if (cuadro) c1 else c2;
        }
    }
    return .{ .ancho = tam, .alto = tam, .pixeles = pixeles };
}

//franjas horizontales, simular madera
pub fn crear_franjas(alloc: std.mem.Allocator, tam: usize, grosor: usize, c1: rl.Color, c2: rl.Color) !Textura {
    const pixeles = try alloc.alloc(rl.Color, tam * tam);
    for (0..tam) |y| {
        for (0..tam) |x| {
            const franja = (y / grosor) % 2 == 0;
            pixeles[y * tam + x] = if (franja) c1 else c2;
        }
    }
    return .{ .ancho = tam, .alto = tam, .pixeles = pixeles };
}

//para color igual en todo, simulando metal
pub fn crear_solido(alloc: std.mem.Allocator, tam: usize, color: rl.Color) !Textura {
    const pixeles = try alloc.alloc(rl.Color, tam * tam);
    @memset(pixeles, color);
    return .{ .ancho = tam, .alto = tam, .pixeles = pixeles };
}

pub fn crear_ladrillos(alloc: std.mem.Allocator, tam: usize, c_ladrillo: rl.Color, c_junta: rl.Color) !Textura { //patron de ladrillos con juntas
    const pixeles = try alloc.alloc(rl.Color, tam * tam);
    const alto_ladrillo: usize = tam / 4;
    const ancho_ladrillo: usize = tam / 4;
    const grosor_junta: usize = 1;

    //filas impares estan offseteadas medio ladrillo para que no se alineen
    for (0..tam) |y| {
        for (0..tam) |x| {
            const fila = y / alto_ladrillo;
            const x_offset = if (fila % 2 == 0) x else x + ancho_ladrillo / 2;
            const es_junta_h = (y % alto_ladrillo) < grosor_junta;
            const es_junta_v = (x_offset % ancho_ladrillo) < grosor_junta;

            pixeles[y * tam + x] = if (es_junta_h or es_junta_v) c_junta else c_ladrillo;
        }
    }
    return .{ .ancho = tam, .alto = tam, .pixeles = pixeles };
}

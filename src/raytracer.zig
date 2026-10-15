//se def las esctructuras que se van a usar en todo el project
const rl = @import("raylib");

pub fn V3FromColor(src: rl.Color) rl.Vector3 { //conversion entre colores RGBA y Vector3
    const x: f32 = @floatFromInt(src.r);
    const y: f32 = @floatFromInt(src.g);
    const z: f32 = @floatFromInt(src.b);
    return .{ .x = x / 255, .y = y / 255, .z = z / 255 };
}
//se usan vectores porque con flotantes mas facil la mate(* brillo, +colores y demas)

pub fn V3ToColor(color: rl.Vector3) rl.Color {
    const r: u8 = @intFromFloat(@max(0, @min(255, color.x * 255)));
    const g: u8 = @intFromFloat(@max(0, @min(255, color.y * 255)));
    const b: u8 = @intFromFloat(@max(0, @min(255, color.z * 255)));
    return .{ .r = r, .g = g, .b = b, .a = 0xff };
}

pub const Light = struct { //fuente de luz
    Color: rl.Vector3,
    Position: rl.Vector3,
    Intensity: f32,
};

pub const Material = struct { //como se comporta superficie de objeto
    Color: rl.Vector3,
    Especular: f32, //intensidad brillo
    Indice_refraccion: f32,
    Propiedades: struct { //valores controlan como se comporta la luz al chocar con el material
        Albedo: f32,
        Especular: f32,
        Reflectividad: f32,
        Transparencia: f32,
    },
    indice_textura: ?usize = null,  
};

pub const Intersect = struct { //cuando rayo golpea algo se guarda la info
    Material: Material,
    Distancia: f32,
    Normal: rl.Vector3,
    Punto: rl.Vector3,
    uv: [2]f32 = .{ 0, 0 },
};

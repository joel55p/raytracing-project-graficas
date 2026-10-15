const Esfera = @import("sphere.zig").Esfera;
const Cubo = @import("cube.zig").Cubo;
const Intersect = @import("raytracer.zig").Intersect;
const rl = @import("raylib");

//para las formas
const Tipo = enum {
    Esfera,
    Cubo,
};

//en si esfera o cubito
pub const Forma = union(Tipo) {
    Esfera: Esfera,
    Cubo: Cubo,

    pub fn intersectar(self: Forma, origen: rl.Vector3, direccion: rl.Vector3) ?Intersect { //segun forma llama metodo de cada forma
        return switch (self) {
            .Esfera => |e| e.intersectar(origen, direccion),
            .Cubo => |c| c.intersectar(origen, direccion),
        };
    }
};

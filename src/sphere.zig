const std = @import("std");
const rl = @import("raylib");
const Intersect = @import("raytracer.zig").Intersect;
const Material = @import("raytracer.zig").Material;

//calcula si un rayo pega en una esferay donde
pub const Esfera = struct {
    centro: rl.Vector3,
    radio: f32,
    material: Material,

    pub fn intersectar(self: Esfera, origen: rl.Vector3, direccion: rl.Vector3) ?Intersect {
        const centro_a_origen = origen.subtract(self.centro);

        // a, b y c como cuadratica  ax2 + bx + c = 0
        const b = 2 * direccion.dotProduct(centro_a_origen);
        const c = centro_a_origen.dotProduct(centro_a_origen) - self.radio * self.radio;

        const discriminante = b * b - 4.0 * c; //b2 - 4ac, a es = 1 porque direccion unitario

        if (discriminante > 0) { //si mayor que 0 entonces hay interseccion
            const t = (-b - @sqrt(discriminante)) / 2;
            if (t > 0) {
                const punto = origen.add(direccion.scale(t));
                const normal = punto.subtract(self.centro).normalize();

                // mapeo  de texturas
                const u = 0.5 + std.math.atan2(normal.z, normal.x) / (2.0 * std.math.pi); //normal de punto de golpe a coordenas uv[0,1]
                const v = 0.5 - std.math.asin(@max(-1.0, @min(1.0, normal.y))) / std.math.pi;

                return .{
                    .Material = self.material,
                    .Distancia = t,
                    .Normal = normal,
                    .Punto = punto,
                    .uv = .{ u, v },
                };
            }
        }
        return null;
    }
};

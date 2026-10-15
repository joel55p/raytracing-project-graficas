const std = @import("std");
const rl = @import("raylib");
const Material = @import("raytracer.zig").Material;
const Intersect = @import("raytracer.zig").Intersect;

//calucla si rayo pega un cubo alineado a ejes. 
pub const Cubo = struct {
    min: rl.Vector3,
    max: rl.Vector3,
    material: Material,

    
    pub fn intersectar(self: Cubo, origen: rl.Vector3, direccion: rl.Vector3) ?Intersect {
        const o = [3]f32{ origen.x, origen.y, origen.z };
        const d = [3]f32{ direccion.x, direccion.y, direccion.z };
        const bmin = [3]f32{ self.min.x, self.min.y, self.min.z };
        const bmax = [3]f32{ self.max.x, self.max.y, self.max.z };

        var tmin_val: f32 = -std.math.floatMax(f32);
        var tmax_val: f32 = std.math.floatMax(f32);

        var eje_entrada: usize = 0;
        var signo_entrada: f32 = -1;
        var eje_salida: usize = 0;
        var signo_salida: f32 = 1;

        // slab method  implementado en ejes: x, y, z
        for (0..3) |i| {
            if (@abs(d[i]) < 1e-8) {
                if (o[i] < bmin[i] or o[i] > bmax[i]) return null;
            } else {
                //t es distancia  a la que rayo entra y sale de cada par en ejes
                var t1 = (bmin[i] - o[i]) / d[i];
                var t2 = (bmax[i] - o[i]) / d[i];
                var signo: f32 = -1;

                if (t1 > t2) { //se intercambian para que t1 sea el de entrada y t2 el de salida
                    std.mem.swap(f32, &t1, &t2);
                    signo = 1;
                }

                if (t1 > tmin_val) { //si t1 es mayor que tmin_val entonces es el nuevo tmin_val
                    tmin_val = t1;
                    eje_entrada = i;
                    signo_entrada = signo;
                }
                if (t2 < tmax_val) { // si t2 es menor que tmax_val entonces es el nuevo tmax_val
                    tmax_val = t2;
                    eje_salida = i;
                    signo_salida = -signo;
                }

                if (tmin_val > tmax_val) return null; //no hay interseccion
            }
        }

        const desde_afuera = tmin_val > 0;
        const t = if (desde_afuera) tmin_val else tmax_val;
        if (t < 0) return null;

        const eje = if (desde_afuera) eje_entrada else eje_salida;
        const signo = if (desde_afuera) signo_entrada else signo_salida;

        const punto = origen.add(direccion.scale(t));

        var normal = rl.Vector3{ .x = 0, .y = 0, .z = 0 };
        switch (eje) {
            0 => normal.x = signo,
            1 => normal.y = signo,
            2 => normal.z = signo,
            else => {},
        }

        const uv = calcular_uv(self.min, self.max, punto, eje);

        return .{
            .Material = self.material,
            .Distancia = t,
            .Normal = normal,
            .Punto = punto,
            .uv = uv,
        };
    }

    //se muestra el punto donde pego  para coordenadas textura.
    fn calcular_uv(bmin: rl.Vector3, bmax: rl.Vector3, punto: rl.Vector3, eje: usize) [2]f32 {
        const min_a = [3]f32{ bmin.x, bmin.y, bmin.z };
        const max_a = [3]f32{ bmax.x, bmax.y, bmax.z };
        const p = [3]f32{ punto.x, punto.y, punto.z };

        // segun la cara usamos los otros dos ejes
        const eje_u: usize = if (eje == 0) 2 else 0;
        const eje_v: usize = if (eje == 2) 1 else if (eje == 0) 1 else 2;

        const tam_u = max_a[eje_u] - min_a[eje_u];
        const tam_v = max_a[eje_v] - min_a[eje_v];

        if (tam_u == 0 or tam_v == 0) return .{ 0, 0 };

        const u = (p[eje_u] - min_a[eje_u]) / tam_u;
        const v = (p[eje_v] - min_a[eje_v]) / tam_v;

        return .{ @max(0, @min(1, u)), @max(0, @min(1, v)) };
    }
};

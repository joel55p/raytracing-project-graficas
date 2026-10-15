const rl = @import("raylib");

//camara que gira al rededor de un punto central, para lanzar los rayos
pub const Camera = struct {
    //tiene 4 vectores
    Posicion: rl.Vector3, //donde esta camara
    Adelante: rl.Vector3, //donde ve
    Derecha: rl.Vector3, //x local
    Arriba: rl.Vector3, //y local

    pub fn init(posicion: rl.Vector3, objetivo: rl.Vector3) Camera {
        var cam = Camera{
            .Adelante = .zero(),
            .Posicion = posicion,
            .Derecha = .{ .x = 1, .y = 0, .z = 0 },
            .Arriba = .{ .x = 0, .y = 1, .z = 0 },
        };
        cam.mirar_a(objetivo);
        return cam;
    }

    //va a recalcular los vectores de orientacion 
    pub fn mirar_a(self: *Camera, objetivo: rl.Vector3) void { 
        self.Adelante = objetivo.subtract(self.Posicion).normalize();
        // producto cruz para sacar el vector a la derecha
        self.Derecha = rl.Vector3.crossProduct(self.Arriba, self.Adelante).normalize();
        self.Arriba = rl.Vector3.crossProduct(self.Adelante, self.Derecha).normalize();
    }
};

const rl = @import("raylib");

//buffer de pixeles, imagen en memoria donde se dibuja cada pixel
pub const Framebuffer = struct {
    ancho: usize,
    alto: usize,
    imagen: rl.Image,
    textura_gpu: ?rl.Texture = null,

    pub fn init(w: usize, h: usize) Framebuffer { //se crea imagen negra de w x h
        return .{
            .ancho = w,
            .alto = h,
            .imagen = rl.genImageColor(@intCast(w), @intCast(h), .black),
        };
    }

    //va a devolver puntero directo a array de colores
    pub fn obtener_pixeles(self: *Framebuffer) [*]rl.Color { 
        return @ptrCast(@alignCast(self.imagen.data)); //asi porque rl.Image.data es puntero a void, y se necesita puntero a Color
    }

    pub fn limpiar(self: *Framebuffer) void { //pone todo en black
        self.imagen.clearBackground(.black);
    }

    pub fn mostrar(self: *Framebuffer) !void { //sube imagen al GPU como textura y tambien  la dibuja en pantalla
        rl.beginDrawing();
        defer rl.endDrawing();

        if (self.textura_gpu) |t| rl.unloadTexture(t);

        const tex = try rl.loadTextureFromImage(self.imagen);
        rl.drawTexture(tex, 0, 0, .white);
        self.textura_gpu = tex;

        rl.drawFPS(10, 10);
    }
};

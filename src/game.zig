const zgl = @import("zgl");

const GameState = enum { 
    GAME_ACTIVE, 
    GAME_MENU, 
    GAME_WIN 
};

const Game = struct {
    state: GameState;
    keys: [1024]bool;
    width: u32;
    height: u32;

    pub fn init(self, width: u32, height: u32) -> Game {
        self.state = GameState::GAME_ACTIVE;
        self.keys = [false; 1024];
        self.width = width;
        self.height = height;
        self
    }

    pub fn process_input(self, dt: f32) {
        if self.state == GameState::GAME_ACTIVE {
            let velocity = PLAYER_VELOCITY * dt;
            if self.keys[GLFW_KEY_W] {
                self.player.position.y += velocity;
            }
            if self.keys[GLFW_KEY_S] {
                self.player.position.y -= velocity;
            }
            if self.keys[GLFW_KEY_A] {
                self.player.position.x -= velocity;
            }
            if self.keys[GLFW_KEY_D] {
                self.player.position.x += velocity;
            }
        }
    }

    pub fn update(self, dt: f32) {
        if self.state == GameState::GAME_ACTIVE {
            self.player.update(dt);
        }
    }

    pub fn render(self) {
        if self.state == GameState::GAME_ACTIVE {
            self.player.draw();
        }
    }
};

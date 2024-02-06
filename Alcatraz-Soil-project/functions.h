/* function prototypes */


void generate();

void LSP_CIA_Start();

int LSP_Get_Pos();

void LSP_Set_Pos(USHORT sequence);

int LSP_Get_Tick();

int LSP_Get_Beat();

void LSP_CIA_Stop();

//*************************

void Alienart_Line(UWORD line);

void Xorart_Line(UWORD line);

void C2P_Line(UBYTE line);

UBYTE XorShift(UBYTE value);

void fillcop1 (UBYTE line);

void fillcop2 (UBYTE line);

void fillcop3 (UBYTE line);

void fillcop4 (UBYTE line);

void fillcoptitle(USHORT frame, UBYTE strength, UBYTE move);

void copy_sprites();

void copy_invader1();

void copy_invader2();

void copy_ship1();

void copy_ship2();

void move_sprite_balls(UBYTE movesprites);

void move_sprite_ship(UBYTE movesprites);

void move_sprite_bubble(USHORT moveit);

void fadetoblack(UBYTE speed, USHORT* source, USHORT* destination);

void fadetoblack2(UBYTE speed, USHORT* source, USHORT* destination);

void fadetoblue(UBYTE speed, USHORT* source, USHORT* destination);

void fadefromblack(UBYTE speed, USHORT* source, USHORT* destination);

void fadefromblue(UBYTE speed, USHORT* source, USHORT* destination);

void fadefromblue2(UBYTE speed, USHORT* source, USHORT* destination);

void fadetowhite(UBYTE speed, USHORT* source, USHORT* destination);

void fadefromwhite(UBYTE speed, USHORT* source, USHORT* destination);

void fadefromwhite2(UBYTE speed, USHORT* source, USHORT* destination);

void putcolor_xor_bpl(USHORT counter, USHORT color, USHORT speed);

void putcolor_xor_spr(USHORT counter, USHORT color, USHORT speed);

void fadetoblack_xor(USHORT* destination);

void colorcycle_beam();

void interleaved (UBYTE line_s);

void blitbubble(UBYTE line, UBYTE* bitplane0, USHORT offset,  UBYTE number, UBYTE seed);

void scrollplane();

void blit_letters();

void blit_letters2();

void calc_stripe();

void calc_stripe2();

void calc_invader();

void blitfire(UWORD lineo,UBYTE minterm);

void copperfire();

void blitshifter(UBYTE* destination);

void setpixel(UBYTE x, USHORT y, UBYTE* destination); 

void clearpixel(UBYTE x, UBYTE y, UBYTE* destination); 

void scrollsines(UBYTE* destination,UBYTE step, UBYTE shift);

void copperendpic();
#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/graphics.h>
#include <graphics/gfxbase.h>
#include <graphics/view.h>
#include <exec/execbase.h>
#include <graphics/gfxmacros.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <hardware/intbits.h>
#include "support/gcc8_c_support.h"
#include "data.h"
#include "functions.h"

#define MUSIC

//#define debug

//#define fastforward 359
//#define fastforwardpos 23

// 23  - 2  :   ship fade in
// 71  - 5  :  	disco disco low
// 103 - 7  :  	disco disco high
// 135 - 9	:	start xor part
// 167 - 11 :	2nd xor part stripes
// 199 - 13	:	3rd xor part invader
// 231 - 15	:   bubbles
// 263 - 17	:   bubbles
// 295 - 19 : 	firefucker
// 359 - 23 : 	sines

#ifdef fastforward
volatile USHORT LSP_Beat 		= fastforward-1;
volatile USHORT LSP_Beat_old 	= fastforward-2;
#else
volatile USHORT LSP_Beat 		= 0; 
volatile USHORT LSP_Beat_old 	= 0;
#endif

UBYTE writerow=0;
volatile ULONG myvbl=0;
volatile ULONG myvblold=0;
UBYTE AK_Progress 		= 0;
ULONG LSP_Tick 			= 0; 
volatile BOOL LSP_Flag 	= FALSE;  	// set at every beat, has to be reset
BOOL LSP_Flag2			= FALSE;	// only for memclear fire fx
UBYTE logomove 			= 0;		// fade title down
UBYTE logoblitshift		= 0;		// blitshift fx on logo
volatile BOOL fadeflag 	= FALSE;
volatile UBYTE fadecnt 	= 0;
volatile UBYTE fadecnt2 = 0;
UBYTE bubblenumber 		= 1;	// number of bubbles to start with
UWORD letterrow 		= 0;	// for upscroller
UWORD letterrow2		 = 0;	// for textwriter
BOOL memclear=FALSE;

struct ExecBase *SysBase;
volatile struct Custom *hw;
struct DosLibrary *DOSBase;
struct GfxBase *GfxBase;
//backup
static UWORD SystemInts;
static UWORD SystemDMA;
static UWORD SystemADKCON;
static volatile APTR VBR=0;
static APTR SystemIrq;
struct View *ActiView;



UBYTE AK_Samples[185656+4] __attribute__((section (".MEMF_CHIP"))) = {};	

// aklang external samples
INCBIN(AK_External_Samples, "sound/Isamp.raw")

// title gfx
INCBIN(title, "gfx/soil_title.bpl")

UBYTE* bitplane0;
UBYTE* bitplane1;
UBYTE* bitplane2;
UBYTE* bitplane3;

UBYTE bitplane4[32*256*2] __attribute__((section (".MEMF_CHIP"))) = {};
UBYTE bitplane_empty[32*256] __attribute__((section (".MEMF_CHIP"))) = {};
UBYTE drawbyte[32*8] __attribute__((section (".MEMF_FAST"))) = {};
UBYTE bmptest[32*64] __attribute__((section (".MEMF_CHIP"))) = {};  // temporary memory for scroller


INCBIN_CHIP(Alcatraz_1bitmap, 	"gfx/Alcatraz_1bitmap.BPL")
INCBIN_CHIP(ball32x32_2b, 		"gfx/ball32x32_2b.bpl") 
INCBIN_CHIP(ball32x32_2b2, 		"gfx/ball32x32_2b2.bpl") 
INCBIN_CHIP(ball32x32_2b3, 		"gfx/ball32x32_2b3.bpl") 
INCBIN_CHIP(ball32x32_2b4, 		"gfx/ball32x32_2b4.bpl") 
INCBIN_CHIP(ball32x32_2b5, 		"gfx/ball32x32_2b5.bpl") 
INCBIN_CHIP(ball32x32_2b6, 		"gfx/ball32x32_2b6.bpl") 
INCBIN_CHIP(ball32x32_2b7, 		"gfx/ball32x32_2b7.bpl") 
INCBIN_CHIP(ball32x32_2b8, 		"gfx/ball32x32_2b8.bpl") 
INCBIN_CHIP(soilfont16, 		"gfx/soilfont16.bpl")	//960x16 pix 1bpl
INCBIN_CHIP(dithered, 			"gfx/dithered.bpl")		//256*64 pix 1bpl
INCBIN(ep,						"gfx/tinybot.bpl")		//256*256 pix 3bpl - first to fastmem, in main copy to chip

UWORD copper1[1024] __attribute__((section (".MEMF_CHIP"))) = {
};

UBYTE* endpic;

//************************************************************************************************


static APTR GetVBR(void) {
	APTR vbr = 0;
	UWORD getvbr[] = { 0x4e7a, 0x0801, 0x4e73 }; // MOVEC.L VBR,D0 RTE

	if (SysBase->AttnFlags & AFF_68010) 
		vbr = (APTR)Supervisor((void*)getvbr);

	return vbr;
}

void SetInterruptHandler(APTR interrupt) {
	*(volatile APTR*)(((UBYTE*)VBR)+0x6c) = interrupt;
}

APTR GetInterruptHandler() {
	return *(volatile APTR*)(((UBYTE*)VBR)+0x6c);
}


//vblank begins at vpos 312 hpos 1 and ends at vpos 25 hpos 1
//vsync begins at line 2 hpos 132 and ends at vpos 5 hpos 18 
void WaitVbl() {
	while (1) {
		volatile ULONG vpos=*(volatile ULONG*)0xDFF004;
		vpos&=0x1ff00;
		if (vpos!=(311<<8))
		//if (vpos>(256<<8))
			break;
	}
	while (1) {
		volatile ULONG vpos=*(volatile ULONG*)0xDFF004;
		vpos&=0x1ff00;
		if (vpos==(311<<8))
		//if (vpos<=(13<<8))
			break;
	}
}

void WaitVBLnew()
{
	while (1) {
if (myvbl!=myvblold) break;

}
}


void WaitLine(USHORT line) {
	while (1) {
		volatile ULONG vpos=*(volatile ULONG*)0xDFF004;
		if(((vpos >> 8) & 511) == line )
			break;
	}
}

inline void WaitBlt() {
	UWORD tst=*(volatile UWORD*)&hw->dmaconr; //for compatiblity a1000
	(void)tst;
	while (*(volatile UWORD*)&hw->dmaconr&(1<<14)) {} //blitter busy wait
}

void TakeSystem() {
	ActiView=GfxBase->ActiView; //store current view
	OwnBlitter();
	WaitBlit();	
	Disable();

	//Save current interrupts and DMA settings so we can restore them upon exit. 
	SystemADKCON=hw->adkconr;
	SystemInts=hw->intenar;
	SystemDMA=hw->dmaconr;
	hw->intena=0x7fff;//disable all interrupts
	hw->intreq=0x7fff;//Clear any interrupts that were pending
	
	WaitVbl();
	WaitVbl();
	hw->dmacon=0x7fff;//Clear all DMA channels

	//set all colors to black
	for(int a=0;a<32;a++) hw->color[a]=0x0000;

	LoadView(0);
	WaitTOF();
	WaitTOF();
	WaitVbl();
	WaitVbl();
	VBR=GetVBR();
	SystemIrq=GetInterruptHandler(); //store interrupt register
}

void FreeSystem() { 
	WaitVbl();
	WaitBlt();
	hw->intena=0x7fff;//disable all interrupts
	hw->intreq=0x7fff;//Clear any interrupts that were pending
	hw->dmacon=0x7fff;//Clear all DMA channels

	//restore interrupts
	SetInterruptHandler(SystemIrq);

	/*Restore system copper list(s). */
	hw->cop1lc=(ULONG)GfxBase->copinit;
	hw->cop2lc=(ULONG)GfxBase->LOFlist;
	hw->copjmp1=0x7fff; //start coppper

	/*Restore all interrupts and DMA settings. */
	hw->intena=SystemInts|0x8000;
	hw->dmacon=SystemDMA|0x8000;
	hw->adkcon=SystemADKCON|0x8000;

	LoadView(ActiView);
	WaitTOF();
	WaitTOF();
	WaitBlit();	
	DisownBlitter();
	Enable();
}

inline short MouseLeft(){return !((*(volatile UBYTE*)0xbfe001)&64);}	
inline short MouseRight(){return !((*(volatile UWORD*)0xdff016)&(1<<10));}

// interrupt progressbar
// *********************************************************************************************************************

static __attribute__((interrupt)) void interruptHandlerProgress() {

	UBYTE prog = AK_Progress+1;
	UWORD	entry = 3;	//word 3 is the first color

	for (UBYTE i=0; i<=prog && i<=32; ++i)
	{
		copperlist_precalc[entry] = 0xccc;
		copperlist_precalc[entry+68] = 0xccc;	//Next line
		entry += 2;	//next color
	}
	hw->intreq=(1<<INTB_VERTB); hw->intreq=(1<<INTB_VERTB); 
}

// interrupt main
// *********************************************************************************************************************

volatile UBYTE line_b 		= 0;
volatile UBYTE line_f 		= 0;
volatile UBYTE movesprites	= 0;
volatile USHORT line_w 		= 0;
volatile USHORT sprite_w	= -16;
USHORT wobble 				= 0;

static __attribute__((interrupt)) void interruptHandler() {

	myvbl++;
	// always first: bitplane + Sprite pointers!
	
	if (LSP_Beat < 103) // stripes plane slow
	hw->bplpt[4]=bitplane4+(((255-(line_b-32))&0b01111111)<<5)*2; 
	
	if (LSP_Beat >= 104 && LSP_Beat < 134) // stripes plane fast
	hw->bplpt[4]=bitplane4+(((-line_b+8)&0b00111111)<<5)*4; 
	
	if (LSP_Beat >= 166 && LSP_Beat <199) // stripe pattern for xor part 2
	hw->bplpt[4]=bitplane4+8192+2048+(((line_b>>1))<<5);
	
	if (LSP_Beat >= 199 && LSP_Beat <231) // invader for xor part 3
	hw->bplpt[4]=bitplane4;
	
	if (LSP_Beat >= 231) // bitplane for bubble part
	hw->bplpt[4]=bitplane4; 
	
	// EHB plane for ATZ logo (needs to come after the others)
	hw->bplpt[5]=bitplane_empty; 
		// show Alcatraz logo in EHB plane
	if (LSP_Beat>=47&&LSP_Beat<67) hw->bplcon0=(0<<10)/*dual pf*/|(1<<9)/*color*/|((6)<<12)/*num bitplanes*/;
	if (LSP_Beat== 67) hw->bplcon0=(0<<10)/*dual pf*/|(1<<9)/*color*/|((5)<<12)/*num bitplanes*/;



	if(LSP_Beat <= 132) // stripes on
	{	
		hw->sprpt[0]=sprite_stripe1;
		hw->sprpt[1]=sprite_stripe2;	
	}
	
	if (LSP_Beat > 131 && LSP_Beat<359) // all off
	{
		hw->sprpt[0]=sprite_stripe1;
		hw->sprpt[1]=sprite_stripe2;	
		hw->sprpt[2]=sprite_data_dummy;		
		hw->sprpt[3]=sprite_data_dummy;
		hw->sprpt[4]=sprite_data_dummy;
		hw->sprpt[5]=sprite_data_dummy;
		hw->sprpt[6]=sprite_data_dummy;	
		hw->sprpt[7]=sprite_data_dummy;
	}
			if (LSP_Beat >= 359 )  // stripes sine scene
	{
		hw->sprpt[0]=sprite_stripe1;
		hw->sprpt[1]=sprite_stripe2;
		hw->sprpt[2]=sprite_data_dummy; // laser
		hw->sprpt[3]=sprite_data_dummy; // invader
		hw->sprpt[4]=sprite_data_dummy; // invader
		hw->sprpt[5]=sprite_data_dummy; // invader			
		hw->sprpt[6]=sprite_data_dummy; // ship	
		hw->sprpt[7]=sprite_data_dummy; // ship
	}


	if (LSP_Beat >= 67 && LSP_Beat < 71) // invader off, laser on
	{
		hw->sprpt[2]=sprite_laser;	   	// laser
		colorcycle_beam();
		
		hw->bplpt[4]=bitplane_empty;			// switch bitplane
		hw->sprpt[3]=sprite_data_dummy; 	// invader
		hw->sprpt[4]=sprite_data_dummy; 	// invader
		hw->sprpt[5]=sprite_data_dummy; 	// invader
	}

	if(LSP_Beat==71) // original colors after laser colorcycle
	{
		spritecolorcalc[4] = 0x0111; 			
		spritecolorcalc[5] = 0x0444;
		spritecolorcalc[6] = 0x0666;
		spritecolorcalc[7] = 0x0888;
	}

	if (LSP_Beat >= 71)  //ship off , laser off , invaders off
	{
		hw->sprpt[2]=sprite_data_dummy; // laser
		hw->sprpt[3]=sprite_data_dummy; // invader
		hw->sprpt[4]=sprite_data_dummy; // invader
		hw->sprpt[5]=sprite_data_dummy; // invader			
		hw->sprpt[6]=sprite_data_dummy; // ship	
		hw->sprpt[7]=sprite_data_dummy; // ship
	}
	// move sprites
	if (LSP_Beat >= 27 && LSP_Beat <71)
	{
		if (LSP_Flag==FALSE && (LSP_Beat&0x01)==0) {copy_invader1();}
		if (LSP_Flag==FALSE && (LSP_Beat&0x01)==1) {copy_invader2();}
		if ((line_b&0x07)==0) {copy_ship1();}
		if ((line_b&0x07)==4) {copy_ship2();}

		if ((sprite_w&0x0200) == 0x0200 || LSP_Beat>=67) movesprites++;
		if (LSP_Beat <67) move_sprite_balls(movesprites);
		move_sprite_ship(movesprites);
		sprite_laser[0]=0x5000+(sprite_ship_left[0]&0x00ff)+4;
	}
	if (LSP_Beat >= 231 && LSP_Beat<295)  // stripes bubble scene + sprite bubble
	{
		if (LSP_Beat >= 279 )  move_sprite_bubble(line_w);
	}

	// get music tick and beat
	LSP_Tick = LSP_Get_Tick();
	#ifdef fastforward
	LSP_Beat=LSP_Get_Beat()+fastforward-1;
	#else
	LSP_Beat=LSP_Get_Beat();
	#endif
	//if(LSP_Tick%24==0) LSP_Beat++; //24 Ticks = 1 Beat
	if (LSP_Beat!=LSP_Beat_old){LSP_Beat_old=LSP_Beat; LSP_Flag=FALSE;LSP_Flag2=FALSE;}
	#ifdef debug
	KPrintF("LSP_Beat %ld",LSP_Beat_old);
	#endif

	// always set bitplane + sprite colors 
	for(int a=1;a<16;a++) hw->color[a]=bitplanecolorcalc[a];
	for(int a=0;a<16;a++) hw->color[a+16]=spritecolorcalc[a];


	// display title
	if (LSP_Beat<25) 
	{
		if (LSP_Beat>=14 && LSP_Beat < 21)
		{
			blitshifter(bitplane4);
			for (USHORT i =0 ;i<127;i++)
			{
				if ((logoblitshift&0x3f)<24  && logoblitshift<64)	
				setpixel(XorShift(logoblitshift+i)&0x1f,XorShift(i)&0x1f,bitplane4);
				else
				clearpixel(XorShift(logoblitshift+i-32)&0x1f,XorShift(i)&0x1f,bitplane4);
			}
			logoblitshift++;
		}
		fillcoptitle(LSP_Tick,128+(wobble>>1),logomove);
		wobble++;
		if (wobble>=255)wobble=255;
	}


	if (LSP_Beat>=25) // end of title
	{
		if(LSP_Beat<131) 
		{
			if (LSP_Beat<127) Alienart_Line(line_w);
			else for (USHORT i = 0; i<256; i++) drawbyte[i] = 0; // fill for transition to xor part
			C2P_Line(255-line_b);
		
			if (LSP_Beat<71) // flight of the commander
			{	
				fillcop3(255-line_b);	
			}
			else if (LSP_Beat<71+32)	// disco disco
			{
				hw->bplcon0=(0<<10)/*dual pf*/|(1<<9)/*color*/|((5)<<12)/*num bitplanes*/;	

				UBYTE change = (1+LSP_Beat>>1)&0x03;
				if (change==0)
				{ 
					if (LSP_Flag==FALSE) fadefromwhite(0,bitplanecolors4,bitplanecolorcalc); 
					fillcop3(255-line_b);
				}	
				if (change==1) 
				{ 
					if (LSP_Flag==FALSE) fadefromwhite(1,bitplanecolors1,bitplanecolorcalc); 
					fillcop2(255-line_b);
				}	
				if (change==2)
				{ 
					if (LSP_Flag==FALSE) fadefromwhite(1,bitplanecolors3,bitplanecolorcalc); 
					fillcop1(255-line_b);
				}		
				if (change==3) 
				{	
					if (LSP_Flag==FALSE) fadefromwhite(1,bitplanecolors2,bitplanecolorcalc); 
					fillcop2(255-line_b);
				}
			}
			else
			{
				hw->bplcon0=(0<<10)/*dual pf*/|(1<<9)/*color*/|((5)<<12)/*num bitplanes*/;	

				UBYTE change = (1+LSP_Beat>>1)&0x03;
				if (change==0)
				{ 
					if (LSP_Flag==FALSE) fadefromwhite(0,bitplanecolors4i,bitplanecolorcalc); 
					fillcop1(255-line_b);
				}	
				if (change==1) 
				{ 
					if (LSP_Flag==FALSE) fadefromwhite(1,bitplanecolors1i,bitplanecolorcalc); 
					fillcop2(255-line_b);
				}	
				if (change==2)
				{ 
					if (LSP_Flag==FALSE) fadefromwhite(1,bitplanecolors3i,bitplanecolorcalc);
					fillcop1(255-line_b);
				}		
				if (change==3) 
				{	
					if (LSP_Flag==FALSE) fadefromwhite(1,bitplanecolors2i,bitplanecolorcalc); 
					fillcop3(255-line_b);
				}

			}	
		}

		if (LSP_Beat>=131&&LSP_Beat<230) // xor art
		{
			if(LSP_Beat<133) fadetoblack_xor(spritecolorcalc); // fade out sprites and stripes
			

			Xorart_Line(line_w);
			C2P_Line(255-line_b);
			if (LSP_Beat < 167)	// xor part 1
			{
				hw->bplcon0=(0<<10)/*dual pf*/|(1<<9)/*color*/|((4)<<12)/*num bitplanes*/;	
				putcolor_xor_bpl(line_w+4,0x09fc,24);
				UBYTE change = (1+LSP_Beat>>2)&0x01;
				if (change==0)fillcop1(255-line_b);	
				if (change==1)fillcop2(255-line_b);	
				if ((line_w&0x01) == 0) fadetoblack_xor(bitplanecolorcalc);// fade slower
			}
			
			if (LSP_Beat >= 167 && LSP_Beat < 199 )	// xor part 2 stripes
			{
				hw->bplcon0=(0<<10)/*dual pf*/|(1<<9)/*color*/|((5)<<12)/*num bitplanes*/;	
				putcolor_xor_bpl(line_w+4,0x09cf,12);
				putcolor_xor_spr(line_w+4,0x09fc,24);
				fillcop4(254-line_b);
				if ((line_w&0x01) == 0) 
				{
				fadetoblack_xor(bitplanecolorcalc);	// fade slower
				fadetoblack_xor(spritecolorcalc);	// fade slower
				}
					
			}

			if (LSP_Beat < 231 && LSP_Beat >= 199)	// xor part 3 invader
			{
				if (LSP_Beat < 229) 
				{
					putcolor_xor_bpl(line_w+4,0x09cf,12); // with fade out for transition to bubbles
					putcolor_xor_spr(line_w+4,0x09fc,3);
				}
				hw->bplcon0=(0<<10)/*dual pf*/|(1<<9)/*color*/|((5)<<12)/*num bitplanes*/;	
				UBYTE change = (1+LSP_Beat>>2)&0x01;
				if (change==0) fillcop4(254-line_b);	
				if (change==1) fillcop3(255-line_b);	
				if ((line_w&0x01) == 0) 
				{
				fadetoblack_xor(bitplanecolorcalc);// fade slower
				fadetoblack_xor(spritecolorcalc);// fade slower
				}
			}
		}

		if (LSP_Beat >= 231 && LSP_Beat < 295) // bubble part
		{
			if (LSP_Beat == 231 || LSP_Beat ==232) // fade in
			{
				hw->bplcon0=(0<<10)/*dual pf*/|(1<<9)/*color*/|((5)<<12)/*num bitplanes*/;	
				if (LSP_Flag==FALSE)
				{ 
					fadefromblue2(1,bubblecolors2,spritecolorcalc); // not working good 
					fadefromblue(1,bubblecolors,bitplanecolorcalc); 
					for(int a=4;a<16;a++) spritecolorcalc[a]=bubblecolors2[a];
				}
			
			}
			if (LSP_Beat==292 && LSP_Flag==FALSE) fadetoblue(0,bubblecolors,bitplanecolorcalc);  // bitplanes
			if ((LSP_Beat==293||LSP_Beat==294) && LSP_Flag==FALSE) {fadetoblue(1,bubblecolors2,spritecolorcalc);}  // sprites
			if (LSP_Beat <294)
			{
				// scroll bitplane4 up
				scrollplane();
				if (LSP_Beat==239) bubblenumber=2;
				if (LSP_Beat==247) bubblenumber=3;
				if (LSP_Beat==247+8) bubblenumber=4;
			
				// create scroll copper
				interleaved(line_b);

				// blit   (speed,     	bitplane,  	offsetY*64, number, seed)
				blitbubble(line_b, 		bitplane0, 	64<<6,   	bubblenumber, 		5);
				blitbubble(line_f, 		bitplane1, 	(16+sine64x256[(24+32+line_w>>0)&0xff])<<6,   	bubblenumber, 		3);
	
				// clear line
				memset(bitplane0+(line_b<<6), 0 , 128);	// slow plane
				//memclr(bitplane0+(line_b<<6), 256);
				memset(bitplane1+(line_f<<6), 0 , 128); // fast plane
				//memclr(bitplane1+(line_f<<6), 256);
				
			
				// copy one line to the bottom
				//if ((line_b&0x1f)==0) blit_letters();
				//memcpy(bitplane4+16384-(64),bmptest+32*((line_b-12)&0x1f),32);
				 // for less space between, seems unstable
				if (writerow==28) {blit_letters();writerow=0;}
				writerow++;
				memcpy(bitplane4+16384-(17*64),bmptest+32*(writerow-1),32);
				
			}
			else hw->bplcon0=(0<<10)/*dual pf*/|(1<<9)/*color*/|((0)<<12)/*num bitplanes*/;	
		}
		
		if (LSP_Beat >= 295 && LSP_Beat < 359) // firefucker part
		{
			// bitplane pointers in copper		
			// blit fire
			if(memclear==FALSE) blitfire(LSP_Tick,61);
			// set copperlist
			copperfire();
			if (((LSP_Beat&0x1f)==7 || (LSP_Beat&0x1f)==8) && LSP_Flag==FALSE) 
			{
				fadefromwhite(1,firecolors1,bitplanecolorcalc); 
				fadefromwhite2(1,firecolors1_dark,spritecolorcalc); // new fade with new counter
			}

			if (((LSP_Beat&0x1f)==(7+16) || (LSP_Beat&0x1f)==(8+16)) && LSP_Flag==FALSE) 
			{
				fadefromwhite(1,firecolors2,bitplanecolorcalc); 
				fadefromwhite2(1,firecolors2_dark,spritecolorcalc); // new fade with new counter
			}
				// set 1st line
				for (UBYTE i=0; i<32; i++) 
				{
					bitplane0[i]=i^line_b>>1;
					bitplane1[i]=i^line_b>>2;
					bitplane2[i]=i^line_b>>3;
					bitplane3[i]=i^line_b>>4;
				}
			if (LSP_Beat==357 && LSP_Flag==FALSE) 
			{
				fadetoblack(0,firecolors2,bitplanecolorcalc); 
				fadetoblack2(0,firecolors2_dark,spritecolorcalc); 
			 } 
		}



		// sine part
		if (LSP_Beat>=359 && LSP_Beat<428)
		{
			// fade in
			if (LSP_Beat>=359 && LSP_Beat <= 361 && LSP_Flag==FALSE) 
			{
				fadefromblack(2,sinecolors3,bitplanecolorcalc); 
				fadefromwhite2(2,sinecolors3_bright,spritecolorcalc);  // Atz logo flash in
			
			}
			// blit 1st text
			if (LSP_Beat>=363 && LSP_Beat<371 && LSP_Flag == FALSE )
			{
				blit_letters2(text2);
			}
			// fade to next color + reset letterrow counter
			if (LSP_Beat>=375 && LSP_Beat <= 376 && LSP_Flag==FALSE) 
			{
				letterrow2=0;
				fadefromblack(1,sinecolors1,bitplanecolorcalc); 
				fadefromwhite2(1,sinecolors1_bright,spritecolorcalc);  
			}
			// fade to next color
			if (LSP_Beat>=391 && LSP_Beat <= 392 && LSP_Flag==FALSE) 
			{
				fadefromblack(1,sinecolors3,bitplanecolorcalc); 
				fadefromwhite2(1,sinecolors3_bright,spritecolorcalc);  
			}
			// blit 2nd text
			if (LSP_Beat>=395 && LSP_Beat<403 && LSP_Flag == FALSE )
			{
				blit_letters2(text3);
			}
			// fade to next color + reset letterrow counter
			if (LSP_Beat>=407 && LSP_Beat <= 408 && LSP_Flag==FALSE) 
			{
				letterrow2=0;
				fadefromblack(1,sinecolors1,bitplanecolorcalc); 
				fadefromwhite2(1,sinecolors1_bright,spritecolorcalc);  
			}
			// blit 3rd text
			if (LSP_Beat>=411 && LSP_Beat<419 && LSP_Flag == FALSE )
			{
				blit_letters2(text4);
			}
			// end of demo, fade out
			if (LSP_Beat>=425 && LSP_Beat<=427 && LSP_Flag==FALSE) 
			{
				fadetoblack(2,sinecolors1,bitplanecolorcalc); 
				fadetoblack2(2,sinecolors1_bright,spritecolorcalc); 
			}
		}

		if (LSP_Beat >= 429 && LSP_Beat<=431 && LSP_Flag==FALSE) 
		{
			hw->dmacon = DMAF_SPRITE;
			copperendpic();
			logoblitshift = 0;
			fadefromwhite(2,endpiccolors,bitplanecolorcalc); 
		}		
		if (LSP_Beat >=437 ) 
		{
			for (int i =0;i<8;i++){hw->color[8+i]=0;}
			blitshifter(bitplane4);
			for (USHORT i =0 ;i<127;i++)
			{
			
				setpixel(XorShift((logoblitshift>>1)+i)&0x1f,XorShift(i)&0x1f,bitplane4);
			}
			logoblitshift++;

		}		



		line_b++;
		line_w++;
		sprite_w++;
		line_f++;line_f++; // for bubbles
	}

	hw->intreq=(1<<INTB_VERTB); hw->intreq=(1<<INTB_VERTB); //reset vbl req. twice for a4000 bug.
}

// *********************************************************************************************************************
// *********************************************************************************************************************


#ifdef MUSIC

	// Amigaklang sample generator
	void generate() { 
		UBYTE* AK_Work = (UBYTE*)AllocMem(32768,MEMF_FAST);
		register volatile const void* _a0 ASM("a0") = AK_Samples;
		register volatile const void* _a1 ASM("a1") = AK_Work;
		register volatile const void* _a2 ASM("a2") = AK_External_Samples;
		register volatile const void* _a3 ASM("a3") = &AK_Progress;
		__asm volatile (
			"movem.l %%d1-%%d7/%%a4-%%a6,-(%%sp)\n"
			"jsr AK_Generate\n"
			"movem.l (%%sp)+,%%d1-%%d7/%%a4-%%a6"
		: "+rf"(_a0), "+rf"(_a1), "+rf"(_a2), "+rf"(_a3)
		:
		: "cc", "memory");
	}

	//LSP_MusicDriver_CIA_Start
	INCBIN(LSP_Music_Data, "sound/soil.lsmusic")
	void LSP_CIA_Start() { 
		register volatile const void* _a0 ASM("a0") = LSP_Music_Data;
		register volatile const void* _a1 ASM("a1") = AK_Samples-4;
		register volatile const void* _a2 ASM("a2") = 0;
		__asm volatile (
			"movem.l %%d1-%%d7/%%a1-%%a6,-(%%sp)\n"
			"jsr LSP_MusicDriver_CIA_Start\n"
			"movem.l (%%sp)+,%%d1-%%d7/%%a1-%%a6"
		: "+rf"(_a0), "+rf"(_a1), "+rf"(_a2)
		:
		: "cc", "memory");
	}
 
	int LSP_Get_Pos() { // gets the current pattern (position)
		register int _d0 asm("d0");
		__asm volatile (
			"jsr LSP_MusicGetPos\n"
		: "+rf"(_d0)
		:
		: "cc");
		return (int)_d0;
	}


	void LSP_Set_Pos(USHORT sequence) {  // sets the pattern (position)
		register int _d0 asm("d0") = sequence;
		__asm volatile (
			"jsr LSP_MusicSetPos\n"
		: "+rf"(_d0)
		:
		: "cc");
	}

	int LSP_Get_Tick() { 
		register int _d0 asm("d0");
		__asm volatile (
			"jsr LSP_MusicGetTick\n"
		: "+rf"(_d0)
		:
		: "cc");
		return (int)_d0;
	}

	int LSP_Get_Beat() { 
		register int _d0 asm("d0");
		__asm volatile (
			"jsr LSP_MusicGetBeat\n"
		: "+rf"(_d0)
		:
		: "cc");
		return (int)_d0;
	}

	void LSP_CIA_Stop() {

		__asm volatile (
			"movem.l %%d0-%%d1/%%a0-%%a1,-(%%sp)\n"
			"jsr LSP_MusicDriver_CIA_Stop\n"
			"movem.l (%%sp)+,%%d0-%%d1/%%a0-%%a1"
		:
		);
	}

#endif


void Alienart_Line(UWORD line) 
{

	for (USHORT x=0;x<256;x++)
	{
		USHORT x1=x;
		USHORT y1=line<<1;
		USHORT temp = y1;
		y1=y1+x1;
		x1=temp-x1;
		USHORT sierpinski = (x1 & y1)/11;
	if (LSP_Beat<71+24)
	{
		USHORT oddline = line&511;
		if(oddline<256) // is odd or even
			drawbyte[x] = sierpinski | (drawbyte[x]-8)>>1;
		else
			drawbyte[x] = sierpinski | (drawbyte[x]-12)>>1;
	}
	else
		drawbyte[x] = sierpinski | (drawbyte[x]-1);

	}
}

void Xorart_Line(UWORD line) 
{
	for (USHORT x=0;x<256;x++)
	{
		USHORT x1=x>>1;
		USHORT y1=line;
		USHORT sierpinski = ((x1 ^ y1)%19);
		if (LSP_Beat<159)
		{
			if ((line&255)>=144) drawbyte[x] = 0;
			else drawbyte[x] =  ((x1 ^ y1));
		}
		else 
		{
			drawbyte[x] = sierpinski;
		}

	}
}

// chunky 2 planar for 1 line
void C2P_Line(UBYTE line) // line is destination where to put it in the bitmap
{
	UBYTE drawbyte0,drawbyte1,drawbyte2,drawbyte3,cell;	
	for (UBYTE x=0;x<32;x++)
	{
		drawbyte0=0;drawbyte1=0;drawbyte2=0;drawbyte3=0;
		for (UBYTE z=0;z<8;z++)
		{ 
			cell = drawbyte[(x<<3)+(7-z)] ;
			// make sure cell isn´t 1: 
			cell&=0x0f; if (cell==0)cell++;

			if ((cell&1)>0) 	drawbyte0 |= 1 << z;
			if ((cell&2)>0) 	drawbyte1 |= 1 << z;
			if ((cell&4)>0) 	drawbyte2 |= 1 << z;
			if ((cell&8)>0) 	drawbyte3 |= 1 << z;	
		}
		bitplane0[x+(line<<5)] = drawbyte0; 
		bitplane1[x+(line<<5)] = drawbyte1; 
		bitplane2[x+(line<<5)] = drawbyte2; 
		bitplane3[x+(line<<5)] = drawbyte3; 
		// double the trouble for scrolling
		bitplane0[x+(line<<5)+8192] = drawbyte0; 
		bitplane1[x+(line<<5)+8192] = drawbyte1; 
		bitplane2[x+(line<<5)+8192] = drawbyte2; 
		bitplane3[x+(line<<5)+8192] = drawbyte3; 
	}
}

UBYTE XorShift(UBYTE value)
{
	value ^= (value<<7);
	value ^= (value>>5);
	value ^= (value<<3);
	return value;
}

__attribute__((always_inline)) inline USHORT* copSetPlanes(UBYTE bplPtrStart,USHORT* copListEnd,const UBYTE **planes,int numPlanes) {
	for (USHORT i=0;i<numPlanes;i++) {
		ULONG addr=(ULONG)planes[i];
		*copListEnd++=offsetof(struct Custom, bplpt[0]) + (i + bplPtrStart) * sizeof(APTR);
		*copListEnd++=(UWORD)(addr>>16);
		*copListEnd++=offsetof(struct Custom, bplpt[0]) + (i + bplPtrStart) * sizeof(APTR) + 2;
		*copListEnd++=(UWORD)addr;
	}
	return copListEnd;
}

__attribute__((always_inline)) inline USHORT* copSetOnePlane(USHORT* copListEnd,const UBYTE *plane, UBYTE nr) {
		ULONG addr=(ULONG)plane;
		*copListEnd++=offsetof(struct Custom, bplpt[nr]) ;
		*copListEnd++=(UWORD)(addr>>16);
		*copListEnd++=offsetof(struct Custom, bplpt[nr]) + 2;
		*copListEnd++=(UWORD)addr;

	return copListEnd;
}

__attribute__((always_inline)) inline USHORT* copWaitXY(USHORT *copListEnd,USHORT x,USHORT i) {
	*copListEnd++=(i<<8)|(x<<1)|1;	//bit 1 means wait. waits for vertical position x<<8, first raster stop position outside the left 
	*copListEnd++=0xfffe;
	return copListEnd;
}

__attribute__((always_inline)) inline USHORT* copWaitY(USHORT* copListEnd,USHORT i) {
	*copListEnd++=(i<<8)|4|1;	//bit 1 means wait. waits for vertical position x<<8, first raster stop position outside the left 
	*copListEnd++=0xfffe;
	return copListEnd;
}

__attribute__((always_inline)) inline USHORT* copSetColor(USHORT* copListCurrent,USHORT index,USHORT color) {
	*copListCurrent++=offsetof(struct Custom, color) + sizeof(UWORD) * index;
	*copListCurrent++=color;
	return copListCurrent;
}

void fillcop1 (UBYTE line) // split in middle 1 scrolling outwards
{
	USHORT* copPtr = copper1;
	const UBYTE* planes[4];
	planes[0]=(UBYTE*)bitplane0+4096+(line<<5);
	planes[1]=(UBYTE*)bitplane1+4096+(line<<5);
	planes[2]=(UBYTE*)bitplane2+4096+(line<<5);
	planes[3]=(UBYTE*)bitplane3+4096+(line<<5);
	copPtr = copWaitY(copPtr,0x28);
	copPtr = copSetPlanes(0, copPtr, planes, 4);
	*copPtr++=0x0108;*copPtr++=0xffc0; // bpl1mod negative
	*copPtr++=0x010a;*copPtr++=0xffc0; // bpl2mod negative

	planes[0]=(UBYTE*)bitplane0+(line<<5)+64;
	planes[1]=(UBYTE*)bitplane1+(line<<5)+64;
	planes[2]=(UBYTE*)bitplane2+(line<<5)+64;
	planes[3]=(UBYTE*)bitplane3+(line<<5)+64;
	copPtr = copWaitY(copPtr,0xa8);
	copPtr = copSetPlanes(0, copPtr, planes, 4);
	*copPtr++=0x0108;*copPtr++=0x0000; // bpl1mod
	*copPtr++=0x010a;*copPtr++=0x0000; // bpl2mod
	*copPtr++=0xffff;*copPtr++=0xfffe; // copper end
}

void fillcop2 (UBYTE line)  // split in middle 2 scrolling inwards
{
	USHORT* copPtr = copper1;
	const UBYTE* planes[4];
	planes[0]=(UBYTE*)bitplane0+(line<<5);
	planes[1]=(UBYTE*)bitplane1+(line<<5);
	planes[2]=(UBYTE*)bitplane2+(line<<5);
	planes[3]=(UBYTE*)bitplane3+(line<<5);
	copPtr = copWaitY(copPtr,0x28); // new
	copPtr = copSetPlanes(0, copPtr, planes, 4);
	*copPtr++=0x0108;*copPtr++=0x0000; // bpl1mod
	*copPtr++=0x010a;*copPtr++=0x0000; // bpl2mod

	planes[0]=(UBYTE*)bitplane0+4096+(line<<5);
	planes[1]=(UBYTE*)bitplane1+4096+(line<<5);
	planes[2]=(UBYTE*)bitplane2+4096+(line<<5);
	planes[3]=(UBYTE*)bitplane3+4096+(line<<5);
	copPtr = copWaitY(copPtr,0xa8);
	copPtr = copSetPlanes(0, copPtr, planes, 4);
	*copPtr++=0x0108;*copPtr++=0xffc0; // bpl1mod negative
	*copPtr++=0x010a;*copPtr++=0xffc0; // bpl2mod negative
	*copPtr++=0xffff;*copPtr++=0xfffe; // copper end
}

void fillcop3 (UBYTE line)  // bottom up
{
	USHORT* copPtr = copper1;
	const UBYTE* planes[4];
	planes[0]=(UBYTE*)bitplane0+(line<<5);
	planes[1]=(UBYTE*)bitplane1+(line<<5);
	planes[2]=(UBYTE*)bitplane2+(line<<5);
	planes[3]=(UBYTE*)bitplane3+(line<<5);
	copPtr = copWaitY(copPtr,0x2a); // 	// correct was to wait for 2a instead of 28 
	copPtr = copSetPlanes(0, copPtr, planes, 4);
	*copPtr++=0x0108;*copPtr++=0x0000; // bpl1mod
	*copPtr++=0x010a;*copPtr++=0x0000; // bpl2mod
	*copPtr++ =offsetof(struct Custom, bplcon1);*copPtr++=0; // no scroll



	*copPtr++=0xffff;*copPtr++=0xfffe; // copper end
}

void fillcop4 (UBYTE line)  // topdown
{
	USHORT* copPtr = copper1;
	const UBYTE* planes[4];
	planes[0]=(UBYTE*)bitplane0+8192+(line<<5);
	planes[1]=(UBYTE*)bitplane1+8192+(line<<5);
	planes[2]=(UBYTE*)bitplane2+8192+(line<<5);
	planes[3]=(UBYTE*)bitplane3+8192+(line<<5);
	copPtr = copWaitY(copPtr,0x28); // new

	copPtr = copSetPlanes(0, copPtr, planes, 4);
	*copPtr++=0x0108;*copPtr++=0xffc0; // bpl1mod negative
	*copPtr++=0x010a;*copPtr++=0xffc0; // bpl2mod negative
	*copPtr++ =offsetof(struct Custom, bplcon1);*copPtr++=0; // no scroll 

	*copPtr++=0xffff;*copPtr++=0xfffe; // copper end
}

void fillcoptitle(USHORT frame, UBYTE strength, UBYTE move)  // title
{	
	USHORT* copPtr = copper1;
	const UBYTE* planes[4];
	copPtr = copWaitY(copPtr,(move>>1)+0x28);
	planes[0]=(UBYTE*)bitplane0;
	planes[1]=(UBYTE*)bitplane1;
	planes[2]=(UBYTE*)bitplane2;
	planes[3]=(UBYTE*)bitplane3;
	planes[4]=(UBYTE*)bitplane4;
	*copPtr++ = offsetof(struct Custom, bplcon0);
	*copPtr++ = (0<<10)/*dual pf*/|(1<<9)/*color*/|((5)<<12)/*num bitplanes*/;
	*copPtr++=0x0108;*copPtr++=0x0000; // bpl1mod 
	*copPtr++=0x010a;*copPtr++=0x0000; // bpl2mod 
	copPtr = copSetPlanes(0, copPtr, planes, 5);
	USHORT distort = 0;
	// create copperlist for distortion
	for (USHORT i=64;i<256;i++)
	{   //                           0xf for more
		distort = (XorShift(i+frame)&0xff)+128;
		if (distort-strength>=128) distort = (distort-strength)>>4;
		else distort=8;
		distort |= distort<<4; // bits 0..3 and 4..7
		copPtr = copWaitY(copPtr,i);
		*copPtr++ =offsetof(struct Custom, bplcon1);*copPtr++=distort; 
	}

	*copPtr++=0xffdf;*copPtr++=0xfffe; // wait for low copper
	
	for (USHORT i=0;i<40;i++)
	{
		distort = (XorShift(i+frame)&0xff)+128;
		if (distort-strength>=128) distort = (distort-strength)>>4;
		else distort=8;
		distort |= distort<<4; // bits 0..3 and 4..7
		copPtr = copWaitY(copPtr,i);
	*copPtr++ =offsetof(struct Custom, bplcon1);*copPtr++=distort; 
	} 

	*copPtr++=0xffff;*copPtr++=0xfffe; // copper end
}

void copy_sprites()  // copy sprite data
{
	/*
	first word: 	
	Bits 15-8 contain the low 8 bits of VSTART
    Bits 7-0 contain the high 8 bits of HSTART
	
	second word:	         
	Bits 15-8       The low eight bits of VSTOP
    Bit 7           (Used in attachment)
    Bits 6-3        Unused (make zero)
    Bit 2           The VSTART high bit   <-this
    Bit 1           The VSTOP high bit    <-this
    Bit 0           The HSTART low bit
	*/

	for (USHORT i=0;i<36;i++)
	{	// copy small sprites
		sprite_ball2[i]=sprite_ball1[i];
		sprite_ball3[i]=sprite_ball1[i];
		sprite_ball4[i]=sprite_ball1[i];
	}
	// set first 2 words (heigth)
	sprite_ball1[0] = 0x8000;
	sprite_ball1[1] = 0x9000;
	sprite_ball2[0] = 0xa000;
	sprite_ball2[1] = 0xb000;
	sprite_ball3[0] = 0xc000;
	sprite_ball3[1] = 0xd000;
	sprite_ball4[0] = 0xe000;
	sprite_ball4[1] = 0xf000;
	// ship
	sprite_ship_left[0]= 0x0000; 
	sprite_ship_left[1]= 0x2006; 
	sprite_ship_right[0]= 0x0008;
	sprite_ship_right[1]= 0x2006;

	// create stripes:
	for (USHORT i=0;i<(64*8+4);i=i+2)
	{
		sprite_stripe1[i]=0xc000;
		sprite_stripe1[i+1]=0x0000;
		sprite_stripe2[i]=0x0003;
		sprite_stripe2[i+1]=0x0000;
	}
	sprite_stripe1[0] = 0x2950;
	sprite_stripe1[1] = 0x2902;
	sprite_stripe2[0] = 0x29c8;
	sprite_stripe2[1] = 0x2902;
	sprite_stripe1[64*8+2] = 0x0000;
	sprite_stripe1[64*8+3] = 0x0000;
	sprite_stripe2[64*8+2] = 0x0000;
	sprite_stripe2[64*8+3] = 0x0000;	

}

void copy_invader1()  // copy sprite data
{

	for (USHORT i=2;i<36;i++)
	{	// copy small sprites
		sprite_ball1[i]=sprite_inv1[i];
		sprite_ball2[i]=sprite_inv1[i];
		sprite_ball3[i]=sprite_inv1[i];
		sprite_ball4[i]=sprite_inv1[i];
	}
	LSP_Flag=TRUE;
}

void copy_invader2()  // copy sprite data
{

	for (USHORT i=2;i<36;i++)
	{	// copy small sprites
		sprite_ball1[i]=sprite_inv2[i];
		sprite_ball2[i]=sprite_inv2[i];
		sprite_ball3[i]=sprite_inv2[i];
		sprite_ball4[i]=sprite_inv2[i];
	}
	LSP_Flag=TRUE;
}

void copy_ship1()  // copy sprite data
{

	for (USHORT i=0;i<12;i++)
	{	
		sprite_ship_left[i+56]=sprite_ship_left1[i];
		sprite_ship_right[i+56]=sprite_ship_right1[i];

	}
	LSP_Flag2=TRUE;
}

void copy_ship2()  // copy sprite data
{

	for (USHORT i=0;i<12;i++)
	{	
		sprite_ship_left[i+56]=sprite_ship_left2[i];
		sprite_ship_right[i+56]=sprite_ship_right2[i];

	}
	LSP_Flag2=TRUE;
}

void move_sprite_balls(UBYTE movesprites)
{  

		sprite_ball1[0]=0x8000+movesprites;
		hw->sprpt[2]=sprite_ball1;
		sprite_ball2[0]=0xa000-movesprites;
		hw->sprpt[3]=sprite_ball2;
		sprite_ball3[0]=0xc000+movesprites+32;
		hw->sprpt[4]=sprite_ball3;
		sprite_ball4[0]=0xe000-movesprites+32;
		hw->sprpt[5]=sprite_ball4;

}
volatile USHORT shipY = 0;
void move_sprite_ship(UBYTE movesprites)
{  
		shipY++;
		UBYTE y = 256-shipY;
		y>>=2;
		if (shipY>=255) shipY=255;
		
		sprite_ship_left[0]=0x0000+0x68+sine64x256[2*movesprites&0xff]+(y<<8);
		sprite_ship_left[1]= 0x2006+(y<<8); 
		hw->sprpt[6]=sprite_ship_left;
		sprite_ship_right[0]=0x0008+0x68+sine64x256[2*movesprites&0xff]+(y<<8);
		sprite_ship_right[1]= 0x2006+(y<<8);
		hw->sprpt[7]=sprite_ship_right;
}

volatile USHORT bubbleY = 0;
void move_sprite_bubble(USHORT moveit)
{  
	
		bubbleY++;
		UWORD y = bubbleY;;
		y>>=1;
		if (bubbleY>=400) bubbleY=400;
		
		sprite_bubble_left[0]=0x0000+0x68+sine64x256[32-moveit&0xff]+(y<<8);
		sprite_bubble_left[1]= 0x2000+(y<<8); 
		hw->sprpt[2]=sprite_bubble_left;
		sprite_bubble_right[0]=0x0008+0x68+sine64x256[32-moveit&0xff]+(y<<8);
		sprite_bubble_right[1]= 0x2000+(y<<8);
		hw->sprpt[3]=sprite_bubble_right;

}

void fadetoblack(UBYTE speed, USHORT* source, USHORT* destination){ //speed 0..3
	for (UBYTE xz=0;xz<16;xz++) 
	{
		USHORT r_orig = (source[xz]&0x0f00)>>8;USHORT g_orig = (source[xz]&0x00f0)>>4;USHORT b_orig = (source[xz]&0x000f);
		USHORT r_new = r_orig-(fadecnt>>speed); if(r_new>16)r_new=0;
		USHORT g_new = g_orig-(fadecnt>>speed); if(g_new>16)g_new=0;
		USHORT b_new = b_orig-(fadecnt>>speed); if(b_new>16)b_new=0;
		USHORT newcol = (r_new<<8)|(g_new<<4)|(b_new);
		destination[xz] = newcol;
	}
	fadecnt++;
	if (fadecnt==(16<<speed)) {fadecnt=0;fadeflag=TRUE;LSP_Flag=TRUE;LSP_Flag2=TRUE;} // LSP_Flag hier zugefügt
}

void fadetoblack2(UBYTE speed, USHORT* source, USHORT* destination){ //speed 0..3
	for (UBYTE xz=0;xz<16;xz++) 
	{
		USHORT r_orig = (source[xz]&0x0f00)>>8;USHORT g_orig = (source[xz]&0x00f0)>>4;USHORT b_orig = (source[xz]&0x000f);
		USHORT r_new = r_orig-(fadecnt2>>speed); if(r_new>16)r_new=0;
		USHORT g_new = g_orig-(fadecnt2>>speed); if(g_new>16)g_new=0;
		USHORT b_new = b_orig-(fadecnt2>>speed); if(b_new>16)b_new=0;
		USHORT newcol = (r_new<<8)|(g_new<<4)|(b_new);
		destination[xz] = newcol;
	}
	fadecnt2++;
	if (fadecnt2==(16<<speed)) {fadecnt2=0;fadeflag=TRUE;LSP_Flag=TRUE;LSP_Flag2=TRUE;} // LSP_Flag hier zugefügt
}


void fadetoblue(UBYTE speed, USHORT* source, USHORT* destination){ //speed 0..3
	for (UBYTE xz=0;xz<16;xz++) 
	{
		USHORT r_orig = (source[xz]&0x0f00)>>8;USHORT g_orig = (source[xz]&0x00f0)>>4;USHORT b_orig = (source[xz]&0x000f);
		USHORT r_new = r_orig-(fadecnt>>speed); if(r_new>16||r_new<1)r_new=1;
		USHORT g_new = g_orig-(fadecnt>>speed); if(g_new>16||g_new<1)g_new=1;
		USHORT b_new = b_orig-(fadecnt>>speed); if(b_new>16||b_new<2)b_new=2;
		USHORT newcol = (r_new<<8)|(g_new<<4)|(b_new);
		destination[xz] = newcol;
	}
	fadecnt++;
	if (fadecnt==(16<<speed)) {fadecnt=0;fadeflag=TRUE;LSP_Flag=TRUE;} // LSP_Flag hier zugefügt
}

void fadefromblack(UBYTE speed, USHORT* source, USHORT* destination){ //speed 0..3
	for (UBYTE xz=0;xz<16;xz++) 
	{
		USHORT r_orig = (source[xz]&0x0f00)>>8;USHORT g_orig = (source[xz]&0x00f0)>>4;USHORT b_orig = (source[xz]&0x000f);
		USHORT r_new = r_orig-(16-(fadecnt>>speed)); if(r_new>16)r_new=0;
		USHORT g_new = g_orig-(16-(fadecnt>>speed)); if(g_new>16)g_new=0;
		USHORT b_new = b_orig-(16-(fadecnt>>speed)); if(b_new>16)b_new=0;
		USHORT newcol = (r_new<<8)|(g_new<<4)|(b_new);
		destination[xz] = newcol;
	}
	fadecnt++;
	if (fadecnt==(16<<speed)) {fadecnt=0;fadeflag=TRUE;LSP_Flag=TRUE;LSP_Flag2=TRUE;}
}

void fadefromblue(UBYTE speed, USHORT* source, USHORT* destination){ //speed 0..3
	for (UBYTE xz=0;xz<16;xz++) 
	{
		USHORT r_orig = (source[xz]&0x0f00)>>8;USHORT g_orig = (source[xz]&0x00f0)>>4;USHORT b_orig = (source[xz]&0x000f);
		USHORT r_new = r_orig-(16-(fadecnt>>speed)); if(r_new>16)r_new=1;
		USHORT g_new = g_orig-(16-(fadecnt>>speed)); if(g_new>16)g_new=1;
		USHORT b_new = b_orig-(16-(fadecnt>>speed)); if(b_new>16)b_new=2;
		USHORT newcol = (r_new<<8)|(g_new<<4)|(b_new);
		destination[xz] = newcol;
	}
	fadecnt++;
	if (fadecnt==(16<<speed)) {fadecnt=0;fadeflag=TRUE;LSP_Flag=TRUE;}
}

void fadefromblue2(UBYTE speed, USHORT* source, USHORT* destination){ //speed 0..3
	for (UBYTE xz=0;xz<16;xz++) 
	{
		USHORT r_orig = (source[xz]&0x0f00)>>8;USHORT g_orig = (source[xz]&0x00f0)>>4;USHORT b_orig = (source[xz]&0x000f);
		USHORT r_new = r_orig-(16-(fadecnt>>speed)); if(r_new>16)r_new=1;
		USHORT g_new = g_orig-(16-(fadecnt>>speed)); if(g_new>16)g_new=1;
		USHORT b_new = b_orig-(16-(fadecnt>>speed)); if(b_new>16)b_new=2;
		USHORT newcol = (r_new<<8)|(g_new<<4)|(b_new);
		destination[xz] = newcol;
	}
}


void fadetowhite(UBYTE speed, USHORT* source, USHORT* destination){ //speed 0..3
	for (UBYTE xz=0;xz<16;xz++) {
		USHORT r_orig = (source[xz]&0x0f00)>>8;USHORT g_orig = (source[xz]&0x00f0)>>4;USHORT b_orig = (source[xz]&0x000f);
		USHORT r_new = r_orig+(fadecnt>>speed); if(r_new>15)r_new=15;
		USHORT g_new = g_orig+(fadecnt>>speed); if(g_new>15)g_new=15;
		USHORT b_new = b_orig+(fadecnt>>speed); if(b_new>15)b_new=15;
		USHORT newcol = (r_new<<8)|(g_new<<4)|(b_new);
		destination[xz] = newcol;
	}
	fadecnt++;
	if (fadecnt==(16<<speed)) {fadecnt=0;fadeflag=TRUE;}
}

void fadefromwhite(UBYTE speed, USHORT* source, USHORT* destination){ //speed 0..3
	for (UBYTE xz=0;xz<16;xz++) {
		USHORT r_orig = (source[xz]&0x0f00)>>8;USHORT g_orig = (source[xz]&0x00f0)>>4;USHORT b_orig = (source[xz]&0x000f);
		USHORT r_new = r_orig+(16-(fadecnt>>speed)); if(r_new>15)r_new=15;
		USHORT g_new = g_orig+(16-(fadecnt>>speed)); if(g_new>15)g_new=15;
		USHORT b_new = b_orig+(16-(fadecnt>>speed)); if(b_new>15)b_new=15;
		USHORT newcol = (r_new<<8)|(g_new<<4)|(b_new);
		destination[xz] = newcol;
	}
	fadecnt++;
	if (fadecnt==(16<<speed)) {fadecnt=0;fadeflag=TRUE;LSP_Flag=TRUE;LSP_Flag2=TRUE;} // LSP_Flag hier zugefügt
}

void fadefromwhite2(UBYTE speed, USHORT* source, USHORT* destination){ //speed 0..3
	for (UBYTE xz=0;xz<16;xz++) {
		USHORT r_orig = (source[xz]&0x0f00)>>8;USHORT g_orig = (source[xz]&0x00f0)>>4;USHORT b_orig = (source[xz]&0x000f);
		USHORT r_new = r_orig+(16-(fadecnt2>>speed)); if(r_new>15)r_new=15;
		USHORT g_new = g_orig+(16-(fadecnt2>>speed)); if(g_new>15)g_new=15;
		USHORT b_new = b_orig+(16-(fadecnt2>>speed)); if(b_new>15)b_new=15;
		USHORT newcol = (r_new<<8)|(g_new<<4)|(b_new);
		destination[xz] = newcol;
	}
	fadecnt2++;
	if (fadecnt2==(16<<speed)) {fadecnt2=0;fadeflag=TRUE;LSP_Flag=TRUE;LSP_Flag2=TRUE;} // LSP_Flag hier zugefügt
}

volatile UBYTE colorpos_xor_bpl = 1;
void putcolor_xor_bpl(USHORT counter, USHORT color, USHORT speed) // put color in colorbuffer
{
	if ((counter%speed)==0) colorpos_xor_bpl++;
	if (colorpos_xor_bpl>15) colorpos_xor_bpl=1; // don´t touch 1st color
	bitplanecolorcalc[colorpos_xor_bpl]= color; 
}

volatile UBYTE colorpos_xor_spr = 0;
void putcolor_xor_spr(USHORT counter, USHORT color, USHORT speed) // put color in colorbuffer
{
	if ((counter%speed)==0) colorpos_xor_spr++;
	if (colorpos_xor_spr>15) colorpos_xor_spr=0; 
	spritecolorcalc[colorpos_xor_spr]= color; 
}

void fadetoblack_xor(USHORT* destination){ // fade one step to black for xor fx
	for (UBYTE xz=0;xz<16;xz++) {
	USHORT r_orig = (destination[xz]&0x0f00)>>8;USHORT g_orig = (destination[xz]&0x00f0)>>4;USHORT b_orig = (destination[xz]&0x000f);
	USHORT r_new = r_orig-1; if(r_new<1)r_new=1;
	USHORT g_new = g_orig-1; if(g_new<1)g_new=1;
	USHORT b_new = b_orig-1; if(b_new<2)b_new=2;
	USHORT newcol = (r_new<<8)|(g_new<<4)|(b_new);
	destination[xz] = newcol&0x0fff;
	}
}

void fadetoblack_xor2(USHORT* destination){ // fade one step to black for xor fx
	for (UBYTE xz=0;xz<16;xz++) {
	USHORT r_orig = (destination[xz]&0x0f00)>>8;USHORT g_orig = (destination[xz]&0x00f0)>>4;USHORT b_orig = (destination[xz]&0x000f);
	USHORT r_new = r_orig-1; if(r_new<1)r_new=1;
	USHORT g_new = g_orig-1; if(g_new<2)g_new=1;
	USHORT b_new = b_orig-1; if(b_new<1)b_new=2;
	USHORT newcol = (r_new<<8)|(g_new<<4)|(b_new);
	destination[xz] = newcol;
	}
}

BOOL colorcyclebeamflag = FALSE;
void colorcycle_beam()
{
	if (colorcyclebeamflag == FALSE)
	{	// colors beam
		spritecolorcalc[4] = 0x0700; 			
		spritecolorcalc[5] = 0x0f00;
		spritecolorcalc[6] = 0x0ff0;
		spritecolorcalc[7] = 0x0f80;
		colorcyclebeamflag = TRUE;	
	}
		if((LSP_Tick&1)==1) // slow down
		{
			UWORD temp = spritecolorcalc[4];
			spritecolorcalc[4]=spritecolorcalc[5];
			spritecolorcalc[5]=spritecolorcalc[6];
			spritecolorcalc[6]=spritecolorcalc[7];
			spritecolorcalc[7]=temp;
		}
}

void interleaved (UBYTE line_s)  
{
	UBYTE line_f=line_s<<1;
	USHORT* copPtr = copper1;
	const UBYTE* planes[4];

	*copPtr++=0x0108;*copPtr++=0x0020;//0xffa0; // bpl1mod interleaved
	*copPtr++=0x010a;*copPtr++=0x0020;//0xffa0; // bpl2mod interleaved

	copPtr=copWaitY(copPtr,0x28);
	*copPtr++=0x0180;*copPtr++=0x0112; // reset color

		planes[0]=(UBYTE*)bitplane0  	+(line_s<<6);
		planes[1]=(UBYTE*)bitplane0+32	+(line_s<<6);
		planes[2]=(UBYTE*)bitplane1  	+(line_f<<6);
		planes[3]=(UBYTE*)bitplane1+32	+(line_f<<6);
		copPtr = copSetPlanes(0, copPtr, planes, 4);

		if(0x28-line_f <= 0x28-line_s)	
		{
			if (((0x28-line_s)>=0) && ((0x28-line_f)>=0) ) {*copPtr++=0xffdf;*copPtr++=0xfffe;} // copper break
			copPtr=copWaitY(copPtr,0x28-line_f);
			////*copPtr++=0x0186;*copPtr++=0x0010; // color green fast
			copPtr = copSetOnePlane(copPtr,bitplane1	+64, 2);
			copPtr = copSetOnePlane(copPtr,bitplane1+32	+64, 3);

			if (((0x28-line_s)>=0) && !((0x28-line_f)>=0) ) {*copPtr++=0xffdf;*copPtr++=0xfffe;} // copper break
			copPtr=copWaitY(copPtr,0x28-line_s);
			//*copPtr++=0x0180;*copPtr++=0x0100; // color red slow
			copPtr = copSetOnePlane(copPtr,bitplane0	+64, 0);
			copPtr = copSetOnePlane(copPtr,bitplane0+32	+64, 1);
		}
		
		if(0x28-line_f > 0x28-line_s)	
		{
			copPtr=copWaitY(copPtr,0x28-line_s);
			//*copPtr++=0x0180;*copPtr++=0x0100; // color red slow
			copPtr = copSetOnePlane(copPtr,bitplane0	+64, 0);
			copPtr = copSetOnePlane(copPtr,bitplane0+32	+64, 1);

			if (((0x28-line_f)>=0) ) {*copPtr++=0xffdf;*copPtr++=0xfffe;} // copper break
			copPtr=copWaitY(copPtr,0x28-line_f);
			////*copPtr++=0x0186;*copPtr++=0x0010; // color green fast
			copPtr = copSetOnePlane(copPtr,bitplane1	+64, 2);
			copPtr = copSetOnePlane(copPtr,bitplane1+32	+64, 3);
		}
		*copPtr++=0xffff;*copPtr++=0xfffe; // copper end
}

void blitbubble(UBYTE line, UBYTE* bitplane0, USHORT offset,  UBYTE number, UBYTE seed)
{
	UBYTE BLT_A =0b11110000;
	UBYTE BLT_B =0b11001100;
	UBYTE BLT_C =0b10101010;
	UBYTE minterm=  (BLT_A & BLT_B)|(BLT_C & ~BLT_B); 

	UBYTE bitplanes = 	2;
	UBYTE screenwidth = 256 /(8); // in Bytes
	UBYTE blitwidth= 	48 /(16); // in Words (32 pix + 16 empty pix)
	UBYTE blitheight = 	32 * bitplanes; // in pixels 

	for(UBYTE i=0;i<number;i++)
	{
		WaitBlit();	
		UBYTE shifter = (line&15);
		if (shifter>10) shifter=10;
		hw->bltcon0 = minterm | SRCA | SRCB | SRCC | DEST | (shifter << ASHIFTSHIFT);
		//hw->bltcon1 = 0;
		hw->bltcon1 = (shifter) << BSHIFTSHIFT;// für Source B
		// bltadat blitter source A data register (for blitting a fixed value)
		// hw->bltadat = 0;
		// bltapt pointer to source A data
		UBYTE* src =0;
		if ((line&7)==7) src = (UBYTE*) ball32x32_2b;
		if ((line&7)==6) src = (UBYTE*) ball32x32_2b2;
		if ((line&7)==5) src = (UBYTE*) ball32x32_2b3;
		if ((line&7)==4) src = (UBYTE*) ball32x32_2b4;
		if ((line&7)==3) src = (UBYTE*) ball32x32_2b5;
		if ((line&7)==2) src = (UBYTE*) ball32x32_2b6;
		if ((line&7)==1) src = (UBYTE*) ball32x32_2b7;
		if ((line&7)==0) src = (UBYTE*) ball32x32_2b8;
		hw->bltapt = src;
		hw->bltamod = 48/8;
		// bltapt pointer to source B data (mask)
		hw->bltbpt = src + (48 / 8);// * 1;
		hw->bltbmod = 48 / 8;
		UBYTE fline=line&0xfc;
		// blitter pointer to source C and destination D
		USHORT xpos = (((XorShift(fline+(i*seed)+(fline>>1))>>3)*7)>>3);
		USHORT ypos = (bitplanes*screenwidth*(XorShift(fline+i)>>1))+(fline<<6)+offset;  //64 slow. 128 fast
		// get rest of bob for 2nd blit if its out of bounds
		if (ypos >16384) ypos-=(16384);
		USHORT rest=0;
		if (ypos >(224*64)) rest =  ypos-(224*64);
		rest>>=6;
		hw->bltdpt = hw->bltcpt = bitplane0+ ypos + xpos;
		// bltter modulo for source C and destination D  (has to be calculated from blitsize)
		// modulo = screenwidth(bytes) - blitwidth(words)*2 
		hw->bltdmod = hw->bltcmod = (screenwidth-blitwidth*2);
		// blitter first word mask for source A
		hw->bltafwm = hw->bltalwm = 0xffff;
		// blitter start and size (6..15:height, 0..5:width )
		hw->bltsize = (blitheight << HSIZEBITS) | blitwidth;

		if(rest>0) // blit the rest cut of the bob to the top
		{
			WaitBlit();
			hw->bltdpt = hw->bltcpt = bitplane0+ xpos;
			hw->bltapt = src + ((32-rest)*6*4);
			hw->bltbpt = src + ((32-rest)*6*4) + (48 / 8);// * 1;
			hw->bltsize = (rest*2 << HSIZEBITS) | blitwidth;
		}
	}
}

void scrollplane()
{
	WaitBlit();
	hw->bltcon0 = A_TO_D | SRCA | SRCC | DEST;
	hw->bltcon1 = 0;
	// bltapt pointer to source A data
	UBYTE* src2 = (UBYTE*) bitplane4;
	hw->bltapt = src2;
	hw->bltamod = 0;
	// bltapt pointer to source B data (mask)
	hw->bltbpt = src2 ;
	hw->bltbmod = 0;
	// blitter pointer to source C and destinantion D
	hw->bltdpt = bitplane4-32;
	// bltter modulo for source C and destination D  (has to be calculated from blitsize)
	// modulo = screenwidth(bytes) - blitwidth(words)*2 
	hw->bltdmod = hw->bltcmod = 0;
	// blitter first word mask for source A
	hw->bltafwm = hw->bltalwm = 0xffff;
	// blitter start and size (6..15:height, 0..5:width )
	hw->bltsize = (512 << HSIZEBITS) | 16;
}

void blit_letters()
{
	UBYTE screenwidth = 256 /(8); // in Bytes
	UBYTE blitwidth= 	16 /(16); // in Words (16 pixel)
	if (letterrow<textcnt)
	{
	for(UBYTE i=1;i<15;i++)
	{
		WaitBlit();
		hw->bltcon0 = A_TO_D | SRCA | SRCC | DEST ;//| ((2) << ASHIFTSHIFT);
		hw->bltcon1 = 0;
		// bltapt pointer to source A data
		UBYTE* src2 = (UBYTE*) soilfont16+text[letterrow*14+i-1]*2-64; // offset for letter here! 32=0
		hw->bltapt = hw->bltbpt = src2;
		hw->bltamod =hw->bltbmod = 40+40+38;
		// blitter pointer to source C and destinantion D
		hw->bltdpt = bmptest+i*2;
		// bltter modulo for source C and destination D  (has to be calculated from blitsize)
		// modulo = screenwidth(bytes) - blitwidth(words)*2 
		hw->bltdmod = hw->bltcmod = (screenwidth-blitwidth*2);
		// blitter first word mask for source A
		hw->bltafwm = hw->bltalwm = 0xffff;
		// blitter start and size (6..15:height, 0..5:width )
		hw->bltsize = (16 << HSIZEBITS) | 1;
	}
	if (text[letterrow*14]=='x') // shift text 8 pixels, if unaligned (x marks the spot)
	{ 
		WaitBlit();
		hw->bltcon0 = A_TO_D | SRCA | SRCC | DEST | ((8) << ASHIFTSHIFT);
		hw->bltcon1 = 0;
		hw->bltapt = hw->bltbpt = bmptest;
		hw->bltamod =hw->bltbmod = 0;
		hw->bltdpt = bmptest;
		hw->bltdmod = hw->bltcmod = 0;
		hw->bltafwm = hw->bltalwm = 0xffff;
		hw->bltsize = (16 << HSIZEBITS) | 16;
	}
	letterrow+=1;	
	}
}

void blit_letters2(UBYTE* text)
{
	if (letterrow2<textcnt2)
	{
	UBYTE screenwidth = 256 /(8); // in Bytes
	UBYTE blitwidth= 	16 /(16); // in Words (16 pixel)
	for(UBYTE i=1;i<15;i++)
	{
		WaitBlit();
		hw->bltcon0 = A_TO_D | SRCA | SRCC | DEST ;//| ((2) << ASHIFTSHIFT);
		hw->bltcon1 = 0;
		// bltapt pointer to source A data
		UBYTE* src2 = (UBYTE*) soilfont16+text[letterrow2*14+i-1]*2-64; // offset for letter here! 32=0
		hw->bltapt = hw->bltbpt = src2;
		hw->bltamod =hw->bltbmod = 40+40+38;
		// blitter pointer to source C and destinantion D
		hw->bltdpt = bitplane4+i*2+letterrow2*20*32+72*32;
		// bltter modulo for source C and destination D  (has to be calculated from blitsize)
		// modulo = screenwidth(bytes) - blitwidth(words)*2 
		hw->bltdmod = hw->bltcmod = (screenwidth-blitwidth*2);
		// blitter first word mask for source A
		hw->bltafwm = hw->bltalwm = 0xffff;
		// blitter start and size (6..15:height, 0..5:width )
		hw->bltsize = (16 << HSIZEBITS) | 1;
	}
	if (text[letterrow2*14]=='x') // shift text 8 pixels, if unaligned (x marks the spot)
	{ 
		WaitBlit();
		hw->bltcon0 = A_TO_D | SRCA | SRCC | DEST | ((8) << ASHIFTSHIFT);
		hw->bltcon1 = 0;
		hw->bltapt = hw->bltbpt = bitplane4+letterrow2*20*32+72*32;
		hw->bltamod =hw->bltbmod = 0;
		hw->bltdpt = bitplane4+letterrow2*20*32+72*32;
		hw->bltdmod = hw->bltcmod = 0;
		hw->bltafwm = hw->bltalwm = 0xffff;
		hw->bltsize = (16 << HSIZEBITS) | 16;
	}
	letterrow2+=1;
	LSP_Flag=TRUE;
	}
}



void calc_stripe()
{
	int offs = 24;
	for (int y=0;y<4;y++)
	{
		for (int x=0;x<256;x++)
		{
			if((x&1)==0) setpixel(x,offs+16+y+(x>>1),bitplane4+8192);
		}
	}

	for (int x=0;x<256;x++)
	{
		if((x&1)==1) setpixel(x,offs+23+(x>>1),bitplane4+8192);
	}
	
	for (int y=0;y<48;y++)
	{
		for (int x=0;x<256;x++)
		{
			setpixel(x,offs+24+y+(x>>1),bitplane4+8192);
		}
	}

	for (int x=0;x<256;x++)
	{
		if((x&1)==0) setpixel(x,offs+72+(x>>1),bitplane4+8192);
	}

	for (int y=0;y<4;y++)
	{
		for (int x=0;x<256;x++)
		{
			if((x&1)==0) setpixel(x,offs+76+y+(x>>1),bitplane4+8192);
		}
	}

}


void calc_stripe2() // precalculate bitplane 4 pattern	for xor part
{	
	for (int i=0; i<256; i++) 
	{
		for (int j=0; j<32; j++)
		{
			if(i >= (16+24) && i<=(80+24) || i >= (144+24) && i <= (208+24)) 
			{
				bitplane4[i*32+j*128+j]=255;
				bitplane4[i*32+j*128+j+8192]=255;
			}
		} 
	} 
}

void calc_invader() // precalculate invader on bitplane4 + bitplane_empty
{
	memclr(bitplane4,256*32);
	for (int i=0;i<128;i++) 
	{
		UBYTE innercount = 8;
		for (int j =0;j<32;j++)
		{
			innercount--;
			if (((invader_data1[((i>>4)*4)+(j>>3)])&(1<<innercount))>0) bitplane4[64*32+(i<<5)+j] = 255;
			if (((invader_data2[((i>>4)*4)+(j>>3)])&(1<<innercount))>0) bitplane_empty[64*32+(i<<5)+j] = 255;
			if (innercount<=0) innercount=8;

		}
 	} 
}

void calc_invader2() // precalculate invader on bitplane_empty for fire fx
{
	memclr(bitplane_empty,256*32);
	for (int i=0;i<128;i++) 
	{
		UBYTE innercount = 8;
		for (int j =0;j<32;j++)
		{
			innercount--;
			if (((invader_data1[((i>>4)*4)+(j>>3)])&(1<<innercount))>0) bitplane_empty[(i<<5)+j] = 255;
			if (((invader_data2[((i>>4)*4)+(j>>3)])&(1<<innercount))>0) bitplane_empty[255*32-(i<<5)+j] = 255;
			if (innercount<=0) innercount=8;

		}
 	} 
}

void blitfire(UWORD lineo,UBYTE minterm)
{	
	#define lines 256
	
	hw->bltcon0 = minterm | SRCA | SRCB | SRCC | DEST  | (1) << ASHIFTSHIFT;
	hw->bltcon1 = 0;//BLITREVERSE;
	hw->bltbmod = hw->bltamod = 0x00;
	hw->bltdmod = hw->bltcmod = 0x00;
	hw->bltafwm = 0xffff; 
	hw->bltalwm = 0xffff;
	if ((lineo&1)==0)
	{
	WaitBlit();
	hw->bltapt = hw->bltbpt = bitplane0-32;
	hw->bltcpt = hw->bltdpt = bitplane0;
	hw->bltsize = ((lines) << HSIZEBITS) | 16;
	WaitBlit();
	hw->bltapt = hw->bltbpt = bitplane1-32;
	hw->bltcpt = hw->bltdpt = bitplane1;
	hw->bltsize = ((lines) << HSIZEBITS) | 16;
	}
	else
	{
	WaitBlit();
	hw->bltapt = hw->bltbpt = bitplane2-32;
	hw->bltcpt = hw->bltdpt = bitplane2;
	hw->bltsize = ((lines) << HSIZEBITS) | 16;
	WaitBlit();
	hw->bltapt = hw->bltbpt = bitplane3-32;
	hw->bltcpt = hw->bltdpt = bitplane3;
	hw->bltsize = ((lines) << HSIZEBITS) | 16;
	}

}


void copperfire()
{
	USHORT* copPtr = copper1;
	const UBYTE* planes[6];
	*copPtr++=0x0100;*copPtr++=(0<<10)/*dual pf*/|(1<<9)/*color*/|((6)<<12)/*num bitplanes*/;// |0x4/*interlace*/;	
	
	*copPtr++=0x0108;*copPtr++=0x0000; //bpl1mod 
	*copPtr++=0x010a;*copPtr++=0x0000;// bpl2mod 
	copPtr=copWaitY(copPtr,0x28);

	planes[0]=(UBYTE*)bitplane0+0;
	planes[1]=(UBYTE*)bitplane1+32;
	planes[2]=(UBYTE*)bitplane2+64;
	planes[3]=(UBYTE*)bitplane3+96;
	planes[4]=(UBYTE*)bitplane4;
	planes[5]=(UBYTE*)bitplane4+32*8; // empty part of plane
	//planes[5]=(UBYTE*)bitplane4;
	copPtr = copSetPlanes(0, copPtr, planes, 6);

	copPtr=copWaitY(copPtr,0x64);
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[4]; 
	copPtr=copWaitY(copPtr,0x66);
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[5]; 
	copPtr=copWaitY(copPtr,0x68);
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[6]; 
	//*copPtr++=0x0100;*copPtr++=(0<<10)/*dual pf*/|(1<<9)/*color*/|((6)<<12)/*num bitplanes*/ |0x4/*interlace*/;
	copPtr = copSetOnePlane(copPtr,bitplane_empty+4096*(((LSP_Beat+5)>>2)&1), 5); // invader plane

	copPtr=copWaitY(copPtr,0x6a);
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[8]; 
	copPtr=copWaitY(copPtr,0x6c);
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[9]; 
	copPtr=copWaitY(copPtr,0x6e);
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[10]; 
	copPtr=copWaitY(copPtr,0x70);
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[11]; 


	copPtr = copWaitY(copPtr,0xe0); 
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[10]; 
	copPtr = copWaitY(copPtr,0xe2); 
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[9]; 
	copPtr = copWaitY(copPtr,0xe4); 
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[8]; 
	copPtr = copWaitY(copPtr,0xe6); 
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[6]; 
	copPtr = copWaitY(copPtr,0xe8); 
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[5]; 
	//*copPtr++=0x0100;*copPtr++=(0<<10)/*dual pf*/|(1<<9)/*color*/|((5)<<12)/*num bitplanes*/ |0x4/*interlace*/;		
	copPtr = copSetOnePlane(copPtr,bitplane4+32*8, 5); // empty part of plane

	copPtr = copWaitY(copPtr,0xea); 
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[4];
	copPtr = copWaitY(copPtr,0xec); 
	*copPtr++=0x0180;*copPtr++=bitplanecolorcalc[3];	 

	*copPtr++=0xffdf;*copPtr++=0xfffe; // low copperlist
	copPtr = copWaitY(copPtr,0x26); 
	*copPtr++=0x0100;*copPtr++=(0<<10)/*dual pf*/|(1<<9)/*color*/|((0)<<12)/*num bitplanes*/ |0x4/*interlace*/;		
	*copPtr++=0xffff;*copPtr++=0xfffe; // end copperlist

}


void blitshifter(UBYTE* destination)
{
	WaitBlit();
	hw->bltcon0 = A_TO_D | SRCA | DEST  | (0) << ASHIFTSHIFT; 
	hw->bltcon1 = 0;//BLITREVERSE; 
	hw->bltbmod = hw->bltamod = 0x001c;
	hw->bltdmod = hw->bltcmod = 0x001c;
	hw->bltafwm = 0xffff; 
	hw->bltalwm = 0xffff;

	// vertical
	for (USHORT y = 1; y < 8; y++)
	{
		WaitBlit();
		hw->bltapt = hw->bltbpt = destination+(256)*32-(y+1)*32*32;
		hw->bltcpt = hw->bltdpt = destination+(256)*32-y*32*32;
		hw->bltsize = (32 << HSIZEBITS) | 2;
	}
	
	for (USHORT i=0; i<8;i++)
	{
	// 8 times horizontal 
		for (UBYTE x = 1; x < 8; x++)
		{
			WaitBlit();
			hw->bltapt = hw->bltbpt = destination+i*1024 + 32-((x+1)*4);
			hw->bltcpt = hw->bltdpt = destination+i*1024 + 32-(x*4);
			hw->bltsize = (32 << HSIZEBITS) | 2;
		}
	}
}

void setpixel(UBYTE x, USHORT y, UBYTE* destination) 
{
	destination[y*32 + (x>>3)] |= 0b10000000>>(x&0x7);
}

void clearpixel(UBYTE x, UBYTE y, UBYTE* destination)  
{
	destination[y*32 + (x>>3)] &= ~(0b10000000>>(x&0x7));
}

void scrollsines(UBYTE* destination,UBYTE step, UBYTE shift)
{
	WaitBlit();
	hw->bltcon0 = A_TO_D | SRCA | DEST | (shift) << ASHIFTSHIFT; 
	hw->bltcon1 = 0;
	hw->bltapt = destination;
	hw->bltamod = 0;
	hw->bltdpt = destination-(step<<5);
	// bltter modulo for source C and destination D  (has to be calculated from blitsize)
	// modulo = screenwidth(bytes) - blitwidth(words)*2 
	hw->bltdmod = 0;
	// blitter first word mask for source A
	hw->bltafwm = hw->bltalwm = 0xffff;
	// blitter start and size (6..15:height, 0..5:width )
	hw->bltsize = (256+128 << HSIZEBITS) | 16;
}

void coppersines()
{
	USHORT* copPtr = copper1;
	const UBYTE* planes[5];
	*copPtr++=0x0100;*copPtr++=(0<<10)/*dual pf*/|(1<<9)/*color*/|((5)<<12)/*num bitplanes*/ ;
	
	*copPtr++=0x0108;*copPtr++=0x0000; //bpl1mod 
	*copPtr++=0x010a;*copPtr++=0x0000;// bpl2mod 

	*copPtr++=0x0180;*copPtr++=0x0000;// background color

	copPtr=copWaitY(copPtr,0x28);

	planes[0]=(UBYTE*)bitplane0;
	planes[1]=(UBYTE*)bitplane0+32;
	planes[2]=(UBYTE*)bitplane0+64;
	planes[3]=(UBYTE*)bitplane0+64+32;
	planes[4]=(UBYTE*)bitplane4;
	copPtr = copSetPlanes(0, copPtr, planes, 5);


	*copPtr++=0xffff;*copPtr++=0xfffe; // end copperlist

}

void copperendpic()
{
	USHORT* copPtr = copper1;
	const UBYTE* planes[4];
	*copPtr++=0x0100;*copPtr++=(0<<10)/*dual pf*/|(1<<9)/*color*/|((4)<<12)/*num bitplanes*/ ;
	
	*copPtr++=0x0108;*copPtr++=0x0000; //bpl1mod 
	*copPtr++=0x010a;*copPtr++=0x0000;// bpl2mod 

	*copPtr++=0x0180;*copPtr++=0x0000;// background color

	copPtr=copWaitY(copPtr,0x28);

	planes[0]=(UBYTE*)endpic;
	planes[1]=(UBYTE*)endpic+8192;
	planes[2]=(UBYTE*)endpic+16384;
	planes[3]=(UBYTE*)bitplane4;

	copPtr = copSetPlanes(0, copPtr, planes, 4);


	*copPtr++=0xffff;*copPtr++=0xfffe; // end copperlist

}

// *********************************************************************************************************************
// *********************************************************************************************************************

int main() {



	LSP_Tick = LSP_Get_Tick();
	#ifdef fastforward
	LSP_Beat=LSP_Get_Beat()+fastforward-1;
	#endif


	SysBase = *((struct ExecBase**)4UL);
	hw = (struct Custom*)0xdff000;
	// We will use the graphics library only to locate and restore the system copper list once we are through.
	GfxBase = (struct GfxBase *)OpenLibrary("graphics.library",0);
	if (!GfxBase)Exit(0);
	// used for printing
	DOSBase = (struct DosLibrary*)OpenLibrary("dos.library", 0);
	if (!DOSBase)Exit(0);

	// TODO: precalc stuff here
	TakeSystem();

//UBYTE bitplane0[32*256*2+32*64] __attribute__((section (".MEMF_CHIP"))) = {};
bitplane0=(UBYTE*)AllocMem(32*256*2+32*64,MEMF_CHIP);
//UBYTE bitplane1[32*256*2+32*64] __attribute__((section (".MEMF_CHIP"))) = {};
bitplane1=(UBYTE*)AllocMem(32*256*2+32*64,MEMF_CHIP);
//UBYTE bitplane2[32*256*2] __attribute__((section (".MEMF_CHIP"))) = {};
bitplane2=(UBYTE*)AllocMem(32*256*2,MEMF_CHIP);
//UBYTE bitplane3[32*256*2] __attribute__((section (".MEMF_CHIP"))) = {};
bitplane3=(UBYTE*)AllocMem(32*256*2,MEMF_CHIP);



	// copy atz logo
	memcpy(bitplane_empty,Alcatraz_1bitmap+16*32,112*32);

	// copy title logo
	memcpy(bitplane0,title,256*32);
	memcpy(bitplane1,title+8192*1,256*32);
	memcpy(bitplane2,title+8192*2,256*32);	
	memcpy(bitplane3,title+8192*3,256*32);	
	// copy sprites
	copy_sprites();
	//memset(bitplane4,0,256*32);

#ifdef MUSIC

	warpmode(1);
	WaitVbl();

	//set bitplane colors 
	for(int a=0;a<16;a++) hw->color[a]=bitplanecolorcalc[a];
	// set sprite colors
	for(int a=0;a<16;a++) hw->color[a+16]=spritecolorcalc[a];

	// enable interrupt Progressbar
	SetInterruptHandler((APTR)interruptHandlerProgress);
	hw->intena=(1<<INTB_SETCLR)|(1<<INTB_INTEN)|(1<<INTB_VERTB);
	hw->intreq=1<<INTB_VERTB;//reset vbl req	

	hw->cop1lc= (ULONG)copperlist_precalc;
	hw->dmacon = DMAF_BLITTER;//disable blitter dma for copjmp bug
	hw->copjmp1 = 0x7fff; //start coppper
	hw->dmacon = DMAF_SETCLR | DMAF_MASTER | DMAF_COPPER ;
	
	// precalculate samples
	generate();
	warpmode(0);
	WaitVbl();

	// start LSP player
	LSP_CIA_Start();
	
	#ifdef fastforwardpos
	LSP_Set_Pos(fastforwardpos); // pattern
	#endif 

#endif

	warpmode(0);
	WaitVbl();
	WaitVbl();
	calc_stripe();
	// enable interrupt Main
	SetInterruptHandler((APTR)interruptHandler);
	hw->intena=(1<<INTB_SETCLR)|(1<<INTB_INTEN)|(1<<INTB_VERTB);
	hw->intreq=1<<INTB_VERTB;//reset vbl req	


	// playfield init
	// standard values for screen window and bitplane DMA
	hw->diwstrt=0x29a1;  // upper left corner of the display window  (line and column where display of playfield begins)  //2981
	hw->diwstop=0x29a1;  // lower right corner of the display window (line and column where display of playfield ends (+1))//29c1		
	hw->ddfstrt=0x0048;  // start of the bitplane DMA (horiz. pos)
	hw->ddfstop=0x00c0;	 // end of the bitplane DMA (horiz. pos)
	USHORT* copPtr = copper1;


	hw->cop1lc= (ULONG)copper1;
	//hw->cop2lc= (ULONG)copper2;
	hw->dmacon = DMAF_BLITTER;//disable blitter dma for copjmp bug
	hw->copjmp1 = 0x7fff; //start coppper
	hw->dmacon = DMAF_SETCLR | DMAF_MASTER | DMAF_RASTER | DMAF_COPPER | DMAF_BLITTER ;
	//hw->bpl1mod = 0x0000;  //ffe0: repeat first line ever again, fff0: double, 
	//hw->bpl2mod = 0x0000;





endpic = (UBYTE*)AllocMem(8192*3,MEMF_CHIP);





//**********************************************************************************************
	BOOL clearflag 	= TRUE;
	BOOL clearflag3 = TRUE;
	BOOL clearflag2 = TRUE;
	BOOL clearflag4 = TRUE;
	BOOL clearflag5 = TRUE;
	BOOL clearflag6 = TRUE;
	BOOL clearflag7 = TRUE;
	BOOL clearflag8 = TRUE;
	BOOL clearflag9 = TRUE;
	UBYTE line_s 	= 32;


	while(!MouseLeft()&&LSP_Beat<441) {
	

	// title fade in
	if (fadeflag==FALSE & (LSP_Beat >=1 && LSP_Beat<=4))
	{
		fadefromblack(2,bitplanecolors_title,bitplanecolorcalc);
		for (UBYTE a = 0; a<16; a++) {spritecolorcalc[a]=0x0000;}
	}
	if (LSP_Beat==5) fadeflag=FALSE; // reset fadeflag

	// title white flash
	if (fadeflag==FALSE & (LSP_Beat >=7 && LSP_Beat<=8))
		fadefromwhite(0,bitplanecolors_title,bitplanecolorcalc);
	if (LSP_Beat==9) fadeflag=FALSE; // reset fadeflag
			// title fade out
	if (fadeflag==FALSE & (LSP_Beat >=22 && LSP_Beat<=24))
	{
		logomove++;
		fadetoblack(2,bitplanecolors_title,bitplanecolorcalc);
	}
	if (LSP_Beat==25) // wipe bitmaps from title
	{
		fadeflag=FALSE; // reset fadeflag
		memset(bitplane0+8192,170,32*256); 
		memset(bitplane1+8192,85,32*256);
		memclr(bitplane2+8192,32*256);
		memcpy(bitplane4,bitplane4+8192,8192); // copy half stripe
	
	}

	// sprites fade in
	if (fadeflag==FALSE & (LSP_Beat >=26 && LSP_Beat<=28)) 
	{
		hw->dmacon = DMAF_SETCLR | DMAF_MASTER | DMAF_RASTER | DMAF_COPPER | DMAF_BLITTER | DMAF_SPRITE; // sprites on
		hw->bplcon0=(0<<10)/*dual pf*/|(1<<9)/*color*/|((5)<<12)/*num bitplanes*/;	
		fadefromblack(2,spritecolors,spritecolorcalc); 
	}
	if (LSP_Beat==29) fadeflag=FALSE; // reset fadeflag

	myvblold=myvbl;
	WaitVBLnew();

	// sierp fade in
	if (fadeflag==FALSE & (LSP_Beat >=39 && LSP_Beat<=41))
		fadefromblack(2,bitplanecolors1,bitplanecolorcalc);
	if (LSP_Beat==43) fadeflag=FALSE; // reset fadeflag


	

	// precalc new stripe pattern for xor (not in interrupt)
	if (LSP_Beat==166 && clearflag2==TRUE) 
	{
		calc_stripe2();
		clearflag2=FALSE;
	}

	// clear bitplane for invader	
	if (LSP_Beat == 198)	memclr(bitplane_empty,256*32);

	// precalc invader
	if (LSP_Beat == 199) calc_invader();

	// clear bitplanes for bubble scene (not in interrupt), sprite DMA on for fastforward
	if (LSP_Beat==230 && clearflag3 == TRUE) 
	{
		hw->dmacon = DMAF_SETCLR | DMAF_MASTER | DMAF_RASTER | DMAF_COPPER | DMAF_BLITTER | DMAF_SPRITE; // sprites on
		memclr(bitplane4,32*256*2); 		// text plane
		clearflag3=FALSE;
	}

	// clear bitplanes for bubble scene (not in interrupt)
	if (LSP_Beat==231 && clearflag==TRUE) 
	{
		
		memclr(bitplane0,32*256*2+32*64);	// slow plane
		memclr(bitplane1,32*256*2+32*64); 	// fast plane
		memclr(bitplane4,32*256*2); 		// text plane
		clearflag=FALSE;
	}

	// clear bitplanes for fire scene (not in interrupt)
	if (LSP_Beat==294 && clearflag4==TRUE) 
	{
		WaitBlit();
		calc_invader2();
		memclr(bitplane0,8192); 	
		memclr(bitplane1,8192); 
		memclr(bitplane2,8192); 
		memclr(bitplane3,8192); 						
		memclr(bitplane4,4096+2048); 	
		memcpy(bitplane4+4096+2048,dithered,64*32);
		memcpy(bitplane4,dithered+62*32,2*32);
		clearflag4=FALSE;
	}


		// clear bitplanes for fire scene every 16th beat (not in interrupt)
	if (LSP_Beat > 295 && LSP_Beat<=359 && LSP_Flag2==FALSE && (LSP_Beat&0x0f)==7) 
	{
		memclear = TRUE;
		//hw->dmacon = DMAF_SPRITE; // sprites off
		WaitBlit();
		memset(bitplane0,0,8192);	
		memset(bitplane1,0,8192);	
		memset(bitplane2,255,8192);	
		memclr(bitplane3,8192); 		
		memclear=FALSE;	LSP_Flag2=TRUE;
	}


	
	if (LSP_Beat == 358&clearflag8==TRUE)
	{
		memclr(bitplane0,8192*2); 	
		memclr(bitplane4,8192); 	
		clearflag8=FALSE;
	}

	if (LSP_Beat == 359&&clearflag5==TRUE) //clear bitplane for scrollsines, generate copperlist
	{	
		coppersines();
		hw->dmacon = DMAF_SETCLR | DMAF_MASTER | DMAF_RASTER | DMAF_COPPER | DMAF_BLITTER | DMAF_SPRITE; // sprites on
		memcpy(bitplane4,Alcatraz_1bitmap+32*32,50*32);
		clearflag5=FALSE;
	}

	if (LSP_Beat == 391&&clearflag6==TRUE) //clear textplane
	{
		memclr(bitplane4+32*32+40*32,8192-32*32-40*32); 	
		memclr(bitplane0,8192+2048);
		clearflag6=FALSE;
	}
	
	if (LSP_Beat == (391+16) && clearflag7==TRUE) //clear textplane
	{
		memclr(bitplane4+32*32+40*32,8192-32*32-40*32); 	
		clearflag7=FALSE;
	}
	
	if (LSP_Beat >= 359 && LSP_Beat<375) // scrollsines part (not in interrupt)
	{
		for (UWORD i =0 ;i<256;i++)
		{

			USHORT func = ((sine64x256[((i<<2)+5*line_s)&255]+sine64x256[((i<<1)+7*line_s)&255]+sine64x256[(3*i+9*line_s)&255]));
			func*=sine64x256[(line_s<<1)&0xff];
			func>>=7;
			func+=255;
			//setpixel(i,func,bitplane0);
			//bitplane0[(func<<5) + (i>>3)] |= 0b10000000>>(i&0x7); // faster
			// setpixel asm
			register const	void*  a0 	ASM("a0") = bitplane0;
			register    	USHORT d0 	ASM("d0") = i;
			register    	USHORT d1 	ASM("d1") = func;
			__asm volatile (
			"lsl.w	#5,%2\n"
   			"add.w  %2,%0\n"
			"move.b %1,%2\n"
			"andi.b #7,%2\n"
			"lsr.b  #3,%1\n"
			"add.w  %1,%0\n"
			"moveq  #-128,%1\n"
			"lsr.b  %2,%1\n"
			"or.b	%1,(%0)\n"	
			: 
			: "a"(a0), "d"(d0), "d"(d1)
			: );
		}
		line_s++;
		scrollsines(bitplane0,8,15);
	}
	if (LSP_Beat >= 375 && LSP_Beat<391) // scrollsines part (not in interrupt)
	{
		for (UWORD i =0 ;i<256;i++)
		{

			USHORT func = ((sine64x256[((i<<2)+5*line_s)&255]+sine64x256[((i<<2)+17*line_s)&255]+sine64x256[(3*i+9*line_s)&255]));
			func*=sine64x256[(line_s<<1)&0xff];
			func>>=7;
			func+=255;
			//setpixel(i,func,bitplane0);
			//bitplane0[(func<<5) + (i>>3)] |= 0b10000000>>(i&0x7); // faster
			// setpixel asm
			register const	void*  a0 	ASM("a0") = bitplane0;
			register    	USHORT d0 	ASM("d0") = i;
			register    	USHORT d1 	ASM("d1") = func;
			__asm volatile (
			"lsl.w	#5,%2\n"
   			"add.w  %2,%0\n"
			"move.b %1,%2\n"
			"andi.b #7,%2\n"
			"lsr.b  #3,%1\n"
			"add.w  %1,%0\n"
			"moveq  #-128,%1\n"
			"lsr.b  %2,%1\n"
			"or.b	%1,(%0)\n"	
			: 
			: "a"(a0), "d"(d0), "d"(d1)
			: );
		}
		line_s++;
		scrollsines(bitplane0,8,15);
	}

	if (LSP_Beat >= 391 && LSP_Beat < 407) 
	{
		for (USHORT i = 0; i < 256; i++)
		{
			USHORT func = ((sine64x256[((i<<2)+5*line_s)&255]+sine64x256[((i<<1)+17*line_s)&255]+sine64x256[(3*i+9*line_s)&255]));
			func *= (sine64x256[line_s]+4);
			func >>= 7;
			func += 255;
			if (func > 286) func = 0; 
			register const	void*  a0 	ASM("a0") = bitplane0;
			register    	USHORT d0 	ASM("d0") = i;
			register    	USHORT d1 	ASM("d1") = func;
			__asm volatile (
			"lsl.w	#5,%2\n"
    		"add.w  %2,%0\n"
			"move.b %1,%2\n"
			"andi.b #7,%2\n"
			"lsr.b  #3,%1\n"
			"add.w  %1,%0\n"
			"moveq  #-128,%1\n"
			"lsr.b  %2,%1\n"
			"or.b	%1,(%0)\n"	
			: 
			: "a"(a0), "d"(d0), "d"(d1)
			: );
		}
		line_s++;
		scrollsines(bitplane0,2,2);
	}
		
	if (LSP_Beat >= 407 && LSP_Beat <428) 
	{
		for (USHORT i = 0; i < 256; i++)
		{
			USHORT func = ((sine64x256[((i<<2)+5*line_s)&255]+sine64x256[((i<<1)+17*line_s)&255]+sine64x256[(3*i+9*line_s)&255]));
			func *= (sine64x256[line_s]+4);
			func >>= 7;
			func += 255;
			if (func < 286) func = 0; 
			register const	void*  a0 	ASM("a0") = bitplane0;
			register    	USHORT d0 	ASM("d0") = i;
			register    	USHORT d1 	ASM("d1") = func;
			__asm volatile (
			"lsl.w	#5,%2\n"
    		"add.w  %2,%0\n"
			"move.b %1,%2\n"
			"andi.b #7,%2\n"
			"lsr.b  #3,%1\n"
			"add.w  %1,%0\n"
			"moveq  #-128,%1\n"
			"lsr.b  %2,%1\n"
			"or.b	%1,(%0)\n"	
			: 
			: "a"(a0), "d"(d0), "d"(d1)
			: );
		}
		line_s++;
		scrollsines(bitplane0,2,2);
	}
	if (LSP_Beat == 428&clearflag9==TRUE)
	{
		memcpy(endpic,ep,8192*3);	
		memset(bitplane4,0,8192); 	
		clearflag9=FALSE;
	}

	}


//******************************************************************************************************************


	// END


	WaitVbl();
	WaitBlit();
	FreeSystem();
	WaitVbl();
	WaitBlit();

	LSP_CIA_Stop();

	WaitVbl();
	WaitBlit();
	CloseLibrary((struct Library*)DOSBase);
	CloseLibrary((struct Library*)GfxBase);
}

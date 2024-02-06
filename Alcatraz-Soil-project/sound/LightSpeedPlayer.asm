;*****************************************************************
;
;	Light Speed Player v1.12
;	Fastest Amiga MOD player ever :)
;	Written By Arnaud Carr� (aka Leonard / OXYGENE)
;	https://github.com/arnaud-carre/LSPlayer
;	twitter: @leonard_coder
;
;	"cia" player version ( or "less effort" )
;
;	Warnings:
;	a)	this file is provided for "easy of use". But if you're working
;		on a cycle-optimizated demo effect, please call LightSpeedPlayer from your
;		own existing interrupt and use copper to set DMACON 11 raster lines later
;
;	b)	this code doesn't restore any amiga OS stuff.
;		( are you a cycle-optimizer or what? :) )
;
;	--------How to use--------- 
;
;	bsr LSP_MusicDriver_CIA_Start : Init LSP player code and install CIA interrupt
;		a0: LSP music data(any memory)
;		a1: LSP sound bank(chip memory)
;		a2: VBR (CPU Vector Base Register) ( use 0 if 68000 )
;		d0: 0=PAL, 1=NTSC
;
;	bsr LSP_MusicDriver_CIA_Stop : Stop LSP music replay
;
;*****************************************************************
LSP_MusicDriver_CIA_Start:
			move.w #0,d0
			move.l  #-10,myGlobalCounter	; initializing tick counter with a little offset (virgill) -22 was good
			move.w	#1,myBeatCounter		; initializing beat counter (virgill)
			move.w	#0,myTemp				; initializing beat counter temp (virgill)
			move.w	d0,-(a7)
			lea		.irqVector(pc),a3
			lea		$78(a2),a2
			move.l	a2,(a3)
			lea		.LSPDmaCon+1(pc),a2		; DMACON byte patch address
			bsr		LSP_MusicInit			; init the LSP player ( whatever fast or insane version )

			lea		.pMusicBPM(pc),a2
			move.l	a0,(a2)					; store music BPM pointer
			move.w	(a0),d0					; start BPM
			lea		.curBpm(pc),a2
			move.w	d0,(a2)
			moveq	#1,d1
			and.w	(a7)+,d1
			bsr.s	.LSP_IrqInstall

			rts

.LSPDmaCon:	dc.w	$8000
.irqVector:	dc.l	0
.ciaClock:	dc.l	0
.curBpm:	dc.w	0
.pMusicBPM:	dc.l	0

; d0: music BPM
; d1: PAL(0) or NTSC(1)
.LSP_IrqInstall:
			move.w 	#(1<<13),$dff09a		; disable CIA interrupt
			lea		.LSP_MainIrq(pc),a0
			move.l	.irqVector(pc),a5
			move.l	a0,(a5)

			lea		$bfd000,a0
			move.b 	#$7f,$d00(a0)
			move.b 	#$10,$e00(a0)
			move.b 	#$10,$f00(a0)
			lsl.w	#2,d1
			move.l	.palClocks(pc,d1.w),d1				; PAL or NTSC clock
			lea		.ciaClock(pc),a5
			move.l	d1,(a5)
			divu.w	d0,d1
			move.b	d1,$400(a0)
			lsr.w 	#8,d1
			move.b	d1,$500(a0)
			move.b	#$83,$d00(a0)
			move.b	#$11,$e00(a0)
			
			move.b	#496&255,$600(a0)		; set timer b to 496 ( to set DMACON )
			move.b	#496>>8,$700(a0)

			move.w 	#(1<<13),$dff09c		; clear any req CIA
			move.w 	#$a000,$dff09a			; CIA interrupt enabled
			rts
		
.palClocks:	dc.l	1773447,1789773

.LSP_MainIrq:
			btst.b	#0,$bfdd00
			beq.s	.skipa
			
			movem.l	d0-d2/a0-a6,-(a7)

		; call player tick
			lea		$dff0a0,a6
			addq.l 	#1,myGlobalCounter
			addq.w 	#1,myTemp
			cmp.w   #23,myTemp
			ble.s	.moveOn
			move.w	#0,myTemp
			addq.w	#1,myBeatCounter
.moveOn:			

			bsr		LSP_MusicPlayTick		; LSP main music driver tick

		; check if BMP changed in the middle of the music
			move.l	.pMusicBPM(pc),a0
			move.w	(a0),d0					; current music BPM
			cmp.w	.curBpm(pc),d0
			beq.s	.noChg
			lea		.curBpm(pc),a2			
			move.w	d0,(a2)					; current BPM
			move.l	.ciaClock(pc),d1
			divu.w	d0,d1
			move.b	d1,$bfd400
			lsr.w 	#8,d1
			move.b	d1,$bfd500			

.noChg:		lea		.LSP_DmaconIrq(pc),a0
			move.l	.irqVector(pc),a1
			move.l	a0,(a1)
			move.b	#$19,$bfdf00			; start timerB, one shot

			movem.l	(a7)+,d0-d2/a0-a6
.skipa:		move.w	#$2000,$dff09c
			nop
			rte

.LSP_DmaconIrq:
			btst.b	#1,$bfdd00
			beq.s	.skipb
			move.w	.LSPDmaCon(pc),$dff096
			pea		(a0)
			move.l	.irqVector(pc),a0
			pea		.LSP_MainIrq(pc)
			move.l	(a7)+,(a0)
			move.l	(a7)+,a0
.skipb:		move.w	#$2000,$dff09c
			nop
			rte

LSP_MusicDriver_CIA_Stop:
			move.b	#$7f,$bfdd00
			move.w	#$2000,$dff09a
			move.w	#$2000,$dff09c
			move.w	#$000f,$dff096
			rts


;*****************************************************************
;
;	Light Speed Player v1.13
;	Fastest Amiga MOD player ever :)
;	Written By Arnaud Carr� (aka Leonard / OXYGENE)
;	https://github.com/arnaud-carre/LSPlayer
;	twitter: @leonard_coder
;
;	"small & fast" player version ( average time: 1 scanline )
;	Less than 512 bytes of code!
;	You can also use generated "insane" player code for half scanline replayer (-insane option)
;
;	LSP_MusicInit		Initialize a LSP driver + relocate score&bank music data
;	LSP_MusicPlayTick	Play a LSP music (call it per frame)
;	LSP_MusicGetPos		Get mod seq pos (see -getpos option in LSPConvert)
;	LSP_MusicSetPos		Set mod seq pos (see -setpos option in LSPConvert)
;
;*****************************************************************

;------------------------------------------------------------------
;
;	LSP_MusicInit
;
;		In:	a0: LSP music data(any memory)
;			a1: LSP sound bank(chip memory)
;			a2: DMACON low byte address (should be odd address!)
;		Out:a0: music BPM pointer (16bits)
;			d0: music len in tick count
;
;------------------------------------------------------------------
LSP_MusicInit:
			cmpi.l	#'LSP1',(a0)+
		;	bne		.dataError
			move.l	(a0)+,d0		; unique id
			cmp.l	(a1),d0			; check that sample bank is this one
		;	bne		.dataError

			lea		LSP_State(pc),a3
			move.l	a2,m_dmaconPatch(a3)
			move.w	#$8000,-1(a2)			; Be sure DMACon word is $8000 (note: a2 should be ODD address)
			cmpi.w	#$010b,(a0)+			; v1.10 minimal major & minor version of latest compatible LSPConvert.exe
			blt		.dataError
			movea.l	a0,a4					; relocation flag ad
			addq.w	#2,a0					; skip relocation flag
			move.w	(a0)+,m_currentBpm(a3)	; default BPM
			move.w	(a0)+,m_escCodeRewind(a3)
			move.w	(a0)+,m_escCodeSetBpm(a3)
			move.w	(a0)+,m_escCodeGetPos(a3)
			move.l	(a0)+,-(a7)				; music len in frame ticks
			move.w	(a0)+,d0				; instrument count
			lea		-12(a0),a2				; LSP data has -12 offset on instrument tab ( to win 2 cycles in insane player :) )
			move.l	a2,m_lspInstruments(a3)	; instrument tab addr ( minus 4 )
			subq.w	#1,d0
			move.l	a1,d1
			movea.l	a0,a1					; keep relocated flag
.relocLoop:	tst.b	(a4)					; relocation guard
			bne.s	.relocated
			add.l	d1,(a0)
			add.l	d1,6(a0)
.relocated:	lea		12(a0),a0
			dbf		d0,.relocLoop
			move.w	(a0)+,d0				; codes table size
			move.l	a0,m_codeTableAddr(a3)	; code table
			add.w	d0,d0
			add.w	d0,a0

		; read sequence timing infos (if any)
			move.w	(a0)+,m_seqCount(a3)
			beq.s	.noSeq
			move.l	a0,m_seqTable(a3)
			clr.w	m_currentSeq(a3)
			move.w	m_seqCount(a3),d0
			moveq	#0,d1
			move.w	d0,d1
			lsl.w	#3,d1			; 8 bytes per entry
			add.w	#12,d1			; add 3 last 32bits (word stream size, byte stream loop, word stream loop)
			add.l	a0,d1			; word stream data address
			subq.w	#1,d0
.seqRel:	tst.b	(a4)
			bne.s	.skipRel
			add.l	d1,(a0)
			add.l	d1,4(a0)
.skipRel:	addq.w	#8,a0
			dbf		d0,.seqRel

.noSeq:		move.l	(a0)+,d0				; word stream size
			move.l	(a0)+,d1				; byte stream loop point
			move.l	(a0)+,d2				; word stream loop point

			st		(a4)					; mark this music score as "relocated"

			move.l	a0,m_wordStream(a3)
			lea		0(a0,d0.l),a1			; byte stream
			move.l	a1,m_byteStream(a3)
			add.l	d2,a0
			add.l	d1,a1
			move.l	a0,m_wordStreamLoop(a3)
			move.l	a1,m_byteStreamLoop(a3)
			bset.b	#1,$bfe001				; disabling this fucking Low pass filter!!
			lea		m_currentBpm(a3),a0
			move.l	(a7)+,d0				; music len in frame ticks
			rts

.dataError:	illegal

;------------------------------------------------------------------
;
;	LSP_MusicPlayTick
;
;		In:	a6: should be $dff0a0
;			Scratched regs: d0/d1/d2/a0/a1/a2/a3/a4/a5
;		Out:None
;
;------------------------------------------------------------------
LSP_MusicPlayTick:
			lea		LSP_State(pc),a1
			move.l	(a1),a0					; byte stream
			move.l	m_codeTableAddr(a1),a2	; code table
.process:	moveq	#0,d0
.cloop:		move.b	(a0)+,d0
			beq		.cextended
			add.w	d0,d0
			move.w	0(a2,d0.w),d0			; code
			beq		.noInst

.cmdExec:	add.b	d0,d0
			bcc.s	.noVd
			move.b	(a0)+,$d9-$a0(a6)
.noVd:		add.b	d0,d0
			bcc.s	.noVc
			move.b	(a0)+,$c9-$a0(a6)
.noVc:		add.b	d0,d0
			bcc.s	.noVb
			move.b	(a0)+,$b9-$a0(a6)
.noVb:		add.b	d0,d0
			bcc.s	.noVa
			move.b	(a0)+,$a9-$a0(a6)
.noVa:		
			move.l	a0,(a1)+	; store byte stream ptr
			move.l	(a1),a0		; word stream

			tst.b	d0
			beq.s	.noPa

			add.b	d0,d0
			bcc.s	.noPd
			move.w	(a0)+,$d6-$a0(a6)
.noPd:		add.b	d0,d0
			bcc.s	.noPc
			move.w	(a0)+,$c6-$a0(a6)
.noPc:		add.b	d0,d0
			bcc.s	.noPb
			move.w	(a0)+,$b6-$a0(a6)
.noPb:		add.b	d0,d0
			bcc.s	.noPa
			move.w	(a0)+,$a6-$a0(a6)
.noPa:		
			tst.w	d0
			beq.s	.noInst

			moveq	#0,d1
			move.l	m_lspInstruments-4(a1),a2	; instrument table
			lea		.resetv+12(pc),a4

			lea		3*16(a6),a5
			moveq	#4-1,d2

.vloop:		add.w	d0,d0
			bcs.s	.setIns
			add.w	d0,d0
			bcc.s	.skip
			move.l	(a4),a3
			move.l	(a3)+,(a5)
			move.w	(a3)+,4(a5)
			bra.s	.skip
.setIns:	add.w	(a0)+,a2
			add.w	d0,d0
			bcc.s	.noReset
			bset	d2,d1
			move.w	d1,$96-$a0(a6)
.noReset:	move.l	(a2)+,(a5)
			move.w	(a2)+,4(a5)
			move.l	a2,(a4)
.skip:		subq.w	#4,a4
			lea		-16(a5),a5
			dbf		d2,.vloop

			move.l	m_dmaconPatch-4(a1),a3		; dmacon patch
			move.b	d1,(a3)						; dmacon			

.noInst:	move.l	a0,(a1)			; store word stream (or byte stream if coming from early out)
			rts

.cextended:	addi.w	#$100,d0
			move.b	(a0)+,d0
			beq.s	.cextended
			add.w	d0,d0
			move.w	0(a2,d0.w),d0			; code

			cmp.w	m_escCodeRewind(a1),d0
			beq.s	.r_rewind
			cmp.w	m_escCodeSetBpm(a1),d0
			beq.s	.r_chgbpm
			cmp.w	m_escCodeGetPos(a1),d0
			bne		.cmdExec

.r_setPos:	move.b	(a0)+,(m_currentSeq+1)(a1)
			bra		.process

.r_rewind:	
			move.l	m_byteStreamLoop(a1),a0
			move.l	m_wordStreamLoop(a1),m_wordStream(a1)
			bra		.process

.r_chgbpm:	move.b	(a0)+,(m_currentBpm+1)(a1)	; BPM
			bra		.process

.resetv:	dc.l	0,0,0,0


;------------------------------------------------------------------
;
;	LSP_MusicSetPos
;
;		In: d0: seq position (from 0 to last seq of the song)
;		Out:None
;
;	Force the replay pointer to a seq position. If music wasn't converted
;	using -setpos option, this func does nothing
;
;------------------------------------------------------------------
LSP_MusicSetPos:
			lea		LSP_State(pc),a3
			move.w	m_seqCount(a3),d1
			beq.s	.noTimingInfo
			cmp.w	d1,d0
			bge.s	.noTimingInfo
			move.w	d0,m_currentSeq(a3)
			move.l	m_seqTable(a3),a0
			lsl.w	#3,d0
			add.w	d0,a0
			move.l	(a0)+,m_wordStream(a3)
			move.l	(a0)+,m_byteStream(a3)
.noTimingInfo:
			rts

;------------------------------------------------------------------
;
;	LSP_MusicGetPos
;
;		In: None
;		Out: d0:  seq position (from 0 to last seq of the song)
;
;	Get the current seq position. If music wasn't converted with
;	-getpos option, this func just returns 0
;
;------------------------------------------------------------------
LSP_MusicGetPos:
			move.w	(LSP_State+m_currentSeq)(pc),d0
			;move.w #3,d0
			rts

;------------------------------------------------------------------
;
;	LSP_MusicGetTick 
;
;		In: None
;		Out: d0:  ticks
;
;	Get the current number of ticks. 
;
;------------------------------------------------------------------
LSP_MusicGetTick:
			move.l	myGlobalCounter,d0
			rts

;------------------------------------------------------------------
;
;	LSP_MusicGetBeat (Virgill) 
;
;		In: None
;		Out: d0:  beats
;
;	Get the current number of beats. 
;
;------------------------------------------------------------------
LSP_MusicGetBeat:
			move.w	myBeatCounter,d0
			rts


	rsreset
	
m_byteStream:		rs.l	1	;  0 byte stream
m_wordStream:		rs.l	1	;  4 word stream
m_dmaconPatch:		rs.l	1	;  8 m_lfmDmaConPatch
m_codeTableAddr:	rs.l	1	; 12 code table addr
m_escCodeRewind:	rs.w	1	; 16 rewind special escape code
m_escCodeSetBpm:	rs.w	1	; 18 set BPM escape code
m_lspInstruments:	rs.l	1	; 20 LSP instruments table addr
m_relocDone:		rs.w	1	; 24 reloc done flag
m_currentBpm:		rs.w	1	; 26 current BPM
m_byteStreamLoop:	rs.l	1	; 28 byte stream loop point
m_wordStreamLoop:	rs.l	1	; 32 word stream loop point
m_seqCount:			rs.w	1
m_seqTable:			rs.l	1
m_currentSeq:		rs.w	1
m_escCodeGetPos:	rs.w	1
sizeof_LSPVars:		rs.w	0
myGlobalCounter: 	dc.l 	0
myBeatCounter:	 	dc.w 	0
myTemp:				dc.w 	0
LSP_State:			ds.b	sizeof_LSPVars


	xdef LSP_MusicInit
	xdef LSP_MusicPlayTick
	xref LSP_MusicDriver_CIA_Start
	xref LSP_MusicDriver_CIA_Stop
	xref LSP_MusicGetPos
	xref LSP_MusicSetPos
	xref LSP_MusicGetTick
	xref LSP_MusicGetBeat
	;xref myGlobalCounter
	;xref myBeatCounter


	
	

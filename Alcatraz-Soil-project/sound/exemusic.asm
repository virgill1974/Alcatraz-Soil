;----------------------------------------------------------------------------
;
; Generated with Aklang2Asm V1.1, by Dan/Lemon. 2021-2022.
;
; Based on Alcatraz Amigaklang rendering core. (c) Jochen 'Virgill' Feldkötter 2020.
;
; What's new in V1.1?
; - Instance offsets fixed in ADSR operator
; - Incorrect shift direction fixed in OnePoleFilter operator
; - Loop Generator now correctly interleaved with instrument generation
; - Fine progress includes loop generation, and new AK_FINE_PROGRESS_LEN added
; - Reverb large buffer instance offsets were wrong, causing potential buffer overrun
;
; Call 'AK_Generate' with the following registers set:
; a0 = Sample Buffer Start Address
; a1 = 32768 Bytes Temporary Work Buffer Address (can be freed after sample rendering complete)
; a2 = External Samples Address (need not be in chip memory, and can be freed after sample rendering complete)
; a3 = Rendering Progress Address (2 modes available... see below)
;
; AK_FINE_PROGRESS equ 0 = rendering progress as a byte (current instrument number)
; AK_FINE_PROGRESS equ 1 = rendering progress as a long (current sample byte)
;
;----------------------------------------------------------------------------

AK_USE_PROGRESS			equ 1
AK_FINE_PROGRESS		equ 0
AK_FINE_PROGRESS_LEN	equ 250847
AK_SMP_LEN				equ 185656
AK_EXT_SMP_LEN			equ 12448

AK_Generate:

				lea		AK_Vars(pc),a5

				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						move.b	#-1,(a3)
					else
						move.l	#0,(a3)
					endif
				endif

				; Create sample & external sample base addresses
				lea		AK_SmpLen(a5),a6
				lea		AK_SmpAddr(a5),a4
				move.l	a0,d0
				moveq	#31-1,d7
.SmpAdrLoop		move.l	d0,(a4)+
				add.l	(a6)+,d0
				dbra	d7,.SmpAdrLoop
				move.l	a2,d0
				moveq	#8-1,d7
.ExtSmpAdrLoop	move.l	d0,(a4)+
				add.l	(a6)+,d0
				dbra	d7,.ExtSmpAdrLoop

				; Convert external samples from stored deltas
				move.l	a2,a6
				move.w	#AK_EXT_SMP_LEN-1,d7
				moveq	#0,d0
.DeltaLoop		add.b	(a6),d0
				move.b	d0,(a6)+
				dbra	d7,.DeltaLoop

;----------------------------------------------------------------------------
; Instrument 1 - Soill-Kick
;----------------------------------------------------------------------------

				moveq	#8,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst1Loop
				; v1 = imported_sample(smp,0)
				moveq	#0,d0
				cmp.l	AK_ExtSmpLen+0(a5),d7
				bge.s	.NoClone_1_1
				move.l	AK_ExtSmpAddr+0(a5),a4
				move.b	(a4,d7.l),d0
				asl.w	#8,d0
.NoClone_1_1

				; v2 = envd(1, 13, 0, 128)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#381184,d5
				bgt.s   .EnvDNoSustain_1_2
				moveq	#0,d5
.EnvDNoSustain_1_2
				move.l	d5,AK_EnvDValue+0(a5)

				; v1 = mul(v1, v2)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+0(a5),d7
				blt		.Inst1Loop

;----------------------------------------------------------------------------
; Instrument 2 - hat_closed
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst2Loop
				; v1 = imported_sample(smp,1)
				moveq	#0,d0
				cmp.l	AK_ExtSmpLen+4(a5),d7
				bge.s	.NoClone_2_1
				move.l	AK_ExtSmpAddr+4(a5),a4
				move.b	(a4,d7.l),d0
				asl.w	#8,d0
.NoClone_2_1

				; v1 = reverb(v1, 32, 16)
				move.l	d7,-(sp)
				sub.l	a6,a6
				move.l	a1,a4
				move.w	AK_OpInstance+0(a5),d5
				move.w	(a4,d5.w),d4
				asr.w	#2,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_2_2_0
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_2_2_0
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#557<<1,d5
				ble.s	.NoReverbReset_2_2_0
				moveq	#0,d5
.NoReverbReset_2_2_0
				move.w  d5,AK_OpInstance+0(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		4096(a1),a4
				move.w	AK_OpInstance+2(a5),d5
				move.w	(a4,d5.w),d4
				asr.w	#2,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_2_2_1
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_2_2_1
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#593<<1,d5
				ble.s	.NoReverbReset_2_2_1
				moveq	#0,d5
.NoReverbReset_2_2_1
				move.w  d5,AK_OpInstance+2(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		8192(a1),a4
				move.w	AK_OpInstance+4(a5),d5
				move.w	(a4,d5.w),d4
				asr.w	#2,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_2_2_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_2_2_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#641<<1,d5
				ble.s	.NoReverbReset_2_2_2
				moveq	#0,d5
.NoReverbReset_2_2_2
				move.w  d5,AK_OpInstance+4(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		12288(a1),a4
				move.w	AK_OpInstance+6(a5),d5
				move.w	(a4,d5.w),d4
				asr.w	#2,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_2_2_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_2_2_3
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#677<<1,d5
				ble.s	.NoReverbReset_2_2_3
				moveq	#0,d5
.NoReverbReset_2_2_3
				move.w  d5,AK_OpInstance+6(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		16384(a1),a4
				move.w	AK_OpInstance+8(a5),d5
				move.w	(a4,d5.w),d4
				asr.w	#2,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_2_2_4
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_2_2_4
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#709<<1,d5
				ble.s	.NoReverbReset_2_2_4
				moveq	#0,d5
.NoReverbReset_2_2_4
				move.w  d5,AK_OpInstance+8(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		20480(a1),a4
				move.w	AK_OpInstance+10(a5),d5
				move.w	(a4,d5.w),d4
				asr.w	#2,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_2_2_5
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_2_2_5
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#743<<1,d5
				ble.s	.NoReverbReset_2_2_5
				moveq	#0,d5
.NoReverbReset_2_2_5
				move.w  d5,AK_OpInstance+10(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		24576(a1),a4
				move.w	AK_OpInstance+12(a5),d5
				move.w	(a4,d5.w),d4
				asr.w	#2,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_2_2_6
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_2_2_6
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#787<<1,d5
				ble.s	.NoReverbReset_2_2_6
				moveq	#0,d5
.NoReverbReset_2_2_6
				move.w  d5,AK_OpInstance+12(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		28672(a1),a4
				move.w	AK_OpInstance+14(a5),d5
				move.w	(a4,d5.w),d4
				asr.w	#2,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_2_2_7
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_2_2_7
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#809<<1,d5
				ble.s	.NoReverbReset_2_2_7
				moveq	#0,d5
.NoReverbReset_2_2_7
				move.w  d5,AK_OpInstance+14(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				move.l	a6,d7
				cmp.l	#32767,d7
				ble.s	.NoReverbMax_2_2
				move.w	#32767,d7
				bra.s	.NoReverbMin_2_2
.NoReverbMax_2_2
				cmp.l	#-32768,d7
				bge.s	.NoReverbMin_2_2
				move.w	#-32768,d7
.NoReverbMin_2_2
				move.w	d7,d0
				move.l	(sp)+,d7

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+4(a5),d7
				blt		.Inst2Loop

;----------------------------------------------------------------------------
; Instrument 3 - hat_open
;----------------------------------------------------------------------------

				moveq	#8,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst3Loop
				; v1 = clone(smp,1, 284)
				move.l	d7,d6
				add.l	#284,d6
				moveq	#0,d0
				cmp.l	AK_SmpLen+4(a5),d6
				bge.s	.NoClone_3_1
				move.l	AK_SmpAddr+4(a5),a4
				move.b	(a4,d6.l),d0
				asl.w	#8,d0
.NoClone_3_1

				; v1 = distortion(v1, 42)
				move.w	d0,d5
				muls	#42,d5
				asr.l	#5,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxDist_3_2
				move.w	#32767,d5
				bra.s	.NoClampMinDist_3_2
.NoClampMaxDist_3_2
				cmp.l	#-32768,d5
				bge.s	.NoClampMinDist_3_2
				move.w	#-32768,d5
.NoClampMinDist_3_2
				asr.w	#1,d5
				move.w	d5,d0
				bge.s	.DistNoAbs_3_2
				neg.w	d5
.DistNoAbs_3_2
				move.w	#32767,d6
				sub.w	d5,d6
				muls	d6,d0
				swap	d0
				asl.w	#3,d0

				; v1 = onepole_flt(2, v1, 32, 1)
				move.w	AK_OpInstance+0(a5),d5
				move.w	d5,d6
				ext.l	d6
				asr.w	#7,d5
				asl.w	#5,d5
				ext.l	d5
				sub.l	d5,d6
				move.w	d0,d5
				asr.w	#7,d5
				asl.w	#5,d5
				ext.l	d5
				add.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxOPF_3_3
				move.w	#32767,d5
				bra.s	.NoClampMinOPF_3_3
.NoClampMaxOPF_3_3
				cmp.l	#-32768,d5
				bge.s	.NoClampMinOPF_3_3
				move.w	#-32768,d5
.NoClampMinOPF_3_3
				move.w	d5,AK_OpInstance+0(a5)
				sub.w	d5,d0

				; v1 = reverb(v1, 127, 32)
				move.l	d7,-(sp)
				sub.l	a6,a6
				move.l	a1,a4
				move.w	AK_OpInstance+2(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_3_4_0
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_3_4_0
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#557<<1,d5
				ble.s	.NoReverbReset_3_4_0
				moveq	#0,d5
.NoReverbReset_3_4_0
				move.w  d5,AK_OpInstance+2(a5)
				move.w	d4,d7
				asr.w	#2,d7
				add.w	d7,a6
				lea		4096(a1),a4
				move.w	AK_OpInstance+4(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_3_4_1
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_3_4_1
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#593<<1,d5
				ble.s	.NoReverbReset_3_4_1
				moveq	#0,d5
.NoReverbReset_3_4_1
				move.w  d5,AK_OpInstance+4(a5)
				move.w	d4,d7
				asr.w	#2,d7
				add.w	d7,a6
				lea		8192(a1),a4
				move.w	AK_OpInstance+6(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_3_4_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_3_4_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#641<<1,d5
				ble.s	.NoReverbReset_3_4_2
				moveq	#0,d5
.NoReverbReset_3_4_2
				move.w  d5,AK_OpInstance+6(a5)
				move.w	d4,d7
				asr.w	#2,d7
				add.w	d7,a6
				lea		12288(a1),a4
				move.w	AK_OpInstance+8(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_3_4_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_3_4_3
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#677<<1,d5
				ble.s	.NoReverbReset_3_4_3
				moveq	#0,d5
.NoReverbReset_3_4_3
				move.w  d5,AK_OpInstance+8(a5)
				move.w	d4,d7
				asr.w	#2,d7
				add.w	d7,a6
				lea		16384(a1),a4
				move.w	AK_OpInstance+10(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_3_4_4
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_3_4_4
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#709<<1,d5
				ble.s	.NoReverbReset_3_4_4
				moveq	#0,d5
.NoReverbReset_3_4_4
				move.w  d5,AK_OpInstance+10(a5)
				move.w	d4,d7
				asr.w	#2,d7
				add.w	d7,a6
				lea		20480(a1),a4
				move.w	AK_OpInstance+12(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_3_4_5
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_3_4_5
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#743<<1,d5
				ble.s	.NoReverbReset_3_4_5
				moveq	#0,d5
.NoReverbReset_3_4_5
				move.w  d5,AK_OpInstance+12(a5)
				move.w	d4,d7
				asr.w	#2,d7
				add.w	d7,a6
				lea		24576(a1),a4
				move.w	AK_OpInstance+14(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_3_4_6
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_3_4_6
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#787<<1,d5
				ble.s	.NoReverbReset_3_4_6
				moveq	#0,d5
.NoReverbReset_3_4_6
				move.w  d5,AK_OpInstance+14(a5)
				move.w	d4,d7
				asr.w	#2,d7
				add.w	d7,a6
				lea		28672(a1),a4
				move.w	AK_OpInstance+16(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_3_4_7
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_3_4_7
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#809<<1,d5
				ble.s	.NoReverbReset_3_4_7
				moveq	#0,d5
.NoReverbReset_3_4_7
				move.w  d5,AK_OpInstance+16(a5)
				move.w	d4,d7
				asr.w	#2,d7
				add.w	d7,a6
				move.l	a6,d7
				cmp.l	#32767,d7
				ble.s	.NoReverbMax_3_4
				move.w	#32767,d7
				bra.s	.NoReverbMin_3_4
.NoReverbMax_3_4
				cmp.l	#-32768,d7
				bge.s	.NoReverbMin_3_4
				move.w	#-32768,d7
.NoReverbMin_3_4
				move.w	d7,d0
				move.l	(sp)+,d7

				; v2 = adsr(4, 8388352, 1170, 0, -3, 0, 8388352)
				move.l	AK_OpInstance+18(a5),d1
				move.w	AK_OpInstance+22(a5),d4
				beq.s	.ADSR_A_3_5
				subq.w	#1,d4
				beq.s	.ADSR_D_3_5
				subq.w	#1,d4
				beq.s	.ADSR_S_3_5
.ADSR_R_3_5
				sub.l	#0,d1
				bge.s	.ADSR_End_3_5
				moveq	#0,d1
				bra.s	.ADSR_End_3_5
.ADSR_A_3_5
				add.l	#8388352,d1
				cmp.l	#8388352,d1
				blt.s	.ADSR_End_3_5
				move.l	#8388352,d1
				move.w	#1,AK_OpInstance+22(a5)
				bra.s	.ADSR_End_3_5
.ADSR_D_3_5
				sub.l	#1170,d1
				cmp.l	#0,d1
				bgt.s	.ADSR_End_3_5
				move.l	#0,d1
				move.l	#-3,AK_OpInstance+24(a5)
				move.w	#2,AK_OpInstance+22(a5)
				bra.s	.ADSR_End_3_5
.ADSR_S_3_5
				subq.l	#1,AK_OpInstance+24(a5)
				bge.s	.ADSR_End_3_5
				move.w	#3,AK_OpInstance+22(a5)
.ADSR_End_3_5
				move.l	d1,AK_OpInstance+18(a5)
				asr.l	#8,d1

				; v1 = mul(v1, v2)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+8(a5),d7
				blt		.Inst3Loop

;----------------------------------------------------------------------------
; Instrument 4 - Kick+Snare
;----------------------------------------------------------------------------

				moveq	#8,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst4Loop
				; v1 = imported_sample(smp,2)
				moveq	#0,d0
				cmp.l	AK_ExtSmpLen+8(a5),d7
				bge.s	.NoClone_4_1
				move.l	AK_ExtSmpAddr+8(a5),a4
				move.b	(a4,d7.l),d0
				asl.w	#8,d0
.NoClone_4_1

				; v2 = onepole_flt(1, v1, 64, 1)
				move.w	AK_OpInstance+0(a5),d5
				move.w	d5,d6
				ext.l	d6
				asr.w	#7,d5
				asl.w	#6,d5
				ext.l	d5
				sub.l	d5,d6
				move.w	d0,d5
				asr.w	#7,d5
				asl.w	#6,d5
				ext.l	d5
				add.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxOPF_4_2
				move.w	#32767,d5
				bra.s	.NoClampMinOPF_4_2
.NoClampMaxOPF_4_2
				cmp.l	#-32768,d5
				bge.s	.NoClampMinOPF_4_2
				move.w	#-32768,d5
.NoClampMinOPF_4_2
				move.w	d5,AK_OpInstance+0(a5)
				move.w	d0,d1
				sub.w	d5,d1

				; v2 = reverb(v2, 90, 16)
				move.l	d7,-(sp)
				sub.l	a6,a6
				move.l	a1,a4
				move.w	AK_OpInstance+2(a5),d5
				move.w	(a4,d5.w),d4
				muls	#90,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_4_3_0
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_4_3_0
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#557<<1,d5
				ble.s	.NoReverbReset_4_3_0
				moveq	#0,d5
.NoReverbReset_4_3_0
				move.w  d5,AK_OpInstance+2(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		4096(a1),a4
				move.w	AK_OpInstance+4(a5),d5
				move.w	(a4,d5.w),d4
				muls	#90,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_4_3_1
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_4_3_1
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#593<<1,d5
				ble.s	.NoReverbReset_4_3_1
				moveq	#0,d5
.NoReverbReset_4_3_1
				move.w  d5,AK_OpInstance+4(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		8192(a1),a4
				move.w	AK_OpInstance+6(a5),d5
				move.w	(a4,d5.w),d4
				muls	#90,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_4_3_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_4_3_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#641<<1,d5
				ble.s	.NoReverbReset_4_3_2
				moveq	#0,d5
.NoReverbReset_4_3_2
				move.w  d5,AK_OpInstance+6(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		12288(a1),a4
				move.w	AK_OpInstance+8(a5),d5
				move.w	(a4,d5.w),d4
				muls	#90,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_4_3_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_4_3_3
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#677<<1,d5
				ble.s	.NoReverbReset_4_3_3
				moveq	#0,d5
.NoReverbReset_4_3_3
				move.w  d5,AK_OpInstance+8(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		16384(a1),a4
				move.w	AK_OpInstance+10(a5),d5
				move.w	(a4,d5.w),d4
				muls	#90,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_4_3_4
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_4_3_4
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#709<<1,d5
				ble.s	.NoReverbReset_4_3_4
				moveq	#0,d5
.NoReverbReset_4_3_4
				move.w  d5,AK_OpInstance+10(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		20480(a1),a4
				move.w	AK_OpInstance+12(a5),d5
				move.w	(a4,d5.w),d4
				muls	#90,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_4_3_5
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_4_3_5
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#743<<1,d5
				ble.s	.NoReverbReset_4_3_5
				moveq	#0,d5
.NoReverbReset_4_3_5
				move.w  d5,AK_OpInstance+12(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		24576(a1),a4
				move.w	AK_OpInstance+14(a5),d5
				move.w	(a4,d5.w),d4
				muls	#90,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_4_3_6
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_4_3_6
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#787<<1,d5
				ble.s	.NoReverbReset_4_3_6
				moveq	#0,d5
.NoReverbReset_4_3_6
				move.w  d5,AK_OpInstance+14(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		28672(a1),a4
				move.w	AK_OpInstance+16(a5),d5
				move.w	(a4,d5.w),d4
				muls	#90,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_4_3_7
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_4_3_7
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#809<<1,d5
				ble.s	.NoReverbReset_4_3_7
				moveq	#0,d5
.NoReverbReset_4_3_7
				move.w  d5,AK_OpInstance+16(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				move.l	a6,d7
				cmp.l	#32767,d7
				ble.s	.NoReverbMax_4_3
				move.w	#32767,d7
				bra.s	.NoReverbMin_4_3
.NoReverbMax_4_3
				cmp.l	#-32768,d7
				bge.s	.NoReverbMin_4_3
				move.w	#-32768,d7
.NoReverbMin_4_3
				move.w	d7,d1
				move.l	(sp)+,d7

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_4_4
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_4_4

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+12(a5),d7
				blt		.Inst4Loop

;----------------------------------------------------------------------------
; Instrument 5 - snare
;----------------------------------------------------------------------------

				moveq	#8,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst5Loop
				; v1 = clone(smp,3, 0)
				moveq	#0,d0
				cmp.l	AK_SmpLen+12(a5),d7
				bge.s	.NoClone_5_1
				move.l	AK_SmpAddr+12(a5),a4
				move.b	(a4,d7.l),d0
				asl.w	#8,d0
.NoClone_5_1

				; v1 = sv_flt_n(1, v1, 32, 127, 1)
				move.w	AK_OpInstance+AK_BPF+0(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				asl.w	#5,d5
				move.w	AK_OpInstance+AK_LPF+0(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_5_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_5_2
				move.w	d4,AK_OpInstance+AK_LPF+0(a5)
				muls	#127,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_5_2
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_5_2
.NoClampMaxHPF_5_2
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_5_2
				move.w	#-32768,d5
.NoClampMinHPF_5_2
				move.w	d5,AK_OpInstance+AK_HPF+0(a5)
				asr.w	#7,d5
				asl.w	#5,d5
				add.w	AK_OpInstance+AK_BPF+0(a5),d5
				bvc.s	.NoClampBPF_5_2
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_5_2
				move.w	d5,AK_OpInstance+AK_BPF+0(a5)
				move.w	AK_OpInstance+AK_HPF+0(a5),d0

				; v1 = onepole_flt(2, v1, 98, 0)
				move.w	AK_OpInstance+6(a5),d5
				move.w	d5,d6
				ext.l	d6
				asr.w	#7,d5
				muls	#98,d5
				sub.l	d5,d6
				move.w	d0,d5
				asr.w	#7,d5
				muls	#98,d5
				add.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxOPF_5_3
				move.w	#32767,d5
				bra.s	.NoClampMinOPF_5_3
.NoClampMaxOPF_5_3
				cmp.l	#-32768,d5
				bge.s	.NoClampMinOPF_5_3
				move.w	#-32768,d5
.NoClampMinOPF_5_3
				move.w	d5,AK_OpInstance+6(a5)
				move.w	d5,d0

				; v1 = reverb(v1, 59, 16)
				move.l	d7,-(sp)
				sub.l	a6,a6
				move.l	a1,a4
				move.w	AK_OpInstance+8(a5),d5
				move.w	(a4,d5.w),d4
				muls	#59,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_5_4_0
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_5_4_0
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#557<<1,d5
				ble.s	.NoReverbReset_5_4_0
				moveq	#0,d5
.NoReverbReset_5_4_0
				move.w  d5,AK_OpInstance+8(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		4096(a1),a4
				move.w	AK_OpInstance+10(a5),d5
				move.w	(a4,d5.w),d4
				muls	#59,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_5_4_1
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_5_4_1
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#593<<1,d5
				ble.s	.NoReverbReset_5_4_1
				moveq	#0,d5
.NoReverbReset_5_4_1
				move.w  d5,AK_OpInstance+10(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		8192(a1),a4
				move.w	AK_OpInstance+12(a5),d5
				move.w	(a4,d5.w),d4
				muls	#59,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_5_4_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_5_4_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#641<<1,d5
				ble.s	.NoReverbReset_5_4_2
				moveq	#0,d5
.NoReverbReset_5_4_2
				move.w  d5,AK_OpInstance+12(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		12288(a1),a4
				move.w	AK_OpInstance+14(a5),d5
				move.w	(a4,d5.w),d4
				muls	#59,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_5_4_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_5_4_3
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#677<<1,d5
				ble.s	.NoReverbReset_5_4_3
				moveq	#0,d5
.NoReverbReset_5_4_3
				move.w  d5,AK_OpInstance+14(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		16384(a1),a4
				move.w	AK_OpInstance+16(a5),d5
				move.w	(a4,d5.w),d4
				muls	#59,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_5_4_4
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_5_4_4
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#709<<1,d5
				ble.s	.NoReverbReset_5_4_4
				moveq	#0,d5
.NoReverbReset_5_4_4
				move.w  d5,AK_OpInstance+16(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		20480(a1),a4
				move.w	AK_OpInstance+18(a5),d5
				move.w	(a4,d5.w),d4
				muls	#59,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_5_4_5
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_5_4_5
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#743<<1,d5
				ble.s	.NoReverbReset_5_4_5
				moveq	#0,d5
.NoReverbReset_5_4_5
				move.w  d5,AK_OpInstance+18(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		24576(a1),a4
				move.w	AK_OpInstance+20(a5),d5
				move.w	(a4,d5.w),d4
				muls	#59,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_5_4_6
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_5_4_6
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#787<<1,d5
				ble.s	.NoReverbReset_5_4_6
				moveq	#0,d5
.NoReverbReset_5_4_6
				move.w  d5,AK_OpInstance+20(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		28672(a1),a4
				move.w	AK_OpInstance+22(a5),d5
				move.w	(a4,d5.w),d4
				muls	#59,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_5_4_7
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_5_4_7
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#809<<1,d5
				ble.s	.NoReverbReset_5_4_7
				moveq	#0,d5
.NoReverbReset_5_4_7
				move.w  d5,AK_OpInstance+22(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				move.l	a6,d7
				cmp.l	#32767,d7
				ble.s	.NoReverbMax_5_4
				move.w	#32767,d7
				bra.s	.NoReverbMin_5_4
.NoReverbMax_5_4
				cmp.l	#-32768,d7
				bge.s	.NoReverbMin_5_4
				move.w	#-32768,d7
.NoReverbMin_5_4
				move.w	d7,d0
				move.l	(sp)+,d7

				; v1 = distortion(v1, 24)
				move.w	d0,d5
				muls	#24,d5
				asr.l	#5,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxDist_5_5
				move.w	#32767,d5
				bra.s	.NoClampMinDist_5_5
.NoClampMaxDist_5_5
				cmp.l	#-32768,d5
				bge.s	.NoClampMinDist_5_5
				move.w	#-32768,d5
.NoClampMinDist_5_5
				asr.w	#1,d5
				move.w	d5,d0
				bge.s	.DistNoAbs_5_5
				neg.w	d5
.DistNoAbs_5_5
				move.w	#32767,d6
				sub.w	d5,d6
				muls	d6,d0
				swap	d0
				asl.w	#3,d0

				; v2 = clone(smp,1, 0)
				moveq	#0,d1
				cmp.l	AK_SmpLen+4(a5),d7
				bge.s	.NoClone_5_6
				move.l	AK_SmpAddr+4(a5),a4
				move.b	(a4,d7.l),d1
				asl.w	#8,d1
.NoClone_5_6

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_5_7
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_5_7

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+16(a5),d7
				blt		.Inst5Loop

;----------------------------------------------------------------------------
; Instrument 6 - hat_short
;----------------------------------------------------------------------------

				moveq	#8,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst6Loop
				; v1 = clone(smp,4, 4)
				move.l	d7,d6
				addq.l	#4,d6
				moveq	#0,d0
				cmp.l	AK_SmpLen+16(a5),d6
				bge.s	.NoClone_6_1
				move.l	AK_SmpAddr+16(a5),a4
				move.b	(a4,d6.l),d0
				asl.w	#8,d0
.NoClone_6_1

				; v1 = sv_flt_n(1, v1, 52, 127, 1)
				move.w	AK_OpInstance+AK_BPF+0(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	#52,d5
				move.w	AK_OpInstance+AK_LPF+0(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_6_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_6_2
				move.w	d4,AK_OpInstance+AK_LPF+0(a5)
				muls	#127,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_6_2
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_6_2
.NoClampMaxHPF_6_2
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_6_2
				move.w	#-32768,d5
.NoClampMinHPF_6_2
				move.w	d5,AK_OpInstance+AK_HPF+0(a5)
				asr.w	#7,d5
				muls	#52,d5
				add.w	AK_OpInstance+AK_BPF+0(a5),d5
				bvc.s	.NoClampBPF_6_2
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_6_2
				move.w	d5,AK_OpInstance+AK_BPF+0(a5)
				move.w	AK_OpInstance+AK_HPF+0(a5),d0

				; v2 = envd(2, 6, 0, 128)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#1677568,d5
				bgt.s   .EnvDNoSustain_6_3
				moveq	#0,d5
.EnvDNoSustain_6_3
				move.l	d5,AK_EnvDValue+0(a5)

				; v1 = mul(v1, v2)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+20(a5),d7
				blt		.Inst6Loop

;----------------------------------------------------------------------------
; Instrument 7 - Zap
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst7Loop
				; v1 = imported_sample(smp,3)
				moveq	#0,d0
				cmp.l	AK_ExtSmpLen+12(a5),d7
				bge.s	.NoClone_7_1
				move.l	AK_ExtSmpAddr+12(a5),a4
				move.b	(a4,d7.l),d0
				asl.w	#8,d0
.NoClone_7_1

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+24(a5),d7
				blt		.Inst7Loop

;----------------------------------------------------------------------------
; Instrument 8 - zap+rev
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst8Loop
				; v1 = clone(smp,6, 0)
				moveq	#0,d0
				cmp.l	AK_SmpLen+24(a5),d7
				bge.s	.NoClone_8_1
				move.l	AK_SmpAddr+24(a5),a4
				move.b	(a4,d7.l),d0
				asl.w	#8,d0
.NoClone_8_1

				; v2 = enva(1, 5, 0, 128)
				move.l	AK_OpInstance+0(a5),d5
				move.l	d5,d1
				swap	d1
				add.l	#2097152,d5
				bvc.s   .EnvANoMax_8_2
				move.l	#32767<<16,d5
.EnvANoMax_8_2
				move.l	d5,AK_OpInstance+0(a5)

				; v2 = mul(v1, v2)
				muls	d0,d1
				add.l	d1,d1
				swap	d1

				; v2 = onepole_flt(3, v2, 24, 1)
				move.w	AK_OpInstance+4(a5),d5
				move.w	d5,d6
				ext.l	d6
				asr.w	#7,d5
				muls	#24,d5
				sub.l	d5,d6
				move.w	d1,d5
				asr.w	#7,d5
				muls	#24,d5
				add.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxOPF_8_4
				move.w	#32767,d5
				bra.s	.NoClampMinOPF_8_4
.NoClampMaxOPF_8_4
				cmp.l	#-32768,d5
				bge.s	.NoClampMinOPF_8_4
				move.w	#-32768,d5
.NoClampMinOPF_8_4
				move.w	d5,AK_OpInstance+4(a5)
				sub.w	d5,d1

				; v2 = reverb(v2, 107, 42)
				move.l	d7,-(sp)
				sub.l	a6,a6
				move.l	a1,a4
				move.w	AK_OpInstance+6(a5),d5
				move.w	(a4,d5.w),d4
				muls	#107,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_8_5_0
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_8_5_0
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#557<<1,d5
				ble.s	.NoReverbReset_8_5_0
				moveq	#0,d5
.NoReverbReset_8_5_0
				move.w  d5,AK_OpInstance+6(a5)
				move.w	d4,d7
				muls	#42,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		4096(a1),a4
				move.w	AK_OpInstance+8(a5),d5
				move.w	(a4,d5.w),d4
				muls	#107,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_8_5_1
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_8_5_1
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#593<<1,d5
				ble.s	.NoReverbReset_8_5_1
				moveq	#0,d5
.NoReverbReset_8_5_1
				move.w  d5,AK_OpInstance+8(a5)
				move.w	d4,d7
				muls	#42,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		8192(a1),a4
				move.w	AK_OpInstance+10(a5),d5
				move.w	(a4,d5.w),d4
				muls	#107,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_8_5_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_8_5_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#641<<1,d5
				ble.s	.NoReverbReset_8_5_2
				moveq	#0,d5
.NoReverbReset_8_5_2
				move.w  d5,AK_OpInstance+10(a5)
				move.w	d4,d7
				muls	#42,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		12288(a1),a4
				move.w	AK_OpInstance+12(a5),d5
				move.w	(a4,d5.w),d4
				muls	#107,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_8_5_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_8_5_3
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#677<<1,d5
				ble.s	.NoReverbReset_8_5_3
				moveq	#0,d5
.NoReverbReset_8_5_3
				move.w  d5,AK_OpInstance+12(a5)
				move.w	d4,d7
				muls	#42,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		16384(a1),a4
				move.w	AK_OpInstance+14(a5),d5
				move.w	(a4,d5.w),d4
				muls	#107,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_8_5_4
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_8_5_4
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#709<<1,d5
				ble.s	.NoReverbReset_8_5_4
				moveq	#0,d5
.NoReverbReset_8_5_4
				move.w  d5,AK_OpInstance+14(a5)
				move.w	d4,d7
				muls	#42,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		20480(a1),a4
				move.w	AK_OpInstance+16(a5),d5
				move.w	(a4,d5.w),d4
				muls	#107,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_8_5_5
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_8_5_5
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#743<<1,d5
				ble.s	.NoReverbReset_8_5_5
				moveq	#0,d5
.NoReverbReset_8_5_5
				move.w  d5,AK_OpInstance+16(a5)
				move.w	d4,d7
				muls	#42,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		24576(a1),a4
				move.w	AK_OpInstance+18(a5),d5
				move.w	(a4,d5.w),d4
				muls	#107,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_8_5_6
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_8_5_6
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#787<<1,d5
				ble.s	.NoReverbReset_8_5_6
				moveq	#0,d5
.NoReverbReset_8_5_6
				move.w  d5,AK_OpInstance+18(a5)
				move.w	d4,d7
				muls	#42,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		28672(a1),a4
				move.w	AK_OpInstance+20(a5),d5
				move.w	(a4,d5.w),d4
				muls	#107,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_8_5_7
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_8_5_7
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#809<<1,d5
				ble.s	.NoReverbReset_8_5_7
				moveq	#0,d5
.NoReverbReset_8_5_7
				move.w  d5,AK_OpInstance+20(a5)
				move.w	d4,d7
				muls	#42,d7
				asr.l	#7,d7
				add.w	d7,a6
				move.l	a6,d7
				cmp.l	#32767,d7
				ble.s	.NoReverbMax_8_5
				move.w	#32767,d7
				bra.s	.NoReverbMin_8_5
.NoReverbMax_8_5
				cmp.l	#-32768,d7
				bge.s	.NoReverbMin_8_5
				move.w	#-32768,d7
.NoReverbMin_8_5
				move.w	d7,d1
				move.l	(sp)+,d7

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_8_6
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_8_6

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+28(a5),d7
				blt		.Inst8Loop

				movem.l a0-a1,-(sp)	;Stash sample base address & large buffer address for loop generator

;----------------------------------------------------------------------------
; Instrument 8 - Loop Generator (Offset: 4562 Length: 3630
;----------------------------------------------------------------------------

				move.l	#3630,d7
				move.l	AK_SmpAddr+28(a5),a0
				lea		4562(a0),a0
				move.l	a0,a1
				sub.l	d7,a1
				moveq	#0,d4
				move.l	#32767<<8,d5
				move.l	d5,d0
				divs	d7,d0
				bvc.s	.LoopGenVC_7
				moveq	#0,d0
.LoopGenVC_7
				moveq	#0,d6
				move.w	d0,d6
.LoopGen_7
				move.l	d4,d2
				asr.l	#8,d2
				move.l	d5,d3
				asr.l	#8,d3
				move.b	(a0),d0
				move.b	(a1)+,d1
				ext.w	d0
				ext.w	d1
				muls	d3,d0
				muls	d2,d1
				add.l	d1,d0
				add.l	d0,d0
				swap	d0
				move.b	d0,(a0)+
				add.l	d6,d4
				sub.l	d6,d5

				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif

				subq.l	#1,d7
				bne.s	.LoopGen_7

				movem.l (sp)+,a0-a1	;Restore sample base address & large buffer address after loop generator

;----------------------------------------------------------------------------
; Instrument 9 - kickbass1
;----------------------------------------------------------------------------

				moveq	#8,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst9Loop
				; v1 = clone(smp,0, 200)
				move.l	d7,d6
				add.l	#200,d6
				moveq	#0,d0
				cmp.l	AK_SmpLen+0(a5),d6
				bge.s	.NoClone_9_1
				move.l	AK_SmpAddr+0(a5),a4
				move.b	(a4,d6.l),d0
				asl.w	#8,d0
.NoClone_9_1

				; v1 = cmb_flt_n(1, v1, 256, 118, 128)
				move.l	a1,a4
				move.w	AK_OpInstance+0(a5),d5
				move.w	(a4,d5.w),d4
				muls	#118,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.CombAddNoClamp_9_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.CombAddNoClamp_9_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#256<<1,d5
				blt.s	.NoCombReset_9_2
				moveq	#0,d5
.NoCombReset_9_2
				move.w  d5,AK_OpInstance+0(a5)
				move.w	d4,d0

				; v2 = envd(2, 12, 12, 128)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#441344,d5
				cmp.l	#201326592,d5
				bgt.s   .EnvDNoSustain_9_3
				move.l	#201326592,d5
.EnvDNoSustain_9_3
				move.l	d5,AK_EnvDValue+0(a5)

				; v2 = mul(v2, 128)
				muls	#128,d1
				add.l	d1,d1
				swap	d1

				; v1 = sv_flt_n(4, v1, v2, 64, 0)
				move.w	AK_OpInstance+AK_BPF+2(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	d1,d5
				move.w	AK_OpInstance+AK_LPF+2(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_9_5
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_9_5
				move.w	d4,AK_OpInstance+AK_LPF+2(a5)
				asl.w	#6,d6
				ext.l	d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_9_5
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_9_5
.NoClampMaxHPF_9_5
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_9_5
				move.w	#-32768,d5
.NoClampMinHPF_9_5
				move.w	d5,AK_OpInstance+AK_HPF+2(a5)
				asr.w	#7,d5
				muls	d1,d5
				add.w	AK_OpInstance+AK_BPF+2(a5),d5
				bvc.s	.NoClampBPF_9_5
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_9_5
				move.w	d5,AK_OpInstance+AK_BPF+2(a5)
				move.w	AK_OpInstance+AK_LPF+2(a5),d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+32(a5),d7
				blt		.Inst9Loop

;----------------------------------------------------------------------------
; Instrument 10 - kickbass_reverse
;----------------------------------------------------------------------------

				moveq	#1,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst10Loop
				; v1 = clone_reverse(smp,0, 200)
				move.l	d7,d6
				add.l	#200,d6
				moveq	#0,d0
				cmp.l	AK_SmpLen+0(a5),d6
				bge.s	.NoClone_10_1
				move.l	AK_SmpAddr+0+4(a5),a4
				neg.l	d6
				move.b	-1(a4,d6.l),d0
				asl.w	#8,d0
.NoClone_10_1

				; v1 = cmb_flt_n(1, v1, 256, 118, 128)
				move.l	a1,a4
				move.w	AK_OpInstance+0(a5),d5
				move.w	(a4,d5.w),d4
				muls	#118,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.CombAddNoClamp_10_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.CombAddNoClamp_10_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#256<<1,d5
				blt.s	.NoCombReset_10_2
				moveq	#0,d5
.NoCombReset_10_2
				move.w  d5,AK_OpInstance+0(a5)
				move.w	d4,d0

				; v2 = envd(2, 12, 12, 128)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#441344,d5
				cmp.l	#201326592,d5
				bgt.s   .EnvDNoSustain_10_3
				move.l	#201326592,d5
.EnvDNoSustain_10_3
				move.l	d5,AK_EnvDValue+0(a5)

				; v2 = mul(v2, 128)
				muls	#128,d1
				add.l	d1,d1
				swap	d1

				; v1 = sv_flt_n(4, v1, v2, 64, 0)
				move.w	AK_OpInstance+AK_BPF+2(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	d1,d5
				move.w	AK_OpInstance+AK_LPF+2(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_10_5
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_10_5
				move.w	d4,AK_OpInstance+AK_LPF+2(a5)
				asl.w	#6,d6
				ext.l	d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_10_5
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_10_5
.NoClampMaxHPF_10_5
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_10_5
				move.w	#-32768,d5
.NoClampMinHPF_10_5
				move.w	d5,AK_OpInstance+AK_HPF+2(a5)
				asr.w	#7,d5
				muls	d1,d5
				add.w	AK_OpInstance+AK_BPF+2(a5),d5
				bvc.s	.NoClampBPF_10_5
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_10_5
				move.w	d5,AK_OpInstance+AK_BPF+2(a5)
				move.w	AK_OpInstance+AK_LPF+2(a5),d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+36(a5),d7
				blt		.Inst10Loop

;----------------------------------------------------------------------------
; Instrument 11 - sfx1
;----------------------------------------------------------------------------

				moveq	#1,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst11Loop
				; v1 = osc_noise(61)
				move.l	AK_NoiseSeeds+0(a5),d4
				move.l	AK_NoiseSeeds+4(a5),d5
				eor.l	d5,d4
				move.l	d4,AK_NoiseSeeds+0(a5)
				add.l	d5,AK_NoiseSeeds+8(a5)
				add.l	d4,AK_NoiseSeeds+4(a5)
				move.w	AK_NoiseSeeds+10(a5),d0
				muls	#61,d0
				asr.l	#7,d0

				; v2 = osc_saw(1, 512, 128)
				add.w	#512,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d1

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_11_3
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_11_3

				; v3 = envd(3, 19, 11, 1)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d2
				swap	d2
				sub.l	#182272,d5
				cmp.l	#184549376,d5
				bgt.s   .EnvDNoSustain_11_4
				move.l	#184549376,d5
.EnvDNoSustain_11_4
				move.l	d5,AK_EnvDValue+0(a5)
				asr.w	#7,d2

				; v2 = osc_sine(4, v3, 128)
				add.w	d2,AK_OpInstance+2(a5)
				move.w	AK_OpInstance+2(a5),d1
				sub.w	#16384,d1
				move.w	d1,d5
				bge.s	.SineNoAbs_11_5
				neg.w	d5
.SineNoAbs_11_5
				move.w	#32767,d6
				sub.w	d5,d6
				muls	d6,d1
				swap	d1
				asl.w	#3,d1

				; v2 = ctrl(v2)
				moveq	#9,d4
				asr.w	d4,d1
				add.w	#64,d1

				; v1 = sv_flt_n(6, v1, v2, 64, 0)
				move.w	AK_OpInstance+AK_BPF+4(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	d1,d5
				move.w	AK_OpInstance+AK_LPF+4(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_11_7
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_11_7
				move.w	d4,AK_OpInstance+AK_LPF+4(a5)
				asl.w	#6,d6
				ext.l	d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_11_7
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_11_7
.NoClampMaxHPF_11_7
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_11_7
				move.w	#-32768,d5
.NoClampMinHPF_11_7
				move.w	d5,AK_OpInstance+AK_HPF+4(a5)
				asr.w	#7,d5
				muls	d1,d5
				add.w	AK_OpInstance+AK_BPF+4(a5),d5
				bvc.s	.NoClampBPF_11_7
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_11_7
				move.w	d5,AK_OpInstance+AK_BPF+4(a5)
				move.w	AK_OpInstance+AK_LPF+4(a5),d0

				; v1 = sv_flt_n(7, v1, 64, 127, 1)
				move.w	AK_OpInstance+AK_BPF+10(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				asl.w	#6,d5
				move.w	AK_OpInstance+AK_LPF+10(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_11_8
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_11_8
				move.w	d4,AK_OpInstance+AK_LPF+10(a5)
				muls	#127,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_11_8
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_11_8
.NoClampMaxHPF_11_8
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_11_8
				move.w	#-32768,d5
.NoClampMinHPF_11_8
				move.w	d5,AK_OpInstance+AK_HPF+10(a5)
				asr.w	#7,d5
				asl.w	#6,d5
				add.w	AK_OpInstance+AK_BPF+10(a5),d5
				bvc.s	.NoClampBPF_11_8
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_11_8
				move.w	d5,AK_OpInstance+AK_BPF+10(a5)
				move.w	AK_OpInstance+AK_HPF+10(a5),d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+40(a5),d7
				blt		.Inst11Loop

				movem.l a0-a1,-(sp)	;Stash sample base address & large buffer address for loop generator

;----------------------------------------------------------------------------
; Instrument 11 - Loop Generator (Offset: 9416 Length: 1336
;----------------------------------------------------------------------------

				move.l	#1336,d7
				move.l	AK_SmpAddr+40(a5),a0
				lea		9416(a0),a0
				move.l	a0,a1
				sub.l	d7,a1
				moveq	#0,d4
				move.l	#32767<<8,d5
				move.l	d5,d0
				divs	d7,d0
				bvc.s	.LoopGenVC_10
				moveq	#0,d0
.LoopGenVC_10
				moveq	#0,d6
				move.w	d0,d6
.LoopGen_10
				move.l	d4,d2
				asr.l	#8,d2
				move.l	d5,d3
				asr.l	#8,d3
				move.b	(a0),d0
				move.b	(a1)+,d1
				ext.w	d0
				ext.w	d1
				muls	d3,d0
				muls	d2,d1
				add.l	d1,d0
				add.l	d0,d0
				swap	d0
				move.b	d0,(a0)+
				add.l	d6,d4
				sub.l	d6,d5

				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif

				subq.l	#1,d7
				bne.s	.LoopGen_10

				movem.l (sp)+,a0-a1	;Restore sample base address & large buffer address after loop generator

;----------------------------------------------------------------------------
; Instrument 12 - sfx2
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst12Loop
				; v1 = osc_noise(128)
				move.l	AK_NoiseSeeds+0(a5),d4
				move.l	AK_NoiseSeeds+4(a5),d5
				eor.l	d5,d4
				move.l	d4,AK_NoiseSeeds+0(a5)
				add.l	d5,AK_NoiseSeeds+8(a5)
				add.l	d4,AK_NoiseSeeds+4(a5)
				move.w	AK_NoiseSeeds+10(a5),d0

				; v1 = add(v1, 32767)
				add.w	#32767,d0
				bvc.s	.AddNoClamp_12_2
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_12_2

				; v1 = sv_flt_n(2, v1, 6, 0, 1)
				move.w	AK_OpInstance+AK_BPF+0(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	#6,d5
				move.w	AK_OpInstance+AK_LPF+0(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_12_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_12_3
				move.w	d4,AK_OpInstance+AK_LPF+0(a5)
				muls	#0,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_12_3
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_12_3
.NoClampMaxHPF_12_3
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_12_3
				move.w	#-32768,d5
.NoClampMinHPF_12_3
				move.w	d5,AK_OpInstance+AK_HPF+0(a5)
				asr.w	#7,d5
				muls	#6,d5
				add.w	AK_OpInstance+AK_BPF+0(a5),d5
				bvc.s	.NoClampBPF_12_3
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_12_3
				move.w	d5,AK_OpInstance+AK_BPF+0(a5)
				move.w	AK_OpInstance+AK_HPF+0(a5),d0

				; v1 = sh(3, v1, 24)
				sub.w	#1,AK_OpInstance+6(a5)
				bge.s	.SHNoStore_12_4
				move.w	d0,AK_OpInstance+8(a5)
				move.w	#144,AK_OpInstance+6(a5)
.SHNoStore_12_4
				move.w	AK_OpInstance+8(a5),d0

				; v1 = osc_sine(4, v1, 80)
				add.w	d0,AK_OpInstance+10(a5)
				move.w	AK_OpInstance+10(a5),d0
				sub.w	#16384,d0
				move.w	d0,d5
				bge.s	.SineNoAbs_12_5
				neg.w	d5
.SineNoAbs_12_5
				move.w	#32767,d6
				sub.w	d5,d6
				muls	d6,d0
				swap	d0
				asl.w	#3,d0
				muls	#80,d0
				asr.l	#7,d0

				; v1 = sv_flt_n(5, v1, 64, 127, 1)
				move.w	AK_OpInstance+AK_BPF+12(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				asl.w	#6,d5
				move.w	AK_OpInstance+AK_LPF+12(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_12_6
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_12_6
				move.w	d4,AK_OpInstance+AK_LPF+12(a5)
				muls	#127,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_12_6
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_12_6
.NoClampMaxHPF_12_6
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_12_6
				move.w	#-32768,d5
.NoClampMinHPF_12_6
				move.w	d5,AK_OpInstance+AK_HPF+12(a5)
				asr.w	#7,d5
				asl.w	#6,d5
				add.w	AK_OpInstance+AK_BPF+12(a5),d5
				bvc.s	.NoClampBPF_12_6
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_12_6
				move.w	d5,AK_OpInstance+AK_BPF+12(a5)
				move.w	AK_OpInstance+AK_HPF+12(a5),d0

				; v1 = reverb(v1, 80, 14)
				move.l	d7,-(sp)
				sub.l	a6,a6
				move.l	a1,a4
				move.w	AK_OpInstance+18(a5),d5
				move.w	(a4,d5.w),d4
				muls	#80,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_12_7_0
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_12_7_0
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#557<<1,d5
				ble.s	.NoReverbReset_12_7_0
				moveq	#0,d5
.NoReverbReset_12_7_0
				move.w  d5,AK_OpInstance+18(a5)
				move.w	d4,d7
				muls	#14,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		4096(a1),a4
				move.w	AK_OpInstance+20(a5),d5
				move.w	(a4,d5.w),d4
				muls	#80,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_12_7_1
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_12_7_1
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#593<<1,d5
				ble.s	.NoReverbReset_12_7_1
				moveq	#0,d5
.NoReverbReset_12_7_1
				move.w  d5,AK_OpInstance+20(a5)
				move.w	d4,d7
				muls	#14,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		8192(a1),a4
				move.w	AK_OpInstance+22(a5),d5
				move.w	(a4,d5.w),d4
				muls	#80,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_12_7_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_12_7_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#641<<1,d5
				ble.s	.NoReverbReset_12_7_2
				moveq	#0,d5
.NoReverbReset_12_7_2
				move.w  d5,AK_OpInstance+22(a5)
				move.w	d4,d7
				muls	#14,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		12288(a1),a4
				move.w	AK_OpInstance+24(a5),d5
				move.w	(a4,d5.w),d4
				muls	#80,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_12_7_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_12_7_3
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#677<<1,d5
				ble.s	.NoReverbReset_12_7_3
				moveq	#0,d5
.NoReverbReset_12_7_3
				move.w  d5,AK_OpInstance+24(a5)
				move.w	d4,d7
				muls	#14,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		16384(a1),a4
				move.w	AK_OpInstance+26(a5),d5
				move.w	(a4,d5.w),d4
				muls	#80,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_12_7_4
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_12_7_4
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#709<<1,d5
				ble.s	.NoReverbReset_12_7_4
				moveq	#0,d5
.NoReverbReset_12_7_4
				move.w  d5,AK_OpInstance+26(a5)
				move.w	d4,d7
				muls	#14,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		20480(a1),a4
				move.w	AK_OpInstance+28(a5),d5
				move.w	(a4,d5.w),d4
				muls	#80,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_12_7_5
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_12_7_5
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#743<<1,d5
				ble.s	.NoReverbReset_12_7_5
				moveq	#0,d5
.NoReverbReset_12_7_5
				move.w  d5,AK_OpInstance+28(a5)
				move.w	d4,d7
				muls	#14,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		24576(a1),a4
				move.w	AK_OpInstance+30(a5),d5
				move.w	(a4,d5.w),d4
				muls	#80,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_12_7_6
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_12_7_6
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#787<<1,d5
				ble.s	.NoReverbReset_12_7_6
				moveq	#0,d5
.NoReverbReset_12_7_6
				move.w  d5,AK_OpInstance+30(a5)
				move.w	d4,d7
				muls	#14,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		28672(a1),a4
				move.w	AK_OpInstance+32(a5),d5
				move.w	(a4,d5.w),d4
				muls	#80,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_12_7_7
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_12_7_7
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#809<<1,d5
				ble.s	.NoReverbReset_12_7_7
				moveq	#0,d5
.NoReverbReset_12_7_7
				move.w  d5,AK_OpInstance+32(a5)
				move.w	d4,d7
				muls	#14,d7
				asr.l	#7,d7
				add.w	d7,a6
				move.l	a6,d7
				cmp.l	#32767,d7
				ble.s	.NoReverbMax_12_7
				move.w	#32767,d7
				bra.s	.NoReverbMin_12_7
.NoReverbMax_12_7
				cmp.l	#-32768,d7
				bge.s	.NoReverbMin_12_7
				move.w	#-32768,d7
.NoReverbMin_12_7
				move.w	d7,d0
				move.l	(sp)+,d7

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+44(a5),d7
				blt		.Inst12Loop

				movem.l a0-a1,-(sp)	;Stash sample base address & large buffer address for loop generator

;----------------------------------------------------------------------------
; Instrument 12 - Loop Generator (Offset: 4096 Length: 4096
;----------------------------------------------------------------------------

				move.l	#4096,d7
				move.l	AK_SmpAddr+44(a5),a0
				lea		4096(a0),a0
				move.l	a0,a1
				sub.l	d7,a1
				moveq	#0,d4
				move.l	#32767<<8,d5
				move.l	d5,d0
				divs	d7,d0
				bvc.s	.LoopGenVC_11
				moveq	#0,d0
.LoopGenVC_11
				moveq	#0,d6
				move.w	d0,d6
.LoopGen_11
				move.l	d4,d2
				asr.l	#8,d2
				move.l	d5,d3
				asr.l	#8,d3
				move.b	(a0),d0
				move.b	(a1)+,d1
				ext.w	d0
				ext.w	d1
				muls	d3,d0
				muls	d2,d1
				add.l	d1,d0
				add.l	d0,d0
				swap	d0
				move.b	d0,(a0)+
				add.l	d6,d4
				sub.l	d6,d5

				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif

				subq.l	#1,d7
				bne.s	.LoopGen_11

				movem.l (sp)+,a0-a1	;Restore sample base address & large buffer address after loop generator

;----------------------------------------------------------------------------
; Instrument 13 - Virgill_SFX_Ship
;----------------------------------------------------------------------------

				moveq	#8,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst13Loop
				; v1 = clone(smp,10, 38)
				move.l	d7,d6
				add.l	#38,d6
				moveq	#0,d0
				cmp.l	AK_SmpLen+40(a5),d6
				bge.s	.NoClone_13_1
				move.l	AK_SmpAddr+40(a5),a4
				move.b	(a4,d6.l),d0
				asl.w	#8,d0
.NoClone_13_1

				; v1 = cmb_flt_n(1, v1, 208, 127, 128)
				move.l	a1,a4
				move.w	AK_OpInstance+0(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.CombAddNoClamp_13_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.CombAddNoClamp_13_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#208<<1,d5
				blt.s	.NoCombReset_13_2
				moveq	#0,d5
.NoCombReset_13_2
				move.w  d5,AK_OpInstance+0(a5)
				move.w	d4,d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+48(a5),d7
				blt		.Inst13Loop

				movem.l a0-a1,-(sp)	;Stash sample base address & large buffer address for loop generator

;----------------------------------------------------------------------------
; Instrument 13 - Loop Generator (Offset: 511 Length: 513
;----------------------------------------------------------------------------

				move.l	#513,d7
				move.l	AK_SmpAddr+48(a5),a0
				lea		511(a0),a0
				move.l	a0,a1
				sub.l	d7,a1
				moveq	#0,d4
				move.l	#32767<<8,d5
				move.l	d5,d0
				divs	d7,d0
				bvc.s	.LoopGenVC_12
				moveq	#0,d0
.LoopGenVC_12
				moveq	#0,d6
				move.w	d0,d6
.LoopGen_12
				move.l	d4,d2
				asr.l	#8,d2
				move.l	d5,d3
				asr.l	#8,d3
				move.b	(a0),d0
				move.b	(a1)+,d1
				ext.w	d0
				ext.w	d1
				muls	d3,d0
				muls	d2,d1
				add.l	d1,d0
				add.l	d0,d0
				swap	d0
				move.b	d0,(a0)+
				add.l	d6,d4
				sub.l	d6,d5

				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif

				subq.l	#1,d7
				bne.s	.LoopGen_12

				movem.l (sp)+,a0-a1	;Restore sample base address & large buffer address after loop generator

;----------------------------------------------------------------------------
; Empty Instrument
;----------------------------------------------------------------------------

				addq.w	#2,a0
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					else
						addq.l	#2,(a3)
					endif
				endif

;----------------------------------------------------------------------------
; Empty Instrument
;----------------------------------------------------------------------------

				addq.w	#2,a0
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					else
						addq.l	#2,(a3)
					endif
				endif

;----------------------------------------------------------------------------
; Instrument 16 - daftpunklead
;----------------------------------------------------------------------------

				moveq	#1,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst16Loop
				; v1 = osc_saw(0, 2048, 93)
				add.w	#2048,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d0
				muls	#93,d0
				asr.l	#7,d0

				; v2 = osc_noise(8)
				move.l	AK_NoiseSeeds+0(a5),d4
				move.l	AK_NoiseSeeds+4(a5),d5
				eor.l	d5,d4
				move.l	d4,AK_NoiseSeeds+0(a5)
				add.l	d5,AK_NoiseSeeds+8(a5)
				add.l	d4,AK_NoiseSeeds+4(a5)
				move.w	AK_NoiseSeeds+10(a5),d1
				asr.w	#4,d1

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_16_3
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_16_3

				; v3 = envd(3, 28, 0, 128)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d2
				swap	d2
				sub.l	#84480,d5
				bgt.s   .EnvDNoSustain_16_4
				moveq	#0,d5
.EnvDNoSustain_16_4
				move.l	d5,AK_EnvDValue+0(a5)

				; v3 = mul(v3, 96)
				muls	#96,d2
				add.l	d2,d2
				swap	d2

				; v3 = add(v3, 0)
				add.w	#0,d2
				bvc.s	.AddNoClamp_16_6
				spl		d2
				ext.w	d2
				eor.w	#$7fff,d2
.AddNoClamp_16_6

				; v2 = osc_pulse(6, 256, 128, 16)
				add.w	#256,AK_OpInstance+2(a5)
				cmp.w	#((16-63)<<9),AK_OpInstance+2(a5)
				slt		d1
				ext.w	d1
				eor.w	#$7fff,d1

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_16_8
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_16_8

				; v1 = sv_flt_n(8, v1, v3, 64, 3)
				move.w	AK_OpInstance+AK_BPF+4(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	d2,d5
				move.w	AK_OpInstance+AK_LPF+4(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_16_9
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_16_9
				move.w	d4,AK_OpInstance+AK_LPF+4(a5)
				asl.w	#6,d6
				ext.l	d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_16_9
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_16_9
.NoClampMaxHPF_16_9
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_16_9
				move.w	#-32768,d5
.NoClampMinHPF_16_9
				move.w	d5,AK_OpInstance+AK_HPF+4(a5)
				asr.w	#7,d5
				muls	d2,d5
				add.w	AK_OpInstance+AK_BPF+4(a5),d5
				bvc.s	.NoClampBPF_16_9
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_16_9
				move.w	d5,AK_OpInstance+AK_BPF+4(a5)
				move.w	AK_OpInstance+AK_HPF+4(a5),d0
				add.w	d0,d0
				bvc.s	.NoClampMode3_16_9
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.NoClampMode3_16_9

				; v1 = sv_flt_n(9, v1, 24, 127, 1)
				move.w	AK_OpInstance+AK_BPF+10(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	#24,d5
				move.w	AK_OpInstance+AK_LPF+10(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_16_10
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_16_10
				move.w	d4,AK_OpInstance+AK_LPF+10(a5)
				muls	#127,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_16_10
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_16_10
.NoClampMaxHPF_16_10
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_16_10
				move.w	#-32768,d5
.NoClampMinHPF_16_10
				move.w	d5,AK_OpInstance+AK_HPF+10(a5)
				asr.w	#7,d5
				muls	#24,d5
				add.w	AK_OpInstance+AK_BPF+10(a5),d5
				bvc.s	.NoClampBPF_16_10
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_16_10
				move.w	d5,AK_OpInstance+AK_BPF+10(a5)
				move.w	AK_OpInstance+AK_HPF+10(a5),d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+60(a5),d7
				blt		.Inst16Loop

				movem.l a0-a1,-(sp)	;Stash sample base address & large buffer address for loop generator

;----------------------------------------------------------------------------
; Instrument 16 - Loop Generator (Offset: 12288 Length: 12288
;----------------------------------------------------------------------------

				move.l	#12288,d7
				move.l	AK_SmpAddr+60(a5),a0
				lea		12288(a0),a0
				move.l	a0,a1
				sub.l	d7,a1
				moveq	#0,d4
				move.l	#32767<<8,d5
				move.l	d5,d0
				divs	d7,d0
				bvc.s	.LoopGenVC_15
				moveq	#0,d0
.LoopGenVC_15
				moveq	#0,d6
				move.w	d0,d6
.LoopGen_15
				move.l	d4,d2
				asr.l	#8,d2
				move.l	d5,d3
				asr.l	#8,d3
				move.b	(a0),d0
				move.b	(a1)+,d1
				ext.w	d0
				ext.w	d1
				muls	d3,d0
				muls	d2,d1
				add.l	d1,d0
				add.l	d0,d0
				swap	d0
				move.b	d0,(a0)+
				add.l	d6,d4
				sub.l	d6,d5

				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif

				subq.l	#1,d7
				bne.s	.LoopGen_15

				movem.l (sp)+,a0-a1	;Restore sample base address & large buffer address after loop generator

;----------------------------------------------------------------------------
; Instrument 17 - plingreverb
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst17Loop
				; v1 = clone(smp,15, 5110)
				move.l	d7,d6
				add.l	#5110,d6
				moveq	#0,d0
				cmp.l	AK_SmpLen+60(a5),d6
				bge.s	.NoClone_17_1
				move.l	AK_SmpAddr+60(a5),a4
				move.b	(a4,d6.l),d0
				asl.w	#8,d0
.NoClone_17_1

				; v2 = adsr(1, 8388352, 3639, 0, 9981, 0, 8388352)
				move.l	AK_OpInstance+0(a5),d1
				move.w	AK_OpInstance+4(a5),d4
				beq.s	.ADSR_A_17_2
				subq.w	#1,d4
				beq.s	.ADSR_D_17_2
				subq.w	#1,d4
				beq.s	.ADSR_S_17_2
.ADSR_R_17_2
				sub.l	#0,d1
				bge.s	.ADSR_End_17_2
				moveq	#0,d1
				bra.s	.ADSR_End_17_2
.ADSR_A_17_2
				add.l	#8388352,d1
				cmp.l	#8388352,d1
				blt.s	.ADSR_End_17_2
				move.l	#8388352,d1
				move.w	#1,AK_OpInstance+4(a5)
				bra.s	.ADSR_End_17_2
.ADSR_D_17_2
				sub.l	#3639,d1
				cmp.l	#0,d1
				bgt.s	.ADSR_End_17_2
				move.l	#0,d1
				move.l	#9981,AK_OpInstance+6(a5)
				move.w	#2,AK_OpInstance+4(a5)
				bra.s	.ADSR_End_17_2
.ADSR_S_17_2
				subq.l	#1,AK_OpInstance+6(a5)
				bge.s	.ADSR_End_17_2
				move.w	#3,AK_OpInstance+4(a5)
.ADSR_End_17_2
				move.l	d1,AK_OpInstance+0(a5)
				asr.l	#8,d1

				; v1 = mul(v1, v2)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				; v1 = reverb(v1, 127, 16)
				move.l	d7,-(sp)
				sub.l	a6,a6
				move.l	a1,a4
				move.w	AK_OpInstance+10(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_17_4_0
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_17_4_0
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#557<<1,d5
				ble.s	.NoReverbReset_17_4_0
				moveq	#0,d5
.NoReverbReset_17_4_0
				move.w  d5,AK_OpInstance+10(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		4096(a1),a4
				move.w	AK_OpInstance+12(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_17_4_1
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_17_4_1
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#593<<1,d5
				ble.s	.NoReverbReset_17_4_1
				moveq	#0,d5
.NoReverbReset_17_4_1
				move.w  d5,AK_OpInstance+12(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		8192(a1),a4
				move.w	AK_OpInstance+14(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_17_4_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_17_4_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#641<<1,d5
				ble.s	.NoReverbReset_17_4_2
				moveq	#0,d5
.NoReverbReset_17_4_2
				move.w  d5,AK_OpInstance+14(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		12288(a1),a4
				move.w	AK_OpInstance+16(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_17_4_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_17_4_3
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#677<<1,d5
				ble.s	.NoReverbReset_17_4_3
				moveq	#0,d5
.NoReverbReset_17_4_3
				move.w  d5,AK_OpInstance+16(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		16384(a1),a4
				move.w	AK_OpInstance+18(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_17_4_4
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_17_4_4
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#709<<1,d5
				ble.s	.NoReverbReset_17_4_4
				moveq	#0,d5
.NoReverbReset_17_4_4
				move.w  d5,AK_OpInstance+18(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		20480(a1),a4
				move.w	AK_OpInstance+20(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_17_4_5
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_17_4_5
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#743<<1,d5
				ble.s	.NoReverbReset_17_4_5
				moveq	#0,d5
.NoReverbReset_17_4_5
				move.w  d5,AK_OpInstance+20(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		24576(a1),a4
				move.w	AK_OpInstance+22(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_17_4_6
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_17_4_6
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#787<<1,d5
				ble.s	.NoReverbReset_17_4_6
				moveq	#0,d5
.NoReverbReset_17_4_6
				move.w  d5,AK_OpInstance+22(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				lea		28672(a1),a4
				move.w	AK_OpInstance+24(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_17_4_7
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_17_4_7
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#809<<1,d5
				ble.s	.NoReverbReset_17_4_7
				moveq	#0,d5
.NoReverbReset_17_4_7
				move.w  d5,AK_OpInstance+24(a5)
				move.w	d4,d7
				asr.w	#3,d7
				add.w	d7,a6
				move.l	a6,d7
				cmp.l	#32767,d7
				ble.s	.NoReverbMax_17_4
				move.w	#32767,d7
				bra.s	.NoReverbMin_17_4
.NoReverbMax_17_4
				cmp.l	#-32768,d7
				bge.s	.NoReverbMin_17_4
				move.w	#-32768,d7
.NoReverbMin_17_4
				move.w	d7,d0
				move.l	(sp)+,d7

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+64(a5),d7
				blt		.Inst17Loop

				movem.l a0-a1,-(sp)	;Stash sample base address & large buffer address for loop generator

;----------------------------------------------------------------------------
; Instrument 17 - Loop Generator (Offset: 6144 Length: 6144
;----------------------------------------------------------------------------

				move.l	#6144,d7
				move.l	AK_SmpAddr+64(a5),a0
				lea		6144(a0),a0
				move.l	a0,a1
				sub.l	d7,a1
				moveq	#0,d4
				move.l	#32767<<8,d5
				move.l	d5,d0
				divs	d7,d0
				bvc.s	.LoopGenVC_16
				moveq	#0,d0
.LoopGenVC_16
				moveq	#0,d6
				move.w	d0,d6
.LoopGen_16
				move.l	d4,d2
				asr.l	#8,d2
				move.l	d5,d3
				asr.l	#8,d3
				move.b	(a0),d0
				move.b	(a1)+,d1
				ext.w	d0
				ext.w	d1
				muls	d3,d0
				muls	d2,d1
				add.l	d1,d0
				add.l	d0,d0
				swap	d0
				move.b	d0,(a0)+
				add.l	d6,d4
				sub.l	d6,d5

				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif

				subq.l	#1,d7
				bne.s	.LoopGen_16

				movem.l (sp)+,a0-a1	;Restore sample base address & large buffer address after loop generator

;----------------------------------------------------------------------------
; Instrument 18 - bass_long
;----------------------------------------------------------------------------

				moveq	#8,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst18Loop
				; v1 = osc_saw(0, 512, 128)
				add.w	#512,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d0

				; v2 = osc_saw(1, 2050, 128)
				add.w	#2050,AK_OpInstance+2(a5)
				move.w	AK_OpInstance+2(a5),d1

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_18_3
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_18_3

				; v2 = envd(3, 11, 24, 128)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#524288,d5
				cmp.l	#402653184,d5
				bgt.s   .EnvDNoSustain_18_4
				move.l	#402653184,d5
.EnvDNoSustain_18_4
				move.l	d5,AK_EnvDValue+0(a5)

				; v2 = mul(v2, 128)
				muls	#128,d1
				add.l	d1,d1
				swap	d1

				; v1 = sv_flt_n(5, v1, v2, 127, 0)
				move.w	AK_OpInstance+AK_BPF+4(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	d1,d5
				move.w	AK_OpInstance+AK_LPF+4(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_18_6
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_18_6
				move.w	d4,AK_OpInstance+AK_LPF+4(a5)
				muls	#127,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_18_6
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_18_6
.NoClampMaxHPF_18_6
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_18_6
				move.w	#-32768,d5
.NoClampMinHPF_18_6
				move.w	d5,AK_OpInstance+AK_HPF+4(a5)
				asr.w	#7,d5
				muls	d1,d5
				add.w	AK_OpInstance+AK_BPF+4(a5),d5
				bvc.s	.NoClampBPF_18_6
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_18_6
				move.w	d5,AK_OpInstance+AK_BPF+4(a5)
				move.w	AK_OpInstance+AK_LPF+4(a5),d0

				; v1 = distortion(v1, 64)
				move.w	d0,d5
				ext.l	d5
				asl.l	#6,d5
				asr.l	#5,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxDist_18_7
				move.w	#32767,d5
				bra.s	.NoClampMinDist_18_7
.NoClampMaxDist_18_7
				cmp.l	#-32768,d5
				bge.s	.NoClampMinDist_18_7
				move.w	#-32768,d5
.NoClampMinDist_18_7
				asr.w	#1,d5
				move.w	d5,d0
				bge.s	.DistNoAbs_18_7
				neg.w	d5
.DistNoAbs_18_7
				move.w	#32767,d6
				sub.w	d5,d6
				muls	d6,d0
				swap	d0
				asl.w	#3,d0

				; v1 = sv_flt_n(7, v1, 7, 127, 1)
				move.w	AK_OpInstance+AK_BPF+10(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	#7,d5
				move.w	AK_OpInstance+AK_LPF+10(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_18_8
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_18_8
				move.w	d4,AK_OpInstance+AK_LPF+10(a5)
				muls	#127,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_18_8
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_18_8
.NoClampMaxHPF_18_8
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_18_8
				move.w	#-32768,d5
.NoClampMinHPF_18_8
				move.w	d5,AK_OpInstance+AK_HPF+10(a5)
				asr.w	#7,d5
				muls	#7,d5
				add.w	AK_OpInstance+AK_BPF+10(a5),d5
				bvc.s	.NoClampBPF_18_8
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_18_8
				move.w	d5,AK_OpInstance+AK_BPF+10(a5)
				move.w	AK_OpInstance+AK_HPF+10(a5),d0

				; v1 = vol(v1, 64)
				asr.w	#1,d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+68(a5),d7
				blt		.Inst18Loop

				movem.l a0-a1,-(sp)	;Stash sample base address & large buffer address for loop generator

;----------------------------------------------------------------------------
; Instrument 18 - Loop Generator (Offset: 16384 Length: 16384
;----------------------------------------------------------------------------

				move.l	#16384,d7
				move.l	AK_SmpAddr+68(a5),a0
				lea		16384(a0),a0
				move.l	a0,a1
				sub.l	d7,a1
				moveq	#0,d4
				move.l	#32767<<8,d5
				move.l	d5,d0
				divs	d7,d0
				bvc.s	.LoopGenVC_17
				moveq	#0,d0
.LoopGenVC_17
				moveq	#0,d6
				move.w	d0,d6
.LoopGen_17
				move.l	d4,d2
				asr.l	#8,d2
				move.l	d5,d3
				asr.l	#8,d3
				move.b	(a0),d0
				move.b	(a1)+,d1
				ext.w	d0
				ext.w	d1
				muls	d3,d0
				muls	d2,d1
				add.l	d1,d0
				add.l	d0,d0
				swap	d0
				move.b	d0,(a0)+
				add.l	d6,d4
				sub.l	d6,d5

				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif

				subq.l	#1,d7
				bne.s	.LoopGen_17

				movem.l (sp)+,a0-a1	;Restore sample base address & large buffer address after loop generator

;----------------------------------------------------------------------------
; Instrument 19 - chord1
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst19Loop
				; v1 = chordgen(0, 17, 4, 7, 11, 0)
				move.l	AK_SmpAddr+68(a5),a4
				move.b	(a4,d7.l),d6
				ext.w	d6
				moveq	#0,d4
				move.w	AK_OpInstance+AK_CHORD1+0(a5),d4
				add.l	#82432,AK_OpInstance+AK_CHORD1+0(a5)
				move.b	(a4,d4.l),d5
				ext.w	d5
				add.w	d5,d6
				move.w	AK_OpInstance+AK_CHORD2+0(a5),d4
				add.l	#98048,AK_OpInstance+AK_CHORD2+0(a5)
				move.b	(a4,d4.l),d5
				ext.w	d5
				add.w	d5,d6
				move.w	AK_OpInstance+AK_CHORD3+0(a5),d4
				add.l	#123648,AK_OpInstance+AK_CHORD3+0(a5)
				move.b	(a4,d4.l),d5
				ext.w	d5
				add.w	d5,d6
				move.w	#255,d5
				cmp.w	d5,d6
				blt.s	.NoClampMaxChord_19_1
				move.w	d5,d6
				bra.s	.NoClampMinChord_19_1
.NoClampMaxChord_19_1
				not.w	d5
				cmp.w	d5,d6
				bge.s	.NoClampMinChord_19_1
				move.w	d5,d6
.NoClampMinChord_19_1
				asl.w	#7,d6
				move.w	d6,d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+72(a5),d7
				blt		.Inst19Loop

				movem.l a0-a1,-(sp)	;Stash sample base address & large buffer address for loop generator

;----------------------------------------------------------------------------
; Instrument 19 - Loop Generator (Offset: 8192 Length: 8192
;----------------------------------------------------------------------------

				move.l	#8192,d7
				move.l	AK_SmpAddr+72(a5),a0
				lea		8192(a0),a0
				move.l	a0,a1
				sub.l	d7,a1
				moveq	#0,d4
				move.l	#32767<<8,d5
				move.l	d5,d0
				divs	d7,d0
				bvc.s	.LoopGenVC_18
				moveq	#0,d0
.LoopGenVC_18
				moveq	#0,d6
				move.w	d0,d6
.LoopGen_18
				move.l	d4,d2
				asr.l	#8,d2
				move.l	d5,d3
				asr.l	#8,d3
				move.b	(a0),d0
				move.b	(a1)+,d1
				ext.w	d0
				ext.w	d1
				muls	d3,d0
				muls	d2,d1
				add.l	d1,d0
				add.l	d0,d0
				swap	d0
				move.b	d0,(a0)+
				add.l	d6,d4
				sub.l	d6,d5

				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif

				subq.l	#1,d7
				bne.s	.LoopGen_18

				movem.l (sp)+,a0-a1	;Restore sample base address & large buffer address after loop generator

;----------------------------------------------------------------------------
; Instrument 20 - chord2
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst20Loop
				; v1 = chordgen(0, 17, 5, 7, 9, 0)
				move.l	AK_SmpAddr+68(a5),a4
				move.b	(a4,d7.l),d6
				ext.w	d6
				moveq	#0,d4
				move.w	AK_OpInstance+AK_CHORD1+0(a5),d4
				add.l	#87552,AK_OpInstance+AK_CHORD1+0(a5)
				move.b	(a4,d4.l),d5
				ext.w	d5
				add.w	d5,d6
				move.w	AK_OpInstance+AK_CHORD2+0(a5),d4
				add.l	#98048,AK_OpInstance+AK_CHORD2+0(a5)
				move.b	(a4,d4.l),d5
				ext.w	d5
				add.w	d5,d6
				move.w	AK_OpInstance+AK_CHORD3+0(a5),d4
				add.l	#110080,AK_OpInstance+AK_CHORD3+0(a5)
				move.b	(a4,d4.l),d5
				ext.w	d5
				add.w	d5,d6
				move.w	#255,d5
				cmp.w	d5,d6
				blt.s	.NoClampMaxChord_20_1
				move.w	d5,d6
				bra.s	.NoClampMinChord_20_1
.NoClampMaxChord_20_1
				not.w	d5
				cmp.w	d5,d6
				bge.s	.NoClampMinChord_20_1
				move.w	d5,d6
.NoClampMinChord_20_1
				asl.w	#7,d6
				move.w	d6,d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+76(a5),d7
				blt		.Inst20Loop

				movem.l a0-a1,-(sp)	;Stash sample base address & large buffer address for loop generator

;----------------------------------------------------------------------------
; Instrument 20 - Loop Generator (Offset: 8192 Length: 8192
;----------------------------------------------------------------------------

				move.l	#8192,d7
				move.l	AK_SmpAddr+76(a5),a0
				lea		8192(a0),a0
				move.l	a0,a1
				sub.l	d7,a1
				moveq	#0,d4
				move.l	#32767<<8,d5
				move.l	d5,d0
				divs	d7,d0
				bvc.s	.LoopGenVC_19
				moveq	#0,d0
.LoopGenVC_19
				moveq	#0,d6
				move.w	d0,d6
.LoopGen_19
				move.l	d4,d2
				asr.l	#8,d2
				move.l	d5,d3
				asr.l	#8,d3
				move.b	(a0),d0
				move.b	(a1)+,d1
				ext.w	d0
				ext.w	d1
				muls	d3,d0
				muls	d2,d1
				add.l	d1,d0
				add.l	d0,d0
				swap	d0
				move.b	d0,(a0)+
				add.l	d6,d4
				sub.l	d6,d5

				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif

				subq.l	#1,d7
				bne.s	.LoopGen_19

				movem.l (sp)+,a0-a1	;Restore sample base address & large buffer address after loop generator

;----------------------------------------------------------------------------
; Empty Instrument
;----------------------------------------------------------------------------

				addq.w	#2,a0
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					else
						addq.l	#2,(a3)
					endif
				endif

;----------------------------------------------------------------------------
; Empty Instrument
;----------------------------------------------------------------------------

				addq.w	#2,a0
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					else
						addq.l	#2,(a3)
					endif
				endif

;----------------------------------------------------------------------------
; Empty Instrument
;----------------------------------------------------------------------------

				addq.w	#2,a0
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					else
						addq.l	#2,(a3)
					endif
				endif

;----------------------------------------------------------------------------
; Instrument 24 - bass_short1
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst24Loop
				; v1 = clone(smp,17, 0)
				moveq	#0,d0
				cmp.l	AK_SmpLen+68(a5),d7
				bge.s	.NoClone_24_1
				move.l	AK_SmpAddr+68(a5),a4
				move.b	(a4,d7.l),d0
				asl.w	#8,d0
.NoClone_24_1

				; v2 = envd(1, 6, 60, 128)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#1677568,d5
				cmp.l	#1006632960,d5
				bgt.s   .EnvDNoSustain_24_2
				move.l	#1006632960,d5
.EnvDNoSustain_24_2
				move.l	d5,AK_EnvDValue+0(a5)

				; v2 = mul(v2, 40)
				muls	#40,d1
				add.l	d1,d1
				swap	d1

				; v1 = distortion(v1, v2)
				move.w	d0,d5
				move.w	d1,d4
				and.w	#255,d4
				muls	d4,d5
				asr.l	#5,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxDist_24_4
				move.w	#32767,d5
				bra.s	.NoClampMinDist_24_4
.NoClampMaxDist_24_4
				cmp.l	#-32768,d5
				bge.s	.NoClampMinDist_24_4
				move.w	#-32768,d5
.NoClampMinDist_24_4
				asr.w	#1,d5
				move.w	d5,d0
				bge.s	.DistNoAbs_24_4
				neg.w	d5
.DistNoAbs_24_4
				move.w	#32767,d6
				sub.w	d5,d6
				muls	d6,d0
				swap	d0
				asl.w	#3,d0

				; v2 = osc_saw(4, 255, 32)
				add.w	#255,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d1
				asr.w	#2,d1

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_24_6
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_24_6

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+92(a5),d7
				blt		.Inst24Loop

;----------------------------------------------------------------------------
; Instrument 25 - bass_short2
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst25Loop
				; v1 = clone(smp,17, 2198)
				move.l	d7,d6
				add.l	#2198,d6
				moveq	#0,d0
				cmp.l	AK_SmpLen+68(a5),d6
				bge.s	.NoClone_25_1
				move.l	AK_SmpAddr+68(a5),a4
				move.b	(a4,d6.l),d0
				asl.w	#8,d0
.NoClone_25_1

				; v2 = envd(1, 6, 60, 128)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#1677568,d5
				cmp.l	#1006632960,d5
				bgt.s   .EnvDNoSustain_25_2
				move.l	#1006632960,d5
.EnvDNoSustain_25_2
				move.l	d5,AK_EnvDValue+0(a5)

				; v2 = mul(v2, 40)
				muls	#40,d1
				add.l	d1,d1
				swap	d1

				; v1 = distortion(v1, v2)
				move.w	d0,d5
				move.w	d1,d4
				and.w	#255,d4
				muls	d4,d5
				asr.l	#5,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxDist_25_4
				move.w	#32767,d5
				bra.s	.NoClampMinDist_25_4
.NoClampMaxDist_25_4
				cmp.l	#-32768,d5
				bge.s	.NoClampMinDist_25_4
				move.w	#-32768,d5
.NoClampMinDist_25_4
				asr.w	#1,d5
				move.w	d5,d0
				bge.s	.DistNoAbs_25_4
				neg.w	d5
.DistNoAbs_25_4
				move.w	#32767,d6
				sub.w	d5,d6
				muls	d6,d0
				swap	d0
				asl.w	#3,d0

				; v2 = osc_sine(4, 255, 32)
				add.w	#255,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d1
				sub.w	#16384,d1
				move.w	d1,d5
				bge.s	.SineNoAbs_25_5
				neg.w	d5
.SineNoAbs_25_5
				move.w	#32767,d6
				sub.w	d5,d6
				muls	d6,d1
				swap	d1
				asl.w	#3,d1
				asr.w	#2,d1

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_25_6
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_25_6

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+96(a5),d7
				blt		.Inst25Loop

;----------------------------------------------------------------------------
; Empty Instrument
;----------------------------------------------------------------------------

				addq.w	#2,a0
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					else
						addq.l	#2,(a3)
					endif
				endif

;----------------------------------------------------------------------------
; Empty Instrument
;----------------------------------------------------------------------------

				addq.w	#2,a0
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					else
						addq.l	#2,(a3)
					endif
				endif

;----------------------------------------------------------------------------
; Empty Instrument
;----------------------------------------------------------------------------

				addq.w	#2,a0
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					else
						addq.l	#2,(a3)
					endif
				endif

;----------------------------------------------------------------------------
; Instrument 29 - Virgill-Robot1
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst29Loop
				; v1 = imported_sample(smp,4)
				moveq	#0,d0
				cmp.l	AK_ExtSmpLen+16(a5),d7
				bge.s	.NoClone_29_1
				move.l	AK_ExtSmpAddr+16(a5),a4
				move.b	(a4,d7.l),d0
				asl.w	#8,d0
.NoClone_29_1

				; v2 = mul(v1, 32767)
				move.w	d0,d1
				muls	#32767,d1
				add.l	d1,d1
				swap	d1

				; v2 = sv_flt_n(2, v2, 80, 127, 1)
				move.w	AK_OpInstance+AK_BPF+0(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	#80,d5
				move.w	AK_OpInstance+AK_LPF+0(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_29_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_29_3
				move.w	d4,AK_OpInstance+AK_LPF+0(a5)
				muls	#127,d6
				move.w	d1,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_29_3
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_29_3
.NoClampMaxHPF_29_3
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_29_3
				move.w	#-32768,d5
.NoClampMinHPF_29_3
				move.w	d5,AK_OpInstance+AK_HPF+0(a5)
				asr.w	#7,d5
				muls	#80,d5
				add.w	AK_OpInstance+AK_BPF+0(a5),d5
				bvc.s	.NoClampBPF_29_3
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_29_3
				move.w	d5,AK_OpInstance+AK_BPF+0(a5)
				move.w	AK_OpInstance+AK_HPF+0(a5),d1

				; v2 = reverb(v2, 100, 10)
				move.l	d7,-(sp)
				sub.l	a6,a6
				move.l	a1,a4
				move.w	AK_OpInstance+6(a5),d5
				move.w	(a4,d5.w),d4
				muls	#100,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_29_4_0
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_29_4_0
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#557<<1,d5
				ble.s	.NoReverbReset_29_4_0
				moveq	#0,d5
.NoReverbReset_29_4_0
				move.w  d5,AK_OpInstance+6(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		4096(a1),a4
				move.w	AK_OpInstance+8(a5),d5
				move.w	(a4,d5.w),d4
				muls	#100,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_29_4_1
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_29_4_1
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#593<<1,d5
				ble.s	.NoReverbReset_29_4_1
				moveq	#0,d5
.NoReverbReset_29_4_1
				move.w  d5,AK_OpInstance+8(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		8192(a1),a4
				move.w	AK_OpInstance+10(a5),d5
				move.w	(a4,d5.w),d4
				muls	#100,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_29_4_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_29_4_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#641<<1,d5
				ble.s	.NoReverbReset_29_4_2
				moveq	#0,d5
.NoReverbReset_29_4_2
				move.w  d5,AK_OpInstance+10(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		12288(a1),a4
				move.w	AK_OpInstance+12(a5),d5
				move.w	(a4,d5.w),d4
				muls	#100,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_29_4_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_29_4_3
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#677<<1,d5
				ble.s	.NoReverbReset_29_4_3
				moveq	#0,d5
.NoReverbReset_29_4_3
				move.w  d5,AK_OpInstance+12(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		16384(a1),a4
				move.w	AK_OpInstance+14(a5),d5
				move.w	(a4,d5.w),d4
				muls	#100,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_29_4_4
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_29_4_4
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#709<<1,d5
				ble.s	.NoReverbReset_29_4_4
				moveq	#0,d5
.NoReverbReset_29_4_4
				move.w  d5,AK_OpInstance+14(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		20480(a1),a4
				move.w	AK_OpInstance+16(a5),d5
				move.w	(a4,d5.w),d4
				muls	#100,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_29_4_5
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_29_4_5
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#743<<1,d5
				ble.s	.NoReverbReset_29_4_5
				moveq	#0,d5
.NoReverbReset_29_4_5
				move.w  d5,AK_OpInstance+16(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		24576(a1),a4
				move.w	AK_OpInstance+18(a5),d5
				move.w	(a4,d5.w),d4
				muls	#100,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_29_4_6
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_29_4_6
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#787<<1,d5
				ble.s	.NoReverbReset_29_4_6
				moveq	#0,d5
.NoReverbReset_29_4_6
				move.w  d5,AK_OpInstance+18(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		28672(a1),a4
				move.w	AK_OpInstance+20(a5),d5
				move.w	(a4,d5.w),d4
				muls	#100,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_29_4_7
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_29_4_7
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#809<<1,d5
				ble.s	.NoReverbReset_29_4_7
				moveq	#0,d5
.NoReverbReset_29_4_7
				move.w  d5,AK_OpInstance+20(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				move.l	a6,d7
				cmp.l	#32767,d7
				ble.s	.NoReverbMax_29_4
				move.w	#32767,d7
				bra.s	.NoReverbMin_29_4
.NoReverbMax_29_4
				cmp.l	#-32768,d7
				bge.s	.NoReverbMin_29_4
				move.w	#-32768,d7
.NoReverbMin_29_4
				move.w	d7,d1
				move.l	(sp)+,d7

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_29_5
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_29_5

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+112(a5),d7
				blt		.Inst29Loop

				movem.l a0-a1,-(sp)	;Stash sample base address & large buffer address for loop generator

;----------------------------------------------------------------------------
; Instrument 29 - Loop Generator (Offset: 3936 Length: 2208
;----------------------------------------------------------------------------

				move.l	#2208,d7
				move.l	AK_SmpAddr+112(a5),a0
				lea		3936(a0),a0
				move.l	a0,a1
				sub.l	d7,a1
				moveq	#0,d4
				move.l	#32767<<8,d5
				move.l	d5,d0
				divs	d7,d0
				bvc.s	.LoopGenVC_28
				moveq	#0,d0
.LoopGenVC_28
				moveq	#0,d6
				move.w	d0,d6
.LoopGen_28
				move.l	d4,d2
				asr.l	#8,d2
				move.l	d5,d3
				asr.l	#8,d3
				move.b	(a0),d0
				move.b	(a1)+,d1
				ext.w	d0
				ext.w	d1
				muls	d3,d0
				muls	d2,d1
				add.l	d1,d0
				add.l	d0,d0
				swap	d0
				move.b	d0,(a0)+
				add.l	d6,d4
				sub.l	d6,d5

				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif

				subq.l	#1,d7
				bne.s	.LoopGen_28

				movem.l (sp)+,a0-a1	;Restore sample base address & large buffer address after loop generator

;----------------------------------------------------------------------------
; Instrument 30 - Virgill-Robot2
;----------------------------------------------------------------------------

				moveq	#8,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst30Loop
				; v1 = imported_sample(smp,5)
				moveq	#0,d0
				cmp.l	AK_ExtSmpLen+20(a5),d7
				bge.s	.NoClone_30_1
				move.l	AK_ExtSmpAddr+20(a5),a4
				move.b	(a4,d7.l),d0
				asl.w	#8,d0
.NoClone_30_1

				; v2 = mul(v1, 32767)
				move.w	d0,d1
				muls	#32767,d1
				add.l	d1,d1
				swap	d1

				; v2 = sv_flt_n(2, v2, 80, 127, 1)
				move.w	AK_OpInstance+AK_BPF+0(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	#80,d5
				move.w	AK_OpInstance+AK_LPF+0(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_30_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_30_3
				move.w	d4,AK_OpInstance+AK_LPF+0(a5)
				muls	#127,d6
				move.w	d1,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_30_3
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_30_3
.NoClampMaxHPF_30_3
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_30_3
				move.w	#-32768,d5
.NoClampMinHPF_30_3
				move.w	d5,AK_OpInstance+AK_HPF+0(a5)
				asr.w	#7,d5
				muls	#80,d5
				add.w	AK_OpInstance+AK_BPF+0(a5),d5
				bvc.s	.NoClampBPF_30_3
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_30_3
				move.w	d5,AK_OpInstance+AK_BPF+0(a5)
				move.w	AK_OpInstance+AK_HPF+0(a5),d1

				; v2 = reverb(v2, 114, 10)
				move.l	d7,-(sp)
				sub.l	a6,a6
				move.l	a1,a4
				move.w	AK_OpInstance+6(a5),d5
				move.w	(a4,d5.w),d4
				muls	#114,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_30_4_0
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_30_4_0
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#557<<1,d5
				ble.s	.NoReverbReset_30_4_0
				moveq	#0,d5
.NoReverbReset_30_4_0
				move.w  d5,AK_OpInstance+6(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		4096(a1),a4
				move.w	AK_OpInstance+8(a5),d5
				move.w	(a4,d5.w),d4
				muls	#114,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_30_4_1
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_30_4_1
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#593<<1,d5
				ble.s	.NoReverbReset_30_4_1
				moveq	#0,d5
.NoReverbReset_30_4_1
				move.w  d5,AK_OpInstance+8(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		8192(a1),a4
				move.w	AK_OpInstance+10(a5),d5
				move.w	(a4,d5.w),d4
				muls	#114,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_30_4_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_30_4_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#641<<1,d5
				ble.s	.NoReverbReset_30_4_2
				moveq	#0,d5
.NoReverbReset_30_4_2
				move.w  d5,AK_OpInstance+10(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		12288(a1),a4
				move.w	AK_OpInstance+12(a5),d5
				move.w	(a4,d5.w),d4
				muls	#114,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_30_4_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_30_4_3
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#677<<1,d5
				ble.s	.NoReverbReset_30_4_3
				moveq	#0,d5
.NoReverbReset_30_4_3
				move.w  d5,AK_OpInstance+12(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		16384(a1),a4
				move.w	AK_OpInstance+14(a5),d5
				move.w	(a4,d5.w),d4
				muls	#114,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_30_4_4
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_30_4_4
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#709<<1,d5
				ble.s	.NoReverbReset_30_4_4
				moveq	#0,d5
.NoReverbReset_30_4_4
				move.w  d5,AK_OpInstance+14(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		20480(a1),a4
				move.w	AK_OpInstance+16(a5),d5
				move.w	(a4,d5.w),d4
				muls	#114,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_30_4_5
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_30_4_5
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#743<<1,d5
				ble.s	.NoReverbReset_30_4_5
				moveq	#0,d5
.NoReverbReset_30_4_5
				move.w  d5,AK_OpInstance+16(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		24576(a1),a4
				move.w	AK_OpInstance+18(a5),d5
				move.w	(a4,d5.w),d4
				muls	#114,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_30_4_6
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_30_4_6
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#787<<1,d5
				ble.s	.NoReverbReset_30_4_6
				moveq	#0,d5
.NoReverbReset_30_4_6
				move.w  d5,AK_OpInstance+18(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		28672(a1),a4
				move.w	AK_OpInstance+20(a5),d5
				move.w	(a4,d5.w),d4
				muls	#114,d4
				asr.l	#7,d4
				add.w	d1,d4
				bvc.s	.ReverbAddNoClamp_30_4_7
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_30_4_7
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#809<<1,d5
				ble.s	.NoReverbReset_30_4_7
				moveq	#0,d5
.NoReverbReset_30_4_7
				move.w  d5,AK_OpInstance+20(a5)
				move.w	d4,d7
				muls	#10,d7
				asr.l	#7,d7
				add.w	d7,a6
				move.l	a6,d7
				cmp.l	#32767,d7
				ble.s	.NoReverbMax_30_4
				move.w	#32767,d7
				bra.s	.NoReverbMin_30_4
.NoReverbMax_30_4
				cmp.l	#-32768,d7
				bge.s	.NoReverbMin_30_4
				move.w	#-32768,d7
.NoReverbMin_30_4
				move.w	d7,d1
				move.l	(sp)+,d7

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_30_5
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_30_5

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+116(a5),d7
				blt		.Inst30Loop

				movem.l a0-a1,-(sp)	;Stash sample base address & large buffer address for loop generator

;----------------------------------------------------------------------------
; Instrument 30 - Loop Generator (Offset: 3936 Length: 2208
;----------------------------------------------------------------------------

				move.l	#2208,d7
				move.l	AK_SmpAddr+116(a5),a0
				lea		3936(a0),a0
				move.l	a0,a1
				sub.l	d7,a1
				moveq	#0,d4
				move.l	#32767<<8,d5
				move.l	d5,d0
				divs	d7,d0
				bvc.s	.LoopGenVC_29
				moveq	#0,d0
.LoopGenVC_29
				moveq	#0,d6
				move.w	d0,d6
.LoopGen_29
				move.l	d4,d2
				asr.l	#8,d2
				move.l	d5,d3
				asr.l	#8,d3
				move.b	(a0),d0
				move.b	(a1)+,d1
				ext.w	d0
				ext.w	d1
				muls	d3,d0
				muls	d2,d1
				add.l	d1,d0
				add.l	d0,d0
				swap	d0
				move.b	d0,(a0)+
				add.l	d6,d4
				sub.l	d6,d5

				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif

				subq.l	#1,d7
				bne.s	.LoopGen_29

				movem.l (sp)+,a0-a1	;Restore sample base address & large buffer address after loop generator

;----------------------------------------------------------------------------
; Instrument 31 - Soil-Filter-Plucked
;----------------------------------------------------------------------------

				moveq	#8,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst31Loop
				; v1 = clone(smp,15, 0)
				moveq	#0,d0
				cmp.l	AK_SmpLen+60(a5),d7
				bge.s	.NoClone_31_1
				move.l	AK_SmpAddr+60(a5),a4
				move.b	(a4,d7.l),d0
				asl.w	#8,d0
.NoClone_31_1

				; v1 = cmb_flt_n(1, v1, 127, 127, 128)
				move.l	a1,a4
				move.w	AK_OpInstance+0(a5),d5
				move.w	(a4,d5.w),d4
				muls	#127,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.CombAddNoClamp_31_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.CombAddNoClamp_31_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#127<<1,d5
				blt.s	.NoCombReset_31_2
				moveq	#0,d5
.NoCombReset_31_2
				move.w  d5,AK_OpInstance+0(a5)
				move.w	d4,d0

				; v1 = sv_flt_n(2, v1, 42, 0, 0)
				move.w	AK_OpInstance+AK_BPF+2(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	#42,d5
				move.w	AK_OpInstance+AK_LPF+2(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_31_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_31_3
				move.w	d4,AK_OpInstance+AK_LPF+2(a5)
				muls	#0,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_31_3
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_31_3
.NoClampMaxHPF_31_3
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_31_3
				move.w	#-32768,d5
.NoClampMinHPF_31_3
				move.w	d5,AK_OpInstance+AK_HPF+2(a5)
				asr.w	#7,d5
				muls	#42,d5
				add.w	AK_OpInstance+AK_BPF+2(a5),d5
				bvc.s	.NoClampBPF_31_3
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_31_3
				move.w	d5,AK_OpInstance+AK_BPF+2(a5)
				move.w	AK_OpInstance+AK_LPF+2(a5),d0

				; v2 = envd(3, 6, 16, 95)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#1677568,d5
				cmp.l	#268435456,d5
				bgt.s   .EnvDNoSustain_31_4
				move.l	#268435456,d5
.EnvDNoSustain_31_4
				move.l	d5,AK_EnvDValue+0(a5)
				muls	#95,d1
				asr.l	#7,d1

				; v1 = mul(v1, v2)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+120(a5),d7
				blt		.Inst31Loop


;----------------------------------------------------------------------------

				; Clear first 2 bytes of each sample
				lea		AK_SmpAddr(a5),a6
				moveq	#0,d0
				moveq	#31-1,d7
.SmpClrLoop		move.l	(a6)+,a4
				move.b	d0,(a4)+
				move.b	d0,(a4)+
				dbra	d7,.SmpClrLoop

				rts

;----------------------------------------------------------------------------

AK_ResetVars:
				moveq   #0,d1
				moveq   #0,d2
				moveq   #0,d3
				move.w  d0,d7
				beq.s	.NoClearDelay
				lsl.w	#8,d7
				subq.w	#1,d7
				move.l  a1,a6
.ClearDelayLoop
				move.l  d1,(a6)+
				move.l  d1,(a6)+
				move.l  d1,(a6)+
				move.l  d1,(a6)+
				dbra	d7,.ClearDelayLoop
.NoClearDelay
				moveq   #0,d0
				lea		AK_OpInstance(a5),a6
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l  #32767<<16,(a6)+
				rts

;----------------------------------------------------------------------------

				rsreset
AK_LPF			rs.w	1
AK_HPF			rs.w	1
AK_BPF			rs.w	1
				rsreset
AK_CHORD1		rs.l	1
AK_CHORD2		rs.l	1
AK_CHORD3		rs.l	1
				rsreset
AK_SmpLen		rs.l	31
AK_ExtSmpLen	rs.l	8
AK_NoiseSeeds	rs.l	3
AK_SmpAddr		rs.l	31
AK_ExtSmpAddr	rs.l	8
AK_OpInstance	rs.w    18
AK_EnvDValue	rs.l	1
AK_VarSize		rs.w	0

AK_Vars:
				dc.l	$00000d86		; Instrument 1 Length 
				dc.l	$000006d0		; Instrument 2 Length 
				dc.l	$00001c00		; Instrument 3 Length 
				dc.l	$00001500		; Instrument 4 Length 
				dc.l	$00001500		; Instrument 5 Length 
				dc.l	$00000400		; Instrument 6 Length 
				dc.l	$000004d2		; Instrument 7 Length 
				dc.l	$00002000		; Instrument 8 Length 
				dc.l	$00001600		; Instrument 9 Length 
				dc.l	$00001600		; Instrument 10 Length 
				dc.l	$00002a00		; Instrument 11 Length 
				dc.l	$00002000		; Instrument 12 Length 
				dc.l	$00000400		; Instrument 13 Length 
				dc.l	$00000002		; Instrument 14 Length 
				dc.l	$00000002		; Instrument 15 Length 
				dc.l	$00006000		; Instrument 16 Length 
				dc.l	$00003000		; Instrument 17 Length 
				dc.l	$00008000		; Instrument 18 Length 
				dc.l	$00004000		; Instrument 19 Length 
				dc.l	$00004000		; Instrument 20 Length 
				dc.l	$00000002		; Instrument 21 Length 
				dc.l	$00000002		; Instrument 22 Length 
				dc.l	$00000002		; Instrument 23 Length 
				dc.l	$00000800		; Instrument 24 Length 
				dc.l	$00000800		; Instrument 25 Length 
				dc.l	$00000002		; Instrument 26 Length 
				dc.l	$00000002		; Instrument 27 Length 
				dc.l	$00000002		; Instrument 28 Length 
				dc.l	$00001800		; Instrument 29 Length 
				dc.l	$00001800		; Instrument 30 Length 
				dc.l	$00000800		; Instrument 31 Length 
				dc.l	$00000d86		; External Sample 1 Length 
				dc.l	$000004ee		; External Sample 2 Length 
				dc.l	$00000d44		; External Sample 3 Length 
				dc.l	$000004d2		; External Sample 4 Length 
				dc.l	$0000078c		; External Sample 5 Length 
				dc.l	$0000048a		; External Sample 6 Length 
				dc.l	$00000000		; External Sample 7 Length 
				dc.l	$00000000		; External Sample 8 Length 
				dc.l	$67452301		; AK_NoiseSeed1
				dc.l	$efcdab89		; AK_NoiseSeed2
				dc.l	$00000000		; AK_NoiseSeed3
				ds.b	AK_VarSize-AK_SmpAddr

;----------------------------------------------------------------------------

	xdef AK_Generate
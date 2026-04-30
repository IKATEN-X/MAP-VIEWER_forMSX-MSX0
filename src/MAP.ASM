PROGRAM_BASE EQU 0C000H

        ORG PROGRAM_BASE

VALTYP  EQU 0F663H
DAC     EQU 0F7F6H
ARG     EQU 0F847H
DECADD  EQU 0269AH
DECSUB  EQU 0268CH
DECMUL  EQU 027E6H
DECDIV  EQU 0289FH
ATN     EQU 02A14H
SGN     EQU 02E97H
FRCDBL  EQU 0303AH
FRCINT  EQU 02F8AH
FIXER   EQU 030BEH
MAM     EQU 02C50H
MFM     EQU 02C5CH
MMF     EQU 02C67H
VMOVFM  EQU 02F08H

LDIRVM  EQU 0005CH

;---------------------------------------------------------
; Memory map
CHUNK_SIZE    EQU 0200H
CHUNK_COUNT   EQU 4
CHUNK_BASE    EQU PROGRAM_END
DRAW_BUF      EQU CHUNK_BASE + CHUNK_SIZE * CHUNK_COUNT
LOAD_OFS_BASE EQU CHUNK_BASE - PROGRAM_BASE
DRAW_W        EQU 32
DRAW_H        EQU 23
DRAW_BYTES    EQU DRAW_W * DRAW_H
VRAM_DRAW     EQU 01820H
MAP_CHUNK_W   EQU 56
MAP_CHUNK_H   EQU 48
SEA_ROW_BYTES EQU 7
SEA_BYTES     EQU 336

        JP INPLON
        JP INPLAT
        JP CALCXY
        JP GETVAL
        JP GETADDR
        JP BUILDFN
        JP CALCOF
        JP CALCFM
        JP CALCLOAD
        JP INITCACHE
        JP CALCB01
        JP DRAWSEG
        JP DISPATCH
        JP DRAWMAP
        JP INPDLON
        JP INPDLAT

;---------------------------------------------------------
; Work area
; 外部から参照が必要になった場合も追いやすいよう、入口JPリスト直後へ配置する
BUF_LON:
        DW 0,0,0,0
BUF_LAT:
        DW 0,0,0,0
BUF_DLON:
        DW 0,0,0,0
BUF_DLAT:
        DW 0,0,0,0
WORK0:
        DW 0,0,0,0
WORK1:
        DW 0,0,0,0
OUT_CX:
        DW 0
OUT_CY:
        DW 0
OUT_PX:
        DW 0
OUT_PY:
        DW 0
OUT_SX:
        DW 0
OUT_SY:
        DW 0
OUT_BX:
        DW 0
OUT_BY:
        DW 0
OUT_BXC:
        DW 0
OUT_BYC:
        DW 0
PREV_AX:
        DW 0
PREV_AY:
        DW 0
PREV_DX:
        DW 0
PREV_DY:
        DW 0
OUT_SKIP:
        DW 0
OUT_TX:
        DW 0
OUT_TY:
        DW 0
OUT_OF:
        DW 0
OUT_FM:
        DW 0
OUT_BF:
        DW 0
OUT_LOAD:
        DW 0
CACHE_X:
        DW 0,0,0,0
CACHE_Y:
        DW 0,0,0,0
OUT_B0:
        DW 0
OUT_B1:
        DW 0
SEG_SA:
        DW 0
SEG_AD:
        DW 0
SEG_CT:
        DW 0
SEG_S0:
        DW 0
SEG_V:
        DW 0
ROW_Y:
        DW 0
ROW_YY:
        DW 0
ROW_RY:
        DW 0
ROW_RF:
        DW 0
ROW_LC:
        DW 0
ROW_RC:
        DW 0
ROW_BF:
        DW 0
OUT_DI:
        DW 0
DIR_CXG:
        DW 0
DIR_CYG:
        DW 0
DIR_DXG:
        DW 0
DIR_DYG:
        DW 0
DIR_AX:
        DW 0
DIR_AY:
        DW 0
DIR_XNEG:
        DB 0
DIR_YSOUTH:
        DB 0
;---------------------------------------------------------
INPLON:
        cp 3
        ret z

INPLON_OK:
        ld (VALTYP),a
        call VMOVFM             ;FACからDACへ引数を取り込む
        ld a,(VALTYP)
        cp 8
        call nz,FRCDBL          ;倍精度へ揃える
        ld hl,BUF_LON
        call MMF                ;DACを経度ワークへ保存
        ret
;---------------------------------------------------------
INPLAT:
        cp 3
        ret z

INPLAT_OK:
        ld (VALTYP),a
        call VMOVFM             ;FACからDACへ引数を取り込む
        ld a,(VALTYP)
        cp 8
        call nz,FRCDBL          ;倍精度へ揃える
        ld hl,BUF_LAT
        call MMF                ;DACを緯度ワークへ保存
        ret

INPDLON:
        cp 3
        ret z

INPDLON_OK:
        ld (VALTYP),a
        call VMOVFM             ;FACからDACへ引数を取り込む
        ld a,(VALTYP)
        cp 8
        call nz,FRCDBL          ;倍精度へ揃える
        ld hl,BUF_DLON
        call MMF                ;DACを目的地経度ワークへ保存
        ret

INPDLAT:
        cp 3
        ret z

INPDLAT_OK:
        ld (VALTYP),a
        call VMOVFM             ;FACからDACへ引数を取り込む
        ld a,(VALTYP)
        cp 8
        call nz,FRCDBL          ;倍精度へ揃える
        ld hl,BUF_DLAT
        call MMF                ;DACを目的地緯度ワークへ保存
        ret

MAKE_X:
        ld a,8
        ld (VALTYP),a           ;以後は倍精度演算として扱う
        ld hl,BUF_LON
        call MFM                ;DACにLON
        ld hl,CONST123
        call MAM                ;ARGに123
        call DECSUB             ;DAC-ARG　= LON - 123 
        ld hl,CONST2
        call MAM                ;ARGに2
        call DECMUL             ;*2
        ret

MAKE_DEST_X:
        ld a,8
        ld (VALTYP),a           ;以後は倍精度演算として扱う
        ld hl,BUF_DLON
        call MFM                ;DACに目的地LON
        ld hl,CONST123
        call MAM                ;ARGに123
        call DECSUB             ;DAC-ARG = DLON - 123
        ld hl,CONST2
        call MAM                ;ARGに2
        call DECMUL             ;*2
        ret

MAKE_DEST_Y:
        ld a,8
        ld (VALTYP),a           ;以後は倍精度演算として扱う
        ld hl,CONST46
        call MFM                ;DACに46
        ld hl,BUF_DLAT
        call MAM                ;ARGに目的地LAT
        call DECSUB             ;DAC-ARG = 46 - DLAT
        ld hl,CONST2
        call MAM                ;ARGに2
        call DECMUL             ;*2
        ret

MAKE_Y:
        ld a,8
        ld (VALTYP),a           ;以後は倍精度演算として扱う
        ld hl,CONST46
        call MFM                ;DACに46
        ld hl,BUF_LAT
        call MAM                ;ARGにLAT
        call DECSUB             ;DAC-ARG = 46 - LAT
        ld hl,CONST2
        call MAM                ;ARGに2
        call DECMUL             ;*2
        ret
;---------------------------------------------------------
CALCXY:
        call CALCCX             ;CX = INT((LON-123)*2)
        call CALCCY             ;CY = INT((46-LAT)*2)
        call CALCPX             ;PX = INT(fracX*32)
        call CALCPY             ;PY = INT(fracY*32)

        ld hl,(OUT_PX)          ;SX = PX - 15
        ld de,15
        xor a
        sbc hl,de
        ld (OUT_SX),hl

        ld hl,(OUT_PY)          ;SY = PY - 10
        ld de,10
        xor a
        sbc hl,de
        ld (OUT_SY),hl

        call CALCBX             ;BX = CX-1 or CX
        call CALCBY             ;BY = CY-1 or CY
        call CLAMPBX            ;BXC = clamp(BX,0,55)
        call CLAMPBY            ;BYC = clamp(BY,0,47)
        call CALCFM_CORE        ;FM = 有効チャンクbit
        call CALCSKIP           ;前フレームと同一なら 1

        ld a,2
        ld (VALTYP),a           ;戻り値は整数0
        ld hl,0
        ld (DAC+2),hl
        ret

CALCCX:
        call MAKE_X
        call FIXER              ;小数部を落とす
        call FRCINT             ;整数としてDAC+2へ出す
        ld hl,(DAC+2)
        ld (OUT_CX),hl          ;CXへ保存
        ret

CALCCY:
        call MAKE_Y
        call FIXER              ;小数部を落とす
        call FRCINT             ;整数としてDAC+2へ出す
        ld hl,(DAC+2)
        ld (OUT_CY),hl          ;CYへ保存
        ret

CALCPX:
        call MAKE_X
        ld hl,WORK0
        call MMF                ;X実数を退避
        call FIXER              ;整数部を作る
        ld hl,WORK1
        call MMF                ;整数部を退避
        ld hl,WORK0
        call MFM                ;元のX実数へ戻す
        ld hl,WORK1
        call MAM                ;ARGに整数部
        call DECSUB             ;小数部だけ残す
        ld hl,CONST32
        call MAM                ;ARGに32
        call DECMUL             ;*32
        call FIXER              ;整数化
        call FRCINT             ;DAC+2へ出す
        ld hl,(DAC+2)
        ld (OUT_PX),hl          ;PXへ保存
        ret

CALCPY:
        call MAKE_Y
        ld hl,WORK0
        call MMF                ;Y実数を退避
        call FIXER              ;整数部を作る
        ld hl,WORK1
        call MMF                ;整数部を退避
        ld hl,WORK0
        call MFM                ;元のY実数へ戻す
        ld hl,WORK1
        call MAM                ;ARGに整数部
        call DECSUB             ;小数部だけ残す
        ld hl,CONST32
        call MAM                ;ARGに32
        call DECMUL             ;*32
        call FIXER              ;整数化
        call FRCINT             ;DAC+2へ出す
        ld hl,(DAC+2)
        ld (OUT_PY),hl          ;PYへ保存
        ret

CALCBX:
        ld hl,(OUT_SX)
        bit 7,h
        jr z,CALCBX_KEEP
        ld hl,(OUT_CX)
        dec hl
        ld (OUT_BX),hl
        ret
CALCBX_KEEP:
        ld hl,(OUT_CX)
        ld (OUT_BX),hl
        ret

CALCBY:
        ld hl,(OUT_SY)
        bit 7,h
        jr z,CALCBY_KEEP
        ld hl,(OUT_CY)
        dec hl
        ld (OUT_BY),hl
        ret
CALCBY_KEEP:
        ld hl,(OUT_CY)
        ld (OUT_BY),hl
        ret

CLAMPBX:
        ld hl,(OUT_BX)
        bit 7,h
        jr z,CLAMPBX_HI
        ld hl,0
        jr CLAMPBX_SAVE
CLAMPBX_HI:
        ld de,55
        or a
        sbc hl,de
        jr c,CLAMPBX_RESTORE
        ld hl,55
        jr CLAMPBX_SAVE
CLAMPBX_RESTORE:
        add hl,de
CLAMPBX_SAVE:
        ld (OUT_BXC),hl
        ret

CLAMPBY:
        ld hl,(OUT_BY)
        bit 7,h
        jr z,CLAMPBY_HI
        ld hl,0
        jr CLAMPBY_SAVE
CLAMPBY_HI:
        ld de,47
        or a
        sbc hl,de
        jr c,CLAMPBY_RESTORE
        ld hl,47
        jr CLAMPBY_SAVE
CLAMPBY_RESTORE:
        add hl,de
CLAMPBY_SAVE:
        ld (OUT_BYC),hl
        ret

CALCSKIP:
        ld hl,(OUT_SX)
        ld de,(PREV_AX)
        or a
        sbc hl,de
        jr nz,CALCSKIP_NO
        ld hl,(OUT_SY)
        ld de,(PREV_AY)
        or a
        sbc hl,de
        jr nz,CALCSKIP_NO
        ld hl,(OUT_BXC)
        ld de,(PREV_DX)
        or a
        sbc hl,de
        jr nz,CALCSKIP_NO
        ld hl,(OUT_BYC)
        ld de,(PREV_DY)
        or a
        sbc hl,de
        jr nz,CALCSKIP_NO
        ld hl,1
        ld (OUT_SKIP),hl
        ret
CALCSKIP_NO:
        ld hl,0
        ld (OUT_SKIP),hl
        ret
;---------------------------------------------------------
GETVAL:
        cp 2
        ret nz
        inc hl
        inc hl
        push hl
        ld  a,(hl)              ;selectorを読む
        ld hl,OUT_CX
        or a
        jr z,GET_DONE
        cp 1
        jr z,GET_CY
        cp 2
        jr z,GET_PX
        cp 3
        jr z,GET_PY
        cp 4
        jr z,GET_SX
        cp 5
        jr z,GET_SY
        cp 6
        jr z,GET_BX
        cp 7
        jr z,GET_BY
        cp 8
        jr z,GET_SKIP
        ld hl,0
        jr GET_WRITE

GET_CY:
        ld hl,OUT_CY
        jr GET_DONE
GET_PX:
        ld hl,OUT_PX
        jr GET_DONE
GET_PY:
        ld hl,OUT_PY
        jr GET_DONE
GET_SX:
        ld hl,OUT_SX
        jr GET_DONE
GET_SY:
        ld hl,OUT_SY
        jr GET_DONE
GET_BX:
        ld hl,OUT_BXC
        jr GET_DONE
GET_BY:
        ld hl,OUT_BYC
        jr GET_DONE
GET_SKIP:
        ld hl,OUT_SKIP

GET_DONE:
        ld e,(hl)               ;選択した16bit値をHLへ積む
        inc hl
        ld d,(hl)
GET_WRITE:
        pop hl
        ld (hl),e
        inc hl
        ld (hl),d
        ret

GETADDR:
        cp 2
        ret nz

GETADDR_OK:
        inc hl                  ;戻り値領域を飛ばす
        inc hl
        push hl
        ld  e,(hl)              ;引数のアドレス下位
        inc hl
        ld  d,(hl)              ;引数のアドレス上位
        ex  de,hl        ; HL=読みたいアドレス

        ld  e,(hl)              ;指定先16bitを読む
        inc hl
        ld  d,(hl)

        pop  hl                 ;戻り値領域へ書く
        ld  (hl),e
        inc hl
        ld  (hl),d

        ret

CALCTXTY:
        cp 2
        ret nz
        inc hl                  ;戻り値領域を飛ばす
        inc hl
        push hl
        ld  a,(hl)              ;BF

        ld hl,(OUT_BXC)         ;TX = BX + (BF AND 1)
        bit 0,a
        jr z,CALCTXTY_TX
        inc hl
CALCTXTY_TX:
        ld (OUT_TX),hl

        ld hl,(OUT_BYC)         ;TY = BY + (BF \ 2)
        bit 1,a
        jr z,CALCTXTY_TY
        inc hl
CALCTXTY_TY:
        ld (OUT_TY),hl

        pop hl                  ;戻り値は整数0
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        ret

CALCOF:
        cp 2
        ret nz
        inc hl                  ;戻り値領域を飛ばす
        inc hl
        push hl
        ld  l,(hl)              ;HL = BF
        ld  h,0
        SLA L
        LD H, L
        LD L, 0
        ld  de,LOAD_OFS_BASE
        add hl,de
        ld (OUT_OF),hl

        pop hl                  ;戻り値は整数0
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        ret

CALCFM:
        cp 2
        ret nz
        inc hl                  ;戻り値領域を飛ばす
        inc hl
        push hl

        call CALCFM_CORE

        pop hl                  ;戻り値は整数0
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        ret

CALCFM_CORE:
        ld a,15                 ;4チャンクすべて有効から始める

        ld hl,(OUT_BXC)         ;右端なら右列bitを落とす
        ld de,55
        or a
        sbc hl,de
        jr nz,CALCFM_Y
        and 5

CALCFM_Y:
        ld hl,(OUT_BYC)         ;下端なら下段bitを落とす
        ld de,47
        or a
        sbc hl,de
        jr nz,CALCFM_SAVE
        and 3

CALCFM_SAVE:
        ld l,a
        ld h,0
        ld (OUT_FM),hl
        ret

CALCLOAD:
        cp 2
        ret nz
        inc hl                  ;戻り値領域を飛ばす
        inc hl
        push hl
        ld a,(hl)               ;引数BFを取り込む
        and 3
        ld (OUT_BF),a

        call CALCFM_CORE

        ld a,(OUT_BF)
        ld b,a                  ;FMの該当bitがなければロード不要
        ld a,(OUT_FM)
        ld c,a
        ld a,b
        or a
        jr z,CALCLOAD_B0
        cp 1
        jr z,CALCLOAD_B1
        cp 2
        jr z,CALCLOAD_B2
        bit 3,c
        jr z,CALCLOAD_NO
        jr CALCLOAD_VALID
CALCLOAD_B0:
        bit 0,c
        jr z,CALCLOAD_NO
        jr CALCLOAD_VALID
CALCLOAD_B1:
        bit 1,c
        jr z,CALCLOAD_NO
        jr CALCLOAD_VALID
CALCLOAD_B2:
        bit 2,c
        jr z,CALCLOAD_NO

CALCLOAD_VALID:
        ld a,(OUT_BF)           ;TX = BX + (BF AND 1)
        ld hl,(OUT_BXC)
        bit 0,a
        jr z,CALCLOAD_TX
        inc hl
CALCLOAD_TX:
        ld (OUT_TX),hl

        ld hl,(OUT_BYC)         ;TY = BY + (BF \ 2)
        bit 1,a
        jr z,CALCLOAD_TY
        inc hl
CALCLOAD_TY:
        ld (OUT_TY),hl

        ld l,a                  ;OF = LOAD_OFS_BASE + BF*CHUNK_SIZE
        ld h,0
        
        SLA L
        LD H, L
        LD L, 0

        ld de,LOAD_OFS_BASE
        add hl,de
        ld (OUT_OF),hl

        ld a,(OUT_BF)           ;キャッシュX比較
        add a,a
        ld e,a
        ld d,0
        ld hl,CACHE_X
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld hl,(OUT_TX)
        or a
        sbc hl,de
        jr nz,CALCLOAD_NEED

        ld a,(OUT_BF)           ;キャッシュY比較
        add a,a
        ld e,a
        ld d,0
        ld hl,CACHE_Y
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld hl,(OUT_TY)
        or a
        sbc hl,de
        jr nz,CALCLOAD_NEED

CALCLOAD_NO:
        ld hl,0
        ld (OUT_LOAD),hl
        jp CALCLOAD_RET

CALCLOAD_NEED:
        call SEA_CHECK
        or a
        jr z,CALCLOAD_YES

        call CALCLOAD_UPDATE_CACHE
        call CLEAR_CHUNK
        ld hl,0
        ld (OUT_LOAD),hl
        jr CALCLOAD_RET

CALCLOAD_YES:
        call CALCLOAD_UPDATE_CACHE
        ld hl,1
        ld (OUT_LOAD),hl
        jr CALCLOAD_RET

CALCLOAD_UPDATE_CACHE:
        ld a,(OUT_BF)           ;ロード/海埋め予定なのでキャッシュを更新
        add a,a
        ld e,a
        ld d,0
        ld hl,CACHE_X
        add hl,de
        ld de,(OUT_TX)
        ld (hl),e
        inc hl
        ld (hl),d

        ld a,(OUT_BF)
        add a,a
        ld e,a
        ld d,0
        ld hl,CACHE_Y
        add hl,de
        ld de,(OUT_TY)
        ld (hl),e
        inc hl
        ld (hl),d
        ret

SEA_CHECK:
        ld hl,(OUT_TY)          ;SEA_TABLE[TY*7 + TX/8] の該当bitを見る
        ld d,h
        ld e,l
        add hl,hl               ;*2
        add hl,hl               ;*4
        add hl,hl               ;*8
        or a
        sbc hl,de               ;*7
        ld a,(OUT_TX)
        srl a
        srl a
        srl a
        ld e,a
        ld d,0
        add hl,de
        ld de,SEA_TABLE
        add hl,de
        ld c,(hl)

        ld a,(OUT_TX)
        and 7
        ld b,a
        ld a,1
        jr z,SEA_CHECK_MASK_DONE
SEA_CHECK_MASK_LOOP:
        add a,a
        djnz SEA_CHECK_MASK_LOOP
SEA_CHECK_MASK_DONE:
        and c
        ret z
        ld a,1
        ret

CLEAR_CHUNK:
        ld a,(OUT_BF)           ;CHUNK_BASE + BF*CHUNK_SIZE を0で埋める
        ld h,a
        ld l,0
        add hl,hl
        ld de,CHUNK_BASE
        add hl,de
        xor a
        ld (hl),a
        ld d,h
        ld e,l
        inc de
        ld bc,CHUNK_SIZE - 1
        ldir
        ret

CALCLOAD_RET:
        pop hl
        ld de,(OUT_LOAD)
        ld (hl),e
        inc hl
        ld (hl),d
        ret

INITCACHE:
        cp 2
        ret nz
        inc hl                  ;戻り値領域を飛ばす
        inc hl
        push hl
        ld hl,CACHE_X
        ld de,0FFFFH
        ld b,8
INITCACHE_LOOP:
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        djnz INITCACHE_LOOP

        ld hl,999               ;初回は必ず再描画させる
        ld (PREV_AX),hl
        ld (PREV_AY),hl
        ld (PREV_DX),hl
        ld (PREV_DY),hl

        pop hl                  ;戻り値は整数0
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        ret

CALCB01:
        cp 2
        ret nz
        inc hl
        inc hl
        push hl

        call CALCB01_CORE

        pop hl
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        ret

CALCB01_CORE:
        ld hl,(OUT_CY)          ;B0 = SY + (CY-BY)*32
        ld de,(OUT_BYC)
        or a
        sbc hl,de
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,(OUT_SY)
        add hl,de
        ld (OUT_B0),hl

        ld hl,(OUT_CX)          ;B1 = SX + (CX-BX)*32
        ld de,(OUT_BXC)
        or a
        sbc hl,de
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,(OUT_SX)
        add hl,de
        ld (OUT_B1),hl
        ret

BUILDFN:
        cp 3
        ret nz
        ex de,hl                ;文字列ディスクリプタはDEで渡される
        ld a,(hl)               ;固定長17文字未満なら何もしない
        cp 17
        jr c,BUILDFN_RET
        inc hl
        ld e,(hl)               ;DE=文字列本体
        inc hl
        ld d,(hl)
        ex de,hl                ;HL=文字列本体

        push hl
        ld de,4                 ;C:\Txx\Txx_yy.BIN の最初のxx
        add hl,de
        ld a,(OUT_TX)
        call WRITE2DIG

        pop hl
        push hl
        ld de,8                 ;2つ目のxx
        add hl,de
        ld a,(OUT_TX)
        call WRITE2DIG

        pop hl
        ld de,11                ;yy
        add hl,de
        ld a,(OUT_TY)
        call WRITE2DIG

BUILDFN_RET:
        ret                     ;VALTYP=3のまま、書き換えた文字列を返す

WRITE2DIG:
        ld b,'0'
WRITE2DIG_LOOP:
        cp 10
        jr c,WRITE2DIG_ONES
        sub 10
        inc b
        jr WRITE2DIG_LOOP
WRITE2DIG_ONES:
        ld (hl),b
        inc hl
        add a,'0'
        ld (hl),a
        ret

DRAWSEG:
        cp 2
        ret nz
        inc hl
        inc hl
        push hl

        call DRAWSEG_CORE

        pop hl
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        ret

DRAWSEG_CORE:

        ld a,(SEG_CT)
        or a
        ret z
        ld b,a                  ;B=残り描画文字数
        ld a,(SEG_S0)
        ld c,a                  ;C=RB

        bit 0,c                 ;奇数開始なら下位ニブルを先に1文字出す
        jr z,DRAWSEG_PAIR
        call DRAWSEG_GETBYTE
        and 00FH
        call DRAWSEG_PUT
        inc c
        djnz DRAWSEG_PAIR
        ret

DRAWSEG_PAIR:
        call DRAWSEG_GETBYTE
        ld (SEG_V),a            ;同じソースbyteから上位/下位を取り出す
        and 0F0H                ;上位ニブル
        rrca
        rrca
        rrca
        rrca
        call DRAWSEG_PUT
        djnz DRAWSEG_LOW
        ret

DRAWSEG_LOW:
        ld a,(SEG_V)
        and 00FH                ;下位ニブル
        call DRAWSEG_PUT
        inc c
        inc c
        djnz DRAWSEG_PAIR
        ret

DRAWSEG_GETBYTE:
        ld hl,(SEG_SA)          ;A = PEEK(SA + RB\2)
        ld a,c
        srl a
        ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        ret

DRAWSEG_PUT:
        add a,080H              ;POKE AD, 128+nibble
        ld hl,(SEG_AD)
        ld (hl),a
        inc hl
        ld (SEG_AD),hl
        ret

DRAWROW:
        cp 2
        ret nz
        inc hl
        inc hl
        push hl
        inc hl
        ld a,(hl)               ;USR(256*Y+6) の高バイトをYとして使う
        ld (ROW_Y),a
        call DRAWROW_CORE

        pop hl
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        ret

DRAWROW_CORE:
        ld a,(ROW_Y)
        ld hl,(OUT_B0)          ;YY = B0 + Y
        ld e,a
        ld d,0
        add hl,de
        ld (ROW_YY),hl

        ld de,32                ;RF/RY
        or a
        sbc hl,de
        jr c,DRAWROW_TOP
        ld (ROW_RY),hl
        ld hl,2
        ld (ROW_RF),hl
        jr DRAWROW_SPLIT
DRAWROW_TOP:
        add hl,de
        ld (ROW_RY),hl
        ld hl,0
        ld (ROW_RF),hl

DRAWROW_SPLIT:
        ld hl,32                ;LC = 32-B1, RC = B1
        ld de,(OUT_B1)
        or a
        sbc hl,de
        ld (ROW_LC),hl
        ld hl,(OUT_B1)
        ld (ROW_RC),hl

        ld hl,(ROW_RF)          ;左セグメント BF=RF
        ld (ROW_BF),hl
        ld hl,(OUT_B1)
        ld a,l
        or h
        jr z,DRAWROW_LEFT_DO
        call DRAWROW_FM_OK
        jr z,DRAWROW_RIGHT

DRAWROW_LEFT_DO:
        call DRAWROW_MKSA
        call DRAWROW_MKAD0
        ld hl,(ROW_LC)
        ld (SEG_CT),hl
        ld hl,(OUT_B1)
        ld (SEG_S0),hl
        call DRAWSEG_CORE

DRAWROW_RIGHT:
        ld hl,(ROW_RC)
        ld a,l
        or h
        jr z,DRAWROW_DONE
        ld hl,(ROW_RF)
        inc hl
        ld (ROW_BF),hl
        call DRAWROW_FM_OK
        jr z,DRAWROW_DONE

        call DRAWROW_MKSA
        call DRAWROW_MKAD0
        ld hl,(SEG_AD)          ;AD = AD + LC
        ld de,(ROW_LC)
        add hl,de
        ld (SEG_AD),hl
        ld hl,(ROW_RC)
        ld (SEG_CT),hl
        ld hl,0
        ld (SEG_S0),hl
        call DRAWSEG_CORE

DRAWROW_DONE:
        ret

DRAWROW_FM_OK:
        ld hl,(ROW_BF)
        ld a,l
        ld c,a
        ld a,(OUT_FM)
        ld b,a
        ld a,c
        or a
        jr z,DRAWROW_FM_B0
        cp 1
        jr z,DRAWROW_FM_B1
        cp 2
        jr z,DRAWROW_FM_B2
        bit 3,b
        jr nz,DRAWROW_FM_YES
        xor a
        ret
DRAWROW_FM_B0:
        bit 0,b
        jr nz,DRAWROW_FM_YES
        xor a
        ret
DRAWROW_FM_B1:
        bit 1,b
        jr nz,DRAWROW_FM_YES
        xor a
        ret
DRAWROW_FM_B2:
        bit 2,b
        jr nz,DRAWROW_FM_YES
        xor a
        ret
DRAWROW_FM_YES:
        ld a,1
        ret

DRAWROW_MKSA:
        ld hl,(ROW_BF)          ;SA = CHUNK_BASE + BF*CHUNK_SIZE + RY*16
        ld h,l
        ld l,0
        add hl,hl
        ld de,CHUNK_BASE
        add hl,de
        ex de,hl
        ld hl,(ROW_RY)
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,de
        ld (SEG_SA),hl
        ret

DRAWROW_MKAD0:
        ld a,(ROW_Y)            ;AD = DRAW_BUF + Y*DRAW_W
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,DRAW_BUF
        add hl,de
        ld (SEG_AD),hl
        ret

DISPATCH:
        cp 2
        ret nz
        push hl
        inc hl
        inc hl
        ld a,(hl)
        cp 4
        jr c,DISP_CALCLOAD_ARG
        jr z,DISP_INITCACHE
        cp 5
        jr z,DISP_CALCXY
        cp 6
        jr z,DISP_DRAWSCREEN
        cp 7
        jr z,DISP_GET_SKIP
        cp 8
        jr z,DISP_GET_OF
        cp 9
        jr z,DISP_CALCDIR
        jr DISP_RET0
DISP_CALCLOAD_ARG:
        ld (hl),a
        pop hl
        ld a,2
        jp CALCLOAD

DISP_RET0:
        pop hl
        ld a,2
        ld (VALTYP),a
        ld hl,0
        ld (DAC+2),hl
        ret

DISP_CALCXY:
        pop hl
        jp CALCXY
DISP_INITCACHE:
        pop hl
        ld a,2
        jp INITCACHE
DISP_DRAWSCREEN:
        pop hl
        ld a,2
        jp DRAWSCREEN
DISP_GET_SKIP:
        ld de,(OUT_SKIP)
        jr DISP_RET_DE
DISP_GET_OF:
        ld de,(OUT_OF)
DISP_RET_DE:
        pop hl
        inc hl
        inc hl
        ld (hl),e
        inc hl
        ld (hl),d
        ret
DISP_CALCDIR:
        pop hl
        ld a,2
        jp CALCDIR

DRAWMAP:
        cp 2
        ret nz
        inc hl
        inc hl
        push hl
        call DRAWMAP_CORE
        call UPDATEPREV
        pop hl
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        ret

DRAWMAP_CORE:
        ld hl,DRAW_BUF
        ld de,VRAM_DRAW
        ld bc,DRAW_BYTES
        call LDIRVM
        ret

UPDATEPREV:
        ld hl,(OUT_SX)
        ld (PREV_AX),hl
        ld hl,(OUT_SY)
        ld (PREV_AY),hl
        ld hl,(OUT_BXC)
        ld (PREV_DX),hl
        ld hl,(OUT_BYC)
        ld (PREV_DY),hl
        ret

DRAWSCREEN:
        cp 2
        ret nz
        inc hl
        inc hl
        push hl

        call CALCB01_CORE
        call DRAWROWS_CORE
        call DRAWMAP_CORE
        call UPDATEPREV

        pop hl
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        ret

DRAWROWS:
        cp 2
        ret nz
        inc hl
        inc hl
        push hl

        call DRAWROWS_CORE

        pop hl
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        ret

DRAWROWS_CORE:
        xor a
        ld (ROW_Y),a
DRAWROWS_LOOP:
        call DRAWROW_CORE
        ld a,(ROW_Y)
        inc a
        ld (ROW_Y),a
        cp 23
        jr nz,DRAWROWS_LOOP
        ret

CALCDIR:
        cp 2
        ret nz
        inc hl
        inc hl
        push hl

        call CALC_GLOBAL_CURRENT_X
        call CALC_GLOBAL_CURRENT_Y
        call CALC_GLOBAL_DEST_X
        call CALC_GLOBAL_DEST_Y
        call CALCDIR_TABLE_CORE

        pop hl
        ld de,(OUT_DI)
        ld (hl),e
        inc hl
        ld (hl),d
        ret

CALCDIR_TABLE_CORE:
        ld hl,(DIR_DXG)         ;X差分 = 目的地X - 現在地X
        ld de,(DIR_CXG)
        or a
        sbc hl,de
        xor a
        ld (DIR_XNEG),a
        bit 7,h
        jr z,CALCDIR_T_X_ABS_DONE
        ld a,1
        ld (DIR_XNEG),a
        call NEG_HL
CALCDIR_T_X_ABS_DONE:
        ld (DIR_AX),hl

        ld hl,(DIR_CYG)         ;北向き差分 = 現在地Y - 目的地Y
        ld de,(DIR_DYG)
        or a
        sbc hl,de
        xor a
        ld (DIR_YSOUTH),a
        bit 7,h
        jr z,CALCDIR_T_Y_ABS_DONE
        ld a,1
        ld (DIR_YSOUTH),a
        call NEG_HL
CALCDIR_T_Y_ABS_DONE:
        ld (DIR_AY),hl

        ld hl,(DIR_AX)          ;完全一致なら DI=-1
        ld a,h
        or l
        ld de,(DIR_AY)
        or d
        or e
        jr nz,CALCDIR_T_NOT_SAME
        ld hl,0FFFFH
        ld (OUT_DI),hl
        ret

CALCDIR_T_NOT_SAME:
        call DIR_NORMALIZE_8

        ld hl,(DIR_AX)          ;TX = 8 +/- abs(dx)
        ld a,(DIR_XNEG)
        or a
        ld a,8
        jr nz,CALCDIR_T_TX_WEST
        add a,l
        jr CALCDIR_T_TX_DONE
CALCDIR_T_TX_WEST:
        sub l
CALCDIR_T_TX_DONE:
        ld c,a

        ld hl,(DIR_AY)          ;TY = 8 - north / 8 + south
        ld a,(DIR_YSOUTH)
        or a
        ld a,8
        jr nz,CALCDIR_T_TY_SOUTH
        sub l
        jr CALCDIR_T_TY_DONE
CALCDIR_T_TY_SOUTH:
        add a,l
CALCDIR_T_TY_DONE:
        ld l,a
        ld h,0
        add hl,hl               ;TY*17 = TY*16 + TY
        add hl,hl
        add hl,hl
        add hl,hl
        ld e,a
        ld d,0
        add hl,de
        ld e,c
        ld d,0
        add hl,de
        ld de,VA_TABLE
        add hl,de
        ld l,(hl)
        ld h,0
        ld (OUT_DI),hl
        ret

DIR_NORMALIZE_8:
        ld hl,(DIR_AX)
        ld a,h
        or a
        jr nz,DIR_NORMALIZE_8_SHIFT
        ld a,l
        cp 9
        jr nc,DIR_NORMALIZE_8_SHIFT
        ld hl,(DIR_AY)
        ld a,h
        or a
        jr nz,DIR_NORMALIZE_8_SHIFT
        ld a,l
        cp 9
        ret c

DIR_NORMALIZE_8_SHIFT:
        ld hl,(DIR_AX)
        srl h
        rr l
        ld (DIR_AX),hl
        ld hl,(DIR_AY)
        srl h
        rr l
        ld (DIR_AY),hl
        jr DIR_NORMALIZE_8

CALCDIR_ATN_CORE:
        call CALCDIR_MKDX
        call CALCDIR_MKDY

        ld hl,(DIR_AX)          ;DX=0かつDY=0なら方向なし
        ld a,h
        or l
        jr nz,CALCDIR_ATN_NOT_SAME
        ld hl,(DIR_AY)
        ld a,h
        or l
        jr nz,CALCDIR_ATN_NOT_SAME
        ld hl,0FFFFH
        ld (OUT_DI),hl
        ret

CALCDIR_ATN_NOT_SAME:
        ld hl,(DIR_AY)          ;DY=0なら東西を直接角度化
        ld a,h
        or l
        jr nz,CALCDIR_ATN_DIV
        ld hl,(DIR_AX)
        bit 7,h
        jr nz,CALCDIR_ATN_W
        ld a,8
        ld (VALTYP),a
        ld hl,CONST_PI2
        call MFM
        jr CALCDIR_ATN_FINISH
CALCDIR_ATN_W:
        ld a,8
        ld (VALTYP),a
        ld hl,CONST_3PI2
        call MFM
        jr CALCDIR_ATN_FINISH

CALCDIR_ATN_DIV:
        ld a,8
        ld (VALTYP),a
        ld hl,WORK0             ;AG = ATN(DX/DY)
        call MFM
        ld hl,WORK1
        call MAM
        call DECDIV
        call ATN

        ld hl,(DIR_AY)          ;DY<0なら +PI
        bit 7,h
        jr z,CALCDIR_ATN_NORTH
        ld hl,CONST_PI
        call MAM
        call DECADD
        jr CALCDIR_ATN_FINISH

CALCDIR_ATN_NORTH:
        ld hl,(DIR_AX)          ;DY>=0かつDX<0なら +2PI
        bit 7,h
        jr z,CALCDIR_ATN_FINISH
        ld hl,CONST_2PI
        call MAM
        call DECADD

CALCDIR_ATN_FINISH:
        ld hl,CONST_PI16        ;DI = INT((AG + PI/16) / (PI/8))
        call MAM
        call DECADD
        ld hl,CONST_PI8
        call MAM
        call DECDIV
        call FIXER
        call FRCINT
        ld hl,(DAC+2)
        ld de,16
        or a
        sbc hl,de
        jr nc,CALCDIR_ATN_SAVE
        add hl,de
CALCDIR_ATN_SAVE:
        ld (OUT_DI),hl
        ret

CALCDIR_MKDX:
        ld a,8
        ld (VALTYP),a
        ld hl,BUF_DLON
        call MFM
        ld hl,BUF_LON
        call MAM
        call DECSUB             ;DX = DLON - LON
        ld hl,WORK0
        call MMF
        call SGN
        ld hl,(DAC+2)
        ld (DIR_AX),hl          ;DIR_AXはDXの符号(-1,0,1)
        ret

CALCDIR_MKDY:
        ld a,8
        ld (VALTYP),a
        ld hl,BUF_DLAT
        call MFM
        ld hl,BUF_LAT
        call MAM
        call DECSUB             ;DY = DLAT - LAT
        ld hl,WORK1
        call MMF
        call SGN
        ld hl,(DAC+2)
        ld (DIR_AY),hl          ;DIR_AYはDYの符号(-1,0,1)
        ret

CALC_GLOBAL_CURRENT_X:
        call MAKE_X
        ld hl,CONST32
        call MAM
        call DECMUL
        ld hl,CONST16
        call MAM
        call DECMUL
        call FIXER
        call FRCINT
        ld hl,(DAC+2)
        ld (DIR_CXG),hl
        ret

CALC_GLOBAL_CURRENT_Y:
        call MAKE_Y
        ld hl,CONST32
        call MAM
        call DECMUL
        ld hl,CONST16
        call MAM
        call DECMUL
        call FIXER
        call FRCINT
        ld hl,(DAC+2)
        ld (DIR_CYG),hl
        ret

CALC_GLOBAL_DEST_X:
        call MAKE_DEST_X
        ld hl,CONST32
        call MAM
        call DECMUL
        ld hl,CONST16
        call MAM
        call DECMUL
        call FIXER
        call FRCINT
        ld hl,(DAC+2)
        ld (DIR_DXG),hl
        ret

CALC_GLOBAL_DEST_Y:
        call MAKE_DEST_Y
        ld hl,CONST32
        call MAM
        call DECMUL
        ld hl,CONST16
        call MAM
        call DECMUL
        call FIXER
        call FRCINT
        ld hl,(DAC+2)
        ld (DIR_DYG),hl
        ret

CALCDIR_CORE:
        ld hl,(DIR_DXG)         ;X差分 = 目的地X - 現在地X
        ld de,(DIR_CXG)
        or a
        sbc hl,de
        xor a
        ld (DIR_XNEG),a
        bit 7,h
        jr z,CALCDIR_X_ABS_DONE
        ld a,1
        ld (DIR_XNEG),a
        call NEG_HL
CALCDIR_X_ABS_DONE:
        ld (DIR_AX),hl

        ld hl,(DIR_CYG)         ;北向き差分 = 現在地Y - 目的地Y
        ld de,(DIR_DYG)
        or a
        sbc hl,de
        xor a
        ld (DIR_YSOUTH),a
        bit 7,h
        jr z,CALCDIR_Y_ABS_DONE
        ld a,1
        ld (DIR_YSOUTH),a
        call NEG_HL
CALCDIR_Y_ABS_DONE:
        ld (DIR_AY),hl

        call DIR_NORMALIZE_ABS  ;*5比較が16bitを超えないよう比率を保って縮小

        ld a,h                  ;完全一致なら DI=-1
        or l
        ld de,(DIR_AX)
        or d
        or e
        jr nz,CALCDIR_NOT_SAME
        ld hl,0FFFFH
        ld (OUT_DI),hl
        ret

CALCDIR_NOT_SAME:
        call DIR_BASE_NE        ;A=0..4 (NからEまでの近さ)
        ld b,a
        ld a,(DIR_XNEG)
        or a
        jr nz,CALCDIR_WEST

        ld a,(DIR_YSOUTH)
        or a
        jr nz,CALCDIR_EAST_SOUTH
        ld a,b                  ;NE象限: 0,1,2,3,4
        jr CALCDIR_SAVE_A

CALCDIR_EAST_SOUTH:
        ld a,8                  ;SE象限: 8,7,6,5,4
        sub b
        jr CALCDIR_SAVE_A

CALCDIR_WEST:
        ld a,(DIR_YSOUTH)
        or a
        jr nz,CALCDIR_WEST_SOUTH
        ld a,16                 ;NW象限: 0,15,14,13,12
        sub b
        and 15
        jr CALCDIR_SAVE_A

CALCDIR_WEST_SOUTH:
        ld a,8                  ;SW象限: 8,9,10,11,12
        add a,b

CALCDIR_SAVE_A:
        ld l,a
        ld h,0
        ld (OUT_DI),hl
        ret

DIR_BASE_NE:
        ld hl,(DIR_AY)          ;x/y >= 16 -> E
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ex de,hl
        ld hl,(DIR_AX)
        call CMP_HL_DE
        jr nc,DIR_BASE_4

        ld hl,(DIR_AY)          ;x/y >= 2 -> ENE
        add hl,hl
        ex de,hl
        ld hl,(DIR_AX)
        call CMP_HL_DE
        jr nc,DIR_BASE_3

        ld hl,(DIR_AX)          ;x/y >= 1/2 -> NE
        add hl,hl
        ex de,hl
        ld hl,(DIR_AY)
        call CMP_HL_DE
        jr nc,DIR_BASE_2

        ld hl,(DIR_AX)          ;x/y >= 1/16 -> NNE
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,(DIR_AY)
        call CMP_HL_DE
        jr nc,DIR_BASE_1

        xor a
        ret
DIR_BASE_1:
        ld a,1
        ret
DIR_BASE_2:
        ld a,2
        ret
DIR_BASE_3:
        ld a,3
        ret
DIR_BASE_4:
        ld a,4
        ret

DIR_NORMALIZE_ABS:
        ld hl,(DIR_AX)
        ld a,h
        and 0E0H
        jr nz,DIR_NORMALIZE_SHIFT
        ld hl,(DIR_AY)
        ld a,h
        and 0E0H
        ret z

DIR_NORMALIZE_SHIFT:
        ld hl,(DIR_AX)
        srl h
        rr l
        ld (DIR_AX),hl
        ld hl,(DIR_AY)
        srl h
        rr l
        ld (DIR_AY),hl
        jr DIR_NORMALIZE_ABS

NEG_HL:
        ex de,hl
        ld hl,0
        or a
        sbc hl,de
        ret

MUL_HL_3:
        ld d,h
        ld e,l
        add hl,hl
        add hl,de
        ret

MUL_HL_5:
        ld d,h
        ld e,l
        add hl,hl
        add hl,hl
        add hl,de
        ret

CMP_HL_DE:
        or a
        sbc hl,de
        ret

VA_TABLE:
        DB 14,14,14,15,15,15,15,0,0,0,1,1,1,1,2,2,2
        DB 14,14,14,14,15,15,15,0,0,0,1,1,1,2,2,2,2
        DB 14,14,14,14,15,15,15,0,0,0,1,1,1,2,2,2,2
        DB 13,14,14,14,14,15,15,15,0,1,1,1,2,2,2,2,3
        DB 13,13,13,14,14,14,15,15,0,1,1,2,2,2,3,3,3
        DB 13,13,13,13,14,14,15,15,0,1,1,2,2,3,3,3,3
        DB 13,13,13,13,13,13,14,15,0,1,2,3,3,3,3,3,3
        DB 12,12,12,13,13,13,13,14,0,2,3,3,3,3,4,4,4
        DB 12,12,12,12,12,12,12,12,12,4,4,4,4,4,4,4,4
        DB 12,12,12,11,11,11,11,10,8,6,5,5,5,5,4,4,4
        DB 11,11,11,11,11,11,10,9,8,7,6,5,5,5,5,5,5
        DB 11,11,11,11,10,10,9,9,8,7,7,6,6,5,5,5,5
        DB 11,11,11,10,10,10,9,9,8,7,7,6,6,6,5,5,5
        DB 11,10,10,10,10,9,9,9,8,7,7,7,6,6,6,6,5
        DB 10,10,10,10,9,9,9,8,8,8,7,7,7,6,6,6,6
        DB 10,10,10,10,9,9,9,8,8,8,7,7,7,6,6,6,6
        DB 10,10,10,9,9,9,9,8,8,8,7,7,7,7,6,6,6

CONST123:
        DB 043H,012H,030H,000H,000H,000H,000H,000H
CONST46:
        DB 042H,046H,000H,000H,000H,000H,000H,000H
CONST2:
        DB 041H,020H,000H,000H,000H,000H,000H,000H
CONST16:
        DB 042H,016H,000H,000H,000H,000H,000H,000H
CONST32:
        DB 042H,032H,000H,000H,000H,000H,000H,000H
CONST_PI16:
        DB 040H,019H,063H,049H,054H,000H,000H,000H
CONST_PI8:
        DB 040H,039H,026H,099H,008H,000H,000H,000H
CONST_PI2:
        DB 041H,015H,070H,079H,063H,030H,000H,000H
CONST_PI:
        DB 041H,031H,041H,059H,026H,050H,000H,000H
CONST_3PI2:
        DB 041H,047H,012H,038H,089H,080H,000H,000H
CONST_2PI:
        DB 041H,062H,083H,018H,053H,010H,000H,000H

; 1bit per chunk: 1=sea only, 0=normal load.
; generated from chunks4_osm_bload
; sea chunks: 2333/2688
SEA_TABLE:
        DB 255,255,255,62,0,0,224,255,255,255,255,7,255,241,255,255
        DB 255,255,31,62,252,255,255,255,255,15,0,254,255,255,255,255
        DB 15,0,255,255,255,255,255,3,128,255,255,255,255,255,1,224
        DB 255,255,255,255,255,32,254,255,255,255,255,255,225,254,255,255
        DB 255,255,255,226,255,255,255,255,255,255,193,255,255,255,255,255
        DB 255,193,255,255,255,255,255,255,129,255,255,255,255,255,255,129
        DB 255,255,255,255,255,255,193,255,255,255,255,255,63,192,255,255
        DB 255,127,255,39,224,255,255,255,127,255,7,224,255,255,255,255
        DB 255,3,240,255,255,255,255,231,1,240,255,255,255,255,7,0
        DB 240,255,255,255,255,3,0,248,255,255,239,239,0,0,252,255
        DB 255,239,47,0,240,252,255,255,255,31,0,248,253,255,255,255
        DB 7,128,253,253,255,255,255,7,224,255,255,255,255,255,27,252
        DB 255,253,255,255,255,27,254,255,255,255,255,255,47,254,255,255
        DB 255,255,255,31,254,255,255,255,255,255,31,255,255,255,255,255
        DB 255,223,255,255,255,255,255,255,207,255,255,255,255,255,255,199
        DB 255,255,255,255,255,255,143,255,255,255,255,255,255,231,255,255
        DB 191,255,255,255,241,255,255,191,255,255,255,248,255,255,191,255
        DB 255,127,252,255,255,255,255,255,252,255,254,255,255,255,255,255
        DB 255,255,255,239,255,255,227,255,255,255,239,255,255,248,255,255
        DB 255,239,255,255,255,255,255,255,255,255,255,255,255,255,255,255
        DB 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255

PROGRAM_END:

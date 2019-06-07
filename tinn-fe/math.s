/*
24 bit fixed point signed math library
*/

.label a1 = $a0
.label a2 = $a1
.label a3 = $a2
.label a4 = $a3
.label a5 = $a4

.label b1 = $a5
.label b2 = $a6
.label b3 = $a7

.label r1 = $a8
.label r2 = $a9
.label r3 = $aa
.label r4 = $ab
.label r5 = $ac

//.label pztemp = $ad


.macro load_a(bhi,bmd,blo){
    lda #blo
    sta a1
    lda #bmd
    sta a2
    lda #bhi
    sta a3
}

.macro load_b(bhi,bmd,blo){
    lda #blo
    sta b1
    lda #bmd
    sta b2
    lda #bhi
    sta b3
}

.macro load_r(bhi,bmd,blo){
    lda #blo
    sta r1
    lda #bmd
    sta r2
    lda #bhi
    sta r3
}

.macro read_r(){
    lda r1
    ldx r2
    ldy r3
}

.macro read_mul_r(){
    lda r3
    ldx r4
    ldy r5
}

.macro mv_a(address){
    lda a1
    sta address
    lda a2
    sta address + 1
    lda a3
    sta address + 2
}

.macro mv_b(address){
    lda b1
    sta address
    lda b2
    sta address + 1
    lda b3
    sta address + 2
}

.macro mv_result(address){
    lda r1
    sta address
    lda r2
    sta address + 1
    lda r3
    sta address + 2
}

.macro mv_mul_result(address){
    lda r3
    sta address
    lda r4
    sta address + 1
    lda r5
    sta address + 2
}

mByteToA:
    sta a3
    rts

mByteToB:
    sta b3
    rts

/*
Load into A register
24 bit start address
x lo byte
y hi byte
returns: x/y next 24bit start address
clobbers a
*/
mLoadA:
    stx mla_ptr
    stx mla_rsx
    sty mla_ptr + 1
    ldx #$02
!loop:
    lda mla_ptr: $ffff,x
    sta a1,x
    dex
    bne !loop-
    ldx mla_rsx: #$00
    inx
    bne !skip+
    iny
!skip:
    rts

/*
Load into B register
24 bit start address
x lo byte
y hi byte
returns: x/y next 24bit start address
clobbers a
*/
mLoadB:
    stx mlb_ptr
    stx mlb_rsx
    sty mlb_ptr + 1
    ldx #$02
!loop:
    lda mlb_ptr: $ffff,x
    sta b1,x
    dex
    bne !loop-
    ldx mlb_rsx: #$00
    inx
    bne !skip+
    iny
!skip:
    rts


/*
24 bit signed add
*/
mAdd:
    clc				
    lda a1
    adc b1
    sta r1
    lda a2
    adc b2
    sta r2
    lda a3
    adc b3
    sta r3
    rts

/*
24 bit signed subtract
*/
mSub:
    sec				
    lda a1
    sbc b1
    sta r1
    lda a2
    sbc b2
    sta r2
    lda a3
    sbc b3
    sta r3
    rts


/*
24 bit signed compare
N will contain the signed comparison result, but in this case:
If the N flag is 1, then A (signed) <= NUM (signed) and BMI will branch
If the N flag is 0, then A (signed) > NUM (signed) and BPL will branch
*/
mCmp:
    sec
    lda a1
    cmp b1
    lda a2
    cmp b2
    lda a3
    cmp b3
    bvc !skip+
    eor #$80
!skip:
    rts

mNegA:
    negative24(a1)
    rts

mNegB:
    negative24(b1)
    rts

mNegR:
    negative24(r1)
    rts

.macro negative24(lowestByte){
    sec
    lda #$00
    sbc lowestByte
    sta lowestByte
    lda #$00
    sbc lowestByte + 1
    sta lowestByte + 1
    lda #$00
    sbc lowestByte + 2
    sta lowestByte + 2
}

/*
Should never need this code!
*/
// .macro negative48(lowestByte){
//     sec
//     lda #$00
//     sbc lowestByte
//     sta lowestByte
//     lda #$00
//     sbc lowestByte + 1
//     sta lowestByte + 1
//     lda #$00
//     sbc lowestByte + 2
//     sta lowestByte + 2
//     lda #$00
//     sbc lowestByte + 3
//     sta lowestByte + 3
//     lda #$00
//     sbc lowestByte + 4
//     sta lowestByte + 4
//     lda #$00
//     sbc lowestByte + 5
//     sta lowestByte + 5
//     lda #$00
//     sbc lowestByte + 6
//     sta lowestByte + 6
// }


/*
Based on http://codebase64.org/doku.php?id=base:24bit_multiplication_24bit_product
	; Signed 24-bit multiply routine
	; Clobbers a, x, factor1, factor2
    modified to handle fixed point multiply (2 extra bytes of precision)
    note that the 24 bit result is actually r3 -> r5 NOT r1! 
    Bascially reading from r3 rescales the result
*/
mMul:
	ldx #$00 // .x will hold the sign of product
    stx r1 // init result
    stx r2
    stx r3
    stx r4
    stx r5
    stx a4
    stx a5
	lda a3 //high byte (sign)
	bpl !skip+ //  if factor1 is negative
	negative24(a1) // then factor1 := -factor1
	inx	// and switch sign
!skip:
	lda b3 //high byte (sign)
	bpl !skip+ // if factor2 is negative
	negative24(b1) // then factor2 := -factor2
	inx // and switch sign
!skip:
    // do unsigned multiplication
!loop:
	lda b1			// ; while factor2 != 0
	bne !nz+
	lda b2
	bne !nz+
	lda b3
	bne !nz+
	jmp !done+
!nz:
	lda b1			// ; if factor2 is odd
	and #$01
	beq !skip+
	
	lda a1			// ; product += factor1
	clc
	adc r1
	sta r1
	
	lda a2
	adc r2
	sta r2
	
    lda a3
    adc r3
    sta r3

    lda a4
    adc r4
    sta r4

    lda a5
    adc r5
    sta r5

//; end if

!skip:
	asl a1			//; << factor1 
	rol a2
	rol a3
    rol a4
    rol a5
	lsr b3			//; >> factor2
	ror b2
	ror b1

	jmp !loop-		//; end while	

!done:
    //clean up sign
	txa
	and #$01 // if .x is odd
	beq !skip+
	negative24(r3) // then product := -product
!skip:
    rts


	

// mDiv:
// 	ldx #$00 // .x will hold the sign of division
//     stx r1 // init result
//     stx r2
//     stx r3
//     stx r4
//     stx r5
//     stx r6

// 	lda a3 //high byte (sign)
// 	bpl !skip+ //  if factor1 is negative
// 	negative24(a1) // then factor1 := -factor1
// 	inx	// and switch sign
// !skip:
// 	lda b3 //high byte (sign)
// 	bpl !skip+ // if factor2 is negative
// 	negative24(b1) // then factor2 := -factor2
// 	inx // and switch sign
//     stx sign_flag
// !skip:

//     //http://codebase64.org/doku.php?id=base:24bit_division_24-bit_result
//     //modified for signed 
// 	ldx #24	       // ;repeat for each bit: ...
// divloop:
// 	asl a1 //dividend	;dividend lb & hb*2, msb -> Carry
// 	rol a2 //dividend+1	
// 	rol a3 //dividend+2
// 	rol r1 //remainder	;remainder lb & hb * 2 + msb from carry
// 	rol r2 //remainder+1
// 	rol r3 //remainder+2
// 	lda r1 //remainder
// 	sec
// 	sbc b1 //divisor	;substract divisor to see if it fits in
// 	tay	   //     ;lb result -> Y, for we may need it later
// 	lda r2 //remainder+1
// 	sbc b2 //divisor+1
// 	sta pztemp
// 	lda r3 //remainder+2
// 	sbc b3 //divisor+2
// 	bcc skip	//;if carry=0 then divisor didn't fit in yet

// 	sta r3 //remainder+2	//;else save substraction result as new remainder,
// 	lda pztemp
// 	sta r2 //remainder+1
// 	sty r1 //remainder	
// 	inc a1 //dividend //	;and INCrement result cause divisor fit in 1 times
// skip:	
//     dex
// 	bne divloop	

//     lda sign_flag: #$00
// 	and #$01 // if .x is odd
// 	beq !skip+
// 	negative24(a1) // then product := -product
//     //rescale result
// !skip:
//     rts




	   title	 "Assignment 3"
	   list		 p=16f877a
	   include	 "P16F877A.INC"

	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _HS_OSC & _WRT_OFF & _LVP_OFF & _CPD_OFF

; '__CONFIG' directive is used to embed configuration data within .asm file.
; The lables following the directive are located in the respective .inc file.
; See respective data sheet for additional information on configuration word.
; Remember there are TWO underscore characters before the word CONFIG.

;*******************************************************************
;
;  filename	 ::	  one line description
;  ===================================
;
; Description
;	 ..............................................
;
;
; Method
;	 ................................................
;
; Version
;	 Lorenzo Stilo	   V1.0	   October 2015
;
; History
;	 ..........................................
;
;******************************************************************* 
;*******************************************************************	
;
; Constant declarations
; =====================
;

BIT0		equ		d'0'
BIT1		equ		d'1'
BIT2		equ		d'2'
BIT3		equ		d'3'
BIT4		equ		d'4'
BIT5		equ		d'5'
BIT6		equ		d'6'
BIT7		equ		d'7'
HBYTE		equ		d'255'			; Set 1 Byte to Hi 
LBYTE		equ		d'0'			; Set 1 Byte to Lo

;
;******************************************************************* 
;*******************************************************************	
;
; Variable declarations	 : User RAM area starts at location h'20' for PIC16F877a
; =====================
;
w_temp		equ		h'7D'		; variable used for context saving 
status_temp	equ		h'7E'		; variable used for context saving
pclath_temp	equ		h'7F'		; variable used for context saving

v1			equ		h'20'		; variable used to store the 500us delay
v2			equ		h'21'		; variable used to store the 50us delay
delcnt		equ		h'22'		; variable used by delay routine
count		equ		h'23'		; variable used by main loop
numbits		equ		h'24'		; number of pins to read

;
;*******************************************************************
;******************************************************************* 
; Initial system vector.
;	
			org		h'00'				; initialise system restart vector

			clrf	STATUS
			clrf	PCLATH				; needed for TinyBootloader functionality
			goto	start

;******************************************************************* 
;******************************************************************* 
; interrupt vector
;
;			org		h'04'
;			goto	int_routine

;******************************************************************* 
;******************************************************************* 
;
; System subroutines.
;  
			org		h'05'			; start of program space
;
;******************************************************************* 
;******************************************************************* 
; System functions
;******************************************************************* 
;
;* Init : initialise I/O ports and variables
;  ====
; Notes
;	   ............................
;
Init	
			bsf		STATUS, RP0		   	; enable page 1 register set
			bcf		STATUS, RP1

			movlw	h'07'
			movwf	ADCON1		   	   	; set PORTA to be digital rather than analogue

			movlw	b'000001'
			movwf	TRISA			   	; set port A	 
			movlw	HBYTE					
			movwf	TRISB			   	; set port B pins all to Inputs
			movlw	LBYTE					
			movwf	TRISC			   	; set port C pins all to Output
;			movlw	b'11111100'					
;			movwf	TRISD			   	; set port D 
			bcf		STATUS, RP0		   	; back to page 0 register set
			
;
; Set watchdog off somehow
;
;			bcf		h'2007',b'00000000000100'		
;	
; enable interrupts
;

;			bsf 	INTCON,GIE
;			bsf 	INTCON,INTE
;			bsf		INTCON,RBIE		;this enables interrupts on PORTB, I want to enable interrupts on PORTA instead
			
;
; initialise program variables
;
			clrf	v1			; ensure that no delay command is active
			clrf	v2			; ensure that no delay command is active
			clrf	delcnt		; clear delay counter			
			clrf	count		; clear main loop counter
			clrf	numbits		; clear the number of switches to read
			return
;******************************************************************* 
;
;  int_routine : routine to handle the single interrupt
;  ===========
; Notes
;	   ............................
;
int_routine
			movwf	w_temp			  ; save off current W register contents
			movf	STATUS,w		  ; move status register into W register
			movwf	status_temp		  ; save off contents of STATUS register
			movf	PCLATH,w	  ; move pclath register into w register
			movwf	pclath_temp	  ; save off contents of PCLATH register
;
; Your interrupt code goes HERE
;
			movf	pclath_temp,w	  ; retrieve copy of PCLATH register
			movwf	PCLATH		  ; restore pre-isr PCLATH register contents
			movf	status_temp,w	  ; retrieve copy of STATUS register
			movwf	STATUS			  ; restore pre-isr STATUS register contents
			swapf	w_temp,f
			swapf	w_temp,w		  ; restore pre-isr W register contents
			retfie 
;*******************************************************************	
;
; ****** other system subroutines.
; delay10uS
; ========
;
delay10uS
			movlw   d'11'       
			movwf   delcnt       
del0    
			nop              	                                                                                                        
			decfsz  delcnt,f     
			goto    del0         
			return


; delay50uS
; ========
;
delay50uS
			movlw   d'59'       
			movwf   delcnt       
del1    
			nop              	                                                                                                        
			decfsz  delcnt,f     
			goto    del1         
			return

; delay500uS
; ========
;	

delay500uS
			movlw   d'250'
   			movwf   delcnt       
del2    
			nop              	 
			nop                  
			nop                  
			nop                  
			nop                  
			nop                  
			nop                  
			decfsz  delcnt,f     
			goto    del2         
			return                


; delayV1
; ==========
;
		
delayV1							; I want to call delay500uS v1 times
			call	delay500uS
			decfsz	v1,f
			goto	delayV1
			return

; delayV2
; ==========
;
	

delayV2							; I want to call delay50uS v2 times
			call	delay50uS
			decfsz	v2,f
			goto	delayV2
			return


; readPB
; ==========
;
readPB
			call	readpin
			decfsz	numbits,f
			goto	readPB
			return
			
; readpin
; ==========
;
readpin
			btfsc	PORTB,numbits
			call	pulseC
			btfss	PORTB,numbits
			call	waitC
			return

; pulseC
; ==========
;
pulseC
			bsf		PORTC,BIT1
			movlw	CCCCC
			movwf	v2
			call	delayV2
			bcf		PORTC, BIT1
			movlw	CCCCC
			movwf	v2
			call	delayV2
			return

; waitC
; ==========
;
waitC
			bcf		PORTC,BIT1
			movlw	CCCCC
			movwf	v2
			call	delayV2
			bcf		PORTC, BIT1
			movlw	CCCCC
			movwf	v2
			call	delayV2
			return	
			
;
;
;******************************************************************* 
;*******************************************************************   
;
; MAIN program
; ============
;
start	
			call	Init
;
			

start1	
			bcf		PORTC,LBYTE
;			goto	start1
;	Your code goes HERE
loop
; =========START Pulse
			bsf		PORTC, BIT1 ; Set PortC Pin 1 to Hi 
;			========TRIGGER			
			bsf		PORTC, BIT0	; Start the Trigger
			call	delay10uS
			bcf		PORTC, BIT0	; Stop the Trigger
;			========			
			movlw	AAAAA
			movwf	v1
			call	delayV1
			bcf		PORTC, BIT1	;
			movlw	BBBBB
			movwf	v1
			call	delayV1

;===========DATA		
			movlw	DDDDD
			movwf	numbits
			call	readPB


; =========STOP Pulse
			bsf		PORTC,BIT1
			movlw	EEEEE
			movwf	v1
			call	delayV1
			bcf		PORTC, BIT1
			movlw	BBBBB
			movwf	v1
			call	delayV1

			incf    count,F   ; keep a count of cycles (0 when 255+1)
			goto	loop

;
;
;******************************************************************* 
;
; Program complete.
;
			END



; -----------------------------------------------------------
; Microcontroller Based Systems Homework
; Author name: Borchani Ahmed
; Neptun code: EFKTV2
; -------------------------------------------------------------------
; Task description: 
;   Convert a hexadecimal number given by a variable-length ASCII character 
;   string in the internal memory (0..FFFF) to binary format. 
;   If an invalid ASCII character is detected in the input, indicate by CY=1.
;   Input: Start address of the string (pointer)
;   Output: Converted binary number in 2 registers, CY flag
; -------------------------------------------------------------------


; Definitions
; -------------------------------------------------------------------

; Address symbols for creating pointers

STR_ADDR_IRAM  EQU 0x40
STR_CHAR1 EQU 'B'
STR_CHAR2 EQU 'E'
STR_CHAR3 EQU 'E'
STR_CHAR4 EQU 'F'
STR_CHAR5 EQU 0

; Test data for input parameters
; (Try also other values while testing your code.)

; Interrupt jump table
ORG 0x0000;
    SJMP  MAIN                  ; Reset vector

; Beginning of the user program
ORG 0x0033

; -------------------------------------------------------------------
; MAIN program
; -------------------------------------------------------------------
; Purpose: Prepare the inputs and call the subroutines
; -------------------------------------------------------------------

MAIN:

    ; Prepare input parameters for the subroutine
	MOV R0,#STR_ADDR_IRAM
	MOV @R0, #STR_CHAR1
	INC R0
	MOV @R0, #STR_CHAR2
	INC R0
	MOV @R0, #STR_CHAR3
	INC R0
	MOV @R0, #STR_CHAR4
	INC R0
	MOV @R0, #STR_CHAR5
	
	MOV R7, #STR_ADDR_IRAM
	
; Infinite loop: Call the subroutine repeatedly
LOOP:

    CALL ASCIIHEX_2_BIN ; Call hex string to number subroutine

    SJMP  LOOP




; ===================================================================           
;                           SUBROUTINE
; ===================================================================           


; -------------------------------------------------------------------
; ASCIIHEX_2_BIN
; -------------------------------------------------------------------
; Purpose: Converts an ASCII hex string into a 16-bit unsigned number
; -------------------------------------------------------------------
; INPUT(S):
;   R7 - Base address of the input string in the internal memory
; OUTPUT(S): 
;   R5 - High byte of the parsed 16-bit number
;   R6 - Low byte of the parsed 16-bit number
;   CY - Invalid input string
; MODIFIES:
;   A, B, R0, R1, R2, R3, R4, R5, R6, R7
; -------------------------------------------------------------------

ASCIIHEX_2_BIN:

	MOV R3, #0x00       ; R3 counts the number of valid characters (to be converted)
	CALL STRING_CALLER  ; the character converter
    RET	


; ===================================================================           
;                           SUBROUTINE(S)
; ===================================================================           


; -------------------------------------------------------------------
; STRING_CALLER
; -------------------------------------------------------------------
; Purpose: Calls a validation-checker and converter subroutine for 
; a character and increment R7 to repeat it with the next character
; -------------------------------------------------------------------
; INPUT(S):
;   R7 - Base address of the input string in the internal memory
; OUTPUT(S): 
;   R5 - High byte of the parsed 16-bit number
;   R6 - Low byte of the parsed 16-bit number
;   CY - Invalid input string
; MODIFIES:
;   A, B, R0, R1, R2, R3, R4, R5, R6, R7
; -------------------------------------------------------------------
STRING_CALLER:
	CALL VALID_CONV  ;checking the ASCII hex validity, converting and writing the result to R5 and R6
	JC BACK			; returning in case the carry was set: an unvalid character was found
	INC R7         ;Incrementing R7 to convert the next character 
	MOV A, R3      ; If 4 characters have been read then R3==4
	SUBB A, #0x04  ; Checking this by setting the carry if R3==4
	JNC BACK        ; Jumping so the next instruction won't be executed
    SJMP STRING_CALLER ; this will convert the next character
BACK: 
	RET            ; Retruning to ASCIIHEX_2_BIN since 4 characters have been read or CY==1

; ===================================================================           
;                           SUBROUTINE(S)
; ===================================================================           


; -------------------------------------------------------------------
; VALID_CONV
; -------------------------------------------------------------------
; Purpose: Checks if an ASCII hex character is valid and writes it in a specific
;		   position in R5 and R6 registers (using register R3 for positioning). 
;		   Retruns CY==1 if the hex character is not valid.
; -------------------------------------------------------------------
; INPUT:
;   R2 - an ASCII hex character 
; OUTPUT(S): 
;   R5 - gets an 8-bit converted ASCII character in a position indicated by R3
;   R6 - gets an 8-bit converted ASCII character in a position indicated by R3
;   CY - Invalid input string
;   R3 - The position of the 8-bit number in the final output
; MODIFIES:
;   A, B, R0, R1, R2, R3, R4, R5, R6, CY
; -------------------------------------------------------------------
VALID_CONV:
;Checking if the character is in the range '0'..'9' which is 0x30 to 0x39 in hex
	CALL READ_CHAR   ; Reading a character x and storing it in R2
	MOV  A, R2        ; moving this character to the accumulator for calculations
	CLR  C		     ; clearing the carry so that SUBB doesn't use it
	SUBB A, #0x30    ; A = x - '0'
	JC   INVALID_LOW_LETTER ; if the hex character is less than 0x30 then it's not a number, nor a letter
    MOV  R1, A       ; R1 gets the value: x - '0'
    MOV  A, #0x09    ; '9' - '0' = 0x39 - 0x30 = 0x09
    SUBB A, R1       ; C = 1 if ('9' - '0') - (x - '0') < 0 which means that x is outside the range '0'..'9'
    JC   INVALID_DIGIT     ; if C==1 Check next interval of values
;converting a VALID_DIGIT:
	INC  R3			 ; R3 holds the index of the character (which we will be converted to hex)
	MOV  A, R2        ; Reading the same character x to the accummulator
	SUBB A, #0x30    ; converting to the numerical value in hex
	MOV  R4, A	     ; storing the hex value
	SJMP WRITING	 ; we write the valid character
	
; Checking if an ASCII hex character is an upper case letter
; in the range 'A'..'F'. If so, it converts it. Otherwise it checks the
; next valid range
INVALID_DIGIT:
	;Checking if the character is in the range 'A'..'F' which is 0x41 to 0x46 in hex
	MOV  A, R2        ; Reading the same character x to the accummulator
	CLR  C		     ; clearing the carry so it can hold the result of validation
	SUBB A, #0x41    ; A = x - 'A'
	JC   INVALID_LOW_LETTER ; if the hex character is less than 0x41 then it's not a letter
    MOV  R1, A       ; R1 gets the value: x - 'A'
    MOV  A, #0x05    ; 'F' - 'A' = 0x46 - 0x41 = 0x05
    SUBB A, R1       ; C = 1 if ('F' - 'A') - (x - 'A') < 0 which means that x is outside the range 'A'..'F'
    JC   INVALID_UP_LETTER    ; if C==1 Check next interval of values
	
;converting the valid upper case letter
	INC  R3			 ; R3 holds the index of the character (which we will be converted to hex)
	MOV  A, R2        ; Reading the same character x to the accummulator
	SUBB A, #0x41    ; getting the number of the character in the range 1('A') .. 5('F')
	ADD  A, #0x0A     ; transforming it into hexadecimal 
	MOV  R4, A	     ; storing the hex value
	SJMP WRITING	 ; we write the valid character
	

; Checking if an ASCII hex character is a lower case letter
; in the range 'a'..'f'. If so, it converts it. Otherwise it checks
; whether the character is a terminating byte or invalid
INVALID_UP_LETTER:
	;Checking if the character is in the range 'a'..'f' which is 0x61 to 0x66 in hex
	MOV  A, R2        ; Reading the same character x to the accummulator
	CLR  C		     ; clearing the carry so it can hold the result of validation
	SUBB A, #0x61    ; A = x - 'a'
	JC   INVALID_LOW_LETTER ; if the hex character is less than 0x61 then it's not a lower case letter
    MOV  R1, A       ; R1 gets the value x - 'a'
    MOV  A, #0x05    ; 'f' - 'a' = 0x66 - 0x61 = 0x05
    SUBB A, R1       ; C = 1 if ('f' - 'a') - (x - 'a') < 0
    JC   INVALID_LOW_LETTER     ; if C = 1 check whether this is a terminating 0 byte (0x00) or invalid
	
;converting the valid lower case letter into binary
	INC  R3			 ; R3 holds the index of the character (which we will be converted to hex)
	MOV  A, R2        ; Reading the same character x to the accummulator
	SUBB A, #0x61    ; getting the number of the character in the range 1('a') .. 5('f')
	ADD  A, #0x0A     ; transforming it into hexadecimal 
	MOV  R4, A	     ; storing the hex value
	SJMP WRITING	 ; we write the valid character

; Checking whether the ASCII character is a terminating 0 byte or an invalid character
INVALID_LOW_LETTER:
	; If the character is not a valid ASCII hex code then we return with a set carry. 
	RET              ; returning with C==1

; Jumping to one of the subroutines to write a converted ASCII character into the right position
WRITING:	
	MOV  A, R3
	SUBB A, #0x02;    
	JC   WRITING_CHAR1   ; if R3==1, we have our first valid character it is written as the highest byte
	MOV  A, R3
	SUBB A, #0x03;
	JC   WRITING_CHAR2   ; if R3==2, we have our second valid character it is written as the second highest byte
	MOV  A, R3
	SUBB A, #0x04;
	JC   WRITING_CHAR3   ; if R3==3, we have our third valid character it is written as the second lowest byte
	MOV  A, R3
	SUBB A, #0x05;
	JC   WRITING_CHAR4   ; if R3==4, we have our fourth valid character it is written as the lowest byte
	

; Stores the converted ASCII hex character into highest byte of R5
WRITING_CHAR1:
	MOV A, R4         ; the valid converted ASCII hex is stored in R4
	MOV R5, A
	CLR C				; clearing the carry to use it for unvalid character detection
	RET
         
; Storing the converted ASCII hex character into the 2nd highest byte of R5	
WRITING_CHAR2:
	MOV B, #0x10
	MOV A, R5 
	MUL AB             ; changing the position of the byte stored in R5 one byte higher
	ADD A, R4
	MOV R5, A   	   ; concatenating the lower byte and the higher byte
	CLR C				; clearing the carry to use it for unvalid character detection
	RET

; Storing the converted ASCII hex character into highest byte of R6	
WRITING_CHAR3:
	MOV A, R4         ; the valid converted ASCII hex is stored in R4
	MOV R6, A
	CLR C				; clearing the carry to use it for unvalid character detection
	RET

; Storing the converted ASCII char into the 2nd highest byte of R6
WRITING_CHAR4:
	MOV B, #0x10
	MOV A, R6
	MUL AB			   ; changing the position of the hex stored in R6 one byte higher
	ADD A, R4
	MOV R6, A   	   ; concatenating the lower byte and the higher byte
	CLR C				; clearing the carry to use it for unvalid character detection
	RET
; ===================================================================           
;                           SUBROUTINE
; ===================================================================           


; -------------------------------------------------------------------
; READ_CHAR
; -------------------------------------------------------------------
; Purpose: Reads an ASCII hex character from the internal memory 
; and stores it in R2
; -------------------------------------------------------------------
; INPUT:
;   R7 - Base address of the input string in the internal memory
; OUTPUT(S): 
;   R2 - the ASCII hex character
; MODIFIES:
;   A, R0, R2
; -------------------------------------------------------------------	
READ_CHAR:
    MOV A, R7    ; Copying the the address stored in R7 to A
    MOV R0, A    ; Using R0 to use indirect addressing
    MOV A, @R0   ; Getting the value from the memory address
	MOV R2, A    ; Storing the value in register R2 for further use
	RET	


; End of the source file
END


org 100H

jmp _start 

;;****************************** variable section ***************************:	  
	  _temporary_opcode DB ' ' ; input opcode variable  
	  
	  _opening_message DB 'POSTFIX Calculator - (Developed for BOUN SWE-514 Project) ', 10, 13,'$'

	  _terminate_message DB 'To terminate all operations press t then press enter' , 10, 13,'$'
	  _warning DB 10, 13,'Give me the problem correctly : $'
	  
      _operation_codes DB '+*/^&|'    	; will be used to compare input
       _temp_token DW 0 ; number calculated  from _tmpdecimaldigit variable
	  _wrong_input DB 'Digits should be in range 0-F and upperCase please', 10, 13,'$'
   
	  _wrong_startpoint DB 'can you start with number please? ', 10, 13,'$'
   
	  _wrong_finishpoint  DB 'Operation should end with an opcode !' ,10, 13,'$'
	  _temporary_input DB ?   ; input variable 
	  _operation_error_handling DB 'Can you start operation codes with a space',10, 13,'$'
   
	  _result_capability DB 'I am amazingly intelligent. Here is your result : $'
	  
	  _lastresult Dw 0
	  _tmpdecimaldigit DW 0 ; hex letter variable
;************************** variable section ends *********************************

	


;************************** starting point *********************************
	
_start: 
	mov AH,9
	mov dx, offset _opening_message  ;print _opening_message
	int 21h
 	mov dx, offset _terminate_message ;print how to quit from calculator
	int 21h
    call _scanf ; get the user input        
;************************* char reading section ********************************
_scanf:   
	mov _temporary_input,'>'                    ; mov > to tem var
	mov _tmpdecimaldigit,0                      ; clear _tmpdecimaldigit
	mov _temp_token,0                           ; clear _temp_token
	mov _temporary_opcode,' ' 
	mov _lastresult,0                           ; clear _lastresult
	
	mov dx, offset _warning                      ; show _warning msg
	call _printf                                 ; keyboard interrupt
	mov bx,offset _temporary_input               ; mov bx to _temporary_input
	_readingloop:
		mov AH,01
		int 21h			                   	     ; read keyboard interrupt
		mov [bx],AL  	                         ; store key into _temporary_input
		inc bx 			  	                     ; point to next byte of _temporary_input	
		cmp AL,13                                ; enter key interrupt
		jne _readingloop 		                 ; do it until enter key pressed
		mov bx,offset _temporary_input   
		cmp b[bx],'t'		                     ; check if  w pressed
		jne _starterpoint 	                     ;if not pressed continue	
		inc bx				    
		cmp b[bx],13                            ;checking if enter pressed
		je  _terminate2dos		                     ; exit 2 dos 
		jmp _starterpoint                        ;else go on 
ret
;************************* char reading section end point ********************************
 

;************************* parsing section ********************************
_starterpoint:

    call _line_generator            ;after that all input goes into _temporary_input array. should travel whole array
	mov bx,offset _temporary_input	;mv bx to zero day point 
	mov si,bx  				        ;indicate the position of token	
	_loop_exec:
		mov dl,b[bx]		        ;Get the char array into dl temporarly
		cmp dl,13				;check if enter pressed
		je _finish_exec  	        ;if enter pressed go last step
		cmp dl,32	                ;check space entered
		jne __token_loop
				     
		call _tokenizer		        ;start tokenizer process
		
		__token_loop:               
        	inc bx		            ;continue to token 
			jmp _loop_exec
			
			
	_finish_exec:
		call _tokenizer		       ;continue to token for last char array
		call __printf_result 	   
		jmp _scanf		           ; turn back to scaning section  		 
		
;************************* parsing section ends ********************************	


;****************** result printing section  *****************************			 
__printf_result:           
    call _line_generator
	
	mov dx, offset _result_capability
	call _printf	   
	mov cx,4
	mov bx,_lastresult       
    _printloop:
        rol bx,4            ;leftmost rotate        
        mov dx,bx                  
        shl dx,12           ;shift left 
        shr dx,12           ;shift right 
        cmp dl,9            ;check lower than 10
        jg _letter2hex      ;go to hex converter
        add dl,'0'          ;else convert to string
        jmp _printfHEX 
		
        _letter2hex:
        add dl,'A'
        sub dl,10           ;find letter
        _printfHEX:
            mov AH,2        ;print the hex digit 
            int 21h  
			
        loop _printloop  
	    call _line_generator
	    jmp _scanf  ; _warning for a new exp. 

;****************** result printing section ends  *****************************	

;****************** DOS EXITIN section  *****************************	
_terminate2dos:
	int 20h
	
	

;****************** DOS EXITIN section ends  *****************************	 

;****************** Token Parsing Section ***************************** 
_tokenizer:
    pop bp                           ;save returning address 
    dec bx                           ;go to prev byte
    mov dl,b[bx]                     ;save it into dl
    inc bx                           ; inc to current byte
    call _opcode_controller	         ;control the byte member of  _operation_codes
    cmp cl,1  
    je _opcode_serializer 		     ;if current is _operation_codes then process it
    jmp _number_serializer	         ;else process as number
    _tokenimp_ret:
        mov si,bx 			         ;mark the next char pos after space as new token start 
    	inc si	    
    push bp                          ;save return address to bp   
    ret
;****************** Token Parsing Section ends *****************************  

		
;****************** Operation Code Parsing Section ***************************** 			    		
_opcode_serializer:
     pop cx                    ;take cx
     pop ax                    ;take ax
     mov dx,0	               ;clear dx 
    cmp _temporary_opcode,'^'  ;check xor
    je _x_or_exec    
    cmp _temporary_opcode,'+'  ;check add
    je _add_exec
    cmp _temporary_opcode,'&'  ;check and
    je _and_exec   
    cmp _temporary_opcode,'*'  ;check mul
    je _mul_exec
    cmp _temporary_opcode,'|'  ;check or
    je _or_exec
    cmp _temporary_opcode,'/'  ;check div
    je _div_exec                
    _mul_exec:
        mul cx
        jmp PUSH_OPCODE    
    _div_exec: 
        div cx
        jmp PUSH_OPCODE         
    _add_exec: 
        add ax,cx
        jmp PUSH_OPCODE
    _x_or_exec:
        xor ax,cx
        jmp PUSH_OPCODE 
    _or_exec:  
        or ax,cx
        jmp PUSH_OPCODE          
    _and_exec:  
        and ax,cx
        jmp PUSH_OPCODE           
    PUSH_OPCODE:    
        mov _lastresult,ax   ;  store the result in reg  
        push ax 
        jmp _tokenimp_ret    ; go _tokenimp_ret
		
		

;****************** Operation Code Parsing Section ends *****************************



;****************** Operation Code controller Section ***************************** 	
_opcode_controller:
	;result will store in cl , 0 = false | 1 = true --- operation store in _temporary_opcode variable 
	push bx 	                    
	mov bx,offset _operation_codes
	
	mov cx,6                              ;we have 6 different _operation_codes
	_opcode_controller_LOOP:
		cmp dl,b[bx]                      ; operation code in the string 
		je _opcode_controller_TRUE    
		inc bx
		loop _opcode_controller_LOOP      ;not opcode
		pop bx 		                      ;restore _start loop var 
		ret
		_opcode_controller_TRUE:
		mov CL,1
		mov _temporary_opcode,dl  
		pop bx 		                      ;restore _start lop var 
		ret		
;****************** Operation Code controller Section ends ***************************** 	

;****************** Hexnum Controller Section ***************************** 								
_hexnum_controller:
	cmp dl,'F'                       ;check if char greater than F
	jg _hexnum_controller_false    
	cmp dl ,'A'				         ;check if char lower than A then it is between 0 to 9	
	jl _digit_controller				 
	sub dl, 'A'					     ;convert 2 decimal number  
	add dl, 10
	jmp _hexnum_controller_true
	_digit_controller:               ;converter
		cmp dl,'0'                   ;check char < 0
		jl _hexnum_controller_false  
		cmp dl,'9'                   ;check char < 10
		jg _hexnum_controller_false  
		sub dl,'0'				     ;convert 2 decimal number 
		jmp _hexnum_controller_true 
	_hexnum_controller_true:   
		 mov dh,0
		 mov _tmpdecimaldigit,dx     ;store decimal number in _tmpdecimaldigit
		 ret
	_hexnum_controller_false:
		mov dx, offset _wrong_input  ;store input into _wrong_input
		call _printf
		jmp _scanf	  
;****************** Hexnum Controller Section ends ***************************** 

;****************** Printing Section ***************************** 		
_printf:
	mov ah,09h
	int 21h
	ret			
;******************  Printing Section ends ***************************** 


;****************** Line Generator Section ***************************** 
_line_generator:
	mov dl, 10
	mov AH, 02h
	int 21h
	mov dl, 13
	mov AH, 02h
	int 21h
	ret	
;****************** Line Generator Section ends***************************** 
          
;****************** Number serializer Section *****************************	 
_number_serializer:
	mov di,bx		; token start point is si , on the other hand token end point di
	xor ax,ax		; refresh ax
	mov cx,1		; refresh cx  
	_token_loop:
		cmp si,di   ; check if we come to end
		je __token_loop_end 
		mov dl,b[si]
		call _hexnum_controller  ; after that number would be converted into hex
		shl ax,4				  ;shift left 4 bit   
		add ax,_tmpdecimaldigit   ; put it into _tmpdecimaldigit
		cmp cx,4				  
		je __token_loop_end       ;compare if its lower than 5 bits
		inc cx					    ;update cx 
		inc si                    ;update si
		jmp _token_loop		
		
		__token_loop_end:   
			mov _temp_token,ax    ;number is into ax 
		    PUSH _temp_token	                     
		jmp _tokenimp_ret
;****************** Number serializer Section ends *****************************	 
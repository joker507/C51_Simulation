;直流电机调速实验

;实验连线
;1) DA0832单元的CS连接端口地址300CS
;2) DA0832单元的AOUT连接直流电机INV

CS0832  EQU 0300H
DA0V    EQU 00H
DA2V5   EQU 7FH
DA5V    EQU 0FFH

        org 0
        mov dptr,#CS0832

;mloop:;方波
 ;       mov a,#DA0V
 ;       movx @dptr,a
 ;       mov r7,#3
  ;      call delay
  ;      
  ;      mov a,#DA5V
  ;      movx @dptr,a
  ;      mov r7,#3
 ;     call delay
 ;       sjmp mloop

mloop:  mov a,#DA0v
loop: ;锯齿  
	movx @dptr, a
	inc a
	sjmp loop
	
delay:  mov r6,#00h
dl1:    mov r5,#00h
        djnz r5,$
        djnz r6,dl1
        djnz r7,delay
        ret

        END


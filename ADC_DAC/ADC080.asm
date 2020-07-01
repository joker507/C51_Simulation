CS0809  EQU 0300H
        org 0

start:  MOV DPTR,#CS0809
	;采用通讯中断
ADC:    MOVX @DPTR,A    ;0809的通道0采样
        nop
        nop
        nop
        nop
        nop
        MOVX A,@DPTR    ;取出采样值
        cpl a
        mov p1,a
        MOV  R7,#00H    ;延时    
        DJNZ R7,$
        SJMP ADC        ;循环

        END

;100% 11111111
;80%  11001100
;60%  10011001
;40%  01100110
;20%  00110011
;0%   00000000
68
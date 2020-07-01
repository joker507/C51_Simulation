
TEMPER_L   EQU 	41H     ;存放读出温度低位数据
TEMPER_H   EQU 	40H     ;存放读出温度高位数据
TEMPER_NUM EQU 	60H     ;存放转换后的温度值
FLAG1      BIT   10H
DQ         BIT  P3.3    ;一线总线控制端口;读出转换后的温度值
led0 equ 0fff0h
led1 equ 0fff1h
ledbuff equ 30h     
ORG 0000H
	MOV SP,#10H
	 MOV dptr,#led1     ;指向命令口
        MOV A,#00H         ;6个8位显示
        MOVX @dptr,a       ;方式字写入
        MOV A,#32H         ;设分频初值
        MOVX @dptr,a       ;分频字写入
        MOV A,#0DFH        ;定义清显字
        MOVX @dptr,a       ;关闭显示器
	MOV ledbuff ,#10H
		MOV ledbuff+1,#10H
		MOV ledbuff+2,#10H
		MOV ledbuff+3,#10H
		MOV ledbuff+4,#10H
		MOV ledbuff+5,#10H
mloop:   LCALL GET_TEMPER
         LCALL TEMPER_COV
	 mov a,TEMPER_NUM
	 mov b,a
	 swap a
	 anl a,#0fh
	 anl b,#0fh
	 MOV LedBuff,b
	 MOV LedBuff+1,a
	 LCALL DISP
	 SJMP mloop
GET_TEMPER:
        SETB DQ         ;定时入口
BCD:    LCALL INIT_1820
        JB FLAG1,S22
        LJMP BCD        ;若DS18B20不存在则返回
S22:    LCALL DISP
        MOV A,#0CCH     ;跳过ROM匹配------0CC
        LCALL WRITE_1820
        MOV A,#44H      ;发出温度转换命令
        LCALL WRITE_1820
        NOP
        LCALL DISP
CBA:    LCALL INIT_1820
        JB FLAG1,ABC
        LJMP CBA
ABC:    LCALL DISP
        MOV A,#0CCH     ;跳过ROM匹配
        LCALL WRITE_1820
        MOV A,#0BEH     ;发出读温度命令
        LCALL WRITE_1820
        LCALL READ_18200
        RET
	
;写DS18B20的程序
WRITE_1820:
        MOV R2,#8
        CLR C
WR1:    CLR DQ
        MOV R3,#3
        DJNZ R3,$
        RRC A
        MOV DQ,C
        MOV R3,#11
        DJNZ R3,$
        SETB DQ
        NOP
        DJNZ R2,WR1
        SETB DQ
        RET

READ_18200:
        MOV R4,#2       ;将温度高位和低位从DS18B20中读出
        MOV R1,#TEMPER_L     ;低位存入41H(TEMPER_L),高位存入40H(TEMPER_H)
RE00:   MOV R2,#8
RE01:   CLR C
        SETB DQ
        NOP
        NOP
        CLR DQ
        NOP
        NOP
        NOP
        SETB DQ
        MOV R3,#3
        DJNZ R3,$
        MOV C,DQ
        MOV R3,#16H
        DJNZ R3,$
        RRC A
        DJNZ R2,RE01
        MOV @R1,A
        DEC R1
        DJNZ R4,RE00
        RET
TEMPER_COV:
        MOV A,#0F0H
        ANL A,TEMPER_L  ;舍去温度低位中小数点后的四位温度数值
        SWAP A
        MOV TEMPER_NUM,A
        MOV A,TEMPER_L
        JNB ACC.3,TEMPER_COV1 ;四舍五入去温度值
        INC TEMPER_NUM
TEMPER_COV1:
        MOV A,TEMPER_H
        ANL A,#07H
        SWAP A
        ADD A,TEMPER_NUM
        MOV TEMPER_NUM,A ; 保存变换后的温度数据
        LCALL BIN_BCD
        RET
BIN_BCD:MOV DPTR,#TEMP_TAB
        MOV A,TEMPER_NUM
        MOVC A,@A+DPTR
        MOV TEMPER_NUM,A
        RET

TEMP_TAB:
        DB 00H,01H,02H,03H,04H,05H,06H,07H
        DB 08H,09H,10H,11H,12H,13H,14H,15H
        DB 16H,17H,18H,19H,20H,21H,22H,23H
        DB 24H,25H,26H,27H,28H,29H,30H,31H
        DB 32H,33H,34H,35H,36H,37H,38H,39H
        DB 40H,41H,42H,43H,44H,45H,46H,47H
        DB 48H,49H,50H,51H,52H,53H,54H,55H
        DB 56H,57H,58H,59H,60H,61H,62H,63H
        DB 64H,65H,66H,67H,68H,69H,70H,71H
        DB 72H,73H,74H,75H,76H,77H,78H,79H
        DB 80H,81H,82H,83H,84H,85H,86H,87H
        DB 88H,89H,90H,91H,92H,93H,94H,95H
        DB 96H,97H,98H,99H
INIT_1820:
        SETB DQ
        NOP
        CLR DQ
        MOV R0,#0EEh
TSR1:   DJNZ R0,TSR1    ;延时
        SETB DQ
        MOV R0,#25h     ;96us
TSR2:   DJNZ R0,TSR2
        JNB DQ,TSR3
        LJMP TSR4       ;延时
TSR3:   SETB FLAG1      ;置标志位,表示DS1820存在
        LJMP TSR5
TSR4:   CLR FLAG1       ;清标志位,表示DS1820不存在
        LJMP TSR7
TSR5:   MOV R0,#6Bh     ;200us
TSR6:   DJNZ R0,TSR6    ;延时
TSR7:   SETB DQ
        RET
;显示子程序
DISP:mov r1,#35h        ;从高位开始
        mov 38h,#85h
dilex:  mov dptr,#led1     ;送字位代码
        mov a,38h
        movx @dptr,a
        mov dptr,#ZOE0     ;索字形代码
        mov a,@r1
        movc a,@a+dptr
        mov dptr,#led0     ;送当前字形
        movx @dptr,a
        dec 38h
        dec r1
        cjne r1,#2fh,dilex ;末满六位转
        ret

ZOE0:   DB 0ch,9fh,4ah,0bh,99h,29h,28h,8fh,08h,09h,88h
;          0   1   2   3   4   5   6   7   8   9   a
        DB 38h,6ch,1ah,68h,0e8h,0ffh,0c0h
;          b   c   d   e   f    

        END

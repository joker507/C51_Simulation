        ORG 0000H
        AJMP START
        ORG 0100H
START:  MOV SP,#60H     ;给堆栈指针赋初值
        MOV TMOD,#20H   ;设置T1为方式2
        MOV SCON,#50H   ;设置串口工作方式1
        MOV TH1,#0FDH   ;设置波特率为9600
        MOV TL1,#0FDH
        MOV PCON,#00H
        SETB TR1        ;定时器1开始计数
MLOOP:  MOV A,P1
        ANL A,#0FH
        MOV SBUF,A
        JNB TI,$
        CLR TI
        JNB RI,$
        CLR RI
        MOV A,SBUF
        ORL A,#0F0H
        SWAP A
        MOV P1,A
        SJMP MLOOP
	END

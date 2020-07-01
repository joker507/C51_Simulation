        ORG 0000H
        AJMP START
	
	ORG 0023H       ;串行中断子程序
RTXD:	
	 PUSH PSW	;保护现场
	PUSH ACC
	 AJMP SBR1
	  	  
	 ORG 0100H
SBR1:	 
      ;判断是接受还是发出中断
       JNB RI, SEND ;发送
SIN:	;接收数据
        CLR RI
        MOV A,SBUF
        ORL A,#0F0H
        SWAP A
        MOV P1,A
        SJMP NEXT
SEND:	;发送数据
        CLR TI
        MOV A,P1	;发送下一个数据
        ANL A,#0FH
        MOV SBUF,A
NEXT:	;中断结束
	POP ACC		;恢复现场
	POP PSW
	RETI
	 
	ORG 0200H
START:  MOV SP,#60H     ;给堆栈指针赋初值
        MOV TMOD,#20H   ;设置T1为方式2
        MOV SCON,#50H   ;设置串口工作方式1
        MOV TH1,#0FDH   ;设置波特率为9600
        MOV TL1,#0FDH
        MOV PCON,#00H
        SETB TR1        ;定时器1开始计数
	
	MOV A,P1	;发送第一个数据
	ANL A,#0FH
        MOV SBUF,A
	
	SETB ES         ;修改：开中断
	SETB EA
	SJMP $
        END

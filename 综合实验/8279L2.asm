;======== 8279键盘、显示实验 ======
led0 equ 0fff0h
led1 equ 0fff1h
;==================================
        ORG 0000H
x900:   MOV SP,#40H
        MOV dptr,#led1     ;指向命令口
        MOV A,#00H         ;6个8位显示
        MOVX @dptr,a       ;方式字写入
        MOV A,#32H         ;设分频初值,18分频
        MOVX @dptr,a       ;分频字写入
        MOV A,#0DFH        ;定义清显示缓冲区命令字
        MOVX @dptr,a       ;清8279显示缓冲区RAM
x90s:   movx a,@dptr       ;清显示缓冲区需要一定时间，取8279状态
        JB ACC.7,x90s      ;若8279显示缓冲区忙转
;------------------------
;初态送显示缓冲区
;------------------------
xmos:   mov r0,#30h      ;定义30-35H为单片机的显示缓冲区，用于装要示的数
        mov a,#10h       ;显示初始值为“P”，其它位全灭，即11H和10H
x35s:    mov @r0,a       ;35H对应最左位
        inc r0
        cjne r0,#35h,x35s
        inc a
        mov @r0,a
;------------------------
;闪动位指向显缓区首址
;------------------------
        mov 36h,#30h     ;修改：#35h -30h按键缓冲区，最右边
;------------------------
;闪动的"p."态待令入口
;------------------------
xmon:   call dswey         ;调显示键扫
        cjne a,#10h,krds   ;判数字键还是功能键
krds:   jnc krdy           ;转功能键处理
;------------------------
;数字键送显缓区
;------------------------
        mov r1,36h
        mov @r1,a      ;键值存入35H—30H，最先按下的存入35H，之后依次存入34H..
;------------------------
;显示缓冲区调正
;------------------------
        ;dec r1            ;修改：不需要其他作为缓冲区，一直显示关闭的就行
        ;cjne r1,#2fh,krdx
        ;mov r1,#35h
	
krdx: 	mov a,#010h ;修改：当有按键时将p灭掉
	mov @r0, a
	mov 36h,r1
        sjmp xmon
;------------------------
;功能键处理入口
;------------------------
krdy:   mov dptr,#CKEY
        anl a,#03h
        clr c
        rl a
        mov r2,a
        inc a
        movc a,@a+dptr   ;xmos的低八位
        push acc
        mov a,r2
        movc a,@a+dptr   ;xmos的高八位
        push acc
        ret           ;返回xmos重新执行，即清除所有显示
;------------------------
;光标闪动显示键扫程序
;------------------------
dswey:  call diled      ;显示子程序
        mov r3,#0a8h
dswks:  call dikey       ;键盘扫描
        cjne a,#20h,dsend    ;有按键按下，转dsend，返回主程序判断按键
        djnz r3,dswks
        mov r1,36h       ;长时间无键按下，修改当前显示缓冲器的值为0ffh,灭
        mov a,@r1
        mov 37h,a
        mov a,#10h
        mov @r1,a
        call diled        ;当前显示位灭
        mov r3,#66h
dswes:  call dikey         ;再次调用按键扫描
        cjne a,#20h,dsond  ;若有按键按下，转dsond
        djnz r3,dswes
        mov r1,36h    ;若仍无按键按下，修改当前显示缓冲器的值为原值，当前显示位亮
        mov a,37h
        mov @r1,a
        sjmp dswey
dsond:  mov r1,36h     ;恢复当前显示位的原值，返回主程序
        xch a,37h       ;mov a,37h
        mov @r1,a
        mov a,37h
dsend:  ret
;-----------------------
;刷新显示子程序；单片机显示缓冲区的数值经过译码，送入8279显示缓冲区
;-----------------------
diled:  mov r1,#35h        ;从高位开始，单片机35H->05H
        mov 38h,#85h    ;写8279显示缓冲区，从05H开始
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
;-----------------------
;键盘扫描子程序
;-----------------------
dikey:  mov r4,#00h        ;设査键次数
dikrd:  mov dptr,#led1     ;指8279状态端口
        movx a,@dptr       ;读键盘标志
        anl a,#07h ;         保留低3位，即检测8279FIFO按键缓冲区
;  是否有数据，有按键按下就有数据
        jnz keys           ;有键按下转
        djnz r4,dikrd      ;未完继续査
        mov a,#20h         ;定义无键码
        ret                ;返回
keys:    mov a, #40h
        Movx @dptr, a     ;读8279FIFORAM命令
mov dptr,#led0     ;指向8279数据端口
        movx a,@dptr       ;读当前键码
        mov r2,a           ;存当前键码
        anl a,#03h         ;保留低二位，即行值，共4行，行值从00-11
        xch a,r2           ;取当前键码
        anl a,#38h         ;舍弃无效位，取列值，共5列，列值从000-100
        rr a               ;键码的压缩，即键值由列值与行值组成，范围是00000-10011
        orl a,r2           ;与低二拼接
        mov dptr,#GOJZ     ;指键码表首
        movc a,@a+dptr     ;查键码值
        ret                ;返回
;------------------------
;-------功能键定义
CKEY:   dw xmos,xmos,xmos,xmos
;       返p.
;------字形代码
ZOE0:   DB 0ch,9fh,4ah,0bh,99h,29h,28h,8fh,08h,09h,88h
;          0   1   2   3   4   5   6   7   8   9   a
        DB 38h,6ch,1ah,68h,0e8h,0ffh,0c0h
;          b   c   d   e   f    关闭  p.
;------按键代码(20h为溢出码)
GOJZ:   db 13h,12h,11h,10h,0dh,0ch,0bh,0ah,0eh,03h  ;对应按键f3,f2,f1,f0,d,c,b,a,e,3的键码
        db 06h,09h,0fh,02h,05h,08h,00h,01h,04h,07h   ;对应按键6,9,f,2,5,8,0,1,4,7的键码
        db 20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h;无按键按下的键码
;------按键对应键值
;       0e0h,0e1h,0d9h,0d1h,0e2h,0dah,0d2h,0e3h,0dbh,0d3h
;       0    1    2    3    4    5    6    7    8    9
;       0cbh,0cah,0c9h,0c8h,0d0h,0d8h,0c3h,0c2h,0c1h,0c0h
;       a    b    c    d    e    f    10   11   12   13
;--------------------------------------------------------
;------------------------
        END


;功能键处理-----=============================================
;扫描键盘，功能键是否按下
xmon:   call dikey         ;调显示键扫
        cjne a,#10h,krds   ;判数字键还是功能键
krds:   jnc krdy           ;转功能键处理
	ret
	;call krdx	   ;转数字键	不需要
	
;功能键处理
krdy:   mov dptr,#CKEY    ;功能键表头
        anl a,#03h
        clr c
        rl a
        mov r2,a
        inc a
        movc a,@a+dptr   ;xmos的低八位
        push acc
        mov a,r2
        movc a,@a+dptr   ;xmos的高八位
        push acc
        ret           ;返回xmos重新执行，即清除所有显示
	
;数字键处理（高低温阈值修改）
WRITH:

	ret

WRITL:

	ret

	
;键盘扫描子程序
dikey:  mov r4,#00h        ;设査键次数
dikrd:  mov dptr,#led1     ;指8279状态端口
        movx a,@dptr       ;读键盘标志
        anl a,#07h ;         保留低3位，即检测8279FIFO按键缓冲区
;  是否有数据，有按键按下就有数据
        jnz keys           ;有键按下转
        djnz r4,dikrd      ;未完继续査
        mov a,#20h         ;定义无键码
        ret                ;返回
keys:    mov a, #40h
        Movx @dptr, a     ;读8279FIFORAM命令
mov dptr,#led0     ;指向8279数据端口
        movx a,@dptr       ;读当前键码
        mov r2,a           ;存当前键码
        anl a,#03h         ;保留低二位，即行值，共4行，行值从00-11
        xch a,r2           ;取当前键码
        anl a,#38h         ;舍弃无效位，取列值，共5列，列值从000-100
        rr a               ;键码的压缩，即键值由列值与行值组成，范围是00000-10011
        orl a,r2           ;与低二拼接
        mov dptr,#GOJZ     ;指键码表首
        movc a,@a+dptr     ;查键码值
        ret                ;返回
;------------------------


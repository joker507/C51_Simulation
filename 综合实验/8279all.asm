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
        mov 36h,#35h
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
        dec r1
        cjne r1,#2fh,krdx
        mov r1,#35h
krdx:   mov 36h,r1
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

;------------------------
        END


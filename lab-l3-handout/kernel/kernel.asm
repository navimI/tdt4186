
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a0013103          	ld	sp,-1536(sp) # 80008a00 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	a1e70713          	addi	a4,a4,-1506 # 80008a70 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	01c78793          	addi	a5,a5,28 # 80006080 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc91f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	eae78793          	addi	a5,a5,-338 # 80000f5c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:

//
// user write()s to the console go here.
//
int consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
    int i;

    for (i = 0; i < n; i++)
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	622080e7          	jalr	1570(ra) # 8000274e <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
            break;
        uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	7a6080e7          	jalr	1958(ra) # 800008e2 <uartputc>
    for (i = 0; i < n; i++)
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
    }

    return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
    for (i = 0; i < n; i++)
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
    uint target;
    int c;
    char cbuf;

    target = n;
    80000188:	00060b9b          	sext.w	s7,a2
    acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	a2450513          	addi	a0,a0,-1500 # 80010bb0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	b1e080e7          	jalr	-1250(ra) # 80000cb2 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	a1448493          	addi	s1,s1,-1516 # 80010bb0 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	aa290913          	addi	s2,s2,-1374 # 80010c48 <cons+0x98>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

        if (c == C('D'))
    800001ae:	4c91                	li	s9,4
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
            break;

        dst++;
        --n;

        if (c == '\n')
    800001b2:	4da9                	li	s11,10
    while (n > 0)
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
        while (cons.r == cons.w)
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
            if (killed(myproc()))
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	9c8080e7          	jalr	-1592(ra) # 80001b8c <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	3cc080e7          	jalr	972(ra) # 80002598 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
            sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	116080e7          	jalr	278(ra) # 800022f0 <sleep>
        while (cons.r == cons.w)
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
        if (c == C('D'))
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
        cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	4e2080e7          	jalr	1250(ra) # 800026f8 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
        dst++;
    80000222:	0a85                	addi	s5,s5,1
        --n;
    80000224:	3a7d                	addiw	s4,s4,-1
        if (c == '\n')
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	98650513          	addi	a0,a0,-1658 # 80010bb0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	b34080e7          	jalr	-1228(ra) # 80000d66 <release>

    return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
                release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	97050513          	addi	a0,a0,-1680 # 80010bb0 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	b1e080e7          	jalr	-1250(ra) # 80000d66 <release>
                return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
            if (n < target)
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
                cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	9cf72823          	sw	a5,-1584(a4) # 80010c48 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
    if (c == BACKSPACE)
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
        uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	576080e7          	jalr	1398(ra) # 80000808 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
        uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	564080e7          	jalr	1380(ra) # 80000808 <uartputc_sync>
        uartputc_sync(' ');
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	558080e7          	jalr	1368(ra) # 80000808 <uartputc_sync>
        uartputc_sync('\b');
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	54e080e7          	jalr	1358(ra) # 80000808 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    800002d2:	00011517          	auipc	a0,0x11
    800002d6:	8de50513          	addi	a0,a0,-1826 # 80010bb0 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	9d8080e7          	jalr	-1576(ra) # 80000cb2 <acquire>

    switch (c)
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
    {
    case C('P'): // Print process list.
        procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	4ac080e7          	jalr	1196(ra) # 800027a4 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	8b050513          	addi	a0,a0,-1872 # 80010bb0 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	a5e080e7          	jalr	-1442(ra) # 80000d66 <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
    switch (c)
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    80000324:	00011717          	auipc	a4,0x11
    80000328:	88c70713          	addi	a4,a4,-1908 # 80010bb0 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
            c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
            consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00011797          	auipc	a5,0x11
    80000352:	86278793          	addi	a5,a5,-1950 # 80010bb0 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
            if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE)
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00011797          	auipc	a5,0x11
    80000380:	8cc7a783          	lw	a5,-1844(a5) # 80010c48 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	82070713          	addi	a4,a4,-2016 # 80010bb0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	81048493          	addi	s1,s1,-2032 # 80010bb0 <cons>
        while (cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
        while (cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
            cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
            consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
        while (cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
        if (cons.e != cons.w)
    800003dc:	00010717          	auipc	a4,0x10
    800003e0:	7d470713          	addi	a4,a4,2004 # 80010bb0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
            cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	84f72f23          	sw	a5,-1954(a4) # 80010c50 <cons+0xa0>
            consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
            consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	79878793          	addi	a5,a5,1944 # 80010bb0 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    8000043c:	00011797          	auipc	a5,0x11
    80000440:	80c7a823          	sw	a2,-2032(a5) # 80010c4c <cons+0x9c>
                wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	80450513          	addi	a0,a0,-2044 # 80010c48 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	f08080e7          	jalr	-248(ra) # 80002354 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bc258593          	addi	a1,a1,-1086 # 80008020 <__func__.1508+0x18>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	74a50513          	addi	a0,a0,1866 # 80010bb0 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	7b4080e7          	jalr	1972(ra) # 80000c22 <initlock>

    uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	342080e7          	jalr	834(ra) # 800007b8 <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	8ca78793          	addi	a5,a5,-1846 # 80020d48 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
    char buf[16];
    int i;
    uint x;

    if (sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
        x = -xx;
    else
        x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

    i = 0;
    800004bc:	4701                	li	a4,0
    do
    {
        buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b9060613          	addi	a2,a2,-1136 # 80008050 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
    } while ((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

    if (sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
        buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

    while (--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
        consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
    while (--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
        x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
    if (sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
        x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    if (locking)
        release(&pr.lock);
}

void panic(char *s, ...)
{
    80000544:	711d                	addi	sp,sp,-96
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
    80000550:	e40c                	sd	a1,8(s0)
    80000552:	e810                	sd	a2,16(s0)
    80000554:	ec14                	sd	a3,24(s0)
    80000556:	f018                	sd	a4,32(s0)
    80000558:	f41c                	sd	a5,40(s0)
    8000055a:	03043823          	sd	a6,48(s0)
    8000055e:	03143c23          	sd	a7,56(s0)
    pr.locking = 0;
    80000562:	00010797          	auipc	a5,0x10
    80000566:	7007a723          	sw	zero,1806(a5) # 80010c70 <pr+0x18>
    printf("panic: ");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	abe50513          	addi	a0,a0,-1346 # 80008028 <__func__.1508+0x20>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	02e080e7          	jalr	46(ra) # 800005a0 <printf>
    printf(s);
    8000057a:	8526                	mv	a0,s1
    8000057c:	00000097          	auipc	ra,0x0
    80000580:	024080e7          	jalr	36(ra) # 800005a0 <printf>
    printf("\n");
    80000584:	00008517          	auipc	a0,0x8
    80000588:	b0450513          	addi	a0,a0,-1276 # 80008088 <digits+0x38>
    8000058c:	00000097          	auipc	ra,0x0
    80000590:	014080e7          	jalr	20(ra) # 800005a0 <printf>
    panicked = 1; // freeze uart output from other CPUs
    80000594:	4785                	li	a5,1
    80000596:	00008717          	auipc	a4,0x8
    8000059a:	48f72523          	sw	a5,1162(a4) # 80008a20 <panicked>
    for (;;)
    8000059e:	a001                	j	8000059e <panic+0x5a>

00000000800005a0 <printf>:
{
    800005a0:	7131                	addi	sp,sp,-192
    800005a2:	fc86                	sd	ra,120(sp)
    800005a4:	f8a2                	sd	s0,112(sp)
    800005a6:	f4a6                	sd	s1,104(sp)
    800005a8:	f0ca                	sd	s2,96(sp)
    800005aa:	ecce                	sd	s3,88(sp)
    800005ac:	e8d2                	sd	s4,80(sp)
    800005ae:	e4d6                	sd	s5,72(sp)
    800005b0:	e0da                	sd	s6,64(sp)
    800005b2:	fc5e                	sd	s7,56(sp)
    800005b4:	f862                	sd	s8,48(sp)
    800005b6:	f466                	sd	s9,40(sp)
    800005b8:	f06a                	sd	s10,32(sp)
    800005ba:	ec6e                	sd	s11,24(sp)
    800005bc:	0100                	addi	s0,sp,128
    800005be:	8a2a                	mv	s4,a0
    800005c0:	e40c                	sd	a1,8(s0)
    800005c2:	e810                	sd	a2,16(s0)
    800005c4:	ec14                	sd	a3,24(s0)
    800005c6:	f018                	sd	a4,32(s0)
    800005c8:	f41c                	sd	a5,40(s0)
    800005ca:	03043823          	sd	a6,48(s0)
    800005ce:	03143c23          	sd	a7,56(s0)
    locking = pr.locking;
    800005d2:	00010d97          	auipc	s11,0x10
    800005d6:	69edad83          	lw	s11,1694(s11) # 80010c70 <pr+0x18>
    if (locking)
    800005da:	020d9b63          	bnez	s11,80000610 <printf+0x70>
    if (fmt == 0)
    800005de:	040a0263          	beqz	s4,80000622 <printf+0x82>
    va_start(ap, fmt);
    800005e2:	00840793          	addi	a5,s0,8
    800005e6:	f8f43423          	sd	a5,-120(s0)
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    800005ea:	000a4503          	lbu	a0,0(s4)
    800005ee:	16050263          	beqz	a0,80000752 <printf+0x1b2>
    800005f2:	4481                	li	s1,0
        if (c != '%')
    800005f4:	02500a93          	li	s5,37
        switch (c)
    800005f8:	07000b13          	li	s6,112
    consputc('x');
    800005fc:	4d41                	li	s10,16
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005fe:	00008b97          	auipc	s7,0x8
    80000602:	a52b8b93          	addi	s7,s7,-1454 # 80008050 <digits>
        switch (c)
    80000606:	07300c93          	li	s9,115
    8000060a:	06400c13          	li	s8,100
    8000060e:	a82d                	j	80000648 <printf+0xa8>
        acquire(&pr.lock);
    80000610:	00010517          	auipc	a0,0x10
    80000614:	64850513          	addi	a0,a0,1608 # 80010c58 <pr>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	69a080e7          	jalr	1690(ra) # 80000cb2 <acquire>
    80000620:	bf7d                	j	800005de <printf+0x3e>
        panic("null fmt");
    80000622:	00008517          	auipc	a0,0x8
    80000626:	a1650513          	addi	a0,a0,-1514 # 80008038 <__func__.1508+0x30>
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	f1a080e7          	jalr	-230(ra) # 80000544 <panic>
            consputc(c);
    80000632:	00000097          	auipc	ra,0x0
    80000636:	c50080e7          	jalr	-944(ra) # 80000282 <consputc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c503          	lbu	a0,0(a5)
    80000644:	10050763          	beqz	a0,80000752 <printf+0x1b2>
        if (c != '%')
    80000648:	ff5515e3          	bne	a0,s5,80000632 <printf+0x92>
        c = fmt[++i] & 0xff;
    8000064c:	2485                	addiw	s1,s1,1
    8000064e:	009a07b3          	add	a5,s4,s1
    80000652:	0007c783          	lbu	a5,0(a5)
    80000656:	0007891b          	sext.w	s2,a5
        if (c == 0)
    8000065a:	cfe5                	beqz	a5,80000752 <printf+0x1b2>
        switch (c)
    8000065c:	05678a63          	beq	a5,s6,800006b0 <printf+0x110>
    80000660:	02fb7663          	bgeu	s6,a5,8000068c <printf+0xec>
    80000664:	09978963          	beq	a5,s9,800006f6 <printf+0x156>
    80000668:	07800713          	li	a4,120
    8000066c:	0ce79863          	bne	a5,a4,8000073c <printf+0x19c>
            printint(va_arg(ap, int), 16, 1);
    80000670:	f8843783          	ld	a5,-120(s0)
    80000674:	00878713          	addi	a4,a5,8
    80000678:	f8e43423          	sd	a4,-120(s0)
    8000067c:	4605                	li	a2,1
    8000067e:	85ea                	mv	a1,s10
    80000680:	4388                	lw	a0,0(a5)
    80000682:	00000097          	auipc	ra,0x0
    80000686:	e20080e7          	jalr	-480(ra) # 800004a2 <printint>
            break;
    8000068a:	bf45                	j	8000063a <printf+0x9a>
        switch (c)
    8000068c:	0b578263          	beq	a5,s5,80000730 <printf+0x190>
    80000690:	0b879663          	bne	a5,s8,8000073c <printf+0x19c>
            printint(va_arg(ap, int), 10, 1);
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	4605                	li	a2,1
    800006a2:	45a9                	li	a1,10
    800006a4:	4388                	lw	a0,0(a5)
    800006a6:	00000097          	auipc	ra,0x0
    800006aa:	dfc080e7          	jalr	-516(ra) # 800004a2 <printint>
            break;
    800006ae:	b771                	j	8000063a <printf+0x9a>
            printptr(va_arg(ap, uint64));
    800006b0:	f8843783          	ld	a5,-120(s0)
    800006b4:	00878713          	addi	a4,a5,8
    800006b8:	f8e43423          	sd	a4,-120(s0)
    800006bc:	0007b983          	ld	s3,0(a5)
    consputc('0');
    800006c0:	03000513          	li	a0,48
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	bbe080e7          	jalr	-1090(ra) # 80000282 <consputc>
    consputc('x');
    800006cc:	07800513          	li	a0,120
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bb2080e7          	jalr	-1102(ra) # 80000282 <consputc>
    800006d8:	896a                	mv	s2,s10
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006da:	03c9d793          	srli	a5,s3,0x3c
    800006de:	97de                	add	a5,a5,s7
    800006e0:	0007c503          	lbu	a0,0(a5)
    800006e4:	00000097          	auipc	ra,0x0
    800006e8:	b9e080e7          	jalr	-1122(ra) # 80000282 <consputc>
    for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006ec:	0992                	slli	s3,s3,0x4
    800006ee:	397d                	addiw	s2,s2,-1
    800006f0:	fe0915e3          	bnez	s2,800006da <printf+0x13a>
    800006f4:	b799                	j	8000063a <printf+0x9a>
            if ((s = va_arg(ap, char *)) == 0)
    800006f6:	f8843783          	ld	a5,-120(s0)
    800006fa:	00878713          	addi	a4,a5,8
    800006fe:	f8e43423          	sd	a4,-120(s0)
    80000702:	0007b903          	ld	s2,0(a5)
    80000706:	00090e63          	beqz	s2,80000722 <printf+0x182>
            for (; *s; s++)
    8000070a:	00094503          	lbu	a0,0(s2)
    8000070e:	d515                	beqz	a0,8000063a <printf+0x9a>
                consputc(*s);
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b72080e7          	jalr	-1166(ra) # 80000282 <consputc>
            for (; *s; s++)
    80000718:	0905                	addi	s2,s2,1
    8000071a:	00094503          	lbu	a0,0(s2)
    8000071e:	f96d                	bnez	a0,80000710 <printf+0x170>
    80000720:	bf29                	j	8000063a <printf+0x9a>
                s = "(null)";
    80000722:	00008917          	auipc	s2,0x8
    80000726:	90e90913          	addi	s2,s2,-1778 # 80008030 <__func__.1508+0x28>
            for (; *s; s++)
    8000072a:	02800513          	li	a0,40
    8000072e:	b7cd                	j	80000710 <printf+0x170>
            consputc('%');
    80000730:	8556                	mv	a0,s5
    80000732:	00000097          	auipc	ra,0x0
    80000736:	b50080e7          	jalr	-1200(ra) # 80000282 <consputc>
            break;
    8000073a:	b701                	j	8000063a <printf+0x9a>
            consputc('%');
    8000073c:	8556                	mv	a0,s5
    8000073e:	00000097          	auipc	ra,0x0
    80000742:	b44080e7          	jalr	-1212(ra) # 80000282 <consputc>
            consputc(c);
    80000746:	854a                	mv	a0,s2
    80000748:	00000097          	auipc	ra,0x0
    8000074c:	b3a080e7          	jalr	-1222(ra) # 80000282 <consputc>
            break;
    80000750:	b5ed                	j	8000063a <printf+0x9a>
    if (locking)
    80000752:	020d9163          	bnez	s11,80000774 <printf+0x1d4>
}
    80000756:	70e6                	ld	ra,120(sp)
    80000758:	7446                	ld	s0,112(sp)
    8000075a:	74a6                	ld	s1,104(sp)
    8000075c:	7906                	ld	s2,96(sp)
    8000075e:	69e6                	ld	s3,88(sp)
    80000760:	6a46                	ld	s4,80(sp)
    80000762:	6aa6                	ld	s5,72(sp)
    80000764:	6b06                	ld	s6,64(sp)
    80000766:	7be2                	ld	s7,56(sp)
    80000768:	7c42                	ld	s8,48(sp)
    8000076a:	7ca2                	ld	s9,40(sp)
    8000076c:	7d02                	ld	s10,32(sp)
    8000076e:	6de2                	ld	s11,24(sp)
    80000770:	6129                	addi	sp,sp,192
    80000772:	8082                	ret
        release(&pr.lock);
    80000774:	00010517          	auipc	a0,0x10
    80000778:	4e450513          	addi	a0,a0,1252 # 80010c58 <pr>
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	5ea080e7          	jalr	1514(ra) # 80000d66 <release>
}
    80000784:	bfc9                	j	80000756 <printf+0x1b6>

0000000080000786 <printfinit>:
        ;
}

void printfinit(void)
{
    80000786:	1101                	addi	sp,sp,-32
    80000788:	ec06                	sd	ra,24(sp)
    8000078a:	e822                	sd	s0,16(sp)
    8000078c:	e426                	sd	s1,8(sp)
    8000078e:	1000                	addi	s0,sp,32
    initlock(&pr.lock, "pr");
    80000790:	00010497          	auipc	s1,0x10
    80000794:	4c848493          	addi	s1,s1,1224 # 80010c58 <pr>
    80000798:	00008597          	auipc	a1,0x8
    8000079c:	8b058593          	addi	a1,a1,-1872 # 80008048 <__func__.1508+0x40>
    800007a0:	8526                	mv	a0,s1
    800007a2:	00000097          	auipc	ra,0x0
    800007a6:	480080e7          	jalr	1152(ra) # 80000c22 <initlock>
    pr.locking = 1;
    800007aa:	4785                	li	a5,1
    800007ac:	cc9c                	sw	a5,24(s1)
}
    800007ae:	60e2                	ld	ra,24(sp)
    800007b0:	6442                	ld	s0,16(sp)
    800007b2:	64a2                	ld	s1,8(sp)
    800007b4:	6105                	addi	sp,sp,32
    800007b6:	8082                	ret

00000000800007b8 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007b8:	1141                	addi	sp,sp,-16
    800007ba:	e406                	sd	ra,8(sp)
    800007bc:	e022                	sd	s0,0(sp)
    800007be:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007c0:	100007b7          	lui	a5,0x10000
    800007c4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007c8:	f8000713          	li	a4,-128
    800007cc:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007d0:	470d                	li	a4,3
    800007d2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007da:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007de:	469d                	li	a3,7
    800007e0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007e4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007e8:	00008597          	auipc	a1,0x8
    800007ec:	88058593          	addi	a1,a1,-1920 # 80008068 <digits+0x18>
    800007f0:	00010517          	auipc	a0,0x10
    800007f4:	48850513          	addi	a0,a0,1160 # 80010c78 <uart_tx_lock>
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	42a080e7          	jalr	1066(ra) # 80000c22 <initlock>
}
    80000800:	60a2                	ld	ra,8(sp)
    80000802:	6402                	ld	s0,0(sp)
    80000804:	0141                	addi	sp,sp,16
    80000806:	8082                	ret

0000000080000808 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000808:	1101                	addi	sp,sp,-32
    8000080a:	ec06                	sd	ra,24(sp)
    8000080c:	e822                	sd	s0,16(sp)
    8000080e:	e426                	sd	s1,8(sp)
    80000810:	1000                	addi	s0,sp,32
    80000812:	84aa                	mv	s1,a0
  push_off();
    80000814:	00000097          	auipc	ra,0x0
    80000818:	452080e7          	jalr	1106(ra) # 80000c66 <push_off>

  if(panicked){
    8000081c:	00008797          	auipc	a5,0x8
    80000820:	2047a783          	lw	a5,516(a5) # 80008a20 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000824:	10000737          	lui	a4,0x10000
  if(panicked){
    80000828:	c391                	beqz	a5,8000082c <uartputc_sync+0x24>
    for(;;)
    8000082a:	a001                	j	8000082a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000082c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000830:	0ff7f793          	andi	a5,a5,255
    80000834:	0207f793          	andi	a5,a5,32
    80000838:	dbf5                	beqz	a5,8000082c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000083a:	0ff4f793          	andi	a5,s1,255
    8000083e:	10000737          	lui	a4,0x10000
    80000842:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000846:	00000097          	auipc	ra,0x0
    8000084a:	4c0080e7          	jalr	1216(ra) # 80000d06 <pop_off>
}
    8000084e:	60e2                	ld	ra,24(sp)
    80000850:	6442                	ld	s0,16(sp)
    80000852:	64a2                	ld	s1,8(sp)
    80000854:	6105                	addi	sp,sp,32
    80000856:	8082                	ret

0000000080000858 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000858:	00008717          	auipc	a4,0x8
    8000085c:	1d073703          	ld	a4,464(a4) # 80008a28 <uart_tx_r>
    80000860:	00008797          	auipc	a5,0x8
    80000864:	1d07b783          	ld	a5,464(a5) # 80008a30 <uart_tx_w>
    80000868:	06e78c63          	beq	a5,a4,800008e0 <uartstart+0x88>
{
    8000086c:	7139                	addi	sp,sp,-64
    8000086e:	fc06                	sd	ra,56(sp)
    80000870:	f822                	sd	s0,48(sp)
    80000872:	f426                	sd	s1,40(sp)
    80000874:	f04a                	sd	s2,32(sp)
    80000876:	ec4e                	sd	s3,24(sp)
    80000878:	e852                	sd	s4,16(sp)
    8000087a:	e456                	sd	s5,8(sp)
    8000087c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	00010a17          	auipc	s4,0x10
    80000886:	3f6a0a13          	addi	s4,s4,1014 # 80010c78 <uart_tx_lock>
    uart_tx_r += 1;
    8000088a:	00008497          	auipc	s1,0x8
    8000088e:	19e48493          	addi	s1,s1,414 # 80008a28 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000892:	00008997          	auipc	s3,0x8
    80000896:	19e98993          	addi	s3,s3,414 # 80008a30 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000089a:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000089e:	0ff7f793          	andi	a5,a5,255
    800008a2:	0207f793          	andi	a5,a5,32
    800008a6:	c785                	beqz	a5,800008ce <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008a8:	01f77793          	andi	a5,a4,31
    800008ac:	97d2                	add	a5,a5,s4
    800008ae:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008b2:	0705                	addi	a4,a4,1
    800008b4:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b6:	8526                	mv	a0,s1
    800008b8:	00002097          	auipc	ra,0x2
    800008bc:	a9c080e7          	jalr	-1380(ra) # 80002354 <wakeup>
    
    WriteReg(THR, c);
    800008c0:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c4:	6098                	ld	a4,0(s1)
    800008c6:	0009b783          	ld	a5,0(s3)
    800008ca:	fce798e3          	bne	a5,a4,8000089a <uartstart+0x42>
  }
}
    800008ce:	70e2                	ld	ra,56(sp)
    800008d0:	7442                	ld	s0,48(sp)
    800008d2:	74a2                	ld	s1,40(sp)
    800008d4:	7902                	ld	s2,32(sp)
    800008d6:	69e2                	ld	s3,24(sp)
    800008d8:	6a42                	ld	s4,16(sp)
    800008da:	6aa2                	ld	s5,8(sp)
    800008dc:	6121                	addi	sp,sp,64
    800008de:	8082                	ret
    800008e0:	8082                	ret

00000000800008e2 <uartputc>:
{
    800008e2:	7179                	addi	sp,sp,-48
    800008e4:	f406                	sd	ra,40(sp)
    800008e6:	f022                	sd	s0,32(sp)
    800008e8:	ec26                	sd	s1,24(sp)
    800008ea:	e84a                	sd	s2,16(sp)
    800008ec:	e44e                	sd	s3,8(sp)
    800008ee:	e052                	sd	s4,0(sp)
    800008f0:	1800                	addi	s0,sp,48
    800008f2:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f4:	00010517          	auipc	a0,0x10
    800008f8:	38450513          	addi	a0,a0,900 # 80010c78 <uart_tx_lock>
    800008fc:	00000097          	auipc	ra,0x0
    80000900:	3b6080e7          	jalr	950(ra) # 80000cb2 <acquire>
  if(panicked){
    80000904:	00008797          	auipc	a5,0x8
    80000908:	11c7a783          	lw	a5,284(a5) # 80008a20 <panicked>
    8000090c:	e7c9                	bnez	a5,80000996 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008797          	auipc	a5,0x8
    80000912:	1227b783          	ld	a5,290(a5) # 80008a30 <uart_tx_w>
    80000916:	00008717          	auipc	a4,0x8
    8000091a:	11273703          	ld	a4,274(a4) # 80008a28 <uart_tx_r>
    8000091e:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000922:	00010a17          	auipc	s4,0x10
    80000926:	356a0a13          	addi	s4,s4,854 # 80010c78 <uart_tx_lock>
    8000092a:	00008497          	auipc	s1,0x8
    8000092e:	0fe48493          	addi	s1,s1,254 # 80008a28 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000932:	00008917          	auipc	s2,0x8
    80000936:	0fe90913          	addi	s2,s2,254 # 80008a30 <uart_tx_w>
    8000093a:	00f71f63          	bne	a4,a5,80000958 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000093e:	85d2                	mv	a1,s4
    80000940:	8526                	mv	a0,s1
    80000942:	00002097          	auipc	ra,0x2
    80000946:	9ae080e7          	jalr	-1618(ra) # 800022f0 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000094a:	00093783          	ld	a5,0(s2)
    8000094e:	6098                	ld	a4,0(s1)
    80000950:	02070713          	addi	a4,a4,32
    80000954:	fef705e3          	beq	a4,a5,8000093e <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000958:	00010497          	auipc	s1,0x10
    8000095c:	32048493          	addi	s1,s1,800 # 80010c78 <uart_tx_lock>
    80000960:	01f7f713          	andi	a4,a5,31
    80000964:	9726                	add	a4,a4,s1
    80000966:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    8000096a:	0785                	addi	a5,a5,1
    8000096c:	00008717          	auipc	a4,0x8
    80000970:	0cf73223          	sd	a5,196(a4) # 80008a30 <uart_tx_w>
  uartstart();
    80000974:	00000097          	auipc	ra,0x0
    80000978:	ee4080e7          	jalr	-284(ra) # 80000858 <uartstart>
  release(&uart_tx_lock);
    8000097c:	8526                	mv	a0,s1
    8000097e:	00000097          	auipc	ra,0x0
    80000982:	3e8080e7          	jalr	1000(ra) # 80000d66 <release>
}
    80000986:	70a2                	ld	ra,40(sp)
    80000988:	7402                	ld	s0,32(sp)
    8000098a:	64e2                	ld	s1,24(sp)
    8000098c:	6942                	ld	s2,16(sp)
    8000098e:	69a2                	ld	s3,8(sp)
    80000990:	6a02                	ld	s4,0(sp)
    80000992:	6145                	addi	sp,sp,48
    80000994:	8082                	ret
    for(;;)
    80000996:	a001                	j	80000996 <uartputc+0xb4>

0000000080000998 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000998:	1141                	addi	sp,sp,-16
    8000099a:	e422                	sd	s0,8(sp)
    8000099c:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a6:	8b85                	andi	a5,a5,1
    800009a8:	cb91                	beqz	a5,800009bc <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009aa:	100007b7          	lui	a5,0x10000
    800009ae:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b2:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b6:	6422                	ld	s0,8(sp)
    800009b8:	0141                	addi	sp,sp,16
    800009ba:	8082                	ret
    return -1;
    800009bc:	557d                	li	a0,-1
    800009be:	bfe5                	j	800009b6 <uartgetc+0x1e>

00000000800009c0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009c0:	1101                	addi	sp,sp,-32
    800009c2:	ec06                	sd	ra,24(sp)
    800009c4:	e822                	sd	s0,16(sp)
    800009c6:	e426                	sd	s1,8(sp)
    800009c8:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ca:	54fd                	li	s1,-1
    int c = uartgetc();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	fcc080e7          	jalr	-52(ra) # 80000998 <uartgetc>
    if(c == -1)
    800009d4:	00950763          	beq	a0,s1,800009e2 <uartintr+0x22>
      break;
    consoleintr(c);
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	8ec080e7          	jalr	-1812(ra) # 800002c4 <consoleintr>
  while(1){
    800009e0:	b7f5                	j	800009cc <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e2:	00010497          	auipc	s1,0x10
    800009e6:	29648493          	addi	s1,s1,662 # 80010c78 <uart_tx_lock>
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2c6080e7          	jalr	710(ra) # 80000cb2 <acquire>
  uartstart();
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	e64080e7          	jalr	-412(ra) # 80000858 <uartstart>
  release(&uart_tx_lock);
    800009fc:	8526                	mv	a0,s1
    800009fe:	00000097          	auipc	ra,0x0
    80000a02:	368080e7          	jalr	872(ra) # 80000d66 <release>
}
    80000a06:	60e2                	ld	ra,24(sp)
    80000a08:	6442                	ld	s0,16(sp)
    80000a0a:	64a2                	ld	s1,8(sp)
    80000a0c:	6105                	addi	sp,sp,32
    80000a0e:	8082                	ret

0000000080000a10 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    80000a10:	1101                	addi	sp,sp,-32
    80000a12:	ec06                	sd	ra,24(sp)
    80000a14:	e822                	sd	s0,16(sp)
    80000a16:	e426                	sd	s1,8(sp)
    80000a18:	e04a                	sd	s2,0(sp)
    80000a1a:	1000                	addi	s0,sp,32
    80000a1c:	84aa                	mv	s1,a0
    if (MAX_PAGES != 0)
    80000a1e:	00008797          	auipc	a5,0x8
    80000a22:	0227b783          	ld	a5,34(a5) # 80008a40 <MAX_PAGES>
    80000a26:	c799                	beqz	a5,80000a34 <kfree+0x24>
        assert(FREE_PAGES < MAX_PAGES);
    80000a28:	00008717          	auipc	a4,0x8
    80000a2c:	01073703          	ld	a4,16(a4) # 80008a38 <FREE_PAGES>
    80000a30:	06f77663          	bgeu	a4,a5,80000a9c <kfree+0x8c>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a34:	03449793          	slli	a5,s1,0x34
    80000a38:	efc1                	bnez	a5,80000ad0 <kfree+0xc0>
    80000a3a:	00021797          	auipc	a5,0x21
    80000a3e:	4a678793          	addi	a5,a5,1190 # 80021ee0 <end>
    80000a42:	08f4e763          	bltu	s1,a5,80000ad0 <kfree+0xc0>
    80000a46:	47c5                	li	a5,17
    80000a48:	07ee                	slli	a5,a5,0x1b
    80000a4a:	08f4f363          	bgeu	s1,a5,80000ad0 <kfree+0xc0>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);
    80000a4e:	6605                	lui	a2,0x1
    80000a50:	4585                	li	a1,1
    80000a52:	8526                	mv	a0,s1
    80000a54:	00000097          	auipc	ra,0x0
    80000a58:	35a080e7          	jalr	858(ra) # 80000dae <memset>

    r = (struct run *)pa;

    acquire(&kmem.lock);
    80000a5c:	00010917          	auipc	s2,0x10
    80000a60:	25490913          	addi	s2,s2,596 # 80010cb0 <kmem>
    80000a64:	854a                	mv	a0,s2
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	24c080e7          	jalr	588(ra) # 80000cb2 <acquire>
    r->next = kmem.freelist;
    80000a6e:	01893783          	ld	a5,24(s2)
    80000a72:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000a74:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000a78:	00008717          	auipc	a4,0x8
    80000a7c:	fc070713          	addi	a4,a4,-64 # 80008a38 <FREE_PAGES>
    80000a80:	631c                	ld	a5,0(a4)
    80000a82:	0785                	addi	a5,a5,1
    80000a84:	e31c                	sd	a5,0(a4)
    release(&kmem.lock);
    80000a86:	854a                	mv	a0,s2
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	2de080e7          	jalr	734(ra) # 80000d66 <release>
}
    80000a90:	60e2                	ld	ra,24(sp)
    80000a92:	6442                	ld	s0,16(sp)
    80000a94:	64a2                	ld	s1,8(sp)
    80000a96:	6902                	ld	s2,0(sp)
    80000a98:	6105                	addi	sp,sp,32
    80000a9a:	8082                	ret
        assert(FREE_PAGES < MAX_PAGES);
    80000a9c:	03700693          	li	a3,55
    80000aa0:	00007617          	auipc	a2,0x7
    80000aa4:	56860613          	addi	a2,a2,1384 # 80008008 <__func__.1508>
    80000aa8:	00007597          	auipc	a1,0x7
    80000aac:	5c858593          	addi	a1,a1,1480 # 80008070 <digits+0x20>
    80000ab0:	00007517          	auipc	a0,0x7
    80000ab4:	5d050513          	addi	a0,a0,1488 # 80008080 <digits+0x30>
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	ae8080e7          	jalr	-1304(ra) # 800005a0 <printf>
    80000ac0:	00007517          	auipc	a0,0x7
    80000ac4:	5d050513          	addi	a0,a0,1488 # 80008090 <digits+0x40>
    80000ac8:	00000097          	auipc	ra,0x0
    80000acc:	a7c080e7          	jalr	-1412(ra) # 80000544 <panic>
        panic("kfree");
    80000ad0:	00007517          	auipc	a0,0x7
    80000ad4:	5d050513          	addi	a0,a0,1488 # 800080a0 <digits+0x50>
    80000ad8:	00000097          	auipc	ra,0x0
    80000adc:	a6c080e7          	jalr	-1428(ra) # 80000544 <panic>

0000000080000ae0 <freerange>:
{
    80000ae0:	7179                	addi	sp,sp,-48
    80000ae2:	f406                	sd	ra,40(sp)
    80000ae4:	f022                	sd	s0,32(sp)
    80000ae6:	ec26                	sd	s1,24(sp)
    80000ae8:	e84a                	sd	s2,16(sp)
    80000aea:	e44e                	sd	s3,8(sp)
    80000aec:	e052                	sd	s4,0(sp)
    80000aee:	1800                	addi	s0,sp,48
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000af0:	6785                	lui	a5,0x1
    80000af2:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000af6:	94aa                	add	s1,s1,a0
    80000af8:	757d                	lui	a0,0xfffff
    80000afa:	8ce9                	and	s1,s1,a0
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000afc:	94be                	add	s1,s1,a5
    80000afe:	0095ee63          	bltu	a1,s1,80000b1a <freerange+0x3a>
    80000b02:	892e                	mv	s2,a1
        kfree(p);
    80000b04:	7a7d                	lui	s4,0xfffff
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b06:	6985                	lui	s3,0x1
        kfree(p);
    80000b08:	01448533          	add	a0,s1,s4
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	f04080e7          	jalr	-252(ra) # 80000a10 <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b14:	94ce                	add	s1,s1,s3
    80000b16:	fe9979e3          	bgeu	s2,s1,80000b08 <freerange+0x28>
}
    80000b1a:	70a2                	ld	ra,40(sp)
    80000b1c:	7402                	ld	s0,32(sp)
    80000b1e:	64e2                	ld	s1,24(sp)
    80000b20:	6942                	ld	s2,16(sp)
    80000b22:	69a2                	ld	s3,8(sp)
    80000b24:	6a02                	ld	s4,0(sp)
    80000b26:	6145                	addi	sp,sp,48
    80000b28:	8082                	ret

0000000080000b2a <kinit>:
{
    80000b2a:	1141                	addi	sp,sp,-16
    80000b2c:	e406                	sd	ra,8(sp)
    80000b2e:	e022                	sd	s0,0(sp)
    80000b30:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000b32:	00007597          	auipc	a1,0x7
    80000b36:	57658593          	addi	a1,a1,1398 # 800080a8 <digits+0x58>
    80000b3a:	00010517          	auipc	a0,0x10
    80000b3e:	17650513          	addi	a0,a0,374 # 80010cb0 <kmem>
    80000b42:	00000097          	auipc	ra,0x0
    80000b46:	0e0080e7          	jalr	224(ra) # 80000c22 <initlock>
    freerange(end, (void *)PHYSTOP);
    80000b4a:	45c5                	li	a1,17
    80000b4c:	05ee                	slli	a1,a1,0x1b
    80000b4e:	00021517          	auipc	a0,0x21
    80000b52:	39250513          	addi	a0,a0,914 # 80021ee0 <end>
    80000b56:	00000097          	auipc	ra,0x0
    80000b5a:	f8a080e7          	jalr	-118(ra) # 80000ae0 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000b5e:	00008797          	auipc	a5,0x8
    80000b62:	eda7b783          	ld	a5,-294(a5) # 80008a38 <FREE_PAGES>
    80000b66:	00008717          	auipc	a4,0x8
    80000b6a:	ecf73d23          	sd	a5,-294(a4) # 80008a40 <MAX_PAGES>
}
    80000b6e:	60a2                	ld	ra,8(sp)
    80000b70:	6402                	ld	s0,0(sp)
    80000b72:	0141                	addi	sp,sp,16
    80000b74:	8082                	ret

0000000080000b76 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
    assert(FREE_PAGES > 0);
    80000b80:	00008797          	auipc	a5,0x8
    80000b84:	eb87b783          	ld	a5,-328(a5) # 80008a38 <FREE_PAGES>
    80000b88:	cbb1                	beqz	a5,80000bdc <kalloc+0x66>
    struct run *r;

    acquire(&kmem.lock);
    80000b8a:	00010497          	auipc	s1,0x10
    80000b8e:	12648493          	addi	s1,s1,294 # 80010cb0 <kmem>
    80000b92:	8526                	mv	a0,s1
    80000b94:	00000097          	auipc	ra,0x0
    80000b98:	11e080e7          	jalr	286(ra) # 80000cb2 <acquire>
    r = kmem.freelist;
    80000b9c:	6c84                	ld	s1,24(s1)
    if (r)
    80000b9e:	c8ad                	beqz	s1,80000c10 <kalloc+0x9a>
        kmem.freelist = r->next;
    80000ba0:	609c                	ld	a5,0(s1)
    80000ba2:	00010517          	auipc	a0,0x10
    80000ba6:	10e50513          	addi	a0,a0,270 # 80010cb0 <kmem>
    80000baa:	ed1c                	sd	a5,24(a0)
    release(&kmem.lock);
    80000bac:	00000097          	auipc	ra,0x0
    80000bb0:	1ba080e7          	jalr	442(ra) # 80000d66 <release>

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000bb4:	6605                	lui	a2,0x1
    80000bb6:	4595                	li	a1,5
    80000bb8:	8526                	mv	a0,s1
    80000bba:	00000097          	auipc	ra,0x0
    80000bbe:	1f4080e7          	jalr	500(ra) # 80000dae <memset>
    FREE_PAGES--;
    80000bc2:	00008717          	auipc	a4,0x8
    80000bc6:	e7670713          	addi	a4,a4,-394 # 80008a38 <FREE_PAGES>
    80000bca:	631c                	ld	a5,0(a4)
    80000bcc:	17fd                	addi	a5,a5,-1
    80000bce:	e31c                	sd	a5,0(a4)
    return (void *)r;
}
    80000bd0:	8526                	mv	a0,s1
    80000bd2:	60e2                	ld	ra,24(sp)
    80000bd4:	6442                	ld	s0,16(sp)
    80000bd6:	64a2                	ld	s1,8(sp)
    80000bd8:	6105                	addi	sp,sp,32
    80000bda:	8082                	ret
    assert(FREE_PAGES > 0);
    80000bdc:	04f00693          	li	a3,79
    80000be0:	00007617          	auipc	a2,0x7
    80000be4:	42060613          	addi	a2,a2,1056 # 80008000 <etext>
    80000be8:	00007597          	auipc	a1,0x7
    80000bec:	48858593          	addi	a1,a1,1160 # 80008070 <digits+0x20>
    80000bf0:	00007517          	auipc	a0,0x7
    80000bf4:	49050513          	addi	a0,a0,1168 # 80008080 <digits+0x30>
    80000bf8:	00000097          	auipc	ra,0x0
    80000bfc:	9a8080e7          	jalr	-1624(ra) # 800005a0 <printf>
    80000c00:	00007517          	auipc	a0,0x7
    80000c04:	49050513          	addi	a0,a0,1168 # 80008090 <digits+0x40>
    80000c08:	00000097          	auipc	ra,0x0
    80000c0c:	93c080e7          	jalr	-1732(ra) # 80000544 <panic>
    release(&kmem.lock);
    80000c10:	00010517          	auipc	a0,0x10
    80000c14:	0a050513          	addi	a0,a0,160 # 80010cb0 <kmem>
    80000c18:	00000097          	auipc	ra,0x0
    80000c1c:	14e080e7          	jalr	334(ra) # 80000d66 <release>
    if (r)
    80000c20:	b74d                	j	80000bc2 <kalloc+0x4c>

0000000080000c22 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c22:	1141                	addi	sp,sp,-16
    80000c24:	e422                	sd	s0,8(sp)
    80000c26:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c28:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c2a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c2e:	00053823          	sd	zero,16(a0)
}
    80000c32:	6422                	ld	s0,8(sp)
    80000c34:	0141                	addi	sp,sp,16
    80000c36:	8082                	ret

0000000080000c38 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c38:	411c                	lw	a5,0(a0)
    80000c3a:	e399                	bnez	a5,80000c40 <holding+0x8>
    80000c3c:	4501                	li	a0,0
  return r;
}
    80000c3e:	8082                	ret
{
    80000c40:	1101                	addi	sp,sp,-32
    80000c42:	ec06                	sd	ra,24(sp)
    80000c44:	e822                	sd	s0,16(sp)
    80000c46:	e426                	sd	s1,8(sp)
    80000c48:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c4a:	6904                	ld	s1,16(a0)
    80000c4c:	00001097          	auipc	ra,0x1
    80000c50:	f24080e7          	jalr	-220(ra) # 80001b70 <mycpu>
    80000c54:	40a48533          	sub	a0,s1,a0
    80000c58:	00153513          	seqz	a0,a0
}
    80000c5c:	60e2                	ld	ra,24(sp)
    80000c5e:	6442                	ld	s0,16(sp)
    80000c60:	64a2                	ld	s1,8(sp)
    80000c62:	6105                	addi	sp,sp,32
    80000c64:	8082                	ret

0000000080000c66 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c66:	1101                	addi	sp,sp,-32
    80000c68:	ec06                	sd	ra,24(sp)
    80000c6a:	e822                	sd	s0,16(sp)
    80000c6c:	e426                	sd	s1,8(sp)
    80000c6e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c70:	100024f3          	csrr	s1,sstatus
    80000c74:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c78:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c7a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c7e:	00001097          	auipc	ra,0x1
    80000c82:	ef2080e7          	jalr	-270(ra) # 80001b70 <mycpu>
    80000c86:	5d3c                	lw	a5,120(a0)
    80000c88:	cf89                	beqz	a5,80000ca2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c8a:	00001097          	auipc	ra,0x1
    80000c8e:	ee6080e7          	jalr	-282(ra) # 80001b70 <mycpu>
    80000c92:	5d3c                	lw	a5,120(a0)
    80000c94:	2785                	addiw	a5,a5,1
    80000c96:	dd3c                	sw	a5,120(a0)
}
    80000c98:	60e2                	ld	ra,24(sp)
    80000c9a:	6442                	ld	s0,16(sp)
    80000c9c:	64a2                	ld	s1,8(sp)
    80000c9e:	6105                	addi	sp,sp,32
    80000ca0:	8082                	ret
    mycpu()->intena = old;
    80000ca2:	00001097          	auipc	ra,0x1
    80000ca6:	ece080e7          	jalr	-306(ra) # 80001b70 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000caa:	8085                	srli	s1,s1,0x1
    80000cac:	8885                	andi	s1,s1,1
    80000cae:	dd64                	sw	s1,124(a0)
    80000cb0:	bfe9                	j	80000c8a <push_off+0x24>

0000000080000cb2 <acquire>:
{
    80000cb2:	1101                	addi	sp,sp,-32
    80000cb4:	ec06                	sd	ra,24(sp)
    80000cb6:	e822                	sd	s0,16(sp)
    80000cb8:	e426                	sd	s1,8(sp)
    80000cba:	1000                	addi	s0,sp,32
    80000cbc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	fa8080e7          	jalr	-88(ra) # 80000c66 <push_off>
  if(holding(lk))
    80000cc6:	8526                	mv	a0,s1
    80000cc8:	00000097          	auipc	ra,0x0
    80000ccc:	f70080e7          	jalr	-144(ra) # 80000c38 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cd0:	4705                	li	a4,1
  if(holding(lk))
    80000cd2:	e115                	bnez	a0,80000cf6 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cd4:	87ba                	mv	a5,a4
    80000cd6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cda:	2781                	sext.w	a5,a5
    80000cdc:	ffe5                	bnez	a5,80000cd4 <acquire+0x22>
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000ce2:	00001097          	auipc	ra,0x1
    80000ce6:	e8e080e7          	jalr	-370(ra) # 80001b70 <mycpu>
    80000cea:	e888                	sd	a0,16(s1)
}
    80000cec:	60e2                	ld	ra,24(sp)
    80000cee:	6442                	ld	s0,16(sp)
    80000cf0:	64a2                	ld	s1,8(sp)
    80000cf2:	6105                	addi	sp,sp,32
    80000cf4:	8082                	ret
    panic("acquire");
    80000cf6:	00007517          	auipc	a0,0x7
    80000cfa:	3ba50513          	addi	a0,a0,954 # 800080b0 <digits+0x60>
    80000cfe:	00000097          	auipc	ra,0x0
    80000d02:	846080e7          	jalr	-1978(ra) # 80000544 <panic>

0000000080000d06 <pop_off>:

void
pop_off(void)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e406                	sd	ra,8(sp)
    80000d0a:	e022                	sd	s0,0(sp)
    80000d0c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d0e:	00001097          	auipc	ra,0x1
    80000d12:	e62080e7          	jalr	-414(ra) # 80001b70 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d16:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d1a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d1c:	e78d                	bnez	a5,80000d46 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d1e:	5d3c                	lw	a5,120(a0)
    80000d20:	02f05b63          	blez	a5,80000d56 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d24:	37fd                	addiw	a5,a5,-1
    80000d26:	0007871b          	sext.w	a4,a5
    80000d2a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d2c:	eb09                	bnez	a4,80000d3e <pop_off+0x38>
    80000d2e:	5d7c                	lw	a5,124(a0)
    80000d30:	c799                	beqz	a5,80000d3e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d32:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d36:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d3a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d3e:	60a2                	ld	ra,8(sp)
    80000d40:	6402                	ld	s0,0(sp)
    80000d42:	0141                	addi	sp,sp,16
    80000d44:	8082                	ret
    panic("pop_off - interruptible");
    80000d46:	00007517          	auipc	a0,0x7
    80000d4a:	37250513          	addi	a0,a0,882 # 800080b8 <digits+0x68>
    80000d4e:	fffff097          	auipc	ra,0xfffff
    80000d52:	7f6080e7          	jalr	2038(ra) # 80000544 <panic>
    panic("pop_off");
    80000d56:	00007517          	auipc	a0,0x7
    80000d5a:	37a50513          	addi	a0,a0,890 # 800080d0 <digits+0x80>
    80000d5e:	fffff097          	auipc	ra,0xfffff
    80000d62:	7e6080e7          	jalr	2022(ra) # 80000544 <panic>

0000000080000d66 <release>:
{
    80000d66:	1101                	addi	sp,sp,-32
    80000d68:	ec06                	sd	ra,24(sp)
    80000d6a:	e822                	sd	s0,16(sp)
    80000d6c:	e426                	sd	s1,8(sp)
    80000d6e:	1000                	addi	s0,sp,32
    80000d70:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d72:	00000097          	auipc	ra,0x0
    80000d76:	ec6080e7          	jalr	-314(ra) # 80000c38 <holding>
    80000d7a:	c115                	beqz	a0,80000d9e <release+0x38>
  lk->cpu = 0;
    80000d7c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d80:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d84:	0f50000f          	fence	iorw,ow
    80000d88:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f7a080e7          	jalr	-134(ra) # 80000d06 <pop_off>
}
    80000d94:	60e2                	ld	ra,24(sp)
    80000d96:	6442                	ld	s0,16(sp)
    80000d98:	64a2                	ld	s1,8(sp)
    80000d9a:	6105                	addi	sp,sp,32
    80000d9c:	8082                	ret
    panic("release");
    80000d9e:	00007517          	auipc	a0,0x7
    80000da2:	33a50513          	addi	a0,a0,826 # 800080d8 <digits+0x88>
    80000da6:	fffff097          	auipc	ra,0xfffff
    80000daa:	79e080e7          	jalr	1950(ra) # 80000544 <panic>

0000000080000dae <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000dae:	1141                	addi	sp,sp,-16
    80000db0:	e422                	sd	s0,8(sp)
    80000db2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000db4:	ce09                	beqz	a2,80000dce <memset+0x20>
    80000db6:	87aa                	mv	a5,a0
    80000db8:	fff6071b          	addiw	a4,a2,-1
    80000dbc:	1702                	slli	a4,a4,0x20
    80000dbe:	9301                	srli	a4,a4,0x20
    80000dc0:	0705                	addi	a4,a4,1
    80000dc2:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000dc4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000dc8:	0785                	addi	a5,a5,1
    80000dca:	fee79de3          	bne	a5,a4,80000dc4 <memset+0x16>
  }
  return dst;
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret

0000000080000dd4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000dd4:	1141                	addi	sp,sp,-16
    80000dd6:	e422                	sd	s0,8(sp)
    80000dd8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dda:	ca05                	beqz	a2,80000e0a <memcmp+0x36>
    80000ddc:	fff6069b          	addiw	a3,a2,-1
    80000de0:	1682                	slli	a3,a3,0x20
    80000de2:	9281                	srli	a3,a3,0x20
    80000de4:	0685                	addi	a3,a3,1
    80000de6:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000de8:	00054783          	lbu	a5,0(a0)
    80000dec:	0005c703          	lbu	a4,0(a1)
    80000df0:	00e79863          	bne	a5,a4,80000e00 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000df4:	0505                	addi	a0,a0,1
    80000df6:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000df8:	fed518e3          	bne	a0,a3,80000de8 <memcmp+0x14>
  }

  return 0;
    80000dfc:	4501                	li	a0,0
    80000dfe:	a019                	j	80000e04 <memcmp+0x30>
      return *s1 - *s2;
    80000e00:	40e7853b          	subw	a0,a5,a4
}
    80000e04:	6422                	ld	s0,8(sp)
    80000e06:	0141                	addi	sp,sp,16
    80000e08:	8082                	ret
  return 0;
    80000e0a:	4501                	li	a0,0
    80000e0c:	bfe5                	j	80000e04 <memcmp+0x30>

0000000080000e0e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e0e:	1141                	addi	sp,sp,-16
    80000e10:	e422                	sd	s0,8(sp)
    80000e12:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e14:	ca0d                	beqz	a2,80000e46 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e16:	00a5f963          	bgeu	a1,a0,80000e28 <memmove+0x1a>
    80000e1a:	02061693          	slli	a3,a2,0x20
    80000e1e:	9281                	srli	a3,a3,0x20
    80000e20:	00d58733          	add	a4,a1,a3
    80000e24:	02e56463          	bltu	a0,a4,80000e4c <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e28:	fff6079b          	addiw	a5,a2,-1
    80000e2c:	1782                	slli	a5,a5,0x20
    80000e2e:	9381                	srli	a5,a5,0x20
    80000e30:	0785                	addi	a5,a5,1
    80000e32:	97ae                	add	a5,a5,a1
    80000e34:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0705                	addi	a4,a4,1
    80000e3a:	fff5c683          	lbu	a3,-1(a1)
    80000e3e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e42:	fef59ae3          	bne	a1,a5,80000e36 <memmove+0x28>

  return dst;
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret
    d += n;
    80000e4c:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e4e:	fff6079b          	addiw	a5,a2,-1
    80000e52:	1782                	slli	a5,a5,0x20
    80000e54:	9381                	srli	a5,a5,0x20
    80000e56:	fff7c793          	not	a5,a5
    80000e5a:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e5c:	177d                	addi	a4,a4,-1
    80000e5e:	16fd                	addi	a3,a3,-1
    80000e60:	00074603          	lbu	a2,0(a4)
    80000e64:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e68:	fef71ae3          	bne	a4,a5,80000e5c <memmove+0x4e>
    80000e6c:	bfe9                	j	80000e46 <memmove+0x38>

0000000080000e6e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e6e:	1141                	addi	sp,sp,-16
    80000e70:	e406                	sd	ra,8(sp)
    80000e72:	e022                	sd	s0,0(sp)
    80000e74:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e76:	00000097          	auipc	ra,0x0
    80000e7a:	f98080e7          	jalr	-104(ra) # 80000e0e <memmove>
}
    80000e7e:	60a2                	ld	ra,8(sp)
    80000e80:	6402                	ld	s0,0(sp)
    80000e82:	0141                	addi	sp,sp,16
    80000e84:	8082                	ret

0000000080000e86 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e86:	1141                	addi	sp,sp,-16
    80000e88:	e422                	sd	s0,8(sp)
    80000e8a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e8c:	ce11                	beqz	a2,80000ea8 <strncmp+0x22>
    80000e8e:	00054783          	lbu	a5,0(a0)
    80000e92:	cf89                	beqz	a5,80000eac <strncmp+0x26>
    80000e94:	0005c703          	lbu	a4,0(a1)
    80000e98:	00f71a63          	bne	a4,a5,80000eac <strncmp+0x26>
    n--, p++, q++;
    80000e9c:	367d                	addiw	a2,a2,-1
    80000e9e:	0505                	addi	a0,a0,1
    80000ea0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ea2:	f675                	bnez	a2,80000e8e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ea4:	4501                	li	a0,0
    80000ea6:	a809                	j	80000eb8 <strncmp+0x32>
    80000ea8:	4501                	li	a0,0
    80000eaa:	a039                	j	80000eb8 <strncmp+0x32>
  if(n == 0)
    80000eac:	ca09                	beqz	a2,80000ebe <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000eae:	00054503          	lbu	a0,0(a0)
    80000eb2:	0005c783          	lbu	a5,0(a1)
    80000eb6:	9d1d                	subw	a0,a0,a5
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret
    return 0;
    80000ebe:	4501                	li	a0,0
    80000ec0:	bfe5                	j	80000eb8 <strncmp+0x32>

0000000080000ec2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ec2:	1141                	addi	sp,sp,-16
    80000ec4:	e422                	sd	s0,8(sp)
    80000ec6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ec8:	872a                	mv	a4,a0
    80000eca:	8832                	mv	a6,a2
    80000ecc:	367d                	addiw	a2,a2,-1
    80000ece:	01005963          	blez	a6,80000ee0 <strncpy+0x1e>
    80000ed2:	0705                	addi	a4,a4,1
    80000ed4:	0005c783          	lbu	a5,0(a1)
    80000ed8:	fef70fa3          	sb	a5,-1(a4)
    80000edc:	0585                	addi	a1,a1,1
    80000ede:	f7f5                	bnez	a5,80000eca <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ee0:	00c05d63          	blez	a2,80000efa <strncpy+0x38>
    80000ee4:	86ba                	mv	a3,a4
    *s++ = 0;
    80000ee6:	0685                	addi	a3,a3,1
    80000ee8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000eec:	fff6c793          	not	a5,a3
    80000ef0:	9fb9                	addw	a5,a5,a4
    80000ef2:	010787bb          	addw	a5,a5,a6
    80000ef6:	fef048e3          	bgtz	a5,80000ee6 <strncpy+0x24>
  return os;
}
    80000efa:	6422                	ld	s0,8(sp)
    80000efc:	0141                	addi	sp,sp,16
    80000efe:	8082                	ret

0000000080000f00 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f00:	1141                	addi	sp,sp,-16
    80000f02:	e422                	sd	s0,8(sp)
    80000f04:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f06:	02c05363          	blez	a2,80000f2c <safestrcpy+0x2c>
    80000f0a:	fff6069b          	addiw	a3,a2,-1
    80000f0e:	1682                	slli	a3,a3,0x20
    80000f10:	9281                	srli	a3,a3,0x20
    80000f12:	96ae                	add	a3,a3,a1
    80000f14:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f16:	00d58963          	beq	a1,a3,80000f28 <safestrcpy+0x28>
    80000f1a:	0585                	addi	a1,a1,1
    80000f1c:	0785                	addi	a5,a5,1
    80000f1e:	fff5c703          	lbu	a4,-1(a1)
    80000f22:	fee78fa3          	sb	a4,-1(a5)
    80000f26:	fb65                	bnez	a4,80000f16 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f28:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f2c:	6422                	ld	s0,8(sp)
    80000f2e:	0141                	addi	sp,sp,16
    80000f30:	8082                	ret

0000000080000f32 <strlen>:

int
strlen(const char *s)
{
    80000f32:	1141                	addi	sp,sp,-16
    80000f34:	e422                	sd	s0,8(sp)
    80000f36:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f38:	00054783          	lbu	a5,0(a0)
    80000f3c:	cf91                	beqz	a5,80000f58 <strlen+0x26>
    80000f3e:	0505                	addi	a0,a0,1
    80000f40:	87aa                	mv	a5,a0
    80000f42:	4685                	li	a3,1
    80000f44:	9e89                	subw	a3,a3,a0
    80000f46:	00f6853b          	addw	a0,a3,a5
    80000f4a:	0785                	addi	a5,a5,1
    80000f4c:	fff7c703          	lbu	a4,-1(a5)
    80000f50:	fb7d                	bnez	a4,80000f46 <strlen+0x14>
    ;
  return n;
}
    80000f52:	6422                	ld	s0,8(sp)
    80000f54:	0141                	addi	sp,sp,16
    80000f56:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f58:	4501                	li	a0,0
    80000f5a:	bfe5                	j	80000f52 <strlen+0x20>

0000000080000f5c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f5c:	1141                	addi	sp,sp,-16
    80000f5e:	e406                	sd	ra,8(sp)
    80000f60:	e022                	sd	s0,0(sp)
    80000f62:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f64:	00001097          	auipc	ra,0x1
    80000f68:	bfc080e7          	jalr	-1028(ra) # 80001b60 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f6c:	00008717          	auipc	a4,0x8
    80000f70:	adc70713          	addi	a4,a4,-1316 # 80008a48 <started>
  if(cpuid() == 0){
    80000f74:	c139                	beqz	a0,80000fba <main+0x5e>
    while(started == 0)
    80000f76:	431c                	lw	a5,0(a4)
    80000f78:	2781                	sext.w	a5,a5
    80000f7a:	dff5                	beqz	a5,80000f76 <main+0x1a>
      ;
    __sync_synchronize();
    80000f7c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f80:	00001097          	auipc	ra,0x1
    80000f84:	be0080e7          	jalr	-1056(ra) # 80001b60 <cpuid>
    80000f88:	85aa                	mv	a1,a0
    80000f8a:	00007517          	auipc	a0,0x7
    80000f8e:	16e50513          	addi	a0,a0,366 # 800080f8 <digits+0xa8>
    80000f92:	fffff097          	auipc	ra,0xfffff
    80000f96:	60e080e7          	jalr	1550(ra) # 800005a0 <printf>
    kvminithart();    // turn on paging
    80000f9a:	00000097          	auipc	ra,0x0
    80000f9e:	0d8080e7          	jalr	216(ra) # 80001072 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fa2:	00002097          	auipc	ra,0x2
    80000fa6:	a7e080e7          	jalr	-1410(ra) # 80002a20 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000faa:	00005097          	auipc	ra,0x5
    80000fae:	116080e7          	jalr	278(ra) # 800060c0 <plicinithart>
  }

  scheduler();        
    80000fb2:	00001097          	auipc	ra,0x1
    80000fb6:	21c080e7          	jalr	540(ra) # 800021ce <scheduler>
    consoleinit();
    80000fba:	fffff097          	auipc	ra,0xfffff
    80000fbe:	49c080e7          	jalr	1180(ra) # 80000456 <consoleinit>
    printfinit();
    80000fc2:	fffff097          	auipc	ra,0xfffff
    80000fc6:	7c4080e7          	jalr	1988(ra) # 80000786 <printfinit>
    printf("\n");
    80000fca:	00007517          	auipc	a0,0x7
    80000fce:	0be50513          	addi	a0,a0,190 # 80008088 <digits+0x38>
    80000fd2:	fffff097          	auipc	ra,0xfffff
    80000fd6:	5ce080e7          	jalr	1486(ra) # 800005a0 <printf>
    printf("xv6 kernel is booting\n");
    80000fda:	00007517          	auipc	a0,0x7
    80000fde:	10650513          	addi	a0,a0,262 # 800080e0 <digits+0x90>
    80000fe2:	fffff097          	auipc	ra,0xfffff
    80000fe6:	5be080e7          	jalr	1470(ra) # 800005a0 <printf>
    printf("\n");
    80000fea:	00007517          	auipc	a0,0x7
    80000fee:	09e50513          	addi	a0,a0,158 # 80008088 <digits+0x38>
    80000ff2:	fffff097          	auipc	ra,0xfffff
    80000ff6:	5ae080e7          	jalr	1454(ra) # 800005a0 <printf>
    kinit();         // physical page allocator
    80000ffa:	00000097          	auipc	ra,0x0
    80000ffe:	b30080e7          	jalr	-1232(ra) # 80000b2a <kinit>
    kvminit();       // create kernel page table
    80001002:	00000097          	auipc	ra,0x0
    80001006:	326080e7          	jalr	806(ra) # 80001328 <kvminit>
    kvminithart();   // turn on paging
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	068080e7          	jalr	104(ra) # 80001072 <kvminithart>
    procinit();      // process table
    80001012:	00001097          	auipc	ra,0x1
    80001016:	a6c080e7          	jalr	-1428(ra) # 80001a7e <procinit>
    trapinit();      // trap vectors
    8000101a:	00002097          	auipc	ra,0x2
    8000101e:	9de080e7          	jalr	-1570(ra) # 800029f8 <trapinit>
    trapinithart();  // install kernel trap vector
    80001022:	00002097          	auipc	ra,0x2
    80001026:	9fe080e7          	jalr	-1538(ra) # 80002a20 <trapinithart>
    plicinit();      // set up interrupt controller
    8000102a:	00005097          	auipc	ra,0x5
    8000102e:	080080e7          	jalr	128(ra) # 800060aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001032:	00005097          	auipc	ra,0x5
    80001036:	08e080e7          	jalr	142(ra) # 800060c0 <plicinithart>
    binit();         // buffer cache
    8000103a:	00002097          	auipc	ra,0x2
    8000103e:	23a080e7          	jalr	570(ra) # 80003274 <binit>
    iinit();         // inode table
    80001042:	00003097          	auipc	ra,0x3
    80001046:	8de080e7          	jalr	-1826(ra) # 80003920 <iinit>
    fileinit();      // file table
    8000104a:	00004097          	auipc	ra,0x4
    8000104e:	87c080e7          	jalr	-1924(ra) # 800048c6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001052:	00005097          	auipc	ra,0x5
    80001056:	176080e7          	jalr	374(ra) # 800061c8 <virtio_disk_init>
    userinit();      // first user process
    8000105a:	00001097          	auipc	ra,0x1
    8000105e:	e0a080e7          	jalr	-502(ra) # 80001e64 <userinit>
    __sync_synchronize();
    80001062:	0ff0000f          	fence
    started = 1;
    80001066:	4785                	li	a5,1
    80001068:	00008717          	auipc	a4,0x8
    8000106c:	9ef72023          	sw	a5,-1568(a4) # 80008a48 <started>
    80001070:	b789                	j	80000fb2 <main+0x56>

0000000080001072 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001072:	1141                	addi	sp,sp,-16
    80001074:	e422                	sd	s0,8(sp)
    80001076:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001078:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    8000107c:	00008797          	auipc	a5,0x8
    80001080:	9d47b783          	ld	a5,-1580(a5) # 80008a50 <kernel_pagetable>
    80001084:	83b1                	srli	a5,a5,0xc
    80001086:	577d                	li	a4,-1
    80001088:	177e                	slli	a4,a4,0x3f
    8000108a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000108c:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001090:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001094:	6422                	ld	s0,8(sp)
    80001096:	0141                	addi	sp,sp,16
    80001098:	8082                	ret

000000008000109a <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000109a:	7139                	addi	sp,sp,-64
    8000109c:	fc06                	sd	ra,56(sp)
    8000109e:	f822                	sd	s0,48(sp)
    800010a0:	f426                	sd	s1,40(sp)
    800010a2:	f04a                	sd	s2,32(sp)
    800010a4:	ec4e                	sd	s3,24(sp)
    800010a6:	e852                	sd	s4,16(sp)
    800010a8:	e456                	sd	s5,8(sp)
    800010aa:	e05a                	sd	s6,0(sp)
    800010ac:	0080                	addi	s0,sp,64
    800010ae:	84aa                	mv	s1,a0
    800010b0:	89ae                	mv	s3,a1
    800010b2:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010b4:	57fd                	li	a5,-1
    800010b6:	83e9                	srli	a5,a5,0x1a
    800010b8:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010ba:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010bc:	04b7f263          	bgeu	a5,a1,80001100 <walk+0x66>
    panic("walk");
    800010c0:	00007517          	auipc	a0,0x7
    800010c4:	05050513          	addi	a0,a0,80 # 80008110 <digits+0xc0>
    800010c8:	fffff097          	auipc	ra,0xfffff
    800010cc:	47c080e7          	jalr	1148(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010d0:	060a8663          	beqz	s5,8000113c <walk+0xa2>
    800010d4:	00000097          	auipc	ra,0x0
    800010d8:	aa2080e7          	jalr	-1374(ra) # 80000b76 <kalloc>
    800010dc:	84aa                	mv	s1,a0
    800010de:	c529                	beqz	a0,80001128 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010e0:	6605                	lui	a2,0x1
    800010e2:	4581                	li	a1,0
    800010e4:	00000097          	auipc	ra,0x0
    800010e8:	cca080e7          	jalr	-822(ra) # 80000dae <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010ec:	00c4d793          	srli	a5,s1,0xc
    800010f0:	07aa                	slli	a5,a5,0xa
    800010f2:	0017e793          	ori	a5,a5,1
    800010f6:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010fa:	3a5d                	addiw	s4,s4,-9
    800010fc:	036a0063          	beq	s4,s6,8000111c <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001100:	0149d933          	srl	s2,s3,s4
    80001104:	1ff97913          	andi	s2,s2,511
    80001108:	090e                	slli	s2,s2,0x3
    8000110a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000110c:	00093483          	ld	s1,0(s2)
    80001110:	0014f793          	andi	a5,s1,1
    80001114:	dfd5                	beqz	a5,800010d0 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001116:	80a9                	srli	s1,s1,0xa
    80001118:	04b2                	slli	s1,s1,0xc
    8000111a:	b7c5                	j	800010fa <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000111c:	00c9d513          	srli	a0,s3,0xc
    80001120:	1ff57513          	andi	a0,a0,511
    80001124:	050e                	slli	a0,a0,0x3
    80001126:	9526                	add	a0,a0,s1
}
    80001128:	70e2                	ld	ra,56(sp)
    8000112a:	7442                	ld	s0,48(sp)
    8000112c:	74a2                	ld	s1,40(sp)
    8000112e:	7902                	ld	s2,32(sp)
    80001130:	69e2                	ld	s3,24(sp)
    80001132:	6a42                	ld	s4,16(sp)
    80001134:	6aa2                	ld	s5,8(sp)
    80001136:	6b02                	ld	s6,0(sp)
    80001138:	6121                	addi	sp,sp,64
    8000113a:	8082                	ret
        return 0;
    8000113c:	4501                	li	a0,0
    8000113e:	b7ed                	j	80001128 <walk+0x8e>

0000000080001140 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001140:	57fd                	li	a5,-1
    80001142:	83e9                	srli	a5,a5,0x1a
    80001144:	00b7f463          	bgeu	a5,a1,8000114c <walkaddr+0xc>
    return 0;
    80001148:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000114a:	8082                	ret
{
    8000114c:	1141                	addi	sp,sp,-16
    8000114e:	e406                	sd	ra,8(sp)
    80001150:	e022                	sd	s0,0(sp)
    80001152:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001154:	4601                	li	a2,0
    80001156:	00000097          	auipc	ra,0x0
    8000115a:	f44080e7          	jalr	-188(ra) # 8000109a <walk>
  if(pte == 0)
    8000115e:	c105                	beqz	a0,8000117e <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001160:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001162:	0117f693          	andi	a3,a5,17
    80001166:	4745                	li	a4,17
    return 0;
    80001168:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000116a:	00e68663          	beq	a3,a4,80001176 <walkaddr+0x36>
}
    8000116e:	60a2                	ld	ra,8(sp)
    80001170:	6402                	ld	s0,0(sp)
    80001172:	0141                	addi	sp,sp,16
    80001174:	8082                	ret
  pa = PTE2PA(*pte);
    80001176:	00a7d513          	srli	a0,a5,0xa
    8000117a:	0532                	slli	a0,a0,0xc
  return pa;
    8000117c:	bfcd                	j	8000116e <walkaddr+0x2e>
    return 0;
    8000117e:	4501                	li	a0,0
    80001180:	b7fd                	j	8000116e <walkaddr+0x2e>

0000000080001182 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001182:	715d                	addi	sp,sp,-80
    80001184:	e486                	sd	ra,72(sp)
    80001186:	e0a2                	sd	s0,64(sp)
    80001188:	fc26                	sd	s1,56(sp)
    8000118a:	f84a                	sd	s2,48(sp)
    8000118c:	f44e                	sd	s3,40(sp)
    8000118e:	f052                	sd	s4,32(sp)
    80001190:	ec56                	sd	s5,24(sp)
    80001192:	e85a                	sd	s6,16(sp)
    80001194:	e45e                	sd	s7,8(sp)
    80001196:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001198:	c205                	beqz	a2,800011b8 <mappages+0x36>
    8000119a:	8aaa                	mv	s5,a0
    8000119c:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000119e:	77fd                	lui	a5,0xfffff
    800011a0:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011a4:	15fd                	addi	a1,a1,-1
    800011a6:	00c589b3          	add	s3,a1,a2
    800011aa:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800011ae:	8952                	mv	s2,s4
    800011b0:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011b4:	6b85                	lui	s7,0x1
    800011b6:	a015                	j	800011da <mappages+0x58>
    panic("mappages: size");
    800011b8:	00007517          	auipc	a0,0x7
    800011bc:	f6050513          	addi	a0,a0,-160 # 80008118 <digits+0xc8>
    800011c0:	fffff097          	auipc	ra,0xfffff
    800011c4:	384080e7          	jalr	900(ra) # 80000544 <panic>
      panic("mappages: remap");
    800011c8:	00007517          	auipc	a0,0x7
    800011cc:	f6050513          	addi	a0,a0,-160 # 80008128 <digits+0xd8>
    800011d0:	fffff097          	auipc	ra,0xfffff
    800011d4:	374080e7          	jalr	884(ra) # 80000544 <panic>
    a += PGSIZE;
    800011d8:	995e                	add	s2,s2,s7
  for(;;){
    800011da:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011de:	4605                	li	a2,1
    800011e0:	85ca                	mv	a1,s2
    800011e2:	8556                	mv	a0,s5
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	eb6080e7          	jalr	-330(ra) # 8000109a <walk>
    800011ec:	cd19                	beqz	a0,8000120a <mappages+0x88>
    if(*pte & PTE_V)
    800011ee:	611c                	ld	a5,0(a0)
    800011f0:	8b85                	andi	a5,a5,1
    800011f2:	fbf9                	bnez	a5,800011c8 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011f4:	80b1                	srli	s1,s1,0xc
    800011f6:	04aa                	slli	s1,s1,0xa
    800011f8:	0164e4b3          	or	s1,s1,s6
    800011fc:	0014e493          	ori	s1,s1,1
    80001200:	e104                	sd	s1,0(a0)
    if(a == last)
    80001202:	fd391be3          	bne	s2,s3,800011d8 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001206:	4501                	li	a0,0
    80001208:	a011                	j	8000120c <mappages+0x8a>
      return -1;
    8000120a:	557d                	li	a0,-1
}
    8000120c:	60a6                	ld	ra,72(sp)
    8000120e:	6406                	ld	s0,64(sp)
    80001210:	74e2                	ld	s1,56(sp)
    80001212:	7942                	ld	s2,48(sp)
    80001214:	79a2                	ld	s3,40(sp)
    80001216:	7a02                	ld	s4,32(sp)
    80001218:	6ae2                	ld	s5,24(sp)
    8000121a:	6b42                	ld	s6,16(sp)
    8000121c:	6ba2                	ld	s7,8(sp)
    8000121e:	6161                	addi	sp,sp,80
    80001220:	8082                	ret

0000000080001222 <kvmmap>:
{
    80001222:	1141                	addi	sp,sp,-16
    80001224:	e406                	sd	ra,8(sp)
    80001226:	e022                	sd	s0,0(sp)
    80001228:	0800                	addi	s0,sp,16
    8000122a:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000122c:	86b2                	mv	a3,a2
    8000122e:	863e                	mv	a2,a5
    80001230:	00000097          	auipc	ra,0x0
    80001234:	f52080e7          	jalr	-174(ra) # 80001182 <mappages>
    80001238:	e509                	bnez	a0,80001242 <kvmmap+0x20>
}
    8000123a:	60a2                	ld	ra,8(sp)
    8000123c:	6402                	ld	s0,0(sp)
    8000123e:	0141                	addi	sp,sp,16
    80001240:	8082                	ret
    panic("kvmmap");
    80001242:	00007517          	auipc	a0,0x7
    80001246:	ef650513          	addi	a0,a0,-266 # 80008138 <digits+0xe8>
    8000124a:	fffff097          	auipc	ra,0xfffff
    8000124e:	2fa080e7          	jalr	762(ra) # 80000544 <panic>

0000000080001252 <kvmmake>:
{
    80001252:	1101                	addi	sp,sp,-32
    80001254:	ec06                	sd	ra,24(sp)
    80001256:	e822                	sd	s0,16(sp)
    80001258:	e426                	sd	s1,8(sp)
    8000125a:	e04a                	sd	s2,0(sp)
    8000125c:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	918080e7          	jalr	-1768(ra) # 80000b76 <kalloc>
    80001266:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001268:	6605                	lui	a2,0x1
    8000126a:	4581                	li	a1,0
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	b42080e7          	jalr	-1214(ra) # 80000dae <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001274:	4719                	li	a4,6
    80001276:	6685                	lui	a3,0x1
    80001278:	10000637          	lui	a2,0x10000
    8000127c:	100005b7          	lui	a1,0x10000
    80001280:	8526                	mv	a0,s1
    80001282:	00000097          	auipc	ra,0x0
    80001286:	fa0080e7          	jalr	-96(ra) # 80001222 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000128a:	4719                	li	a4,6
    8000128c:	6685                	lui	a3,0x1
    8000128e:	10001637          	lui	a2,0x10001
    80001292:	100015b7          	lui	a1,0x10001
    80001296:	8526                	mv	a0,s1
    80001298:	00000097          	auipc	ra,0x0
    8000129c:	f8a080e7          	jalr	-118(ra) # 80001222 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012a0:	4719                	li	a4,6
    800012a2:	004006b7          	lui	a3,0x400
    800012a6:	0c000637          	lui	a2,0xc000
    800012aa:	0c0005b7          	lui	a1,0xc000
    800012ae:	8526                	mv	a0,s1
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	f72080e7          	jalr	-142(ra) # 80001222 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012b8:	00007917          	auipc	s2,0x7
    800012bc:	d4890913          	addi	s2,s2,-696 # 80008000 <etext>
    800012c0:	4729                	li	a4,10
    800012c2:	80007697          	auipc	a3,0x80007
    800012c6:	d3e68693          	addi	a3,a3,-706 # 8000 <_entry-0x7fff8000>
    800012ca:	4605                	li	a2,1
    800012cc:	067e                	slli	a2,a2,0x1f
    800012ce:	85b2                	mv	a1,a2
    800012d0:	8526                	mv	a0,s1
    800012d2:	00000097          	auipc	ra,0x0
    800012d6:	f50080e7          	jalr	-176(ra) # 80001222 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012da:	4719                	li	a4,6
    800012dc:	46c5                	li	a3,17
    800012de:	06ee                	slli	a3,a3,0x1b
    800012e0:	412686b3          	sub	a3,a3,s2
    800012e4:	864a                	mv	a2,s2
    800012e6:	85ca                	mv	a1,s2
    800012e8:	8526                	mv	a0,s1
    800012ea:	00000097          	auipc	ra,0x0
    800012ee:	f38080e7          	jalr	-200(ra) # 80001222 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012f2:	4729                	li	a4,10
    800012f4:	6685                	lui	a3,0x1
    800012f6:	00006617          	auipc	a2,0x6
    800012fa:	d0a60613          	addi	a2,a2,-758 # 80007000 <_trampoline>
    800012fe:	040005b7          	lui	a1,0x4000
    80001302:	15fd                	addi	a1,a1,-1
    80001304:	05b2                	slli	a1,a1,0xc
    80001306:	8526                	mv	a0,s1
    80001308:	00000097          	auipc	ra,0x0
    8000130c:	f1a080e7          	jalr	-230(ra) # 80001222 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001310:	8526                	mv	a0,s1
    80001312:	00000097          	auipc	ra,0x0
    80001316:	6d6080e7          	jalr	1750(ra) # 800019e8 <proc_mapstacks>
}
    8000131a:	8526                	mv	a0,s1
    8000131c:	60e2                	ld	ra,24(sp)
    8000131e:	6442                	ld	s0,16(sp)
    80001320:	64a2                	ld	s1,8(sp)
    80001322:	6902                	ld	s2,0(sp)
    80001324:	6105                	addi	sp,sp,32
    80001326:	8082                	ret

0000000080001328 <kvminit>:
{
    80001328:	1141                	addi	sp,sp,-16
    8000132a:	e406                	sd	ra,8(sp)
    8000132c:	e022                	sd	s0,0(sp)
    8000132e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001330:	00000097          	auipc	ra,0x0
    80001334:	f22080e7          	jalr	-222(ra) # 80001252 <kvmmake>
    80001338:	00007797          	auipc	a5,0x7
    8000133c:	70a7bc23          	sd	a0,1816(a5) # 80008a50 <kernel_pagetable>
}
    80001340:	60a2                	ld	ra,8(sp)
    80001342:	6402                	ld	s0,0(sp)
    80001344:	0141                	addi	sp,sp,16
    80001346:	8082                	ret

0000000080001348 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001348:	715d                	addi	sp,sp,-80
    8000134a:	e486                	sd	ra,72(sp)
    8000134c:	e0a2                	sd	s0,64(sp)
    8000134e:	fc26                	sd	s1,56(sp)
    80001350:	f84a                	sd	s2,48(sp)
    80001352:	f44e                	sd	s3,40(sp)
    80001354:	f052                	sd	s4,32(sp)
    80001356:	ec56                	sd	s5,24(sp)
    80001358:	e85a                	sd	s6,16(sp)
    8000135a:	e45e                	sd	s7,8(sp)
    8000135c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000135e:	03459793          	slli	a5,a1,0x34
    80001362:	e795                	bnez	a5,8000138e <uvmunmap+0x46>
    80001364:	8a2a                	mv	s4,a0
    80001366:	892e                	mv	s2,a1
    80001368:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000136a:	0632                	slli	a2,a2,0xc
    8000136c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001370:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001372:	6b05                	lui	s6,0x1
    80001374:	0735e863          	bltu	a1,s3,800013e4 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001378:	60a6                	ld	ra,72(sp)
    8000137a:	6406                	ld	s0,64(sp)
    8000137c:	74e2                	ld	s1,56(sp)
    8000137e:	7942                	ld	s2,48(sp)
    80001380:	79a2                	ld	s3,40(sp)
    80001382:	7a02                	ld	s4,32(sp)
    80001384:	6ae2                	ld	s5,24(sp)
    80001386:	6b42                	ld	s6,16(sp)
    80001388:	6ba2                	ld	s7,8(sp)
    8000138a:	6161                	addi	sp,sp,80
    8000138c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000138e:	00007517          	auipc	a0,0x7
    80001392:	db250513          	addi	a0,a0,-590 # 80008140 <digits+0xf0>
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	1ae080e7          	jalr	430(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    8000139e:	00007517          	auipc	a0,0x7
    800013a2:	dba50513          	addi	a0,a0,-582 # 80008158 <digits+0x108>
    800013a6:	fffff097          	auipc	ra,0xfffff
    800013aa:	19e080e7          	jalr	414(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	dba50513          	addi	a0,a0,-582 # 80008168 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	18e080e7          	jalr	398(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800013be:	00007517          	auipc	a0,0x7
    800013c2:	dc250513          	addi	a0,a0,-574 # 80008180 <digits+0x130>
    800013c6:	fffff097          	auipc	ra,0xfffff
    800013ca:	17e080e7          	jalr	382(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    800013ce:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013d0:	0532                	slli	a0,a0,0xc
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	63e080e7          	jalr	1598(ra) # 80000a10 <kfree>
    *pte = 0;
    800013da:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013de:	995a                	add	s2,s2,s6
    800013e0:	f9397ce3          	bgeu	s2,s3,80001378 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013e4:	4601                	li	a2,0
    800013e6:	85ca                	mv	a1,s2
    800013e8:	8552                	mv	a0,s4
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	cb0080e7          	jalr	-848(ra) # 8000109a <walk>
    800013f2:	84aa                	mv	s1,a0
    800013f4:	d54d                	beqz	a0,8000139e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013f6:	6108                	ld	a0,0(a0)
    800013f8:	00157793          	andi	a5,a0,1
    800013fc:	dbcd                	beqz	a5,800013ae <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013fe:	3ff57793          	andi	a5,a0,1023
    80001402:	fb778ee3          	beq	a5,s7,800013be <uvmunmap+0x76>
    if(do_free){
    80001406:	fc0a8ae3          	beqz	s5,800013da <uvmunmap+0x92>
    8000140a:	b7d1                	j	800013ce <uvmunmap+0x86>

000000008000140c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000140c:	1101                	addi	sp,sp,-32
    8000140e:	ec06                	sd	ra,24(sp)
    80001410:	e822                	sd	s0,16(sp)
    80001412:	e426                	sd	s1,8(sp)
    80001414:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001416:	fffff097          	auipc	ra,0xfffff
    8000141a:	760080e7          	jalr	1888(ra) # 80000b76 <kalloc>
    8000141e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001420:	c519                	beqz	a0,8000142e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001422:	6605                	lui	a2,0x1
    80001424:	4581                	li	a1,0
    80001426:	00000097          	auipc	ra,0x0
    8000142a:	988080e7          	jalr	-1656(ra) # 80000dae <memset>
  return pagetable;
}
    8000142e:	8526                	mv	a0,s1
    80001430:	60e2                	ld	ra,24(sp)
    80001432:	6442                	ld	s0,16(sp)
    80001434:	64a2                	ld	s1,8(sp)
    80001436:	6105                	addi	sp,sp,32
    80001438:	8082                	ret

000000008000143a <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000143a:	7179                	addi	sp,sp,-48
    8000143c:	f406                	sd	ra,40(sp)
    8000143e:	f022                	sd	s0,32(sp)
    80001440:	ec26                	sd	s1,24(sp)
    80001442:	e84a                	sd	s2,16(sp)
    80001444:	e44e                	sd	s3,8(sp)
    80001446:	e052                	sd	s4,0(sp)
    80001448:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000144a:	6785                	lui	a5,0x1
    8000144c:	04f67863          	bgeu	a2,a5,8000149c <uvmfirst+0x62>
    80001450:	8a2a                	mv	s4,a0
    80001452:	89ae                	mv	s3,a1
    80001454:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	720080e7          	jalr	1824(ra) # 80000b76 <kalloc>
    8000145e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001460:	6605                	lui	a2,0x1
    80001462:	4581                	li	a1,0
    80001464:	00000097          	auipc	ra,0x0
    80001468:	94a080e7          	jalr	-1718(ra) # 80000dae <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000146c:	4779                	li	a4,30
    8000146e:	86ca                	mv	a3,s2
    80001470:	6605                	lui	a2,0x1
    80001472:	4581                	li	a1,0
    80001474:	8552                	mv	a0,s4
    80001476:	00000097          	auipc	ra,0x0
    8000147a:	d0c080e7          	jalr	-756(ra) # 80001182 <mappages>
  memmove(mem, src, sz);
    8000147e:	8626                	mv	a2,s1
    80001480:	85ce                	mv	a1,s3
    80001482:	854a                	mv	a0,s2
    80001484:	00000097          	auipc	ra,0x0
    80001488:	98a080e7          	jalr	-1654(ra) # 80000e0e <memmove>
}
    8000148c:	70a2                	ld	ra,40(sp)
    8000148e:	7402                	ld	s0,32(sp)
    80001490:	64e2                	ld	s1,24(sp)
    80001492:	6942                	ld	s2,16(sp)
    80001494:	69a2                	ld	s3,8(sp)
    80001496:	6a02                	ld	s4,0(sp)
    80001498:	6145                	addi	sp,sp,48
    8000149a:	8082                	ret
    panic("uvmfirst: more than a page");
    8000149c:	00007517          	auipc	a0,0x7
    800014a0:	cfc50513          	addi	a0,a0,-772 # 80008198 <digits+0x148>
    800014a4:	fffff097          	auipc	ra,0xfffff
    800014a8:	0a0080e7          	jalr	160(ra) # 80000544 <panic>

00000000800014ac <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014ac:	1101                	addi	sp,sp,-32
    800014ae:	ec06                	sd	ra,24(sp)
    800014b0:	e822                	sd	s0,16(sp)
    800014b2:	e426                	sd	s1,8(sp)
    800014b4:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014b6:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014b8:	00b67d63          	bgeu	a2,a1,800014d2 <uvmdealloc+0x26>
    800014bc:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014be:	6785                	lui	a5,0x1
    800014c0:	17fd                	addi	a5,a5,-1
    800014c2:	00f60733          	add	a4,a2,a5
    800014c6:	767d                	lui	a2,0xfffff
    800014c8:	8f71                	and	a4,a4,a2
    800014ca:	97ae                	add	a5,a5,a1
    800014cc:	8ff1                	and	a5,a5,a2
    800014ce:	00f76863          	bltu	a4,a5,800014de <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014d2:	8526                	mv	a0,s1
    800014d4:	60e2                	ld	ra,24(sp)
    800014d6:	6442                	ld	s0,16(sp)
    800014d8:	64a2                	ld	s1,8(sp)
    800014da:	6105                	addi	sp,sp,32
    800014dc:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014de:	8f99                	sub	a5,a5,a4
    800014e0:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014e2:	4685                	li	a3,1
    800014e4:	0007861b          	sext.w	a2,a5
    800014e8:	85ba                	mv	a1,a4
    800014ea:	00000097          	auipc	ra,0x0
    800014ee:	e5e080e7          	jalr	-418(ra) # 80001348 <uvmunmap>
    800014f2:	b7c5                	j	800014d2 <uvmdealloc+0x26>

00000000800014f4 <uvmalloc>:
  if(newsz < oldsz)
    800014f4:	0ab66563          	bltu	a2,a1,8000159e <uvmalloc+0xaa>
{
    800014f8:	7139                	addi	sp,sp,-64
    800014fa:	fc06                	sd	ra,56(sp)
    800014fc:	f822                	sd	s0,48(sp)
    800014fe:	f426                	sd	s1,40(sp)
    80001500:	f04a                	sd	s2,32(sp)
    80001502:	ec4e                	sd	s3,24(sp)
    80001504:	e852                	sd	s4,16(sp)
    80001506:	e456                	sd	s5,8(sp)
    80001508:	e05a                	sd	s6,0(sp)
    8000150a:	0080                	addi	s0,sp,64
    8000150c:	8aaa                	mv	s5,a0
    8000150e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001510:	6985                	lui	s3,0x1
    80001512:	19fd                	addi	s3,s3,-1
    80001514:	95ce                	add	a1,a1,s3
    80001516:	79fd                	lui	s3,0xfffff
    80001518:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000151c:	08c9f363          	bgeu	s3,a2,800015a2 <uvmalloc+0xae>
    80001520:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001522:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	650080e7          	jalr	1616(ra) # 80000b76 <kalloc>
    8000152e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001530:	c51d                	beqz	a0,8000155e <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001532:	6605                	lui	a2,0x1
    80001534:	4581                	li	a1,0
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	878080e7          	jalr	-1928(ra) # 80000dae <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000153e:	875a                	mv	a4,s6
    80001540:	86a6                	mv	a3,s1
    80001542:	6605                	lui	a2,0x1
    80001544:	85ca                	mv	a1,s2
    80001546:	8556                	mv	a0,s5
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	c3a080e7          	jalr	-966(ra) # 80001182 <mappages>
    80001550:	e90d                	bnez	a0,80001582 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001552:	6785                	lui	a5,0x1
    80001554:	993e                	add	s2,s2,a5
    80001556:	fd4968e3          	bltu	s2,s4,80001526 <uvmalloc+0x32>
  return newsz;
    8000155a:	8552                	mv	a0,s4
    8000155c:	a809                	j	8000156e <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000155e:	864e                	mv	a2,s3
    80001560:	85ca                	mv	a1,s2
    80001562:	8556                	mv	a0,s5
    80001564:	00000097          	auipc	ra,0x0
    80001568:	f48080e7          	jalr	-184(ra) # 800014ac <uvmdealloc>
      return 0;
    8000156c:	4501                	li	a0,0
}
    8000156e:	70e2                	ld	ra,56(sp)
    80001570:	7442                	ld	s0,48(sp)
    80001572:	74a2                	ld	s1,40(sp)
    80001574:	7902                	ld	s2,32(sp)
    80001576:	69e2                	ld	s3,24(sp)
    80001578:	6a42                	ld	s4,16(sp)
    8000157a:	6aa2                	ld	s5,8(sp)
    8000157c:	6b02                	ld	s6,0(sp)
    8000157e:	6121                	addi	sp,sp,64
    80001580:	8082                	ret
      kfree(mem);
    80001582:	8526                	mv	a0,s1
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	48c080e7          	jalr	1164(ra) # 80000a10 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000158c:	864e                	mv	a2,s3
    8000158e:	85ca                	mv	a1,s2
    80001590:	8556                	mv	a0,s5
    80001592:	00000097          	auipc	ra,0x0
    80001596:	f1a080e7          	jalr	-230(ra) # 800014ac <uvmdealloc>
      return 0;
    8000159a:	4501                	li	a0,0
    8000159c:	bfc9                	j	8000156e <uvmalloc+0x7a>
    return oldsz;
    8000159e:	852e                	mv	a0,a1
}
    800015a0:	8082                	ret
  return newsz;
    800015a2:	8532                	mv	a0,a2
    800015a4:	b7e9                	j	8000156e <uvmalloc+0x7a>

00000000800015a6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015a6:	7179                	addi	sp,sp,-48
    800015a8:	f406                	sd	ra,40(sp)
    800015aa:	f022                	sd	s0,32(sp)
    800015ac:	ec26                	sd	s1,24(sp)
    800015ae:	e84a                	sd	s2,16(sp)
    800015b0:	e44e                	sd	s3,8(sp)
    800015b2:	e052                	sd	s4,0(sp)
    800015b4:	1800                	addi	s0,sp,48
    800015b6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015b8:	84aa                	mv	s1,a0
    800015ba:	6905                	lui	s2,0x1
    800015bc:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015be:	4985                	li	s3,1
    800015c0:	a821                	j	800015d8 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015c2:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015c4:	0532                	slli	a0,a0,0xc
    800015c6:	00000097          	auipc	ra,0x0
    800015ca:	fe0080e7          	jalr	-32(ra) # 800015a6 <freewalk>
      pagetable[i] = 0;
    800015ce:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015d2:	04a1                	addi	s1,s1,8
    800015d4:	03248163          	beq	s1,s2,800015f6 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015d8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015da:	00f57793          	andi	a5,a0,15
    800015de:	ff3782e3          	beq	a5,s3,800015c2 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015e2:	8905                	andi	a0,a0,1
    800015e4:	d57d                	beqz	a0,800015d2 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015e6:	00007517          	auipc	a0,0x7
    800015ea:	bd250513          	addi	a0,a0,-1070 # 800081b8 <digits+0x168>
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	f56080e7          	jalr	-170(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    800015f6:	8552                	mv	a0,s4
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	418080e7          	jalr	1048(ra) # 80000a10 <kfree>
}
    80001600:	70a2                	ld	ra,40(sp)
    80001602:	7402                	ld	s0,32(sp)
    80001604:	64e2                	ld	s1,24(sp)
    80001606:	6942                	ld	s2,16(sp)
    80001608:	69a2                	ld	s3,8(sp)
    8000160a:	6a02                	ld	s4,0(sp)
    8000160c:	6145                	addi	sp,sp,48
    8000160e:	8082                	ret

0000000080001610 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001610:	1101                	addi	sp,sp,-32
    80001612:	ec06                	sd	ra,24(sp)
    80001614:	e822                	sd	s0,16(sp)
    80001616:	e426                	sd	s1,8(sp)
    80001618:	1000                	addi	s0,sp,32
    8000161a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000161c:	e999                	bnez	a1,80001632 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000161e:	8526                	mv	a0,s1
    80001620:	00000097          	auipc	ra,0x0
    80001624:	f86080e7          	jalr	-122(ra) # 800015a6 <freewalk>
}
    80001628:	60e2                	ld	ra,24(sp)
    8000162a:	6442                	ld	s0,16(sp)
    8000162c:	64a2                	ld	s1,8(sp)
    8000162e:	6105                	addi	sp,sp,32
    80001630:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001632:	6605                	lui	a2,0x1
    80001634:	167d                	addi	a2,a2,-1
    80001636:	962e                	add	a2,a2,a1
    80001638:	4685                	li	a3,1
    8000163a:	8231                	srli	a2,a2,0xc
    8000163c:	4581                	li	a1,0
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	d0a080e7          	jalr	-758(ra) # 80001348 <uvmunmap>
    80001646:	bfe1                	j	8000161e <uvmfree+0xe>

0000000080001648 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001648:	c679                	beqz	a2,80001716 <uvmcopy+0xce>
{
    8000164a:	715d                	addi	sp,sp,-80
    8000164c:	e486                	sd	ra,72(sp)
    8000164e:	e0a2                	sd	s0,64(sp)
    80001650:	fc26                	sd	s1,56(sp)
    80001652:	f84a                	sd	s2,48(sp)
    80001654:	f44e                	sd	s3,40(sp)
    80001656:	f052                	sd	s4,32(sp)
    80001658:	ec56                	sd	s5,24(sp)
    8000165a:	e85a                	sd	s6,16(sp)
    8000165c:	e45e                	sd	s7,8(sp)
    8000165e:	0880                	addi	s0,sp,80
    80001660:	8b2a                	mv	s6,a0
    80001662:	8aae                	mv	s5,a1
    80001664:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001666:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001668:	4601                	li	a2,0
    8000166a:	85ce                	mv	a1,s3
    8000166c:	855a                	mv	a0,s6
    8000166e:	00000097          	auipc	ra,0x0
    80001672:	a2c080e7          	jalr	-1492(ra) # 8000109a <walk>
    80001676:	c531                	beqz	a0,800016c2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001678:	6118                	ld	a4,0(a0)
    8000167a:	00177793          	andi	a5,a4,1
    8000167e:	cbb1                	beqz	a5,800016d2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001680:	00a75593          	srli	a1,a4,0xa
    80001684:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001688:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000168c:	fffff097          	auipc	ra,0xfffff
    80001690:	4ea080e7          	jalr	1258(ra) # 80000b76 <kalloc>
    80001694:	892a                	mv	s2,a0
    80001696:	c939                	beqz	a0,800016ec <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001698:	6605                	lui	a2,0x1
    8000169a:	85de                	mv	a1,s7
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	772080e7          	jalr	1906(ra) # 80000e0e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016a4:	8726                	mv	a4,s1
    800016a6:	86ca                	mv	a3,s2
    800016a8:	6605                	lui	a2,0x1
    800016aa:	85ce                	mv	a1,s3
    800016ac:	8556                	mv	a0,s5
    800016ae:	00000097          	auipc	ra,0x0
    800016b2:	ad4080e7          	jalr	-1324(ra) # 80001182 <mappages>
    800016b6:	e515                	bnez	a0,800016e2 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016b8:	6785                	lui	a5,0x1
    800016ba:	99be                	add	s3,s3,a5
    800016bc:	fb49e6e3          	bltu	s3,s4,80001668 <uvmcopy+0x20>
    800016c0:	a081                	j	80001700 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016c2:	00007517          	auipc	a0,0x7
    800016c6:	b0650513          	addi	a0,a0,-1274 # 800081c8 <digits+0x178>
    800016ca:	fffff097          	auipc	ra,0xfffff
    800016ce:	e7a080e7          	jalr	-390(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    800016d2:	00007517          	auipc	a0,0x7
    800016d6:	b1650513          	addi	a0,a0,-1258 # 800081e8 <digits+0x198>
    800016da:	fffff097          	auipc	ra,0xfffff
    800016de:	e6a080e7          	jalr	-406(ra) # 80000544 <panic>
      kfree(mem);
    800016e2:	854a                	mv	a0,s2
    800016e4:	fffff097          	auipc	ra,0xfffff
    800016e8:	32c080e7          	jalr	812(ra) # 80000a10 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016ec:	4685                	li	a3,1
    800016ee:	00c9d613          	srli	a2,s3,0xc
    800016f2:	4581                	li	a1,0
    800016f4:	8556                	mv	a0,s5
    800016f6:	00000097          	auipc	ra,0x0
    800016fa:	c52080e7          	jalr	-942(ra) # 80001348 <uvmunmap>
  return -1;
    800016fe:	557d                	li	a0,-1
}
    80001700:	60a6                	ld	ra,72(sp)
    80001702:	6406                	ld	s0,64(sp)
    80001704:	74e2                	ld	s1,56(sp)
    80001706:	7942                	ld	s2,48(sp)
    80001708:	79a2                	ld	s3,40(sp)
    8000170a:	7a02                	ld	s4,32(sp)
    8000170c:	6ae2                	ld	s5,24(sp)
    8000170e:	6b42                	ld	s6,16(sp)
    80001710:	6ba2                	ld	s7,8(sp)
    80001712:	6161                	addi	sp,sp,80
    80001714:	8082                	ret
  return 0;
    80001716:	4501                	li	a0,0
}
    80001718:	8082                	ret

000000008000171a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000171a:	1141                	addi	sp,sp,-16
    8000171c:	e406                	sd	ra,8(sp)
    8000171e:	e022                	sd	s0,0(sp)
    80001720:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001722:	4601                	li	a2,0
    80001724:	00000097          	auipc	ra,0x0
    80001728:	976080e7          	jalr	-1674(ra) # 8000109a <walk>
  if(pte == 0)
    8000172c:	c901                	beqz	a0,8000173c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000172e:	611c                	ld	a5,0(a0)
    80001730:	9bbd                	andi	a5,a5,-17
    80001732:	e11c                	sd	a5,0(a0)
}
    80001734:	60a2                	ld	ra,8(sp)
    80001736:	6402                	ld	s0,0(sp)
    80001738:	0141                	addi	sp,sp,16
    8000173a:	8082                	ret
    panic("uvmclear");
    8000173c:	00007517          	auipc	a0,0x7
    80001740:	acc50513          	addi	a0,a0,-1332 # 80008208 <digits+0x1b8>
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	e00080e7          	jalr	-512(ra) # 80000544 <panic>

000000008000174c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000174c:	c6bd                	beqz	a3,800017ba <copyout+0x6e>
{
    8000174e:	715d                	addi	sp,sp,-80
    80001750:	e486                	sd	ra,72(sp)
    80001752:	e0a2                	sd	s0,64(sp)
    80001754:	fc26                	sd	s1,56(sp)
    80001756:	f84a                	sd	s2,48(sp)
    80001758:	f44e                	sd	s3,40(sp)
    8000175a:	f052                	sd	s4,32(sp)
    8000175c:	ec56                	sd	s5,24(sp)
    8000175e:	e85a                	sd	s6,16(sp)
    80001760:	e45e                	sd	s7,8(sp)
    80001762:	e062                	sd	s8,0(sp)
    80001764:	0880                	addi	s0,sp,80
    80001766:	8b2a                	mv	s6,a0
    80001768:	8c2e                	mv	s8,a1
    8000176a:	8a32                	mv	s4,a2
    8000176c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000176e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001770:	6a85                	lui	s5,0x1
    80001772:	a015                	j	80001796 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001774:	9562                	add	a0,a0,s8
    80001776:	0004861b          	sext.w	a2,s1
    8000177a:	85d2                	mv	a1,s4
    8000177c:	41250533          	sub	a0,a0,s2
    80001780:	fffff097          	auipc	ra,0xfffff
    80001784:	68e080e7          	jalr	1678(ra) # 80000e0e <memmove>

    len -= n;
    80001788:	409989b3          	sub	s3,s3,s1
    src += n;
    8000178c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000178e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001792:	02098263          	beqz	s3,800017b6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001796:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000179a:	85ca                	mv	a1,s2
    8000179c:	855a                	mv	a0,s6
    8000179e:	00000097          	auipc	ra,0x0
    800017a2:	9a2080e7          	jalr	-1630(ra) # 80001140 <walkaddr>
    if(pa0 == 0)
    800017a6:	cd01                	beqz	a0,800017be <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017a8:	418904b3          	sub	s1,s2,s8
    800017ac:	94d6                	add	s1,s1,s5
    if(n > len)
    800017ae:	fc99f3e3          	bgeu	s3,s1,80001774 <copyout+0x28>
    800017b2:	84ce                	mv	s1,s3
    800017b4:	b7c1                	j	80001774 <copyout+0x28>
  }
  return 0;
    800017b6:	4501                	li	a0,0
    800017b8:	a021                	j	800017c0 <copyout+0x74>
    800017ba:	4501                	li	a0,0
}
    800017bc:	8082                	ret
      return -1;
    800017be:	557d                	li	a0,-1
}
    800017c0:	60a6                	ld	ra,72(sp)
    800017c2:	6406                	ld	s0,64(sp)
    800017c4:	74e2                	ld	s1,56(sp)
    800017c6:	7942                	ld	s2,48(sp)
    800017c8:	79a2                	ld	s3,40(sp)
    800017ca:	7a02                	ld	s4,32(sp)
    800017cc:	6ae2                	ld	s5,24(sp)
    800017ce:	6b42                	ld	s6,16(sp)
    800017d0:	6ba2                	ld	s7,8(sp)
    800017d2:	6c02                	ld	s8,0(sp)
    800017d4:	6161                	addi	sp,sp,80
    800017d6:	8082                	ret

00000000800017d8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017d8:	c6bd                	beqz	a3,80001846 <copyin+0x6e>
{
    800017da:	715d                	addi	sp,sp,-80
    800017dc:	e486                	sd	ra,72(sp)
    800017de:	e0a2                	sd	s0,64(sp)
    800017e0:	fc26                	sd	s1,56(sp)
    800017e2:	f84a                	sd	s2,48(sp)
    800017e4:	f44e                	sd	s3,40(sp)
    800017e6:	f052                	sd	s4,32(sp)
    800017e8:	ec56                	sd	s5,24(sp)
    800017ea:	e85a                	sd	s6,16(sp)
    800017ec:	e45e                	sd	s7,8(sp)
    800017ee:	e062                	sd	s8,0(sp)
    800017f0:	0880                	addi	s0,sp,80
    800017f2:	8b2a                	mv	s6,a0
    800017f4:	8a2e                	mv	s4,a1
    800017f6:	8c32                	mv	s8,a2
    800017f8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017fa:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017fc:	6a85                	lui	s5,0x1
    800017fe:	a015                	j	80001822 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001800:	9562                	add	a0,a0,s8
    80001802:	0004861b          	sext.w	a2,s1
    80001806:	412505b3          	sub	a1,a0,s2
    8000180a:	8552                	mv	a0,s4
    8000180c:	fffff097          	auipc	ra,0xfffff
    80001810:	602080e7          	jalr	1538(ra) # 80000e0e <memmove>

    len -= n;
    80001814:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001818:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000181a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000181e:	02098263          	beqz	s3,80001842 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001822:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001826:	85ca                	mv	a1,s2
    80001828:	855a                	mv	a0,s6
    8000182a:	00000097          	auipc	ra,0x0
    8000182e:	916080e7          	jalr	-1770(ra) # 80001140 <walkaddr>
    if(pa0 == 0)
    80001832:	cd01                	beqz	a0,8000184a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001834:	418904b3          	sub	s1,s2,s8
    80001838:	94d6                	add	s1,s1,s5
    if(n > len)
    8000183a:	fc99f3e3          	bgeu	s3,s1,80001800 <copyin+0x28>
    8000183e:	84ce                	mv	s1,s3
    80001840:	b7c1                	j	80001800 <copyin+0x28>
  }
  return 0;
    80001842:	4501                	li	a0,0
    80001844:	a021                	j	8000184c <copyin+0x74>
    80001846:	4501                	li	a0,0
}
    80001848:	8082                	ret
      return -1;
    8000184a:	557d                	li	a0,-1
}
    8000184c:	60a6                	ld	ra,72(sp)
    8000184e:	6406                	ld	s0,64(sp)
    80001850:	74e2                	ld	s1,56(sp)
    80001852:	7942                	ld	s2,48(sp)
    80001854:	79a2                	ld	s3,40(sp)
    80001856:	7a02                	ld	s4,32(sp)
    80001858:	6ae2                	ld	s5,24(sp)
    8000185a:	6b42                	ld	s6,16(sp)
    8000185c:	6ba2                	ld	s7,8(sp)
    8000185e:	6c02                	ld	s8,0(sp)
    80001860:	6161                	addi	sp,sp,80
    80001862:	8082                	ret

0000000080001864 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001864:	c6c5                	beqz	a3,8000190c <copyinstr+0xa8>
{
    80001866:	715d                	addi	sp,sp,-80
    80001868:	e486                	sd	ra,72(sp)
    8000186a:	e0a2                	sd	s0,64(sp)
    8000186c:	fc26                	sd	s1,56(sp)
    8000186e:	f84a                	sd	s2,48(sp)
    80001870:	f44e                	sd	s3,40(sp)
    80001872:	f052                	sd	s4,32(sp)
    80001874:	ec56                	sd	s5,24(sp)
    80001876:	e85a                	sd	s6,16(sp)
    80001878:	e45e                	sd	s7,8(sp)
    8000187a:	0880                	addi	s0,sp,80
    8000187c:	8a2a                	mv	s4,a0
    8000187e:	8b2e                	mv	s6,a1
    80001880:	8bb2                	mv	s7,a2
    80001882:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001884:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001886:	6985                	lui	s3,0x1
    80001888:	a035                	j	800018b4 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000188a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000188e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001890:	0017b793          	seqz	a5,a5
    80001894:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001898:	60a6                	ld	ra,72(sp)
    8000189a:	6406                	ld	s0,64(sp)
    8000189c:	74e2                	ld	s1,56(sp)
    8000189e:	7942                	ld	s2,48(sp)
    800018a0:	79a2                	ld	s3,40(sp)
    800018a2:	7a02                	ld	s4,32(sp)
    800018a4:	6ae2                	ld	s5,24(sp)
    800018a6:	6b42                	ld	s6,16(sp)
    800018a8:	6ba2                	ld	s7,8(sp)
    800018aa:	6161                	addi	sp,sp,80
    800018ac:	8082                	ret
    srcva = va0 + PGSIZE;
    800018ae:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018b2:	c8a9                	beqz	s1,80001904 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018b4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018b8:	85ca                	mv	a1,s2
    800018ba:	8552                	mv	a0,s4
    800018bc:	00000097          	auipc	ra,0x0
    800018c0:	884080e7          	jalr	-1916(ra) # 80001140 <walkaddr>
    if(pa0 == 0)
    800018c4:	c131                	beqz	a0,80001908 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018c6:	41790833          	sub	a6,s2,s7
    800018ca:	984e                	add	a6,a6,s3
    if(n > max)
    800018cc:	0104f363          	bgeu	s1,a6,800018d2 <copyinstr+0x6e>
    800018d0:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018d2:	955e                	add	a0,a0,s7
    800018d4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018d8:	fc080be3          	beqz	a6,800018ae <copyinstr+0x4a>
    800018dc:	985a                	add	a6,a6,s6
    800018de:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018e0:	41650633          	sub	a2,a0,s6
    800018e4:	14fd                	addi	s1,s1,-1
    800018e6:	9b26                	add	s6,s6,s1
    800018e8:	00f60733          	add	a4,a2,a5
    800018ec:	00074703          	lbu	a4,0(a4)
    800018f0:	df49                	beqz	a4,8000188a <copyinstr+0x26>
        *dst = *p;
    800018f2:	00e78023          	sb	a4,0(a5)
      --max;
    800018f6:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018fa:	0785                	addi	a5,a5,1
    while(n > 0){
    800018fc:	ff0796e3          	bne	a5,a6,800018e8 <copyinstr+0x84>
      dst++;
    80001900:	8b42                	mv	s6,a6
    80001902:	b775                	j	800018ae <copyinstr+0x4a>
    80001904:	4781                	li	a5,0
    80001906:	b769                	j	80001890 <copyinstr+0x2c>
      return -1;
    80001908:	557d                	li	a0,-1
    8000190a:	b779                	j	80001898 <copyinstr+0x34>
  int got_null = 0;
    8000190c:	4781                	li	a5,0
  if(got_null){
    8000190e:	0017b793          	seqz	a5,a5
    80001912:	40f00533          	neg	a0,a5
}
    80001916:	8082                	ret

0000000080001918 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001918:	715d                	addi	sp,sp,-80
    8000191a:	e486                	sd	ra,72(sp)
    8000191c:	e0a2                	sd	s0,64(sp)
    8000191e:	fc26                	sd	s1,56(sp)
    80001920:	f84a                	sd	s2,48(sp)
    80001922:	f44e                	sd	s3,40(sp)
    80001924:	f052                	sd	s4,32(sp)
    80001926:	ec56                	sd	s5,24(sp)
    80001928:	e85a                	sd	s6,16(sp)
    8000192a:	e45e                	sd	s7,8(sp)
    8000192c:	e062                	sd	s8,0(sp)
    8000192e:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80001930:	8912                	mv	s2,tp
    int id = r_tp();
    80001932:	2901                	sext.w	s2,s2
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001934:	0000fa97          	auipc	s5,0xf
    80001938:	39ca8a93          	addi	s5,s5,924 # 80010cd0 <cpus>
    8000193c:	00791793          	slli	a5,s2,0x7
    80001940:	00fa8733          	add	a4,s5,a5
    80001944:	00073023          	sd	zero,0(a4)
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    80001948:	07a1                	addi	a5,a5,8
    8000194a:	9abe                	add	s5,s5,a5
                c->proc = p;
    8000194c:	893a                	mv	s2,a4
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    8000194e:	00007c17          	auipc	s8,0x7
    80001952:	03ac0c13          	addi	s8,s8,58 # 80008988 <sched_pointer>
    80001956:	00000b97          	auipc	s7,0x0
    8000195a:	fc2b8b93          	addi	s7,s7,-62 # 80001918 <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000195e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001962:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001966:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    8000196a:	0000f497          	auipc	s1,0xf
    8000196e:	79648493          	addi	s1,s1,1942 # 80011100 <proc>
            if (p->state == RUNNABLE)
    80001972:	498d                	li	s3,3
                p->state = RUNNING;
    80001974:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    80001976:	00015a17          	auipc	s4,0x15
    8000197a:	18aa0a13          	addi	s4,s4,394 # 80016b00 <tickslock>
    8000197e:	a81d                	j	800019b4 <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001980:	8526                	mv	a0,s1
    80001982:	fffff097          	auipc	ra,0xfffff
    80001986:	3e4080e7          	jalr	996(ra) # 80000d66 <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    8000198a:	60a6                	ld	ra,72(sp)
    8000198c:	6406                	ld	s0,64(sp)
    8000198e:	74e2                	ld	s1,56(sp)
    80001990:	7942                	ld	s2,48(sp)
    80001992:	79a2                	ld	s3,40(sp)
    80001994:	7a02                	ld	s4,32(sp)
    80001996:	6ae2                	ld	s5,24(sp)
    80001998:	6b42                	ld	s6,16(sp)
    8000199a:	6ba2                	ld	s7,8(sp)
    8000199c:	6c02                	ld	s8,0(sp)
    8000199e:	6161                	addi	sp,sp,80
    800019a0:	8082                	ret
            release(&p->lock);
    800019a2:	8526                	mv	a0,s1
    800019a4:	fffff097          	auipc	ra,0xfffff
    800019a8:	3c2080e7          	jalr	962(ra) # 80000d66 <release>
        for (p = proc; p < &proc[NPROC]; p++)
    800019ac:	16848493          	addi	s1,s1,360
    800019b0:	fb4487e3          	beq	s1,s4,8000195e <rr_scheduler+0x46>
            acquire(&p->lock);
    800019b4:	8526                	mv	a0,s1
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	2fc080e7          	jalr	764(ra) # 80000cb2 <acquire>
            if (p->state == RUNNABLE)
    800019be:	4c9c                	lw	a5,24(s1)
    800019c0:	ff3791e3          	bne	a5,s3,800019a2 <rr_scheduler+0x8a>
                p->state = RUNNING;
    800019c4:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    800019c8:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    800019cc:	06048593          	addi	a1,s1,96
    800019d0:	8556                	mv	a0,s5
    800019d2:	00001097          	auipc	ra,0x1
    800019d6:	fbc080e7          	jalr	-68(ra) # 8000298e <swtch>
                if (sched_pointer != &rr_scheduler)
    800019da:	000c3783          	ld	a5,0(s8)
    800019de:	fb7791e3          	bne	a5,s7,80001980 <rr_scheduler+0x68>
                c->proc = 0;
    800019e2:	00093023          	sd	zero,0(s2)
    800019e6:	bf75                	j	800019a2 <rr_scheduler+0x8a>

00000000800019e8 <proc_mapstacks>:
{
    800019e8:	7139                	addi	sp,sp,-64
    800019ea:	fc06                	sd	ra,56(sp)
    800019ec:	f822                	sd	s0,48(sp)
    800019ee:	f426                	sd	s1,40(sp)
    800019f0:	f04a                	sd	s2,32(sp)
    800019f2:	ec4e                	sd	s3,24(sp)
    800019f4:	e852                	sd	s4,16(sp)
    800019f6:	e456                	sd	s5,8(sp)
    800019f8:	e05a                	sd	s6,0(sp)
    800019fa:	0080                	addi	s0,sp,64
    800019fc:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    800019fe:	0000f497          	auipc	s1,0xf
    80001a02:	70248493          	addi	s1,s1,1794 # 80011100 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001a06:	8b26                	mv	s6,s1
    80001a08:	00006a97          	auipc	s5,0x6
    80001a0c:	608a8a93          	addi	s5,s5,1544 # 80008010 <__func__.1508+0x8>
    80001a10:	04000937          	lui	s2,0x4000
    80001a14:	197d                	addi	s2,s2,-1
    80001a16:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001a18:	00015a17          	auipc	s4,0x15
    80001a1c:	0e8a0a13          	addi	s4,s4,232 # 80016b00 <tickslock>
        char *pa = kalloc();
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	156080e7          	jalr	342(ra) # 80000b76 <kalloc>
    80001a28:	862a                	mv	a2,a0
        if (pa == 0)
    80001a2a:	c131                	beqz	a0,80001a6e <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001a2c:	416485b3          	sub	a1,s1,s6
    80001a30:	858d                	srai	a1,a1,0x3
    80001a32:	000ab783          	ld	a5,0(s5)
    80001a36:	02f585b3          	mul	a1,a1,a5
    80001a3a:	2585                	addiw	a1,a1,1
    80001a3c:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a40:	4719                	li	a4,6
    80001a42:	6685                	lui	a3,0x1
    80001a44:	40b905b3          	sub	a1,s2,a1
    80001a48:	854e                	mv	a0,s3
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	7d8080e7          	jalr	2008(ra) # 80001222 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001a52:	16848493          	addi	s1,s1,360
    80001a56:	fd4495e3          	bne	s1,s4,80001a20 <proc_mapstacks+0x38>
}
    80001a5a:	70e2                	ld	ra,56(sp)
    80001a5c:	7442                	ld	s0,48(sp)
    80001a5e:	74a2                	ld	s1,40(sp)
    80001a60:	7902                	ld	s2,32(sp)
    80001a62:	69e2                	ld	s3,24(sp)
    80001a64:	6a42                	ld	s4,16(sp)
    80001a66:	6aa2                	ld	s5,8(sp)
    80001a68:	6b02                	ld	s6,0(sp)
    80001a6a:	6121                	addi	sp,sp,64
    80001a6c:	8082                	ret
            panic("kalloc");
    80001a6e:	00006517          	auipc	a0,0x6
    80001a72:	7aa50513          	addi	a0,a0,1962 # 80008218 <digits+0x1c8>
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	ace080e7          	jalr	-1330(ra) # 80000544 <panic>

0000000080001a7e <procinit>:
{
    80001a7e:	7139                	addi	sp,sp,-64
    80001a80:	fc06                	sd	ra,56(sp)
    80001a82:	f822                	sd	s0,48(sp)
    80001a84:	f426                	sd	s1,40(sp)
    80001a86:	f04a                	sd	s2,32(sp)
    80001a88:	ec4e                	sd	s3,24(sp)
    80001a8a:	e852                	sd	s4,16(sp)
    80001a8c:	e456                	sd	s5,8(sp)
    80001a8e:	e05a                	sd	s6,0(sp)
    80001a90:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001a92:	00006597          	auipc	a1,0x6
    80001a96:	78e58593          	addi	a1,a1,1934 # 80008220 <digits+0x1d0>
    80001a9a:	0000f517          	auipc	a0,0xf
    80001a9e:	63650513          	addi	a0,a0,1590 # 800110d0 <pid_lock>
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	180080e7          	jalr	384(ra) # 80000c22 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001aaa:	00006597          	auipc	a1,0x6
    80001aae:	77e58593          	addi	a1,a1,1918 # 80008228 <digits+0x1d8>
    80001ab2:	0000f517          	auipc	a0,0xf
    80001ab6:	63650513          	addi	a0,a0,1590 # 800110e8 <wait_lock>
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	168080e7          	jalr	360(ra) # 80000c22 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001ac2:	0000f497          	auipc	s1,0xf
    80001ac6:	63e48493          	addi	s1,s1,1598 # 80011100 <proc>
        initlock(&p->lock, "proc");
    80001aca:	00006b17          	auipc	s6,0x6
    80001ace:	76eb0b13          	addi	s6,s6,1902 # 80008238 <digits+0x1e8>
        p->kstack = KSTACK((int)(p - proc));
    80001ad2:	8aa6                	mv	s5,s1
    80001ad4:	00006a17          	auipc	s4,0x6
    80001ad8:	53ca0a13          	addi	s4,s4,1340 # 80008010 <__func__.1508+0x8>
    80001adc:	04000937          	lui	s2,0x4000
    80001ae0:	197d                	addi	s2,s2,-1
    80001ae2:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001ae4:	00015997          	auipc	s3,0x15
    80001ae8:	01c98993          	addi	s3,s3,28 # 80016b00 <tickslock>
        initlock(&p->lock, "proc");
    80001aec:	85da                	mv	a1,s6
    80001aee:	8526                	mv	a0,s1
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	132080e7          	jalr	306(ra) # 80000c22 <initlock>
        p->state = UNUSED;
    80001af8:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001afc:	415487b3          	sub	a5,s1,s5
    80001b00:	878d                	srai	a5,a5,0x3
    80001b02:	000a3703          	ld	a4,0(s4)
    80001b06:	02e787b3          	mul	a5,a5,a4
    80001b0a:	2785                	addiw	a5,a5,1
    80001b0c:	00d7979b          	slliw	a5,a5,0xd
    80001b10:	40f907b3          	sub	a5,s2,a5
    80001b14:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001b16:	16848493          	addi	s1,s1,360
    80001b1a:	fd3499e3          	bne	s1,s3,80001aec <procinit+0x6e>
}
    80001b1e:	70e2                	ld	ra,56(sp)
    80001b20:	7442                	ld	s0,48(sp)
    80001b22:	74a2                	ld	s1,40(sp)
    80001b24:	7902                	ld	s2,32(sp)
    80001b26:	69e2                	ld	s3,24(sp)
    80001b28:	6a42                	ld	s4,16(sp)
    80001b2a:	6aa2                	ld	s5,8(sp)
    80001b2c:	6b02                	ld	s6,0(sp)
    80001b2e:	6121                	addi	sp,sp,64
    80001b30:	8082                	ret

0000000080001b32 <copy_array>:
{
    80001b32:	1141                	addi	sp,sp,-16
    80001b34:	e422                	sd	s0,8(sp)
    80001b36:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001b38:	02c05163          	blez	a2,80001b5a <copy_array+0x28>
    80001b3c:	87aa                	mv	a5,a0
    80001b3e:	0505                	addi	a0,a0,1
    80001b40:	fff6069b          	addiw	a3,a2,-1
    80001b44:	1682                	slli	a3,a3,0x20
    80001b46:	9281                	srli	a3,a3,0x20
    80001b48:	96aa                	add	a3,a3,a0
        dst[i] = src[i];
    80001b4a:	0007c703          	lbu	a4,0(a5)
    80001b4e:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001b52:	0785                	addi	a5,a5,1
    80001b54:	0585                	addi	a1,a1,1
    80001b56:	fed79ae3          	bne	a5,a3,80001b4a <copy_array+0x18>
}
    80001b5a:	6422                	ld	s0,8(sp)
    80001b5c:	0141                	addi	sp,sp,16
    80001b5e:	8082                	ret

0000000080001b60 <cpuid>:
{
    80001b60:	1141                	addi	sp,sp,-16
    80001b62:	e422                	sd	s0,8(sp)
    80001b64:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b66:	8512                	mv	a0,tp
}
    80001b68:	2501                	sext.w	a0,a0
    80001b6a:	6422                	ld	s0,8(sp)
    80001b6c:	0141                	addi	sp,sp,16
    80001b6e:	8082                	ret

0000000080001b70 <mycpu>:
{
    80001b70:	1141                	addi	sp,sp,-16
    80001b72:	e422                	sd	s0,8(sp)
    80001b74:	0800                	addi	s0,sp,16
    80001b76:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001b78:	2781                	sext.w	a5,a5
    80001b7a:	079e                	slli	a5,a5,0x7
}
    80001b7c:	0000f517          	auipc	a0,0xf
    80001b80:	15450513          	addi	a0,a0,340 # 80010cd0 <cpus>
    80001b84:	953e                	add	a0,a0,a5
    80001b86:	6422                	ld	s0,8(sp)
    80001b88:	0141                	addi	sp,sp,16
    80001b8a:	8082                	ret

0000000080001b8c <myproc>:
{
    80001b8c:	1101                	addi	sp,sp,-32
    80001b8e:	ec06                	sd	ra,24(sp)
    80001b90:	e822                	sd	s0,16(sp)
    80001b92:	e426                	sd	s1,8(sp)
    80001b94:	1000                	addi	s0,sp,32
    push_off();
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	0d0080e7          	jalr	208(ra) # 80000c66 <push_off>
    80001b9e:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001ba0:	2781                	sext.w	a5,a5
    80001ba2:	079e                	slli	a5,a5,0x7
    80001ba4:	0000f717          	auipc	a4,0xf
    80001ba8:	12c70713          	addi	a4,a4,300 # 80010cd0 <cpus>
    80001bac:	97ba                	add	a5,a5,a4
    80001bae:	6384                	ld	s1,0(a5)
    pop_off();
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	156080e7          	jalr	342(ra) # 80000d06 <pop_off>
}
    80001bb8:	8526                	mv	a0,s1
    80001bba:	60e2                	ld	ra,24(sp)
    80001bbc:	6442                	ld	s0,16(sp)
    80001bbe:	64a2                	ld	s1,8(sp)
    80001bc0:	6105                	addi	sp,sp,32
    80001bc2:	8082                	ret

0000000080001bc4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bc4:	1141                	addi	sp,sp,-16
    80001bc6:	e406                	sd	ra,8(sp)
    80001bc8:	e022                	sd	s0,0(sp)
    80001bca:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001bcc:	00000097          	auipc	ra,0x0
    80001bd0:	fc0080e7          	jalr	-64(ra) # 80001b8c <myproc>
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	192080e7          	jalr	402(ra) # 80000d66 <release>

    if (first)
    80001bdc:	00007797          	auipc	a5,0x7
    80001be0:	da47a783          	lw	a5,-604(a5) # 80008980 <first.1730>
    80001be4:	eb89                	bnez	a5,80001bf6 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001be6:	00001097          	auipc	ra,0x1
    80001bea:	e52080e7          	jalr	-430(ra) # 80002a38 <usertrapret>
}
    80001bee:	60a2                	ld	ra,8(sp)
    80001bf0:	6402                	ld	s0,0(sp)
    80001bf2:	0141                	addi	sp,sp,16
    80001bf4:	8082                	ret
        first = 0;
    80001bf6:	00007797          	auipc	a5,0x7
    80001bfa:	d807a523          	sw	zero,-630(a5) # 80008980 <first.1730>
        fsinit(ROOTDEV);
    80001bfe:	4505                	li	a0,1
    80001c00:	00002097          	auipc	ra,0x2
    80001c04:	ca0080e7          	jalr	-864(ra) # 800038a0 <fsinit>
    80001c08:	bff9                	j	80001be6 <forkret+0x22>

0000000080001c0a <allocpid>:
{
    80001c0a:	1101                	addi	sp,sp,-32
    80001c0c:	ec06                	sd	ra,24(sp)
    80001c0e:	e822                	sd	s0,16(sp)
    80001c10:	e426                	sd	s1,8(sp)
    80001c12:	e04a                	sd	s2,0(sp)
    80001c14:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001c16:	0000f917          	auipc	s2,0xf
    80001c1a:	4ba90913          	addi	s2,s2,1210 # 800110d0 <pid_lock>
    80001c1e:	854a                	mv	a0,s2
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	092080e7          	jalr	146(ra) # 80000cb2 <acquire>
    pid = nextpid;
    80001c28:	00007797          	auipc	a5,0x7
    80001c2c:	d6878793          	addi	a5,a5,-664 # 80008990 <nextpid>
    80001c30:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001c32:	0014871b          	addiw	a4,s1,1
    80001c36:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001c38:	854a                	mv	a0,s2
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	12c080e7          	jalr	300(ra) # 80000d66 <release>
}
    80001c42:	8526                	mv	a0,s1
    80001c44:	60e2                	ld	ra,24(sp)
    80001c46:	6442                	ld	s0,16(sp)
    80001c48:	64a2                	ld	s1,8(sp)
    80001c4a:	6902                	ld	s2,0(sp)
    80001c4c:	6105                	addi	sp,sp,32
    80001c4e:	8082                	ret

0000000080001c50 <proc_pagetable>:
{
    80001c50:	1101                	addi	sp,sp,-32
    80001c52:	ec06                	sd	ra,24(sp)
    80001c54:	e822                	sd	s0,16(sp)
    80001c56:	e426                	sd	s1,8(sp)
    80001c58:	e04a                	sd	s2,0(sp)
    80001c5a:	1000                	addi	s0,sp,32
    80001c5c:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	7ae080e7          	jalr	1966(ra) # 8000140c <uvmcreate>
    80001c66:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001c68:	c121                	beqz	a0,80001ca8 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c6a:	4729                	li	a4,10
    80001c6c:	00005697          	auipc	a3,0x5
    80001c70:	39468693          	addi	a3,a3,916 # 80007000 <_trampoline>
    80001c74:	6605                	lui	a2,0x1
    80001c76:	040005b7          	lui	a1,0x4000
    80001c7a:	15fd                	addi	a1,a1,-1
    80001c7c:	05b2                	slli	a1,a1,0xc
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	504080e7          	jalr	1284(ra) # 80001182 <mappages>
    80001c86:	02054863          	bltz	a0,80001cb6 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c8a:	4719                	li	a4,6
    80001c8c:	05893683          	ld	a3,88(s2)
    80001c90:	6605                	lui	a2,0x1
    80001c92:	020005b7          	lui	a1,0x2000
    80001c96:	15fd                	addi	a1,a1,-1
    80001c98:	05b6                	slli	a1,a1,0xd
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	4e6080e7          	jalr	1254(ra) # 80001182 <mappages>
    80001ca4:	02054163          	bltz	a0,80001cc6 <proc_pagetable+0x76>
}
    80001ca8:	8526                	mv	a0,s1
    80001caa:	60e2                	ld	ra,24(sp)
    80001cac:	6442                	ld	s0,16(sp)
    80001cae:	64a2                	ld	s1,8(sp)
    80001cb0:	6902                	ld	s2,0(sp)
    80001cb2:	6105                	addi	sp,sp,32
    80001cb4:	8082                	ret
        uvmfree(pagetable, 0);
    80001cb6:	4581                	li	a1,0
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	956080e7          	jalr	-1706(ra) # 80001610 <uvmfree>
        return 0;
    80001cc2:	4481                	li	s1,0
    80001cc4:	b7d5                	j	80001ca8 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cc6:	4681                	li	a3,0
    80001cc8:	4605                	li	a2,1
    80001cca:	040005b7          	lui	a1,0x4000
    80001cce:	15fd                	addi	a1,a1,-1
    80001cd0:	05b2                	slli	a1,a1,0xc
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	674080e7          	jalr	1652(ra) # 80001348 <uvmunmap>
        uvmfree(pagetable, 0);
    80001cdc:	4581                	li	a1,0
    80001cde:	8526                	mv	a0,s1
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	930080e7          	jalr	-1744(ra) # 80001610 <uvmfree>
        return 0;
    80001ce8:	4481                	li	s1,0
    80001cea:	bf7d                	j	80001ca8 <proc_pagetable+0x58>

0000000080001cec <proc_freepagetable>:
{
    80001cec:	1101                	addi	sp,sp,-32
    80001cee:	ec06                	sd	ra,24(sp)
    80001cf0:	e822                	sd	s0,16(sp)
    80001cf2:	e426                	sd	s1,8(sp)
    80001cf4:	e04a                	sd	s2,0(sp)
    80001cf6:	1000                	addi	s0,sp,32
    80001cf8:	84aa                	mv	s1,a0
    80001cfa:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cfc:	4681                	li	a3,0
    80001cfe:	4605                	li	a2,1
    80001d00:	040005b7          	lui	a1,0x4000
    80001d04:	15fd                	addi	a1,a1,-1
    80001d06:	05b2                	slli	a1,a1,0xc
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	640080e7          	jalr	1600(ra) # 80001348 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d10:	4681                	li	a3,0
    80001d12:	4605                	li	a2,1
    80001d14:	020005b7          	lui	a1,0x2000
    80001d18:	15fd                	addi	a1,a1,-1
    80001d1a:	05b6                	slli	a1,a1,0xd
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	62a080e7          	jalr	1578(ra) # 80001348 <uvmunmap>
    uvmfree(pagetable, sz);
    80001d26:	85ca                	mv	a1,s2
    80001d28:	8526                	mv	a0,s1
    80001d2a:	00000097          	auipc	ra,0x0
    80001d2e:	8e6080e7          	jalr	-1818(ra) # 80001610 <uvmfree>
}
    80001d32:	60e2                	ld	ra,24(sp)
    80001d34:	6442                	ld	s0,16(sp)
    80001d36:	64a2                	ld	s1,8(sp)
    80001d38:	6902                	ld	s2,0(sp)
    80001d3a:	6105                	addi	sp,sp,32
    80001d3c:	8082                	ret

0000000080001d3e <freeproc>:
{
    80001d3e:	1101                	addi	sp,sp,-32
    80001d40:	ec06                	sd	ra,24(sp)
    80001d42:	e822                	sd	s0,16(sp)
    80001d44:	e426                	sd	s1,8(sp)
    80001d46:	1000                	addi	s0,sp,32
    80001d48:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001d4a:	6d28                	ld	a0,88(a0)
    80001d4c:	c509                	beqz	a0,80001d56 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	cc2080e7          	jalr	-830(ra) # 80000a10 <kfree>
    p->trapframe = 0;
    80001d56:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001d5a:	68a8                	ld	a0,80(s1)
    80001d5c:	c511                	beqz	a0,80001d68 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001d5e:	64ac                	ld	a1,72(s1)
    80001d60:	00000097          	auipc	ra,0x0
    80001d64:	f8c080e7          	jalr	-116(ra) # 80001cec <proc_freepagetable>
    p->pagetable = 0;
    80001d68:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001d6c:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001d70:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001d74:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001d78:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001d7c:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001d80:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001d84:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001d88:	0004ac23          	sw	zero,24(s1)
}
    80001d8c:	60e2                	ld	ra,24(sp)
    80001d8e:	6442                	ld	s0,16(sp)
    80001d90:	64a2                	ld	s1,8(sp)
    80001d92:	6105                	addi	sp,sp,32
    80001d94:	8082                	ret

0000000080001d96 <allocproc>:
{
    80001d96:	1101                	addi	sp,sp,-32
    80001d98:	ec06                	sd	ra,24(sp)
    80001d9a:	e822                	sd	s0,16(sp)
    80001d9c:	e426                	sd	s1,8(sp)
    80001d9e:	e04a                	sd	s2,0(sp)
    80001da0:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001da2:	0000f497          	auipc	s1,0xf
    80001da6:	35e48493          	addi	s1,s1,862 # 80011100 <proc>
    80001daa:	00015917          	auipc	s2,0x15
    80001dae:	d5690913          	addi	s2,s2,-682 # 80016b00 <tickslock>
        acquire(&p->lock);
    80001db2:	8526                	mv	a0,s1
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	efe080e7          	jalr	-258(ra) # 80000cb2 <acquire>
        if (p->state == UNUSED)
    80001dbc:	4c9c                	lw	a5,24(s1)
    80001dbe:	cf81                	beqz	a5,80001dd6 <allocproc+0x40>
            release(&p->lock);
    80001dc0:	8526                	mv	a0,s1
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	fa4080e7          	jalr	-92(ra) # 80000d66 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001dca:	16848493          	addi	s1,s1,360
    80001dce:	ff2492e3          	bne	s1,s2,80001db2 <allocproc+0x1c>
    return 0;
    80001dd2:	4481                	li	s1,0
    80001dd4:	a889                	j	80001e26 <allocproc+0x90>
    p->pid = allocpid();
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	e34080e7          	jalr	-460(ra) # 80001c0a <allocpid>
    80001dde:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001de0:	4785                	li	a5,1
    80001de2:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	d92080e7          	jalr	-622(ra) # 80000b76 <kalloc>
    80001dec:	892a                	mv	s2,a0
    80001dee:	eca8                	sd	a0,88(s1)
    80001df0:	c131                	beqz	a0,80001e34 <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001df2:	8526                	mv	a0,s1
    80001df4:	00000097          	auipc	ra,0x0
    80001df8:	e5c080e7          	jalr	-420(ra) # 80001c50 <proc_pagetable>
    80001dfc:	892a                	mv	s2,a0
    80001dfe:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001e00:	c531                	beqz	a0,80001e4c <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001e02:	07000613          	li	a2,112
    80001e06:	4581                	li	a1,0
    80001e08:	06048513          	addi	a0,s1,96
    80001e0c:	fffff097          	auipc	ra,0xfffff
    80001e10:	fa2080e7          	jalr	-94(ra) # 80000dae <memset>
    p->context.ra = (uint64)forkret;
    80001e14:	00000797          	auipc	a5,0x0
    80001e18:	db078793          	addi	a5,a5,-592 # 80001bc4 <forkret>
    80001e1c:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001e1e:	60bc                	ld	a5,64(s1)
    80001e20:	6705                	lui	a4,0x1
    80001e22:	97ba                	add	a5,a5,a4
    80001e24:	f4bc                	sd	a5,104(s1)
}
    80001e26:	8526                	mv	a0,s1
    80001e28:	60e2                	ld	ra,24(sp)
    80001e2a:	6442                	ld	s0,16(sp)
    80001e2c:	64a2                	ld	s1,8(sp)
    80001e2e:	6902                	ld	s2,0(sp)
    80001e30:	6105                	addi	sp,sp,32
    80001e32:	8082                	ret
        freeproc(p);
    80001e34:	8526                	mv	a0,s1
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	f08080e7          	jalr	-248(ra) # 80001d3e <freeproc>
        release(&p->lock);
    80001e3e:	8526                	mv	a0,s1
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	f26080e7          	jalr	-218(ra) # 80000d66 <release>
        return 0;
    80001e48:	84ca                	mv	s1,s2
    80001e4a:	bff1                	j	80001e26 <allocproc+0x90>
        freeproc(p);
    80001e4c:	8526                	mv	a0,s1
    80001e4e:	00000097          	auipc	ra,0x0
    80001e52:	ef0080e7          	jalr	-272(ra) # 80001d3e <freeproc>
        release(&p->lock);
    80001e56:	8526                	mv	a0,s1
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	f0e080e7          	jalr	-242(ra) # 80000d66 <release>
        return 0;
    80001e60:	84ca                	mv	s1,s2
    80001e62:	b7d1                	j	80001e26 <allocproc+0x90>

0000000080001e64 <userinit>:
{
    80001e64:	1101                	addi	sp,sp,-32
    80001e66:	ec06                	sd	ra,24(sp)
    80001e68:	e822                	sd	s0,16(sp)
    80001e6a:	e426                	sd	s1,8(sp)
    80001e6c:	1000                	addi	s0,sp,32
    p = allocproc();
    80001e6e:	00000097          	auipc	ra,0x0
    80001e72:	f28080e7          	jalr	-216(ra) # 80001d96 <allocproc>
    80001e76:	84aa                	mv	s1,a0
    initproc = p;
    80001e78:	00007797          	auipc	a5,0x7
    80001e7c:	bea7b023          	sd	a0,-1056(a5) # 80008a58 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e80:	03400613          	li	a2,52
    80001e84:	00007597          	auipc	a1,0x7
    80001e88:	b1c58593          	addi	a1,a1,-1252 # 800089a0 <initcode>
    80001e8c:	6928                	ld	a0,80(a0)
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	5ac080e7          	jalr	1452(ra) # 8000143a <uvmfirst>
    p->sz = PGSIZE;
    80001e96:	6785                	lui	a5,0x1
    80001e98:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001e9a:	6cb8                	ld	a4,88(s1)
    80001e9c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001ea0:	6cb8                	ld	a4,88(s1)
    80001ea2:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ea4:	4641                	li	a2,16
    80001ea6:	00006597          	auipc	a1,0x6
    80001eaa:	39a58593          	addi	a1,a1,922 # 80008240 <digits+0x1f0>
    80001eae:	15848513          	addi	a0,s1,344
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	04e080e7          	jalr	78(ra) # 80000f00 <safestrcpy>
    p->cwd = namei("/");
    80001eba:	00006517          	auipc	a0,0x6
    80001ebe:	39650513          	addi	a0,a0,918 # 80008250 <digits+0x200>
    80001ec2:	00002097          	auipc	ra,0x2
    80001ec6:	400080e7          	jalr	1024(ra) # 800042c2 <namei>
    80001eca:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001ece:	478d                	li	a5,3
    80001ed0:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001ed2:	8526                	mv	a0,s1
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	e92080e7          	jalr	-366(ra) # 80000d66 <release>
}
    80001edc:	60e2                	ld	ra,24(sp)
    80001ede:	6442                	ld	s0,16(sp)
    80001ee0:	64a2                	ld	s1,8(sp)
    80001ee2:	6105                	addi	sp,sp,32
    80001ee4:	8082                	ret

0000000080001ee6 <growproc>:
{
    80001ee6:	1101                	addi	sp,sp,-32
    80001ee8:	ec06                	sd	ra,24(sp)
    80001eea:	e822                	sd	s0,16(sp)
    80001eec:	e426                	sd	s1,8(sp)
    80001eee:	e04a                	sd	s2,0(sp)
    80001ef0:	1000                	addi	s0,sp,32
    80001ef2:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001ef4:	00000097          	auipc	ra,0x0
    80001ef8:	c98080e7          	jalr	-872(ra) # 80001b8c <myproc>
    80001efc:	84aa                	mv	s1,a0
    sz = p->sz;
    80001efe:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001f00:	01204c63          	bgtz	s2,80001f18 <growproc+0x32>
    else if (n < 0)
    80001f04:	02094663          	bltz	s2,80001f30 <growproc+0x4a>
    p->sz = sz;
    80001f08:	e4ac                	sd	a1,72(s1)
    return 0;
    80001f0a:	4501                	li	a0,0
}
    80001f0c:	60e2                	ld	ra,24(sp)
    80001f0e:	6442                	ld	s0,16(sp)
    80001f10:	64a2                	ld	s1,8(sp)
    80001f12:	6902                	ld	s2,0(sp)
    80001f14:	6105                	addi	sp,sp,32
    80001f16:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f18:	4691                	li	a3,4
    80001f1a:	00b90633          	add	a2,s2,a1
    80001f1e:	6928                	ld	a0,80(a0)
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	5d4080e7          	jalr	1492(ra) # 800014f4 <uvmalloc>
    80001f28:	85aa                	mv	a1,a0
    80001f2a:	fd79                	bnez	a0,80001f08 <growproc+0x22>
            return -1;
    80001f2c:	557d                	li	a0,-1
    80001f2e:	bff9                	j	80001f0c <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f30:	00b90633          	add	a2,s2,a1
    80001f34:	6928                	ld	a0,80(a0)
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	576080e7          	jalr	1398(ra) # 800014ac <uvmdealloc>
    80001f3e:	85aa                	mv	a1,a0
    80001f40:	b7e1                	j	80001f08 <growproc+0x22>

0000000080001f42 <ps>:
{
    80001f42:	715d                	addi	sp,sp,-80
    80001f44:	e486                	sd	ra,72(sp)
    80001f46:	e0a2                	sd	s0,64(sp)
    80001f48:	fc26                	sd	s1,56(sp)
    80001f4a:	f84a                	sd	s2,48(sp)
    80001f4c:	f44e                	sd	s3,40(sp)
    80001f4e:	f052                	sd	s4,32(sp)
    80001f50:	ec56                	sd	s5,24(sp)
    80001f52:	e85a                	sd	s6,16(sp)
    80001f54:	e45e                	sd	s7,8(sp)
    80001f56:	e062                	sd	s8,0(sp)
    80001f58:	0880                	addi	s0,sp,80
    80001f5a:	84aa                	mv	s1,a0
    80001f5c:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001f5e:	00000097          	auipc	ra,0x0
    80001f62:	c2e080e7          	jalr	-978(ra) # 80001b8c <myproc>
    if (count == 0)
    80001f66:	120b8063          	beqz	s7,80002086 <ps+0x144>
    void *result = (void *)myproc()->sz;
    80001f6a:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001f6e:	003b951b          	slliw	a0,s7,0x3
    80001f72:	0175053b          	addw	a0,a0,s7
    80001f76:	0025151b          	slliw	a0,a0,0x2
    80001f7a:	00000097          	auipc	ra,0x0
    80001f7e:	f6c080e7          	jalr	-148(ra) # 80001ee6 <growproc>
    80001f82:	10054463          	bltz	a0,8000208a <ps+0x148>
    struct user_proc loc_result[count];
    80001f86:	003b9a13          	slli	s4,s7,0x3
    80001f8a:	9a5e                	add	s4,s4,s7
    80001f8c:	0a0a                	slli	s4,s4,0x2
    80001f8e:	00fa0793          	addi	a5,s4,15
    80001f92:	8391                	srli	a5,a5,0x4
    80001f94:	0792                	slli	a5,a5,0x4
    80001f96:	40f10133          	sub	sp,sp,a5
    80001f9a:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    80001f9c:	007e9537          	lui	a0,0x7e9
    80001fa0:	02a484b3          	mul	s1,s1,a0
    80001fa4:	0000f797          	auipc	a5,0xf
    80001fa8:	15c78793          	addi	a5,a5,348 # 80011100 <proc>
    80001fac:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80001fae:	00015797          	auipc	a5,0x15
    80001fb2:	b5278793          	addi	a5,a5,-1198 # 80016b00 <tickslock>
    80001fb6:	0cf4fc63          	bgeu	s1,a5,8000208e <ps+0x14c>
    80001fba:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    80001fbe:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80001fc0:	8c3e                	mv	s8,a5
    80001fc2:	a051                	j	80002046 <ps+0x104>
            loc_result[localCount].state = UNUSED;
    80001fc4:	00399793          	slli	a5,s3,0x3
    80001fc8:	97ce                	add	a5,a5,s3
    80001fca:	078a                	slli	a5,a5,0x2
    80001fcc:	97d6                	add	a5,a5,s5
    80001fce:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	d92080e7          	jalr	-622(ra) # 80000d66 <release>
    if (localCount < count)
    80001fdc:	0179f963          	bgeu	s3,s7,80001fee <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80001fe0:	00399793          	slli	a5,s3,0x3
    80001fe4:	97ce                	add	a5,a5,s3
    80001fe6:	078a                	slli	a5,a5,0x2
    80001fe8:	97d6                	add	a5,a5,s5
    80001fea:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    80001fee:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    80001ff0:	00000097          	auipc	ra,0x0
    80001ff4:	b9c080e7          	jalr	-1124(ra) # 80001b8c <myproc>
    80001ff8:	86d2                	mv	a3,s4
    80001ffa:	8656                	mv	a2,s5
    80001ffc:	85da                	mv	a1,s6
    80001ffe:	6928                	ld	a0,80(a0)
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	74c080e7          	jalr	1868(ra) # 8000174c <copyout>
}
    80002008:	8526                	mv	a0,s1
    8000200a:	fb040113          	addi	sp,s0,-80
    8000200e:	60a6                	ld	ra,72(sp)
    80002010:	6406                	ld	s0,64(sp)
    80002012:	74e2                	ld	s1,56(sp)
    80002014:	7942                	ld	s2,48(sp)
    80002016:	79a2                	ld	s3,40(sp)
    80002018:	7a02                	ld	s4,32(sp)
    8000201a:	6ae2                	ld	s5,24(sp)
    8000201c:	6b42                	ld	s6,16(sp)
    8000201e:	6ba2                	ld	s7,8(sp)
    80002020:	6c02                	ld	s8,0(sp)
    80002022:	6161                	addi	sp,sp,80
    80002024:	8082                	ret
        release(&p->lock);
    80002026:	8526                	mv	a0,s1
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	d3e080e7          	jalr	-706(ra) # 80000d66 <release>
        localCount++;
    80002030:	2985                	addiw	s3,s3,1
    80002032:	0ff9f993          	andi	s3,s3,255
    for (; p < &proc[NPROC]; p++)
    80002036:	16848493          	addi	s1,s1,360
    8000203a:	fb84f1e3          	bgeu	s1,s8,80001fdc <ps+0x9a>
        if (localCount == count)
    8000203e:	02490913          	addi	s2,s2,36
    80002042:	fb3b86e3          	beq	s7,s3,80001fee <ps+0xac>
        acquire(&p->lock);
    80002046:	8526                	mv	a0,s1
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	c6a080e7          	jalr	-918(ra) # 80000cb2 <acquire>
        if (p->state == UNUSED)
    80002050:	4c9c                	lw	a5,24(s1)
    80002052:	dbad                	beqz	a5,80001fc4 <ps+0x82>
        loc_result[localCount].state = p->state;
    80002054:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    80002058:	549c                	lw	a5,40(s1)
    8000205a:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    8000205e:	54dc                	lw	a5,44(s1)
    80002060:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80002064:	589c                	lw	a5,48(s1)
    80002066:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    8000206a:	4641                	li	a2,16
    8000206c:	85ca                	mv	a1,s2
    8000206e:	15848513          	addi	a0,s1,344
    80002072:	00000097          	auipc	ra,0x0
    80002076:	ac0080e7          	jalr	-1344(ra) # 80001b32 <copy_array>
        if (p->parent != 0) // init
    8000207a:	7c9c                	ld	a5,56(s1)
    8000207c:	d7cd                	beqz	a5,80002026 <ps+0xe4>
            loc_result[localCount].parent_id = p->parent->pid;
    8000207e:	5b9c                	lw	a5,48(a5)
    80002080:	fef92e23          	sw	a5,-4(s2)
    80002084:	b74d                	j	80002026 <ps+0xe4>
        return result;
    80002086:	4481                	li	s1,0
    80002088:	b741                	j	80002008 <ps+0xc6>
        return result;
    8000208a:	4481                	li	s1,0
    8000208c:	bfb5                	j	80002008 <ps+0xc6>
        return result;
    8000208e:	4481                	li	s1,0
    80002090:	bfa5                	j	80002008 <ps+0xc6>

0000000080002092 <fork>:
{
    80002092:	7179                	addi	sp,sp,-48
    80002094:	f406                	sd	ra,40(sp)
    80002096:	f022                	sd	s0,32(sp)
    80002098:	ec26                	sd	s1,24(sp)
    8000209a:	e84a                	sd	s2,16(sp)
    8000209c:	e44e                	sd	s3,8(sp)
    8000209e:	e052                	sd	s4,0(sp)
    800020a0:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800020a2:	00000097          	auipc	ra,0x0
    800020a6:	aea080e7          	jalr	-1302(ra) # 80001b8c <myproc>
    800020aa:	892a                	mv	s2,a0
    if ((np = allocproc()) == 0)
    800020ac:	00000097          	auipc	ra,0x0
    800020b0:	cea080e7          	jalr	-790(ra) # 80001d96 <allocproc>
    800020b4:	10050b63          	beqz	a0,800021ca <fork+0x138>
    800020b8:	89aa                	mv	s3,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800020ba:	04893603          	ld	a2,72(s2)
    800020be:	692c                	ld	a1,80(a0)
    800020c0:	05093503          	ld	a0,80(s2)
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	584080e7          	jalr	1412(ra) # 80001648 <uvmcopy>
    800020cc:	04054663          	bltz	a0,80002118 <fork+0x86>
    np->sz = p->sz;
    800020d0:	04893783          	ld	a5,72(s2)
    800020d4:	04f9b423          	sd	a5,72(s3)
    *(np->trapframe) = *(p->trapframe);
    800020d8:	05893683          	ld	a3,88(s2)
    800020dc:	87b6                	mv	a5,a3
    800020de:	0589b703          	ld	a4,88(s3)
    800020e2:	12068693          	addi	a3,a3,288
    800020e6:	0007b803          	ld	a6,0(a5)
    800020ea:	6788                	ld	a0,8(a5)
    800020ec:	6b8c                	ld	a1,16(a5)
    800020ee:	6f90                	ld	a2,24(a5)
    800020f0:	01073023          	sd	a6,0(a4)
    800020f4:	e708                	sd	a0,8(a4)
    800020f6:	eb0c                	sd	a1,16(a4)
    800020f8:	ef10                	sd	a2,24(a4)
    800020fa:	02078793          	addi	a5,a5,32
    800020fe:	02070713          	addi	a4,a4,32
    80002102:	fed792e3          	bne	a5,a3,800020e6 <fork+0x54>
    np->trapframe->a0 = 0;
    80002106:	0589b783          	ld	a5,88(s3)
    8000210a:	0607b823          	sd	zero,112(a5)
    8000210e:	0d000493          	li	s1,208
    for (i = 0; i < NOFILE; i++)
    80002112:	15000a13          	li	s4,336
    80002116:	a03d                	j	80002144 <fork+0xb2>
        freeproc(np);
    80002118:	854e                	mv	a0,s3
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	c24080e7          	jalr	-988(ra) # 80001d3e <freeproc>
        release(&np->lock);
    80002122:	854e                	mv	a0,s3
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	c42080e7          	jalr	-958(ra) # 80000d66 <release>
        return -1;
    8000212c:	5a7d                	li	s4,-1
    8000212e:	a069                	j	800021b8 <fork+0x126>
            np->ofile[i] = filedup(p->ofile[i]);
    80002130:	00003097          	auipc	ra,0x3
    80002134:	828080e7          	jalr	-2008(ra) # 80004958 <filedup>
    80002138:	009987b3          	add	a5,s3,s1
    8000213c:	e388                	sd	a0,0(a5)
    for (i = 0; i < NOFILE; i++)
    8000213e:	04a1                	addi	s1,s1,8
    80002140:	01448763          	beq	s1,s4,8000214e <fork+0xbc>
        if (p->ofile[i])
    80002144:	009907b3          	add	a5,s2,s1
    80002148:	6388                	ld	a0,0(a5)
    8000214a:	f17d                	bnez	a0,80002130 <fork+0x9e>
    8000214c:	bfcd                	j	8000213e <fork+0xac>
    np->cwd = idup(p->cwd);
    8000214e:	15093503          	ld	a0,336(s2)
    80002152:	00002097          	auipc	ra,0x2
    80002156:	98c080e7          	jalr	-1652(ra) # 80003ade <idup>
    8000215a:	14a9b823          	sd	a0,336(s3)
    safestrcpy(np->name, p->name, sizeof(p->name));
    8000215e:	4641                	li	a2,16
    80002160:	15890593          	addi	a1,s2,344
    80002164:	15898513          	addi	a0,s3,344
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	d98080e7          	jalr	-616(ra) # 80000f00 <safestrcpy>
    pid = np->pid;
    80002170:	0309aa03          	lw	s4,48(s3)
    release(&np->lock);
    80002174:	854e                	mv	a0,s3
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	bf0080e7          	jalr	-1040(ra) # 80000d66 <release>
    acquire(&wait_lock);
    8000217e:	0000f497          	auipc	s1,0xf
    80002182:	f6a48493          	addi	s1,s1,-150 # 800110e8 <wait_lock>
    80002186:	8526                	mv	a0,s1
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	b2a080e7          	jalr	-1238(ra) # 80000cb2 <acquire>
    np->parent = p;
    80002190:	0329bc23          	sd	s2,56(s3)
    release(&wait_lock);
    80002194:	8526                	mv	a0,s1
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	bd0080e7          	jalr	-1072(ra) # 80000d66 <release>
    acquire(&np->lock);
    8000219e:	854e                	mv	a0,s3
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	b12080e7          	jalr	-1262(ra) # 80000cb2 <acquire>
    np->state = RUNNABLE;
    800021a8:	478d                	li	a5,3
    800021aa:	00f9ac23          	sw	a5,24(s3)
    release(&np->lock);
    800021ae:	854e                	mv	a0,s3
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	bb6080e7          	jalr	-1098(ra) # 80000d66 <release>
}
    800021b8:	8552                	mv	a0,s4
    800021ba:	70a2                	ld	ra,40(sp)
    800021bc:	7402                	ld	s0,32(sp)
    800021be:	64e2                	ld	s1,24(sp)
    800021c0:	6942                	ld	s2,16(sp)
    800021c2:	69a2                	ld	s3,8(sp)
    800021c4:	6a02                	ld	s4,0(sp)
    800021c6:	6145                	addi	sp,sp,48
    800021c8:	8082                	ret
        return -1;
    800021ca:	5a7d                	li	s4,-1
    800021cc:	b7f5                	j	800021b8 <fork+0x126>

00000000800021ce <scheduler>:
{
    800021ce:	1101                	addi	sp,sp,-32
    800021d0:	ec06                	sd	ra,24(sp)
    800021d2:	e822                	sd	s0,16(sp)
    800021d4:	e426                	sd	s1,8(sp)
    800021d6:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800021d8:	00006497          	auipc	s1,0x6
    800021dc:	7b048493          	addi	s1,s1,1968 # 80008988 <sched_pointer>
    800021e0:	609c                	ld	a5,0(s1)
    800021e2:	9782                	jalr	a5
    while (1)
    800021e4:	bff5                	j	800021e0 <scheduler+0x12>

00000000800021e6 <sched>:
{
    800021e6:	7179                	addi	sp,sp,-48
    800021e8:	f406                	sd	ra,40(sp)
    800021ea:	f022                	sd	s0,32(sp)
    800021ec:	ec26                	sd	s1,24(sp)
    800021ee:	e84a                	sd	s2,16(sp)
    800021f0:	e44e                	sd	s3,8(sp)
    800021f2:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	998080e7          	jalr	-1640(ra) # 80001b8c <myproc>
    800021fc:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	a3a080e7          	jalr	-1478(ra) # 80000c38 <holding>
    80002206:	c53d                	beqz	a0,80002274 <sched+0x8e>
    80002208:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    8000220a:	2781                	sext.w	a5,a5
    8000220c:	079e                	slli	a5,a5,0x7
    8000220e:	0000f717          	auipc	a4,0xf
    80002212:	ac270713          	addi	a4,a4,-1342 # 80010cd0 <cpus>
    80002216:	97ba                	add	a5,a5,a4
    80002218:	5fb8                	lw	a4,120(a5)
    8000221a:	4785                	li	a5,1
    8000221c:	06f71463          	bne	a4,a5,80002284 <sched+0x9e>
    if (p->state == RUNNING)
    80002220:	4c98                	lw	a4,24(s1)
    80002222:	4791                	li	a5,4
    80002224:	06f70863          	beq	a4,a5,80002294 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002228:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000222c:	8b89                	andi	a5,a5,2
    if (intr_get())
    8000222e:	ebbd                	bnez	a5,800022a4 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002230:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002232:	0000f917          	auipc	s2,0xf
    80002236:	a9e90913          	addi	s2,s2,-1378 # 80010cd0 <cpus>
    8000223a:	2781                	sext.w	a5,a5
    8000223c:	079e                	slli	a5,a5,0x7
    8000223e:	97ca                	add	a5,a5,s2
    80002240:	07c7a983          	lw	s3,124(a5)
    80002244:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    80002246:	2581                	sext.w	a1,a1
    80002248:	059e                	slli	a1,a1,0x7
    8000224a:	05a1                	addi	a1,a1,8
    8000224c:	95ca                	add	a1,a1,s2
    8000224e:	06048513          	addi	a0,s1,96
    80002252:	00000097          	auipc	ra,0x0
    80002256:	73c080e7          	jalr	1852(ra) # 8000298e <swtch>
    8000225a:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    8000225c:	2781                	sext.w	a5,a5
    8000225e:	079e                	slli	a5,a5,0x7
    80002260:	993e                	add	s2,s2,a5
    80002262:	07392e23          	sw	s3,124(s2)
}
    80002266:	70a2                	ld	ra,40(sp)
    80002268:	7402                	ld	s0,32(sp)
    8000226a:	64e2                	ld	s1,24(sp)
    8000226c:	6942                	ld	s2,16(sp)
    8000226e:	69a2                	ld	s3,8(sp)
    80002270:	6145                	addi	sp,sp,48
    80002272:	8082                	ret
        panic("sched p->lock");
    80002274:	00006517          	auipc	a0,0x6
    80002278:	fe450513          	addi	a0,a0,-28 # 80008258 <digits+0x208>
    8000227c:	ffffe097          	auipc	ra,0xffffe
    80002280:	2c8080e7          	jalr	712(ra) # 80000544 <panic>
        panic("sched locks");
    80002284:	00006517          	auipc	a0,0x6
    80002288:	fe450513          	addi	a0,a0,-28 # 80008268 <digits+0x218>
    8000228c:	ffffe097          	auipc	ra,0xffffe
    80002290:	2b8080e7          	jalr	696(ra) # 80000544 <panic>
        panic("sched running");
    80002294:	00006517          	auipc	a0,0x6
    80002298:	fe450513          	addi	a0,a0,-28 # 80008278 <digits+0x228>
    8000229c:	ffffe097          	auipc	ra,0xffffe
    800022a0:	2a8080e7          	jalr	680(ra) # 80000544 <panic>
        panic("sched interruptible");
    800022a4:	00006517          	auipc	a0,0x6
    800022a8:	fe450513          	addi	a0,a0,-28 # 80008288 <digits+0x238>
    800022ac:	ffffe097          	auipc	ra,0xffffe
    800022b0:	298080e7          	jalr	664(ra) # 80000544 <panic>

00000000800022b4 <yield>:
{
    800022b4:	1101                	addi	sp,sp,-32
    800022b6:	ec06                	sd	ra,24(sp)
    800022b8:	e822                	sd	s0,16(sp)
    800022ba:	e426                	sd	s1,8(sp)
    800022bc:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	8ce080e7          	jalr	-1842(ra) # 80001b8c <myproc>
    800022c6:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	9ea080e7          	jalr	-1558(ra) # 80000cb2 <acquire>
    p->state = RUNNABLE;
    800022d0:	478d                	li	a5,3
    800022d2:	cc9c                	sw	a5,24(s1)
    sched();
    800022d4:	00000097          	auipc	ra,0x0
    800022d8:	f12080e7          	jalr	-238(ra) # 800021e6 <sched>
    release(&p->lock);
    800022dc:	8526                	mv	a0,s1
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	a88080e7          	jalr	-1400(ra) # 80000d66 <release>
}
    800022e6:	60e2                	ld	ra,24(sp)
    800022e8:	6442                	ld	s0,16(sp)
    800022ea:	64a2                	ld	s1,8(sp)
    800022ec:	6105                	addi	sp,sp,32
    800022ee:	8082                	ret

00000000800022f0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800022f0:	7179                	addi	sp,sp,-48
    800022f2:	f406                	sd	ra,40(sp)
    800022f4:	f022                	sd	s0,32(sp)
    800022f6:	ec26                	sd	s1,24(sp)
    800022f8:	e84a                	sd	s2,16(sp)
    800022fa:	e44e                	sd	s3,8(sp)
    800022fc:	1800                	addi	s0,sp,48
    800022fe:	89aa                	mv	s3,a0
    80002300:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002302:	00000097          	auipc	ra,0x0
    80002306:	88a080e7          	jalr	-1910(ra) # 80001b8c <myproc>
    8000230a:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	9a6080e7          	jalr	-1626(ra) # 80000cb2 <acquire>
    release(lk);
    80002314:	854a                	mv	a0,s2
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	a50080e7          	jalr	-1456(ra) # 80000d66 <release>

    // Go to sleep.
    p->chan = chan;
    8000231e:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002322:	4789                	li	a5,2
    80002324:	cc9c                	sw	a5,24(s1)

    sched();
    80002326:	00000097          	auipc	ra,0x0
    8000232a:	ec0080e7          	jalr	-320(ra) # 800021e6 <sched>

    // Tidy up.
    p->chan = 0;
    8000232e:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	a32080e7          	jalr	-1486(ra) # 80000d66 <release>
    acquire(lk);
    8000233c:	854a                	mv	a0,s2
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	974080e7          	jalr	-1676(ra) # 80000cb2 <acquire>
}
    80002346:	70a2                	ld	ra,40(sp)
    80002348:	7402                	ld	s0,32(sp)
    8000234a:	64e2                	ld	s1,24(sp)
    8000234c:	6942                	ld	s2,16(sp)
    8000234e:	69a2                	ld	s3,8(sp)
    80002350:	6145                	addi	sp,sp,48
    80002352:	8082                	ret

0000000080002354 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002354:	7139                	addi	sp,sp,-64
    80002356:	fc06                	sd	ra,56(sp)
    80002358:	f822                	sd	s0,48(sp)
    8000235a:	f426                	sd	s1,40(sp)
    8000235c:	f04a                	sd	s2,32(sp)
    8000235e:	ec4e                	sd	s3,24(sp)
    80002360:	e852                	sd	s4,16(sp)
    80002362:	e456                	sd	s5,8(sp)
    80002364:	0080                	addi	s0,sp,64
    80002366:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002368:	0000f497          	auipc	s1,0xf
    8000236c:	d9848493          	addi	s1,s1,-616 # 80011100 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    80002370:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    80002372:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002374:	00014917          	auipc	s2,0x14
    80002378:	78c90913          	addi	s2,s2,1932 # 80016b00 <tickslock>
    8000237c:	a821                	j	80002394 <wakeup+0x40>
                p->state = RUNNABLE;
    8000237e:	0154ac23          	sw	s5,24(s1)
            }
            release(&p->lock);
    80002382:	8526                	mv	a0,s1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	9e2080e7          	jalr	-1566(ra) # 80000d66 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000238c:	16848493          	addi	s1,s1,360
    80002390:	03248463          	beq	s1,s2,800023b8 <wakeup+0x64>
        if (p != myproc())
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	7f8080e7          	jalr	2040(ra) # 80001b8c <myproc>
    8000239c:	fea488e3          	beq	s1,a0,8000238c <wakeup+0x38>
            acquire(&p->lock);
    800023a0:	8526                	mv	a0,s1
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	910080e7          	jalr	-1776(ra) # 80000cb2 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    800023aa:	4c9c                	lw	a5,24(s1)
    800023ac:	fd379be3          	bne	a5,s3,80002382 <wakeup+0x2e>
    800023b0:	709c                	ld	a5,32(s1)
    800023b2:	fd4798e3          	bne	a5,s4,80002382 <wakeup+0x2e>
    800023b6:	b7e1                	j	8000237e <wakeup+0x2a>
        }
    }
}
    800023b8:	70e2                	ld	ra,56(sp)
    800023ba:	7442                	ld	s0,48(sp)
    800023bc:	74a2                	ld	s1,40(sp)
    800023be:	7902                	ld	s2,32(sp)
    800023c0:	69e2                	ld	s3,24(sp)
    800023c2:	6a42                	ld	s4,16(sp)
    800023c4:	6aa2                	ld	s5,8(sp)
    800023c6:	6121                	addi	sp,sp,64
    800023c8:	8082                	ret

00000000800023ca <reparent>:
{
    800023ca:	7179                	addi	sp,sp,-48
    800023cc:	f406                	sd	ra,40(sp)
    800023ce:	f022                	sd	s0,32(sp)
    800023d0:	ec26                	sd	s1,24(sp)
    800023d2:	e84a                	sd	s2,16(sp)
    800023d4:	e44e                	sd	s3,8(sp)
    800023d6:	e052                	sd	s4,0(sp)
    800023d8:	1800                	addi	s0,sp,48
    800023da:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023dc:	0000f497          	auipc	s1,0xf
    800023e0:	d2448493          	addi	s1,s1,-732 # 80011100 <proc>
            pp->parent = initproc;
    800023e4:	00006a17          	auipc	s4,0x6
    800023e8:	674a0a13          	addi	s4,s4,1652 # 80008a58 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023ec:	00014997          	auipc	s3,0x14
    800023f0:	71498993          	addi	s3,s3,1812 # 80016b00 <tickslock>
    800023f4:	a029                	j	800023fe <reparent+0x34>
    800023f6:	16848493          	addi	s1,s1,360
    800023fa:	01348d63          	beq	s1,s3,80002414 <reparent+0x4a>
        if (pp->parent == p)
    800023fe:	7c9c                	ld	a5,56(s1)
    80002400:	ff279be3          	bne	a5,s2,800023f6 <reparent+0x2c>
            pp->parent = initproc;
    80002404:	000a3503          	ld	a0,0(s4)
    80002408:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    8000240a:	00000097          	auipc	ra,0x0
    8000240e:	f4a080e7          	jalr	-182(ra) # 80002354 <wakeup>
    80002412:	b7d5                	j	800023f6 <reparent+0x2c>
}
    80002414:	70a2                	ld	ra,40(sp)
    80002416:	7402                	ld	s0,32(sp)
    80002418:	64e2                	ld	s1,24(sp)
    8000241a:	6942                	ld	s2,16(sp)
    8000241c:	69a2                	ld	s3,8(sp)
    8000241e:	6a02                	ld	s4,0(sp)
    80002420:	6145                	addi	sp,sp,48
    80002422:	8082                	ret

0000000080002424 <exit>:
{
    80002424:	7179                	addi	sp,sp,-48
    80002426:	f406                	sd	ra,40(sp)
    80002428:	f022                	sd	s0,32(sp)
    8000242a:	ec26                	sd	s1,24(sp)
    8000242c:	e84a                	sd	s2,16(sp)
    8000242e:	e44e                	sd	s3,8(sp)
    80002430:	e052                	sd	s4,0(sp)
    80002432:	1800                	addi	s0,sp,48
    80002434:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	756080e7          	jalr	1878(ra) # 80001b8c <myproc>
    8000243e:	89aa                	mv	s3,a0
    if (p == initproc)
    80002440:	00006797          	auipc	a5,0x6
    80002444:	6187b783          	ld	a5,1560(a5) # 80008a58 <initproc>
    80002448:	0d050493          	addi	s1,a0,208
    8000244c:	15050913          	addi	s2,a0,336
    80002450:	02a79363          	bne	a5,a0,80002476 <exit+0x52>
        panic("init exiting");
    80002454:	00006517          	auipc	a0,0x6
    80002458:	e4c50513          	addi	a0,a0,-436 # 800082a0 <digits+0x250>
    8000245c:	ffffe097          	auipc	ra,0xffffe
    80002460:	0e8080e7          	jalr	232(ra) # 80000544 <panic>
            fileclose(f);
    80002464:	00002097          	auipc	ra,0x2
    80002468:	546080e7          	jalr	1350(ra) # 800049aa <fileclose>
            p->ofile[fd] = 0;
    8000246c:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    80002470:	04a1                	addi	s1,s1,8
    80002472:	01248563          	beq	s1,s2,8000247c <exit+0x58>
        if (p->ofile[fd])
    80002476:	6088                	ld	a0,0(s1)
    80002478:	f575                	bnez	a0,80002464 <exit+0x40>
    8000247a:	bfdd                	j	80002470 <exit+0x4c>
    begin_op();
    8000247c:	00002097          	auipc	ra,0x2
    80002480:	062080e7          	jalr	98(ra) # 800044de <begin_op>
    iput(p->cwd);
    80002484:	1509b503          	ld	a0,336(s3)
    80002488:	00002097          	auipc	ra,0x2
    8000248c:	84e080e7          	jalr	-1970(ra) # 80003cd6 <iput>
    end_op();
    80002490:	00002097          	auipc	ra,0x2
    80002494:	0ce080e7          	jalr	206(ra) # 8000455e <end_op>
    p->cwd = 0;
    80002498:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    8000249c:	0000f497          	auipc	s1,0xf
    800024a0:	c4c48493          	addi	s1,s1,-948 # 800110e8 <wait_lock>
    800024a4:	8526                	mv	a0,s1
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	80c080e7          	jalr	-2036(ra) # 80000cb2 <acquire>
    reparent(p);
    800024ae:	854e                	mv	a0,s3
    800024b0:	00000097          	auipc	ra,0x0
    800024b4:	f1a080e7          	jalr	-230(ra) # 800023ca <reparent>
    wakeup(p->parent);
    800024b8:	0389b503          	ld	a0,56(s3)
    800024bc:	00000097          	auipc	ra,0x0
    800024c0:	e98080e7          	jalr	-360(ra) # 80002354 <wakeup>
    acquire(&p->lock);
    800024c4:	854e                	mv	a0,s3
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	7ec080e7          	jalr	2028(ra) # 80000cb2 <acquire>
    p->xstate = status;
    800024ce:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800024d2:	4795                	li	a5,5
    800024d4:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800024d8:	8526                	mv	a0,s1
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	88c080e7          	jalr	-1908(ra) # 80000d66 <release>
    sched();
    800024e2:	00000097          	auipc	ra,0x0
    800024e6:	d04080e7          	jalr	-764(ra) # 800021e6 <sched>
    panic("zombie exit");
    800024ea:	00006517          	auipc	a0,0x6
    800024ee:	dc650513          	addi	a0,a0,-570 # 800082b0 <digits+0x260>
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	052080e7          	jalr	82(ra) # 80000544 <panic>

00000000800024fa <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800024fa:	7179                	addi	sp,sp,-48
    800024fc:	f406                	sd	ra,40(sp)
    800024fe:	f022                	sd	s0,32(sp)
    80002500:	ec26                	sd	s1,24(sp)
    80002502:	e84a                	sd	s2,16(sp)
    80002504:	e44e                	sd	s3,8(sp)
    80002506:	1800                	addi	s0,sp,48
    80002508:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000250a:	0000f497          	auipc	s1,0xf
    8000250e:	bf648493          	addi	s1,s1,-1034 # 80011100 <proc>
    80002512:	00014997          	auipc	s3,0x14
    80002516:	5ee98993          	addi	s3,s3,1518 # 80016b00 <tickslock>
    {
        acquire(&p->lock);
    8000251a:	8526                	mv	a0,s1
    8000251c:	ffffe097          	auipc	ra,0xffffe
    80002520:	796080e7          	jalr	1942(ra) # 80000cb2 <acquire>
        if (p->pid == pid)
    80002524:	589c                	lw	a5,48(s1)
    80002526:	01278d63          	beq	a5,s2,80002540 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    8000252a:	8526                	mv	a0,s1
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	83a080e7          	jalr	-1990(ra) # 80000d66 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002534:	16848493          	addi	s1,s1,360
    80002538:	ff3491e3          	bne	s1,s3,8000251a <kill+0x20>
    }
    return -1;
    8000253c:	557d                	li	a0,-1
    8000253e:	a829                	j	80002558 <kill+0x5e>
            p->killed = 1;
    80002540:	4785                	li	a5,1
    80002542:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002544:	4c98                	lw	a4,24(s1)
    80002546:	4789                	li	a5,2
    80002548:	00f70f63          	beq	a4,a5,80002566 <kill+0x6c>
            release(&p->lock);
    8000254c:	8526                	mv	a0,s1
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	818080e7          	jalr	-2024(ra) # 80000d66 <release>
            return 0;
    80002556:	4501                	li	a0,0
}
    80002558:	70a2                	ld	ra,40(sp)
    8000255a:	7402                	ld	s0,32(sp)
    8000255c:	64e2                	ld	s1,24(sp)
    8000255e:	6942                	ld	s2,16(sp)
    80002560:	69a2                	ld	s3,8(sp)
    80002562:	6145                	addi	sp,sp,48
    80002564:	8082                	ret
                p->state = RUNNABLE;
    80002566:	478d                	li	a5,3
    80002568:	cc9c                	sw	a5,24(s1)
    8000256a:	b7cd                	j	8000254c <kill+0x52>

000000008000256c <setkilled>:

void setkilled(struct proc *p)
{
    8000256c:	1101                	addi	sp,sp,-32
    8000256e:	ec06                	sd	ra,24(sp)
    80002570:	e822                	sd	s0,16(sp)
    80002572:	e426                	sd	s1,8(sp)
    80002574:	1000                	addi	s0,sp,32
    80002576:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	73a080e7          	jalr	1850(ra) # 80000cb2 <acquire>
    p->killed = 1;
    80002580:	4785                	li	a5,1
    80002582:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    80002584:	8526                	mv	a0,s1
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	7e0080e7          	jalr	2016(ra) # 80000d66 <release>
}
    8000258e:	60e2                	ld	ra,24(sp)
    80002590:	6442                	ld	s0,16(sp)
    80002592:	64a2                	ld	s1,8(sp)
    80002594:	6105                	addi	sp,sp,32
    80002596:	8082                	ret

0000000080002598 <killed>:

int killed(struct proc *p)
{
    80002598:	1101                	addi	sp,sp,-32
    8000259a:	ec06                	sd	ra,24(sp)
    8000259c:	e822                	sd	s0,16(sp)
    8000259e:	e426                	sd	s1,8(sp)
    800025a0:	e04a                	sd	s2,0(sp)
    800025a2:	1000                	addi	s0,sp,32
    800025a4:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	70c080e7          	jalr	1804(ra) # 80000cb2 <acquire>
    k = p->killed;
    800025ae:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    800025b2:	8526                	mv	a0,s1
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	7b2080e7          	jalr	1970(ra) # 80000d66 <release>
    return k;
}
    800025bc:	854a                	mv	a0,s2
    800025be:	60e2                	ld	ra,24(sp)
    800025c0:	6442                	ld	s0,16(sp)
    800025c2:	64a2                	ld	s1,8(sp)
    800025c4:	6902                	ld	s2,0(sp)
    800025c6:	6105                	addi	sp,sp,32
    800025c8:	8082                	ret

00000000800025ca <wait>:
{
    800025ca:	715d                	addi	sp,sp,-80
    800025cc:	e486                	sd	ra,72(sp)
    800025ce:	e0a2                	sd	s0,64(sp)
    800025d0:	fc26                	sd	s1,56(sp)
    800025d2:	f84a                	sd	s2,48(sp)
    800025d4:	f44e                	sd	s3,40(sp)
    800025d6:	f052                	sd	s4,32(sp)
    800025d8:	ec56                	sd	s5,24(sp)
    800025da:	e85a                	sd	s6,16(sp)
    800025dc:	e45e                	sd	s7,8(sp)
    800025de:	e062                	sd	s8,0(sp)
    800025e0:	0880                	addi	s0,sp,80
    800025e2:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800025e4:	fffff097          	auipc	ra,0xfffff
    800025e8:	5a8080e7          	jalr	1448(ra) # 80001b8c <myproc>
    800025ec:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800025ee:	0000f517          	auipc	a0,0xf
    800025f2:	afa50513          	addi	a0,a0,-1286 # 800110e8 <wait_lock>
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	6bc080e7          	jalr	1724(ra) # 80000cb2 <acquire>
        havekids = 0;
    800025fe:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    80002600:	4a15                	li	s4,5
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002602:	00014997          	auipc	s3,0x14
    80002606:	4fe98993          	addi	s3,s3,1278 # 80016b00 <tickslock>
                havekids = 1;
    8000260a:	4a85                	li	s5,1
        sleep(p, &wait_lock); // DOC: wait-sleep
    8000260c:	0000fc17          	auipc	s8,0xf
    80002610:	adcc0c13          	addi	s8,s8,-1316 # 800110e8 <wait_lock>
        havekids = 0;
    80002614:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002616:	0000f497          	auipc	s1,0xf
    8000261a:	aea48493          	addi	s1,s1,-1302 # 80011100 <proc>
    8000261e:	a0bd                	j	8000268c <wait+0xc2>
                    pid = pp->pid;
    80002620:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002624:	000b0e63          	beqz	s6,80002640 <wait+0x76>
    80002628:	4691                	li	a3,4
    8000262a:	02c48613          	addi	a2,s1,44
    8000262e:	85da                	mv	a1,s6
    80002630:	05093503          	ld	a0,80(s2)
    80002634:	fffff097          	auipc	ra,0xfffff
    80002638:	118080e7          	jalr	280(ra) # 8000174c <copyout>
    8000263c:	02054563          	bltz	a0,80002666 <wait+0x9c>
                    freeproc(pp);
    80002640:	8526                	mv	a0,s1
    80002642:	fffff097          	auipc	ra,0xfffff
    80002646:	6fc080e7          	jalr	1788(ra) # 80001d3e <freeproc>
                    release(&pp->lock);
    8000264a:	8526                	mv	a0,s1
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	71a080e7          	jalr	1818(ra) # 80000d66 <release>
                    release(&wait_lock);
    80002654:	0000f517          	auipc	a0,0xf
    80002658:	a9450513          	addi	a0,a0,-1388 # 800110e8 <wait_lock>
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	70a080e7          	jalr	1802(ra) # 80000d66 <release>
                    return pid;
    80002664:	a0b5                	j	800026d0 <wait+0x106>
                        release(&pp->lock);
    80002666:	8526                	mv	a0,s1
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	6fe080e7          	jalr	1790(ra) # 80000d66 <release>
                        release(&wait_lock);
    80002670:	0000f517          	auipc	a0,0xf
    80002674:	a7850513          	addi	a0,a0,-1416 # 800110e8 <wait_lock>
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	6ee080e7          	jalr	1774(ra) # 80000d66 <release>
                        return -1;
    80002680:	59fd                	li	s3,-1
    80002682:	a0b9                	j	800026d0 <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002684:	16848493          	addi	s1,s1,360
    80002688:	03348463          	beq	s1,s3,800026b0 <wait+0xe6>
            if (pp->parent == p)
    8000268c:	7c9c                	ld	a5,56(s1)
    8000268e:	ff279be3          	bne	a5,s2,80002684 <wait+0xba>
                acquire(&pp->lock);
    80002692:	8526                	mv	a0,s1
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	61e080e7          	jalr	1566(ra) # 80000cb2 <acquire>
                if (pp->state == ZOMBIE)
    8000269c:	4c9c                	lw	a5,24(s1)
    8000269e:	f94781e3          	beq	a5,s4,80002620 <wait+0x56>
                release(&pp->lock);
    800026a2:	8526                	mv	a0,s1
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	6c2080e7          	jalr	1730(ra) # 80000d66 <release>
                havekids = 1;
    800026ac:	8756                	mv	a4,s5
    800026ae:	bfd9                	j	80002684 <wait+0xba>
        if (!havekids || killed(p))
    800026b0:	c719                	beqz	a4,800026be <wait+0xf4>
    800026b2:	854a                	mv	a0,s2
    800026b4:	00000097          	auipc	ra,0x0
    800026b8:	ee4080e7          	jalr	-284(ra) # 80002598 <killed>
    800026bc:	c51d                	beqz	a0,800026ea <wait+0x120>
            release(&wait_lock);
    800026be:	0000f517          	auipc	a0,0xf
    800026c2:	a2a50513          	addi	a0,a0,-1494 # 800110e8 <wait_lock>
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	6a0080e7          	jalr	1696(ra) # 80000d66 <release>
            return -1;
    800026ce:	59fd                	li	s3,-1
}
    800026d0:	854e                	mv	a0,s3
    800026d2:	60a6                	ld	ra,72(sp)
    800026d4:	6406                	ld	s0,64(sp)
    800026d6:	74e2                	ld	s1,56(sp)
    800026d8:	7942                	ld	s2,48(sp)
    800026da:	79a2                	ld	s3,40(sp)
    800026dc:	7a02                	ld	s4,32(sp)
    800026de:	6ae2                	ld	s5,24(sp)
    800026e0:	6b42                	ld	s6,16(sp)
    800026e2:	6ba2                	ld	s7,8(sp)
    800026e4:	6c02                	ld	s8,0(sp)
    800026e6:	6161                	addi	sp,sp,80
    800026e8:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    800026ea:	85e2                	mv	a1,s8
    800026ec:	854a                	mv	a0,s2
    800026ee:	00000097          	auipc	ra,0x0
    800026f2:	c02080e7          	jalr	-1022(ra) # 800022f0 <sleep>
        havekids = 0;
    800026f6:	bf39                	j	80002614 <wait+0x4a>

00000000800026f8 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026f8:	7179                	addi	sp,sp,-48
    800026fa:	f406                	sd	ra,40(sp)
    800026fc:	f022                	sd	s0,32(sp)
    800026fe:	ec26                	sd	s1,24(sp)
    80002700:	e84a                	sd	s2,16(sp)
    80002702:	e44e                	sd	s3,8(sp)
    80002704:	e052                	sd	s4,0(sp)
    80002706:	1800                	addi	s0,sp,48
    80002708:	84aa                	mv	s1,a0
    8000270a:	892e                	mv	s2,a1
    8000270c:	89b2                	mv	s3,a2
    8000270e:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	47c080e7          	jalr	1148(ra) # 80001b8c <myproc>
    if (user_dst)
    80002718:	c08d                	beqz	s1,8000273a <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    8000271a:	86d2                	mv	a3,s4
    8000271c:	864e                	mv	a2,s3
    8000271e:	85ca                	mv	a1,s2
    80002720:	6928                	ld	a0,80(a0)
    80002722:	fffff097          	auipc	ra,0xfffff
    80002726:	02a080e7          	jalr	42(ra) # 8000174c <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    8000272a:	70a2                	ld	ra,40(sp)
    8000272c:	7402                	ld	s0,32(sp)
    8000272e:	64e2                	ld	s1,24(sp)
    80002730:	6942                	ld	s2,16(sp)
    80002732:	69a2                	ld	s3,8(sp)
    80002734:	6a02                	ld	s4,0(sp)
    80002736:	6145                	addi	sp,sp,48
    80002738:	8082                	ret
        memmove((char *)dst, src, len);
    8000273a:	000a061b          	sext.w	a2,s4
    8000273e:	85ce                	mv	a1,s3
    80002740:	854a                	mv	a0,s2
    80002742:	ffffe097          	auipc	ra,0xffffe
    80002746:	6cc080e7          	jalr	1740(ra) # 80000e0e <memmove>
        return 0;
    8000274a:	8526                	mv	a0,s1
    8000274c:	bff9                	j	8000272a <either_copyout+0x32>

000000008000274e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000274e:	7179                	addi	sp,sp,-48
    80002750:	f406                	sd	ra,40(sp)
    80002752:	f022                	sd	s0,32(sp)
    80002754:	ec26                	sd	s1,24(sp)
    80002756:	e84a                	sd	s2,16(sp)
    80002758:	e44e                	sd	s3,8(sp)
    8000275a:	e052                	sd	s4,0(sp)
    8000275c:	1800                	addi	s0,sp,48
    8000275e:	892a                	mv	s2,a0
    80002760:	84ae                	mv	s1,a1
    80002762:	89b2                	mv	s3,a2
    80002764:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002766:	fffff097          	auipc	ra,0xfffff
    8000276a:	426080e7          	jalr	1062(ra) # 80001b8c <myproc>
    if (user_src)
    8000276e:	c08d                	beqz	s1,80002790 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    80002770:	86d2                	mv	a3,s4
    80002772:	864e                	mv	a2,s3
    80002774:	85ca                	mv	a1,s2
    80002776:	6928                	ld	a0,80(a0)
    80002778:	fffff097          	auipc	ra,0xfffff
    8000277c:	060080e7          	jalr	96(ra) # 800017d8 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    80002780:	70a2                	ld	ra,40(sp)
    80002782:	7402                	ld	s0,32(sp)
    80002784:	64e2                	ld	s1,24(sp)
    80002786:	6942                	ld	s2,16(sp)
    80002788:	69a2                	ld	s3,8(sp)
    8000278a:	6a02                	ld	s4,0(sp)
    8000278c:	6145                	addi	sp,sp,48
    8000278e:	8082                	ret
        memmove(dst, (char *)src, len);
    80002790:	000a061b          	sext.w	a2,s4
    80002794:	85ce                	mv	a1,s3
    80002796:	854a                	mv	a0,s2
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	676080e7          	jalr	1654(ra) # 80000e0e <memmove>
        return 0;
    800027a0:	8526                	mv	a0,s1
    800027a2:	bff9                	j	80002780 <either_copyin+0x32>

00000000800027a4 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800027a4:	715d                	addi	sp,sp,-80
    800027a6:	e486                	sd	ra,72(sp)
    800027a8:	e0a2                	sd	s0,64(sp)
    800027aa:	fc26                	sd	s1,56(sp)
    800027ac:	f84a                	sd	s2,48(sp)
    800027ae:	f44e                	sd	s3,40(sp)
    800027b0:	f052                	sd	s4,32(sp)
    800027b2:	ec56                	sd	s5,24(sp)
    800027b4:	e85a                	sd	s6,16(sp)
    800027b6:	e45e                	sd	s7,8(sp)
    800027b8:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    800027ba:	00006517          	auipc	a0,0x6
    800027be:	8ce50513          	addi	a0,a0,-1842 # 80008088 <digits+0x38>
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	dde080e7          	jalr	-546(ra) # 800005a0 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800027ca:	0000f497          	auipc	s1,0xf
    800027ce:	a8e48493          	addi	s1,s1,-1394 # 80011258 <proc+0x158>
    800027d2:	00014917          	auipc	s2,0x14
    800027d6:	48690913          	addi	s2,s2,1158 # 80016c58 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027da:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800027dc:	00006997          	auipc	s3,0x6
    800027e0:	ae498993          	addi	s3,s3,-1308 # 800082c0 <digits+0x270>
        printf("%d <%s %s", p->pid, state, p->name);
    800027e4:	00006a97          	auipc	s5,0x6
    800027e8:	ae4a8a93          	addi	s5,s5,-1308 # 800082c8 <digits+0x278>
        printf("\n");
    800027ec:	00006a17          	auipc	s4,0x6
    800027f0:	89ca0a13          	addi	s4,s4,-1892 # 80008088 <digits+0x38>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027f4:	00006b97          	auipc	s7,0x6
    800027f8:	be4b8b93          	addi	s7,s7,-1052 # 800083d8 <states.1774>
    800027fc:	a00d                	j	8000281e <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    800027fe:	ed86a583          	lw	a1,-296(a3)
    80002802:	8556                	mv	a0,s5
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	d9c080e7          	jalr	-612(ra) # 800005a0 <printf>
        printf("\n");
    8000280c:	8552                	mv	a0,s4
    8000280e:	ffffe097          	auipc	ra,0xffffe
    80002812:	d92080e7          	jalr	-622(ra) # 800005a0 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002816:	16848493          	addi	s1,s1,360
    8000281a:	03248163          	beq	s1,s2,8000283c <procdump+0x98>
        if (p->state == UNUSED)
    8000281e:	86a6                	mv	a3,s1
    80002820:	ec04a783          	lw	a5,-320(s1)
    80002824:	dbed                	beqz	a5,80002816 <procdump+0x72>
            state = "???";
    80002826:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002828:	fcfb6be3          	bltu	s6,a5,800027fe <procdump+0x5a>
    8000282c:	1782                	slli	a5,a5,0x20
    8000282e:	9381                	srli	a5,a5,0x20
    80002830:	078e                	slli	a5,a5,0x3
    80002832:	97de                	add	a5,a5,s7
    80002834:	6390                	ld	a2,0(a5)
    80002836:	f661                	bnez	a2,800027fe <procdump+0x5a>
            state = "???";
    80002838:	864e                	mv	a2,s3
    8000283a:	b7d1                	j	800027fe <procdump+0x5a>
    }
}
    8000283c:	60a6                	ld	ra,72(sp)
    8000283e:	6406                	ld	s0,64(sp)
    80002840:	74e2                	ld	s1,56(sp)
    80002842:	7942                	ld	s2,48(sp)
    80002844:	79a2                	ld	s3,40(sp)
    80002846:	7a02                	ld	s4,32(sp)
    80002848:	6ae2                	ld	s5,24(sp)
    8000284a:	6b42                	ld	s6,16(sp)
    8000284c:	6ba2                	ld	s7,8(sp)
    8000284e:	6161                	addi	sp,sp,80
    80002850:	8082                	ret

0000000080002852 <schedls>:

void schedls()
{
    80002852:	1141                	addi	sp,sp,-16
    80002854:	e406                	sd	ra,8(sp)
    80002856:	e022                	sd	s0,0(sp)
    80002858:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    8000285a:	00006517          	auipc	a0,0x6
    8000285e:	a7e50513          	addi	a0,a0,-1410 # 800082d8 <digits+0x288>
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	d3e080e7          	jalr	-706(ra) # 800005a0 <printf>
    printf("====================================\n");
    8000286a:	00006517          	auipc	a0,0x6
    8000286e:	a9650513          	addi	a0,a0,-1386 # 80008300 <digits+0x2b0>
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	d2e080e7          	jalr	-722(ra) # 800005a0 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    8000287a:	00006717          	auipc	a4,0x6
    8000287e:	16e73703          	ld	a4,366(a4) # 800089e8 <available_schedulers+0x10>
    80002882:	00006797          	auipc	a5,0x6
    80002886:	1067b783          	ld	a5,262(a5) # 80008988 <sched_pointer>
    8000288a:	04f70663          	beq	a4,a5,800028d6 <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    8000288e:	00006517          	auipc	a0,0x6
    80002892:	aa250513          	addi	a0,a0,-1374 # 80008330 <digits+0x2e0>
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	d0a080e7          	jalr	-758(ra) # 800005a0 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    8000289e:	00006617          	auipc	a2,0x6
    800028a2:	15262603          	lw	a2,338(a2) # 800089f0 <available_schedulers+0x18>
    800028a6:	00006597          	auipc	a1,0x6
    800028aa:	13258593          	addi	a1,a1,306 # 800089d8 <available_schedulers>
    800028ae:	00006517          	auipc	a0,0x6
    800028b2:	a8a50513          	addi	a0,a0,-1398 # 80008338 <digits+0x2e8>
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	cea080e7          	jalr	-790(ra) # 800005a0 <printf>
    }
    printf("\n*: current scheduler\n\n");
    800028be:	00006517          	auipc	a0,0x6
    800028c2:	a8250513          	addi	a0,a0,-1406 # 80008340 <digits+0x2f0>
    800028c6:	ffffe097          	auipc	ra,0xffffe
    800028ca:	cda080e7          	jalr	-806(ra) # 800005a0 <printf>
}
    800028ce:	60a2                	ld	ra,8(sp)
    800028d0:	6402                	ld	s0,0(sp)
    800028d2:	0141                	addi	sp,sp,16
    800028d4:	8082                	ret
            printf("[*]\t");
    800028d6:	00006517          	auipc	a0,0x6
    800028da:	a5250513          	addi	a0,a0,-1454 # 80008328 <digits+0x2d8>
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	cc2080e7          	jalr	-830(ra) # 800005a0 <printf>
    800028e6:	bf65                	j	8000289e <schedls+0x4c>

00000000800028e8 <schedset>:

void schedset(int id)
{
    800028e8:	1141                	addi	sp,sp,-16
    800028ea:	e406                	sd	ra,8(sp)
    800028ec:	e022                	sd	s0,0(sp)
    800028ee:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    800028f0:	e90d                	bnez	a0,80002922 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    800028f2:	00006797          	auipc	a5,0x6
    800028f6:	0f67b783          	ld	a5,246(a5) # 800089e8 <available_schedulers+0x10>
    800028fa:	00006717          	auipc	a4,0x6
    800028fe:	08f73723          	sd	a5,142(a4) # 80008988 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002902:	00006597          	auipc	a1,0x6
    80002906:	0d658593          	addi	a1,a1,214 # 800089d8 <available_schedulers>
    8000290a:	00006517          	auipc	a0,0x6
    8000290e:	a7650513          	addi	a0,a0,-1418 # 80008380 <digits+0x330>
    80002912:	ffffe097          	auipc	ra,0xffffe
    80002916:	c8e080e7          	jalr	-882(ra) # 800005a0 <printf>
}
    8000291a:	60a2                	ld	ra,8(sp)
    8000291c:	6402                	ld	s0,0(sp)
    8000291e:	0141                	addi	sp,sp,16
    80002920:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002922:	00006517          	auipc	a0,0x6
    80002926:	a3650513          	addi	a0,a0,-1482 # 80008358 <digits+0x308>
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	c76080e7          	jalr	-906(ra) # 800005a0 <printf>
        return;
    80002932:	b7e5                	j	8000291a <schedset+0x32>

0000000080002934 <va2pa>:

int va2pa (int addr, int pid)
{
    80002934:	862a                	mv	a2,a0
    struct proc *p;

    for (p=proc; p < &proc[NPROC]; p++){
    80002936:	0000e797          	auipc	a5,0xe
    8000293a:	7ca78793          	addi	a5,a5,1994 # 80011100 <proc>
    8000293e:	00014697          	auipc	a3,0x14
    80002942:	1c268693          	addi	a3,a3,450 # 80016b00 <tickslock>
        if(p->pid == pid)
    80002946:	5b98                	lw	a4,48(a5)
    80002948:	00b70863          	beq	a4,a1,80002958 <va2pa+0x24>
    for (p=proc; p < &proc[NPROC]; p++){
    8000294c:	16878793          	addi	a5,a5,360
    80002950:	fed79be3          	bne	a5,a3,80002946 <va2pa+0x12>
            break;
    }

    if ( p >= &proc[NPROC] || p->state == UNUSED){
        return 0;
    80002954:	4501                	li	a0,0
    80002956:	8082                	ret
    if ( p >= &proc[NPROC] || p->state == UNUSED){
    80002958:	00014717          	auipc	a4,0x14
    8000295c:	1a870713          	addi	a4,a4,424 # 80016b00 <tickslock>
    80002960:	02e7f563          	bgeu	a5,a4,8000298a <va2pa+0x56>
    80002964:	4f98                	lw	a4,24(a5)
        return 0;
    80002966:	4501                	li	a0,0
    if ( p >= &proc[NPROC] || p->state == UNUSED){
    80002968:	e311                	bnez	a4,8000296c <va2pa+0x38>
    }

    return walkaddr(p->pagetable, addr);
    8000296a:	8082                	ret
{
    8000296c:	1141                	addi	sp,sp,-16
    8000296e:	e406                	sd	ra,8(sp)
    80002970:	e022                	sd	s0,0(sp)
    80002972:	0800                	addi	s0,sp,16
    return walkaddr(p->pagetable, addr);
    80002974:	85b2                	mv	a1,a2
    80002976:	6ba8                	ld	a0,80(a5)
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	7c8080e7          	jalr	1992(ra) # 80001140 <walkaddr>
    80002980:	2501                	sext.w	a0,a0
    80002982:	60a2                	ld	ra,8(sp)
    80002984:	6402                	ld	s0,0(sp)
    80002986:	0141                	addi	sp,sp,16
    80002988:	8082                	ret
        return 0;
    8000298a:	4501                	li	a0,0
    8000298c:	8082                	ret

000000008000298e <swtch>:
    8000298e:	00153023          	sd	ra,0(a0)
    80002992:	00253423          	sd	sp,8(a0)
    80002996:	e900                	sd	s0,16(a0)
    80002998:	ed04                	sd	s1,24(a0)
    8000299a:	03253023          	sd	s2,32(a0)
    8000299e:	03353423          	sd	s3,40(a0)
    800029a2:	03453823          	sd	s4,48(a0)
    800029a6:	03553c23          	sd	s5,56(a0)
    800029aa:	05653023          	sd	s6,64(a0)
    800029ae:	05753423          	sd	s7,72(a0)
    800029b2:	05853823          	sd	s8,80(a0)
    800029b6:	05953c23          	sd	s9,88(a0)
    800029ba:	07a53023          	sd	s10,96(a0)
    800029be:	07b53423          	sd	s11,104(a0)
    800029c2:	0005b083          	ld	ra,0(a1)
    800029c6:	0085b103          	ld	sp,8(a1)
    800029ca:	6980                	ld	s0,16(a1)
    800029cc:	6d84                	ld	s1,24(a1)
    800029ce:	0205b903          	ld	s2,32(a1)
    800029d2:	0285b983          	ld	s3,40(a1)
    800029d6:	0305ba03          	ld	s4,48(a1)
    800029da:	0385ba83          	ld	s5,56(a1)
    800029de:	0405bb03          	ld	s6,64(a1)
    800029e2:	0485bb83          	ld	s7,72(a1)
    800029e6:	0505bc03          	ld	s8,80(a1)
    800029ea:	0585bc83          	ld	s9,88(a1)
    800029ee:	0605bd03          	ld	s10,96(a1)
    800029f2:	0685bd83          	ld	s11,104(a1)
    800029f6:	8082                	ret

00000000800029f8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029f8:	1141                	addi	sp,sp,-16
    800029fa:	e406                	sd	ra,8(sp)
    800029fc:	e022                	sd	s0,0(sp)
    800029fe:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a00:	00006597          	auipc	a1,0x6
    80002a04:	a0858593          	addi	a1,a1,-1528 # 80008408 <states.1774+0x30>
    80002a08:	00014517          	auipc	a0,0x14
    80002a0c:	0f850513          	addi	a0,a0,248 # 80016b00 <tickslock>
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	212080e7          	jalr	530(ra) # 80000c22 <initlock>
}
    80002a18:	60a2                	ld	ra,8(sp)
    80002a1a:	6402                	ld	s0,0(sp)
    80002a1c:	0141                	addi	sp,sp,16
    80002a1e:	8082                	ret

0000000080002a20 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a20:	1141                	addi	sp,sp,-16
    80002a22:	e422                	sd	s0,8(sp)
    80002a24:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a26:	00003797          	auipc	a5,0x3
    80002a2a:	5ca78793          	addi	a5,a5,1482 # 80005ff0 <kernelvec>
    80002a2e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a32:	6422                	ld	s0,8(sp)
    80002a34:	0141                	addi	sp,sp,16
    80002a36:	8082                	ret

0000000080002a38 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a38:	1141                	addi	sp,sp,-16
    80002a3a:	e406                	sd	ra,8(sp)
    80002a3c:	e022                	sd	s0,0(sp)
    80002a3e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a40:	fffff097          	auipc	ra,0xfffff
    80002a44:	14c080e7          	jalr	332(ra) # 80001b8c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a4c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a4e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a52:	00004617          	auipc	a2,0x4
    80002a56:	5ae60613          	addi	a2,a2,1454 # 80007000 <_trampoline>
    80002a5a:	00004697          	auipc	a3,0x4
    80002a5e:	5a668693          	addi	a3,a3,1446 # 80007000 <_trampoline>
    80002a62:	8e91                	sub	a3,a3,a2
    80002a64:	040007b7          	lui	a5,0x4000
    80002a68:	17fd                	addi	a5,a5,-1
    80002a6a:	07b2                	slli	a5,a5,0xc
    80002a6c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a6e:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a72:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a74:	180026f3          	csrr	a3,satp
    80002a78:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a7a:	6d38                	ld	a4,88(a0)
    80002a7c:	6134                	ld	a3,64(a0)
    80002a7e:	6585                	lui	a1,0x1
    80002a80:	96ae                	add	a3,a3,a1
    80002a82:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a84:	6d38                	ld	a4,88(a0)
    80002a86:	00000697          	auipc	a3,0x0
    80002a8a:	13068693          	addi	a3,a3,304 # 80002bb6 <usertrap>
    80002a8e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a90:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a92:	8692                	mv	a3,tp
    80002a94:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a96:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a9a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a9e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aa2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002aa6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002aa8:	6f18                	ld	a4,24(a4)
    80002aaa:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002aae:	6928                	ld	a0,80(a0)
    80002ab0:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002ab2:	00004717          	auipc	a4,0x4
    80002ab6:	5ea70713          	addi	a4,a4,1514 # 8000709c <userret>
    80002aba:	8f11                	sub	a4,a4,a2
    80002abc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002abe:	577d                	li	a4,-1
    80002ac0:	177e                	slli	a4,a4,0x3f
    80002ac2:	8d59                	or	a0,a0,a4
    80002ac4:	9782                	jalr	a5
}
    80002ac6:	60a2                	ld	ra,8(sp)
    80002ac8:	6402                	ld	s0,0(sp)
    80002aca:	0141                	addi	sp,sp,16
    80002acc:	8082                	ret

0000000080002ace <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ace:	1101                	addi	sp,sp,-32
    80002ad0:	ec06                	sd	ra,24(sp)
    80002ad2:	e822                	sd	s0,16(sp)
    80002ad4:	e426                	sd	s1,8(sp)
    80002ad6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ad8:	00014497          	auipc	s1,0x14
    80002adc:	02848493          	addi	s1,s1,40 # 80016b00 <tickslock>
    80002ae0:	8526                	mv	a0,s1
    80002ae2:	ffffe097          	auipc	ra,0xffffe
    80002ae6:	1d0080e7          	jalr	464(ra) # 80000cb2 <acquire>
  ticks++;
    80002aea:	00006517          	auipc	a0,0x6
    80002aee:	f7650513          	addi	a0,a0,-138 # 80008a60 <ticks>
    80002af2:	411c                	lw	a5,0(a0)
    80002af4:	2785                	addiw	a5,a5,1
    80002af6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002af8:	00000097          	auipc	ra,0x0
    80002afc:	85c080e7          	jalr	-1956(ra) # 80002354 <wakeup>
  release(&tickslock);
    80002b00:	8526                	mv	a0,s1
    80002b02:	ffffe097          	auipc	ra,0xffffe
    80002b06:	264080e7          	jalr	612(ra) # 80000d66 <release>
}
    80002b0a:	60e2                	ld	ra,24(sp)
    80002b0c:	6442                	ld	s0,16(sp)
    80002b0e:	64a2                	ld	s1,8(sp)
    80002b10:	6105                	addi	sp,sp,32
    80002b12:	8082                	ret

0000000080002b14 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b14:	1101                	addi	sp,sp,-32
    80002b16:	ec06                	sd	ra,24(sp)
    80002b18:	e822                	sd	s0,16(sp)
    80002b1a:	e426                	sd	s1,8(sp)
    80002b1c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b1e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b22:	00074d63          	bltz	a4,80002b3c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b26:	57fd                	li	a5,-1
    80002b28:	17fe                	slli	a5,a5,0x3f
    80002b2a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b2c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b2e:	06f70363          	beq	a4,a5,80002b94 <devintr+0x80>
  }
}
    80002b32:	60e2                	ld	ra,24(sp)
    80002b34:	6442                	ld	s0,16(sp)
    80002b36:	64a2                	ld	s1,8(sp)
    80002b38:	6105                	addi	sp,sp,32
    80002b3a:	8082                	ret
     (scause & 0xff) == 9){
    80002b3c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b40:	46a5                	li	a3,9
    80002b42:	fed792e3          	bne	a5,a3,80002b26 <devintr+0x12>
    int irq = plic_claim();
    80002b46:	00003097          	auipc	ra,0x3
    80002b4a:	5b2080e7          	jalr	1458(ra) # 800060f8 <plic_claim>
    80002b4e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b50:	47a9                	li	a5,10
    80002b52:	02f50763          	beq	a0,a5,80002b80 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b56:	4785                	li	a5,1
    80002b58:	02f50963          	beq	a0,a5,80002b8a <devintr+0x76>
    return 1;
    80002b5c:	4505                	li	a0,1
    } else if(irq){
    80002b5e:	d8f1                	beqz	s1,80002b32 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b60:	85a6                	mv	a1,s1
    80002b62:	00006517          	auipc	a0,0x6
    80002b66:	8ae50513          	addi	a0,a0,-1874 # 80008410 <states.1774+0x38>
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	a36080e7          	jalr	-1482(ra) # 800005a0 <printf>
      plic_complete(irq);
    80002b72:	8526                	mv	a0,s1
    80002b74:	00003097          	auipc	ra,0x3
    80002b78:	5a8080e7          	jalr	1448(ra) # 8000611c <plic_complete>
    return 1;
    80002b7c:	4505                	li	a0,1
    80002b7e:	bf55                	j	80002b32 <devintr+0x1e>
      uartintr();
    80002b80:	ffffe097          	auipc	ra,0xffffe
    80002b84:	e40080e7          	jalr	-448(ra) # 800009c0 <uartintr>
    80002b88:	b7ed                	j	80002b72 <devintr+0x5e>
      virtio_disk_intr();
    80002b8a:	00004097          	auipc	ra,0x4
    80002b8e:	abc080e7          	jalr	-1348(ra) # 80006646 <virtio_disk_intr>
    80002b92:	b7c5                	j	80002b72 <devintr+0x5e>
    if(cpuid() == 0){
    80002b94:	fffff097          	auipc	ra,0xfffff
    80002b98:	fcc080e7          	jalr	-52(ra) # 80001b60 <cpuid>
    80002b9c:	c901                	beqz	a0,80002bac <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b9e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ba2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ba4:	14479073          	csrw	sip,a5
    return 2;
    80002ba8:	4509                	li	a0,2
    80002baa:	b761                	j	80002b32 <devintr+0x1e>
      clockintr();
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	f22080e7          	jalr	-222(ra) # 80002ace <clockintr>
    80002bb4:	b7ed                	j	80002b9e <devintr+0x8a>

0000000080002bb6 <usertrap>:
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	e426                	sd	s1,8(sp)
    80002bbe:	e04a                	sd	s2,0(sp)
    80002bc0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bc2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002bc6:	1007f793          	andi	a5,a5,256
    80002bca:	e3b1                	bnez	a5,80002c0e <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bcc:	00003797          	auipc	a5,0x3
    80002bd0:	42478793          	addi	a5,a5,1060 # 80005ff0 <kernelvec>
    80002bd4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bd8:	fffff097          	auipc	ra,0xfffff
    80002bdc:	fb4080e7          	jalr	-76(ra) # 80001b8c <myproc>
    80002be0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002be2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be4:	14102773          	csrr	a4,sepc
    80002be8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bea:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bee:	47a1                	li	a5,8
    80002bf0:	02f70763          	beq	a4,a5,80002c1e <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002bf4:	00000097          	auipc	ra,0x0
    80002bf8:	f20080e7          	jalr	-224(ra) # 80002b14 <devintr>
    80002bfc:	892a                	mv	s2,a0
    80002bfe:	c151                	beqz	a0,80002c82 <usertrap+0xcc>
  if(killed(p))
    80002c00:	8526                	mv	a0,s1
    80002c02:	00000097          	auipc	ra,0x0
    80002c06:	996080e7          	jalr	-1642(ra) # 80002598 <killed>
    80002c0a:	c929                	beqz	a0,80002c5c <usertrap+0xa6>
    80002c0c:	a099                	j	80002c52 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002c0e:	00006517          	auipc	a0,0x6
    80002c12:	82250513          	addi	a0,a0,-2014 # 80008430 <states.1774+0x58>
    80002c16:	ffffe097          	auipc	ra,0xffffe
    80002c1a:	92e080e7          	jalr	-1746(ra) # 80000544 <panic>
    if(killed(p))
    80002c1e:	00000097          	auipc	ra,0x0
    80002c22:	97a080e7          	jalr	-1670(ra) # 80002598 <killed>
    80002c26:	e921                	bnez	a0,80002c76 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002c28:	6cb8                	ld	a4,88(s1)
    80002c2a:	6f1c                	ld	a5,24(a4)
    80002c2c:	0791                	addi	a5,a5,4
    80002c2e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c30:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c34:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c38:	10079073          	csrw	sstatus,a5
    syscall();
    80002c3c:	00000097          	auipc	ra,0x0
    80002c40:	2d4080e7          	jalr	724(ra) # 80002f10 <syscall>
  if(killed(p))
    80002c44:	8526                	mv	a0,s1
    80002c46:	00000097          	auipc	ra,0x0
    80002c4a:	952080e7          	jalr	-1710(ra) # 80002598 <killed>
    80002c4e:	c911                	beqz	a0,80002c62 <usertrap+0xac>
    80002c50:	4901                	li	s2,0
    exit(-1);
    80002c52:	557d                	li	a0,-1
    80002c54:	fffff097          	auipc	ra,0xfffff
    80002c58:	7d0080e7          	jalr	2000(ra) # 80002424 <exit>
  if(which_dev == 2)
    80002c5c:	4789                	li	a5,2
    80002c5e:	04f90f63          	beq	s2,a5,80002cbc <usertrap+0x106>
  usertrapret();
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	dd6080e7          	jalr	-554(ra) # 80002a38 <usertrapret>
}
    80002c6a:	60e2                	ld	ra,24(sp)
    80002c6c:	6442                	ld	s0,16(sp)
    80002c6e:	64a2                	ld	s1,8(sp)
    80002c70:	6902                	ld	s2,0(sp)
    80002c72:	6105                	addi	sp,sp,32
    80002c74:	8082                	ret
      exit(-1);
    80002c76:	557d                	li	a0,-1
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	7ac080e7          	jalr	1964(ra) # 80002424 <exit>
    80002c80:	b765                	j	80002c28 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c82:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c86:	5890                	lw	a2,48(s1)
    80002c88:	00005517          	auipc	a0,0x5
    80002c8c:	7c850513          	addi	a0,a0,1992 # 80008450 <states.1774+0x78>
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	910080e7          	jalr	-1776(ra) # 800005a0 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c98:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c9c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ca0:	00005517          	auipc	a0,0x5
    80002ca4:	7e050513          	addi	a0,a0,2016 # 80008480 <states.1774+0xa8>
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	8f8080e7          	jalr	-1800(ra) # 800005a0 <printf>
    setkilled(p);
    80002cb0:	8526                	mv	a0,s1
    80002cb2:	00000097          	auipc	ra,0x0
    80002cb6:	8ba080e7          	jalr	-1862(ra) # 8000256c <setkilled>
    80002cba:	b769                	j	80002c44 <usertrap+0x8e>
    yield();
    80002cbc:	fffff097          	auipc	ra,0xfffff
    80002cc0:	5f8080e7          	jalr	1528(ra) # 800022b4 <yield>
    80002cc4:	bf79                	j	80002c62 <usertrap+0xac>

0000000080002cc6 <kerneltrap>:
{
    80002cc6:	7179                	addi	sp,sp,-48
    80002cc8:	f406                	sd	ra,40(sp)
    80002cca:	f022                	sd	s0,32(sp)
    80002ccc:	ec26                	sd	s1,24(sp)
    80002cce:	e84a                	sd	s2,16(sp)
    80002cd0:	e44e                	sd	s3,8(sp)
    80002cd2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cd4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cd8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cdc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ce0:	1004f793          	andi	a5,s1,256
    80002ce4:	cb85                	beqz	a5,80002d14 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ce6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cea:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cec:	ef85                	bnez	a5,80002d24 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002cee:	00000097          	auipc	ra,0x0
    80002cf2:	e26080e7          	jalr	-474(ra) # 80002b14 <devintr>
    80002cf6:	cd1d                	beqz	a0,80002d34 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cf8:	4789                	li	a5,2
    80002cfa:	06f50a63          	beq	a0,a5,80002d6e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cfe:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d02:	10049073          	csrw	sstatus,s1
}
    80002d06:	70a2                	ld	ra,40(sp)
    80002d08:	7402                	ld	s0,32(sp)
    80002d0a:	64e2                	ld	s1,24(sp)
    80002d0c:	6942                	ld	s2,16(sp)
    80002d0e:	69a2                	ld	s3,8(sp)
    80002d10:	6145                	addi	sp,sp,48
    80002d12:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d14:	00005517          	auipc	a0,0x5
    80002d18:	78c50513          	addi	a0,a0,1932 # 800084a0 <states.1774+0xc8>
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	828080e7          	jalr	-2008(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002d24:	00005517          	auipc	a0,0x5
    80002d28:	7a450513          	addi	a0,a0,1956 # 800084c8 <states.1774+0xf0>
    80002d2c:	ffffe097          	auipc	ra,0xffffe
    80002d30:	818080e7          	jalr	-2024(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002d34:	85ce                	mv	a1,s3
    80002d36:	00005517          	auipc	a0,0x5
    80002d3a:	7b250513          	addi	a0,a0,1970 # 800084e8 <states.1774+0x110>
    80002d3e:	ffffe097          	auipc	ra,0xffffe
    80002d42:	862080e7          	jalr	-1950(ra) # 800005a0 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d46:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d4a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d4e:	00005517          	auipc	a0,0x5
    80002d52:	7aa50513          	addi	a0,a0,1962 # 800084f8 <states.1774+0x120>
    80002d56:	ffffe097          	auipc	ra,0xffffe
    80002d5a:	84a080e7          	jalr	-1974(ra) # 800005a0 <printf>
    panic("kerneltrap");
    80002d5e:	00005517          	auipc	a0,0x5
    80002d62:	7b250513          	addi	a0,a0,1970 # 80008510 <states.1774+0x138>
    80002d66:	ffffd097          	auipc	ra,0xffffd
    80002d6a:	7de080e7          	jalr	2014(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	e1e080e7          	jalr	-482(ra) # 80001b8c <myproc>
    80002d76:	d541                	beqz	a0,80002cfe <kerneltrap+0x38>
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	e14080e7          	jalr	-492(ra) # 80001b8c <myproc>
    80002d80:	4d18                	lw	a4,24(a0)
    80002d82:	4791                	li	a5,4
    80002d84:	f6f71de3          	bne	a4,a5,80002cfe <kerneltrap+0x38>
    yield();
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	52c080e7          	jalr	1324(ra) # 800022b4 <yield>
    80002d90:	b7bd                	j	80002cfe <kerneltrap+0x38>

0000000080002d92 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d92:	1101                	addi	sp,sp,-32
    80002d94:	ec06                	sd	ra,24(sp)
    80002d96:	e822                	sd	s0,16(sp)
    80002d98:	e426                	sd	s1,8(sp)
    80002d9a:	1000                	addi	s0,sp,32
    80002d9c:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	dee080e7          	jalr	-530(ra) # 80001b8c <myproc>
    switch (n)
    80002da6:	4795                	li	a5,5
    80002da8:	0497e163          	bltu	a5,s1,80002dea <argraw+0x58>
    80002dac:	048a                	slli	s1,s1,0x2
    80002dae:	00005717          	auipc	a4,0x5
    80002db2:	79a70713          	addi	a4,a4,1946 # 80008548 <states.1774+0x170>
    80002db6:	94ba                	add	s1,s1,a4
    80002db8:	409c                	lw	a5,0(s1)
    80002dba:	97ba                	add	a5,a5,a4
    80002dbc:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002dbe:	6d3c                	ld	a5,88(a0)
    80002dc0:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002dc2:	60e2                	ld	ra,24(sp)
    80002dc4:	6442                	ld	s0,16(sp)
    80002dc6:	64a2                	ld	s1,8(sp)
    80002dc8:	6105                	addi	sp,sp,32
    80002dca:	8082                	ret
        return p->trapframe->a1;
    80002dcc:	6d3c                	ld	a5,88(a0)
    80002dce:	7fa8                	ld	a0,120(a5)
    80002dd0:	bfcd                	j	80002dc2 <argraw+0x30>
        return p->trapframe->a2;
    80002dd2:	6d3c                	ld	a5,88(a0)
    80002dd4:	63c8                	ld	a0,128(a5)
    80002dd6:	b7f5                	j	80002dc2 <argraw+0x30>
        return p->trapframe->a3;
    80002dd8:	6d3c                	ld	a5,88(a0)
    80002dda:	67c8                	ld	a0,136(a5)
    80002ddc:	b7dd                	j	80002dc2 <argraw+0x30>
        return p->trapframe->a4;
    80002dde:	6d3c                	ld	a5,88(a0)
    80002de0:	6bc8                	ld	a0,144(a5)
    80002de2:	b7c5                	j	80002dc2 <argraw+0x30>
        return p->trapframe->a5;
    80002de4:	6d3c                	ld	a5,88(a0)
    80002de6:	6fc8                	ld	a0,152(a5)
    80002de8:	bfe9                	j	80002dc2 <argraw+0x30>
    panic("argraw");
    80002dea:	00005517          	auipc	a0,0x5
    80002dee:	73650513          	addi	a0,a0,1846 # 80008520 <states.1774+0x148>
    80002df2:	ffffd097          	auipc	ra,0xffffd
    80002df6:	752080e7          	jalr	1874(ra) # 80000544 <panic>

0000000080002dfa <fetchaddr>:
{
    80002dfa:	1101                	addi	sp,sp,-32
    80002dfc:	ec06                	sd	ra,24(sp)
    80002dfe:	e822                	sd	s0,16(sp)
    80002e00:	e426                	sd	s1,8(sp)
    80002e02:	e04a                	sd	s2,0(sp)
    80002e04:	1000                	addi	s0,sp,32
    80002e06:	84aa                	mv	s1,a0
    80002e08:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	d82080e7          	jalr	-638(ra) # 80001b8c <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002e12:	653c                	ld	a5,72(a0)
    80002e14:	02f4f863          	bgeu	s1,a5,80002e44 <fetchaddr+0x4a>
    80002e18:	00848713          	addi	a4,s1,8
    80002e1c:	02e7e663          	bltu	a5,a4,80002e48 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e20:	46a1                	li	a3,8
    80002e22:	8626                	mv	a2,s1
    80002e24:	85ca                	mv	a1,s2
    80002e26:	6928                	ld	a0,80(a0)
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	9b0080e7          	jalr	-1616(ra) # 800017d8 <copyin>
    80002e30:	00a03533          	snez	a0,a0
    80002e34:	40a00533          	neg	a0,a0
}
    80002e38:	60e2                	ld	ra,24(sp)
    80002e3a:	6442                	ld	s0,16(sp)
    80002e3c:	64a2                	ld	s1,8(sp)
    80002e3e:	6902                	ld	s2,0(sp)
    80002e40:	6105                	addi	sp,sp,32
    80002e42:	8082                	ret
        return -1;
    80002e44:	557d                	li	a0,-1
    80002e46:	bfcd                	j	80002e38 <fetchaddr+0x3e>
    80002e48:	557d                	li	a0,-1
    80002e4a:	b7fd                	j	80002e38 <fetchaddr+0x3e>

0000000080002e4c <fetchstr>:
{
    80002e4c:	7179                	addi	sp,sp,-48
    80002e4e:	f406                	sd	ra,40(sp)
    80002e50:	f022                	sd	s0,32(sp)
    80002e52:	ec26                	sd	s1,24(sp)
    80002e54:	e84a                	sd	s2,16(sp)
    80002e56:	e44e                	sd	s3,8(sp)
    80002e58:	1800                	addi	s0,sp,48
    80002e5a:	892a                	mv	s2,a0
    80002e5c:	84ae                	mv	s1,a1
    80002e5e:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002e60:	fffff097          	auipc	ra,0xfffff
    80002e64:	d2c080e7          	jalr	-724(ra) # 80001b8c <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002e68:	86ce                	mv	a3,s3
    80002e6a:	864a                	mv	a2,s2
    80002e6c:	85a6                	mv	a1,s1
    80002e6e:	6928                	ld	a0,80(a0)
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	9f4080e7          	jalr	-1548(ra) # 80001864 <copyinstr>
    80002e78:	00054e63          	bltz	a0,80002e94 <fetchstr+0x48>
    return strlen(buf);
    80002e7c:	8526                	mv	a0,s1
    80002e7e:	ffffe097          	auipc	ra,0xffffe
    80002e82:	0b4080e7          	jalr	180(ra) # 80000f32 <strlen>
}
    80002e86:	70a2                	ld	ra,40(sp)
    80002e88:	7402                	ld	s0,32(sp)
    80002e8a:	64e2                	ld	s1,24(sp)
    80002e8c:	6942                	ld	s2,16(sp)
    80002e8e:	69a2                	ld	s3,8(sp)
    80002e90:	6145                	addi	sp,sp,48
    80002e92:	8082                	ret
        return -1;
    80002e94:	557d                	li	a0,-1
    80002e96:	bfc5                	j	80002e86 <fetchstr+0x3a>

0000000080002e98 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002e98:	1101                	addi	sp,sp,-32
    80002e9a:	ec06                	sd	ra,24(sp)
    80002e9c:	e822                	sd	s0,16(sp)
    80002e9e:	e426                	sd	s1,8(sp)
    80002ea0:	1000                	addi	s0,sp,32
    80002ea2:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002ea4:	00000097          	auipc	ra,0x0
    80002ea8:	eee080e7          	jalr	-274(ra) # 80002d92 <argraw>
    80002eac:	c088                	sw	a0,0(s1)
}
    80002eae:	60e2                	ld	ra,24(sp)
    80002eb0:	6442                	ld	s0,16(sp)
    80002eb2:	64a2                	ld	s1,8(sp)
    80002eb4:	6105                	addi	sp,sp,32
    80002eb6:	8082                	ret

0000000080002eb8 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002eb8:	1101                	addi	sp,sp,-32
    80002eba:	ec06                	sd	ra,24(sp)
    80002ebc:	e822                	sd	s0,16(sp)
    80002ebe:	e426                	sd	s1,8(sp)
    80002ec0:	1000                	addi	s0,sp,32
    80002ec2:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002ec4:	00000097          	auipc	ra,0x0
    80002ec8:	ece080e7          	jalr	-306(ra) # 80002d92 <argraw>
    80002ecc:	e088                	sd	a0,0(s1)
}
    80002ece:	60e2                	ld	ra,24(sp)
    80002ed0:	6442                	ld	s0,16(sp)
    80002ed2:	64a2                	ld	s1,8(sp)
    80002ed4:	6105                	addi	sp,sp,32
    80002ed6:	8082                	ret

0000000080002ed8 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002ed8:	7179                	addi	sp,sp,-48
    80002eda:	f406                	sd	ra,40(sp)
    80002edc:	f022                	sd	s0,32(sp)
    80002ede:	ec26                	sd	s1,24(sp)
    80002ee0:	e84a                	sd	s2,16(sp)
    80002ee2:	1800                	addi	s0,sp,48
    80002ee4:	84ae                	mv	s1,a1
    80002ee6:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80002ee8:	fd840593          	addi	a1,s0,-40
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	fcc080e7          	jalr	-52(ra) # 80002eb8 <argaddr>
    return fetchstr(addr, buf, max);
    80002ef4:	864a                	mv	a2,s2
    80002ef6:	85a6                	mv	a1,s1
    80002ef8:	fd843503          	ld	a0,-40(s0)
    80002efc:	00000097          	auipc	ra,0x0
    80002f00:	f50080e7          	jalr	-176(ra) # 80002e4c <fetchstr>
}
    80002f04:	70a2                	ld	ra,40(sp)
    80002f06:	7402                	ld	s0,32(sp)
    80002f08:	64e2                	ld	s1,24(sp)
    80002f0a:	6942                	ld	s2,16(sp)
    80002f0c:	6145                	addi	sp,sp,48
    80002f0e:	8082                	ret

0000000080002f10 <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    80002f10:	1101                	addi	sp,sp,-32
    80002f12:	ec06                	sd	ra,24(sp)
    80002f14:	e822                	sd	s0,16(sp)
    80002f16:	e426                	sd	s1,8(sp)
    80002f18:	e04a                	sd	s2,0(sp)
    80002f1a:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    80002f1c:	fffff097          	auipc	ra,0xfffff
    80002f20:	c70080e7          	jalr	-912(ra) # 80001b8c <myproc>
    80002f24:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80002f26:	05853903          	ld	s2,88(a0)
    80002f2a:	0a893783          	ld	a5,168(s2)
    80002f2e:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002f32:	37fd                	addiw	a5,a5,-1
    80002f34:	4765                	li	a4,25
    80002f36:	00f76f63          	bltu	a4,a5,80002f54 <syscall+0x44>
    80002f3a:	00369713          	slli	a4,a3,0x3
    80002f3e:	00005797          	auipc	a5,0x5
    80002f42:	62278793          	addi	a5,a5,1570 # 80008560 <syscalls>
    80002f46:	97ba                	add	a5,a5,a4
    80002f48:	639c                	ld	a5,0(a5)
    80002f4a:	c789                	beqz	a5,80002f54 <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    80002f4c:	9782                	jalr	a5
    80002f4e:	06a93823          	sd	a0,112(s2)
    80002f52:	a839                	j	80002f70 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    80002f54:	15848613          	addi	a2,s1,344
    80002f58:	588c                	lw	a1,48(s1)
    80002f5a:	00005517          	auipc	a0,0x5
    80002f5e:	5ce50513          	addi	a0,a0,1486 # 80008528 <states.1774+0x150>
    80002f62:	ffffd097          	auipc	ra,0xffffd
    80002f66:	63e080e7          	jalr	1598(ra) # 800005a0 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    80002f6a:	6cbc                	ld	a5,88(s1)
    80002f6c:	577d                	li	a4,-1
    80002f6e:	fbb8                	sd	a4,112(a5)
    }
}
    80002f70:	60e2                	ld	ra,24(sp)
    80002f72:	6442                	ld	s0,16(sp)
    80002f74:	64a2                	ld	s1,8(sp)
    80002f76:	6902                	ld	s2,0(sp)
    80002f78:	6105                	addi	sp,sp,32
    80002f7a:	8082                	ret

0000000080002f7c <sys_exit>:

extern uint64 FREE_PAGES; // kalloc.c keeps track of those

uint64
sys_exit(void)
{
    80002f7c:	1101                	addi	sp,sp,-32
    80002f7e:	ec06                	sd	ra,24(sp)
    80002f80:	e822                	sd	s0,16(sp)
    80002f82:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    80002f84:	fec40593          	addi	a1,s0,-20
    80002f88:	4501                	li	a0,0
    80002f8a:	00000097          	auipc	ra,0x0
    80002f8e:	f0e080e7          	jalr	-242(ra) # 80002e98 <argint>
    exit(n);
    80002f92:	fec42503          	lw	a0,-20(s0)
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	48e080e7          	jalr	1166(ra) # 80002424 <exit>
    return 0; // not reached
}
    80002f9e:	4501                	li	a0,0
    80002fa0:	60e2                	ld	ra,24(sp)
    80002fa2:	6442                	ld	s0,16(sp)
    80002fa4:	6105                	addi	sp,sp,32
    80002fa6:	8082                	ret

0000000080002fa8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002fa8:	1141                	addi	sp,sp,-16
    80002faa:	e406                	sd	ra,8(sp)
    80002fac:	e022                	sd	s0,0(sp)
    80002fae:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80002fb0:	fffff097          	auipc	ra,0xfffff
    80002fb4:	bdc080e7          	jalr	-1060(ra) # 80001b8c <myproc>
}
    80002fb8:	5908                	lw	a0,48(a0)
    80002fba:	60a2                	ld	ra,8(sp)
    80002fbc:	6402                	ld	s0,0(sp)
    80002fbe:	0141                	addi	sp,sp,16
    80002fc0:	8082                	ret

0000000080002fc2 <sys_fork>:

uint64
sys_fork(void)
{
    80002fc2:	1141                	addi	sp,sp,-16
    80002fc4:	e406                	sd	ra,8(sp)
    80002fc6:	e022                	sd	s0,0(sp)
    80002fc8:	0800                	addi	s0,sp,16
    return fork();
    80002fca:	fffff097          	auipc	ra,0xfffff
    80002fce:	0c8080e7          	jalr	200(ra) # 80002092 <fork>
}
    80002fd2:	60a2                	ld	ra,8(sp)
    80002fd4:	6402                	ld	s0,0(sp)
    80002fd6:	0141                	addi	sp,sp,16
    80002fd8:	8082                	ret

0000000080002fda <sys_wait>:

uint64
sys_wait(void)
{
    80002fda:	1101                	addi	sp,sp,-32
    80002fdc:	ec06                	sd	ra,24(sp)
    80002fde:	e822                	sd	s0,16(sp)
    80002fe0:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80002fe2:	fe840593          	addi	a1,s0,-24
    80002fe6:	4501                	li	a0,0
    80002fe8:	00000097          	auipc	ra,0x0
    80002fec:	ed0080e7          	jalr	-304(ra) # 80002eb8 <argaddr>
    return wait(p);
    80002ff0:	fe843503          	ld	a0,-24(s0)
    80002ff4:	fffff097          	auipc	ra,0xfffff
    80002ff8:	5d6080e7          	jalr	1494(ra) # 800025ca <wait>
}
    80002ffc:	60e2                	ld	ra,24(sp)
    80002ffe:	6442                	ld	s0,16(sp)
    80003000:	6105                	addi	sp,sp,32
    80003002:	8082                	ret

0000000080003004 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003004:	7179                	addi	sp,sp,-48
    80003006:	f406                	sd	ra,40(sp)
    80003008:	f022                	sd	s0,32(sp)
    8000300a:	ec26                	sd	s1,24(sp)
    8000300c:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    8000300e:	fdc40593          	addi	a1,s0,-36
    80003012:	4501                	li	a0,0
    80003014:	00000097          	auipc	ra,0x0
    80003018:	e84080e7          	jalr	-380(ra) # 80002e98 <argint>
    addr = myproc()->sz;
    8000301c:	fffff097          	auipc	ra,0xfffff
    80003020:	b70080e7          	jalr	-1168(ra) # 80001b8c <myproc>
    80003024:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    80003026:	fdc42503          	lw	a0,-36(s0)
    8000302a:	fffff097          	auipc	ra,0xfffff
    8000302e:	ebc080e7          	jalr	-324(ra) # 80001ee6 <growproc>
    80003032:	00054863          	bltz	a0,80003042 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80003036:	8526                	mv	a0,s1
    80003038:	70a2                	ld	ra,40(sp)
    8000303a:	7402                	ld	s0,32(sp)
    8000303c:	64e2                	ld	s1,24(sp)
    8000303e:	6145                	addi	sp,sp,48
    80003040:	8082                	ret
        return -1;
    80003042:	54fd                	li	s1,-1
    80003044:	bfcd                	j	80003036 <sys_sbrk+0x32>

0000000080003046 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003046:	7139                	addi	sp,sp,-64
    80003048:	fc06                	sd	ra,56(sp)
    8000304a:	f822                	sd	s0,48(sp)
    8000304c:	f426                	sd	s1,40(sp)
    8000304e:	f04a                	sd	s2,32(sp)
    80003050:	ec4e                	sd	s3,24(sp)
    80003052:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    80003054:	fcc40593          	addi	a1,s0,-52
    80003058:	4501                	li	a0,0
    8000305a:	00000097          	auipc	ra,0x0
    8000305e:	e3e080e7          	jalr	-450(ra) # 80002e98 <argint>
    acquire(&tickslock);
    80003062:	00014517          	auipc	a0,0x14
    80003066:	a9e50513          	addi	a0,a0,-1378 # 80016b00 <tickslock>
    8000306a:	ffffe097          	auipc	ra,0xffffe
    8000306e:	c48080e7          	jalr	-952(ra) # 80000cb2 <acquire>
    ticks0 = ticks;
    80003072:	00006917          	auipc	s2,0x6
    80003076:	9ee92903          	lw	s2,-1554(s2) # 80008a60 <ticks>
    while (ticks - ticks0 < n)
    8000307a:	fcc42783          	lw	a5,-52(s0)
    8000307e:	cf9d                	beqz	a5,800030bc <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80003080:	00014997          	auipc	s3,0x14
    80003084:	a8098993          	addi	s3,s3,-1408 # 80016b00 <tickslock>
    80003088:	00006497          	auipc	s1,0x6
    8000308c:	9d848493          	addi	s1,s1,-1576 # 80008a60 <ticks>
        if (killed(myproc()))
    80003090:	fffff097          	auipc	ra,0xfffff
    80003094:	afc080e7          	jalr	-1284(ra) # 80001b8c <myproc>
    80003098:	fffff097          	auipc	ra,0xfffff
    8000309c:	500080e7          	jalr	1280(ra) # 80002598 <killed>
    800030a0:	ed15                	bnez	a0,800030dc <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    800030a2:	85ce                	mv	a1,s3
    800030a4:	8526                	mv	a0,s1
    800030a6:	fffff097          	auipc	ra,0xfffff
    800030aa:	24a080e7          	jalr	586(ra) # 800022f0 <sleep>
    while (ticks - ticks0 < n)
    800030ae:	409c                	lw	a5,0(s1)
    800030b0:	412787bb          	subw	a5,a5,s2
    800030b4:	fcc42703          	lw	a4,-52(s0)
    800030b8:	fce7ece3          	bltu	a5,a4,80003090 <sys_sleep+0x4a>
    }
    release(&tickslock);
    800030bc:	00014517          	auipc	a0,0x14
    800030c0:	a4450513          	addi	a0,a0,-1468 # 80016b00 <tickslock>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	ca2080e7          	jalr	-862(ra) # 80000d66 <release>
    return 0;
    800030cc:	4501                	li	a0,0
}
    800030ce:	70e2                	ld	ra,56(sp)
    800030d0:	7442                	ld	s0,48(sp)
    800030d2:	74a2                	ld	s1,40(sp)
    800030d4:	7902                	ld	s2,32(sp)
    800030d6:	69e2                	ld	s3,24(sp)
    800030d8:	6121                	addi	sp,sp,64
    800030da:	8082                	ret
            release(&tickslock);
    800030dc:	00014517          	auipc	a0,0x14
    800030e0:	a2450513          	addi	a0,a0,-1500 # 80016b00 <tickslock>
    800030e4:	ffffe097          	auipc	ra,0xffffe
    800030e8:	c82080e7          	jalr	-894(ra) # 80000d66 <release>
            return -1;
    800030ec:	557d                	li	a0,-1
    800030ee:	b7c5                	j	800030ce <sys_sleep+0x88>

00000000800030f0 <sys_kill>:

uint64
sys_kill(void)
{
    800030f0:	1101                	addi	sp,sp,-32
    800030f2:	ec06                	sd	ra,24(sp)
    800030f4:	e822                	sd	s0,16(sp)
    800030f6:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    800030f8:	fec40593          	addi	a1,s0,-20
    800030fc:	4501                	li	a0,0
    800030fe:	00000097          	auipc	ra,0x0
    80003102:	d9a080e7          	jalr	-614(ra) # 80002e98 <argint>
    return kill(pid);
    80003106:	fec42503          	lw	a0,-20(s0)
    8000310a:	fffff097          	auipc	ra,0xfffff
    8000310e:	3f0080e7          	jalr	1008(ra) # 800024fa <kill>
}
    80003112:	60e2                	ld	ra,24(sp)
    80003114:	6442                	ld	s0,16(sp)
    80003116:	6105                	addi	sp,sp,32
    80003118:	8082                	ret

000000008000311a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000311a:	1101                	addi	sp,sp,-32
    8000311c:	ec06                	sd	ra,24(sp)
    8000311e:	e822                	sd	s0,16(sp)
    80003120:	e426                	sd	s1,8(sp)
    80003122:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    80003124:	00014517          	auipc	a0,0x14
    80003128:	9dc50513          	addi	a0,a0,-1572 # 80016b00 <tickslock>
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	b86080e7          	jalr	-1146(ra) # 80000cb2 <acquire>
    xticks = ticks;
    80003134:	00006497          	auipc	s1,0x6
    80003138:	92c4a483          	lw	s1,-1748(s1) # 80008a60 <ticks>
    release(&tickslock);
    8000313c:	00014517          	auipc	a0,0x14
    80003140:	9c450513          	addi	a0,a0,-1596 # 80016b00 <tickslock>
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	c22080e7          	jalr	-990(ra) # 80000d66 <release>
    return xticks;
}
    8000314c:	02049513          	slli	a0,s1,0x20
    80003150:	9101                	srli	a0,a0,0x20
    80003152:	60e2                	ld	ra,24(sp)
    80003154:	6442                	ld	s0,16(sp)
    80003156:	64a2                	ld	s1,8(sp)
    80003158:	6105                	addi	sp,sp,32
    8000315a:	8082                	ret

000000008000315c <sys_ps>:

void *
sys_ps(void)
{
    8000315c:	1101                	addi	sp,sp,-32
    8000315e:	ec06                	sd	ra,24(sp)
    80003160:	e822                	sd	s0,16(sp)
    80003162:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    80003164:	fe042623          	sw	zero,-20(s0)
    80003168:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    8000316c:	fec40593          	addi	a1,s0,-20
    80003170:	4501                	li	a0,0
    80003172:	00000097          	auipc	ra,0x0
    80003176:	d26080e7          	jalr	-730(ra) # 80002e98 <argint>
    argint(1, &count);
    8000317a:	fe840593          	addi	a1,s0,-24
    8000317e:	4505                	li	a0,1
    80003180:	00000097          	auipc	ra,0x0
    80003184:	d18080e7          	jalr	-744(ra) # 80002e98 <argint>
    return ps((uint8)start, (uint8)count);
    80003188:	fe844583          	lbu	a1,-24(s0)
    8000318c:	fec44503          	lbu	a0,-20(s0)
    80003190:	fffff097          	auipc	ra,0xfffff
    80003194:	db2080e7          	jalr	-590(ra) # 80001f42 <ps>
}
    80003198:	60e2                	ld	ra,24(sp)
    8000319a:	6442                	ld	s0,16(sp)
    8000319c:	6105                	addi	sp,sp,32
    8000319e:	8082                	ret

00000000800031a0 <sys_schedls>:

uint64 sys_schedls(void)
{
    800031a0:	1141                	addi	sp,sp,-16
    800031a2:	e406                	sd	ra,8(sp)
    800031a4:	e022                	sd	s0,0(sp)
    800031a6:	0800                	addi	s0,sp,16
    schedls();
    800031a8:	fffff097          	auipc	ra,0xfffff
    800031ac:	6aa080e7          	jalr	1706(ra) # 80002852 <schedls>
    return 0;
}
    800031b0:	4501                	li	a0,0
    800031b2:	60a2                	ld	ra,8(sp)
    800031b4:	6402                	ld	s0,0(sp)
    800031b6:	0141                	addi	sp,sp,16
    800031b8:	8082                	ret

00000000800031ba <sys_schedset>:

uint64 sys_schedset(void)
{
    800031ba:	1101                	addi	sp,sp,-32
    800031bc:	ec06                	sd	ra,24(sp)
    800031be:	e822                	sd	s0,16(sp)
    800031c0:	1000                	addi	s0,sp,32
    int id = 0;
    800031c2:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    800031c6:	fec40593          	addi	a1,s0,-20
    800031ca:	4501                	li	a0,0
    800031cc:	00000097          	auipc	ra,0x0
    800031d0:	ccc080e7          	jalr	-820(ra) # 80002e98 <argint>
    schedset(id - 1);
    800031d4:	fec42503          	lw	a0,-20(s0)
    800031d8:	357d                	addiw	a0,a0,-1
    800031da:	fffff097          	auipc	ra,0xfffff
    800031de:	70e080e7          	jalr	1806(ra) # 800028e8 <schedset>
    return 0;
}
    800031e2:	4501                	li	a0,0
    800031e4:	60e2                	ld	ra,24(sp)
    800031e6:	6442                	ld	s0,16(sp)
    800031e8:	6105                	addi	sp,sp,32
    800031ea:	8082                	ret

00000000800031ec <sys_va2pa>:

uint64 sys_va2pa(void)
{
    800031ec:	1101                	addi	sp,sp,-32
    800031ee:	ec06                	sd	ra,24(sp)
    800031f0:	e822                	sd	s0,16(sp)
    800031f2:	1000                	addi	s0,sp,32
    int addr = 0, pid = 0;
    800031f4:	fe042623          	sw	zero,-20(s0)
    800031f8:	fe042423          	sw	zero,-24(s0)
    
    argint(0, &addr);
    800031fc:	fec40593          	addi	a1,s0,-20
    80003200:	4501                	li	a0,0
    80003202:	00000097          	auipc	ra,0x0
    80003206:	c96080e7          	jalr	-874(ra) # 80002e98 <argint>
    argint(1, &pid);
    8000320a:	fe840593          	addi	a1,s0,-24
    8000320e:	4505                	li	a0,1
    80003210:	00000097          	auipc	ra,0x0
    80003214:	c88080e7          	jalr	-888(ra) # 80002e98 <argint>

    if( pid == -1 ){
    80003218:	fe842703          	lw	a4,-24(s0)
    8000321c:	57fd                	li	a5,-1
    8000321e:	00f70e63          	beq	a4,a5,8000323a <sys_va2pa+0x4e>
        pid =  myproc()->pid;
    }
    
    return va2pa( addr, pid );
    80003222:	fe842583          	lw	a1,-24(s0)
    80003226:	fec42503          	lw	a0,-20(s0)
    8000322a:	fffff097          	auipc	ra,0xfffff
    8000322e:	70a080e7          	jalr	1802(ra) # 80002934 <va2pa>
}
    80003232:	60e2                	ld	ra,24(sp)
    80003234:	6442                	ld	s0,16(sp)
    80003236:	6105                	addi	sp,sp,32
    80003238:	8082                	ret
        pid =  myproc()->pid;
    8000323a:	fffff097          	auipc	ra,0xfffff
    8000323e:	952080e7          	jalr	-1710(ra) # 80001b8c <myproc>
    80003242:	591c                	lw	a5,48(a0)
    80003244:	fef42423          	sw	a5,-24(s0)
    80003248:	bfe9                	j	80003222 <sys_va2pa+0x36>

000000008000324a <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    8000324a:	1141                	addi	sp,sp,-16
    8000324c:	e406                	sd	ra,8(sp)
    8000324e:	e022                	sd	s0,0(sp)
    80003250:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    80003252:	00005597          	auipc	a1,0x5
    80003256:	7e65b583          	ld	a1,2022(a1) # 80008a38 <FREE_PAGES>
    8000325a:	00005517          	auipc	a0,0x5
    8000325e:	2e650513          	addi	a0,a0,742 # 80008540 <states.1774+0x168>
    80003262:	ffffd097          	auipc	ra,0xffffd
    80003266:	33e080e7          	jalr	830(ra) # 800005a0 <printf>
    return 0;
}
    8000326a:	4501                	li	a0,0
    8000326c:	60a2                	ld	ra,8(sp)
    8000326e:	6402                	ld	s0,0(sp)
    80003270:	0141                	addi	sp,sp,16
    80003272:	8082                	ret

0000000080003274 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003274:	7179                	addi	sp,sp,-48
    80003276:	f406                	sd	ra,40(sp)
    80003278:	f022                	sd	s0,32(sp)
    8000327a:	ec26                	sd	s1,24(sp)
    8000327c:	e84a                	sd	s2,16(sp)
    8000327e:	e44e                	sd	s3,8(sp)
    80003280:	e052                	sd	s4,0(sp)
    80003282:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003284:	00005597          	auipc	a1,0x5
    80003288:	3b458593          	addi	a1,a1,948 # 80008638 <syscalls+0xd8>
    8000328c:	00014517          	auipc	a0,0x14
    80003290:	88c50513          	addi	a0,a0,-1908 # 80016b18 <bcache>
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	98e080e7          	jalr	-1650(ra) # 80000c22 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000329c:	0001c797          	auipc	a5,0x1c
    800032a0:	87c78793          	addi	a5,a5,-1924 # 8001eb18 <bcache+0x8000>
    800032a4:	0001c717          	auipc	a4,0x1c
    800032a8:	adc70713          	addi	a4,a4,-1316 # 8001ed80 <bcache+0x8268>
    800032ac:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800032b0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032b4:	00014497          	auipc	s1,0x14
    800032b8:	87c48493          	addi	s1,s1,-1924 # 80016b30 <bcache+0x18>
    b->next = bcache.head.next;
    800032bc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032be:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032c0:	00005a17          	auipc	s4,0x5
    800032c4:	380a0a13          	addi	s4,s4,896 # 80008640 <syscalls+0xe0>
    b->next = bcache.head.next;
    800032c8:	2b893783          	ld	a5,696(s2)
    800032cc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032ce:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032d2:	85d2                	mv	a1,s4
    800032d4:	01048513          	addi	a0,s1,16
    800032d8:	00001097          	auipc	ra,0x1
    800032dc:	4c4080e7          	jalr	1220(ra) # 8000479c <initsleeplock>
    bcache.head.next->prev = b;
    800032e0:	2b893783          	ld	a5,696(s2)
    800032e4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032e6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032ea:	45848493          	addi	s1,s1,1112
    800032ee:	fd349de3          	bne	s1,s3,800032c8 <binit+0x54>
  }
}
    800032f2:	70a2                	ld	ra,40(sp)
    800032f4:	7402                	ld	s0,32(sp)
    800032f6:	64e2                	ld	s1,24(sp)
    800032f8:	6942                	ld	s2,16(sp)
    800032fa:	69a2                	ld	s3,8(sp)
    800032fc:	6a02                	ld	s4,0(sp)
    800032fe:	6145                	addi	sp,sp,48
    80003300:	8082                	ret

0000000080003302 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003302:	7179                	addi	sp,sp,-48
    80003304:	f406                	sd	ra,40(sp)
    80003306:	f022                	sd	s0,32(sp)
    80003308:	ec26                	sd	s1,24(sp)
    8000330a:	e84a                	sd	s2,16(sp)
    8000330c:	e44e                	sd	s3,8(sp)
    8000330e:	1800                	addi	s0,sp,48
    80003310:	89aa                	mv	s3,a0
    80003312:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003314:	00014517          	auipc	a0,0x14
    80003318:	80450513          	addi	a0,a0,-2044 # 80016b18 <bcache>
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	996080e7          	jalr	-1642(ra) # 80000cb2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003324:	0001c497          	auipc	s1,0x1c
    80003328:	aac4b483          	ld	s1,-1364(s1) # 8001edd0 <bcache+0x82b8>
    8000332c:	0001c797          	auipc	a5,0x1c
    80003330:	a5478793          	addi	a5,a5,-1452 # 8001ed80 <bcache+0x8268>
    80003334:	02f48f63          	beq	s1,a5,80003372 <bread+0x70>
    80003338:	873e                	mv	a4,a5
    8000333a:	a021                	j	80003342 <bread+0x40>
    8000333c:	68a4                	ld	s1,80(s1)
    8000333e:	02e48a63          	beq	s1,a4,80003372 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003342:	449c                	lw	a5,8(s1)
    80003344:	ff379ce3          	bne	a5,s3,8000333c <bread+0x3a>
    80003348:	44dc                	lw	a5,12(s1)
    8000334a:	ff2799e3          	bne	a5,s2,8000333c <bread+0x3a>
      b->refcnt++;
    8000334e:	40bc                	lw	a5,64(s1)
    80003350:	2785                	addiw	a5,a5,1
    80003352:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003354:	00013517          	auipc	a0,0x13
    80003358:	7c450513          	addi	a0,a0,1988 # 80016b18 <bcache>
    8000335c:	ffffe097          	auipc	ra,0xffffe
    80003360:	a0a080e7          	jalr	-1526(ra) # 80000d66 <release>
      acquiresleep(&b->lock);
    80003364:	01048513          	addi	a0,s1,16
    80003368:	00001097          	auipc	ra,0x1
    8000336c:	46e080e7          	jalr	1134(ra) # 800047d6 <acquiresleep>
      return b;
    80003370:	a8b9                	j	800033ce <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003372:	0001c497          	auipc	s1,0x1c
    80003376:	a564b483          	ld	s1,-1450(s1) # 8001edc8 <bcache+0x82b0>
    8000337a:	0001c797          	auipc	a5,0x1c
    8000337e:	a0678793          	addi	a5,a5,-1530 # 8001ed80 <bcache+0x8268>
    80003382:	00f48863          	beq	s1,a5,80003392 <bread+0x90>
    80003386:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003388:	40bc                	lw	a5,64(s1)
    8000338a:	cf81                	beqz	a5,800033a2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000338c:	64a4                	ld	s1,72(s1)
    8000338e:	fee49de3          	bne	s1,a4,80003388 <bread+0x86>
  panic("bget: no buffers");
    80003392:	00005517          	auipc	a0,0x5
    80003396:	2b650513          	addi	a0,a0,694 # 80008648 <syscalls+0xe8>
    8000339a:	ffffd097          	auipc	ra,0xffffd
    8000339e:	1aa080e7          	jalr	426(ra) # 80000544 <panic>
      b->dev = dev;
    800033a2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800033a6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800033aa:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800033ae:	4785                	li	a5,1
    800033b0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033b2:	00013517          	auipc	a0,0x13
    800033b6:	76650513          	addi	a0,a0,1894 # 80016b18 <bcache>
    800033ba:	ffffe097          	auipc	ra,0xffffe
    800033be:	9ac080e7          	jalr	-1620(ra) # 80000d66 <release>
      acquiresleep(&b->lock);
    800033c2:	01048513          	addi	a0,s1,16
    800033c6:	00001097          	auipc	ra,0x1
    800033ca:	410080e7          	jalr	1040(ra) # 800047d6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033ce:	409c                	lw	a5,0(s1)
    800033d0:	cb89                	beqz	a5,800033e2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033d2:	8526                	mv	a0,s1
    800033d4:	70a2                	ld	ra,40(sp)
    800033d6:	7402                	ld	s0,32(sp)
    800033d8:	64e2                	ld	s1,24(sp)
    800033da:	6942                	ld	s2,16(sp)
    800033dc:	69a2                	ld	s3,8(sp)
    800033de:	6145                	addi	sp,sp,48
    800033e0:	8082                	ret
    virtio_disk_rw(b, 0);
    800033e2:	4581                	li	a1,0
    800033e4:	8526                	mv	a0,s1
    800033e6:	00003097          	auipc	ra,0x3
    800033ea:	fd2080e7          	jalr	-46(ra) # 800063b8 <virtio_disk_rw>
    b->valid = 1;
    800033ee:	4785                	li	a5,1
    800033f0:	c09c                	sw	a5,0(s1)
  return b;
    800033f2:	b7c5                	j	800033d2 <bread+0xd0>

00000000800033f4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033f4:	1101                	addi	sp,sp,-32
    800033f6:	ec06                	sd	ra,24(sp)
    800033f8:	e822                	sd	s0,16(sp)
    800033fa:	e426                	sd	s1,8(sp)
    800033fc:	1000                	addi	s0,sp,32
    800033fe:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003400:	0541                	addi	a0,a0,16
    80003402:	00001097          	auipc	ra,0x1
    80003406:	46e080e7          	jalr	1134(ra) # 80004870 <holdingsleep>
    8000340a:	cd01                	beqz	a0,80003422 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000340c:	4585                	li	a1,1
    8000340e:	8526                	mv	a0,s1
    80003410:	00003097          	auipc	ra,0x3
    80003414:	fa8080e7          	jalr	-88(ra) # 800063b8 <virtio_disk_rw>
}
    80003418:	60e2                	ld	ra,24(sp)
    8000341a:	6442                	ld	s0,16(sp)
    8000341c:	64a2                	ld	s1,8(sp)
    8000341e:	6105                	addi	sp,sp,32
    80003420:	8082                	ret
    panic("bwrite");
    80003422:	00005517          	auipc	a0,0x5
    80003426:	23e50513          	addi	a0,a0,574 # 80008660 <syscalls+0x100>
    8000342a:	ffffd097          	auipc	ra,0xffffd
    8000342e:	11a080e7          	jalr	282(ra) # 80000544 <panic>

0000000080003432 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003432:	1101                	addi	sp,sp,-32
    80003434:	ec06                	sd	ra,24(sp)
    80003436:	e822                	sd	s0,16(sp)
    80003438:	e426                	sd	s1,8(sp)
    8000343a:	e04a                	sd	s2,0(sp)
    8000343c:	1000                	addi	s0,sp,32
    8000343e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003440:	01050913          	addi	s2,a0,16
    80003444:	854a                	mv	a0,s2
    80003446:	00001097          	auipc	ra,0x1
    8000344a:	42a080e7          	jalr	1066(ra) # 80004870 <holdingsleep>
    8000344e:	c92d                	beqz	a0,800034c0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003450:	854a                	mv	a0,s2
    80003452:	00001097          	auipc	ra,0x1
    80003456:	3da080e7          	jalr	986(ra) # 8000482c <releasesleep>

  acquire(&bcache.lock);
    8000345a:	00013517          	auipc	a0,0x13
    8000345e:	6be50513          	addi	a0,a0,1726 # 80016b18 <bcache>
    80003462:	ffffe097          	auipc	ra,0xffffe
    80003466:	850080e7          	jalr	-1968(ra) # 80000cb2 <acquire>
  b->refcnt--;
    8000346a:	40bc                	lw	a5,64(s1)
    8000346c:	37fd                	addiw	a5,a5,-1
    8000346e:	0007871b          	sext.w	a4,a5
    80003472:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003474:	eb05                	bnez	a4,800034a4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003476:	68bc                	ld	a5,80(s1)
    80003478:	64b8                	ld	a4,72(s1)
    8000347a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000347c:	64bc                	ld	a5,72(s1)
    8000347e:	68b8                	ld	a4,80(s1)
    80003480:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003482:	0001b797          	auipc	a5,0x1b
    80003486:	69678793          	addi	a5,a5,1686 # 8001eb18 <bcache+0x8000>
    8000348a:	2b87b703          	ld	a4,696(a5)
    8000348e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003490:	0001c717          	auipc	a4,0x1c
    80003494:	8f070713          	addi	a4,a4,-1808 # 8001ed80 <bcache+0x8268>
    80003498:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000349a:	2b87b703          	ld	a4,696(a5)
    8000349e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800034a0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800034a4:	00013517          	auipc	a0,0x13
    800034a8:	67450513          	addi	a0,a0,1652 # 80016b18 <bcache>
    800034ac:	ffffe097          	auipc	ra,0xffffe
    800034b0:	8ba080e7          	jalr	-1862(ra) # 80000d66 <release>
}
    800034b4:	60e2                	ld	ra,24(sp)
    800034b6:	6442                	ld	s0,16(sp)
    800034b8:	64a2                	ld	s1,8(sp)
    800034ba:	6902                	ld	s2,0(sp)
    800034bc:	6105                	addi	sp,sp,32
    800034be:	8082                	ret
    panic("brelse");
    800034c0:	00005517          	auipc	a0,0x5
    800034c4:	1a850513          	addi	a0,a0,424 # 80008668 <syscalls+0x108>
    800034c8:	ffffd097          	auipc	ra,0xffffd
    800034cc:	07c080e7          	jalr	124(ra) # 80000544 <panic>

00000000800034d0 <bpin>:

void
bpin(struct buf *b) {
    800034d0:	1101                	addi	sp,sp,-32
    800034d2:	ec06                	sd	ra,24(sp)
    800034d4:	e822                	sd	s0,16(sp)
    800034d6:	e426                	sd	s1,8(sp)
    800034d8:	1000                	addi	s0,sp,32
    800034da:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034dc:	00013517          	auipc	a0,0x13
    800034e0:	63c50513          	addi	a0,a0,1596 # 80016b18 <bcache>
    800034e4:	ffffd097          	auipc	ra,0xffffd
    800034e8:	7ce080e7          	jalr	1998(ra) # 80000cb2 <acquire>
  b->refcnt++;
    800034ec:	40bc                	lw	a5,64(s1)
    800034ee:	2785                	addiw	a5,a5,1
    800034f0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034f2:	00013517          	auipc	a0,0x13
    800034f6:	62650513          	addi	a0,a0,1574 # 80016b18 <bcache>
    800034fa:	ffffe097          	auipc	ra,0xffffe
    800034fe:	86c080e7          	jalr	-1940(ra) # 80000d66 <release>
}
    80003502:	60e2                	ld	ra,24(sp)
    80003504:	6442                	ld	s0,16(sp)
    80003506:	64a2                	ld	s1,8(sp)
    80003508:	6105                	addi	sp,sp,32
    8000350a:	8082                	ret

000000008000350c <bunpin>:

void
bunpin(struct buf *b) {
    8000350c:	1101                	addi	sp,sp,-32
    8000350e:	ec06                	sd	ra,24(sp)
    80003510:	e822                	sd	s0,16(sp)
    80003512:	e426                	sd	s1,8(sp)
    80003514:	1000                	addi	s0,sp,32
    80003516:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003518:	00013517          	auipc	a0,0x13
    8000351c:	60050513          	addi	a0,a0,1536 # 80016b18 <bcache>
    80003520:	ffffd097          	auipc	ra,0xffffd
    80003524:	792080e7          	jalr	1938(ra) # 80000cb2 <acquire>
  b->refcnt--;
    80003528:	40bc                	lw	a5,64(s1)
    8000352a:	37fd                	addiw	a5,a5,-1
    8000352c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000352e:	00013517          	auipc	a0,0x13
    80003532:	5ea50513          	addi	a0,a0,1514 # 80016b18 <bcache>
    80003536:	ffffe097          	auipc	ra,0xffffe
    8000353a:	830080e7          	jalr	-2000(ra) # 80000d66 <release>
}
    8000353e:	60e2                	ld	ra,24(sp)
    80003540:	6442                	ld	s0,16(sp)
    80003542:	64a2                	ld	s1,8(sp)
    80003544:	6105                	addi	sp,sp,32
    80003546:	8082                	ret

0000000080003548 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003548:	1101                	addi	sp,sp,-32
    8000354a:	ec06                	sd	ra,24(sp)
    8000354c:	e822                	sd	s0,16(sp)
    8000354e:	e426                	sd	s1,8(sp)
    80003550:	e04a                	sd	s2,0(sp)
    80003552:	1000                	addi	s0,sp,32
    80003554:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003556:	00d5d59b          	srliw	a1,a1,0xd
    8000355a:	0001c797          	auipc	a5,0x1c
    8000355e:	c9a7a783          	lw	a5,-870(a5) # 8001f1f4 <sb+0x1c>
    80003562:	9dbd                	addw	a1,a1,a5
    80003564:	00000097          	auipc	ra,0x0
    80003568:	d9e080e7          	jalr	-610(ra) # 80003302 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000356c:	0074f713          	andi	a4,s1,7
    80003570:	4785                	li	a5,1
    80003572:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003576:	14ce                	slli	s1,s1,0x33
    80003578:	90d9                	srli	s1,s1,0x36
    8000357a:	00950733          	add	a4,a0,s1
    8000357e:	05874703          	lbu	a4,88(a4)
    80003582:	00e7f6b3          	and	a3,a5,a4
    80003586:	c69d                	beqz	a3,800035b4 <bfree+0x6c>
    80003588:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000358a:	94aa                	add	s1,s1,a0
    8000358c:	fff7c793          	not	a5,a5
    80003590:	8ff9                	and	a5,a5,a4
    80003592:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003596:	00001097          	auipc	ra,0x1
    8000359a:	120080e7          	jalr	288(ra) # 800046b6 <log_write>
  brelse(bp);
    8000359e:	854a                	mv	a0,s2
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	e92080e7          	jalr	-366(ra) # 80003432 <brelse>
}
    800035a8:	60e2                	ld	ra,24(sp)
    800035aa:	6442                	ld	s0,16(sp)
    800035ac:	64a2                	ld	s1,8(sp)
    800035ae:	6902                	ld	s2,0(sp)
    800035b0:	6105                	addi	sp,sp,32
    800035b2:	8082                	ret
    panic("freeing free block");
    800035b4:	00005517          	auipc	a0,0x5
    800035b8:	0bc50513          	addi	a0,a0,188 # 80008670 <syscalls+0x110>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	f88080e7          	jalr	-120(ra) # 80000544 <panic>

00000000800035c4 <balloc>:
{
    800035c4:	711d                	addi	sp,sp,-96
    800035c6:	ec86                	sd	ra,88(sp)
    800035c8:	e8a2                	sd	s0,80(sp)
    800035ca:	e4a6                	sd	s1,72(sp)
    800035cc:	e0ca                	sd	s2,64(sp)
    800035ce:	fc4e                	sd	s3,56(sp)
    800035d0:	f852                	sd	s4,48(sp)
    800035d2:	f456                	sd	s5,40(sp)
    800035d4:	f05a                	sd	s6,32(sp)
    800035d6:	ec5e                	sd	s7,24(sp)
    800035d8:	e862                	sd	s8,16(sp)
    800035da:	e466                	sd	s9,8(sp)
    800035dc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035de:	0001c797          	auipc	a5,0x1c
    800035e2:	bfe7a783          	lw	a5,-1026(a5) # 8001f1dc <sb+0x4>
    800035e6:	10078163          	beqz	a5,800036e8 <balloc+0x124>
    800035ea:	8baa                	mv	s7,a0
    800035ec:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035ee:	0001cb17          	auipc	s6,0x1c
    800035f2:	beab0b13          	addi	s6,s6,-1046 # 8001f1d8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035f6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035f8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035fa:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035fc:	6c89                	lui	s9,0x2
    800035fe:	a061                	j	80003686 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003600:	974a                	add	a4,a4,s2
    80003602:	8fd5                	or	a5,a5,a3
    80003604:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003608:	854a                	mv	a0,s2
    8000360a:	00001097          	auipc	ra,0x1
    8000360e:	0ac080e7          	jalr	172(ra) # 800046b6 <log_write>
        brelse(bp);
    80003612:	854a                	mv	a0,s2
    80003614:	00000097          	auipc	ra,0x0
    80003618:	e1e080e7          	jalr	-482(ra) # 80003432 <brelse>
  bp = bread(dev, bno);
    8000361c:	85a6                	mv	a1,s1
    8000361e:	855e                	mv	a0,s7
    80003620:	00000097          	auipc	ra,0x0
    80003624:	ce2080e7          	jalr	-798(ra) # 80003302 <bread>
    80003628:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000362a:	40000613          	li	a2,1024
    8000362e:	4581                	li	a1,0
    80003630:	05850513          	addi	a0,a0,88
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	77a080e7          	jalr	1914(ra) # 80000dae <memset>
  log_write(bp);
    8000363c:	854a                	mv	a0,s2
    8000363e:	00001097          	auipc	ra,0x1
    80003642:	078080e7          	jalr	120(ra) # 800046b6 <log_write>
  brelse(bp);
    80003646:	854a                	mv	a0,s2
    80003648:	00000097          	auipc	ra,0x0
    8000364c:	dea080e7          	jalr	-534(ra) # 80003432 <brelse>
}
    80003650:	8526                	mv	a0,s1
    80003652:	60e6                	ld	ra,88(sp)
    80003654:	6446                	ld	s0,80(sp)
    80003656:	64a6                	ld	s1,72(sp)
    80003658:	6906                	ld	s2,64(sp)
    8000365a:	79e2                	ld	s3,56(sp)
    8000365c:	7a42                	ld	s4,48(sp)
    8000365e:	7aa2                	ld	s5,40(sp)
    80003660:	7b02                	ld	s6,32(sp)
    80003662:	6be2                	ld	s7,24(sp)
    80003664:	6c42                	ld	s8,16(sp)
    80003666:	6ca2                	ld	s9,8(sp)
    80003668:	6125                	addi	sp,sp,96
    8000366a:	8082                	ret
    brelse(bp);
    8000366c:	854a                	mv	a0,s2
    8000366e:	00000097          	auipc	ra,0x0
    80003672:	dc4080e7          	jalr	-572(ra) # 80003432 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003676:	015c87bb          	addw	a5,s9,s5
    8000367a:	00078a9b          	sext.w	s5,a5
    8000367e:	004b2703          	lw	a4,4(s6)
    80003682:	06eaf363          	bgeu	s5,a4,800036e8 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003686:	41fad79b          	sraiw	a5,s5,0x1f
    8000368a:	0137d79b          	srliw	a5,a5,0x13
    8000368e:	015787bb          	addw	a5,a5,s5
    80003692:	40d7d79b          	sraiw	a5,a5,0xd
    80003696:	01cb2583          	lw	a1,28(s6)
    8000369a:	9dbd                	addw	a1,a1,a5
    8000369c:	855e                	mv	a0,s7
    8000369e:	00000097          	auipc	ra,0x0
    800036a2:	c64080e7          	jalr	-924(ra) # 80003302 <bread>
    800036a6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036a8:	004b2503          	lw	a0,4(s6)
    800036ac:	000a849b          	sext.w	s1,s5
    800036b0:	8662                	mv	a2,s8
    800036b2:	faa4fde3          	bgeu	s1,a0,8000366c <balloc+0xa8>
      m = 1 << (bi % 8);
    800036b6:	41f6579b          	sraiw	a5,a2,0x1f
    800036ba:	01d7d69b          	srliw	a3,a5,0x1d
    800036be:	00c6873b          	addw	a4,a3,a2
    800036c2:	00777793          	andi	a5,a4,7
    800036c6:	9f95                	subw	a5,a5,a3
    800036c8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036cc:	4037571b          	sraiw	a4,a4,0x3
    800036d0:	00e906b3          	add	a3,s2,a4
    800036d4:	0586c683          	lbu	a3,88(a3)
    800036d8:	00d7f5b3          	and	a1,a5,a3
    800036dc:	d195                	beqz	a1,80003600 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036de:	2605                	addiw	a2,a2,1
    800036e0:	2485                	addiw	s1,s1,1
    800036e2:	fd4618e3          	bne	a2,s4,800036b2 <balloc+0xee>
    800036e6:	b759                	j	8000366c <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800036e8:	00005517          	auipc	a0,0x5
    800036ec:	fa050513          	addi	a0,a0,-96 # 80008688 <syscalls+0x128>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	eb0080e7          	jalr	-336(ra) # 800005a0 <printf>
  return 0;
    800036f8:	4481                	li	s1,0
    800036fa:	bf99                	j	80003650 <balloc+0x8c>

00000000800036fc <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800036fc:	7179                	addi	sp,sp,-48
    800036fe:	f406                	sd	ra,40(sp)
    80003700:	f022                	sd	s0,32(sp)
    80003702:	ec26                	sd	s1,24(sp)
    80003704:	e84a                	sd	s2,16(sp)
    80003706:	e44e                	sd	s3,8(sp)
    80003708:	e052                	sd	s4,0(sp)
    8000370a:	1800                	addi	s0,sp,48
    8000370c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000370e:	47ad                	li	a5,11
    80003710:	02b7e763          	bltu	a5,a1,8000373e <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003714:	02059493          	slli	s1,a1,0x20
    80003718:	9081                	srli	s1,s1,0x20
    8000371a:	048a                	slli	s1,s1,0x2
    8000371c:	94aa                	add	s1,s1,a0
    8000371e:	0504a903          	lw	s2,80(s1)
    80003722:	06091e63          	bnez	s2,8000379e <bmap+0xa2>
      addr = balloc(ip->dev);
    80003726:	4108                	lw	a0,0(a0)
    80003728:	00000097          	auipc	ra,0x0
    8000372c:	e9c080e7          	jalr	-356(ra) # 800035c4 <balloc>
    80003730:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003734:	06090563          	beqz	s2,8000379e <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003738:	0524a823          	sw	s2,80(s1)
    8000373c:	a08d                	j	8000379e <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000373e:	ff45849b          	addiw	s1,a1,-12
    80003742:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003746:	0ff00793          	li	a5,255
    8000374a:	08e7e563          	bltu	a5,a4,800037d4 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000374e:	08052903          	lw	s2,128(a0)
    80003752:	00091d63          	bnez	s2,8000376c <bmap+0x70>
      addr = balloc(ip->dev);
    80003756:	4108                	lw	a0,0(a0)
    80003758:	00000097          	auipc	ra,0x0
    8000375c:	e6c080e7          	jalr	-404(ra) # 800035c4 <balloc>
    80003760:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003764:	02090d63          	beqz	s2,8000379e <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003768:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000376c:	85ca                	mv	a1,s2
    8000376e:	0009a503          	lw	a0,0(s3)
    80003772:	00000097          	auipc	ra,0x0
    80003776:	b90080e7          	jalr	-1136(ra) # 80003302 <bread>
    8000377a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000377c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003780:	02049593          	slli	a1,s1,0x20
    80003784:	9181                	srli	a1,a1,0x20
    80003786:	058a                	slli	a1,a1,0x2
    80003788:	00b784b3          	add	s1,a5,a1
    8000378c:	0004a903          	lw	s2,0(s1)
    80003790:	02090063          	beqz	s2,800037b0 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003794:	8552                	mv	a0,s4
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	c9c080e7          	jalr	-868(ra) # 80003432 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000379e:	854a                	mv	a0,s2
    800037a0:	70a2                	ld	ra,40(sp)
    800037a2:	7402                	ld	s0,32(sp)
    800037a4:	64e2                	ld	s1,24(sp)
    800037a6:	6942                	ld	s2,16(sp)
    800037a8:	69a2                	ld	s3,8(sp)
    800037aa:	6a02                	ld	s4,0(sp)
    800037ac:	6145                	addi	sp,sp,48
    800037ae:	8082                	ret
      addr = balloc(ip->dev);
    800037b0:	0009a503          	lw	a0,0(s3)
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	e10080e7          	jalr	-496(ra) # 800035c4 <balloc>
    800037bc:	0005091b          	sext.w	s2,a0
      if(addr){
    800037c0:	fc090ae3          	beqz	s2,80003794 <bmap+0x98>
        a[bn] = addr;
    800037c4:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800037c8:	8552                	mv	a0,s4
    800037ca:	00001097          	auipc	ra,0x1
    800037ce:	eec080e7          	jalr	-276(ra) # 800046b6 <log_write>
    800037d2:	b7c9                	j	80003794 <bmap+0x98>
  panic("bmap: out of range");
    800037d4:	00005517          	auipc	a0,0x5
    800037d8:	ecc50513          	addi	a0,a0,-308 # 800086a0 <syscalls+0x140>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	d68080e7          	jalr	-664(ra) # 80000544 <panic>

00000000800037e4 <iget>:
{
    800037e4:	7179                	addi	sp,sp,-48
    800037e6:	f406                	sd	ra,40(sp)
    800037e8:	f022                	sd	s0,32(sp)
    800037ea:	ec26                	sd	s1,24(sp)
    800037ec:	e84a                	sd	s2,16(sp)
    800037ee:	e44e                	sd	s3,8(sp)
    800037f0:	e052                	sd	s4,0(sp)
    800037f2:	1800                	addi	s0,sp,48
    800037f4:	89aa                	mv	s3,a0
    800037f6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037f8:	0001c517          	auipc	a0,0x1c
    800037fc:	a0050513          	addi	a0,a0,-1536 # 8001f1f8 <itable>
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	4b2080e7          	jalr	1202(ra) # 80000cb2 <acquire>
  empty = 0;
    80003808:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000380a:	0001c497          	auipc	s1,0x1c
    8000380e:	a0648493          	addi	s1,s1,-1530 # 8001f210 <itable+0x18>
    80003812:	0001d697          	auipc	a3,0x1d
    80003816:	48e68693          	addi	a3,a3,1166 # 80020ca0 <log>
    8000381a:	a039                	j	80003828 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000381c:	02090b63          	beqz	s2,80003852 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003820:	08848493          	addi	s1,s1,136
    80003824:	02d48a63          	beq	s1,a3,80003858 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003828:	449c                	lw	a5,8(s1)
    8000382a:	fef059e3          	blez	a5,8000381c <iget+0x38>
    8000382e:	4098                	lw	a4,0(s1)
    80003830:	ff3716e3          	bne	a4,s3,8000381c <iget+0x38>
    80003834:	40d8                	lw	a4,4(s1)
    80003836:	ff4713e3          	bne	a4,s4,8000381c <iget+0x38>
      ip->ref++;
    8000383a:	2785                	addiw	a5,a5,1
    8000383c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000383e:	0001c517          	auipc	a0,0x1c
    80003842:	9ba50513          	addi	a0,a0,-1606 # 8001f1f8 <itable>
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	520080e7          	jalr	1312(ra) # 80000d66 <release>
      return ip;
    8000384e:	8926                	mv	s2,s1
    80003850:	a03d                	j	8000387e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003852:	f7f9                	bnez	a5,80003820 <iget+0x3c>
    80003854:	8926                	mv	s2,s1
    80003856:	b7e9                	j	80003820 <iget+0x3c>
  if(empty == 0)
    80003858:	02090c63          	beqz	s2,80003890 <iget+0xac>
  ip->dev = dev;
    8000385c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003860:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003864:	4785                	li	a5,1
    80003866:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000386a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000386e:	0001c517          	auipc	a0,0x1c
    80003872:	98a50513          	addi	a0,a0,-1654 # 8001f1f8 <itable>
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	4f0080e7          	jalr	1264(ra) # 80000d66 <release>
}
    8000387e:	854a                	mv	a0,s2
    80003880:	70a2                	ld	ra,40(sp)
    80003882:	7402                	ld	s0,32(sp)
    80003884:	64e2                	ld	s1,24(sp)
    80003886:	6942                	ld	s2,16(sp)
    80003888:	69a2                	ld	s3,8(sp)
    8000388a:	6a02                	ld	s4,0(sp)
    8000388c:	6145                	addi	sp,sp,48
    8000388e:	8082                	ret
    panic("iget: no inodes");
    80003890:	00005517          	auipc	a0,0x5
    80003894:	e2850513          	addi	a0,a0,-472 # 800086b8 <syscalls+0x158>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	cac080e7          	jalr	-852(ra) # 80000544 <panic>

00000000800038a0 <fsinit>:
fsinit(int dev) {
    800038a0:	7179                	addi	sp,sp,-48
    800038a2:	f406                	sd	ra,40(sp)
    800038a4:	f022                	sd	s0,32(sp)
    800038a6:	ec26                	sd	s1,24(sp)
    800038a8:	e84a                	sd	s2,16(sp)
    800038aa:	e44e                	sd	s3,8(sp)
    800038ac:	1800                	addi	s0,sp,48
    800038ae:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038b0:	4585                	li	a1,1
    800038b2:	00000097          	auipc	ra,0x0
    800038b6:	a50080e7          	jalr	-1456(ra) # 80003302 <bread>
    800038ba:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038bc:	0001c997          	auipc	s3,0x1c
    800038c0:	91c98993          	addi	s3,s3,-1764 # 8001f1d8 <sb>
    800038c4:	02000613          	li	a2,32
    800038c8:	05850593          	addi	a1,a0,88
    800038cc:	854e                	mv	a0,s3
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	540080e7          	jalr	1344(ra) # 80000e0e <memmove>
  brelse(bp);
    800038d6:	8526                	mv	a0,s1
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	b5a080e7          	jalr	-1190(ra) # 80003432 <brelse>
  if(sb.magic != FSMAGIC)
    800038e0:	0009a703          	lw	a4,0(s3)
    800038e4:	102037b7          	lui	a5,0x10203
    800038e8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038ec:	02f71263          	bne	a4,a5,80003910 <fsinit+0x70>
  initlog(dev, &sb);
    800038f0:	0001c597          	auipc	a1,0x1c
    800038f4:	8e858593          	addi	a1,a1,-1816 # 8001f1d8 <sb>
    800038f8:	854a                	mv	a0,s2
    800038fa:	00001097          	auipc	ra,0x1
    800038fe:	b40080e7          	jalr	-1216(ra) # 8000443a <initlog>
}
    80003902:	70a2                	ld	ra,40(sp)
    80003904:	7402                	ld	s0,32(sp)
    80003906:	64e2                	ld	s1,24(sp)
    80003908:	6942                	ld	s2,16(sp)
    8000390a:	69a2                	ld	s3,8(sp)
    8000390c:	6145                	addi	sp,sp,48
    8000390e:	8082                	ret
    panic("invalid file system");
    80003910:	00005517          	auipc	a0,0x5
    80003914:	db850513          	addi	a0,a0,-584 # 800086c8 <syscalls+0x168>
    80003918:	ffffd097          	auipc	ra,0xffffd
    8000391c:	c2c080e7          	jalr	-980(ra) # 80000544 <panic>

0000000080003920 <iinit>:
{
    80003920:	7179                	addi	sp,sp,-48
    80003922:	f406                	sd	ra,40(sp)
    80003924:	f022                	sd	s0,32(sp)
    80003926:	ec26                	sd	s1,24(sp)
    80003928:	e84a                	sd	s2,16(sp)
    8000392a:	e44e                	sd	s3,8(sp)
    8000392c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000392e:	00005597          	auipc	a1,0x5
    80003932:	db258593          	addi	a1,a1,-590 # 800086e0 <syscalls+0x180>
    80003936:	0001c517          	auipc	a0,0x1c
    8000393a:	8c250513          	addi	a0,a0,-1854 # 8001f1f8 <itable>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	2e4080e7          	jalr	740(ra) # 80000c22 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003946:	0001c497          	auipc	s1,0x1c
    8000394a:	8da48493          	addi	s1,s1,-1830 # 8001f220 <itable+0x28>
    8000394e:	0001d997          	auipc	s3,0x1d
    80003952:	36298993          	addi	s3,s3,866 # 80020cb0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003956:	00005917          	auipc	s2,0x5
    8000395a:	d9290913          	addi	s2,s2,-622 # 800086e8 <syscalls+0x188>
    8000395e:	85ca                	mv	a1,s2
    80003960:	8526                	mv	a0,s1
    80003962:	00001097          	auipc	ra,0x1
    80003966:	e3a080e7          	jalr	-454(ra) # 8000479c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000396a:	08848493          	addi	s1,s1,136
    8000396e:	ff3498e3          	bne	s1,s3,8000395e <iinit+0x3e>
}
    80003972:	70a2                	ld	ra,40(sp)
    80003974:	7402                	ld	s0,32(sp)
    80003976:	64e2                	ld	s1,24(sp)
    80003978:	6942                	ld	s2,16(sp)
    8000397a:	69a2                	ld	s3,8(sp)
    8000397c:	6145                	addi	sp,sp,48
    8000397e:	8082                	ret

0000000080003980 <ialloc>:
{
    80003980:	715d                	addi	sp,sp,-80
    80003982:	e486                	sd	ra,72(sp)
    80003984:	e0a2                	sd	s0,64(sp)
    80003986:	fc26                	sd	s1,56(sp)
    80003988:	f84a                	sd	s2,48(sp)
    8000398a:	f44e                	sd	s3,40(sp)
    8000398c:	f052                	sd	s4,32(sp)
    8000398e:	ec56                	sd	s5,24(sp)
    80003990:	e85a                	sd	s6,16(sp)
    80003992:	e45e                	sd	s7,8(sp)
    80003994:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003996:	0001c717          	auipc	a4,0x1c
    8000399a:	84e72703          	lw	a4,-1970(a4) # 8001f1e4 <sb+0xc>
    8000399e:	4785                	li	a5,1
    800039a0:	04e7fa63          	bgeu	a5,a4,800039f4 <ialloc+0x74>
    800039a4:	8aaa                	mv	s5,a0
    800039a6:	8bae                	mv	s7,a1
    800039a8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039aa:	0001ca17          	auipc	s4,0x1c
    800039ae:	82ea0a13          	addi	s4,s4,-2002 # 8001f1d8 <sb>
    800039b2:	00048b1b          	sext.w	s6,s1
    800039b6:	0044d593          	srli	a1,s1,0x4
    800039ba:	018a2783          	lw	a5,24(s4)
    800039be:	9dbd                	addw	a1,a1,a5
    800039c0:	8556                	mv	a0,s5
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	940080e7          	jalr	-1728(ra) # 80003302 <bread>
    800039ca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039cc:	05850993          	addi	s3,a0,88
    800039d0:	00f4f793          	andi	a5,s1,15
    800039d4:	079a                	slli	a5,a5,0x6
    800039d6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039d8:	00099783          	lh	a5,0(s3)
    800039dc:	c3a1                	beqz	a5,80003a1c <ialloc+0x9c>
    brelse(bp);
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	a54080e7          	jalr	-1452(ra) # 80003432 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039e6:	0485                	addi	s1,s1,1
    800039e8:	00ca2703          	lw	a4,12(s4)
    800039ec:	0004879b          	sext.w	a5,s1
    800039f0:	fce7e1e3          	bltu	a5,a4,800039b2 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800039f4:	00005517          	auipc	a0,0x5
    800039f8:	cfc50513          	addi	a0,a0,-772 # 800086f0 <syscalls+0x190>
    800039fc:	ffffd097          	auipc	ra,0xffffd
    80003a00:	ba4080e7          	jalr	-1116(ra) # 800005a0 <printf>
  return 0;
    80003a04:	4501                	li	a0,0
}
    80003a06:	60a6                	ld	ra,72(sp)
    80003a08:	6406                	ld	s0,64(sp)
    80003a0a:	74e2                	ld	s1,56(sp)
    80003a0c:	7942                	ld	s2,48(sp)
    80003a0e:	79a2                	ld	s3,40(sp)
    80003a10:	7a02                	ld	s4,32(sp)
    80003a12:	6ae2                	ld	s5,24(sp)
    80003a14:	6b42                	ld	s6,16(sp)
    80003a16:	6ba2                	ld	s7,8(sp)
    80003a18:	6161                	addi	sp,sp,80
    80003a1a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003a1c:	04000613          	li	a2,64
    80003a20:	4581                	li	a1,0
    80003a22:	854e                	mv	a0,s3
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	38a080e7          	jalr	906(ra) # 80000dae <memset>
      dip->type = type;
    80003a2c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a30:	854a                	mv	a0,s2
    80003a32:	00001097          	auipc	ra,0x1
    80003a36:	c84080e7          	jalr	-892(ra) # 800046b6 <log_write>
      brelse(bp);
    80003a3a:	854a                	mv	a0,s2
    80003a3c:	00000097          	auipc	ra,0x0
    80003a40:	9f6080e7          	jalr	-1546(ra) # 80003432 <brelse>
      return iget(dev, inum);
    80003a44:	85da                	mv	a1,s6
    80003a46:	8556                	mv	a0,s5
    80003a48:	00000097          	auipc	ra,0x0
    80003a4c:	d9c080e7          	jalr	-612(ra) # 800037e4 <iget>
    80003a50:	bf5d                	j	80003a06 <ialloc+0x86>

0000000080003a52 <iupdate>:
{
    80003a52:	1101                	addi	sp,sp,-32
    80003a54:	ec06                	sd	ra,24(sp)
    80003a56:	e822                	sd	s0,16(sp)
    80003a58:	e426                	sd	s1,8(sp)
    80003a5a:	e04a                	sd	s2,0(sp)
    80003a5c:	1000                	addi	s0,sp,32
    80003a5e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a60:	415c                	lw	a5,4(a0)
    80003a62:	0047d79b          	srliw	a5,a5,0x4
    80003a66:	0001b597          	auipc	a1,0x1b
    80003a6a:	78a5a583          	lw	a1,1930(a1) # 8001f1f0 <sb+0x18>
    80003a6e:	9dbd                	addw	a1,a1,a5
    80003a70:	4108                	lw	a0,0(a0)
    80003a72:	00000097          	auipc	ra,0x0
    80003a76:	890080e7          	jalr	-1904(ra) # 80003302 <bread>
    80003a7a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a7c:	05850793          	addi	a5,a0,88
    80003a80:	40c8                	lw	a0,4(s1)
    80003a82:	893d                	andi	a0,a0,15
    80003a84:	051a                	slli	a0,a0,0x6
    80003a86:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a88:	04449703          	lh	a4,68(s1)
    80003a8c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a90:	04649703          	lh	a4,70(s1)
    80003a94:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a98:	04849703          	lh	a4,72(s1)
    80003a9c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003aa0:	04a49703          	lh	a4,74(s1)
    80003aa4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003aa8:	44f8                	lw	a4,76(s1)
    80003aaa:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003aac:	03400613          	li	a2,52
    80003ab0:	05048593          	addi	a1,s1,80
    80003ab4:	0531                	addi	a0,a0,12
    80003ab6:	ffffd097          	auipc	ra,0xffffd
    80003aba:	358080e7          	jalr	856(ra) # 80000e0e <memmove>
  log_write(bp);
    80003abe:	854a                	mv	a0,s2
    80003ac0:	00001097          	auipc	ra,0x1
    80003ac4:	bf6080e7          	jalr	-1034(ra) # 800046b6 <log_write>
  brelse(bp);
    80003ac8:	854a                	mv	a0,s2
    80003aca:	00000097          	auipc	ra,0x0
    80003ace:	968080e7          	jalr	-1688(ra) # 80003432 <brelse>
}
    80003ad2:	60e2                	ld	ra,24(sp)
    80003ad4:	6442                	ld	s0,16(sp)
    80003ad6:	64a2                	ld	s1,8(sp)
    80003ad8:	6902                	ld	s2,0(sp)
    80003ada:	6105                	addi	sp,sp,32
    80003adc:	8082                	ret

0000000080003ade <idup>:
{
    80003ade:	1101                	addi	sp,sp,-32
    80003ae0:	ec06                	sd	ra,24(sp)
    80003ae2:	e822                	sd	s0,16(sp)
    80003ae4:	e426                	sd	s1,8(sp)
    80003ae6:	1000                	addi	s0,sp,32
    80003ae8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aea:	0001b517          	auipc	a0,0x1b
    80003aee:	70e50513          	addi	a0,a0,1806 # 8001f1f8 <itable>
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	1c0080e7          	jalr	448(ra) # 80000cb2 <acquire>
  ip->ref++;
    80003afa:	449c                	lw	a5,8(s1)
    80003afc:	2785                	addiw	a5,a5,1
    80003afe:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b00:	0001b517          	auipc	a0,0x1b
    80003b04:	6f850513          	addi	a0,a0,1784 # 8001f1f8 <itable>
    80003b08:	ffffd097          	auipc	ra,0xffffd
    80003b0c:	25e080e7          	jalr	606(ra) # 80000d66 <release>
}
    80003b10:	8526                	mv	a0,s1
    80003b12:	60e2                	ld	ra,24(sp)
    80003b14:	6442                	ld	s0,16(sp)
    80003b16:	64a2                	ld	s1,8(sp)
    80003b18:	6105                	addi	sp,sp,32
    80003b1a:	8082                	ret

0000000080003b1c <ilock>:
{
    80003b1c:	1101                	addi	sp,sp,-32
    80003b1e:	ec06                	sd	ra,24(sp)
    80003b20:	e822                	sd	s0,16(sp)
    80003b22:	e426                	sd	s1,8(sp)
    80003b24:	e04a                	sd	s2,0(sp)
    80003b26:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b28:	c115                	beqz	a0,80003b4c <ilock+0x30>
    80003b2a:	84aa                	mv	s1,a0
    80003b2c:	451c                	lw	a5,8(a0)
    80003b2e:	00f05f63          	blez	a5,80003b4c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b32:	0541                	addi	a0,a0,16
    80003b34:	00001097          	auipc	ra,0x1
    80003b38:	ca2080e7          	jalr	-862(ra) # 800047d6 <acquiresleep>
  if(ip->valid == 0){
    80003b3c:	40bc                	lw	a5,64(s1)
    80003b3e:	cf99                	beqz	a5,80003b5c <ilock+0x40>
}
    80003b40:	60e2                	ld	ra,24(sp)
    80003b42:	6442                	ld	s0,16(sp)
    80003b44:	64a2                	ld	s1,8(sp)
    80003b46:	6902                	ld	s2,0(sp)
    80003b48:	6105                	addi	sp,sp,32
    80003b4a:	8082                	ret
    panic("ilock");
    80003b4c:	00005517          	auipc	a0,0x5
    80003b50:	bbc50513          	addi	a0,a0,-1092 # 80008708 <syscalls+0x1a8>
    80003b54:	ffffd097          	auipc	ra,0xffffd
    80003b58:	9f0080e7          	jalr	-1552(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b5c:	40dc                	lw	a5,4(s1)
    80003b5e:	0047d79b          	srliw	a5,a5,0x4
    80003b62:	0001b597          	auipc	a1,0x1b
    80003b66:	68e5a583          	lw	a1,1678(a1) # 8001f1f0 <sb+0x18>
    80003b6a:	9dbd                	addw	a1,a1,a5
    80003b6c:	4088                	lw	a0,0(s1)
    80003b6e:	fffff097          	auipc	ra,0xfffff
    80003b72:	794080e7          	jalr	1940(ra) # 80003302 <bread>
    80003b76:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b78:	05850593          	addi	a1,a0,88
    80003b7c:	40dc                	lw	a5,4(s1)
    80003b7e:	8bbd                	andi	a5,a5,15
    80003b80:	079a                	slli	a5,a5,0x6
    80003b82:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b84:	00059783          	lh	a5,0(a1)
    80003b88:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b8c:	00259783          	lh	a5,2(a1)
    80003b90:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b94:	00459783          	lh	a5,4(a1)
    80003b98:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b9c:	00659783          	lh	a5,6(a1)
    80003ba0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ba4:	459c                	lw	a5,8(a1)
    80003ba6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ba8:	03400613          	li	a2,52
    80003bac:	05b1                	addi	a1,a1,12
    80003bae:	05048513          	addi	a0,s1,80
    80003bb2:	ffffd097          	auipc	ra,0xffffd
    80003bb6:	25c080e7          	jalr	604(ra) # 80000e0e <memmove>
    brelse(bp);
    80003bba:	854a                	mv	a0,s2
    80003bbc:	00000097          	auipc	ra,0x0
    80003bc0:	876080e7          	jalr	-1930(ra) # 80003432 <brelse>
    ip->valid = 1;
    80003bc4:	4785                	li	a5,1
    80003bc6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003bc8:	04449783          	lh	a5,68(s1)
    80003bcc:	fbb5                	bnez	a5,80003b40 <ilock+0x24>
      panic("ilock: no type");
    80003bce:	00005517          	auipc	a0,0x5
    80003bd2:	b4250513          	addi	a0,a0,-1214 # 80008710 <syscalls+0x1b0>
    80003bd6:	ffffd097          	auipc	ra,0xffffd
    80003bda:	96e080e7          	jalr	-1682(ra) # 80000544 <panic>

0000000080003bde <iunlock>:
{
    80003bde:	1101                	addi	sp,sp,-32
    80003be0:	ec06                	sd	ra,24(sp)
    80003be2:	e822                	sd	s0,16(sp)
    80003be4:	e426                	sd	s1,8(sp)
    80003be6:	e04a                	sd	s2,0(sp)
    80003be8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003bea:	c905                	beqz	a0,80003c1a <iunlock+0x3c>
    80003bec:	84aa                	mv	s1,a0
    80003bee:	01050913          	addi	s2,a0,16
    80003bf2:	854a                	mv	a0,s2
    80003bf4:	00001097          	auipc	ra,0x1
    80003bf8:	c7c080e7          	jalr	-900(ra) # 80004870 <holdingsleep>
    80003bfc:	cd19                	beqz	a0,80003c1a <iunlock+0x3c>
    80003bfe:	449c                	lw	a5,8(s1)
    80003c00:	00f05d63          	blez	a5,80003c1a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c04:	854a                	mv	a0,s2
    80003c06:	00001097          	auipc	ra,0x1
    80003c0a:	c26080e7          	jalr	-986(ra) # 8000482c <releasesleep>
}
    80003c0e:	60e2                	ld	ra,24(sp)
    80003c10:	6442                	ld	s0,16(sp)
    80003c12:	64a2                	ld	s1,8(sp)
    80003c14:	6902                	ld	s2,0(sp)
    80003c16:	6105                	addi	sp,sp,32
    80003c18:	8082                	ret
    panic("iunlock");
    80003c1a:	00005517          	auipc	a0,0x5
    80003c1e:	b0650513          	addi	a0,a0,-1274 # 80008720 <syscalls+0x1c0>
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	922080e7          	jalr	-1758(ra) # 80000544 <panic>

0000000080003c2a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c2a:	7179                	addi	sp,sp,-48
    80003c2c:	f406                	sd	ra,40(sp)
    80003c2e:	f022                	sd	s0,32(sp)
    80003c30:	ec26                	sd	s1,24(sp)
    80003c32:	e84a                	sd	s2,16(sp)
    80003c34:	e44e                	sd	s3,8(sp)
    80003c36:	e052                	sd	s4,0(sp)
    80003c38:	1800                	addi	s0,sp,48
    80003c3a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c3c:	05050493          	addi	s1,a0,80
    80003c40:	08050913          	addi	s2,a0,128
    80003c44:	a021                	j	80003c4c <itrunc+0x22>
    80003c46:	0491                	addi	s1,s1,4
    80003c48:	01248d63          	beq	s1,s2,80003c62 <itrunc+0x38>
    if(ip->addrs[i]){
    80003c4c:	408c                	lw	a1,0(s1)
    80003c4e:	dde5                	beqz	a1,80003c46 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c50:	0009a503          	lw	a0,0(s3)
    80003c54:	00000097          	auipc	ra,0x0
    80003c58:	8f4080e7          	jalr	-1804(ra) # 80003548 <bfree>
      ip->addrs[i] = 0;
    80003c5c:	0004a023          	sw	zero,0(s1)
    80003c60:	b7dd                	j	80003c46 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c62:	0809a583          	lw	a1,128(s3)
    80003c66:	e185                	bnez	a1,80003c86 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c68:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c6c:	854e                	mv	a0,s3
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	de4080e7          	jalr	-540(ra) # 80003a52 <iupdate>
}
    80003c76:	70a2                	ld	ra,40(sp)
    80003c78:	7402                	ld	s0,32(sp)
    80003c7a:	64e2                	ld	s1,24(sp)
    80003c7c:	6942                	ld	s2,16(sp)
    80003c7e:	69a2                	ld	s3,8(sp)
    80003c80:	6a02                	ld	s4,0(sp)
    80003c82:	6145                	addi	sp,sp,48
    80003c84:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c86:	0009a503          	lw	a0,0(s3)
    80003c8a:	fffff097          	auipc	ra,0xfffff
    80003c8e:	678080e7          	jalr	1656(ra) # 80003302 <bread>
    80003c92:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c94:	05850493          	addi	s1,a0,88
    80003c98:	45850913          	addi	s2,a0,1112
    80003c9c:	a811                	j	80003cb0 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003c9e:	0009a503          	lw	a0,0(s3)
    80003ca2:	00000097          	auipc	ra,0x0
    80003ca6:	8a6080e7          	jalr	-1882(ra) # 80003548 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003caa:	0491                	addi	s1,s1,4
    80003cac:	01248563          	beq	s1,s2,80003cb6 <itrunc+0x8c>
      if(a[j])
    80003cb0:	408c                	lw	a1,0(s1)
    80003cb2:	dde5                	beqz	a1,80003caa <itrunc+0x80>
    80003cb4:	b7ed                	j	80003c9e <itrunc+0x74>
    brelse(bp);
    80003cb6:	8552                	mv	a0,s4
    80003cb8:	fffff097          	auipc	ra,0xfffff
    80003cbc:	77a080e7          	jalr	1914(ra) # 80003432 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003cc0:	0809a583          	lw	a1,128(s3)
    80003cc4:	0009a503          	lw	a0,0(s3)
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	880080e7          	jalr	-1920(ra) # 80003548 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cd0:	0809a023          	sw	zero,128(s3)
    80003cd4:	bf51                	j	80003c68 <itrunc+0x3e>

0000000080003cd6 <iput>:
{
    80003cd6:	1101                	addi	sp,sp,-32
    80003cd8:	ec06                	sd	ra,24(sp)
    80003cda:	e822                	sd	s0,16(sp)
    80003cdc:	e426                	sd	s1,8(sp)
    80003cde:	e04a                	sd	s2,0(sp)
    80003ce0:	1000                	addi	s0,sp,32
    80003ce2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ce4:	0001b517          	auipc	a0,0x1b
    80003ce8:	51450513          	addi	a0,a0,1300 # 8001f1f8 <itable>
    80003cec:	ffffd097          	auipc	ra,0xffffd
    80003cf0:	fc6080e7          	jalr	-58(ra) # 80000cb2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cf4:	4498                	lw	a4,8(s1)
    80003cf6:	4785                	li	a5,1
    80003cf8:	02f70363          	beq	a4,a5,80003d1e <iput+0x48>
  ip->ref--;
    80003cfc:	449c                	lw	a5,8(s1)
    80003cfe:	37fd                	addiw	a5,a5,-1
    80003d00:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d02:	0001b517          	auipc	a0,0x1b
    80003d06:	4f650513          	addi	a0,a0,1270 # 8001f1f8 <itable>
    80003d0a:	ffffd097          	auipc	ra,0xffffd
    80003d0e:	05c080e7          	jalr	92(ra) # 80000d66 <release>
}
    80003d12:	60e2                	ld	ra,24(sp)
    80003d14:	6442                	ld	s0,16(sp)
    80003d16:	64a2                	ld	s1,8(sp)
    80003d18:	6902                	ld	s2,0(sp)
    80003d1a:	6105                	addi	sp,sp,32
    80003d1c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d1e:	40bc                	lw	a5,64(s1)
    80003d20:	dff1                	beqz	a5,80003cfc <iput+0x26>
    80003d22:	04a49783          	lh	a5,74(s1)
    80003d26:	fbf9                	bnez	a5,80003cfc <iput+0x26>
    acquiresleep(&ip->lock);
    80003d28:	01048913          	addi	s2,s1,16
    80003d2c:	854a                	mv	a0,s2
    80003d2e:	00001097          	auipc	ra,0x1
    80003d32:	aa8080e7          	jalr	-1368(ra) # 800047d6 <acquiresleep>
    release(&itable.lock);
    80003d36:	0001b517          	auipc	a0,0x1b
    80003d3a:	4c250513          	addi	a0,a0,1218 # 8001f1f8 <itable>
    80003d3e:	ffffd097          	auipc	ra,0xffffd
    80003d42:	028080e7          	jalr	40(ra) # 80000d66 <release>
    itrunc(ip);
    80003d46:	8526                	mv	a0,s1
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	ee2080e7          	jalr	-286(ra) # 80003c2a <itrunc>
    ip->type = 0;
    80003d50:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d54:	8526                	mv	a0,s1
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	cfc080e7          	jalr	-772(ra) # 80003a52 <iupdate>
    ip->valid = 0;
    80003d5e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d62:	854a                	mv	a0,s2
    80003d64:	00001097          	auipc	ra,0x1
    80003d68:	ac8080e7          	jalr	-1336(ra) # 8000482c <releasesleep>
    acquire(&itable.lock);
    80003d6c:	0001b517          	auipc	a0,0x1b
    80003d70:	48c50513          	addi	a0,a0,1164 # 8001f1f8 <itable>
    80003d74:	ffffd097          	auipc	ra,0xffffd
    80003d78:	f3e080e7          	jalr	-194(ra) # 80000cb2 <acquire>
    80003d7c:	b741                	j	80003cfc <iput+0x26>

0000000080003d7e <iunlockput>:
{
    80003d7e:	1101                	addi	sp,sp,-32
    80003d80:	ec06                	sd	ra,24(sp)
    80003d82:	e822                	sd	s0,16(sp)
    80003d84:	e426                	sd	s1,8(sp)
    80003d86:	1000                	addi	s0,sp,32
    80003d88:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	e54080e7          	jalr	-428(ra) # 80003bde <iunlock>
  iput(ip);
    80003d92:	8526                	mv	a0,s1
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	f42080e7          	jalr	-190(ra) # 80003cd6 <iput>
}
    80003d9c:	60e2                	ld	ra,24(sp)
    80003d9e:	6442                	ld	s0,16(sp)
    80003da0:	64a2                	ld	s1,8(sp)
    80003da2:	6105                	addi	sp,sp,32
    80003da4:	8082                	ret

0000000080003da6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003da6:	1141                	addi	sp,sp,-16
    80003da8:	e422                	sd	s0,8(sp)
    80003daa:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003dac:	411c                	lw	a5,0(a0)
    80003dae:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003db0:	415c                	lw	a5,4(a0)
    80003db2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003db4:	04451783          	lh	a5,68(a0)
    80003db8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003dbc:	04a51783          	lh	a5,74(a0)
    80003dc0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003dc4:	04c56783          	lwu	a5,76(a0)
    80003dc8:	e99c                	sd	a5,16(a1)
}
    80003dca:	6422                	ld	s0,8(sp)
    80003dcc:	0141                	addi	sp,sp,16
    80003dce:	8082                	ret

0000000080003dd0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dd0:	457c                	lw	a5,76(a0)
    80003dd2:	0ed7e963          	bltu	a5,a3,80003ec4 <readi+0xf4>
{
    80003dd6:	7159                	addi	sp,sp,-112
    80003dd8:	f486                	sd	ra,104(sp)
    80003dda:	f0a2                	sd	s0,96(sp)
    80003ddc:	eca6                	sd	s1,88(sp)
    80003dde:	e8ca                	sd	s2,80(sp)
    80003de0:	e4ce                	sd	s3,72(sp)
    80003de2:	e0d2                	sd	s4,64(sp)
    80003de4:	fc56                	sd	s5,56(sp)
    80003de6:	f85a                	sd	s6,48(sp)
    80003de8:	f45e                	sd	s7,40(sp)
    80003dea:	f062                	sd	s8,32(sp)
    80003dec:	ec66                	sd	s9,24(sp)
    80003dee:	e86a                	sd	s10,16(sp)
    80003df0:	e46e                	sd	s11,8(sp)
    80003df2:	1880                	addi	s0,sp,112
    80003df4:	8b2a                	mv	s6,a0
    80003df6:	8bae                	mv	s7,a1
    80003df8:	8a32                	mv	s4,a2
    80003dfa:	84b6                	mv	s1,a3
    80003dfc:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003dfe:	9f35                	addw	a4,a4,a3
    return 0;
    80003e00:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e02:	0ad76063          	bltu	a4,a3,80003ea2 <readi+0xd2>
  if(off + n > ip->size)
    80003e06:	00e7f463          	bgeu	a5,a4,80003e0e <readi+0x3e>
    n = ip->size - off;
    80003e0a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e0e:	0a0a8963          	beqz	s5,80003ec0 <readi+0xf0>
    80003e12:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e14:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e18:	5c7d                	li	s8,-1
    80003e1a:	a82d                	j	80003e54 <readi+0x84>
    80003e1c:	020d1d93          	slli	s11,s10,0x20
    80003e20:	020ddd93          	srli	s11,s11,0x20
    80003e24:	05890613          	addi	a2,s2,88
    80003e28:	86ee                	mv	a3,s11
    80003e2a:	963a                	add	a2,a2,a4
    80003e2c:	85d2                	mv	a1,s4
    80003e2e:	855e                	mv	a0,s7
    80003e30:	fffff097          	auipc	ra,0xfffff
    80003e34:	8c8080e7          	jalr	-1848(ra) # 800026f8 <either_copyout>
    80003e38:	05850d63          	beq	a0,s8,80003e92 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e3c:	854a                	mv	a0,s2
    80003e3e:	fffff097          	auipc	ra,0xfffff
    80003e42:	5f4080e7          	jalr	1524(ra) # 80003432 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e46:	013d09bb          	addw	s3,s10,s3
    80003e4a:	009d04bb          	addw	s1,s10,s1
    80003e4e:	9a6e                	add	s4,s4,s11
    80003e50:	0559f763          	bgeu	s3,s5,80003e9e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003e54:	00a4d59b          	srliw	a1,s1,0xa
    80003e58:	855a                	mv	a0,s6
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	8a2080e7          	jalr	-1886(ra) # 800036fc <bmap>
    80003e62:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e66:	cd85                	beqz	a1,80003e9e <readi+0xce>
    bp = bread(ip->dev, addr);
    80003e68:	000b2503          	lw	a0,0(s6)
    80003e6c:	fffff097          	auipc	ra,0xfffff
    80003e70:	496080e7          	jalr	1174(ra) # 80003302 <bread>
    80003e74:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e76:	3ff4f713          	andi	a4,s1,1023
    80003e7a:	40ec87bb          	subw	a5,s9,a4
    80003e7e:	413a86bb          	subw	a3,s5,s3
    80003e82:	8d3e                	mv	s10,a5
    80003e84:	2781                	sext.w	a5,a5
    80003e86:	0006861b          	sext.w	a2,a3
    80003e8a:	f8f679e3          	bgeu	a2,a5,80003e1c <readi+0x4c>
    80003e8e:	8d36                	mv	s10,a3
    80003e90:	b771                	j	80003e1c <readi+0x4c>
      brelse(bp);
    80003e92:	854a                	mv	a0,s2
    80003e94:	fffff097          	auipc	ra,0xfffff
    80003e98:	59e080e7          	jalr	1438(ra) # 80003432 <brelse>
      tot = -1;
    80003e9c:	59fd                	li	s3,-1
  }
  return tot;
    80003e9e:	0009851b          	sext.w	a0,s3
}
    80003ea2:	70a6                	ld	ra,104(sp)
    80003ea4:	7406                	ld	s0,96(sp)
    80003ea6:	64e6                	ld	s1,88(sp)
    80003ea8:	6946                	ld	s2,80(sp)
    80003eaa:	69a6                	ld	s3,72(sp)
    80003eac:	6a06                	ld	s4,64(sp)
    80003eae:	7ae2                	ld	s5,56(sp)
    80003eb0:	7b42                	ld	s6,48(sp)
    80003eb2:	7ba2                	ld	s7,40(sp)
    80003eb4:	7c02                	ld	s8,32(sp)
    80003eb6:	6ce2                	ld	s9,24(sp)
    80003eb8:	6d42                	ld	s10,16(sp)
    80003eba:	6da2                	ld	s11,8(sp)
    80003ebc:	6165                	addi	sp,sp,112
    80003ebe:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ec0:	89d6                	mv	s3,s5
    80003ec2:	bff1                	j	80003e9e <readi+0xce>
    return 0;
    80003ec4:	4501                	li	a0,0
}
    80003ec6:	8082                	ret

0000000080003ec8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ec8:	457c                	lw	a5,76(a0)
    80003eca:	10d7e863          	bltu	a5,a3,80003fda <writei+0x112>
{
    80003ece:	7159                	addi	sp,sp,-112
    80003ed0:	f486                	sd	ra,104(sp)
    80003ed2:	f0a2                	sd	s0,96(sp)
    80003ed4:	eca6                	sd	s1,88(sp)
    80003ed6:	e8ca                	sd	s2,80(sp)
    80003ed8:	e4ce                	sd	s3,72(sp)
    80003eda:	e0d2                	sd	s4,64(sp)
    80003edc:	fc56                	sd	s5,56(sp)
    80003ede:	f85a                	sd	s6,48(sp)
    80003ee0:	f45e                	sd	s7,40(sp)
    80003ee2:	f062                	sd	s8,32(sp)
    80003ee4:	ec66                	sd	s9,24(sp)
    80003ee6:	e86a                	sd	s10,16(sp)
    80003ee8:	e46e                	sd	s11,8(sp)
    80003eea:	1880                	addi	s0,sp,112
    80003eec:	8aaa                	mv	s5,a0
    80003eee:	8bae                	mv	s7,a1
    80003ef0:	8a32                	mv	s4,a2
    80003ef2:	8936                	mv	s2,a3
    80003ef4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ef6:	00e687bb          	addw	a5,a3,a4
    80003efa:	0ed7e263          	bltu	a5,a3,80003fde <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003efe:	00043737          	lui	a4,0x43
    80003f02:	0ef76063          	bltu	a4,a5,80003fe2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f06:	0c0b0863          	beqz	s6,80003fd6 <writei+0x10e>
    80003f0a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f0c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f10:	5c7d                	li	s8,-1
    80003f12:	a091                	j	80003f56 <writei+0x8e>
    80003f14:	020d1d93          	slli	s11,s10,0x20
    80003f18:	020ddd93          	srli	s11,s11,0x20
    80003f1c:	05848513          	addi	a0,s1,88
    80003f20:	86ee                	mv	a3,s11
    80003f22:	8652                	mv	a2,s4
    80003f24:	85de                	mv	a1,s7
    80003f26:	953a                	add	a0,a0,a4
    80003f28:	fffff097          	auipc	ra,0xfffff
    80003f2c:	826080e7          	jalr	-2010(ra) # 8000274e <either_copyin>
    80003f30:	07850263          	beq	a0,s8,80003f94 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f34:	8526                	mv	a0,s1
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	780080e7          	jalr	1920(ra) # 800046b6 <log_write>
    brelse(bp);
    80003f3e:	8526                	mv	a0,s1
    80003f40:	fffff097          	auipc	ra,0xfffff
    80003f44:	4f2080e7          	jalr	1266(ra) # 80003432 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f48:	013d09bb          	addw	s3,s10,s3
    80003f4c:	012d093b          	addw	s2,s10,s2
    80003f50:	9a6e                	add	s4,s4,s11
    80003f52:	0569f663          	bgeu	s3,s6,80003f9e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003f56:	00a9559b          	srliw	a1,s2,0xa
    80003f5a:	8556                	mv	a0,s5
    80003f5c:	fffff097          	auipc	ra,0xfffff
    80003f60:	7a0080e7          	jalr	1952(ra) # 800036fc <bmap>
    80003f64:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f68:	c99d                	beqz	a1,80003f9e <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003f6a:	000aa503          	lw	a0,0(s5)
    80003f6e:	fffff097          	auipc	ra,0xfffff
    80003f72:	394080e7          	jalr	916(ra) # 80003302 <bread>
    80003f76:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f78:	3ff97713          	andi	a4,s2,1023
    80003f7c:	40ec87bb          	subw	a5,s9,a4
    80003f80:	413b06bb          	subw	a3,s6,s3
    80003f84:	8d3e                	mv	s10,a5
    80003f86:	2781                	sext.w	a5,a5
    80003f88:	0006861b          	sext.w	a2,a3
    80003f8c:	f8f674e3          	bgeu	a2,a5,80003f14 <writei+0x4c>
    80003f90:	8d36                	mv	s10,a3
    80003f92:	b749                	j	80003f14 <writei+0x4c>
      brelse(bp);
    80003f94:	8526                	mv	a0,s1
    80003f96:	fffff097          	auipc	ra,0xfffff
    80003f9a:	49c080e7          	jalr	1180(ra) # 80003432 <brelse>
  }

  if(off > ip->size)
    80003f9e:	04caa783          	lw	a5,76(s5)
    80003fa2:	0127f463          	bgeu	a5,s2,80003faa <writei+0xe2>
    ip->size = off;
    80003fa6:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003faa:	8556                	mv	a0,s5
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	aa6080e7          	jalr	-1370(ra) # 80003a52 <iupdate>

  return tot;
    80003fb4:	0009851b          	sext.w	a0,s3
}
    80003fb8:	70a6                	ld	ra,104(sp)
    80003fba:	7406                	ld	s0,96(sp)
    80003fbc:	64e6                	ld	s1,88(sp)
    80003fbe:	6946                	ld	s2,80(sp)
    80003fc0:	69a6                	ld	s3,72(sp)
    80003fc2:	6a06                	ld	s4,64(sp)
    80003fc4:	7ae2                	ld	s5,56(sp)
    80003fc6:	7b42                	ld	s6,48(sp)
    80003fc8:	7ba2                	ld	s7,40(sp)
    80003fca:	7c02                	ld	s8,32(sp)
    80003fcc:	6ce2                	ld	s9,24(sp)
    80003fce:	6d42                	ld	s10,16(sp)
    80003fd0:	6da2                	ld	s11,8(sp)
    80003fd2:	6165                	addi	sp,sp,112
    80003fd4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fd6:	89da                	mv	s3,s6
    80003fd8:	bfc9                	j	80003faa <writei+0xe2>
    return -1;
    80003fda:	557d                	li	a0,-1
}
    80003fdc:	8082                	ret
    return -1;
    80003fde:	557d                	li	a0,-1
    80003fe0:	bfe1                	j	80003fb8 <writei+0xf0>
    return -1;
    80003fe2:	557d                	li	a0,-1
    80003fe4:	bfd1                	j	80003fb8 <writei+0xf0>

0000000080003fe6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fe6:	1141                	addi	sp,sp,-16
    80003fe8:	e406                	sd	ra,8(sp)
    80003fea:	e022                	sd	s0,0(sp)
    80003fec:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fee:	4639                	li	a2,14
    80003ff0:	ffffd097          	auipc	ra,0xffffd
    80003ff4:	e96080e7          	jalr	-362(ra) # 80000e86 <strncmp>
}
    80003ff8:	60a2                	ld	ra,8(sp)
    80003ffa:	6402                	ld	s0,0(sp)
    80003ffc:	0141                	addi	sp,sp,16
    80003ffe:	8082                	ret

0000000080004000 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004000:	7139                	addi	sp,sp,-64
    80004002:	fc06                	sd	ra,56(sp)
    80004004:	f822                	sd	s0,48(sp)
    80004006:	f426                	sd	s1,40(sp)
    80004008:	f04a                	sd	s2,32(sp)
    8000400a:	ec4e                	sd	s3,24(sp)
    8000400c:	e852                	sd	s4,16(sp)
    8000400e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004010:	04451703          	lh	a4,68(a0)
    80004014:	4785                	li	a5,1
    80004016:	00f71a63          	bne	a4,a5,8000402a <dirlookup+0x2a>
    8000401a:	892a                	mv	s2,a0
    8000401c:	89ae                	mv	s3,a1
    8000401e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004020:	457c                	lw	a5,76(a0)
    80004022:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004024:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004026:	e79d                	bnez	a5,80004054 <dirlookup+0x54>
    80004028:	a8a5                	j	800040a0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000402a:	00004517          	auipc	a0,0x4
    8000402e:	6fe50513          	addi	a0,a0,1790 # 80008728 <syscalls+0x1c8>
    80004032:	ffffc097          	auipc	ra,0xffffc
    80004036:	512080e7          	jalr	1298(ra) # 80000544 <panic>
      panic("dirlookup read");
    8000403a:	00004517          	auipc	a0,0x4
    8000403e:	70650513          	addi	a0,a0,1798 # 80008740 <syscalls+0x1e0>
    80004042:	ffffc097          	auipc	ra,0xffffc
    80004046:	502080e7          	jalr	1282(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000404a:	24c1                	addiw	s1,s1,16
    8000404c:	04c92783          	lw	a5,76(s2)
    80004050:	04f4f763          	bgeu	s1,a5,8000409e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004054:	4741                	li	a4,16
    80004056:	86a6                	mv	a3,s1
    80004058:	fc040613          	addi	a2,s0,-64
    8000405c:	4581                	li	a1,0
    8000405e:	854a                	mv	a0,s2
    80004060:	00000097          	auipc	ra,0x0
    80004064:	d70080e7          	jalr	-656(ra) # 80003dd0 <readi>
    80004068:	47c1                	li	a5,16
    8000406a:	fcf518e3          	bne	a0,a5,8000403a <dirlookup+0x3a>
    if(de.inum == 0)
    8000406e:	fc045783          	lhu	a5,-64(s0)
    80004072:	dfe1                	beqz	a5,8000404a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004074:	fc240593          	addi	a1,s0,-62
    80004078:	854e                	mv	a0,s3
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	f6c080e7          	jalr	-148(ra) # 80003fe6 <namecmp>
    80004082:	f561                	bnez	a0,8000404a <dirlookup+0x4a>
      if(poff)
    80004084:	000a0463          	beqz	s4,8000408c <dirlookup+0x8c>
        *poff = off;
    80004088:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000408c:	fc045583          	lhu	a1,-64(s0)
    80004090:	00092503          	lw	a0,0(s2)
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	750080e7          	jalr	1872(ra) # 800037e4 <iget>
    8000409c:	a011                	j	800040a0 <dirlookup+0xa0>
  return 0;
    8000409e:	4501                	li	a0,0
}
    800040a0:	70e2                	ld	ra,56(sp)
    800040a2:	7442                	ld	s0,48(sp)
    800040a4:	74a2                	ld	s1,40(sp)
    800040a6:	7902                	ld	s2,32(sp)
    800040a8:	69e2                	ld	s3,24(sp)
    800040aa:	6a42                	ld	s4,16(sp)
    800040ac:	6121                	addi	sp,sp,64
    800040ae:	8082                	ret

00000000800040b0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040b0:	711d                	addi	sp,sp,-96
    800040b2:	ec86                	sd	ra,88(sp)
    800040b4:	e8a2                	sd	s0,80(sp)
    800040b6:	e4a6                	sd	s1,72(sp)
    800040b8:	e0ca                	sd	s2,64(sp)
    800040ba:	fc4e                	sd	s3,56(sp)
    800040bc:	f852                	sd	s4,48(sp)
    800040be:	f456                	sd	s5,40(sp)
    800040c0:	f05a                	sd	s6,32(sp)
    800040c2:	ec5e                	sd	s7,24(sp)
    800040c4:	e862                	sd	s8,16(sp)
    800040c6:	e466                	sd	s9,8(sp)
    800040c8:	1080                	addi	s0,sp,96
    800040ca:	84aa                	mv	s1,a0
    800040cc:	8b2e                	mv	s6,a1
    800040ce:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040d0:	00054703          	lbu	a4,0(a0)
    800040d4:	02f00793          	li	a5,47
    800040d8:	02f70363          	beq	a4,a5,800040fe <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040dc:	ffffe097          	auipc	ra,0xffffe
    800040e0:	ab0080e7          	jalr	-1360(ra) # 80001b8c <myproc>
    800040e4:	15053503          	ld	a0,336(a0)
    800040e8:	00000097          	auipc	ra,0x0
    800040ec:	9f6080e7          	jalr	-1546(ra) # 80003ade <idup>
    800040f0:	89aa                	mv	s3,a0
  while(*path == '/')
    800040f2:	02f00913          	li	s2,47
  len = path - s;
    800040f6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800040f8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040fa:	4c05                	li	s8,1
    800040fc:	a865                	j	800041b4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800040fe:	4585                	li	a1,1
    80004100:	4505                	li	a0,1
    80004102:	fffff097          	auipc	ra,0xfffff
    80004106:	6e2080e7          	jalr	1762(ra) # 800037e4 <iget>
    8000410a:	89aa                	mv	s3,a0
    8000410c:	b7dd                	j	800040f2 <namex+0x42>
      iunlockput(ip);
    8000410e:	854e                	mv	a0,s3
    80004110:	00000097          	auipc	ra,0x0
    80004114:	c6e080e7          	jalr	-914(ra) # 80003d7e <iunlockput>
      return 0;
    80004118:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000411a:	854e                	mv	a0,s3
    8000411c:	60e6                	ld	ra,88(sp)
    8000411e:	6446                	ld	s0,80(sp)
    80004120:	64a6                	ld	s1,72(sp)
    80004122:	6906                	ld	s2,64(sp)
    80004124:	79e2                	ld	s3,56(sp)
    80004126:	7a42                	ld	s4,48(sp)
    80004128:	7aa2                	ld	s5,40(sp)
    8000412a:	7b02                	ld	s6,32(sp)
    8000412c:	6be2                	ld	s7,24(sp)
    8000412e:	6c42                	ld	s8,16(sp)
    80004130:	6ca2                	ld	s9,8(sp)
    80004132:	6125                	addi	sp,sp,96
    80004134:	8082                	ret
      iunlock(ip);
    80004136:	854e                	mv	a0,s3
    80004138:	00000097          	auipc	ra,0x0
    8000413c:	aa6080e7          	jalr	-1370(ra) # 80003bde <iunlock>
      return ip;
    80004140:	bfe9                	j	8000411a <namex+0x6a>
      iunlockput(ip);
    80004142:	854e                	mv	a0,s3
    80004144:	00000097          	auipc	ra,0x0
    80004148:	c3a080e7          	jalr	-966(ra) # 80003d7e <iunlockput>
      return 0;
    8000414c:	89d2                	mv	s3,s4
    8000414e:	b7f1                	j	8000411a <namex+0x6a>
  len = path - s;
    80004150:	40b48633          	sub	a2,s1,a1
    80004154:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004158:	094cd463          	bge	s9,s4,800041e0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000415c:	4639                	li	a2,14
    8000415e:	8556                	mv	a0,s5
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	cae080e7          	jalr	-850(ra) # 80000e0e <memmove>
  while(*path == '/')
    80004168:	0004c783          	lbu	a5,0(s1)
    8000416c:	01279763          	bne	a5,s2,8000417a <namex+0xca>
    path++;
    80004170:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004172:	0004c783          	lbu	a5,0(s1)
    80004176:	ff278de3          	beq	a5,s2,80004170 <namex+0xc0>
    ilock(ip);
    8000417a:	854e                	mv	a0,s3
    8000417c:	00000097          	auipc	ra,0x0
    80004180:	9a0080e7          	jalr	-1632(ra) # 80003b1c <ilock>
    if(ip->type != T_DIR){
    80004184:	04499783          	lh	a5,68(s3)
    80004188:	f98793e3          	bne	a5,s8,8000410e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000418c:	000b0563          	beqz	s6,80004196 <namex+0xe6>
    80004190:	0004c783          	lbu	a5,0(s1)
    80004194:	d3cd                	beqz	a5,80004136 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004196:	865e                	mv	a2,s7
    80004198:	85d6                	mv	a1,s5
    8000419a:	854e                	mv	a0,s3
    8000419c:	00000097          	auipc	ra,0x0
    800041a0:	e64080e7          	jalr	-412(ra) # 80004000 <dirlookup>
    800041a4:	8a2a                	mv	s4,a0
    800041a6:	dd51                	beqz	a0,80004142 <namex+0x92>
    iunlockput(ip);
    800041a8:	854e                	mv	a0,s3
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	bd4080e7          	jalr	-1068(ra) # 80003d7e <iunlockput>
    ip = next;
    800041b2:	89d2                	mv	s3,s4
  while(*path == '/')
    800041b4:	0004c783          	lbu	a5,0(s1)
    800041b8:	05279763          	bne	a5,s2,80004206 <namex+0x156>
    path++;
    800041bc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041be:	0004c783          	lbu	a5,0(s1)
    800041c2:	ff278de3          	beq	a5,s2,800041bc <namex+0x10c>
  if(*path == 0)
    800041c6:	c79d                	beqz	a5,800041f4 <namex+0x144>
    path++;
    800041c8:	85a6                	mv	a1,s1
  len = path - s;
    800041ca:	8a5e                	mv	s4,s7
    800041cc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041ce:	01278963          	beq	a5,s2,800041e0 <namex+0x130>
    800041d2:	dfbd                	beqz	a5,80004150 <namex+0xa0>
    path++;
    800041d4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800041d6:	0004c783          	lbu	a5,0(s1)
    800041da:	ff279ce3          	bne	a5,s2,800041d2 <namex+0x122>
    800041de:	bf8d                	j	80004150 <namex+0xa0>
    memmove(name, s, len);
    800041e0:	2601                	sext.w	a2,a2
    800041e2:	8556                	mv	a0,s5
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	c2a080e7          	jalr	-982(ra) # 80000e0e <memmove>
    name[len] = 0;
    800041ec:	9a56                	add	s4,s4,s5
    800041ee:	000a0023          	sb	zero,0(s4)
    800041f2:	bf9d                	j	80004168 <namex+0xb8>
  if(nameiparent){
    800041f4:	f20b03e3          	beqz	s6,8000411a <namex+0x6a>
    iput(ip);
    800041f8:	854e                	mv	a0,s3
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	adc080e7          	jalr	-1316(ra) # 80003cd6 <iput>
    return 0;
    80004202:	4981                	li	s3,0
    80004204:	bf19                	j	8000411a <namex+0x6a>
  if(*path == 0)
    80004206:	d7fd                	beqz	a5,800041f4 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004208:	0004c783          	lbu	a5,0(s1)
    8000420c:	85a6                	mv	a1,s1
    8000420e:	b7d1                	j	800041d2 <namex+0x122>

0000000080004210 <dirlink>:
{
    80004210:	7139                	addi	sp,sp,-64
    80004212:	fc06                	sd	ra,56(sp)
    80004214:	f822                	sd	s0,48(sp)
    80004216:	f426                	sd	s1,40(sp)
    80004218:	f04a                	sd	s2,32(sp)
    8000421a:	ec4e                	sd	s3,24(sp)
    8000421c:	e852                	sd	s4,16(sp)
    8000421e:	0080                	addi	s0,sp,64
    80004220:	892a                	mv	s2,a0
    80004222:	8a2e                	mv	s4,a1
    80004224:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004226:	4601                	li	a2,0
    80004228:	00000097          	auipc	ra,0x0
    8000422c:	dd8080e7          	jalr	-552(ra) # 80004000 <dirlookup>
    80004230:	e93d                	bnez	a0,800042a6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004232:	04c92483          	lw	s1,76(s2)
    80004236:	c49d                	beqz	s1,80004264 <dirlink+0x54>
    80004238:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000423a:	4741                	li	a4,16
    8000423c:	86a6                	mv	a3,s1
    8000423e:	fc040613          	addi	a2,s0,-64
    80004242:	4581                	li	a1,0
    80004244:	854a                	mv	a0,s2
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	b8a080e7          	jalr	-1142(ra) # 80003dd0 <readi>
    8000424e:	47c1                	li	a5,16
    80004250:	06f51163          	bne	a0,a5,800042b2 <dirlink+0xa2>
    if(de.inum == 0)
    80004254:	fc045783          	lhu	a5,-64(s0)
    80004258:	c791                	beqz	a5,80004264 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000425a:	24c1                	addiw	s1,s1,16
    8000425c:	04c92783          	lw	a5,76(s2)
    80004260:	fcf4ede3          	bltu	s1,a5,8000423a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004264:	4639                	li	a2,14
    80004266:	85d2                	mv	a1,s4
    80004268:	fc240513          	addi	a0,s0,-62
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	c56080e7          	jalr	-938(ra) # 80000ec2 <strncpy>
  de.inum = inum;
    80004274:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004278:	4741                	li	a4,16
    8000427a:	86a6                	mv	a3,s1
    8000427c:	fc040613          	addi	a2,s0,-64
    80004280:	4581                	li	a1,0
    80004282:	854a                	mv	a0,s2
    80004284:	00000097          	auipc	ra,0x0
    80004288:	c44080e7          	jalr	-956(ra) # 80003ec8 <writei>
    8000428c:	1541                	addi	a0,a0,-16
    8000428e:	00a03533          	snez	a0,a0
    80004292:	40a00533          	neg	a0,a0
}
    80004296:	70e2                	ld	ra,56(sp)
    80004298:	7442                	ld	s0,48(sp)
    8000429a:	74a2                	ld	s1,40(sp)
    8000429c:	7902                	ld	s2,32(sp)
    8000429e:	69e2                	ld	s3,24(sp)
    800042a0:	6a42                	ld	s4,16(sp)
    800042a2:	6121                	addi	sp,sp,64
    800042a4:	8082                	ret
    iput(ip);
    800042a6:	00000097          	auipc	ra,0x0
    800042aa:	a30080e7          	jalr	-1488(ra) # 80003cd6 <iput>
    return -1;
    800042ae:	557d                	li	a0,-1
    800042b0:	b7dd                	j	80004296 <dirlink+0x86>
      panic("dirlink read");
    800042b2:	00004517          	auipc	a0,0x4
    800042b6:	49e50513          	addi	a0,a0,1182 # 80008750 <syscalls+0x1f0>
    800042ba:	ffffc097          	auipc	ra,0xffffc
    800042be:	28a080e7          	jalr	650(ra) # 80000544 <panic>

00000000800042c2 <namei>:

struct inode*
namei(char *path)
{
    800042c2:	1101                	addi	sp,sp,-32
    800042c4:	ec06                	sd	ra,24(sp)
    800042c6:	e822                	sd	s0,16(sp)
    800042c8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042ca:	fe040613          	addi	a2,s0,-32
    800042ce:	4581                	li	a1,0
    800042d0:	00000097          	auipc	ra,0x0
    800042d4:	de0080e7          	jalr	-544(ra) # 800040b0 <namex>
}
    800042d8:	60e2                	ld	ra,24(sp)
    800042da:	6442                	ld	s0,16(sp)
    800042dc:	6105                	addi	sp,sp,32
    800042de:	8082                	ret

00000000800042e0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042e0:	1141                	addi	sp,sp,-16
    800042e2:	e406                	sd	ra,8(sp)
    800042e4:	e022                	sd	s0,0(sp)
    800042e6:	0800                	addi	s0,sp,16
    800042e8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042ea:	4585                	li	a1,1
    800042ec:	00000097          	auipc	ra,0x0
    800042f0:	dc4080e7          	jalr	-572(ra) # 800040b0 <namex>
}
    800042f4:	60a2                	ld	ra,8(sp)
    800042f6:	6402                	ld	s0,0(sp)
    800042f8:	0141                	addi	sp,sp,16
    800042fa:	8082                	ret

00000000800042fc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042fc:	1101                	addi	sp,sp,-32
    800042fe:	ec06                	sd	ra,24(sp)
    80004300:	e822                	sd	s0,16(sp)
    80004302:	e426                	sd	s1,8(sp)
    80004304:	e04a                	sd	s2,0(sp)
    80004306:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004308:	0001d917          	auipc	s2,0x1d
    8000430c:	99890913          	addi	s2,s2,-1640 # 80020ca0 <log>
    80004310:	01892583          	lw	a1,24(s2)
    80004314:	02892503          	lw	a0,40(s2)
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	fea080e7          	jalr	-22(ra) # 80003302 <bread>
    80004320:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004322:	02c92683          	lw	a3,44(s2)
    80004326:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004328:	02d05763          	blez	a3,80004356 <write_head+0x5a>
    8000432c:	0001d797          	auipc	a5,0x1d
    80004330:	9a478793          	addi	a5,a5,-1628 # 80020cd0 <log+0x30>
    80004334:	05c50713          	addi	a4,a0,92
    80004338:	36fd                	addiw	a3,a3,-1
    8000433a:	1682                	slli	a3,a3,0x20
    8000433c:	9281                	srli	a3,a3,0x20
    8000433e:	068a                	slli	a3,a3,0x2
    80004340:	0001d617          	auipc	a2,0x1d
    80004344:	99460613          	addi	a2,a2,-1644 # 80020cd4 <log+0x34>
    80004348:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000434a:	4390                	lw	a2,0(a5)
    8000434c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000434e:	0791                	addi	a5,a5,4
    80004350:	0711                	addi	a4,a4,4
    80004352:	fed79ce3          	bne	a5,a3,8000434a <write_head+0x4e>
  }
  bwrite(buf);
    80004356:	8526                	mv	a0,s1
    80004358:	fffff097          	auipc	ra,0xfffff
    8000435c:	09c080e7          	jalr	156(ra) # 800033f4 <bwrite>
  brelse(buf);
    80004360:	8526                	mv	a0,s1
    80004362:	fffff097          	auipc	ra,0xfffff
    80004366:	0d0080e7          	jalr	208(ra) # 80003432 <brelse>
}
    8000436a:	60e2                	ld	ra,24(sp)
    8000436c:	6442                	ld	s0,16(sp)
    8000436e:	64a2                	ld	s1,8(sp)
    80004370:	6902                	ld	s2,0(sp)
    80004372:	6105                	addi	sp,sp,32
    80004374:	8082                	ret

0000000080004376 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004376:	0001d797          	auipc	a5,0x1d
    8000437a:	9567a783          	lw	a5,-1706(a5) # 80020ccc <log+0x2c>
    8000437e:	0af05d63          	blez	a5,80004438 <install_trans+0xc2>
{
    80004382:	7139                	addi	sp,sp,-64
    80004384:	fc06                	sd	ra,56(sp)
    80004386:	f822                	sd	s0,48(sp)
    80004388:	f426                	sd	s1,40(sp)
    8000438a:	f04a                	sd	s2,32(sp)
    8000438c:	ec4e                	sd	s3,24(sp)
    8000438e:	e852                	sd	s4,16(sp)
    80004390:	e456                	sd	s5,8(sp)
    80004392:	e05a                	sd	s6,0(sp)
    80004394:	0080                	addi	s0,sp,64
    80004396:	8b2a                	mv	s6,a0
    80004398:	0001da97          	auipc	s5,0x1d
    8000439c:	938a8a93          	addi	s5,s5,-1736 # 80020cd0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043a2:	0001d997          	auipc	s3,0x1d
    800043a6:	8fe98993          	addi	s3,s3,-1794 # 80020ca0 <log>
    800043aa:	a035                	j	800043d6 <install_trans+0x60>
      bunpin(dbuf);
    800043ac:	8526                	mv	a0,s1
    800043ae:	fffff097          	auipc	ra,0xfffff
    800043b2:	15e080e7          	jalr	350(ra) # 8000350c <bunpin>
    brelse(lbuf);
    800043b6:	854a                	mv	a0,s2
    800043b8:	fffff097          	auipc	ra,0xfffff
    800043bc:	07a080e7          	jalr	122(ra) # 80003432 <brelse>
    brelse(dbuf);
    800043c0:	8526                	mv	a0,s1
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	070080e7          	jalr	112(ra) # 80003432 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ca:	2a05                	addiw	s4,s4,1
    800043cc:	0a91                	addi	s5,s5,4
    800043ce:	02c9a783          	lw	a5,44(s3)
    800043d2:	04fa5963          	bge	s4,a5,80004424 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043d6:	0189a583          	lw	a1,24(s3)
    800043da:	014585bb          	addw	a1,a1,s4
    800043de:	2585                	addiw	a1,a1,1
    800043e0:	0289a503          	lw	a0,40(s3)
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	f1e080e7          	jalr	-226(ra) # 80003302 <bread>
    800043ec:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043ee:	000aa583          	lw	a1,0(s5)
    800043f2:	0289a503          	lw	a0,40(s3)
    800043f6:	fffff097          	auipc	ra,0xfffff
    800043fa:	f0c080e7          	jalr	-244(ra) # 80003302 <bread>
    800043fe:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004400:	40000613          	li	a2,1024
    80004404:	05890593          	addi	a1,s2,88
    80004408:	05850513          	addi	a0,a0,88
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	a02080e7          	jalr	-1534(ra) # 80000e0e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004414:	8526                	mv	a0,s1
    80004416:	fffff097          	auipc	ra,0xfffff
    8000441a:	fde080e7          	jalr	-34(ra) # 800033f4 <bwrite>
    if(recovering == 0)
    8000441e:	f80b1ce3          	bnez	s6,800043b6 <install_trans+0x40>
    80004422:	b769                	j	800043ac <install_trans+0x36>
}
    80004424:	70e2                	ld	ra,56(sp)
    80004426:	7442                	ld	s0,48(sp)
    80004428:	74a2                	ld	s1,40(sp)
    8000442a:	7902                	ld	s2,32(sp)
    8000442c:	69e2                	ld	s3,24(sp)
    8000442e:	6a42                	ld	s4,16(sp)
    80004430:	6aa2                	ld	s5,8(sp)
    80004432:	6b02                	ld	s6,0(sp)
    80004434:	6121                	addi	sp,sp,64
    80004436:	8082                	ret
    80004438:	8082                	ret

000000008000443a <initlog>:
{
    8000443a:	7179                	addi	sp,sp,-48
    8000443c:	f406                	sd	ra,40(sp)
    8000443e:	f022                	sd	s0,32(sp)
    80004440:	ec26                	sd	s1,24(sp)
    80004442:	e84a                	sd	s2,16(sp)
    80004444:	e44e                	sd	s3,8(sp)
    80004446:	1800                	addi	s0,sp,48
    80004448:	892a                	mv	s2,a0
    8000444a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000444c:	0001d497          	auipc	s1,0x1d
    80004450:	85448493          	addi	s1,s1,-1964 # 80020ca0 <log>
    80004454:	00004597          	auipc	a1,0x4
    80004458:	30c58593          	addi	a1,a1,780 # 80008760 <syscalls+0x200>
    8000445c:	8526                	mv	a0,s1
    8000445e:	ffffc097          	auipc	ra,0xffffc
    80004462:	7c4080e7          	jalr	1988(ra) # 80000c22 <initlock>
  log.start = sb->logstart;
    80004466:	0149a583          	lw	a1,20(s3)
    8000446a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000446c:	0109a783          	lw	a5,16(s3)
    80004470:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004472:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004476:	854a                	mv	a0,s2
    80004478:	fffff097          	auipc	ra,0xfffff
    8000447c:	e8a080e7          	jalr	-374(ra) # 80003302 <bread>
  log.lh.n = lh->n;
    80004480:	4d3c                	lw	a5,88(a0)
    80004482:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004484:	02f05563          	blez	a5,800044ae <initlog+0x74>
    80004488:	05c50713          	addi	a4,a0,92
    8000448c:	0001d697          	auipc	a3,0x1d
    80004490:	84468693          	addi	a3,a3,-1980 # 80020cd0 <log+0x30>
    80004494:	37fd                	addiw	a5,a5,-1
    80004496:	1782                	slli	a5,a5,0x20
    80004498:	9381                	srli	a5,a5,0x20
    8000449a:	078a                	slli	a5,a5,0x2
    8000449c:	06050613          	addi	a2,a0,96
    800044a0:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800044a2:	4310                	lw	a2,0(a4)
    800044a4:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800044a6:	0711                	addi	a4,a4,4
    800044a8:	0691                	addi	a3,a3,4
    800044aa:	fef71ce3          	bne	a4,a5,800044a2 <initlog+0x68>
  brelse(buf);
    800044ae:	fffff097          	auipc	ra,0xfffff
    800044b2:	f84080e7          	jalr	-124(ra) # 80003432 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044b6:	4505                	li	a0,1
    800044b8:	00000097          	auipc	ra,0x0
    800044bc:	ebe080e7          	jalr	-322(ra) # 80004376 <install_trans>
  log.lh.n = 0;
    800044c0:	0001d797          	auipc	a5,0x1d
    800044c4:	8007a623          	sw	zero,-2036(a5) # 80020ccc <log+0x2c>
  write_head(); // clear the log
    800044c8:	00000097          	auipc	ra,0x0
    800044cc:	e34080e7          	jalr	-460(ra) # 800042fc <write_head>
}
    800044d0:	70a2                	ld	ra,40(sp)
    800044d2:	7402                	ld	s0,32(sp)
    800044d4:	64e2                	ld	s1,24(sp)
    800044d6:	6942                	ld	s2,16(sp)
    800044d8:	69a2                	ld	s3,8(sp)
    800044da:	6145                	addi	sp,sp,48
    800044dc:	8082                	ret

00000000800044de <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044de:	1101                	addi	sp,sp,-32
    800044e0:	ec06                	sd	ra,24(sp)
    800044e2:	e822                	sd	s0,16(sp)
    800044e4:	e426                	sd	s1,8(sp)
    800044e6:	e04a                	sd	s2,0(sp)
    800044e8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044ea:	0001c517          	auipc	a0,0x1c
    800044ee:	7b650513          	addi	a0,a0,1974 # 80020ca0 <log>
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	7c0080e7          	jalr	1984(ra) # 80000cb2 <acquire>
  while(1){
    if(log.committing){
    800044fa:	0001c497          	auipc	s1,0x1c
    800044fe:	7a648493          	addi	s1,s1,1958 # 80020ca0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004502:	4979                	li	s2,30
    80004504:	a039                	j	80004512 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004506:	85a6                	mv	a1,s1
    80004508:	8526                	mv	a0,s1
    8000450a:	ffffe097          	auipc	ra,0xffffe
    8000450e:	de6080e7          	jalr	-538(ra) # 800022f0 <sleep>
    if(log.committing){
    80004512:	50dc                	lw	a5,36(s1)
    80004514:	fbed                	bnez	a5,80004506 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004516:	509c                	lw	a5,32(s1)
    80004518:	0017871b          	addiw	a4,a5,1
    8000451c:	0007069b          	sext.w	a3,a4
    80004520:	0027179b          	slliw	a5,a4,0x2
    80004524:	9fb9                	addw	a5,a5,a4
    80004526:	0017979b          	slliw	a5,a5,0x1
    8000452a:	54d8                	lw	a4,44(s1)
    8000452c:	9fb9                	addw	a5,a5,a4
    8000452e:	00f95963          	bge	s2,a5,80004540 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004532:	85a6                	mv	a1,s1
    80004534:	8526                	mv	a0,s1
    80004536:	ffffe097          	auipc	ra,0xffffe
    8000453a:	dba080e7          	jalr	-582(ra) # 800022f0 <sleep>
    8000453e:	bfd1                	j	80004512 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004540:	0001c517          	auipc	a0,0x1c
    80004544:	76050513          	addi	a0,a0,1888 # 80020ca0 <log>
    80004548:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000454a:	ffffd097          	auipc	ra,0xffffd
    8000454e:	81c080e7          	jalr	-2020(ra) # 80000d66 <release>
      break;
    }
  }
}
    80004552:	60e2                	ld	ra,24(sp)
    80004554:	6442                	ld	s0,16(sp)
    80004556:	64a2                	ld	s1,8(sp)
    80004558:	6902                	ld	s2,0(sp)
    8000455a:	6105                	addi	sp,sp,32
    8000455c:	8082                	ret

000000008000455e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000455e:	7139                	addi	sp,sp,-64
    80004560:	fc06                	sd	ra,56(sp)
    80004562:	f822                	sd	s0,48(sp)
    80004564:	f426                	sd	s1,40(sp)
    80004566:	f04a                	sd	s2,32(sp)
    80004568:	ec4e                	sd	s3,24(sp)
    8000456a:	e852                	sd	s4,16(sp)
    8000456c:	e456                	sd	s5,8(sp)
    8000456e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004570:	0001c497          	auipc	s1,0x1c
    80004574:	73048493          	addi	s1,s1,1840 # 80020ca0 <log>
    80004578:	8526                	mv	a0,s1
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	738080e7          	jalr	1848(ra) # 80000cb2 <acquire>
  log.outstanding -= 1;
    80004582:	509c                	lw	a5,32(s1)
    80004584:	37fd                	addiw	a5,a5,-1
    80004586:	0007891b          	sext.w	s2,a5
    8000458a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000458c:	50dc                	lw	a5,36(s1)
    8000458e:	efb9                	bnez	a5,800045ec <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004590:	06091663          	bnez	s2,800045fc <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004594:	0001c497          	auipc	s1,0x1c
    80004598:	70c48493          	addi	s1,s1,1804 # 80020ca0 <log>
    8000459c:	4785                	li	a5,1
    8000459e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045a0:	8526                	mv	a0,s1
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	7c4080e7          	jalr	1988(ra) # 80000d66 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045aa:	54dc                	lw	a5,44(s1)
    800045ac:	06f04763          	bgtz	a5,8000461a <end_op+0xbc>
    acquire(&log.lock);
    800045b0:	0001c497          	auipc	s1,0x1c
    800045b4:	6f048493          	addi	s1,s1,1776 # 80020ca0 <log>
    800045b8:	8526                	mv	a0,s1
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	6f8080e7          	jalr	1784(ra) # 80000cb2 <acquire>
    log.committing = 0;
    800045c2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045c6:	8526                	mv	a0,s1
    800045c8:	ffffe097          	auipc	ra,0xffffe
    800045cc:	d8c080e7          	jalr	-628(ra) # 80002354 <wakeup>
    release(&log.lock);
    800045d0:	8526                	mv	a0,s1
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	794080e7          	jalr	1940(ra) # 80000d66 <release>
}
    800045da:	70e2                	ld	ra,56(sp)
    800045dc:	7442                	ld	s0,48(sp)
    800045de:	74a2                	ld	s1,40(sp)
    800045e0:	7902                	ld	s2,32(sp)
    800045e2:	69e2                	ld	s3,24(sp)
    800045e4:	6a42                	ld	s4,16(sp)
    800045e6:	6aa2                	ld	s5,8(sp)
    800045e8:	6121                	addi	sp,sp,64
    800045ea:	8082                	ret
    panic("log.committing");
    800045ec:	00004517          	auipc	a0,0x4
    800045f0:	17c50513          	addi	a0,a0,380 # 80008768 <syscalls+0x208>
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	f50080e7          	jalr	-176(ra) # 80000544 <panic>
    wakeup(&log);
    800045fc:	0001c497          	auipc	s1,0x1c
    80004600:	6a448493          	addi	s1,s1,1700 # 80020ca0 <log>
    80004604:	8526                	mv	a0,s1
    80004606:	ffffe097          	auipc	ra,0xffffe
    8000460a:	d4e080e7          	jalr	-690(ra) # 80002354 <wakeup>
  release(&log.lock);
    8000460e:	8526                	mv	a0,s1
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	756080e7          	jalr	1878(ra) # 80000d66 <release>
  if(do_commit){
    80004618:	b7c9                	j	800045da <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000461a:	0001ca97          	auipc	s5,0x1c
    8000461e:	6b6a8a93          	addi	s5,s5,1718 # 80020cd0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004622:	0001ca17          	auipc	s4,0x1c
    80004626:	67ea0a13          	addi	s4,s4,1662 # 80020ca0 <log>
    8000462a:	018a2583          	lw	a1,24(s4)
    8000462e:	012585bb          	addw	a1,a1,s2
    80004632:	2585                	addiw	a1,a1,1
    80004634:	028a2503          	lw	a0,40(s4)
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	cca080e7          	jalr	-822(ra) # 80003302 <bread>
    80004640:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004642:	000aa583          	lw	a1,0(s5)
    80004646:	028a2503          	lw	a0,40(s4)
    8000464a:	fffff097          	auipc	ra,0xfffff
    8000464e:	cb8080e7          	jalr	-840(ra) # 80003302 <bread>
    80004652:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004654:	40000613          	li	a2,1024
    80004658:	05850593          	addi	a1,a0,88
    8000465c:	05848513          	addi	a0,s1,88
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	7ae080e7          	jalr	1966(ra) # 80000e0e <memmove>
    bwrite(to);  // write the log
    80004668:	8526                	mv	a0,s1
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	d8a080e7          	jalr	-630(ra) # 800033f4 <bwrite>
    brelse(from);
    80004672:	854e                	mv	a0,s3
    80004674:	fffff097          	auipc	ra,0xfffff
    80004678:	dbe080e7          	jalr	-578(ra) # 80003432 <brelse>
    brelse(to);
    8000467c:	8526                	mv	a0,s1
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	db4080e7          	jalr	-588(ra) # 80003432 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004686:	2905                	addiw	s2,s2,1
    80004688:	0a91                	addi	s5,s5,4
    8000468a:	02ca2783          	lw	a5,44(s4)
    8000468e:	f8f94ee3          	blt	s2,a5,8000462a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004692:	00000097          	auipc	ra,0x0
    80004696:	c6a080e7          	jalr	-918(ra) # 800042fc <write_head>
    install_trans(0); // Now install writes to home locations
    8000469a:	4501                	li	a0,0
    8000469c:	00000097          	auipc	ra,0x0
    800046a0:	cda080e7          	jalr	-806(ra) # 80004376 <install_trans>
    log.lh.n = 0;
    800046a4:	0001c797          	auipc	a5,0x1c
    800046a8:	6207a423          	sw	zero,1576(a5) # 80020ccc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046ac:	00000097          	auipc	ra,0x0
    800046b0:	c50080e7          	jalr	-944(ra) # 800042fc <write_head>
    800046b4:	bdf5                	j	800045b0 <end_op+0x52>

00000000800046b6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046b6:	1101                	addi	sp,sp,-32
    800046b8:	ec06                	sd	ra,24(sp)
    800046ba:	e822                	sd	s0,16(sp)
    800046bc:	e426                	sd	s1,8(sp)
    800046be:	e04a                	sd	s2,0(sp)
    800046c0:	1000                	addi	s0,sp,32
    800046c2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046c4:	0001c917          	auipc	s2,0x1c
    800046c8:	5dc90913          	addi	s2,s2,1500 # 80020ca0 <log>
    800046cc:	854a                	mv	a0,s2
    800046ce:	ffffc097          	auipc	ra,0xffffc
    800046d2:	5e4080e7          	jalr	1508(ra) # 80000cb2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046d6:	02c92603          	lw	a2,44(s2)
    800046da:	47f5                	li	a5,29
    800046dc:	06c7c563          	blt	a5,a2,80004746 <log_write+0x90>
    800046e0:	0001c797          	auipc	a5,0x1c
    800046e4:	5dc7a783          	lw	a5,1500(a5) # 80020cbc <log+0x1c>
    800046e8:	37fd                	addiw	a5,a5,-1
    800046ea:	04f65e63          	bge	a2,a5,80004746 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046ee:	0001c797          	auipc	a5,0x1c
    800046f2:	5d27a783          	lw	a5,1490(a5) # 80020cc0 <log+0x20>
    800046f6:	06f05063          	blez	a5,80004756 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046fa:	4781                	li	a5,0
    800046fc:	06c05563          	blez	a2,80004766 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004700:	44cc                	lw	a1,12(s1)
    80004702:	0001c717          	auipc	a4,0x1c
    80004706:	5ce70713          	addi	a4,a4,1486 # 80020cd0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000470a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000470c:	4314                	lw	a3,0(a4)
    8000470e:	04b68c63          	beq	a3,a1,80004766 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004712:	2785                	addiw	a5,a5,1
    80004714:	0711                	addi	a4,a4,4
    80004716:	fef61be3          	bne	a2,a5,8000470c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000471a:	0621                	addi	a2,a2,8
    8000471c:	060a                	slli	a2,a2,0x2
    8000471e:	0001c797          	auipc	a5,0x1c
    80004722:	58278793          	addi	a5,a5,1410 # 80020ca0 <log>
    80004726:	963e                	add	a2,a2,a5
    80004728:	44dc                	lw	a5,12(s1)
    8000472a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000472c:	8526                	mv	a0,s1
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	da2080e7          	jalr	-606(ra) # 800034d0 <bpin>
    log.lh.n++;
    80004736:	0001c717          	auipc	a4,0x1c
    8000473a:	56a70713          	addi	a4,a4,1386 # 80020ca0 <log>
    8000473e:	575c                	lw	a5,44(a4)
    80004740:	2785                	addiw	a5,a5,1
    80004742:	d75c                	sw	a5,44(a4)
    80004744:	a835                	j	80004780 <log_write+0xca>
    panic("too big a transaction");
    80004746:	00004517          	auipc	a0,0x4
    8000474a:	03250513          	addi	a0,a0,50 # 80008778 <syscalls+0x218>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	df6080e7          	jalr	-522(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004756:	00004517          	auipc	a0,0x4
    8000475a:	03a50513          	addi	a0,a0,58 # 80008790 <syscalls+0x230>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	de6080e7          	jalr	-538(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004766:	00878713          	addi	a4,a5,8
    8000476a:	00271693          	slli	a3,a4,0x2
    8000476e:	0001c717          	auipc	a4,0x1c
    80004772:	53270713          	addi	a4,a4,1330 # 80020ca0 <log>
    80004776:	9736                	add	a4,a4,a3
    80004778:	44d4                	lw	a3,12(s1)
    8000477a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000477c:	faf608e3          	beq	a2,a5,8000472c <log_write+0x76>
  }
  release(&log.lock);
    80004780:	0001c517          	auipc	a0,0x1c
    80004784:	52050513          	addi	a0,a0,1312 # 80020ca0 <log>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	5de080e7          	jalr	1502(ra) # 80000d66 <release>
}
    80004790:	60e2                	ld	ra,24(sp)
    80004792:	6442                	ld	s0,16(sp)
    80004794:	64a2                	ld	s1,8(sp)
    80004796:	6902                	ld	s2,0(sp)
    80004798:	6105                	addi	sp,sp,32
    8000479a:	8082                	ret

000000008000479c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000479c:	1101                	addi	sp,sp,-32
    8000479e:	ec06                	sd	ra,24(sp)
    800047a0:	e822                	sd	s0,16(sp)
    800047a2:	e426                	sd	s1,8(sp)
    800047a4:	e04a                	sd	s2,0(sp)
    800047a6:	1000                	addi	s0,sp,32
    800047a8:	84aa                	mv	s1,a0
    800047aa:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047ac:	00004597          	auipc	a1,0x4
    800047b0:	00458593          	addi	a1,a1,4 # 800087b0 <syscalls+0x250>
    800047b4:	0521                	addi	a0,a0,8
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	46c080e7          	jalr	1132(ra) # 80000c22 <initlock>
  lk->name = name;
    800047be:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047c2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047c6:	0204a423          	sw	zero,40(s1)
}
    800047ca:	60e2                	ld	ra,24(sp)
    800047cc:	6442                	ld	s0,16(sp)
    800047ce:	64a2                	ld	s1,8(sp)
    800047d0:	6902                	ld	s2,0(sp)
    800047d2:	6105                	addi	sp,sp,32
    800047d4:	8082                	ret

00000000800047d6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047d6:	1101                	addi	sp,sp,-32
    800047d8:	ec06                	sd	ra,24(sp)
    800047da:	e822                	sd	s0,16(sp)
    800047dc:	e426                	sd	s1,8(sp)
    800047de:	e04a                	sd	s2,0(sp)
    800047e0:	1000                	addi	s0,sp,32
    800047e2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047e4:	00850913          	addi	s2,a0,8
    800047e8:	854a                	mv	a0,s2
    800047ea:	ffffc097          	auipc	ra,0xffffc
    800047ee:	4c8080e7          	jalr	1224(ra) # 80000cb2 <acquire>
  while (lk->locked) {
    800047f2:	409c                	lw	a5,0(s1)
    800047f4:	cb89                	beqz	a5,80004806 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047f6:	85ca                	mv	a1,s2
    800047f8:	8526                	mv	a0,s1
    800047fa:	ffffe097          	auipc	ra,0xffffe
    800047fe:	af6080e7          	jalr	-1290(ra) # 800022f0 <sleep>
  while (lk->locked) {
    80004802:	409c                	lw	a5,0(s1)
    80004804:	fbed                	bnez	a5,800047f6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004806:	4785                	li	a5,1
    80004808:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000480a:	ffffd097          	auipc	ra,0xffffd
    8000480e:	382080e7          	jalr	898(ra) # 80001b8c <myproc>
    80004812:	591c                	lw	a5,48(a0)
    80004814:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004816:	854a                	mv	a0,s2
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	54e080e7          	jalr	1358(ra) # 80000d66 <release>
}
    80004820:	60e2                	ld	ra,24(sp)
    80004822:	6442                	ld	s0,16(sp)
    80004824:	64a2                	ld	s1,8(sp)
    80004826:	6902                	ld	s2,0(sp)
    80004828:	6105                	addi	sp,sp,32
    8000482a:	8082                	ret

000000008000482c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000482c:	1101                	addi	sp,sp,-32
    8000482e:	ec06                	sd	ra,24(sp)
    80004830:	e822                	sd	s0,16(sp)
    80004832:	e426                	sd	s1,8(sp)
    80004834:	e04a                	sd	s2,0(sp)
    80004836:	1000                	addi	s0,sp,32
    80004838:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000483a:	00850913          	addi	s2,a0,8
    8000483e:	854a                	mv	a0,s2
    80004840:	ffffc097          	auipc	ra,0xffffc
    80004844:	472080e7          	jalr	1138(ra) # 80000cb2 <acquire>
  lk->locked = 0;
    80004848:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000484c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004850:	8526                	mv	a0,s1
    80004852:	ffffe097          	auipc	ra,0xffffe
    80004856:	b02080e7          	jalr	-1278(ra) # 80002354 <wakeup>
  release(&lk->lk);
    8000485a:	854a                	mv	a0,s2
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	50a080e7          	jalr	1290(ra) # 80000d66 <release>
}
    80004864:	60e2                	ld	ra,24(sp)
    80004866:	6442                	ld	s0,16(sp)
    80004868:	64a2                	ld	s1,8(sp)
    8000486a:	6902                	ld	s2,0(sp)
    8000486c:	6105                	addi	sp,sp,32
    8000486e:	8082                	ret

0000000080004870 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004870:	7179                	addi	sp,sp,-48
    80004872:	f406                	sd	ra,40(sp)
    80004874:	f022                	sd	s0,32(sp)
    80004876:	ec26                	sd	s1,24(sp)
    80004878:	e84a                	sd	s2,16(sp)
    8000487a:	e44e                	sd	s3,8(sp)
    8000487c:	1800                	addi	s0,sp,48
    8000487e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004880:	00850913          	addi	s2,a0,8
    80004884:	854a                	mv	a0,s2
    80004886:	ffffc097          	auipc	ra,0xffffc
    8000488a:	42c080e7          	jalr	1068(ra) # 80000cb2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000488e:	409c                	lw	a5,0(s1)
    80004890:	ef99                	bnez	a5,800048ae <holdingsleep+0x3e>
    80004892:	4481                	li	s1,0
  release(&lk->lk);
    80004894:	854a                	mv	a0,s2
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	4d0080e7          	jalr	1232(ra) # 80000d66 <release>
  return r;
}
    8000489e:	8526                	mv	a0,s1
    800048a0:	70a2                	ld	ra,40(sp)
    800048a2:	7402                	ld	s0,32(sp)
    800048a4:	64e2                	ld	s1,24(sp)
    800048a6:	6942                	ld	s2,16(sp)
    800048a8:	69a2                	ld	s3,8(sp)
    800048aa:	6145                	addi	sp,sp,48
    800048ac:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048ae:	0284a983          	lw	s3,40(s1)
    800048b2:	ffffd097          	auipc	ra,0xffffd
    800048b6:	2da080e7          	jalr	730(ra) # 80001b8c <myproc>
    800048ba:	5904                	lw	s1,48(a0)
    800048bc:	413484b3          	sub	s1,s1,s3
    800048c0:	0014b493          	seqz	s1,s1
    800048c4:	bfc1                	j	80004894 <holdingsleep+0x24>

00000000800048c6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048c6:	1141                	addi	sp,sp,-16
    800048c8:	e406                	sd	ra,8(sp)
    800048ca:	e022                	sd	s0,0(sp)
    800048cc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048ce:	00004597          	auipc	a1,0x4
    800048d2:	ef258593          	addi	a1,a1,-270 # 800087c0 <syscalls+0x260>
    800048d6:	0001c517          	auipc	a0,0x1c
    800048da:	51250513          	addi	a0,a0,1298 # 80020de8 <ftable>
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	344080e7          	jalr	836(ra) # 80000c22 <initlock>
}
    800048e6:	60a2                	ld	ra,8(sp)
    800048e8:	6402                	ld	s0,0(sp)
    800048ea:	0141                	addi	sp,sp,16
    800048ec:	8082                	ret

00000000800048ee <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048ee:	1101                	addi	sp,sp,-32
    800048f0:	ec06                	sd	ra,24(sp)
    800048f2:	e822                	sd	s0,16(sp)
    800048f4:	e426                	sd	s1,8(sp)
    800048f6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048f8:	0001c517          	auipc	a0,0x1c
    800048fc:	4f050513          	addi	a0,a0,1264 # 80020de8 <ftable>
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	3b2080e7          	jalr	946(ra) # 80000cb2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004908:	0001c497          	auipc	s1,0x1c
    8000490c:	4f848493          	addi	s1,s1,1272 # 80020e00 <ftable+0x18>
    80004910:	0001d717          	auipc	a4,0x1d
    80004914:	49070713          	addi	a4,a4,1168 # 80021da0 <disk>
    if(f->ref == 0){
    80004918:	40dc                	lw	a5,4(s1)
    8000491a:	cf99                	beqz	a5,80004938 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000491c:	02848493          	addi	s1,s1,40
    80004920:	fee49ce3          	bne	s1,a4,80004918 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004924:	0001c517          	auipc	a0,0x1c
    80004928:	4c450513          	addi	a0,a0,1220 # 80020de8 <ftable>
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	43a080e7          	jalr	1082(ra) # 80000d66 <release>
  return 0;
    80004934:	4481                	li	s1,0
    80004936:	a819                	j	8000494c <filealloc+0x5e>
      f->ref = 1;
    80004938:	4785                	li	a5,1
    8000493a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000493c:	0001c517          	auipc	a0,0x1c
    80004940:	4ac50513          	addi	a0,a0,1196 # 80020de8 <ftable>
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	422080e7          	jalr	1058(ra) # 80000d66 <release>
}
    8000494c:	8526                	mv	a0,s1
    8000494e:	60e2                	ld	ra,24(sp)
    80004950:	6442                	ld	s0,16(sp)
    80004952:	64a2                	ld	s1,8(sp)
    80004954:	6105                	addi	sp,sp,32
    80004956:	8082                	ret

0000000080004958 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004958:	1101                	addi	sp,sp,-32
    8000495a:	ec06                	sd	ra,24(sp)
    8000495c:	e822                	sd	s0,16(sp)
    8000495e:	e426                	sd	s1,8(sp)
    80004960:	1000                	addi	s0,sp,32
    80004962:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004964:	0001c517          	auipc	a0,0x1c
    80004968:	48450513          	addi	a0,a0,1156 # 80020de8 <ftable>
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	346080e7          	jalr	838(ra) # 80000cb2 <acquire>
  if(f->ref < 1)
    80004974:	40dc                	lw	a5,4(s1)
    80004976:	02f05263          	blez	a5,8000499a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000497a:	2785                	addiw	a5,a5,1
    8000497c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000497e:	0001c517          	auipc	a0,0x1c
    80004982:	46a50513          	addi	a0,a0,1130 # 80020de8 <ftable>
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	3e0080e7          	jalr	992(ra) # 80000d66 <release>
  return f;
}
    8000498e:	8526                	mv	a0,s1
    80004990:	60e2                	ld	ra,24(sp)
    80004992:	6442                	ld	s0,16(sp)
    80004994:	64a2                	ld	s1,8(sp)
    80004996:	6105                	addi	sp,sp,32
    80004998:	8082                	ret
    panic("filedup");
    8000499a:	00004517          	auipc	a0,0x4
    8000499e:	e2e50513          	addi	a0,a0,-466 # 800087c8 <syscalls+0x268>
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	ba2080e7          	jalr	-1118(ra) # 80000544 <panic>

00000000800049aa <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049aa:	7139                	addi	sp,sp,-64
    800049ac:	fc06                	sd	ra,56(sp)
    800049ae:	f822                	sd	s0,48(sp)
    800049b0:	f426                	sd	s1,40(sp)
    800049b2:	f04a                	sd	s2,32(sp)
    800049b4:	ec4e                	sd	s3,24(sp)
    800049b6:	e852                	sd	s4,16(sp)
    800049b8:	e456                	sd	s5,8(sp)
    800049ba:	0080                	addi	s0,sp,64
    800049bc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049be:	0001c517          	auipc	a0,0x1c
    800049c2:	42a50513          	addi	a0,a0,1066 # 80020de8 <ftable>
    800049c6:	ffffc097          	auipc	ra,0xffffc
    800049ca:	2ec080e7          	jalr	748(ra) # 80000cb2 <acquire>
  if(f->ref < 1)
    800049ce:	40dc                	lw	a5,4(s1)
    800049d0:	06f05163          	blez	a5,80004a32 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049d4:	37fd                	addiw	a5,a5,-1
    800049d6:	0007871b          	sext.w	a4,a5
    800049da:	c0dc                	sw	a5,4(s1)
    800049dc:	06e04363          	bgtz	a4,80004a42 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049e0:	0004a903          	lw	s2,0(s1)
    800049e4:	0094ca83          	lbu	s5,9(s1)
    800049e8:	0104ba03          	ld	s4,16(s1)
    800049ec:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049f0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049f4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049f8:	0001c517          	auipc	a0,0x1c
    800049fc:	3f050513          	addi	a0,a0,1008 # 80020de8 <ftable>
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	366080e7          	jalr	870(ra) # 80000d66 <release>

  if(ff.type == FD_PIPE){
    80004a08:	4785                	li	a5,1
    80004a0a:	04f90d63          	beq	s2,a5,80004a64 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a0e:	3979                	addiw	s2,s2,-2
    80004a10:	4785                	li	a5,1
    80004a12:	0527e063          	bltu	a5,s2,80004a52 <fileclose+0xa8>
    begin_op();
    80004a16:	00000097          	auipc	ra,0x0
    80004a1a:	ac8080e7          	jalr	-1336(ra) # 800044de <begin_op>
    iput(ff.ip);
    80004a1e:	854e                	mv	a0,s3
    80004a20:	fffff097          	auipc	ra,0xfffff
    80004a24:	2b6080e7          	jalr	694(ra) # 80003cd6 <iput>
    end_op();
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	b36080e7          	jalr	-1226(ra) # 8000455e <end_op>
    80004a30:	a00d                	j	80004a52 <fileclose+0xa8>
    panic("fileclose");
    80004a32:	00004517          	auipc	a0,0x4
    80004a36:	d9e50513          	addi	a0,a0,-610 # 800087d0 <syscalls+0x270>
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	b0a080e7          	jalr	-1270(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004a42:	0001c517          	auipc	a0,0x1c
    80004a46:	3a650513          	addi	a0,a0,934 # 80020de8 <ftable>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	31c080e7          	jalr	796(ra) # 80000d66 <release>
  }
}
    80004a52:	70e2                	ld	ra,56(sp)
    80004a54:	7442                	ld	s0,48(sp)
    80004a56:	74a2                	ld	s1,40(sp)
    80004a58:	7902                	ld	s2,32(sp)
    80004a5a:	69e2                	ld	s3,24(sp)
    80004a5c:	6a42                	ld	s4,16(sp)
    80004a5e:	6aa2                	ld	s5,8(sp)
    80004a60:	6121                	addi	sp,sp,64
    80004a62:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a64:	85d6                	mv	a1,s5
    80004a66:	8552                	mv	a0,s4
    80004a68:	00000097          	auipc	ra,0x0
    80004a6c:	34c080e7          	jalr	844(ra) # 80004db4 <pipeclose>
    80004a70:	b7cd                	j	80004a52 <fileclose+0xa8>

0000000080004a72 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a72:	715d                	addi	sp,sp,-80
    80004a74:	e486                	sd	ra,72(sp)
    80004a76:	e0a2                	sd	s0,64(sp)
    80004a78:	fc26                	sd	s1,56(sp)
    80004a7a:	f84a                	sd	s2,48(sp)
    80004a7c:	f44e                	sd	s3,40(sp)
    80004a7e:	0880                	addi	s0,sp,80
    80004a80:	84aa                	mv	s1,a0
    80004a82:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a84:	ffffd097          	auipc	ra,0xffffd
    80004a88:	108080e7          	jalr	264(ra) # 80001b8c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a8c:	409c                	lw	a5,0(s1)
    80004a8e:	37f9                	addiw	a5,a5,-2
    80004a90:	4705                	li	a4,1
    80004a92:	04f76763          	bltu	a4,a5,80004ae0 <filestat+0x6e>
    80004a96:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a98:	6c88                	ld	a0,24(s1)
    80004a9a:	fffff097          	auipc	ra,0xfffff
    80004a9e:	082080e7          	jalr	130(ra) # 80003b1c <ilock>
    stati(f->ip, &st);
    80004aa2:	fb840593          	addi	a1,s0,-72
    80004aa6:	6c88                	ld	a0,24(s1)
    80004aa8:	fffff097          	auipc	ra,0xfffff
    80004aac:	2fe080e7          	jalr	766(ra) # 80003da6 <stati>
    iunlock(f->ip);
    80004ab0:	6c88                	ld	a0,24(s1)
    80004ab2:	fffff097          	auipc	ra,0xfffff
    80004ab6:	12c080e7          	jalr	300(ra) # 80003bde <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004aba:	46e1                	li	a3,24
    80004abc:	fb840613          	addi	a2,s0,-72
    80004ac0:	85ce                	mv	a1,s3
    80004ac2:	05093503          	ld	a0,80(s2)
    80004ac6:	ffffd097          	auipc	ra,0xffffd
    80004aca:	c86080e7          	jalr	-890(ra) # 8000174c <copyout>
    80004ace:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ad2:	60a6                	ld	ra,72(sp)
    80004ad4:	6406                	ld	s0,64(sp)
    80004ad6:	74e2                	ld	s1,56(sp)
    80004ad8:	7942                	ld	s2,48(sp)
    80004ada:	79a2                	ld	s3,40(sp)
    80004adc:	6161                	addi	sp,sp,80
    80004ade:	8082                	ret
  return -1;
    80004ae0:	557d                	li	a0,-1
    80004ae2:	bfc5                	j	80004ad2 <filestat+0x60>

0000000080004ae4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ae4:	7179                	addi	sp,sp,-48
    80004ae6:	f406                	sd	ra,40(sp)
    80004ae8:	f022                	sd	s0,32(sp)
    80004aea:	ec26                	sd	s1,24(sp)
    80004aec:	e84a                	sd	s2,16(sp)
    80004aee:	e44e                	sd	s3,8(sp)
    80004af0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004af2:	00854783          	lbu	a5,8(a0)
    80004af6:	c3d5                	beqz	a5,80004b9a <fileread+0xb6>
    80004af8:	84aa                	mv	s1,a0
    80004afa:	89ae                	mv	s3,a1
    80004afc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004afe:	411c                	lw	a5,0(a0)
    80004b00:	4705                	li	a4,1
    80004b02:	04e78963          	beq	a5,a4,80004b54 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b06:	470d                	li	a4,3
    80004b08:	04e78d63          	beq	a5,a4,80004b62 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b0c:	4709                	li	a4,2
    80004b0e:	06e79e63          	bne	a5,a4,80004b8a <fileread+0xa6>
    ilock(f->ip);
    80004b12:	6d08                	ld	a0,24(a0)
    80004b14:	fffff097          	auipc	ra,0xfffff
    80004b18:	008080e7          	jalr	8(ra) # 80003b1c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b1c:	874a                	mv	a4,s2
    80004b1e:	5094                	lw	a3,32(s1)
    80004b20:	864e                	mv	a2,s3
    80004b22:	4585                	li	a1,1
    80004b24:	6c88                	ld	a0,24(s1)
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	2aa080e7          	jalr	682(ra) # 80003dd0 <readi>
    80004b2e:	892a                	mv	s2,a0
    80004b30:	00a05563          	blez	a0,80004b3a <fileread+0x56>
      f->off += r;
    80004b34:	509c                	lw	a5,32(s1)
    80004b36:	9fa9                	addw	a5,a5,a0
    80004b38:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b3a:	6c88                	ld	a0,24(s1)
    80004b3c:	fffff097          	auipc	ra,0xfffff
    80004b40:	0a2080e7          	jalr	162(ra) # 80003bde <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b44:	854a                	mv	a0,s2
    80004b46:	70a2                	ld	ra,40(sp)
    80004b48:	7402                	ld	s0,32(sp)
    80004b4a:	64e2                	ld	s1,24(sp)
    80004b4c:	6942                	ld	s2,16(sp)
    80004b4e:	69a2                	ld	s3,8(sp)
    80004b50:	6145                	addi	sp,sp,48
    80004b52:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b54:	6908                	ld	a0,16(a0)
    80004b56:	00000097          	auipc	ra,0x0
    80004b5a:	3ce080e7          	jalr	974(ra) # 80004f24 <piperead>
    80004b5e:	892a                	mv	s2,a0
    80004b60:	b7d5                	j	80004b44 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b62:	02451783          	lh	a5,36(a0)
    80004b66:	03079693          	slli	a3,a5,0x30
    80004b6a:	92c1                	srli	a3,a3,0x30
    80004b6c:	4725                	li	a4,9
    80004b6e:	02d76863          	bltu	a4,a3,80004b9e <fileread+0xba>
    80004b72:	0792                	slli	a5,a5,0x4
    80004b74:	0001c717          	auipc	a4,0x1c
    80004b78:	1d470713          	addi	a4,a4,468 # 80020d48 <devsw>
    80004b7c:	97ba                	add	a5,a5,a4
    80004b7e:	639c                	ld	a5,0(a5)
    80004b80:	c38d                	beqz	a5,80004ba2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b82:	4505                	li	a0,1
    80004b84:	9782                	jalr	a5
    80004b86:	892a                	mv	s2,a0
    80004b88:	bf75                	j	80004b44 <fileread+0x60>
    panic("fileread");
    80004b8a:	00004517          	auipc	a0,0x4
    80004b8e:	c5650513          	addi	a0,a0,-938 # 800087e0 <syscalls+0x280>
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	9b2080e7          	jalr	-1614(ra) # 80000544 <panic>
    return -1;
    80004b9a:	597d                	li	s2,-1
    80004b9c:	b765                	j	80004b44 <fileread+0x60>
      return -1;
    80004b9e:	597d                	li	s2,-1
    80004ba0:	b755                	j	80004b44 <fileread+0x60>
    80004ba2:	597d                	li	s2,-1
    80004ba4:	b745                	j	80004b44 <fileread+0x60>

0000000080004ba6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ba6:	715d                	addi	sp,sp,-80
    80004ba8:	e486                	sd	ra,72(sp)
    80004baa:	e0a2                	sd	s0,64(sp)
    80004bac:	fc26                	sd	s1,56(sp)
    80004bae:	f84a                	sd	s2,48(sp)
    80004bb0:	f44e                	sd	s3,40(sp)
    80004bb2:	f052                	sd	s4,32(sp)
    80004bb4:	ec56                	sd	s5,24(sp)
    80004bb6:	e85a                	sd	s6,16(sp)
    80004bb8:	e45e                	sd	s7,8(sp)
    80004bba:	e062                	sd	s8,0(sp)
    80004bbc:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004bbe:	00954783          	lbu	a5,9(a0)
    80004bc2:	10078663          	beqz	a5,80004cce <filewrite+0x128>
    80004bc6:	892a                	mv	s2,a0
    80004bc8:	8aae                	mv	s5,a1
    80004bca:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bcc:	411c                	lw	a5,0(a0)
    80004bce:	4705                	li	a4,1
    80004bd0:	02e78263          	beq	a5,a4,80004bf4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bd4:	470d                	li	a4,3
    80004bd6:	02e78663          	beq	a5,a4,80004c02 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bda:	4709                	li	a4,2
    80004bdc:	0ee79163          	bne	a5,a4,80004cbe <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004be0:	0ac05d63          	blez	a2,80004c9a <filewrite+0xf4>
    int i = 0;
    80004be4:	4981                	li	s3,0
    80004be6:	6b05                	lui	s6,0x1
    80004be8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004bec:	6b85                	lui	s7,0x1
    80004bee:	c00b8b9b          	addiw	s7,s7,-1024
    80004bf2:	a861                	j	80004c8a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bf4:	6908                	ld	a0,16(a0)
    80004bf6:	00000097          	auipc	ra,0x0
    80004bfa:	22e080e7          	jalr	558(ra) # 80004e24 <pipewrite>
    80004bfe:	8a2a                	mv	s4,a0
    80004c00:	a045                	j	80004ca0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c02:	02451783          	lh	a5,36(a0)
    80004c06:	03079693          	slli	a3,a5,0x30
    80004c0a:	92c1                	srli	a3,a3,0x30
    80004c0c:	4725                	li	a4,9
    80004c0e:	0cd76263          	bltu	a4,a3,80004cd2 <filewrite+0x12c>
    80004c12:	0792                	slli	a5,a5,0x4
    80004c14:	0001c717          	auipc	a4,0x1c
    80004c18:	13470713          	addi	a4,a4,308 # 80020d48 <devsw>
    80004c1c:	97ba                	add	a5,a5,a4
    80004c1e:	679c                	ld	a5,8(a5)
    80004c20:	cbdd                	beqz	a5,80004cd6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c22:	4505                	li	a0,1
    80004c24:	9782                	jalr	a5
    80004c26:	8a2a                	mv	s4,a0
    80004c28:	a8a5                	j	80004ca0 <filewrite+0xfa>
    80004c2a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c2e:	00000097          	auipc	ra,0x0
    80004c32:	8b0080e7          	jalr	-1872(ra) # 800044de <begin_op>
      ilock(f->ip);
    80004c36:	01893503          	ld	a0,24(s2)
    80004c3a:	fffff097          	auipc	ra,0xfffff
    80004c3e:	ee2080e7          	jalr	-286(ra) # 80003b1c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c42:	8762                	mv	a4,s8
    80004c44:	02092683          	lw	a3,32(s2)
    80004c48:	01598633          	add	a2,s3,s5
    80004c4c:	4585                	li	a1,1
    80004c4e:	01893503          	ld	a0,24(s2)
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	276080e7          	jalr	630(ra) # 80003ec8 <writei>
    80004c5a:	84aa                	mv	s1,a0
    80004c5c:	00a05763          	blez	a0,80004c6a <filewrite+0xc4>
        f->off += r;
    80004c60:	02092783          	lw	a5,32(s2)
    80004c64:	9fa9                	addw	a5,a5,a0
    80004c66:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c6a:	01893503          	ld	a0,24(s2)
    80004c6e:	fffff097          	auipc	ra,0xfffff
    80004c72:	f70080e7          	jalr	-144(ra) # 80003bde <iunlock>
      end_op();
    80004c76:	00000097          	auipc	ra,0x0
    80004c7a:	8e8080e7          	jalr	-1816(ra) # 8000455e <end_op>

      if(r != n1){
    80004c7e:	009c1f63          	bne	s8,s1,80004c9c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c82:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c86:	0149db63          	bge	s3,s4,80004c9c <filewrite+0xf6>
      int n1 = n - i;
    80004c8a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c8e:	84be                	mv	s1,a5
    80004c90:	2781                	sext.w	a5,a5
    80004c92:	f8fb5ce3          	bge	s6,a5,80004c2a <filewrite+0x84>
    80004c96:	84de                	mv	s1,s7
    80004c98:	bf49                	j	80004c2a <filewrite+0x84>
    int i = 0;
    80004c9a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c9c:	013a1f63          	bne	s4,s3,80004cba <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ca0:	8552                	mv	a0,s4
    80004ca2:	60a6                	ld	ra,72(sp)
    80004ca4:	6406                	ld	s0,64(sp)
    80004ca6:	74e2                	ld	s1,56(sp)
    80004ca8:	7942                	ld	s2,48(sp)
    80004caa:	79a2                	ld	s3,40(sp)
    80004cac:	7a02                	ld	s4,32(sp)
    80004cae:	6ae2                	ld	s5,24(sp)
    80004cb0:	6b42                	ld	s6,16(sp)
    80004cb2:	6ba2                	ld	s7,8(sp)
    80004cb4:	6c02                	ld	s8,0(sp)
    80004cb6:	6161                	addi	sp,sp,80
    80004cb8:	8082                	ret
    ret = (i == n ? n : -1);
    80004cba:	5a7d                	li	s4,-1
    80004cbc:	b7d5                	j	80004ca0 <filewrite+0xfa>
    panic("filewrite");
    80004cbe:	00004517          	auipc	a0,0x4
    80004cc2:	b3250513          	addi	a0,a0,-1230 # 800087f0 <syscalls+0x290>
    80004cc6:	ffffc097          	auipc	ra,0xffffc
    80004cca:	87e080e7          	jalr	-1922(ra) # 80000544 <panic>
    return -1;
    80004cce:	5a7d                	li	s4,-1
    80004cd0:	bfc1                	j	80004ca0 <filewrite+0xfa>
      return -1;
    80004cd2:	5a7d                	li	s4,-1
    80004cd4:	b7f1                	j	80004ca0 <filewrite+0xfa>
    80004cd6:	5a7d                	li	s4,-1
    80004cd8:	b7e1                	j	80004ca0 <filewrite+0xfa>

0000000080004cda <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004cda:	7179                	addi	sp,sp,-48
    80004cdc:	f406                	sd	ra,40(sp)
    80004cde:	f022                	sd	s0,32(sp)
    80004ce0:	ec26                	sd	s1,24(sp)
    80004ce2:	e84a                	sd	s2,16(sp)
    80004ce4:	e44e                	sd	s3,8(sp)
    80004ce6:	e052                	sd	s4,0(sp)
    80004ce8:	1800                	addi	s0,sp,48
    80004cea:	84aa                	mv	s1,a0
    80004cec:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cee:	0005b023          	sd	zero,0(a1)
    80004cf2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cf6:	00000097          	auipc	ra,0x0
    80004cfa:	bf8080e7          	jalr	-1032(ra) # 800048ee <filealloc>
    80004cfe:	e088                	sd	a0,0(s1)
    80004d00:	c551                	beqz	a0,80004d8c <pipealloc+0xb2>
    80004d02:	00000097          	auipc	ra,0x0
    80004d06:	bec080e7          	jalr	-1044(ra) # 800048ee <filealloc>
    80004d0a:	00aa3023          	sd	a0,0(s4)
    80004d0e:	c92d                	beqz	a0,80004d80 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	e66080e7          	jalr	-410(ra) # 80000b76 <kalloc>
    80004d18:	892a                	mv	s2,a0
    80004d1a:	c125                	beqz	a0,80004d7a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d1c:	4985                	li	s3,1
    80004d1e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d22:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d26:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d2a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d2e:	00004597          	auipc	a1,0x4
    80004d32:	ad258593          	addi	a1,a1,-1326 # 80008800 <syscalls+0x2a0>
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	eec080e7          	jalr	-276(ra) # 80000c22 <initlock>
  (*f0)->type = FD_PIPE;
    80004d3e:	609c                	ld	a5,0(s1)
    80004d40:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d44:	609c                	ld	a5,0(s1)
    80004d46:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d4a:	609c                	ld	a5,0(s1)
    80004d4c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d50:	609c                	ld	a5,0(s1)
    80004d52:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d56:	000a3783          	ld	a5,0(s4)
    80004d5a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d5e:	000a3783          	ld	a5,0(s4)
    80004d62:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d66:	000a3783          	ld	a5,0(s4)
    80004d6a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d6e:	000a3783          	ld	a5,0(s4)
    80004d72:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d76:	4501                	li	a0,0
    80004d78:	a025                	j	80004da0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d7a:	6088                	ld	a0,0(s1)
    80004d7c:	e501                	bnez	a0,80004d84 <pipealloc+0xaa>
    80004d7e:	a039                	j	80004d8c <pipealloc+0xb2>
    80004d80:	6088                	ld	a0,0(s1)
    80004d82:	c51d                	beqz	a0,80004db0 <pipealloc+0xd6>
    fileclose(*f0);
    80004d84:	00000097          	auipc	ra,0x0
    80004d88:	c26080e7          	jalr	-986(ra) # 800049aa <fileclose>
  if(*f1)
    80004d8c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d90:	557d                	li	a0,-1
  if(*f1)
    80004d92:	c799                	beqz	a5,80004da0 <pipealloc+0xc6>
    fileclose(*f1);
    80004d94:	853e                	mv	a0,a5
    80004d96:	00000097          	auipc	ra,0x0
    80004d9a:	c14080e7          	jalr	-1004(ra) # 800049aa <fileclose>
  return -1;
    80004d9e:	557d                	li	a0,-1
}
    80004da0:	70a2                	ld	ra,40(sp)
    80004da2:	7402                	ld	s0,32(sp)
    80004da4:	64e2                	ld	s1,24(sp)
    80004da6:	6942                	ld	s2,16(sp)
    80004da8:	69a2                	ld	s3,8(sp)
    80004daa:	6a02                	ld	s4,0(sp)
    80004dac:	6145                	addi	sp,sp,48
    80004dae:	8082                	ret
  return -1;
    80004db0:	557d                	li	a0,-1
    80004db2:	b7fd                	j	80004da0 <pipealloc+0xc6>

0000000080004db4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004db4:	1101                	addi	sp,sp,-32
    80004db6:	ec06                	sd	ra,24(sp)
    80004db8:	e822                	sd	s0,16(sp)
    80004dba:	e426                	sd	s1,8(sp)
    80004dbc:	e04a                	sd	s2,0(sp)
    80004dbe:	1000                	addi	s0,sp,32
    80004dc0:	84aa                	mv	s1,a0
    80004dc2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004dc4:	ffffc097          	auipc	ra,0xffffc
    80004dc8:	eee080e7          	jalr	-274(ra) # 80000cb2 <acquire>
  if(writable){
    80004dcc:	02090d63          	beqz	s2,80004e06 <pipeclose+0x52>
    pi->writeopen = 0;
    80004dd0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004dd4:	21848513          	addi	a0,s1,536
    80004dd8:	ffffd097          	auipc	ra,0xffffd
    80004ddc:	57c080e7          	jalr	1404(ra) # 80002354 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004de0:	2204b783          	ld	a5,544(s1)
    80004de4:	eb95                	bnez	a5,80004e18 <pipeclose+0x64>
    release(&pi->lock);
    80004de6:	8526                	mv	a0,s1
    80004de8:	ffffc097          	auipc	ra,0xffffc
    80004dec:	f7e080e7          	jalr	-130(ra) # 80000d66 <release>
    kfree((char*)pi);
    80004df0:	8526                	mv	a0,s1
    80004df2:	ffffc097          	auipc	ra,0xffffc
    80004df6:	c1e080e7          	jalr	-994(ra) # 80000a10 <kfree>
  } else
    release(&pi->lock);
}
    80004dfa:	60e2                	ld	ra,24(sp)
    80004dfc:	6442                	ld	s0,16(sp)
    80004dfe:	64a2                	ld	s1,8(sp)
    80004e00:	6902                	ld	s2,0(sp)
    80004e02:	6105                	addi	sp,sp,32
    80004e04:	8082                	ret
    pi->readopen = 0;
    80004e06:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e0a:	21c48513          	addi	a0,s1,540
    80004e0e:	ffffd097          	auipc	ra,0xffffd
    80004e12:	546080e7          	jalr	1350(ra) # 80002354 <wakeup>
    80004e16:	b7e9                	j	80004de0 <pipeclose+0x2c>
    release(&pi->lock);
    80004e18:	8526                	mv	a0,s1
    80004e1a:	ffffc097          	auipc	ra,0xffffc
    80004e1e:	f4c080e7          	jalr	-180(ra) # 80000d66 <release>
}
    80004e22:	bfe1                	j	80004dfa <pipeclose+0x46>

0000000080004e24 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e24:	7159                	addi	sp,sp,-112
    80004e26:	f486                	sd	ra,104(sp)
    80004e28:	f0a2                	sd	s0,96(sp)
    80004e2a:	eca6                	sd	s1,88(sp)
    80004e2c:	e8ca                	sd	s2,80(sp)
    80004e2e:	e4ce                	sd	s3,72(sp)
    80004e30:	e0d2                	sd	s4,64(sp)
    80004e32:	fc56                	sd	s5,56(sp)
    80004e34:	f85a                	sd	s6,48(sp)
    80004e36:	f45e                	sd	s7,40(sp)
    80004e38:	f062                	sd	s8,32(sp)
    80004e3a:	ec66                	sd	s9,24(sp)
    80004e3c:	1880                	addi	s0,sp,112
    80004e3e:	84aa                	mv	s1,a0
    80004e40:	8aae                	mv	s5,a1
    80004e42:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e44:	ffffd097          	auipc	ra,0xffffd
    80004e48:	d48080e7          	jalr	-696(ra) # 80001b8c <myproc>
    80004e4c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e4e:	8526                	mv	a0,s1
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	e62080e7          	jalr	-414(ra) # 80000cb2 <acquire>
  while(i < n){
    80004e58:	0d405463          	blez	s4,80004f20 <pipewrite+0xfc>
    80004e5c:	8ba6                	mv	s7,s1
  int i = 0;
    80004e5e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e60:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e62:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e66:	21c48c13          	addi	s8,s1,540
    80004e6a:	a08d                	j	80004ecc <pipewrite+0xa8>
      release(&pi->lock);
    80004e6c:	8526                	mv	a0,s1
    80004e6e:	ffffc097          	auipc	ra,0xffffc
    80004e72:	ef8080e7          	jalr	-264(ra) # 80000d66 <release>
      return -1;
    80004e76:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e78:	854a                	mv	a0,s2
    80004e7a:	70a6                	ld	ra,104(sp)
    80004e7c:	7406                	ld	s0,96(sp)
    80004e7e:	64e6                	ld	s1,88(sp)
    80004e80:	6946                	ld	s2,80(sp)
    80004e82:	69a6                	ld	s3,72(sp)
    80004e84:	6a06                	ld	s4,64(sp)
    80004e86:	7ae2                	ld	s5,56(sp)
    80004e88:	7b42                	ld	s6,48(sp)
    80004e8a:	7ba2                	ld	s7,40(sp)
    80004e8c:	7c02                	ld	s8,32(sp)
    80004e8e:	6ce2                	ld	s9,24(sp)
    80004e90:	6165                	addi	sp,sp,112
    80004e92:	8082                	ret
      wakeup(&pi->nread);
    80004e94:	8566                	mv	a0,s9
    80004e96:	ffffd097          	auipc	ra,0xffffd
    80004e9a:	4be080e7          	jalr	1214(ra) # 80002354 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e9e:	85de                	mv	a1,s7
    80004ea0:	8562                	mv	a0,s8
    80004ea2:	ffffd097          	auipc	ra,0xffffd
    80004ea6:	44e080e7          	jalr	1102(ra) # 800022f0 <sleep>
    80004eaa:	a839                	j	80004ec8 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004eac:	21c4a783          	lw	a5,540(s1)
    80004eb0:	0017871b          	addiw	a4,a5,1
    80004eb4:	20e4ae23          	sw	a4,540(s1)
    80004eb8:	1ff7f793          	andi	a5,a5,511
    80004ebc:	97a6                	add	a5,a5,s1
    80004ebe:	f9f44703          	lbu	a4,-97(s0)
    80004ec2:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ec6:	2905                	addiw	s2,s2,1
  while(i < n){
    80004ec8:	05495063          	bge	s2,s4,80004f08 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004ecc:	2204a783          	lw	a5,544(s1)
    80004ed0:	dfd1                	beqz	a5,80004e6c <pipewrite+0x48>
    80004ed2:	854e                	mv	a0,s3
    80004ed4:	ffffd097          	auipc	ra,0xffffd
    80004ed8:	6c4080e7          	jalr	1732(ra) # 80002598 <killed>
    80004edc:	f941                	bnez	a0,80004e6c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ede:	2184a783          	lw	a5,536(s1)
    80004ee2:	21c4a703          	lw	a4,540(s1)
    80004ee6:	2007879b          	addiw	a5,a5,512
    80004eea:	faf705e3          	beq	a4,a5,80004e94 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004eee:	4685                	li	a3,1
    80004ef0:	01590633          	add	a2,s2,s5
    80004ef4:	f9f40593          	addi	a1,s0,-97
    80004ef8:	0509b503          	ld	a0,80(s3)
    80004efc:	ffffd097          	auipc	ra,0xffffd
    80004f00:	8dc080e7          	jalr	-1828(ra) # 800017d8 <copyin>
    80004f04:	fb6514e3          	bne	a0,s6,80004eac <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f08:	21848513          	addi	a0,s1,536
    80004f0c:	ffffd097          	auipc	ra,0xffffd
    80004f10:	448080e7          	jalr	1096(ra) # 80002354 <wakeup>
  release(&pi->lock);
    80004f14:	8526                	mv	a0,s1
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	e50080e7          	jalr	-432(ra) # 80000d66 <release>
  return i;
    80004f1e:	bfa9                	j	80004e78 <pipewrite+0x54>
  int i = 0;
    80004f20:	4901                	li	s2,0
    80004f22:	b7dd                	j	80004f08 <pipewrite+0xe4>

0000000080004f24 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f24:	715d                	addi	sp,sp,-80
    80004f26:	e486                	sd	ra,72(sp)
    80004f28:	e0a2                	sd	s0,64(sp)
    80004f2a:	fc26                	sd	s1,56(sp)
    80004f2c:	f84a                	sd	s2,48(sp)
    80004f2e:	f44e                	sd	s3,40(sp)
    80004f30:	f052                	sd	s4,32(sp)
    80004f32:	ec56                	sd	s5,24(sp)
    80004f34:	e85a                	sd	s6,16(sp)
    80004f36:	0880                	addi	s0,sp,80
    80004f38:	84aa                	mv	s1,a0
    80004f3a:	892e                	mv	s2,a1
    80004f3c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f3e:	ffffd097          	auipc	ra,0xffffd
    80004f42:	c4e080e7          	jalr	-946(ra) # 80001b8c <myproc>
    80004f46:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f48:	8b26                	mv	s6,s1
    80004f4a:	8526                	mv	a0,s1
    80004f4c:	ffffc097          	auipc	ra,0xffffc
    80004f50:	d66080e7          	jalr	-666(ra) # 80000cb2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f54:	2184a703          	lw	a4,536(s1)
    80004f58:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f5c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f60:	02f71763          	bne	a4,a5,80004f8e <piperead+0x6a>
    80004f64:	2244a783          	lw	a5,548(s1)
    80004f68:	c39d                	beqz	a5,80004f8e <piperead+0x6a>
    if(killed(pr)){
    80004f6a:	8552                	mv	a0,s4
    80004f6c:	ffffd097          	auipc	ra,0xffffd
    80004f70:	62c080e7          	jalr	1580(ra) # 80002598 <killed>
    80004f74:	e941                	bnez	a0,80005004 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f76:	85da                	mv	a1,s6
    80004f78:	854e                	mv	a0,s3
    80004f7a:	ffffd097          	auipc	ra,0xffffd
    80004f7e:	376080e7          	jalr	886(ra) # 800022f0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f82:	2184a703          	lw	a4,536(s1)
    80004f86:	21c4a783          	lw	a5,540(s1)
    80004f8a:	fcf70de3          	beq	a4,a5,80004f64 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f8e:	09505263          	blez	s5,80005012 <piperead+0xee>
    80004f92:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f94:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004f96:	2184a783          	lw	a5,536(s1)
    80004f9a:	21c4a703          	lw	a4,540(s1)
    80004f9e:	02f70d63          	beq	a4,a5,80004fd8 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004fa2:	0017871b          	addiw	a4,a5,1
    80004fa6:	20e4ac23          	sw	a4,536(s1)
    80004faa:	1ff7f793          	andi	a5,a5,511
    80004fae:	97a6                	add	a5,a5,s1
    80004fb0:	0187c783          	lbu	a5,24(a5)
    80004fb4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fb8:	4685                	li	a3,1
    80004fba:	fbf40613          	addi	a2,s0,-65
    80004fbe:	85ca                	mv	a1,s2
    80004fc0:	050a3503          	ld	a0,80(s4)
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	788080e7          	jalr	1928(ra) # 8000174c <copyout>
    80004fcc:	01650663          	beq	a0,s6,80004fd8 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fd0:	2985                	addiw	s3,s3,1
    80004fd2:	0905                	addi	s2,s2,1
    80004fd4:	fd3a91e3          	bne	s5,s3,80004f96 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fd8:	21c48513          	addi	a0,s1,540
    80004fdc:	ffffd097          	auipc	ra,0xffffd
    80004fe0:	378080e7          	jalr	888(ra) # 80002354 <wakeup>
  release(&pi->lock);
    80004fe4:	8526                	mv	a0,s1
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	d80080e7          	jalr	-640(ra) # 80000d66 <release>
  return i;
}
    80004fee:	854e                	mv	a0,s3
    80004ff0:	60a6                	ld	ra,72(sp)
    80004ff2:	6406                	ld	s0,64(sp)
    80004ff4:	74e2                	ld	s1,56(sp)
    80004ff6:	7942                	ld	s2,48(sp)
    80004ff8:	79a2                	ld	s3,40(sp)
    80004ffa:	7a02                	ld	s4,32(sp)
    80004ffc:	6ae2                	ld	s5,24(sp)
    80004ffe:	6b42                	ld	s6,16(sp)
    80005000:	6161                	addi	sp,sp,80
    80005002:	8082                	ret
      release(&pi->lock);
    80005004:	8526                	mv	a0,s1
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	d60080e7          	jalr	-672(ra) # 80000d66 <release>
      return -1;
    8000500e:	59fd                	li	s3,-1
    80005010:	bff9                	j	80004fee <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005012:	4981                	li	s3,0
    80005014:	b7d1                	j	80004fd8 <piperead+0xb4>

0000000080005016 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005016:	1141                	addi	sp,sp,-16
    80005018:	e422                	sd	s0,8(sp)
    8000501a:	0800                	addi	s0,sp,16
    8000501c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000501e:	8905                	andi	a0,a0,1
    80005020:	c111                	beqz	a0,80005024 <flags2perm+0xe>
      perm = PTE_X;
    80005022:	4521                	li	a0,8
    if(flags & 0x2)
    80005024:	8b89                	andi	a5,a5,2
    80005026:	c399                	beqz	a5,8000502c <flags2perm+0x16>
      perm |= PTE_W;
    80005028:	00456513          	ori	a0,a0,4
    return perm;
}
    8000502c:	6422                	ld	s0,8(sp)
    8000502e:	0141                	addi	sp,sp,16
    80005030:	8082                	ret

0000000080005032 <exec>:

int
exec(char *path, char **argv)
{
    80005032:	df010113          	addi	sp,sp,-528
    80005036:	20113423          	sd	ra,520(sp)
    8000503a:	20813023          	sd	s0,512(sp)
    8000503e:	ffa6                	sd	s1,504(sp)
    80005040:	fbca                	sd	s2,496(sp)
    80005042:	f7ce                	sd	s3,488(sp)
    80005044:	f3d2                	sd	s4,480(sp)
    80005046:	efd6                	sd	s5,472(sp)
    80005048:	ebda                	sd	s6,464(sp)
    8000504a:	e7de                	sd	s7,456(sp)
    8000504c:	e3e2                	sd	s8,448(sp)
    8000504e:	ff66                	sd	s9,440(sp)
    80005050:	fb6a                	sd	s10,432(sp)
    80005052:	f76e                	sd	s11,424(sp)
    80005054:	0c00                	addi	s0,sp,528
    80005056:	84aa                	mv	s1,a0
    80005058:	dea43c23          	sd	a0,-520(s0)
    8000505c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005060:	ffffd097          	auipc	ra,0xffffd
    80005064:	b2c080e7          	jalr	-1236(ra) # 80001b8c <myproc>
    80005068:	892a                	mv	s2,a0

  begin_op();
    8000506a:	fffff097          	auipc	ra,0xfffff
    8000506e:	474080e7          	jalr	1140(ra) # 800044de <begin_op>

  if((ip = namei(path)) == 0){
    80005072:	8526                	mv	a0,s1
    80005074:	fffff097          	auipc	ra,0xfffff
    80005078:	24e080e7          	jalr	590(ra) # 800042c2 <namei>
    8000507c:	c92d                	beqz	a0,800050ee <exec+0xbc>
    8000507e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	a9c080e7          	jalr	-1380(ra) # 80003b1c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005088:	04000713          	li	a4,64
    8000508c:	4681                	li	a3,0
    8000508e:	e5040613          	addi	a2,s0,-432
    80005092:	4581                	li	a1,0
    80005094:	8526                	mv	a0,s1
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	d3a080e7          	jalr	-710(ra) # 80003dd0 <readi>
    8000509e:	04000793          	li	a5,64
    800050a2:	00f51a63          	bne	a0,a5,800050b6 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800050a6:	e5042703          	lw	a4,-432(s0)
    800050aa:	464c47b7          	lui	a5,0x464c4
    800050ae:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050b2:	04f70463          	beq	a4,a5,800050fa <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050b6:	8526                	mv	a0,s1
    800050b8:	fffff097          	auipc	ra,0xfffff
    800050bc:	cc6080e7          	jalr	-826(ra) # 80003d7e <iunlockput>
    end_op();
    800050c0:	fffff097          	auipc	ra,0xfffff
    800050c4:	49e080e7          	jalr	1182(ra) # 8000455e <end_op>
  }
  return -1;
    800050c8:	557d                	li	a0,-1
}
    800050ca:	20813083          	ld	ra,520(sp)
    800050ce:	20013403          	ld	s0,512(sp)
    800050d2:	74fe                	ld	s1,504(sp)
    800050d4:	795e                	ld	s2,496(sp)
    800050d6:	79be                	ld	s3,488(sp)
    800050d8:	7a1e                	ld	s4,480(sp)
    800050da:	6afe                	ld	s5,472(sp)
    800050dc:	6b5e                	ld	s6,464(sp)
    800050de:	6bbe                	ld	s7,456(sp)
    800050e0:	6c1e                	ld	s8,448(sp)
    800050e2:	7cfa                	ld	s9,440(sp)
    800050e4:	7d5a                	ld	s10,432(sp)
    800050e6:	7dba                	ld	s11,424(sp)
    800050e8:	21010113          	addi	sp,sp,528
    800050ec:	8082                	ret
    end_op();
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	470080e7          	jalr	1136(ra) # 8000455e <end_op>
    return -1;
    800050f6:	557d                	li	a0,-1
    800050f8:	bfc9                	j	800050ca <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800050fa:	854a                	mv	a0,s2
    800050fc:	ffffd097          	auipc	ra,0xffffd
    80005100:	b54080e7          	jalr	-1196(ra) # 80001c50 <proc_pagetable>
    80005104:	8baa                	mv	s7,a0
    80005106:	d945                	beqz	a0,800050b6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005108:	e7042983          	lw	s3,-400(s0)
    8000510c:	e8845783          	lhu	a5,-376(s0)
    80005110:	c7ad                	beqz	a5,8000517a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005112:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005114:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005116:	6c85                	lui	s9,0x1
    80005118:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000511c:	def43823          	sd	a5,-528(s0)
    80005120:	ac0d                	j	80005352 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005122:	00003517          	auipc	a0,0x3
    80005126:	6e650513          	addi	a0,a0,1766 # 80008808 <syscalls+0x2a8>
    8000512a:	ffffb097          	auipc	ra,0xffffb
    8000512e:	41a080e7          	jalr	1050(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005132:	8756                	mv	a4,s5
    80005134:	012d86bb          	addw	a3,s11,s2
    80005138:	4581                	li	a1,0
    8000513a:	8526                	mv	a0,s1
    8000513c:	fffff097          	auipc	ra,0xfffff
    80005140:	c94080e7          	jalr	-876(ra) # 80003dd0 <readi>
    80005144:	2501                	sext.w	a0,a0
    80005146:	1aaa9a63          	bne	s5,a0,800052fa <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    8000514a:	6785                	lui	a5,0x1
    8000514c:	0127893b          	addw	s2,a5,s2
    80005150:	77fd                	lui	a5,0xfffff
    80005152:	01478a3b          	addw	s4,a5,s4
    80005156:	1f897563          	bgeu	s2,s8,80005340 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    8000515a:	02091593          	slli	a1,s2,0x20
    8000515e:	9181                	srli	a1,a1,0x20
    80005160:	95ea                	add	a1,a1,s10
    80005162:	855e                	mv	a0,s7
    80005164:	ffffc097          	auipc	ra,0xffffc
    80005168:	fdc080e7          	jalr	-36(ra) # 80001140 <walkaddr>
    8000516c:	862a                	mv	a2,a0
    if(pa == 0)
    8000516e:	d955                	beqz	a0,80005122 <exec+0xf0>
      n = PGSIZE;
    80005170:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005172:	fd9a70e3          	bgeu	s4,s9,80005132 <exec+0x100>
      n = sz - i;
    80005176:	8ad2                	mv	s5,s4
    80005178:	bf6d                	j	80005132 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000517a:	4a01                	li	s4,0
  iunlockput(ip);
    8000517c:	8526                	mv	a0,s1
    8000517e:	fffff097          	auipc	ra,0xfffff
    80005182:	c00080e7          	jalr	-1024(ra) # 80003d7e <iunlockput>
  end_op();
    80005186:	fffff097          	auipc	ra,0xfffff
    8000518a:	3d8080e7          	jalr	984(ra) # 8000455e <end_op>
  p = myproc();
    8000518e:	ffffd097          	auipc	ra,0xffffd
    80005192:	9fe080e7          	jalr	-1538(ra) # 80001b8c <myproc>
    80005196:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005198:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000519c:	6785                	lui	a5,0x1
    8000519e:	17fd                	addi	a5,a5,-1
    800051a0:	9a3e                	add	s4,s4,a5
    800051a2:	757d                	lui	a0,0xfffff
    800051a4:	00aa77b3          	and	a5,s4,a0
    800051a8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800051ac:	4691                	li	a3,4
    800051ae:	6609                	lui	a2,0x2
    800051b0:	963e                	add	a2,a2,a5
    800051b2:	85be                	mv	a1,a5
    800051b4:	855e                	mv	a0,s7
    800051b6:	ffffc097          	auipc	ra,0xffffc
    800051ba:	33e080e7          	jalr	830(ra) # 800014f4 <uvmalloc>
    800051be:	8b2a                	mv	s6,a0
  ip = 0;
    800051c0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800051c2:	12050c63          	beqz	a0,800052fa <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051c6:	75f9                	lui	a1,0xffffe
    800051c8:	95aa                	add	a1,a1,a0
    800051ca:	855e                	mv	a0,s7
    800051cc:	ffffc097          	auipc	ra,0xffffc
    800051d0:	54e080e7          	jalr	1358(ra) # 8000171a <uvmclear>
  stackbase = sp - PGSIZE;
    800051d4:	7c7d                	lui	s8,0xfffff
    800051d6:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800051d8:	e0043783          	ld	a5,-512(s0)
    800051dc:	6388                	ld	a0,0(a5)
    800051de:	c535                	beqz	a0,8000524a <exec+0x218>
    800051e0:	e9040993          	addi	s3,s0,-368
    800051e4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051e8:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800051ea:	ffffc097          	auipc	ra,0xffffc
    800051ee:	d48080e7          	jalr	-696(ra) # 80000f32 <strlen>
    800051f2:	2505                	addiw	a0,a0,1
    800051f4:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051f8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800051fc:	13896663          	bltu	s2,s8,80005328 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005200:	e0043d83          	ld	s11,-512(s0)
    80005204:	000dba03          	ld	s4,0(s11)
    80005208:	8552                	mv	a0,s4
    8000520a:	ffffc097          	auipc	ra,0xffffc
    8000520e:	d28080e7          	jalr	-728(ra) # 80000f32 <strlen>
    80005212:	0015069b          	addiw	a3,a0,1
    80005216:	8652                	mv	a2,s4
    80005218:	85ca                	mv	a1,s2
    8000521a:	855e                	mv	a0,s7
    8000521c:	ffffc097          	auipc	ra,0xffffc
    80005220:	530080e7          	jalr	1328(ra) # 8000174c <copyout>
    80005224:	10054663          	bltz	a0,80005330 <exec+0x2fe>
    ustack[argc] = sp;
    80005228:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000522c:	0485                	addi	s1,s1,1
    8000522e:	008d8793          	addi	a5,s11,8
    80005232:	e0f43023          	sd	a5,-512(s0)
    80005236:	008db503          	ld	a0,8(s11)
    8000523a:	c911                	beqz	a0,8000524e <exec+0x21c>
    if(argc >= MAXARG)
    8000523c:	09a1                	addi	s3,s3,8
    8000523e:	fb3c96e3          	bne	s9,s3,800051ea <exec+0x1b8>
  sz = sz1;
    80005242:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005246:	4481                	li	s1,0
    80005248:	a84d                	j	800052fa <exec+0x2c8>
  sp = sz;
    8000524a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000524c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000524e:	00349793          	slli	a5,s1,0x3
    80005252:	f9040713          	addi	a4,s0,-112
    80005256:	97ba                	add	a5,a5,a4
    80005258:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000525c:	00148693          	addi	a3,s1,1
    80005260:	068e                	slli	a3,a3,0x3
    80005262:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005266:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000526a:	01897663          	bgeu	s2,s8,80005276 <exec+0x244>
  sz = sz1;
    8000526e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005272:	4481                	li	s1,0
    80005274:	a059                	j	800052fa <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005276:	e9040613          	addi	a2,s0,-368
    8000527a:	85ca                	mv	a1,s2
    8000527c:	855e                	mv	a0,s7
    8000527e:	ffffc097          	auipc	ra,0xffffc
    80005282:	4ce080e7          	jalr	1230(ra) # 8000174c <copyout>
    80005286:	0a054963          	bltz	a0,80005338 <exec+0x306>
  p->trapframe->a1 = sp;
    8000528a:	058ab783          	ld	a5,88(s5)
    8000528e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005292:	df843783          	ld	a5,-520(s0)
    80005296:	0007c703          	lbu	a4,0(a5)
    8000529a:	cf11                	beqz	a4,800052b6 <exec+0x284>
    8000529c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000529e:	02f00693          	li	a3,47
    800052a2:	a039                	j	800052b0 <exec+0x27e>
      last = s+1;
    800052a4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800052a8:	0785                	addi	a5,a5,1
    800052aa:	fff7c703          	lbu	a4,-1(a5)
    800052ae:	c701                	beqz	a4,800052b6 <exec+0x284>
    if(*s == '/')
    800052b0:	fed71ce3          	bne	a4,a3,800052a8 <exec+0x276>
    800052b4:	bfc5                	j	800052a4 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    800052b6:	4641                	li	a2,16
    800052b8:	df843583          	ld	a1,-520(s0)
    800052bc:	158a8513          	addi	a0,s5,344
    800052c0:	ffffc097          	auipc	ra,0xffffc
    800052c4:	c40080e7          	jalr	-960(ra) # 80000f00 <safestrcpy>
  oldpagetable = p->pagetable;
    800052c8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800052cc:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800052d0:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052d4:	058ab783          	ld	a5,88(s5)
    800052d8:	e6843703          	ld	a4,-408(s0)
    800052dc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052de:	058ab783          	ld	a5,88(s5)
    800052e2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052e6:	85ea                	mv	a1,s10
    800052e8:	ffffd097          	auipc	ra,0xffffd
    800052ec:	a04080e7          	jalr	-1532(ra) # 80001cec <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052f0:	0004851b          	sext.w	a0,s1
    800052f4:	bbd9                	j	800050ca <exec+0x98>
    800052f6:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    800052fa:	e0843583          	ld	a1,-504(s0)
    800052fe:	855e                	mv	a0,s7
    80005300:	ffffd097          	auipc	ra,0xffffd
    80005304:	9ec080e7          	jalr	-1556(ra) # 80001cec <proc_freepagetable>
  if(ip){
    80005308:	da0497e3          	bnez	s1,800050b6 <exec+0x84>
  return -1;
    8000530c:	557d                	li	a0,-1
    8000530e:	bb75                	j	800050ca <exec+0x98>
    80005310:	e1443423          	sd	s4,-504(s0)
    80005314:	b7dd                	j	800052fa <exec+0x2c8>
    80005316:	e1443423          	sd	s4,-504(s0)
    8000531a:	b7c5                	j	800052fa <exec+0x2c8>
    8000531c:	e1443423          	sd	s4,-504(s0)
    80005320:	bfe9                	j	800052fa <exec+0x2c8>
    80005322:	e1443423          	sd	s4,-504(s0)
    80005326:	bfd1                	j	800052fa <exec+0x2c8>
  sz = sz1;
    80005328:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000532c:	4481                	li	s1,0
    8000532e:	b7f1                	j	800052fa <exec+0x2c8>
  sz = sz1;
    80005330:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005334:	4481                	li	s1,0
    80005336:	b7d1                	j	800052fa <exec+0x2c8>
  sz = sz1;
    80005338:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000533c:	4481                	li	s1,0
    8000533e:	bf75                	j	800052fa <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005340:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005344:	2b05                	addiw	s6,s6,1
    80005346:	0389899b          	addiw	s3,s3,56
    8000534a:	e8845783          	lhu	a5,-376(s0)
    8000534e:	e2fb57e3          	bge	s6,a5,8000517c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005352:	2981                	sext.w	s3,s3
    80005354:	03800713          	li	a4,56
    80005358:	86ce                	mv	a3,s3
    8000535a:	e1840613          	addi	a2,s0,-488
    8000535e:	4581                	li	a1,0
    80005360:	8526                	mv	a0,s1
    80005362:	fffff097          	auipc	ra,0xfffff
    80005366:	a6e080e7          	jalr	-1426(ra) # 80003dd0 <readi>
    8000536a:	03800793          	li	a5,56
    8000536e:	f8f514e3          	bne	a0,a5,800052f6 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005372:	e1842783          	lw	a5,-488(s0)
    80005376:	4705                	li	a4,1
    80005378:	fce796e3          	bne	a5,a4,80005344 <exec+0x312>
    if(ph.memsz < ph.filesz)
    8000537c:	e4043903          	ld	s2,-448(s0)
    80005380:	e3843783          	ld	a5,-456(s0)
    80005384:	f8f966e3          	bltu	s2,a5,80005310 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005388:	e2843783          	ld	a5,-472(s0)
    8000538c:	993e                	add	s2,s2,a5
    8000538e:	f8f964e3          	bltu	s2,a5,80005316 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005392:	df043703          	ld	a4,-528(s0)
    80005396:	8ff9                	and	a5,a5,a4
    80005398:	f3d1                	bnez	a5,8000531c <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000539a:	e1c42503          	lw	a0,-484(s0)
    8000539e:	00000097          	auipc	ra,0x0
    800053a2:	c78080e7          	jalr	-904(ra) # 80005016 <flags2perm>
    800053a6:	86aa                	mv	a3,a0
    800053a8:	864a                	mv	a2,s2
    800053aa:	85d2                	mv	a1,s4
    800053ac:	855e                	mv	a0,s7
    800053ae:	ffffc097          	auipc	ra,0xffffc
    800053b2:	146080e7          	jalr	326(ra) # 800014f4 <uvmalloc>
    800053b6:	e0a43423          	sd	a0,-504(s0)
    800053ba:	d525                	beqz	a0,80005322 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053bc:	e2843d03          	ld	s10,-472(s0)
    800053c0:	e2042d83          	lw	s11,-480(s0)
    800053c4:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053c8:	f60c0ce3          	beqz	s8,80005340 <exec+0x30e>
    800053cc:	8a62                	mv	s4,s8
    800053ce:	4901                	li	s2,0
    800053d0:	b369                	j	8000515a <exec+0x128>

00000000800053d2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053d2:	7179                	addi	sp,sp,-48
    800053d4:	f406                	sd	ra,40(sp)
    800053d6:	f022                	sd	s0,32(sp)
    800053d8:	ec26                	sd	s1,24(sp)
    800053da:	e84a                	sd	s2,16(sp)
    800053dc:	1800                	addi	s0,sp,48
    800053de:	892e                	mv	s2,a1
    800053e0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800053e2:	fdc40593          	addi	a1,s0,-36
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	ab2080e7          	jalr	-1358(ra) # 80002e98 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053ee:	fdc42703          	lw	a4,-36(s0)
    800053f2:	47bd                	li	a5,15
    800053f4:	02e7eb63          	bltu	a5,a4,8000542a <argfd+0x58>
    800053f8:	ffffc097          	auipc	ra,0xffffc
    800053fc:	794080e7          	jalr	1940(ra) # 80001b8c <myproc>
    80005400:	fdc42703          	lw	a4,-36(s0)
    80005404:	01a70793          	addi	a5,a4,26
    80005408:	078e                	slli	a5,a5,0x3
    8000540a:	953e                	add	a0,a0,a5
    8000540c:	611c                	ld	a5,0(a0)
    8000540e:	c385                	beqz	a5,8000542e <argfd+0x5c>
    return -1;
  if(pfd)
    80005410:	00090463          	beqz	s2,80005418 <argfd+0x46>
    *pfd = fd;
    80005414:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005418:	4501                	li	a0,0
  if(pf)
    8000541a:	c091                	beqz	s1,8000541e <argfd+0x4c>
    *pf = f;
    8000541c:	e09c                	sd	a5,0(s1)
}
    8000541e:	70a2                	ld	ra,40(sp)
    80005420:	7402                	ld	s0,32(sp)
    80005422:	64e2                	ld	s1,24(sp)
    80005424:	6942                	ld	s2,16(sp)
    80005426:	6145                	addi	sp,sp,48
    80005428:	8082                	ret
    return -1;
    8000542a:	557d                	li	a0,-1
    8000542c:	bfcd                	j	8000541e <argfd+0x4c>
    8000542e:	557d                	li	a0,-1
    80005430:	b7fd                	j	8000541e <argfd+0x4c>

0000000080005432 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005432:	1101                	addi	sp,sp,-32
    80005434:	ec06                	sd	ra,24(sp)
    80005436:	e822                	sd	s0,16(sp)
    80005438:	e426                	sd	s1,8(sp)
    8000543a:	1000                	addi	s0,sp,32
    8000543c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000543e:	ffffc097          	auipc	ra,0xffffc
    80005442:	74e080e7          	jalr	1870(ra) # 80001b8c <myproc>
    80005446:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005448:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdd1f0>
    8000544c:	4501                	li	a0,0
    8000544e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005450:	6398                	ld	a4,0(a5)
    80005452:	cb19                	beqz	a4,80005468 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005454:	2505                	addiw	a0,a0,1
    80005456:	07a1                	addi	a5,a5,8
    80005458:	fed51ce3          	bne	a0,a3,80005450 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000545c:	557d                	li	a0,-1
}
    8000545e:	60e2                	ld	ra,24(sp)
    80005460:	6442                	ld	s0,16(sp)
    80005462:	64a2                	ld	s1,8(sp)
    80005464:	6105                	addi	sp,sp,32
    80005466:	8082                	ret
      p->ofile[fd] = f;
    80005468:	01a50793          	addi	a5,a0,26
    8000546c:	078e                	slli	a5,a5,0x3
    8000546e:	963e                	add	a2,a2,a5
    80005470:	e204                	sd	s1,0(a2)
      return fd;
    80005472:	b7f5                	j	8000545e <fdalloc+0x2c>

0000000080005474 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005474:	715d                	addi	sp,sp,-80
    80005476:	e486                	sd	ra,72(sp)
    80005478:	e0a2                	sd	s0,64(sp)
    8000547a:	fc26                	sd	s1,56(sp)
    8000547c:	f84a                	sd	s2,48(sp)
    8000547e:	f44e                	sd	s3,40(sp)
    80005480:	f052                	sd	s4,32(sp)
    80005482:	ec56                	sd	s5,24(sp)
    80005484:	e85a                	sd	s6,16(sp)
    80005486:	0880                	addi	s0,sp,80
    80005488:	8b2e                	mv	s6,a1
    8000548a:	89b2                	mv	s3,a2
    8000548c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000548e:	fb040593          	addi	a1,s0,-80
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	e4e080e7          	jalr	-434(ra) # 800042e0 <nameiparent>
    8000549a:	84aa                	mv	s1,a0
    8000549c:	16050063          	beqz	a0,800055fc <create+0x188>
    return 0;

  ilock(dp);
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	67c080e7          	jalr	1660(ra) # 80003b1c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054a8:	4601                	li	a2,0
    800054aa:	fb040593          	addi	a1,s0,-80
    800054ae:	8526                	mv	a0,s1
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	b50080e7          	jalr	-1200(ra) # 80004000 <dirlookup>
    800054b8:	8aaa                	mv	s5,a0
    800054ba:	c931                	beqz	a0,8000550e <create+0x9a>
    iunlockput(dp);
    800054bc:	8526                	mv	a0,s1
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	8c0080e7          	jalr	-1856(ra) # 80003d7e <iunlockput>
    ilock(ip);
    800054c6:	8556                	mv	a0,s5
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	654080e7          	jalr	1620(ra) # 80003b1c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054d0:	000b059b          	sext.w	a1,s6
    800054d4:	4789                	li	a5,2
    800054d6:	02f59563          	bne	a1,a5,80005500 <create+0x8c>
    800054da:	044ad783          	lhu	a5,68(s5)
    800054de:	37f9                	addiw	a5,a5,-2
    800054e0:	17c2                	slli	a5,a5,0x30
    800054e2:	93c1                	srli	a5,a5,0x30
    800054e4:	4705                	li	a4,1
    800054e6:	00f76d63          	bltu	a4,a5,80005500 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800054ea:	8556                	mv	a0,s5
    800054ec:	60a6                	ld	ra,72(sp)
    800054ee:	6406                	ld	s0,64(sp)
    800054f0:	74e2                	ld	s1,56(sp)
    800054f2:	7942                	ld	s2,48(sp)
    800054f4:	79a2                	ld	s3,40(sp)
    800054f6:	7a02                	ld	s4,32(sp)
    800054f8:	6ae2                	ld	s5,24(sp)
    800054fa:	6b42                	ld	s6,16(sp)
    800054fc:	6161                	addi	sp,sp,80
    800054fe:	8082                	ret
    iunlockput(ip);
    80005500:	8556                	mv	a0,s5
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	87c080e7          	jalr	-1924(ra) # 80003d7e <iunlockput>
    return 0;
    8000550a:	4a81                	li	s5,0
    8000550c:	bff9                	j	800054ea <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000550e:	85da                	mv	a1,s6
    80005510:	4088                	lw	a0,0(s1)
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	46e080e7          	jalr	1134(ra) # 80003980 <ialloc>
    8000551a:	8a2a                	mv	s4,a0
    8000551c:	c921                	beqz	a0,8000556c <create+0xf8>
  ilock(ip);
    8000551e:	ffffe097          	auipc	ra,0xffffe
    80005522:	5fe080e7          	jalr	1534(ra) # 80003b1c <ilock>
  ip->major = major;
    80005526:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000552a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000552e:	4785                	li	a5,1
    80005530:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005534:	8552                	mv	a0,s4
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	51c080e7          	jalr	1308(ra) # 80003a52 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000553e:	000b059b          	sext.w	a1,s6
    80005542:	4785                	li	a5,1
    80005544:	02f58b63          	beq	a1,a5,8000557a <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005548:	004a2603          	lw	a2,4(s4)
    8000554c:	fb040593          	addi	a1,s0,-80
    80005550:	8526                	mv	a0,s1
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	cbe080e7          	jalr	-834(ra) # 80004210 <dirlink>
    8000555a:	06054f63          	bltz	a0,800055d8 <create+0x164>
  iunlockput(dp);
    8000555e:	8526                	mv	a0,s1
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	81e080e7          	jalr	-2018(ra) # 80003d7e <iunlockput>
  return ip;
    80005568:	8ad2                	mv	s5,s4
    8000556a:	b741                	j	800054ea <create+0x76>
    iunlockput(dp);
    8000556c:	8526                	mv	a0,s1
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	810080e7          	jalr	-2032(ra) # 80003d7e <iunlockput>
    return 0;
    80005576:	8ad2                	mv	s5,s4
    80005578:	bf8d                	j	800054ea <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000557a:	004a2603          	lw	a2,4(s4)
    8000557e:	00003597          	auipc	a1,0x3
    80005582:	2aa58593          	addi	a1,a1,682 # 80008828 <syscalls+0x2c8>
    80005586:	8552                	mv	a0,s4
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	c88080e7          	jalr	-888(ra) # 80004210 <dirlink>
    80005590:	04054463          	bltz	a0,800055d8 <create+0x164>
    80005594:	40d0                	lw	a2,4(s1)
    80005596:	00003597          	auipc	a1,0x3
    8000559a:	29a58593          	addi	a1,a1,666 # 80008830 <syscalls+0x2d0>
    8000559e:	8552                	mv	a0,s4
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	c70080e7          	jalr	-912(ra) # 80004210 <dirlink>
    800055a8:	02054863          	bltz	a0,800055d8 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800055ac:	004a2603          	lw	a2,4(s4)
    800055b0:	fb040593          	addi	a1,s0,-80
    800055b4:	8526                	mv	a0,s1
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	c5a080e7          	jalr	-934(ra) # 80004210 <dirlink>
    800055be:	00054d63          	bltz	a0,800055d8 <create+0x164>
    dp->nlink++;  // for ".."
    800055c2:	04a4d783          	lhu	a5,74(s1)
    800055c6:	2785                	addiw	a5,a5,1
    800055c8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055cc:	8526                	mv	a0,s1
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	484080e7          	jalr	1156(ra) # 80003a52 <iupdate>
    800055d6:	b761                	j	8000555e <create+0xea>
  ip->nlink = 0;
    800055d8:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800055dc:	8552                	mv	a0,s4
    800055de:	ffffe097          	auipc	ra,0xffffe
    800055e2:	474080e7          	jalr	1140(ra) # 80003a52 <iupdate>
  iunlockput(ip);
    800055e6:	8552                	mv	a0,s4
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	796080e7          	jalr	1942(ra) # 80003d7e <iunlockput>
  iunlockput(dp);
    800055f0:	8526                	mv	a0,s1
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	78c080e7          	jalr	1932(ra) # 80003d7e <iunlockput>
  return 0;
    800055fa:	bdc5                	j	800054ea <create+0x76>
    return 0;
    800055fc:	8aaa                	mv	s5,a0
    800055fe:	b5f5                	j	800054ea <create+0x76>

0000000080005600 <sys_dup>:
{
    80005600:	7179                	addi	sp,sp,-48
    80005602:	f406                	sd	ra,40(sp)
    80005604:	f022                	sd	s0,32(sp)
    80005606:	ec26                	sd	s1,24(sp)
    80005608:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000560a:	fd840613          	addi	a2,s0,-40
    8000560e:	4581                	li	a1,0
    80005610:	4501                	li	a0,0
    80005612:	00000097          	auipc	ra,0x0
    80005616:	dc0080e7          	jalr	-576(ra) # 800053d2 <argfd>
    return -1;
    8000561a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000561c:	02054363          	bltz	a0,80005642 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005620:	fd843503          	ld	a0,-40(s0)
    80005624:	00000097          	auipc	ra,0x0
    80005628:	e0e080e7          	jalr	-498(ra) # 80005432 <fdalloc>
    8000562c:	84aa                	mv	s1,a0
    return -1;
    8000562e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005630:	00054963          	bltz	a0,80005642 <sys_dup+0x42>
  filedup(f);
    80005634:	fd843503          	ld	a0,-40(s0)
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	320080e7          	jalr	800(ra) # 80004958 <filedup>
  return fd;
    80005640:	87a6                	mv	a5,s1
}
    80005642:	853e                	mv	a0,a5
    80005644:	70a2                	ld	ra,40(sp)
    80005646:	7402                	ld	s0,32(sp)
    80005648:	64e2                	ld	s1,24(sp)
    8000564a:	6145                	addi	sp,sp,48
    8000564c:	8082                	ret

000000008000564e <sys_read>:
{
    8000564e:	7179                	addi	sp,sp,-48
    80005650:	f406                	sd	ra,40(sp)
    80005652:	f022                	sd	s0,32(sp)
    80005654:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005656:	fd840593          	addi	a1,s0,-40
    8000565a:	4505                	li	a0,1
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	85c080e7          	jalr	-1956(ra) # 80002eb8 <argaddr>
  argint(2, &n);
    80005664:	fe440593          	addi	a1,s0,-28
    80005668:	4509                	li	a0,2
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	82e080e7          	jalr	-2002(ra) # 80002e98 <argint>
  if(argfd(0, 0, &f) < 0)
    80005672:	fe840613          	addi	a2,s0,-24
    80005676:	4581                	li	a1,0
    80005678:	4501                	li	a0,0
    8000567a:	00000097          	auipc	ra,0x0
    8000567e:	d58080e7          	jalr	-680(ra) # 800053d2 <argfd>
    80005682:	87aa                	mv	a5,a0
    return -1;
    80005684:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005686:	0007cc63          	bltz	a5,8000569e <sys_read+0x50>
  return fileread(f, p, n);
    8000568a:	fe442603          	lw	a2,-28(s0)
    8000568e:	fd843583          	ld	a1,-40(s0)
    80005692:	fe843503          	ld	a0,-24(s0)
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	44e080e7          	jalr	1102(ra) # 80004ae4 <fileread>
}
    8000569e:	70a2                	ld	ra,40(sp)
    800056a0:	7402                	ld	s0,32(sp)
    800056a2:	6145                	addi	sp,sp,48
    800056a4:	8082                	ret

00000000800056a6 <sys_write>:
{
    800056a6:	7179                	addi	sp,sp,-48
    800056a8:	f406                	sd	ra,40(sp)
    800056aa:	f022                	sd	s0,32(sp)
    800056ac:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800056ae:	fd840593          	addi	a1,s0,-40
    800056b2:	4505                	li	a0,1
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	804080e7          	jalr	-2044(ra) # 80002eb8 <argaddr>
  argint(2, &n);
    800056bc:	fe440593          	addi	a1,s0,-28
    800056c0:	4509                	li	a0,2
    800056c2:	ffffd097          	auipc	ra,0xffffd
    800056c6:	7d6080e7          	jalr	2006(ra) # 80002e98 <argint>
  if(argfd(0, 0, &f) < 0)
    800056ca:	fe840613          	addi	a2,s0,-24
    800056ce:	4581                	li	a1,0
    800056d0:	4501                	li	a0,0
    800056d2:	00000097          	auipc	ra,0x0
    800056d6:	d00080e7          	jalr	-768(ra) # 800053d2 <argfd>
    800056da:	87aa                	mv	a5,a0
    return -1;
    800056dc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056de:	0007cc63          	bltz	a5,800056f6 <sys_write+0x50>
  return filewrite(f, p, n);
    800056e2:	fe442603          	lw	a2,-28(s0)
    800056e6:	fd843583          	ld	a1,-40(s0)
    800056ea:	fe843503          	ld	a0,-24(s0)
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	4b8080e7          	jalr	1208(ra) # 80004ba6 <filewrite>
}
    800056f6:	70a2                	ld	ra,40(sp)
    800056f8:	7402                	ld	s0,32(sp)
    800056fa:	6145                	addi	sp,sp,48
    800056fc:	8082                	ret

00000000800056fe <sys_close>:
{
    800056fe:	1101                	addi	sp,sp,-32
    80005700:	ec06                	sd	ra,24(sp)
    80005702:	e822                	sd	s0,16(sp)
    80005704:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005706:	fe040613          	addi	a2,s0,-32
    8000570a:	fec40593          	addi	a1,s0,-20
    8000570e:	4501                	li	a0,0
    80005710:	00000097          	auipc	ra,0x0
    80005714:	cc2080e7          	jalr	-830(ra) # 800053d2 <argfd>
    return -1;
    80005718:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000571a:	02054463          	bltz	a0,80005742 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000571e:	ffffc097          	auipc	ra,0xffffc
    80005722:	46e080e7          	jalr	1134(ra) # 80001b8c <myproc>
    80005726:	fec42783          	lw	a5,-20(s0)
    8000572a:	07e9                	addi	a5,a5,26
    8000572c:	078e                	slli	a5,a5,0x3
    8000572e:	97aa                	add	a5,a5,a0
    80005730:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005734:	fe043503          	ld	a0,-32(s0)
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	272080e7          	jalr	626(ra) # 800049aa <fileclose>
  return 0;
    80005740:	4781                	li	a5,0
}
    80005742:	853e                	mv	a0,a5
    80005744:	60e2                	ld	ra,24(sp)
    80005746:	6442                	ld	s0,16(sp)
    80005748:	6105                	addi	sp,sp,32
    8000574a:	8082                	ret

000000008000574c <sys_fstat>:
{
    8000574c:	1101                	addi	sp,sp,-32
    8000574e:	ec06                	sd	ra,24(sp)
    80005750:	e822                	sd	s0,16(sp)
    80005752:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005754:	fe040593          	addi	a1,s0,-32
    80005758:	4505                	li	a0,1
    8000575a:	ffffd097          	auipc	ra,0xffffd
    8000575e:	75e080e7          	jalr	1886(ra) # 80002eb8 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005762:	fe840613          	addi	a2,s0,-24
    80005766:	4581                	li	a1,0
    80005768:	4501                	li	a0,0
    8000576a:	00000097          	auipc	ra,0x0
    8000576e:	c68080e7          	jalr	-920(ra) # 800053d2 <argfd>
    80005772:	87aa                	mv	a5,a0
    return -1;
    80005774:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005776:	0007ca63          	bltz	a5,8000578a <sys_fstat+0x3e>
  return filestat(f, st);
    8000577a:	fe043583          	ld	a1,-32(s0)
    8000577e:	fe843503          	ld	a0,-24(s0)
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	2f0080e7          	jalr	752(ra) # 80004a72 <filestat>
}
    8000578a:	60e2                	ld	ra,24(sp)
    8000578c:	6442                	ld	s0,16(sp)
    8000578e:	6105                	addi	sp,sp,32
    80005790:	8082                	ret

0000000080005792 <sys_link>:
{
    80005792:	7169                	addi	sp,sp,-304
    80005794:	f606                	sd	ra,296(sp)
    80005796:	f222                	sd	s0,288(sp)
    80005798:	ee26                	sd	s1,280(sp)
    8000579a:	ea4a                	sd	s2,272(sp)
    8000579c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000579e:	08000613          	li	a2,128
    800057a2:	ed040593          	addi	a1,s0,-304
    800057a6:	4501                	li	a0,0
    800057a8:	ffffd097          	auipc	ra,0xffffd
    800057ac:	730080e7          	jalr	1840(ra) # 80002ed8 <argstr>
    return -1;
    800057b0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057b2:	10054e63          	bltz	a0,800058ce <sys_link+0x13c>
    800057b6:	08000613          	li	a2,128
    800057ba:	f5040593          	addi	a1,s0,-176
    800057be:	4505                	li	a0,1
    800057c0:	ffffd097          	auipc	ra,0xffffd
    800057c4:	718080e7          	jalr	1816(ra) # 80002ed8 <argstr>
    return -1;
    800057c8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057ca:	10054263          	bltz	a0,800058ce <sys_link+0x13c>
  begin_op();
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	d10080e7          	jalr	-752(ra) # 800044de <begin_op>
  if((ip = namei(old)) == 0){
    800057d6:	ed040513          	addi	a0,s0,-304
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	ae8080e7          	jalr	-1304(ra) # 800042c2 <namei>
    800057e2:	84aa                	mv	s1,a0
    800057e4:	c551                	beqz	a0,80005870 <sys_link+0xde>
  ilock(ip);
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	336080e7          	jalr	822(ra) # 80003b1c <ilock>
  if(ip->type == T_DIR){
    800057ee:	04449703          	lh	a4,68(s1)
    800057f2:	4785                	li	a5,1
    800057f4:	08f70463          	beq	a4,a5,8000587c <sys_link+0xea>
  ip->nlink++;
    800057f8:	04a4d783          	lhu	a5,74(s1)
    800057fc:	2785                	addiw	a5,a5,1
    800057fe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005802:	8526                	mv	a0,s1
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	24e080e7          	jalr	590(ra) # 80003a52 <iupdate>
  iunlock(ip);
    8000580c:	8526                	mv	a0,s1
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	3d0080e7          	jalr	976(ra) # 80003bde <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005816:	fd040593          	addi	a1,s0,-48
    8000581a:	f5040513          	addi	a0,s0,-176
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	ac2080e7          	jalr	-1342(ra) # 800042e0 <nameiparent>
    80005826:	892a                	mv	s2,a0
    80005828:	c935                	beqz	a0,8000589c <sys_link+0x10a>
  ilock(dp);
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	2f2080e7          	jalr	754(ra) # 80003b1c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005832:	00092703          	lw	a4,0(s2)
    80005836:	409c                	lw	a5,0(s1)
    80005838:	04f71d63          	bne	a4,a5,80005892 <sys_link+0x100>
    8000583c:	40d0                	lw	a2,4(s1)
    8000583e:	fd040593          	addi	a1,s0,-48
    80005842:	854a                	mv	a0,s2
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	9cc080e7          	jalr	-1588(ra) # 80004210 <dirlink>
    8000584c:	04054363          	bltz	a0,80005892 <sys_link+0x100>
  iunlockput(dp);
    80005850:	854a                	mv	a0,s2
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	52c080e7          	jalr	1324(ra) # 80003d7e <iunlockput>
  iput(ip);
    8000585a:	8526                	mv	a0,s1
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	47a080e7          	jalr	1146(ra) # 80003cd6 <iput>
  end_op();
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	cfa080e7          	jalr	-774(ra) # 8000455e <end_op>
  return 0;
    8000586c:	4781                	li	a5,0
    8000586e:	a085                	j	800058ce <sys_link+0x13c>
    end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	cee080e7          	jalr	-786(ra) # 8000455e <end_op>
    return -1;
    80005878:	57fd                	li	a5,-1
    8000587a:	a891                	j	800058ce <sys_link+0x13c>
    iunlockput(ip);
    8000587c:	8526                	mv	a0,s1
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	500080e7          	jalr	1280(ra) # 80003d7e <iunlockput>
    end_op();
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	cd8080e7          	jalr	-808(ra) # 8000455e <end_op>
    return -1;
    8000588e:	57fd                	li	a5,-1
    80005890:	a83d                	j	800058ce <sys_link+0x13c>
    iunlockput(dp);
    80005892:	854a                	mv	a0,s2
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	4ea080e7          	jalr	1258(ra) # 80003d7e <iunlockput>
  ilock(ip);
    8000589c:	8526                	mv	a0,s1
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	27e080e7          	jalr	638(ra) # 80003b1c <ilock>
  ip->nlink--;
    800058a6:	04a4d783          	lhu	a5,74(s1)
    800058aa:	37fd                	addiw	a5,a5,-1
    800058ac:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058b0:	8526                	mv	a0,s1
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	1a0080e7          	jalr	416(ra) # 80003a52 <iupdate>
  iunlockput(ip);
    800058ba:	8526                	mv	a0,s1
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	4c2080e7          	jalr	1218(ra) # 80003d7e <iunlockput>
  end_op();
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	c9a080e7          	jalr	-870(ra) # 8000455e <end_op>
  return -1;
    800058cc:	57fd                	li	a5,-1
}
    800058ce:	853e                	mv	a0,a5
    800058d0:	70b2                	ld	ra,296(sp)
    800058d2:	7412                	ld	s0,288(sp)
    800058d4:	64f2                	ld	s1,280(sp)
    800058d6:	6952                	ld	s2,272(sp)
    800058d8:	6155                	addi	sp,sp,304
    800058da:	8082                	ret

00000000800058dc <sys_unlink>:
{
    800058dc:	7151                	addi	sp,sp,-240
    800058de:	f586                	sd	ra,232(sp)
    800058e0:	f1a2                	sd	s0,224(sp)
    800058e2:	eda6                	sd	s1,216(sp)
    800058e4:	e9ca                	sd	s2,208(sp)
    800058e6:	e5ce                	sd	s3,200(sp)
    800058e8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058ea:	08000613          	li	a2,128
    800058ee:	f3040593          	addi	a1,s0,-208
    800058f2:	4501                	li	a0,0
    800058f4:	ffffd097          	auipc	ra,0xffffd
    800058f8:	5e4080e7          	jalr	1508(ra) # 80002ed8 <argstr>
    800058fc:	18054163          	bltz	a0,80005a7e <sys_unlink+0x1a2>
  begin_op();
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	bde080e7          	jalr	-1058(ra) # 800044de <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005908:	fb040593          	addi	a1,s0,-80
    8000590c:	f3040513          	addi	a0,s0,-208
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	9d0080e7          	jalr	-1584(ra) # 800042e0 <nameiparent>
    80005918:	84aa                	mv	s1,a0
    8000591a:	c979                	beqz	a0,800059f0 <sys_unlink+0x114>
  ilock(dp);
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	200080e7          	jalr	512(ra) # 80003b1c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005924:	00003597          	auipc	a1,0x3
    80005928:	f0458593          	addi	a1,a1,-252 # 80008828 <syscalls+0x2c8>
    8000592c:	fb040513          	addi	a0,s0,-80
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	6b6080e7          	jalr	1718(ra) # 80003fe6 <namecmp>
    80005938:	14050a63          	beqz	a0,80005a8c <sys_unlink+0x1b0>
    8000593c:	00003597          	auipc	a1,0x3
    80005940:	ef458593          	addi	a1,a1,-268 # 80008830 <syscalls+0x2d0>
    80005944:	fb040513          	addi	a0,s0,-80
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	69e080e7          	jalr	1694(ra) # 80003fe6 <namecmp>
    80005950:	12050e63          	beqz	a0,80005a8c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005954:	f2c40613          	addi	a2,s0,-212
    80005958:	fb040593          	addi	a1,s0,-80
    8000595c:	8526                	mv	a0,s1
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	6a2080e7          	jalr	1698(ra) # 80004000 <dirlookup>
    80005966:	892a                	mv	s2,a0
    80005968:	12050263          	beqz	a0,80005a8c <sys_unlink+0x1b0>
  ilock(ip);
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	1b0080e7          	jalr	432(ra) # 80003b1c <ilock>
  if(ip->nlink < 1)
    80005974:	04a91783          	lh	a5,74(s2)
    80005978:	08f05263          	blez	a5,800059fc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000597c:	04491703          	lh	a4,68(s2)
    80005980:	4785                	li	a5,1
    80005982:	08f70563          	beq	a4,a5,80005a0c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005986:	4641                	li	a2,16
    80005988:	4581                	li	a1,0
    8000598a:	fc040513          	addi	a0,s0,-64
    8000598e:	ffffb097          	auipc	ra,0xffffb
    80005992:	420080e7          	jalr	1056(ra) # 80000dae <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005996:	4741                	li	a4,16
    80005998:	f2c42683          	lw	a3,-212(s0)
    8000599c:	fc040613          	addi	a2,s0,-64
    800059a0:	4581                	li	a1,0
    800059a2:	8526                	mv	a0,s1
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	524080e7          	jalr	1316(ra) # 80003ec8 <writei>
    800059ac:	47c1                	li	a5,16
    800059ae:	0af51563          	bne	a0,a5,80005a58 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059b2:	04491703          	lh	a4,68(s2)
    800059b6:	4785                	li	a5,1
    800059b8:	0af70863          	beq	a4,a5,80005a68 <sys_unlink+0x18c>
  iunlockput(dp);
    800059bc:	8526                	mv	a0,s1
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	3c0080e7          	jalr	960(ra) # 80003d7e <iunlockput>
  ip->nlink--;
    800059c6:	04a95783          	lhu	a5,74(s2)
    800059ca:	37fd                	addiw	a5,a5,-1
    800059cc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059d0:	854a                	mv	a0,s2
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	080080e7          	jalr	128(ra) # 80003a52 <iupdate>
  iunlockput(ip);
    800059da:	854a                	mv	a0,s2
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	3a2080e7          	jalr	930(ra) # 80003d7e <iunlockput>
  end_op();
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	b7a080e7          	jalr	-1158(ra) # 8000455e <end_op>
  return 0;
    800059ec:	4501                	li	a0,0
    800059ee:	a84d                	j	80005aa0 <sys_unlink+0x1c4>
    end_op();
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	b6e080e7          	jalr	-1170(ra) # 8000455e <end_op>
    return -1;
    800059f8:	557d                	li	a0,-1
    800059fa:	a05d                	j	80005aa0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059fc:	00003517          	auipc	a0,0x3
    80005a00:	e3c50513          	addi	a0,a0,-452 # 80008838 <syscalls+0x2d8>
    80005a04:	ffffb097          	auipc	ra,0xffffb
    80005a08:	b40080e7          	jalr	-1216(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a0c:	04c92703          	lw	a4,76(s2)
    80005a10:	02000793          	li	a5,32
    80005a14:	f6e7f9e3          	bgeu	a5,a4,80005986 <sys_unlink+0xaa>
    80005a18:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a1c:	4741                	li	a4,16
    80005a1e:	86ce                	mv	a3,s3
    80005a20:	f1840613          	addi	a2,s0,-232
    80005a24:	4581                	li	a1,0
    80005a26:	854a                	mv	a0,s2
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	3a8080e7          	jalr	936(ra) # 80003dd0 <readi>
    80005a30:	47c1                	li	a5,16
    80005a32:	00f51b63          	bne	a0,a5,80005a48 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a36:	f1845783          	lhu	a5,-232(s0)
    80005a3a:	e7a1                	bnez	a5,80005a82 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a3c:	29c1                	addiw	s3,s3,16
    80005a3e:	04c92783          	lw	a5,76(s2)
    80005a42:	fcf9ede3          	bltu	s3,a5,80005a1c <sys_unlink+0x140>
    80005a46:	b781                	j	80005986 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a48:	00003517          	auipc	a0,0x3
    80005a4c:	e0850513          	addi	a0,a0,-504 # 80008850 <syscalls+0x2f0>
    80005a50:	ffffb097          	auipc	ra,0xffffb
    80005a54:	af4080e7          	jalr	-1292(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005a58:	00003517          	auipc	a0,0x3
    80005a5c:	e1050513          	addi	a0,a0,-496 # 80008868 <syscalls+0x308>
    80005a60:	ffffb097          	auipc	ra,0xffffb
    80005a64:	ae4080e7          	jalr	-1308(ra) # 80000544 <panic>
    dp->nlink--;
    80005a68:	04a4d783          	lhu	a5,74(s1)
    80005a6c:	37fd                	addiw	a5,a5,-1
    80005a6e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a72:	8526                	mv	a0,s1
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	fde080e7          	jalr	-34(ra) # 80003a52 <iupdate>
    80005a7c:	b781                	j	800059bc <sys_unlink+0xe0>
    return -1;
    80005a7e:	557d                	li	a0,-1
    80005a80:	a005                	j	80005aa0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a82:	854a                	mv	a0,s2
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	2fa080e7          	jalr	762(ra) # 80003d7e <iunlockput>
  iunlockput(dp);
    80005a8c:	8526                	mv	a0,s1
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	2f0080e7          	jalr	752(ra) # 80003d7e <iunlockput>
  end_op();
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	ac8080e7          	jalr	-1336(ra) # 8000455e <end_op>
  return -1;
    80005a9e:	557d                	li	a0,-1
}
    80005aa0:	70ae                	ld	ra,232(sp)
    80005aa2:	740e                	ld	s0,224(sp)
    80005aa4:	64ee                	ld	s1,216(sp)
    80005aa6:	694e                	ld	s2,208(sp)
    80005aa8:	69ae                	ld	s3,200(sp)
    80005aaa:	616d                	addi	sp,sp,240
    80005aac:	8082                	ret

0000000080005aae <sys_open>:

uint64
sys_open(void)
{
    80005aae:	7131                	addi	sp,sp,-192
    80005ab0:	fd06                	sd	ra,184(sp)
    80005ab2:	f922                	sd	s0,176(sp)
    80005ab4:	f526                	sd	s1,168(sp)
    80005ab6:	f14a                	sd	s2,160(sp)
    80005ab8:	ed4e                	sd	s3,152(sp)
    80005aba:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005abc:	f4c40593          	addi	a1,s0,-180
    80005ac0:	4505                	li	a0,1
    80005ac2:	ffffd097          	auipc	ra,0xffffd
    80005ac6:	3d6080e7          	jalr	982(ra) # 80002e98 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005aca:	08000613          	li	a2,128
    80005ace:	f5040593          	addi	a1,s0,-176
    80005ad2:	4501                	li	a0,0
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	404080e7          	jalr	1028(ra) # 80002ed8 <argstr>
    80005adc:	87aa                	mv	a5,a0
    return -1;
    80005ade:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ae0:	0a07c963          	bltz	a5,80005b92 <sys_open+0xe4>

  begin_op();
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	9fa080e7          	jalr	-1542(ra) # 800044de <begin_op>

  if(omode & O_CREATE){
    80005aec:	f4c42783          	lw	a5,-180(s0)
    80005af0:	2007f793          	andi	a5,a5,512
    80005af4:	cfc5                	beqz	a5,80005bac <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005af6:	4681                	li	a3,0
    80005af8:	4601                	li	a2,0
    80005afa:	4589                	li	a1,2
    80005afc:	f5040513          	addi	a0,s0,-176
    80005b00:	00000097          	auipc	ra,0x0
    80005b04:	974080e7          	jalr	-1676(ra) # 80005474 <create>
    80005b08:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b0a:	c959                	beqz	a0,80005ba0 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b0c:	04449703          	lh	a4,68(s1)
    80005b10:	478d                	li	a5,3
    80005b12:	00f71763          	bne	a4,a5,80005b20 <sys_open+0x72>
    80005b16:	0464d703          	lhu	a4,70(s1)
    80005b1a:	47a5                	li	a5,9
    80005b1c:	0ce7ed63          	bltu	a5,a4,80005bf6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	dce080e7          	jalr	-562(ra) # 800048ee <filealloc>
    80005b28:	89aa                	mv	s3,a0
    80005b2a:	10050363          	beqz	a0,80005c30 <sys_open+0x182>
    80005b2e:	00000097          	auipc	ra,0x0
    80005b32:	904080e7          	jalr	-1788(ra) # 80005432 <fdalloc>
    80005b36:	892a                	mv	s2,a0
    80005b38:	0e054763          	bltz	a0,80005c26 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b3c:	04449703          	lh	a4,68(s1)
    80005b40:	478d                	li	a5,3
    80005b42:	0cf70563          	beq	a4,a5,80005c0c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b46:	4789                	li	a5,2
    80005b48:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b4c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b50:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b54:	f4c42783          	lw	a5,-180(s0)
    80005b58:	0017c713          	xori	a4,a5,1
    80005b5c:	8b05                	andi	a4,a4,1
    80005b5e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b62:	0037f713          	andi	a4,a5,3
    80005b66:	00e03733          	snez	a4,a4
    80005b6a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b6e:	4007f793          	andi	a5,a5,1024
    80005b72:	c791                	beqz	a5,80005b7e <sys_open+0xd0>
    80005b74:	04449703          	lh	a4,68(s1)
    80005b78:	4789                	li	a5,2
    80005b7a:	0af70063          	beq	a4,a5,80005c1a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b7e:	8526                	mv	a0,s1
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	05e080e7          	jalr	94(ra) # 80003bde <iunlock>
  end_op();
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	9d6080e7          	jalr	-1578(ra) # 8000455e <end_op>

  return fd;
    80005b90:	854a                	mv	a0,s2
}
    80005b92:	70ea                	ld	ra,184(sp)
    80005b94:	744a                	ld	s0,176(sp)
    80005b96:	74aa                	ld	s1,168(sp)
    80005b98:	790a                	ld	s2,160(sp)
    80005b9a:	69ea                	ld	s3,152(sp)
    80005b9c:	6129                	addi	sp,sp,192
    80005b9e:	8082                	ret
      end_op();
    80005ba0:	fffff097          	auipc	ra,0xfffff
    80005ba4:	9be080e7          	jalr	-1602(ra) # 8000455e <end_op>
      return -1;
    80005ba8:	557d                	li	a0,-1
    80005baa:	b7e5                	j	80005b92 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bac:	f5040513          	addi	a0,s0,-176
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	712080e7          	jalr	1810(ra) # 800042c2 <namei>
    80005bb8:	84aa                	mv	s1,a0
    80005bba:	c905                	beqz	a0,80005bea <sys_open+0x13c>
    ilock(ip);
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	f60080e7          	jalr	-160(ra) # 80003b1c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bc4:	04449703          	lh	a4,68(s1)
    80005bc8:	4785                	li	a5,1
    80005bca:	f4f711e3          	bne	a4,a5,80005b0c <sys_open+0x5e>
    80005bce:	f4c42783          	lw	a5,-180(s0)
    80005bd2:	d7b9                	beqz	a5,80005b20 <sys_open+0x72>
      iunlockput(ip);
    80005bd4:	8526                	mv	a0,s1
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	1a8080e7          	jalr	424(ra) # 80003d7e <iunlockput>
      end_op();
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	980080e7          	jalr	-1664(ra) # 8000455e <end_op>
      return -1;
    80005be6:	557d                	li	a0,-1
    80005be8:	b76d                	j	80005b92 <sys_open+0xe4>
      end_op();
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	974080e7          	jalr	-1676(ra) # 8000455e <end_op>
      return -1;
    80005bf2:	557d                	li	a0,-1
    80005bf4:	bf79                	j	80005b92 <sys_open+0xe4>
    iunlockput(ip);
    80005bf6:	8526                	mv	a0,s1
    80005bf8:	ffffe097          	auipc	ra,0xffffe
    80005bfc:	186080e7          	jalr	390(ra) # 80003d7e <iunlockput>
    end_op();
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	95e080e7          	jalr	-1698(ra) # 8000455e <end_op>
    return -1;
    80005c08:	557d                	li	a0,-1
    80005c0a:	b761                	j	80005b92 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c0c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c10:	04649783          	lh	a5,70(s1)
    80005c14:	02f99223          	sh	a5,36(s3)
    80005c18:	bf25                	j	80005b50 <sys_open+0xa2>
    itrunc(ip);
    80005c1a:	8526                	mv	a0,s1
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	00e080e7          	jalr	14(ra) # 80003c2a <itrunc>
    80005c24:	bfa9                	j	80005b7e <sys_open+0xd0>
      fileclose(f);
    80005c26:	854e                	mv	a0,s3
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	d82080e7          	jalr	-638(ra) # 800049aa <fileclose>
    iunlockput(ip);
    80005c30:	8526                	mv	a0,s1
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	14c080e7          	jalr	332(ra) # 80003d7e <iunlockput>
    end_op();
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	924080e7          	jalr	-1756(ra) # 8000455e <end_op>
    return -1;
    80005c42:	557d                	li	a0,-1
    80005c44:	b7b9                	j	80005b92 <sys_open+0xe4>

0000000080005c46 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c46:	7175                	addi	sp,sp,-144
    80005c48:	e506                	sd	ra,136(sp)
    80005c4a:	e122                	sd	s0,128(sp)
    80005c4c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	890080e7          	jalr	-1904(ra) # 800044de <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c56:	08000613          	li	a2,128
    80005c5a:	f7040593          	addi	a1,s0,-144
    80005c5e:	4501                	li	a0,0
    80005c60:	ffffd097          	auipc	ra,0xffffd
    80005c64:	278080e7          	jalr	632(ra) # 80002ed8 <argstr>
    80005c68:	02054963          	bltz	a0,80005c9a <sys_mkdir+0x54>
    80005c6c:	4681                	li	a3,0
    80005c6e:	4601                	li	a2,0
    80005c70:	4585                	li	a1,1
    80005c72:	f7040513          	addi	a0,s0,-144
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	7fe080e7          	jalr	2046(ra) # 80005474 <create>
    80005c7e:	cd11                	beqz	a0,80005c9a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	0fe080e7          	jalr	254(ra) # 80003d7e <iunlockput>
  end_op();
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	8d6080e7          	jalr	-1834(ra) # 8000455e <end_op>
  return 0;
    80005c90:	4501                	li	a0,0
}
    80005c92:	60aa                	ld	ra,136(sp)
    80005c94:	640a                	ld	s0,128(sp)
    80005c96:	6149                	addi	sp,sp,144
    80005c98:	8082                	ret
    end_op();
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	8c4080e7          	jalr	-1852(ra) # 8000455e <end_op>
    return -1;
    80005ca2:	557d                	li	a0,-1
    80005ca4:	b7fd                	j	80005c92 <sys_mkdir+0x4c>

0000000080005ca6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ca6:	7135                	addi	sp,sp,-160
    80005ca8:	ed06                	sd	ra,152(sp)
    80005caa:	e922                	sd	s0,144(sp)
    80005cac:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	830080e7          	jalr	-2000(ra) # 800044de <begin_op>
  argint(1, &major);
    80005cb6:	f6c40593          	addi	a1,s0,-148
    80005cba:	4505                	li	a0,1
    80005cbc:	ffffd097          	auipc	ra,0xffffd
    80005cc0:	1dc080e7          	jalr	476(ra) # 80002e98 <argint>
  argint(2, &minor);
    80005cc4:	f6840593          	addi	a1,s0,-152
    80005cc8:	4509                	li	a0,2
    80005cca:	ffffd097          	auipc	ra,0xffffd
    80005cce:	1ce080e7          	jalr	462(ra) # 80002e98 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cd2:	08000613          	li	a2,128
    80005cd6:	f7040593          	addi	a1,s0,-144
    80005cda:	4501                	li	a0,0
    80005cdc:	ffffd097          	auipc	ra,0xffffd
    80005ce0:	1fc080e7          	jalr	508(ra) # 80002ed8 <argstr>
    80005ce4:	02054b63          	bltz	a0,80005d1a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ce8:	f6841683          	lh	a3,-152(s0)
    80005cec:	f6c41603          	lh	a2,-148(s0)
    80005cf0:	458d                	li	a1,3
    80005cf2:	f7040513          	addi	a0,s0,-144
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	77e080e7          	jalr	1918(ra) # 80005474 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cfe:	cd11                	beqz	a0,80005d1a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	07e080e7          	jalr	126(ra) # 80003d7e <iunlockput>
  end_op();
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	856080e7          	jalr	-1962(ra) # 8000455e <end_op>
  return 0;
    80005d10:	4501                	li	a0,0
}
    80005d12:	60ea                	ld	ra,152(sp)
    80005d14:	644a                	ld	s0,144(sp)
    80005d16:	610d                	addi	sp,sp,160
    80005d18:	8082                	ret
    end_op();
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	844080e7          	jalr	-1980(ra) # 8000455e <end_op>
    return -1;
    80005d22:	557d                	li	a0,-1
    80005d24:	b7fd                	j	80005d12 <sys_mknod+0x6c>

0000000080005d26 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d26:	7135                	addi	sp,sp,-160
    80005d28:	ed06                	sd	ra,152(sp)
    80005d2a:	e922                	sd	s0,144(sp)
    80005d2c:	e526                	sd	s1,136(sp)
    80005d2e:	e14a                	sd	s2,128(sp)
    80005d30:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d32:	ffffc097          	auipc	ra,0xffffc
    80005d36:	e5a080e7          	jalr	-422(ra) # 80001b8c <myproc>
    80005d3a:	892a                	mv	s2,a0
  
  begin_op();
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	7a2080e7          	jalr	1954(ra) # 800044de <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d44:	08000613          	li	a2,128
    80005d48:	f6040593          	addi	a1,s0,-160
    80005d4c:	4501                	li	a0,0
    80005d4e:	ffffd097          	auipc	ra,0xffffd
    80005d52:	18a080e7          	jalr	394(ra) # 80002ed8 <argstr>
    80005d56:	04054b63          	bltz	a0,80005dac <sys_chdir+0x86>
    80005d5a:	f6040513          	addi	a0,s0,-160
    80005d5e:	ffffe097          	auipc	ra,0xffffe
    80005d62:	564080e7          	jalr	1380(ra) # 800042c2 <namei>
    80005d66:	84aa                	mv	s1,a0
    80005d68:	c131                	beqz	a0,80005dac <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d6a:	ffffe097          	auipc	ra,0xffffe
    80005d6e:	db2080e7          	jalr	-590(ra) # 80003b1c <ilock>
  if(ip->type != T_DIR){
    80005d72:	04449703          	lh	a4,68(s1)
    80005d76:	4785                	li	a5,1
    80005d78:	04f71063          	bne	a4,a5,80005db8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d7c:	8526                	mv	a0,s1
    80005d7e:	ffffe097          	auipc	ra,0xffffe
    80005d82:	e60080e7          	jalr	-416(ra) # 80003bde <iunlock>
  iput(p->cwd);
    80005d86:	15093503          	ld	a0,336(s2)
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	f4c080e7          	jalr	-180(ra) # 80003cd6 <iput>
  end_op();
    80005d92:	ffffe097          	auipc	ra,0xffffe
    80005d96:	7cc080e7          	jalr	1996(ra) # 8000455e <end_op>
  p->cwd = ip;
    80005d9a:	14993823          	sd	s1,336(s2)
  return 0;
    80005d9e:	4501                	li	a0,0
}
    80005da0:	60ea                	ld	ra,152(sp)
    80005da2:	644a                	ld	s0,144(sp)
    80005da4:	64aa                	ld	s1,136(sp)
    80005da6:	690a                	ld	s2,128(sp)
    80005da8:	610d                	addi	sp,sp,160
    80005daa:	8082                	ret
    end_op();
    80005dac:	ffffe097          	auipc	ra,0xffffe
    80005db0:	7b2080e7          	jalr	1970(ra) # 8000455e <end_op>
    return -1;
    80005db4:	557d                	li	a0,-1
    80005db6:	b7ed                	j	80005da0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005db8:	8526                	mv	a0,s1
    80005dba:	ffffe097          	auipc	ra,0xffffe
    80005dbe:	fc4080e7          	jalr	-60(ra) # 80003d7e <iunlockput>
    end_op();
    80005dc2:	ffffe097          	auipc	ra,0xffffe
    80005dc6:	79c080e7          	jalr	1948(ra) # 8000455e <end_op>
    return -1;
    80005dca:	557d                	li	a0,-1
    80005dcc:	bfd1                	j	80005da0 <sys_chdir+0x7a>

0000000080005dce <sys_exec>:

uint64
sys_exec(void)
{
    80005dce:	7145                	addi	sp,sp,-464
    80005dd0:	e786                	sd	ra,456(sp)
    80005dd2:	e3a2                	sd	s0,448(sp)
    80005dd4:	ff26                	sd	s1,440(sp)
    80005dd6:	fb4a                	sd	s2,432(sp)
    80005dd8:	f74e                	sd	s3,424(sp)
    80005dda:	f352                	sd	s4,416(sp)
    80005ddc:	ef56                	sd	s5,408(sp)
    80005dde:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005de0:	e3840593          	addi	a1,s0,-456
    80005de4:	4505                	li	a0,1
    80005de6:	ffffd097          	auipc	ra,0xffffd
    80005dea:	0d2080e7          	jalr	210(ra) # 80002eb8 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005dee:	08000613          	li	a2,128
    80005df2:	f4040593          	addi	a1,s0,-192
    80005df6:	4501                	li	a0,0
    80005df8:	ffffd097          	auipc	ra,0xffffd
    80005dfc:	0e0080e7          	jalr	224(ra) # 80002ed8 <argstr>
    80005e00:	87aa                	mv	a5,a0
    return -1;
    80005e02:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e04:	0c07c263          	bltz	a5,80005ec8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e08:	10000613          	li	a2,256
    80005e0c:	4581                	li	a1,0
    80005e0e:	e4040513          	addi	a0,s0,-448
    80005e12:	ffffb097          	auipc	ra,0xffffb
    80005e16:	f9c080e7          	jalr	-100(ra) # 80000dae <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e1a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e1e:	89a6                	mv	s3,s1
    80005e20:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e22:	02000a13          	li	s4,32
    80005e26:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e2a:	00391513          	slli	a0,s2,0x3
    80005e2e:	e3040593          	addi	a1,s0,-464
    80005e32:	e3843783          	ld	a5,-456(s0)
    80005e36:	953e                	add	a0,a0,a5
    80005e38:	ffffd097          	auipc	ra,0xffffd
    80005e3c:	fc2080e7          	jalr	-62(ra) # 80002dfa <fetchaddr>
    80005e40:	02054a63          	bltz	a0,80005e74 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005e44:	e3043783          	ld	a5,-464(s0)
    80005e48:	c3b9                	beqz	a5,80005e8e <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e4a:	ffffb097          	auipc	ra,0xffffb
    80005e4e:	d2c080e7          	jalr	-724(ra) # 80000b76 <kalloc>
    80005e52:	85aa                	mv	a1,a0
    80005e54:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e58:	cd11                	beqz	a0,80005e74 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e5a:	6605                	lui	a2,0x1
    80005e5c:	e3043503          	ld	a0,-464(s0)
    80005e60:	ffffd097          	auipc	ra,0xffffd
    80005e64:	fec080e7          	jalr	-20(ra) # 80002e4c <fetchstr>
    80005e68:	00054663          	bltz	a0,80005e74 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005e6c:	0905                	addi	s2,s2,1
    80005e6e:	09a1                	addi	s3,s3,8
    80005e70:	fb491be3          	bne	s2,s4,80005e26 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e74:	10048913          	addi	s2,s1,256
    80005e78:	6088                	ld	a0,0(s1)
    80005e7a:	c531                	beqz	a0,80005ec6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005e7c:	ffffb097          	auipc	ra,0xffffb
    80005e80:	b94080e7          	jalr	-1132(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e84:	04a1                	addi	s1,s1,8
    80005e86:	ff2499e3          	bne	s1,s2,80005e78 <sys_exec+0xaa>
  return -1;
    80005e8a:	557d                	li	a0,-1
    80005e8c:	a835                	j	80005ec8 <sys_exec+0xfa>
      argv[i] = 0;
    80005e8e:	0a8e                	slli	s5,s5,0x3
    80005e90:	fc040793          	addi	a5,s0,-64
    80005e94:	9abe                	add	s5,s5,a5
    80005e96:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e9a:	e4040593          	addi	a1,s0,-448
    80005e9e:	f4040513          	addi	a0,s0,-192
    80005ea2:	fffff097          	auipc	ra,0xfffff
    80005ea6:	190080e7          	jalr	400(ra) # 80005032 <exec>
    80005eaa:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eac:	10048993          	addi	s3,s1,256
    80005eb0:	6088                	ld	a0,0(s1)
    80005eb2:	c901                	beqz	a0,80005ec2 <sys_exec+0xf4>
    kfree(argv[i]);
    80005eb4:	ffffb097          	auipc	ra,0xffffb
    80005eb8:	b5c080e7          	jalr	-1188(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ebc:	04a1                	addi	s1,s1,8
    80005ebe:	ff3499e3          	bne	s1,s3,80005eb0 <sys_exec+0xe2>
  return ret;
    80005ec2:	854a                	mv	a0,s2
    80005ec4:	a011                	j	80005ec8 <sys_exec+0xfa>
  return -1;
    80005ec6:	557d                	li	a0,-1
}
    80005ec8:	60be                	ld	ra,456(sp)
    80005eca:	641e                	ld	s0,448(sp)
    80005ecc:	74fa                	ld	s1,440(sp)
    80005ece:	795a                	ld	s2,432(sp)
    80005ed0:	79ba                	ld	s3,424(sp)
    80005ed2:	7a1a                	ld	s4,416(sp)
    80005ed4:	6afa                	ld	s5,408(sp)
    80005ed6:	6179                	addi	sp,sp,464
    80005ed8:	8082                	ret

0000000080005eda <sys_pipe>:

uint64
sys_pipe(void)
{
    80005eda:	7139                	addi	sp,sp,-64
    80005edc:	fc06                	sd	ra,56(sp)
    80005ede:	f822                	sd	s0,48(sp)
    80005ee0:	f426                	sd	s1,40(sp)
    80005ee2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ee4:	ffffc097          	auipc	ra,0xffffc
    80005ee8:	ca8080e7          	jalr	-856(ra) # 80001b8c <myproc>
    80005eec:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005eee:	fd840593          	addi	a1,s0,-40
    80005ef2:	4501                	li	a0,0
    80005ef4:	ffffd097          	auipc	ra,0xffffd
    80005ef8:	fc4080e7          	jalr	-60(ra) # 80002eb8 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005efc:	fc840593          	addi	a1,s0,-56
    80005f00:	fd040513          	addi	a0,s0,-48
    80005f04:	fffff097          	auipc	ra,0xfffff
    80005f08:	dd6080e7          	jalr	-554(ra) # 80004cda <pipealloc>
    return -1;
    80005f0c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f0e:	0c054463          	bltz	a0,80005fd6 <sys_pipe+0xfc>
  fd0 = -1;
    80005f12:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f16:	fd043503          	ld	a0,-48(s0)
    80005f1a:	fffff097          	auipc	ra,0xfffff
    80005f1e:	518080e7          	jalr	1304(ra) # 80005432 <fdalloc>
    80005f22:	fca42223          	sw	a0,-60(s0)
    80005f26:	08054b63          	bltz	a0,80005fbc <sys_pipe+0xe2>
    80005f2a:	fc843503          	ld	a0,-56(s0)
    80005f2e:	fffff097          	auipc	ra,0xfffff
    80005f32:	504080e7          	jalr	1284(ra) # 80005432 <fdalloc>
    80005f36:	fca42023          	sw	a0,-64(s0)
    80005f3a:	06054863          	bltz	a0,80005faa <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f3e:	4691                	li	a3,4
    80005f40:	fc440613          	addi	a2,s0,-60
    80005f44:	fd843583          	ld	a1,-40(s0)
    80005f48:	68a8                	ld	a0,80(s1)
    80005f4a:	ffffc097          	auipc	ra,0xffffc
    80005f4e:	802080e7          	jalr	-2046(ra) # 8000174c <copyout>
    80005f52:	02054063          	bltz	a0,80005f72 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f56:	4691                	li	a3,4
    80005f58:	fc040613          	addi	a2,s0,-64
    80005f5c:	fd843583          	ld	a1,-40(s0)
    80005f60:	0591                	addi	a1,a1,4
    80005f62:	68a8                	ld	a0,80(s1)
    80005f64:	ffffb097          	auipc	ra,0xffffb
    80005f68:	7e8080e7          	jalr	2024(ra) # 8000174c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f6c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f6e:	06055463          	bgez	a0,80005fd6 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005f72:	fc442783          	lw	a5,-60(s0)
    80005f76:	07e9                	addi	a5,a5,26
    80005f78:	078e                	slli	a5,a5,0x3
    80005f7a:	97a6                	add	a5,a5,s1
    80005f7c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f80:	fc042503          	lw	a0,-64(s0)
    80005f84:	0569                	addi	a0,a0,26
    80005f86:	050e                	slli	a0,a0,0x3
    80005f88:	94aa                	add	s1,s1,a0
    80005f8a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f8e:	fd043503          	ld	a0,-48(s0)
    80005f92:	fffff097          	auipc	ra,0xfffff
    80005f96:	a18080e7          	jalr	-1512(ra) # 800049aa <fileclose>
    fileclose(wf);
    80005f9a:	fc843503          	ld	a0,-56(s0)
    80005f9e:	fffff097          	auipc	ra,0xfffff
    80005fa2:	a0c080e7          	jalr	-1524(ra) # 800049aa <fileclose>
    return -1;
    80005fa6:	57fd                	li	a5,-1
    80005fa8:	a03d                	j	80005fd6 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005faa:	fc442783          	lw	a5,-60(s0)
    80005fae:	0007c763          	bltz	a5,80005fbc <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005fb2:	07e9                	addi	a5,a5,26
    80005fb4:	078e                	slli	a5,a5,0x3
    80005fb6:	94be                	add	s1,s1,a5
    80005fb8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005fbc:	fd043503          	ld	a0,-48(s0)
    80005fc0:	fffff097          	auipc	ra,0xfffff
    80005fc4:	9ea080e7          	jalr	-1558(ra) # 800049aa <fileclose>
    fileclose(wf);
    80005fc8:	fc843503          	ld	a0,-56(s0)
    80005fcc:	fffff097          	auipc	ra,0xfffff
    80005fd0:	9de080e7          	jalr	-1570(ra) # 800049aa <fileclose>
    return -1;
    80005fd4:	57fd                	li	a5,-1
}
    80005fd6:	853e                	mv	a0,a5
    80005fd8:	70e2                	ld	ra,56(sp)
    80005fda:	7442                	ld	s0,48(sp)
    80005fdc:	74a2                	ld	s1,40(sp)
    80005fde:	6121                	addi	sp,sp,64
    80005fe0:	8082                	ret
	...

0000000080005ff0 <kernelvec>:
    80005ff0:	7111                	addi	sp,sp,-256
    80005ff2:	e006                	sd	ra,0(sp)
    80005ff4:	e40a                	sd	sp,8(sp)
    80005ff6:	e80e                	sd	gp,16(sp)
    80005ff8:	ec12                	sd	tp,24(sp)
    80005ffa:	f016                	sd	t0,32(sp)
    80005ffc:	f41a                	sd	t1,40(sp)
    80005ffe:	f81e                	sd	t2,48(sp)
    80006000:	fc22                	sd	s0,56(sp)
    80006002:	e0a6                	sd	s1,64(sp)
    80006004:	e4aa                	sd	a0,72(sp)
    80006006:	e8ae                	sd	a1,80(sp)
    80006008:	ecb2                	sd	a2,88(sp)
    8000600a:	f0b6                	sd	a3,96(sp)
    8000600c:	f4ba                	sd	a4,104(sp)
    8000600e:	f8be                	sd	a5,112(sp)
    80006010:	fcc2                	sd	a6,120(sp)
    80006012:	e146                	sd	a7,128(sp)
    80006014:	e54a                	sd	s2,136(sp)
    80006016:	e94e                	sd	s3,144(sp)
    80006018:	ed52                	sd	s4,152(sp)
    8000601a:	f156                	sd	s5,160(sp)
    8000601c:	f55a                	sd	s6,168(sp)
    8000601e:	f95e                	sd	s7,176(sp)
    80006020:	fd62                	sd	s8,184(sp)
    80006022:	e1e6                	sd	s9,192(sp)
    80006024:	e5ea                	sd	s10,200(sp)
    80006026:	e9ee                	sd	s11,208(sp)
    80006028:	edf2                	sd	t3,216(sp)
    8000602a:	f1f6                	sd	t4,224(sp)
    8000602c:	f5fa                	sd	t5,232(sp)
    8000602e:	f9fe                	sd	t6,240(sp)
    80006030:	c97fc0ef          	jal	ra,80002cc6 <kerneltrap>
    80006034:	6082                	ld	ra,0(sp)
    80006036:	6122                	ld	sp,8(sp)
    80006038:	61c2                	ld	gp,16(sp)
    8000603a:	7282                	ld	t0,32(sp)
    8000603c:	7322                	ld	t1,40(sp)
    8000603e:	73c2                	ld	t2,48(sp)
    80006040:	7462                	ld	s0,56(sp)
    80006042:	6486                	ld	s1,64(sp)
    80006044:	6526                	ld	a0,72(sp)
    80006046:	65c6                	ld	a1,80(sp)
    80006048:	6666                	ld	a2,88(sp)
    8000604a:	7686                	ld	a3,96(sp)
    8000604c:	7726                	ld	a4,104(sp)
    8000604e:	77c6                	ld	a5,112(sp)
    80006050:	7866                	ld	a6,120(sp)
    80006052:	688a                	ld	a7,128(sp)
    80006054:	692a                	ld	s2,136(sp)
    80006056:	69ca                	ld	s3,144(sp)
    80006058:	6a6a                	ld	s4,152(sp)
    8000605a:	7a8a                	ld	s5,160(sp)
    8000605c:	7b2a                	ld	s6,168(sp)
    8000605e:	7bca                	ld	s7,176(sp)
    80006060:	7c6a                	ld	s8,184(sp)
    80006062:	6c8e                	ld	s9,192(sp)
    80006064:	6d2e                	ld	s10,200(sp)
    80006066:	6dce                	ld	s11,208(sp)
    80006068:	6e6e                	ld	t3,216(sp)
    8000606a:	7e8e                	ld	t4,224(sp)
    8000606c:	7f2e                	ld	t5,232(sp)
    8000606e:	7fce                	ld	t6,240(sp)
    80006070:	6111                	addi	sp,sp,256
    80006072:	10200073          	sret
    80006076:	00000013          	nop
    8000607a:	00000013          	nop
    8000607e:	0001                	nop

0000000080006080 <timervec>:
    80006080:	34051573          	csrrw	a0,mscratch,a0
    80006084:	e10c                	sd	a1,0(a0)
    80006086:	e510                	sd	a2,8(a0)
    80006088:	e914                	sd	a3,16(a0)
    8000608a:	6d0c                	ld	a1,24(a0)
    8000608c:	7110                	ld	a2,32(a0)
    8000608e:	6194                	ld	a3,0(a1)
    80006090:	96b2                	add	a3,a3,a2
    80006092:	e194                	sd	a3,0(a1)
    80006094:	4589                	li	a1,2
    80006096:	14459073          	csrw	sip,a1
    8000609a:	6914                	ld	a3,16(a0)
    8000609c:	6510                	ld	a2,8(a0)
    8000609e:	610c                	ld	a1,0(a0)
    800060a0:	34051573          	csrrw	a0,mscratch,a0
    800060a4:	30200073          	mret
	...

00000000800060aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060aa:	1141                	addi	sp,sp,-16
    800060ac:	e422                	sd	s0,8(sp)
    800060ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060b0:	0c0007b7          	lui	a5,0xc000
    800060b4:	4705                	li	a4,1
    800060b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060b8:	c3d8                	sw	a4,4(a5)
}
    800060ba:	6422                	ld	s0,8(sp)
    800060bc:	0141                	addi	sp,sp,16
    800060be:	8082                	ret

00000000800060c0 <plicinithart>:

void
plicinithart(void)
{
    800060c0:	1141                	addi	sp,sp,-16
    800060c2:	e406                	sd	ra,8(sp)
    800060c4:	e022                	sd	s0,0(sp)
    800060c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060c8:	ffffc097          	auipc	ra,0xffffc
    800060cc:	a98080e7          	jalr	-1384(ra) # 80001b60 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060d0:	0085171b          	slliw	a4,a0,0x8
    800060d4:	0c0027b7          	lui	a5,0xc002
    800060d8:	97ba                	add	a5,a5,a4
    800060da:	40200713          	li	a4,1026
    800060de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060e2:	00d5151b          	slliw	a0,a0,0xd
    800060e6:	0c2017b7          	lui	a5,0xc201
    800060ea:	953e                	add	a0,a0,a5
    800060ec:	00052023          	sw	zero,0(a0)
}
    800060f0:	60a2                	ld	ra,8(sp)
    800060f2:	6402                	ld	s0,0(sp)
    800060f4:	0141                	addi	sp,sp,16
    800060f6:	8082                	ret

00000000800060f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060f8:	1141                	addi	sp,sp,-16
    800060fa:	e406                	sd	ra,8(sp)
    800060fc:	e022                	sd	s0,0(sp)
    800060fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006100:	ffffc097          	auipc	ra,0xffffc
    80006104:	a60080e7          	jalr	-1440(ra) # 80001b60 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006108:	00d5179b          	slliw	a5,a0,0xd
    8000610c:	0c201537          	lui	a0,0xc201
    80006110:	953e                	add	a0,a0,a5
  return irq;
}
    80006112:	4148                	lw	a0,4(a0)
    80006114:	60a2                	ld	ra,8(sp)
    80006116:	6402                	ld	s0,0(sp)
    80006118:	0141                	addi	sp,sp,16
    8000611a:	8082                	ret

000000008000611c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000611c:	1101                	addi	sp,sp,-32
    8000611e:	ec06                	sd	ra,24(sp)
    80006120:	e822                	sd	s0,16(sp)
    80006122:	e426                	sd	s1,8(sp)
    80006124:	1000                	addi	s0,sp,32
    80006126:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006128:	ffffc097          	auipc	ra,0xffffc
    8000612c:	a38080e7          	jalr	-1480(ra) # 80001b60 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006130:	00d5151b          	slliw	a0,a0,0xd
    80006134:	0c2017b7          	lui	a5,0xc201
    80006138:	97aa                	add	a5,a5,a0
    8000613a:	c3c4                	sw	s1,4(a5)
}
    8000613c:	60e2                	ld	ra,24(sp)
    8000613e:	6442                	ld	s0,16(sp)
    80006140:	64a2                	ld	s1,8(sp)
    80006142:	6105                	addi	sp,sp,32
    80006144:	8082                	ret

0000000080006146 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006146:	1141                	addi	sp,sp,-16
    80006148:	e406                	sd	ra,8(sp)
    8000614a:	e022                	sd	s0,0(sp)
    8000614c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000614e:	479d                	li	a5,7
    80006150:	04a7cc63          	blt	a5,a0,800061a8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006154:	0001c797          	auipc	a5,0x1c
    80006158:	c4c78793          	addi	a5,a5,-948 # 80021da0 <disk>
    8000615c:	97aa                	add	a5,a5,a0
    8000615e:	0187c783          	lbu	a5,24(a5)
    80006162:	ebb9                	bnez	a5,800061b8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006164:	00451613          	slli	a2,a0,0x4
    80006168:	0001c797          	auipc	a5,0x1c
    8000616c:	c3878793          	addi	a5,a5,-968 # 80021da0 <disk>
    80006170:	6394                	ld	a3,0(a5)
    80006172:	96b2                	add	a3,a3,a2
    80006174:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006178:	6398                	ld	a4,0(a5)
    8000617a:	9732                	add	a4,a4,a2
    8000617c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006180:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006184:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006188:	953e                	add	a0,a0,a5
    8000618a:	4785                	li	a5,1
    8000618c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006190:	0001c517          	auipc	a0,0x1c
    80006194:	c2850513          	addi	a0,a0,-984 # 80021db8 <disk+0x18>
    80006198:	ffffc097          	auipc	ra,0xffffc
    8000619c:	1bc080e7          	jalr	444(ra) # 80002354 <wakeup>
}
    800061a0:	60a2                	ld	ra,8(sp)
    800061a2:	6402                	ld	s0,0(sp)
    800061a4:	0141                	addi	sp,sp,16
    800061a6:	8082                	ret
    panic("free_desc 1");
    800061a8:	00002517          	auipc	a0,0x2
    800061ac:	6d050513          	addi	a0,a0,1744 # 80008878 <syscalls+0x318>
    800061b0:	ffffa097          	auipc	ra,0xffffa
    800061b4:	394080e7          	jalr	916(ra) # 80000544 <panic>
    panic("free_desc 2");
    800061b8:	00002517          	auipc	a0,0x2
    800061bc:	6d050513          	addi	a0,a0,1744 # 80008888 <syscalls+0x328>
    800061c0:	ffffa097          	auipc	ra,0xffffa
    800061c4:	384080e7          	jalr	900(ra) # 80000544 <panic>

00000000800061c8 <virtio_disk_init>:
{
    800061c8:	1101                	addi	sp,sp,-32
    800061ca:	ec06                	sd	ra,24(sp)
    800061cc:	e822                	sd	s0,16(sp)
    800061ce:	e426                	sd	s1,8(sp)
    800061d0:	e04a                	sd	s2,0(sp)
    800061d2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061d4:	00002597          	auipc	a1,0x2
    800061d8:	6c458593          	addi	a1,a1,1732 # 80008898 <syscalls+0x338>
    800061dc:	0001c517          	auipc	a0,0x1c
    800061e0:	cec50513          	addi	a0,a0,-788 # 80021ec8 <disk+0x128>
    800061e4:	ffffb097          	auipc	ra,0xffffb
    800061e8:	a3e080e7          	jalr	-1474(ra) # 80000c22 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061ec:	100017b7          	lui	a5,0x10001
    800061f0:	4398                	lw	a4,0(a5)
    800061f2:	2701                	sext.w	a4,a4
    800061f4:	747277b7          	lui	a5,0x74727
    800061f8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061fc:	14f71e63          	bne	a4,a5,80006358 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006200:	100017b7          	lui	a5,0x10001
    80006204:	43dc                	lw	a5,4(a5)
    80006206:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006208:	4709                	li	a4,2
    8000620a:	14e79763          	bne	a5,a4,80006358 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000620e:	100017b7          	lui	a5,0x10001
    80006212:	479c                	lw	a5,8(a5)
    80006214:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006216:	14e79163          	bne	a5,a4,80006358 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000621a:	100017b7          	lui	a5,0x10001
    8000621e:	47d8                	lw	a4,12(a5)
    80006220:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006222:	554d47b7          	lui	a5,0x554d4
    80006226:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000622a:	12f71763          	bne	a4,a5,80006358 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000622e:	100017b7          	lui	a5,0x10001
    80006232:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006236:	4705                	li	a4,1
    80006238:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000623a:	470d                	li	a4,3
    8000623c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000623e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006240:	c7ffe737          	lui	a4,0xc7ffe
    80006244:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc87f>
    80006248:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000624a:	2701                	sext.w	a4,a4
    8000624c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000624e:	472d                	li	a4,11
    80006250:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006252:	0707a903          	lw	s2,112(a5)
    80006256:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006258:	00897793          	andi	a5,s2,8
    8000625c:	10078663          	beqz	a5,80006368 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006260:	100017b7          	lui	a5,0x10001
    80006264:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006268:	43fc                	lw	a5,68(a5)
    8000626a:	2781                	sext.w	a5,a5
    8000626c:	10079663          	bnez	a5,80006378 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006270:	100017b7          	lui	a5,0x10001
    80006274:	5bdc                	lw	a5,52(a5)
    80006276:	2781                	sext.w	a5,a5
  if(max == 0)
    80006278:	10078863          	beqz	a5,80006388 <virtio_disk_init+0x1c0>
  if(max < NUM)
    8000627c:	471d                	li	a4,7
    8000627e:	10f77d63          	bgeu	a4,a5,80006398 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006282:	ffffb097          	auipc	ra,0xffffb
    80006286:	8f4080e7          	jalr	-1804(ra) # 80000b76 <kalloc>
    8000628a:	0001c497          	auipc	s1,0x1c
    8000628e:	b1648493          	addi	s1,s1,-1258 # 80021da0 <disk>
    80006292:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006294:	ffffb097          	auipc	ra,0xffffb
    80006298:	8e2080e7          	jalr	-1822(ra) # 80000b76 <kalloc>
    8000629c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000629e:	ffffb097          	auipc	ra,0xffffb
    800062a2:	8d8080e7          	jalr	-1832(ra) # 80000b76 <kalloc>
    800062a6:	87aa                	mv	a5,a0
    800062a8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800062aa:	6088                	ld	a0,0(s1)
    800062ac:	cd75                	beqz	a0,800063a8 <virtio_disk_init+0x1e0>
    800062ae:	0001c717          	auipc	a4,0x1c
    800062b2:	afa73703          	ld	a4,-1286(a4) # 80021da8 <disk+0x8>
    800062b6:	cb6d                	beqz	a4,800063a8 <virtio_disk_init+0x1e0>
    800062b8:	cbe5                	beqz	a5,800063a8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    800062ba:	6605                	lui	a2,0x1
    800062bc:	4581                	li	a1,0
    800062be:	ffffb097          	auipc	ra,0xffffb
    800062c2:	af0080e7          	jalr	-1296(ra) # 80000dae <memset>
  memset(disk.avail, 0, PGSIZE);
    800062c6:	0001c497          	auipc	s1,0x1c
    800062ca:	ada48493          	addi	s1,s1,-1318 # 80021da0 <disk>
    800062ce:	6605                	lui	a2,0x1
    800062d0:	4581                	li	a1,0
    800062d2:	6488                	ld	a0,8(s1)
    800062d4:	ffffb097          	auipc	ra,0xffffb
    800062d8:	ada080e7          	jalr	-1318(ra) # 80000dae <memset>
  memset(disk.used, 0, PGSIZE);
    800062dc:	6605                	lui	a2,0x1
    800062de:	4581                	li	a1,0
    800062e0:	6888                	ld	a0,16(s1)
    800062e2:	ffffb097          	auipc	ra,0xffffb
    800062e6:	acc080e7          	jalr	-1332(ra) # 80000dae <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062ea:	100017b7          	lui	a5,0x10001
    800062ee:	4721                	li	a4,8
    800062f0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800062f2:	4098                	lw	a4,0(s1)
    800062f4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800062f8:	40d8                	lw	a4,4(s1)
    800062fa:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800062fe:	6498                	ld	a4,8(s1)
    80006300:	0007069b          	sext.w	a3,a4
    80006304:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006308:	9701                	srai	a4,a4,0x20
    8000630a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000630e:	6898                	ld	a4,16(s1)
    80006310:	0007069b          	sext.w	a3,a4
    80006314:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006318:	9701                	srai	a4,a4,0x20
    8000631a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000631e:	4685                	li	a3,1
    80006320:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006322:	4705                	li	a4,1
    80006324:	00d48c23          	sb	a3,24(s1)
    80006328:	00e48ca3          	sb	a4,25(s1)
    8000632c:	00e48d23          	sb	a4,26(s1)
    80006330:	00e48da3          	sb	a4,27(s1)
    80006334:	00e48e23          	sb	a4,28(s1)
    80006338:	00e48ea3          	sb	a4,29(s1)
    8000633c:	00e48f23          	sb	a4,30(s1)
    80006340:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006344:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006348:	0727a823          	sw	s2,112(a5)
}
    8000634c:	60e2                	ld	ra,24(sp)
    8000634e:	6442                	ld	s0,16(sp)
    80006350:	64a2                	ld	s1,8(sp)
    80006352:	6902                	ld	s2,0(sp)
    80006354:	6105                	addi	sp,sp,32
    80006356:	8082                	ret
    panic("could not find virtio disk");
    80006358:	00002517          	auipc	a0,0x2
    8000635c:	55050513          	addi	a0,a0,1360 # 800088a8 <syscalls+0x348>
    80006360:	ffffa097          	auipc	ra,0xffffa
    80006364:	1e4080e7          	jalr	484(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006368:	00002517          	auipc	a0,0x2
    8000636c:	56050513          	addi	a0,a0,1376 # 800088c8 <syscalls+0x368>
    80006370:	ffffa097          	auipc	ra,0xffffa
    80006374:	1d4080e7          	jalr	468(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006378:	00002517          	auipc	a0,0x2
    8000637c:	57050513          	addi	a0,a0,1392 # 800088e8 <syscalls+0x388>
    80006380:	ffffa097          	auipc	ra,0xffffa
    80006384:	1c4080e7          	jalr	452(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006388:	00002517          	auipc	a0,0x2
    8000638c:	58050513          	addi	a0,a0,1408 # 80008908 <syscalls+0x3a8>
    80006390:	ffffa097          	auipc	ra,0xffffa
    80006394:	1b4080e7          	jalr	436(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006398:	00002517          	auipc	a0,0x2
    8000639c:	59050513          	addi	a0,a0,1424 # 80008928 <syscalls+0x3c8>
    800063a0:	ffffa097          	auipc	ra,0xffffa
    800063a4:	1a4080e7          	jalr	420(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800063a8:	00002517          	auipc	a0,0x2
    800063ac:	5a050513          	addi	a0,a0,1440 # 80008948 <syscalls+0x3e8>
    800063b0:	ffffa097          	auipc	ra,0xffffa
    800063b4:	194080e7          	jalr	404(ra) # 80000544 <panic>

00000000800063b8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063b8:	7159                	addi	sp,sp,-112
    800063ba:	f486                	sd	ra,104(sp)
    800063bc:	f0a2                	sd	s0,96(sp)
    800063be:	eca6                	sd	s1,88(sp)
    800063c0:	e8ca                	sd	s2,80(sp)
    800063c2:	e4ce                	sd	s3,72(sp)
    800063c4:	e0d2                	sd	s4,64(sp)
    800063c6:	fc56                	sd	s5,56(sp)
    800063c8:	f85a                	sd	s6,48(sp)
    800063ca:	f45e                	sd	s7,40(sp)
    800063cc:	f062                	sd	s8,32(sp)
    800063ce:	ec66                	sd	s9,24(sp)
    800063d0:	e86a                	sd	s10,16(sp)
    800063d2:	1880                	addi	s0,sp,112
    800063d4:	892a                	mv	s2,a0
    800063d6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063d8:	00c52c83          	lw	s9,12(a0)
    800063dc:	001c9c9b          	slliw	s9,s9,0x1
    800063e0:	1c82                	slli	s9,s9,0x20
    800063e2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800063e6:	0001c517          	auipc	a0,0x1c
    800063ea:	ae250513          	addi	a0,a0,-1310 # 80021ec8 <disk+0x128>
    800063ee:	ffffb097          	auipc	ra,0xffffb
    800063f2:	8c4080e7          	jalr	-1852(ra) # 80000cb2 <acquire>
  for(int i = 0; i < 3; i++){
    800063f6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063f8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800063fa:	0001cb17          	auipc	s6,0x1c
    800063fe:	9a6b0b13          	addi	s6,s6,-1626 # 80021da0 <disk>
  for(int i = 0; i < 3; i++){
    80006402:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006404:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006406:	0001cc17          	auipc	s8,0x1c
    8000640a:	ac2c0c13          	addi	s8,s8,-1342 # 80021ec8 <disk+0x128>
    8000640e:	a8b5                	j	8000648a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006410:	00fb06b3          	add	a3,s6,a5
    80006414:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006418:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000641a:	0207c563          	bltz	a5,80006444 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000641e:	2485                	addiw	s1,s1,1
    80006420:	0711                	addi	a4,a4,4
    80006422:	1f548a63          	beq	s1,s5,80006616 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006426:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006428:	0001c697          	auipc	a3,0x1c
    8000642c:	97868693          	addi	a3,a3,-1672 # 80021da0 <disk>
    80006430:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006432:	0186c583          	lbu	a1,24(a3)
    80006436:	fde9                	bnez	a1,80006410 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006438:	2785                	addiw	a5,a5,1
    8000643a:	0685                	addi	a3,a3,1
    8000643c:	ff779be3          	bne	a5,s7,80006432 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006440:	57fd                	li	a5,-1
    80006442:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006444:	02905a63          	blez	s1,80006478 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006448:	f9042503          	lw	a0,-112(s0)
    8000644c:	00000097          	auipc	ra,0x0
    80006450:	cfa080e7          	jalr	-774(ra) # 80006146 <free_desc>
      for(int j = 0; j < i; j++)
    80006454:	4785                	li	a5,1
    80006456:	0297d163          	bge	a5,s1,80006478 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000645a:	f9442503          	lw	a0,-108(s0)
    8000645e:	00000097          	auipc	ra,0x0
    80006462:	ce8080e7          	jalr	-792(ra) # 80006146 <free_desc>
      for(int j = 0; j < i; j++)
    80006466:	4789                	li	a5,2
    80006468:	0097d863          	bge	a5,s1,80006478 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000646c:	f9842503          	lw	a0,-104(s0)
    80006470:	00000097          	auipc	ra,0x0
    80006474:	cd6080e7          	jalr	-810(ra) # 80006146 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006478:	85e2                	mv	a1,s8
    8000647a:	0001c517          	auipc	a0,0x1c
    8000647e:	93e50513          	addi	a0,a0,-1730 # 80021db8 <disk+0x18>
    80006482:	ffffc097          	auipc	ra,0xffffc
    80006486:	e6e080e7          	jalr	-402(ra) # 800022f0 <sleep>
  for(int i = 0; i < 3; i++){
    8000648a:	f9040713          	addi	a4,s0,-112
    8000648e:	84ce                	mv	s1,s3
    80006490:	bf59                	j	80006426 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006492:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006496:	00479693          	slli	a3,a5,0x4
    8000649a:	0001c797          	auipc	a5,0x1c
    8000649e:	90678793          	addi	a5,a5,-1786 # 80021da0 <disk>
    800064a2:	97b6                	add	a5,a5,a3
    800064a4:	4685                	li	a3,1
    800064a6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064a8:	0001c597          	auipc	a1,0x1c
    800064ac:	8f858593          	addi	a1,a1,-1800 # 80021da0 <disk>
    800064b0:	00a60793          	addi	a5,a2,10
    800064b4:	0792                	slli	a5,a5,0x4
    800064b6:	97ae                	add	a5,a5,a1
    800064b8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800064bc:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064c0:	f6070693          	addi	a3,a4,-160
    800064c4:	619c                	ld	a5,0(a1)
    800064c6:	97b6                	add	a5,a5,a3
    800064c8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064ca:	6188                	ld	a0,0(a1)
    800064cc:	96aa                	add	a3,a3,a0
    800064ce:	47c1                	li	a5,16
    800064d0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064d2:	4785                	li	a5,1
    800064d4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800064d8:	f9442783          	lw	a5,-108(s0)
    800064dc:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064e0:	0792                	slli	a5,a5,0x4
    800064e2:	953e                	add	a0,a0,a5
    800064e4:	05890693          	addi	a3,s2,88
    800064e8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800064ea:	6188                	ld	a0,0(a1)
    800064ec:	97aa                	add	a5,a5,a0
    800064ee:	40000693          	li	a3,1024
    800064f2:	c794                	sw	a3,8(a5)
  if(write)
    800064f4:	100d0d63          	beqz	s10,8000660e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800064f8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064fc:	00c7d683          	lhu	a3,12(a5)
    80006500:	0016e693          	ori	a3,a3,1
    80006504:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006508:	f9842583          	lw	a1,-104(s0)
    8000650c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006510:	0001c697          	auipc	a3,0x1c
    80006514:	89068693          	addi	a3,a3,-1904 # 80021da0 <disk>
    80006518:	00260793          	addi	a5,a2,2
    8000651c:	0792                	slli	a5,a5,0x4
    8000651e:	97b6                	add	a5,a5,a3
    80006520:	587d                	li	a6,-1
    80006522:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006526:	0592                	slli	a1,a1,0x4
    80006528:	952e                	add	a0,a0,a1
    8000652a:	f9070713          	addi	a4,a4,-112
    8000652e:	9736                	add	a4,a4,a3
    80006530:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006532:	6298                	ld	a4,0(a3)
    80006534:	972e                	add	a4,a4,a1
    80006536:	4585                	li	a1,1
    80006538:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000653a:	4509                	li	a0,2
    8000653c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006540:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006544:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006548:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000654c:	6698                	ld	a4,8(a3)
    8000654e:	00275783          	lhu	a5,2(a4)
    80006552:	8b9d                	andi	a5,a5,7
    80006554:	0786                	slli	a5,a5,0x1
    80006556:	97ba                	add	a5,a5,a4
    80006558:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000655c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006560:	6698                	ld	a4,8(a3)
    80006562:	00275783          	lhu	a5,2(a4)
    80006566:	2785                	addiw	a5,a5,1
    80006568:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000656c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006570:	100017b7          	lui	a5,0x10001
    80006574:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006578:	00492703          	lw	a4,4(s2)
    8000657c:	4785                	li	a5,1
    8000657e:	02f71163          	bne	a4,a5,800065a0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006582:	0001c997          	auipc	s3,0x1c
    80006586:	94698993          	addi	s3,s3,-1722 # 80021ec8 <disk+0x128>
  while(b->disk == 1) {
    8000658a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000658c:	85ce                	mv	a1,s3
    8000658e:	854a                	mv	a0,s2
    80006590:	ffffc097          	auipc	ra,0xffffc
    80006594:	d60080e7          	jalr	-672(ra) # 800022f0 <sleep>
  while(b->disk == 1) {
    80006598:	00492783          	lw	a5,4(s2)
    8000659c:	fe9788e3          	beq	a5,s1,8000658c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800065a0:	f9042903          	lw	s2,-112(s0)
    800065a4:	00290793          	addi	a5,s2,2
    800065a8:	00479713          	slli	a4,a5,0x4
    800065ac:	0001b797          	auipc	a5,0x1b
    800065b0:	7f478793          	addi	a5,a5,2036 # 80021da0 <disk>
    800065b4:	97ba                	add	a5,a5,a4
    800065b6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800065ba:	0001b997          	auipc	s3,0x1b
    800065be:	7e698993          	addi	s3,s3,2022 # 80021da0 <disk>
    800065c2:	00491713          	slli	a4,s2,0x4
    800065c6:	0009b783          	ld	a5,0(s3)
    800065ca:	97ba                	add	a5,a5,a4
    800065cc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065d0:	854a                	mv	a0,s2
    800065d2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065d6:	00000097          	auipc	ra,0x0
    800065da:	b70080e7          	jalr	-1168(ra) # 80006146 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065de:	8885                	andi	s1,s1,1
    800065e0:	f0ed                	bnez	s1,800065c2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065e2:	0001c517          	auipc	a0,0x1c
    800065e6:	8e650513          	addi	a0,a0,-1818 # 80021ec8 <disk+0x128>
    800065ea:	ffffa097          	auipc	ra,0xffffa
    800065ee:	77c080e7          	jalr	1916(ra) # 80000d66 <release>
}
    800065f2:	70a6                	ld	ra,104(sp)
    800065f4:	7406                	ld	s0,96(sp)
    800065f6:	64e6                	ld	s1,88(sp)
    800065f8:	6946                	ld	s2,80(sp)
    800065fa:	69a6                	ld	s3,72(sp)
    800065fc:	6a06                	ld	s4,64(sp)
    800065fe:	7ae2                	ld	s5,56(sp)
    80006600:	7b42                	ld	s6,48(sp)
    80006602:	7ba2                	ld	s7,40(sp)
    80006604:	7c02                	ld	s8,32(sp)
    80006606:	6ce2                	ld	s9,24(sp)
    80006608:	6d42                	ld	s10,16(sp)
    8000660a:	6165                	addi	sp,sp,112
    8000660c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000660e:	4689                	li	a3,2
    80006610:	00d79623          	sh	a3,12(a5)
    80006614:	b5e5                	j	800064fc <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006616:	f9042603          	lw	a2,-112(s0)
    8000661a:	00a60713          	addi	a4,a2,10
    8000661e:	0712                	slli	a4,a4,0x4
    80006620:	0001b517          	auipc	a0,0x1b
    80006624:	78850513          	addi	a0,a0,1928 # 80021da8 <disk+0x8>
    80006628:	953a                	add	a0,a0,a4
  if(write)
    8000662a:	e60d14e3          	bnez	s10,80006492 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000662e:	00a60793          	addi	a5,a2,10
    80006632:	00479693          	slli	a3,a5,0x4
    80006636:	0001b797          	auipc	a5,0x1b
    8000663a:	76a78793          	addi	a5,a5,1898 # 80021da0 <disk>
    8000663e:	97b6                	add	a5,a5,a3
    80006640:	0007a423          	sw	zero,8(a5)
    80006644:	b595                	j	800064a8 <virtio_disk_rw+0xf0>

0000000080006646 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006646:	1101                	addi	sp,sp,-32
    80006648:	ec06                	sd	ra,24(sp)
    8000664a:	e822                	sd	s0,16(sp)
    8000664c:	e426                	sd	s1,8(sp)
    8000664e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006650:	0001b497          	auipc	s1,0x1b
    80006654:	75048493          	addi	s1,s1,1872 # 80021da0 <disk>
    80006658:	0001c517          	auipc	a0,0x1c
    8000665c:	87050513          	addi	a0,a0,-1936 # 80021ec8 <disk+0x128>
    80006660:	ffffa097          	auipc	ra,0xffffa
    80006664:	652080e7          	jalr	1618(ra) # 80000cb2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006668:	10001737          	lui	a4,0x10001
    8000666c:	533c                	lw	a5,96(a4)
    8000666e:	8b8d                	andi	a5,a5,3
    80006670:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006672:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006676:	689c                	ld	a5,16(s1)
    80006678:	0204d703          	lhu	a4,32(s1)
    8000667c:	0027d783          	lhu	a5,2(a5)
    80006680:	04f70863          	beq	a4,a5,800066d0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006684:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006688:	6898                	ld	a4,16(s1)
    8000668a:	0204d783          	lhu	a5,32(s1)
    8000668e:	8b9d                	andi	a5,a5,7
    80006690:	078e                	slli	a5,a5,0x3
    80006692:	97ba                	add	a5,a5,a4
    80006694:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006696:	00278713          	addi	a4,a5,2
    8000669a:	0712                	slli	a4,a4,0x4
    8000669c:	9726                	add	a4,a4,s1
    8000669e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800066a2:	e721                	bnez	a4,800066ea <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066a4:	0789                	addi	a5,a5,2
    800066a6:	0792                	slli	a5,a5,0x4
    800066a8:	97a6                	add	a5,a5,s1
    800066aa:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800066ac:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066b0:	ffffc097          	auipc	ra,0xffffc
    800066b4:	ca4080e7          	jalr	-860(ra) # 80002354 <wakeup>

    disk.used_idx += 1;
    800066b8:	0204d783          	lhu	a5,32(s1)
    800066bc:	2785                	addiw	a5,a5,1
    800066be:	17c2                	slli	a5,a5,0x30
    800066c0:	93c1                	srli	a5,a5,0x30
    800066c2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066c6:	6898                	ld	a4,16(s1)
    800066c8:	00275703          	lhu	a4,2(a4)
    800066cc:	faf71ce3          	bne	a4,a5,80006684 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800066d0:	0001b517          	auipc	a0,0x1b
    800066d4:	7f850513          	addi	a0,a0,2040 # 80021ec8 <disk+0x128>
    800066d8:	ffffa097          	auipc	ra,0xffffa
    800066dc:	68e080e7          	jalr	1678(ra) # 80000d66 <release>
}
    800066e0:	60e2                	ld	ra,24(sp)
    800066e2:	6442                	ld	s0,16(sp)
    800066e4:	64a2                	ld	s1,8(sp)
    800066e6:	6105                	addi	sp,sp,32
    800066e8:	8082                	ret
      panic("virtio_disk_intr status");
    800066ea:	00002517          	auipc	a0,0x2
    800066ee:	27650513          	addi	a0,a0,630 # 80008960 <syscalls+0x400>
    800066f2:	ffffa097          	auipc	ra,0xffffa
    800066f6:	e52080e7          	jalr	-430(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...

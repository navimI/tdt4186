
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9e013103          	ld	sp,-1568(sp) # 800089e0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	9ee70713          	addi	a4,a4,-1554 # 80008a40 <timer_scratch>
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
    80000068:	21c78793          	addi	a5,a5,540 # 80006280 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc32f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
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
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	8ae080e7          	jalr	-1874(ra) # 800029da <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
            break;
        uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
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
    80000190:	9f450513          	addi	a0,a0,-1548 # 80010b80 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	9e448493          	addi	s1,s1,-1564 # 80010b80 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	a7290913          	addi	s2,s2,-1422 # 80010c18 <cons+0x98>
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
    800001c8:	90a080e7          	jalr	-1782(ra) # 80001ace <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	658080e7          	jalr	1624(ra) # 80002824 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
            sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	3a2080e7          	jalr	930(ra) # 8000257c <sleep>
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
    8000021a:	76e080e7          	jalr	1902(ra) # 80002984 <either_copyout>
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
    8000022e:	95650513          	addi	a0,a0,-1706 # 80010b80 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

    return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
                release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	94050513          	addi	a0,a0,-1728 # 80010b80 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
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
    8000027c:	9af72023          	sw	a5,-1632(a4) # 80010c18 <cons+0x98>
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
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
        uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
        uartputc_sync(' ');
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
        uartputc_sync('\b');
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
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
    800002d6:	8ae50513          	addi	a0,a0,-1874 # 80010b80 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

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
    800002fc:	738080e7          	jalr	1848(ra) # 80002a30 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	88050513          	addi	a0,a0,-1920 # 80010b80 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
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
    80000328:	85c70713          	addi	a4,a4,-1956 # 80010b80 <cons>
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
    80000352:	83278793          	addi	a5,a5,-1998 # 80010b80 <cons>
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
    80000380:	89c7a783          	lw	a5,-1892(a5) # 80010c18 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	7f070713          	addi	a4,a4,2032 # 80010b80 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	7e048493          	addi	s1,s1,2016 # 80010b80 <cons>
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
    800003e0:	7a470713          	addi	a4,a4,1956 # 80010b80 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
            cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	82f72723          	sw	a5,-2002(a4) # 80010c20 <cons+0xa0>
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
    8000041c:	76878793          	addi	a5,a5,1896 # 80010b80 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    8000043c:	00010797          	auipc	a5,0x10
    80000440:	7ec7a023          	sw	a2,2016(a5) # 80010c1c <cons+0x9c>
                wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	7d450513          	addi	a0,a0,2004 # 80010c18 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	194080e7          	jalr	404(ra) # 800025e0 <wakeup>
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
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	71a50513          	addi	a0,a0,1818 # 80010b80 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

    uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	eba78793          	addi	a5,a5,-326 # 80021338 <devsw>
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

  if(sign && (sign = xx < 0))
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
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
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
  while(--i >= 0)
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
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	6e07a823          	sw	zero,1776(a5) # 80010c40 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	46f72e23          	sw	a5,1148(a4) # 80008a00 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	680dad83          	lw	s11,1664(s11) # 80010c40 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	62a50513          	addi	a0,a0,1578 # 80010c28 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	4c650513          	addi	a0,a0,1222 # 80010c28 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	4aa48493          	addi	s1,s1,1194 # 80010c28 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	46a50513          	addi	a0,a0,1130 # 80010c48 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	1f67a783          	lw	a5,502(a5) # 80008a00 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	1c273703          	ld	a4,450(a4) # 80008a08 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	1c27b783          	ld	a5,450(a5) # 80008a10 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	3d8a0a13          	addi	s4,s4,984 # 80010c48 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	19048493          	addi	s1,s1,400 # 80008a08 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	19098993          	addi	s3,s3,400 # 80008a10 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	d3a080e7          	jalr	-710(ra) # 800025e0 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	36650513          	addi	a0,a0,870 # 80010c48 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	10e7a783          	lw	a5,270(a5) # 80008a00 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	1147b783          	ld	a5,276(a5) # 80008a10 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	10473703          	ld	a4,260(a4) # 80008a08 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	338a0a13          	addi	s4,s4,824 # 80010c48 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	0f048493          	addi	s1,s1,240 # 80008a08 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	0f090913          	addi	s2,s2,240 # 80008a10 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	c4c080e7          	jalr	-948(ra) # 8000257c <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	30248493          	addi	s1,s1,770 # 80010c48 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	0af73b23          	sd	a5,182(a4) # 80008a10 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	27848493          	addi	s1,s1,632 # 80010c48 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00022797          	auipc	a5,0x22
    80000a16:	abe78793          	addi	a5,a5,-1346 # 800224d0 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	24e90913          	addi	s2,s2,590 # 80010c80 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	1b250513          	addi	a0,a0,434 # 80010c80 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00022517          	auipc	a0,0x22
    80000ae6:	9ee50513          	addi	a0,a0,-1554 # 800224d0 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	17c48493          	addi	s1,s1,380 # 80010c80 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	16450513          	addi	a0,a0,356 # 80010c80 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	13850513          	addi	a0,a0,312 # 80010c80 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	f2e080e7          	jalr	-210(ra) # 80001ab2 <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	efc080e7          	jalr	-260(ra) # 80001ab2 <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	ef0080e7          	jalr	-272(ra) # 80001ab2 <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	ed8080e7          	jalr	-296(ra) # 80001ab2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	e98080e7          	jalr	-360(ra) # 80001ab2 <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	e6c080e7          	jalr	-404(ra) # 80001ab2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	c06080e7          	jalr	-1018(ra) # 80001aa2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	b7470713          	addi	a4,a4,-1164 # 80008a18 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	bea080e7          	jalr	-1046(ra) # 80001aa2 <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	ddc080e7          	jalr	-548(ra) # 80002cb6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	3de080e7          	jalr	990(ra) # 800062c0 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	2ba080e7          	jalr	698(ra) # 800021a4 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	a4c080e7          	jalr	-1460(ra) # 80001996 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	d3c080e7          	jalr	-708(ra) # 80002c8e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	d5c080e7          	jalr	-676(ra) # 80002cb6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	348080e7          	jalr	840(ra) # 800062aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	356080e7          	jalr	854(ra) # 800062c0 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	510080e7          	jalr	1296(ra) # 80003482 <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	bb4080e7          	jalr	-1100(ra) # 80003b2e <iinit>
    fileinit();      // file table
    80000f82:	00004097          	auipc	ra,0x4
    80000f86:	b52080e7          	jalr	-1198(ra) # 80004ad4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	43e080e7          	jalr	1086(ra) # 800063c8 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	e1c080e7          	jalr	-484(ra) # 80001dae <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	a6f72c23          	sw	a5,-1416(a4) # 80008a18 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	a6c7b783          	ld	a5,-1428(a5) # 80008a20 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	6b6080e7          	jalr	1718(ra) # 80001900 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00007797          	auipc	a5,0x7
    80001274:	7aa7b823          	sd	a0,1968(a5) # 80008a20 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80001864:	8792                	mv	a5,tp
    int id = r_tp();
    80001866:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001868:	0000fa97          	auipc	s5,0xf
    8000186c:	438a8a93          	addi	s5,s5,1080 # 80010ca0 <cpus>
    80001870:	00779713          	slli	a4,a5,0x7
    80001874:	00ea86b3          	add	a3,s5,a4
    80001878:	0006b023          	sd	zero,0(a3) # 1000 <_entry-0x7ffff000>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000187c:	100026f3          	csrr	a3,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001880:	0026e693          	ori	a3,a3,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001884:	10069073          	csrw	sstatus,a3
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
            c->proc = p;
            swtch(&c->context, &p->context);
    80001888:	0721                	addi	a4,a4,8
    8000188a:	9aba                	add	s5,s5,a4
    for (p = proc; p < &proc[NPROC]; p++)
    8000188c:	00010497          	auipc	s1,0x10
    80001890:	c6448493          	addi	s1,s1,-924 # 800114f0 <proc>
        if (p->state == RUNNABLE)
    80001894:	498d                	li	s3,3
            p->state = RUNNING;
    80001896:	4b11                	li	s6,4
            c->proc = p;
    80001898:	079e                	slli	a5,a5,0x7
    8000189a:	0000fa17          	auipc	s4,0xf
    8000189e:	406a0a13          	addi	s4,s4,1030 # 80010ca0 <cpus>
    800018a2:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800018a4:	00016917          	auipc	s2,0x16
    800018a8:	84c90913          	addi	s2,s2,-1972 # 800170f0 <tickslock>
    800018ac:	a03d                	j	800018da <rr_scheduler+0x8a>
            p->state = RUNNING;
    800018ae:	0164ac23          	sw	s6,24(s1)
            c->proc = p;
    800018b2:	009a3023          	sd	s1,0(s4)
            swtch(&c->context, &p->context);
    800018b6:	06048593          	addi	a1,s1,96
    800018ba:	8556                	mv	a0,s5
    800018bc:	00001097          	auipc	ra,0x1
    800018c0:	368080e7          	jalr	872(ra) # 80002c24 <swtch>

            // Process is done running for now.
            // It should have changed its p->state before coming back.
            c->proc = 0;
    800018c4:	000a3023          	sd	zero,0(s4)
        }
        release(&p->lock);
    800018c8:	8526                	mv	a0,s1
    800018ca:	fffff097          	auipc	ra,0xfffff
    800018ce:	3d4080e7          	jalr	980(ra) # 80000c9e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800018d2:	17048493          	addi	s1,s1,368
    800018d6:	01248b63          	beq	s1,s2,800018ec <rr_scheduler+0x9c>
        acquire(&p->lock);
    800018da:	8526                	mv	a0,s1
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	30e080e7          	jalr	782(ra) # 80000bea <acquire>
        if (p->state == RUNNABLE)
    800018e4:	4c9c                	lw	a5,24(s1)
    800018e6:	ff3791e3          	bne	a5,s3,800018c8 <rr_scheduler+0x78>
    800018ea:	b7d1                	j	800018ae <rr_scheduler+0x5e>
    }
    // In case a setsched happened, we will switch to the new scheduler after one
    // Round Robin round has completed.
}
    800018ec:	70e2                	ld	ra,56(sp)
    800018ee:	7442                	ld	s0,48(sp)
    800018f0:	74a2                	ld	s1,40(sp)
    800018f2:	7902                	ld	s2,32(sp)
    800018f4:	69e2                	ld	s3,24(sp)
    800018f6:	6a42                	ld	s4,16(sp)
    800018f8:	6aa2                	ld	s5,8(sp)
    800018fa:	6b02                	ld	s6,0(sp)
    800018fc:	6121                	addi	sp,sp,64
    800018fe:	8082                	ret

0000000080001900 <proc_mapstacks>:
{
    80001900:	7139                	addi	sp,sp,-64
    80001902:	fc06                	sd	ra,56(sp)
    80001904:	f822                	sd	s0,48(sp)
    80001906:	f426                	sd	s1,40(sp)
    80001908:	f04a                	sd	s2,32(sp)
    8000190a:	ec4e                	sd	s3,24(sp)
    8000190c:	e852                	sd	s4,16(sp)
    8000190e:	e456                	sd	s5,8(sp)
    80001910:	e05a                	sd	s6,0(sp)
    80001912:	0080                	addi	s0,sp,64
    80001914:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001916:	00010497          	auipc	s1,0x10
    8000191a:	bda48493          	addi	s1,s1,-1062 # 800114f0 <proc>
        uint64 va = KSTACK((int)(p - proc));
    8000191e:	8b26                	mv	s6,s1
    80001920:	00006a97          	auipc	s5,0x6
    80001924:	6e0a8a93          	addi	s5,s5,1760 # 80008000 <etext>
    80001928:	04000937          	lui	s2,0x4000
    8000192c:	197d                	addi	s2,s2,-1
    8000192e:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001930:	00015a17          	auipc	s4,0x15
    80001934:	7c0a0a13          	addi	s4,s4,1984 # 800170f0 <tickslock>
        char *pa = kalloc();
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	1c2080e7          	jalr	450(ra) # 80000afa <kalloc>
    80001940:	862a                	mv	a2,a0
        if (pa == 0)
    80001942:	c131                	beqz	a0,80001986 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001944:	416485b3          	sub	a1,s1,s6
    80001948:	8591                	srai	a1,a1,0x4
    8000194a:	000ab783          	ld	a5,0(s5)
    8000194e:	02f585b3          	mul	a1,a1,a5
    80001952:	2585                	addiw	a1,a1,1
    80001954:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001958:	4719                	li	a4,6
    8000195a:	6685                	lui	a3,0x1
    8000195c:	40b905b3          	sub	a1,s2,a1
    80001960:	854e                	mv	a0,s3
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	7f8080e7          	jalr	2040(ra) # 8000115a <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    8000196a:	17048493          	addi	s1,s1,368
    8000196e:	fd4495e3          	bne	s1,s4,80001938 <proc_mapstacks+0x38>
}
    80001972:	70e2                	ld	ra,56(sp)
    80001974:	7442                	ld	s0,48(sp)
    80001976:	74a2                	ld	s1,40(sp)
    80001978:	7902                	ld	s2,32(sp)
    8000197a:	69e2                	ld	s3,24(sp)
    8000197c:	6a42                	ld	s4,16(sp)
    8000197e:	6aa2                	ld	s5,8(sp)
    80001980:	6b02                	ld	s6,0(sp)
    80001982:	6121                	addi	sp,sp,64
    80001984:	8082                	ret
            panic("kalloc");
    80001986:	00007517          	auipc	a0,0x7
    8000198a:	85250513          	addi	a0,a0,-1966 # 800081d8 <digits+0x198>
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	bb6080e7          	jalr	-1098(ra) # 80000544 <panic>

0000000080001996 <procinit>:
{
    80001996:	7139                	addi	sp,sp,-64
    80001998:	fc06                	sd	ra,56(sp)
    8000199a:	f822                	sd	s0,48(sp)
    8000199c:	f426                	sd	s1,40(sp)
    8000199e:	f04a                	sd	s2,32(sp)
    800019a0:	ec4e                	sd	s3,24(sp)
    800019a2:	e852                	sd	s4,16(sp)
    800019a4:	e456                	sd	s5,8(sp)
    800019a6:	e05a                	sd	s6,0(sp)
    800019a8:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    800019aa:	00007597          	auipc	a1,0x7
    800019ae:	83658593          	addi	a1,a1,-1994 # 800081e0 <digits+0x1a0>
    800019b2:	0000f517          	auipc	a0,0xf
    800019b6:	6ee50513          	addi	a0,a0,1774 # 800110a0 <pid_lock>
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1a0080e7          	jalr	416(ra) # 80000b5a <initlock>
    initlock(&wait_lock, "wait_lock");
    800019c2:	00007597          	auipc	a1,0x7
    800019c6:	82658593          	addi	a1,a1,-2010 # 800081e8 <digits+0x1a8>
    800019ca:	0000f517          	auipc	a0,0xf
    800019ce:	6ee50513          	addi	a0,a0,1774 # 800110b8 <wait_lock>
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	188080e7          	jalr	392(ra) # 80000b5a <initlock>
    initlock(&priotable.lock, "priotable");
    800019da:	00007597          	auipc	a1,0x7
    800019de:	81e58593          	addi	a1,a1,-2018 # 800081f8 <digits+0x1b8>
    800019e2:	0000f517          	auipc	a0,0xf
    800019e6:	6ee50513          	addi	a0,a0,1774 # 800110d0 <priotable>
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	170080e7          	jalr	368(ra) # 80000b5a <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    800019f2:	00010497          	auipc	s1,0x10
    800019f6:	afe48493          	addi	s1,s1,-1282 # 800114f0 <proc>
        initlock(&p->lock, "proc");
    800019fa:	00007b17          	auipc	s6,0x7
    800019fe:	80eb0b13          	addi	s6,s6,-2034 # 80008208 <digits+0x1c8>
        p->kstack = KSTACK((int)(p - proc));
    80001a02:	8aa6                	mv	s5,s1
    80001a04:	00006a17          	auipc	s4,0x6
    80001a08:	5fca0a13          	addi	s4,s4,1532 # 80008000 <etext>
    80001a0c:	04000937          	lui	s2,0x4000
    80001a10:	197d                	addi	s2,s2,-1
    80001a12:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001a14:	00015997          	auipc	s3,0x15
    80001a18:	6dc98993          	addi	s3,s3,1756 # 800170f0 <tickslock>
        initlock(&p->lock, "proc");
    80001a1c:	85da                	mv	a1,s6
    80001a1e:	8526                	mv	a0,s1
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	13a080e7          	jalr	314(ra) # 80000b5a <initlock>
        p->state = UNUSED;
    80001a28:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001a2c:	415487b3          	sub	a5,s1,s5
    80001a30:	8791                	srai	a5,a5,0x4
    80001a32:	000a3703          	ld	a4,0(s4)
    80001a36:	02e787b3          	mul	a5,a5,a4
    80001a3a:	2785                	addiw	a5,a5,1
    80001a3c:	00d7979b          	slliw	a5,a5,0xd
    80001a40:	40f907b3          	sub	a5,s2,a5
    80001a44:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001a46:	17048493          	addi	s1,s1,368
    80001a4a:	fd3499e3          	bne	s1,s3,80001a1c <procinit+0x86>
        priotable.priCount[i] = -1;
    80001a4e:	00010797          	auipc	a5,0x10
    80001a52:	25278793          	addi	a5,a5,594 # 80011ca0 <proc+0x7b0>
    80001a56:	577d                	li	a4,-1
    80001a58:	84e7a423          	sw	a4,-1976(a5)
    80001a5c:	84e7a623          	sw	a4,-1972(a5)
}
    80001a60:	70e2                	ld	ra,56(sp)
    80001a62:	7442                	ld	s0,48(sp)
    80001a64:	74a2                	ld	s1,40(sp)
    80001a66:	7902                	ld	s2,32(sp)
    80001a68:	69e2                	ld	s3,24(sp)
    80001a6a:	6a42                	ld	s4,16(sp)
    80001a6c:	6aa2                	ld	s5,8(sp)
    80001a6e:	6b02                	ld	s6,0(sp)
    80001a70:	6121                	addi	sp,sp,64
    80001a72:	8082                	ret

0000000080001a74 <copy_array>:
{
    80001a74:	1141                	addi	sp,sp,-16
    80001a76:	e422                	sd	s0,8(sp)
    80001a78:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001a7a:	02c05163          	blez	a2,80001a9c <copy_array+0x28>
    80001a7e:	87aa                	mv	a5,a0
    80001a80:	0505                	addi	a0,a0,1
    80001a82:	fff6069b          	addiw	a3,a2,-1
    80001a86:	1682                	slli	a3,a3,0x20
    80001a88:	9281                	srli	a3,a3,0x20
    80001a8a:	96aa                	add	a3,a3,a0
        dst[i] = src[i];
    80001a8c:	0007c703          	lbu	a4,0(a5)
    80001a90:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001a94:	0785                	addi	a5,a5,1
    80001a96:	0585                	addi	a1,a1,1
    80001a98:	fed79ae3          	bne	a5,a3,80001a8c <copy_array+0x18>
}
    80001a9c:	6422                	ld	s0,8(sp)
    80001a9e:	0141                	addi	sp,sp,16
    80001aa0:	8082                	ret

0000000080001aa2 <cpuid>:
{
    80001aa2:	1141                	addi	sp,sp,-16
    80001aa4:	e422                	sd	s0,8(sp)
    80001aa6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001aa8:	8512                	mv	a0,tp
}
    80001aaa:	2501                	sext.w	a0,a0
    80001aac:	6422                	ld	s0,8(sp)
    80001aae:	0141                	addi	sp,sp,16
    80001ab0:	8082                	ret

0000000080001ab2 <mycpu>:
{
    80001ab2:	1141                	addi	sp,sp,-16
    80001ab4:	e422                	sd	s0,8(sp)
    80001ab6:	0800                	addi	s0,sp,16
    80001ab8:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001aba:	2781                	sext.w	a5,a5
    80001abc:	079e                	slli	a5,a5,0x7
}
    80001abe:	0000f517          	auipc	a0,0xf
    80001ac2:	1e250513          	addi	a0,a0,482 # 80010ca0 <cpus>
    80001ac6:	953e                	add	a0,a0,a5
    80001ac8:	6422                	ld	s0,8(sp)
    80001aca:	0141                	addi	sp,sp,16
    80001acc:	8082                	ret

0000000080001ace <myproc>:
{
    80001ace:	1101                	addi	sp,sp,-32
    80001ad0:	ec06                	sd	ra,24(sp)
    80001ad2:	e822                	sd	s0,16(sp)
    80001ad4:	e426                	sd	s1,8(sp)
    80001ad6:	1000                	addi	s0,sp,32
    push_off();
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	0c6080e7          	jalr	198(ra) # 80000b9e <push_off>
    80001ae0:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001ae2:	2781                	sext.w	a5,a5
    80001ae4:	079e                	slli	a5,a5,0x7
    80001ae6:	0000f717          	auipc	a4,0xf
    80001aea:	1ba70713          	addi	a4,a4,442 # 80010ca0 <cpus>
    80001aee:	97ba                	add	a5,a5,a4
    80001af0:	6384                	ld	s1,0(a5)
    pop_off();
    80001af2:	fffff097          	auipc	ra,0xfffff
    80001af6:	14c080e7          	jalr	332(ra) # 80000c3e <pop_off>
}
    80001afa:	8526                	mv	a0,s1
    80001afc:	60e2                	ld	ra,24(sp)
    80001afe:	6442                	ld	s0,16(sp)
    80001b00:	64a2                	ld	s1,8(sp)
    80001b02:	6105                	addi	sp,sp,32
    80001b04:	8082                	ret

0000000080001b06 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001b06:	1141                	addi	sp,sp,-16
    80001b08:	e406                	sd	ra,8(sp)
    80001b0a:	e022                	sd	s0,0(sp)
    80001b0c:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001b0e:	00000097          	auipc	ra,0x0
    80001b12:	fc0080e7          	jalr	-64(ra) # 80001ace <myproc>
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	188080e7          	jalr	392(ra) # 80000c9e <release>

    if (first)
    80001b1e:	00007797          	auipc	a5,0x7
    80001b22:	e227a783          	lw	a5,-478(a5) # 80008940 <first.1765>
    80001b26:	eb89                	bnez	a5,80001b38 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001b28:	00001097          	auipc	ra,0x1
    80001b2c:	1a6080e7          	jalr	422(ra) # 80002cce <usertrapret>
}
    80001b30:	60a2                	ld	ra,8(sp)
    80001b32:	6402                	ld	s0,0(sp)
    80001b34:	0141                	addi	sp,sp,16
    80001b36:	8082                	ret
        first = 0;
    80001b38:	00007797          	auipc	a5,0x7
    80001b3c:	e007a423          	sw	zero,-504(a5) # 80008940 <first.1765>
        fsinit(ROOTDEV);
    80001b40:	4505                	li	a0,1
    80001b42:	00002097          	auipc	ra,0x2
    80001b46:	f6c080e7          	jalr	-148(ra) # 80003aae <fsinit>
    80001b4a:	bff9                	j	80001b28 <forkret+0x22>

0000000080001b4c <allocpid>:
{
    80001b4c:	1101                	addi	sp,sp,-32
    80001b4e:	ec06                	sd	ra,24(sp)
    80001b50:	e822                	sd	s0,16(sp)
    80001b52:	e426                	sd	s1,8(sp)
    80001b54:	e04a                	sd	s2,0(sp)
    80001b56:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001b58:	0000f917          	auipc	s2,0xf
    80001b5c:	54890913          	addi	s2,s2,1352 # 800110a0 <pid_lock>
    80001b60:	854a                	mv	a0,s2
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	088080e7          	jalr	136(ra) # 80000bea <acquire>
    pid = nextpid;
    80001b6a:	00007797          	auipc	a5,0x7
    80001b6e:	de678793          	addi	a5,a5,-538 # 80008950 <nextpid>
    80001b72:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001b74:	0014871b          	addiw	a4,s1,1
    80001b78:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001b7a:	854a                	mv	a0,s2
    80001b7c:	fffff097          	auipc	ra,0xfffff
    80001b80:	122080e7          	jalr	290(ra) # 80000c9e <release>
}
    80001b84:	8526                	mv	a0,s1
    80001b86:	60e2                	ld	ra,24(sp)
    80001b88:	6442                	ld	s0,16(sp)
    80001b8a:	64a2                	ld	s1,8(sp)
    80001b8c:	6902                	ld	s2,0(sp)
    80001b8e:	6105                	addi	sp,sp,32
    80001b90:	8082                	ret

0000000080001b92 <proc_pagetable>:
{
    80001b92:	1101                	addi	sp,sp,-32
    80001b94:	ec06                	sd	ra,24(sp)
    80001b96:	e822                	sd	s0,16(sp)
    80001b98:	e426                	sd	s1,8(sp)
    80001b9a:	e04a                	sd	s2,0(sp)
    80001b9c:	1000                	addi	s0,sp,32
    80001b9e:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	7a4080e7          	jalr	1956(ra) # 80001344 <uvmcreate>
    80001ba8:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001baa:	c121                	beqz	a0,80001bea <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bac:	4729                	li	a4,10
    80001bae:	00005697          	auipc	a3,0x5
    80001bb2:	45268693          	addi	a3,a3,1106 # 80007000 <_trampoline>
    80001bb6:	6605                	lui	a2,0x1
    80001bb8:	040005b7          	lui	a1,0x4000
    80001bbc:	15fd                	addi	a1,a1,-1
    80001bbe:	05b2                	slli	a1,a1,0xc
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	4fa080e7          	jalr	1274(ra) # 800010ba <mappages>
    80001bc8:	02054863          	bltz	a0,80001bf8 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bcc:	4719                	li	a4,6
    80001bce:	05893683          	ld	a3,88(s2)
    80001bd2:	6605                	lui	a2,0x1
    80001bd4:	020005b7          	lui	a1,0x2000
    80001bd8:	15fd                	addi	a1,a1,-1
    80001bda:	05b6                	slli	a1,a1,0xd
    80001bdc:	8526                	mv	a0,s1
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	4dc080e7          	jalr	1244(ra) # 800010ba <mappages>
    80001be6:	02054163          	bltz	a0,80001c08 <proc_pagetable+0x76>
}
    80001bea:	8526                	mv	a0,s1
    80001bec:	60e2                	ld	ra,24(sp)
    80001bee:	6442                	ld	s0,16(sp)
    80001bf0:	64a2                	ld	s1,8(sp)
    80001bf2:	6902                	ld	s2,0(sp)
    80001bf4:	6105                	addi	sp,sp,32
    80001bf6:	8082                	ret
        uvmfree(pagetable, 0);
    80001bf8:	4581                	li	a1,0
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	00000097          	auipc	ra,0x0
    80001c00:	94c080e7          	jalr	-1716(ra) # 80001548 <uvmfree>
        return 0;
    80001c04:	4481                	li	s1,0
    80001c06:	b7d5                	j	80001bea <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c08:	4681                	li	a3,0
    80001c0a:	4605                	li	a2,1
    80001c0c:	040005b7          	lui	a1,0x4000
    80001c10:	15fd                	addi	a1,a1,-1
    80001c12:	05b2                	slli	a1,a1,0xc
    80001c14:	8526                	mv	a0,s1
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	66a080e7          	jalr	1642(ra) # 80001280 <uvmunmap>
        uvmfree(pagetable, 0);
    80001c1e:	4581                	li	a1,0
    80001c20:	8526                	mv	a0,s1
    80001c22:	00000097          	auipc	ra,0x0
    80001c26:	926080e7          	jalr	-1754(ra) # 80001548 <uvmfree>
        return 0;
    80001c2a:	4481                	li	s1,0
    80001c2c:	bf7d                	j	80001bea <proc_pagetable+0x58>

0000000080001c2e <proc_freepagetable>:
{
    80001c2e:	1101                	addi	sp,sp,-32
    80001c30:	ec06                	sd	ra,24(sp)
    80001c32:	e822                	sd	s0,16(sp)
    80001c34:	e426                	sd	s1,8(sp)
    80001c36:	e04a                	sd	s2,0(sp)
    80001c38:	1000                	addi	s0,sp,32
    80001c3a:	84aa                	mv	s1,a0
    80001c3c:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c3e:	4681                	li	a3,0
    80001c40:	4605                	li	a2,1
    80001c42:	040005b7          	lui	a1,0x4000
    80001c46:	15fd                	addi	a1,a1,-1
    80001c48:	05b2                	slli	a1,a1,0xc
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	636080e7          	jalr	1590(ra) # 80001280 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c52:	4681                	li	a3,0
    80001c54:	4605                	li	a2,1
    80001c56:	020005b7          	lui	a1,0x2000
    80001c5a:	15fd                	addi	a1,a1,-1
    80001c5c:	05b6                	slli	a1,a1,0xd
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	620080e7          	jalr	1568(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, sz);
    80001c68:	85ca                	mv	a1,s2
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	00000097          	auipc	ra,0x0
    80001c70:	8dc080e7          	jalr	-1828(ra) # 80001548 <uvmfree>
}
    80001c74:	60e2                	ld	ra,24(sp)
    80001c76:	6442                	ld	s0,16(sp)
    80001c78:	64a2                	ld	s1,8(sp)
    80001c7a:	6902                	ld	s2,0(sp)
    80001c7c:	6105                	addi	sp,sp,32
    80001c7e:	8082                	ret

0000000080001c80 <freeproc>:
{
    80001c80:	1101                	addi	sp,sp,-32
    80001c82:	ec06                	sd	ra,24(sp)
    80001c84:	e822                	sd	s0,16(sp)
    80001c86:	e426                	sd	s1,8(sp)
    80001c88:	1000                	addi	s0,sp,32
    80001c8a:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001c8c:	6d28                	ld	a0,88(a0)
    80001c8e:	c509                	beqz	a0,80001c98 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	d6e080e7          	jalr	-658(ra) # 800009fe <kfree>
    p->trapframe = 0;
    80001c98:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001c9c:	68a8                	ld	a0,80(s1)
    80001c9e:	c511                	beqz	a0,80001caa <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001ca0:	64ac                	ld	a1,72(s1)
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	f8c080e7          	jalr	-116(ra) # 80001c2e <proc_freepagetable>
    p->pagetable = 0;
    80001caa:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001cae:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001cb2:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001cb6:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001cba:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001cbe:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001cc2:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001cc6:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001cca:	0004ac23          	sw	zero,24(s1)
    p->priority = 0;
    80001cce:	1604a423          	sw	zero,360(s1)
}
    80001cd2:	60e2                	ld	ra,24(sp)
    80001cd4:	6442                	ld	s0,16(sp)
    80001cd6:	64a2                	ld	s1,8(sp)
    80001cd8:	6105                	addi	sp,sp,32
    80001cda:	8082                	ret

0000000080001cdc <allocproc>:
{
    80001cdc:	1101                	addi	sp,sp,-32
    80001cde:	ec06                	sd	ra,24(sp)
    80001ce0:	e822                	sd	s0,16(sp)
    80001ce2:	e426                	sd	s1,8(sp)
    80001ce4:	e04a                	sd	s2,0(sp)
    80001ce6:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001ce8:	00010497          	auipc	s1,0x10
    80001cec:	80848493          	addi	s1,s1,-2040 # 800114f0 <proc>
    80001cf0:	00015917          	auipc	s2,0x15
    80001cf4:	40090913          	addi	s2,s2,1024 # 800170f0 <tickslock>
        acquire(&p->lock);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	ef0080e7          	jalr	-272(ra) # 80000bea <acquire>
        if (p->state == UNUSED)
    80001d02:	4c9c                	lw	a5,24(s1)
    80001d04:	cf81                	beqz	a5,80001d1c <allocproc+0x40>
            release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f96080e7          	jalr	-106(ra) # 80000c9e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001d10:	17048493          	addi	s1,s1,368
    80001d14:	ff2492e3          	bne	s1,s2,80001cf8 <allocproc+0x1c>
    return 0;
    80001d18:	4481                	li	s1,0
    80001d1a:	a899                	j	80001d70 <allocproc+0x94>
    p->pid = allocpid();
    80001d1c:	00000097          	auipc	ra,0x0
    80001d20:	e30080e7          	jalr	-464(ra) # 80001b4c <allocpid>
    80001d24:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001d26:	4785                	li	a5,1
    80001d28:	cc9c                	sw	a5,24(s1)
    p->priority = 0;
    80001d2a:	1604a423          	sw	zero,360(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	dcc080e7          	jalr	-564(ra) # 80000afa <kalloc>
    80001d36:	892a                	mv	s2,a0
    80001d38:	eca8                	sd	a0,88(s1)
    80001d3a:	c131                	beqz	a0,80001d7e <allocproc+0xa2>
    p->pagetable = proc_pagetable(p);
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	00000097          	auipc	ra,0x0
    80001d42:	e54080e7          	jalr	-428(ra) # 80001b92 <proc_pagetable>
    80001d46:	892a                	mv	s2,a0
    80001d48:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001d4a:	c531                	beqz	a0,80001d96 <allocproc+0xba>
    memset(&p->context, 0, sizeof(p->context));
    80001d4c:	07000613          	li	a2,112
    80001d50:	4581                	li	a1,0
    80001d52:	06048513          	addi	a0,s1,96
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	f90080e7          	jalr	-112(ra) # 80000ce6 <memset>
    p->context.ra = (uint64)forkret;
    80001d5e:	00000797          	auipc	a5,0x0
    80001d62:	da878793          	addi	a5,a5,-600 # 80001b06 <forkret>
    80001d66:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001d68:	60bc                	ld	a5,64(s1)
    80001d6a:	6705                	lui	a4,0x1
    80001d6c:	97ba                	add	a5,a5,a4
    80001d6e:	f4bc                	sd	a5,104(s1)
}
    80001d70:	8526                	mv	a0,s1
    80001d72:	60e2                	ld	ra,24(sp)
    80001d74:	6442                	ld	s0,16(sp)
    80001d76:	64a2                	ld	s1,8(sp)
    80001d78:	6902                	ld	s2,0(sp)
    80001d7a:	6105                	addi	sp,sp,32
    80001d7c:	8082                	ret
        freeproc(p);
    80001d7e:	8526                	mv	a0,s1
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	f00080e7          	jalr	-256(ra) # 80001c80 <freeproc>
        release(&p->lock);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	f14080e7          	jalr	-236(ra) # 80000c9e <release>
        return 0;
    80001d92:	84ca                	mv	s1,s2
    80001d94:	bff1                	j	80001d70 <allocproc+0x94>
        freeproc(p);
    80001d96:	8526                	mv	a0,s1
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	ee8080e7          	jalr	-280(ra) # 80001c80 <freeproc>
        release(&p->lock);
    80001da0:	8526                	mv	a0,s1
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	efc080e7          	jalr	-260(ra) # 80000c9e <release>
        return 0;
    80001daa:	84ca                	mv	s1,s2
    80001dac:	b7d1                	j	80001d70 <allocproc+0x94>

0000000080001dae <userinit>:
{
    80001dae:	1101                	addi	sp,sp,-32
    80001db0:	ec06                	sd	ra,24(sp)
    80001db2:	e822                	sd	s0,16(sp)
    80001db4:	e426                	sd	s1,8(sp)
    80001db6:	e04a                	sd	s2,0(sp)
    80001db8:	1000                	addi	s0,sp,32
    p = allocproc();
    80001dba:	00000097          	auipc	ra,0x0
    80001dbe:	f22080e7          	jalr	-222(ra) # 80001cdc <allocproc>
    80001dc2:	84aa                	mv	s1,a0
    initproc = p;
    80001dc4:	00007797          	auipc	a5,0x7
    80001dc8:	c6a7b623          	sd	a0,-916(a5) # 80008a30 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001dcc:	03400613          	li	a2,52
    80001dd0:	00007597          	auipc	a1,0x7
    80001dd4:	b9058593          	addi	a1,a1,-1136 # 80008960 <initcode>
    80001dd8:	6928                	ld	a0,80(a0)
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	598080e7          	jalr	1432(ra) # 80001372 <uvmfirst>
    p->sz = PGSIZE;
    80001de2:	6785                	lui	a5,0x1
    80001de4:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001de6:	6cb8                	ld	a4,88(s1)
    80001de8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001dec:	6cb8                	ld	a4,88(s1)
    80001dee:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001df0:	4641                	li	a2,16
    80001df2:	00006597          	auipc	a1,0x6
    80001df6:	41e58593          	addi	a1,a1,1054 # 80008210 <digits+0x1d0>
    80001dfa:	15848513          	addi	a0,s1,344
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	03a080e7          	jalr	58(ra) # 80000e38 <safestrcpy>
    p->cwd = namei("/");
    80001e06:	00006517          	auipc	a0,0x6
    80001e0a:	41a50513          	addi	a0,a0,1050 # 80008220 <digits+0x1e0>
    80001e0e:	00002097          	auipc	ra,0x2
    80001e12:	6c2080e7          	jalr	1730(ra) # 800044d0 <namei>
    80001e16:	14a4b823          	sd	a0,336(s1)
    acquire(&priotable.lock);
    80001e1a:	0000f917          	auipc	s2,0xf
    80001e1e:	2b690913          	addi	s2,s2,694 # 800110d0 <priotable>
    80001e22:	854a                	mv	a0,s2
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	dc6080e7          	jalr	-570(ra) # 80000bea <acquire>
    priotable.priCount[0]++;
    80001e2c:	00010697          	auipc	a3,0x10
    80001e30:	e7468693          	addi	a3,a3,-396 # 80011ca0 <proc+0x7b0>
    80001e34:	8486a703          	lw	a4,-1976(a3)
    80001e38:	2705                	addiw	a4,a4,1
    80001e3a:	0007079b          	sext.w	a5,a4
    80001e3e:	84e6a423          	sw	a4,-1976(a3)
    priotable.que[0][priotable.priCount[0]] = p;
    80001e42:	0789                	addi	a5,a5,2
    80001e44:	078e                	slli	a5,a5,0x3
    80001e46:	0000f717          	auipc	a4,0xf
    80001e4a:	e5a70713          	addi	a4,a4,-422 # 80010ca0 <cpus>
    80001e4e:	97ba                	add	a5,a5,a4
    80001e50:	4297bc23          	sd	s1,1080(a5) # 1438 <_entry-0x7fffebc8>
    release(&priotable.lock);
    80001e54:	854a                	mv	a0,s2
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	e48080e7          	jalr	-440(ra) # 80000c9e <release>
    p->state = RUNNABLE;
    80001e5e:	478d                	li	a5,3
    80001e60:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001e62:	8526                	mv	a0,s1
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	e3a080e7          	jalr	-454(ra) # 80000c9e <release>
}
    80001e6c:	60e2                	ld	ra,24(sp)
    80001e6e:	6442                	ld	s0,16(sp)
    80001e70:	64a2                	ld	s1,8(sp)
    80001e72:	6902                	ld	s2,0(sp)
    80001e74:	6105                	addi	sp,sp,32
    80001e76:	8082                	ret

0000000080001e78 <growproc>:
{
    80001e78:	1101                	addi	sp,sp,-32
    80001e7a:	ec06                	sd	ra,24(sp)
    80001e7c:	e822                	sd	s0,16(sp)
    80001e7e:	e426                	sd	s1,8(sp)
    80001e80:	e04a                	sd	s2,0(sp)
    80001e82:	1000                	addi	s0,sp,32
    80001e84:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001e86:	00000097          	auipc	ra,0x0
    80001e8a:	c48080e7          	jalr	-952(ra) # 80001ace <myproc>
    80001e8e:	84aa                	mv	s1,a0
    sz = p->sz;
    80001e90:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001e92:	01204c63          	bgtz	s2,80001eaa <growproc+0x32>
    else if (n < 0)
    80001e96:	02094663          	bltz	s2,80001ec2 <growproc+0x4a>
    p->sz = sz;
    80001e9a:	e4ac                	sd	a1,72(s1)
    return 0;
    80001e9c:	4501                	li	a0,0
}
    80001e9e:	60e2                	ld	ra,24(sp)
    80001ea0:	6442                	ld	s0,16(sp)
    80001ea2:	64a2                	ld	s1,8(sp)
    80001ea4:	6902                	ld	s2,0(sp)
    80001ea6:	6105                	addi	sp,sp,32
    80001ea8:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001eaa:	4691                	li	a3,4
    80001eac:	00b90633          	add	a2,s2,a1
    80001eb0:	6928                	ld	a0,80(a0)
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	57a080e7          	jalr	1402(ra) # 8000142c <uvmalloc>
    80001eba:	85aa                	mv	a1,a0
    80001ebc:	fd79                	bnez	a0,80001e9a <growproc+0x22>
            return -1;
    80001ebe:	557d                	li	a0,-1
    80001ec0:	bff9                	j	80001e9e <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ec2:	00b90633          	add	a2,s2,a1
    80001ec6:	6928                	ld	a0,80(a0)
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	51c080e7          	jalr	1308(ra) # 800013e4 <uvmdealloc>
    80001ed0:	85aa                	mv	a1,a0
    80001ed2:	b7e1                	j	80001e9a <growproc+0x22>

0000000080001ed4 <ps>:
{
    80001ed4:	715d                	addi	sp,sp,-80
    80001ed6:	e486                	sd	ra,72(sp)
    80001ed8:	e0a2                	sd	s0,64(sp)
    80001eda:	fc26                	sd	s1,56(sp)
    80001edc:	f84a                	sd	s2,48(sp)
    80001ede:	f44e                	sd	s3,40(sp)
    80001ee0:	f052                	sd	s4,32(sp)
    80001ee2:	ec56                	sd	s5,24(sp)
    80001ee4:	e85a                	sd	s6,16(sp)
    80001ee6:	e45e                	sd	s7,8(sp)
    80001ee8:	e062                	sd	s8,0(sp)
    80001eea:	0880                	addi	s0,sp,80
    80001eec:	84aa                	mv	s1,a0
    80001eee:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001ef0:	00000097          	auipc	ra,0x0
    80001ef4:	bde080e7          	jalr	-1058(ra) # 80001ace <myproc>
    if (count == 0)
    80001ef8:	120b8063          	beqz	s7,80002018 <ps+0x144>
    void *result = (void *)myproc()->sz;
    80001efc:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001f00:	003b951b          	slliw	a0,s7,0x3
    80001f04:	0175053b          	addw	a0,a0,s7
    80001f08:	0025151b          	slliw	a0,a0,0x2
    80001f0c:	00000097          	auipc	ra,0x0
    80001f10:	f6c080e7          	jalr	-148(ra) # 80001e78 <growproc>
    80001f14:	10054463          	bltz	a0,8000201c <ps+0x148>
    struct user_proc loc_result[count];
    80001f18:	003b9a13          	slli	s4,s7,0x3
    80001f1c:	9a5e                	add	s4,s4,s7
    80001f1e:	0a0a                	slli	s4,s4,0x2
    80001f20:	00fa0793          	addi	a5,s4,15
    80001f24:	8391                	srli	a5,a5,0x4
    80001f26:	0792                	slli	a5,a5,0x4
    80001f28:	40f10133          	sub	sp,sp,a5
    80001f2c:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    80001f2e:	00844537          	lui	a0,0x844
    80001f32:	02a484b3          	mul	s1,s1,a0
    80001f36:	0000f797          	auipc	a5,0xf
    80001f3a:	5ba78793          	addi	a5,a5,1466 # 800114f0 <proc>
    80001f3e:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80001f40:	00015797          	auipc	a5,0x15
    80001f44:	1b078793          	addi	a5,a5,432 # 800170f0 <tickslock>
    80001f48:	0cf4fc63          	bgeu	s1,a5,80002020 <ps+0x14c>
    80001f4c:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    80001f50:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80001f52:	8c3e                	mv	s8,a5
    80001f54:	a051                	j	80001fd8 <ps+0x104>
            loc_result[localCount].state = UNUSED;
    80001f56:	00399793          	slli	a5,s3,0x3
    80001f5a:	97ce                	add	a5,a5,s3
    80001f5c:	078a                	slli	a5,a5,0x2
    80001f5e:	97d6                	add	a5,a5,s5
    80001f60:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80001f64:	8526                	mv	a0,s1
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	d38080e7          	jalr	-712(ra) # 80000c9e <release>
    if (localCount < count)
    80001f6e:	0179f963          	bgeu	s3,s7,80001f80 <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80001f72:	00399793          	slli	a5,s3,0x3
    80001f76:	97ce                	add	a5,a5,s3
    80001f78:	078a                	slli	a5,a5,0x2
    80001f7a:	97d6                	add	a5,a5,s5
    80001f7c:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    80001f80:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    80001f82:	00000097          	auipc	ra,0x0
    80001f86:	b4c080e7          	jalr	-1204(ra) # 80001ace <myproc>
    80001f8a:	86d2                	mv	a3,s4
    80001f8c:	8656                	mv	a2,s5
    80001f8e:	85da                	mv	a1,s6
    80001f90:	6928                	ld	a0,80(a0)
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	6f2080e7          	jalr	1778(ra) # 80001684 <copyout>
}
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fb040113          	addi	sp,s0,-80
    80001fa0:	60a6                	ld	ra,72(sp)
    80001fa2:	6406                	ld	s0,64(sp)
    80001fa4:	74e2                	ld	s1,56(sp)
    80001fa6:	7942                	ld	s2,48(sp)
    80001fa8:	79a2                	ld	s3,40(sp)
    80001faa:	7a02                	ld	s4,32(sp)
    80001fac:	6ae2                	ld	s5,24(sp)
    80001fae:	6b42                	ld	s6,16(sp)
    80001fb0:	6ba2                	ld	s7,8(sp)
    80001fb2:	6c02                	ld	s8,0(sp)
    80001fb4:	6161                	addi	sp,sp,80
    80001fb6:	8082                	ret
        release(&p->lock);
    80001fb8:	8526                	mv	a0,s1
    80001fba:	fffff097          	auipc	ra,0xfffff
    80001fbe:	ce4080e7          	jalr	-796(ra) # 80000c9e <release>
        localCount++;
    80001fc2:	2985                	addiw	s3,s3,1
    80001fc4:	0ff9f993          	andi	s3,s3,255
    for (; p < &proc[NPROC]; p++)
    80001fc8:	17048493          	addi	s1,s1,368
    80001fcc:	fb84f1e3          	bgeu	s1,s8,80001f6e <ps+0x9a>
        if (localCount == count)
    80001fd0:	02490913          	addi	s2,s2,36
    80001fd4:	fb3b86e3          	beq	s7,s3,80001f80 <ps+0xac>
        acquire(&p->lock);
    80001fd8:	8526                	mv	a0,s1
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	c10080e7          	jalr	-1008(ra) # 80000bea <acquire>
        if (p->state == UNUSED)
    80001fe2:	4c9c                	lw	a5,24(s1)
    80001fe4:	dbad                	beqz	a5,80001f56 <ps+0x82>
        loc_result[localCount].state = p->state;
    80001fe6:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    80001fea:	549c                	lw	a5,40(s1)
    80001fec:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    80001ff0:	54dc                	lw	a5,44(s1)
    80001ff2:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80001ff6:	589c                	lw	a5,48(s1)
    80001ff8:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    80001ffc:	4641                	li	a2,16
    80001ffe:	85ca                	mv	a1,s2
    80002000:	15848513          	addi	a0,s1,344
    80002004:	00000097          	auipc	ra,0x0
    80002008:	a70080e7          	jalr	-1424(ra) # 80001a74 <copy_array>
        if (p->parent != 0) // init
    8000200c:	7c9c                	ld	a5,56(s1)
    8000200e:	d7cd                	beqz	a5,80001fb8 <ps+0xe4>
            loc_result[localCount].parent_id = p->parent->pid;
    80002010:	5b9c                	lw	a5,48(a5)
    80002012:	fef92e23          	sw	a5,-4(s2)
    80002016:	b74d                	j	80001fb8 <ps+0xe4>
        return result;
    80002018:	4481                	li	s1,0
    8000201a:	b741                	j	80001f9a <ps+0xc6>
        return result;
    8000201c:	4481                	li	s1,0
    8000201e:	bfb5                	j	80001f9a <ps+0xc6>
        return result;
    80002020:	4481                	li	s1,0
    80002022:	bfa5                	j	80001f9a <ps+0xc6>

0000000080002024 <fork>:
{
    80002024:	7179                	addi	sp,sp,-48
    80002026:	f406                	sd	ra,40(sp)
    80002028:	f022                	sd	s0,32(sp)
    8000202a:	ec26                	sd	s1,24(sp)
    8000202c:	e84a                	sd	s2,16(sp)
    8000202e:	e44e                	sd	s3,8(sp)
    80002030:	e052                	sd	s4,0(sp)
    80002032:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002034:	00000097          	auipc	ra,0x0
    80002038:	a9a080e7          	jalr	-1382(ra) # 80001ace <myproc>
    8000203c:	892a                	mv	s2,a0
    if ((np = allocproc()) == 0)
    8000203e:	00000097          	auipc	ra,0x0
    80002042:	c9e080e7          	jalr	-866(ra) # 80001cdc <allocproc>
    80002046:	14050d63          	beqz	a0,800021a0 <fork+0x17c>
    8000204a:	89aa                	mv	s3,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    8000204c:	04893603          	ld	a2,72(s2)
    80002050:	692c                	ld	a1,80(a0)
    80002052:	05093503          	ld	a0,80(s2)
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	52a080e7          	jalr	1322(ra) # 80001580 <uvmcopy>
    8000205e:	04054663          	bltz	a0,800020aa <fork+0x86>
    np->sz = p->sz;
    80002062:	04893783          	ld	a5,72(s2)
    80002066:	04f9b423          	sd	a5,72(s3)
    *(np->trapframe) = *(p->trapframe);
    8000206a:	05893683          	ld	a3,88(s2)
    8000206e:	87b6                	mv	a5,a3
    80002070:	0589b703          	ld	a4,88(s3)
    80002074:	12068693          	addi	a3,a3,288
    80002078:	0007b803          	ld	a6,0(a5)
    8000207c:	6788                	ld	a0,8(a5)
    8000207e:	6b8c                	ld	a1,16(a5)
    80002080:	6f90                	ld	a2,24(a5)
    80002082:	01073023          	sd	a6,0(a4)
    80002086:	e708                	sd	a0,8(a4)
    80002088:	eb0c                	sd	a1,16(a4)
    8000208a:	ef10                	sd	a2,24(a4)
    8000208c:	02078793          	addi	a5,a5,32
    80002090:	02070713          	addi	a4,a4,32
    80002094:	fed792e3          	bne	a5,a3,80002078 <fork+0x54>
    np->trapframe->a0 = 0;
    80002098:	0589b783          	ld	a5,88(s3)
    8000209c:	0607b823          	sd	zero,112(a5)
    800020a0:	0d000493          	li	s1,208
    for (i = 0; i < NOFILE; i++)
    800020a4:	15000a13          	li	s4,336
    800020a8:	a03d                	j	800020d6 <fork+0xb2>
        freeproc(np);
    800020aa:	854e                	mv	a0,s3
    800020ac:	00000097          	auipc	ra,0x0
    800020b0:	bd4080e7          	jalr	-1068(ra) # 80001c80 <freeproc>
        release(&np->lock);
    800020b4:	854e                	mv	a0,s3
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	be8080e7          	jalr	-1048(ra) # 80000c9e <release>
        return -1;
    800020be:	5a7d                	li	s4,-1
    800020c0:	a0f9                	j	8000218e <fork+0x16a>
            np->ofile[i] = filedup(p->ofile[i]);
    800020c2:	00003097          	auipc	ra,0x3
    800020c6:	aa4080e7          	jalr	-1372(ra) # 80004b66 <filedup>
    800020ca:	009987b3          	add	a5,s3,s1
    800020ce:	e388                	sd	a0,0(a5)
    for (i = 0; i < NOFILE; i++)
    800020d0:	04a1                	addi	s1,s1,8
    800020d2:	01448763          	beq	s1,s4,800020e0 <fork+0xbc>
        if (p->ofile[i])
    800020d6:	009907b3          	add	a5,s2,s1
    800020da:	6388                	ld	a0,0(a5)
    800020dc:	f17d                	bnez	a0,800020c2 <fork+0x9e>
    800020de:	bfcd                	j	800020d0 <fork+0xac>
    np->cwd = idup(p->cwd);
    800020e0:	15093503          	ld	a0,336(s2)
    800020e4:	00002097          	auipc	ra,0x2
    800020e8:	c08080e7          	jalr	-1016(ra) # 80003cec <idup>
    800020ec:	14a9b823          	sd	a0,336(s3)
    safestrcpy(np->name, p->name, sizeof(p->name));
    800020f0:	4641                	li	a2,16
    800020f2:	15890593          	addi	a1,s2,344
    800020f6:	15898513          	addi	a0,s3,344
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	d3e080e7          	jalr	-706(ra) # 80000e38 <safestrcpy>
    pid = np->pid;
    80002102:	0309aa03          	lw	s4,48(s3)
    release(&np->lock);
    80002106:	854e                	mv	a0,s3
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	b96080e7          	jalr	-1130(ra) # 80000c9e <release>
    acquire(&wait_lock);
    80002110:	0000f497          	auipc	s1,0xf
    80002114:	fa848493          	addi	s1,s1,-88 # 800110b8 <wait_lock>
    80002118:	8526                	mv	a0,s1
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	ad0080e7          	jalr	-1328(ra) # 80000bea <acquire>
    np->parent = p;
    80002122:	0329bc23          	sd	s2,56(s3)
    release(&wait_lock);
    80002126:	8526                	mv	a0,s1
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	b76080e7          	jalr	-1162(ra) # 80000c9e <release>
    acquire(&np->lock);
    80002130:	854e                	mv	a0,s3
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	ab8080e7          	jalr	-1352(ra) # 80000bea <acquire>
    np->state = RUNNABLE;
    8000213a:	478d                	li	a5,3
    8000213c:	00f9ac23          	sw	a5,24(s3)
    release(&np->lock);
    80002140:	854e                	mv	a0,s3
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	b5c080e7          	jalr	-1188(ra) # 80000c9e <release>
    acquire(&priotable.lock);
    8000214a:	0000f497          	auipc	s1,0xf
    8000214e:	f8648493          	addi	s1,s1,-122 # 800110d0 <priotable>
    80002152:	8526                	mv	a0,s1
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	a96080e7          	jalr	-1386(ra) # 80000bea <acquire>
    priotable.priCount[0]++;
    8000215c:	00010697          	auipc	a3,0x10
    80002160:	b4468693          	addi	a3,a3,-1212 # 80011ca0 <proc+0x7b0>
    80002164:	8486a703          	lw	a4,-1976(a3)
    80002168:	2705                	addiw	a4,a4,1
    8000216a:	0007079b          	sext.w	a5,a4
    8000216e:	84e6a423          	sw	a4,-1976(a3)
    priotable.que[0][priotable.priCount[0]] = np;
    80002172:	0789                	addi	a5,a5,2
    80002174:	078e                	slli	a5,a5,0x3
    80002176:	0000f717          	auipc	a4,0xf
    8000217a:	b2a70713          	addi	a4,a4,-1238 # 80010ca0 <cpus>
    8000217e:	97ba                	add	a5,a5,a4
    80002180:	4337bc23          	sd	s3,1080(a5)
    release(&priotable.lock);
    80002184:	8526                	mv	a0,s1
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	b18080e7          	jalr	-1256(ra) # 80000c9e <release>
}
    8000218e:	8552                	mv	a0,s4
    80002190:	70a2                	ld	ra,40(sp)
    80002192:	7402                	ld	s0,32(sp)
    80002194:	64e2                	ld	s1,24(sp)
    80002196:	6942                	ld	s2,16(sp)
    80002198:	69a2                	ld	s3,8(sp)
    8000219a:	6a02                	ld	s4,0(sp)
    8000219c:	6145                	addi	sp,sp,48
    8000219e:	8082                	ret
        return -1;
    800021a0:	5a7d                	li	s4,-1
    800021a2:	b7f5                	j	8000218e <fork+0x16a>

00000000800021a4 <scheduler>:
{
    800021a4:	1101                	addi	sp,sp,-32
    800021a6:	ec06                	sd	ra,24(sp)
    800021a8:	e822                	sd	s0,16(sp)
    800021aa:	e426                	sd	s1,8(sp)
    800021ac:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800021ae:	00006497          	auipc	s1,0x6
    800021b2:	79a48493          	addi	s1,s1,1946 # 80008948 <sched_pointer>
    800021b6:	609c                	ld	a5,0(s1)
    800021b8:	9782                	jalr	a5
    while (1)
    800021ba:	bff5                	j	800021b6 <scheduler+0x12>

00000000800021bc <check_pri_Update>:
{
    800021bc:	1101                	addi	sp,sp,-32
    800021be:	ec06                	sd	ra,24(sp)
    800021c0:	e822                	sd	s0,16(sp)
    800021c2:	e426                	sd	s1,8(sp)
    800021c4:	1000                	addi	s0,sp,32
    800021c6:	84aa                	mv	s1,a0
    acquire(&priotable.lock);
    800021c8:	0000f517          	auipc	a0,0xf
    800021cc:	f0850513          	addi	a0,a0,-248 # 800110d0 <priotable>
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	a1a080e7          	jalr	-1510(ra) # 80000bea <acquire>
    while(priotable.que[1][i]->priUpgrade-ticks_proc<0 && i < priotable.priCount[1]) i++;
    800021d8:	0000f617          	auipc	a2,0xf
    800021dc:	11063603          	ld	a2,272(a2) # 800112e8 <priotable+0x218>
    800021e0:	16c62683          	lw	a3,364(a2)
    800021e4:	409687bb          	subw	a5,a3,s1
    800021e8:	0207d663          	bgez	a5,80002214 <check_pri_Update+0x58>
    800021ec:	0000f517          	auipc	a0,0xf
    800021f0:	30052503          	lw	a0,768(a0) # 800114ec <priotable+0x41c>
    800021f4:	0000f717          	auipc	a4,0xf
    800021f8:	0fc70713          	addi	a4,a4,252 # 800112f0 <priotable+0x220>
    int i = 0;
    800021fc:	4781                	li	a5,0
    while(priotable.que[1][i]->priUpgrade-ticks_proc<0 && i < priotable.priCount[1]) i++;
    800021fe:	00a7db63          	bge	a5,a0,80002214 <check_pri_Update+0x58>
    80002202:	2785                	addiw	a5,a5,1
    80002204:	6310                	ld	a2,0(a4)
    80002206:	16c62683          	lw	a3,364(a2)
    8000220a:	0721                	addi	a4,a4,8
    8000220c:	409685bb          	subw	a1,a3,s1
    80002210:	fe05c7e3          	bltz	a1,800021fe <check_pri_Update+0x42>
    if(priotable.que[1][i]->priUpgrade-ticks_proc == 0)
    80002214:	00d48f63          	beq	s1,a3,80002232 <check_pri_Update+0x76>
    release(&priotable.lock);
    80002218:	0000f517          	auipc	a0,0xf
    8000221c:	eb850513          	addi	a0,a0,-328 # 800110d0 <priotable>
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	a7e080e7          	jalr	-1410(ra) # 80000c9e <release>
}
    80002228:	60e2                	ld	ra,24(sp)
    8000222a:	6442                	ld	s0,16(sp)
    8000222c:	64a2                	ld	s1,8(sp)
    8000222e:	6105                	addi	sp,sp,32
    80002230:	8082                	ret
        priotable.priCount[0]++;
    80002232:	00010697          	auipc	a3,0x10
    80002236:	a6e68693          	addi	a3,a3,-1426 # 80011ca0 <proc+0x7b0>
    8000223a:	8486a703          	lw	a4,-1976(a3)
    8000223e:	2705                	addiw	a4,a4,1
    80002240:	0007079b          	sext.w	a5,a4
    80002244:	84e6a423          	sw	a4,-1976(a3)
        priotable.que[0][priotable.priCount[0]] = priotable.que[1][i];
    80002248:	0789                	addi	a5,a5,2
    8000224a:	078e                	slli	a5,a5,0x3
    8000224c:	0000f717          	auipc	a4,0xf
    80002250:	a5470713          	addi	a4,a4,-1452 # 80010ca0 <cpus>
    80002254:	97ba                	add	a5,a5,a4
    80002256:	42c7bc23          	sd	a2,1080(a5)
    8000225a:	bf7d                	j	80002218 <check_pri_Update+0x5c>

000000008000225c <mlfq_scheduler>:
{
    8000225c:	7159                	addi	sp,sp,-112
    8000225e:	f486                	sd	ra,104(sp)
    80002260:	f0a2                	sd	s0,96(sp)
    80002262:	eca6                	sd	s1,88(sp)
    80002264:	e8ca                	sd	s2,80(sp)
    80002266:	e4ce                	sd	s3,72(sp)
    80002268:	e0d2                	sd	s4,64(sp)
    8000226a:	fc56                	sd	s5,56(sp)
    8000226c:	f85a                	sd	s6,48(sp)
    8000226e:	f45e                	sd	s7,40(sp)
    80002270:	f062                	sd	s8,32(sp)
    80002272:	ec66                	sd	s9,24(sp)
    80002274:	e86a                	sd	s10,16(sp)
    80002276:	e46e                	sd	s11,8(sp)
    80002278:	1880                	addi	s0,sp,112
    8000227a:	8492                	mv	s1,tp
    int id = r_tp();
    8000227c:	2481                	sext.w	s1,s1
    c -> proc = 0;
    8000227e:	0000fb17          	auipc	s6,0xf
    80002282:	a22b0b13          	addi	s6,s6,-1502 # 80010ca0 <cpus>
    80002286:	00749913          	slli	s2,s1,0x7
    8000228a:	012b07b3          	add	a5,s6,s2
    8000228e:	0007b023          	sd	zero,0(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002292:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002296:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000229a:	10079073          	csrw	sstatus,a5
    acquire(&priotable.lock);
    8000229e:	0000f517          	auipc	a0,0xf
    800022a2:	e3250513          	addi	a0,a0,-462 # 800110d0 <priotable>
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	944080e7          	jalr	-1724(ra) # 80000bea <acquire>
            swtch(&c->context, &p->context);
    800022ae:	0921                	addi	s2,s2,8
    800022b0:	9b4a                	add	s6,s6,s2
    800022b2:	0000fd97          	auipc	s11,0xf
    800022b6:	236d8d93          	addi	s11,s11,566 # 800114e8 <priotable+0x418>
    800022ba:	0000f997          	auipc	s3,0xf
    800022be:	e2e98993          	addi	s3,s3,-466 # 800110e8 <priotable+0x18>
    800022c2:	4a81                	li	s5,0
    800022c4:	0000fd17          	auipc	s10,0xf
    800022c8:	e2cd0d13          	addi	s10,s10,-468 # 800110f0 <priotable+0x20>
            ticks_proc++;
    800022cc:	00006a17          	auipc	s4,0x6
    800022d0:	75ca0a13          	addi	s4,s4,1884 # 80008a28 <ticks_proc>
            proc->state = RUNNING;
    800022d4:	0000fc97          	auipc	s9,0xf
    800022d8:	21cc8c93          	addi	s9,s9,540 # 800114f0 <proc>
    800022dc:	4c11                	li	s8,4
            c->proc = 0;
    800022de:	049e                	slli	s1,s1,0x7
    800022e0:	0000fb97          	auipc	s7,0xf
    800022e4:	9c0b8b93          	addi	s7,s7,-1600 # 80010ca0 <cpus>
    800022e8:	9ba6                	add	s7,s7,s1
    800022ea:	a8bd                	j	80002368 <mlfq_scheduler+0x10c>
            acquire(&p->lock);
    800022ec:	8526                	mv	a0,s1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	8fc080e7          	jalr	-1796(ra) # 80000bea <acquire>
            priotable.priCount[i] --;
    800022f6:	00092783          	lw	a5,0(s2)
    800022fa:	37fd                	addiw	a5,a5,-1
    800022fc:	00f92023          	sw	a5,0(s2)
            ticks_proc++;
    80002300:	000a2783          	lw	a5,0(s4)
    80002304:	2785                	addiw	a5,a5,1
    80002306:	00fa2023          	sw	a5,0(s4)
            proc->state = RUNNING;
    8000230a:	018cac23          	sw	s8,24(s9)
            swtch(&c->context, &p->context);
    8000230e:	06048593          	addi	a1,s1,96
    80002312:	855a                	mv	a0,s6
    80002314:	00001097          	auipc	ra,0x1
    80002318:	910080e7          	jalr	-1776(ra) # 80002c24 <swtch>
            c->proc = 0;
    8000231c:	000bb023          	sd	zero,0(s7)
            release(&p->lock);
    80002320:	8526                	mv	a0,s1
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	97c080e7          	jalr	-1668(ra) # 80000c9e <release>
        while(priotable.priCount[i]>(-1)){
    8000232a:	00092783          	lw	a5,0(s2)
    8000232e:	0207c463          	bltz	a5,80002356 <mlfq_scheduler+0xfa>
            p = priotable.que[i][0];
    80002332:	0009b483          	ld	s1,0(s3)
            for(int j = 0; j < priotable.priCount[i]; j++){
    80002336:	faf05be3          	blez	a5,800022ec <mlfq_scheduler+0x90>
    8000233a:	fff7871b          	addiw	a4,a5,-1
    8000233e:	1702                	slli	a4,a4,0x20
    80002340:	9301                	srli	a4,a4,0x20
    80002342:	9756                	add	a4,a4,s5
    80002344:	070e                	slli	a4,a4,0x3
    80002346:	976a                	add	a4,a4,s10
    80002348:	87ce                	mv	a5,s3
                priotable.que[i][j] = priotable.que[i][j+1];
    8000234a:	6794                	ld	a3,8(a5)
    8000234c:	e394                	sd	a3,0(a5)
            for(int j = 0; j < priotable.priCount[i]; j++){
    8000234e:	07a1                	addi	a5,a5,8
    80002350:	fee79de3          	bne	a5,a4,8000234a <mlfq_scheduler+0xee>
    80002354:	bf61                	j	800022ec <mlfq_scheduler+0x90>
    for(int i = 0; i < PRIORITY_QUEUES; i++){
    80002356:	0d91                	addi	s11,s11,4
    80002358:	20098993          	addi	s3,s3,512
    8000235c:	040a8a93          	addi	s5,s5,64
    80002360:	08000793          	li	a5,128
    80002364:	00fa8863          	beq	s5,a5,80002374 <mlfq_scheduler+0x118>
        while(priotable.priCount[i]>(-1)){
    80002368:	896e                	mv	s2,s11
    8000236a:	000da783          	lw	a5,0(s11)
    8000236e:	fc07d2e3          	bgez	a5,80002332 <mlfq_scheduler+0xd6>
    80002372:	b7d5                	j	80002356 <mlfq_scheduler+0xfa>
    release(&priotable.lock);
    80002374:	0000f517          	auipc	a0,0xf
    80002378:	d5c50513          	addi	a0,a0,-676 # 800110d0 <priotable>
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	922080e7          	jalr	-1758(ra) # 80000c9e <release>
    check_pri_Update(ticks_proc);
    80002384:	00006517          	auipc	a0,0x6
    80002388:	6a452503          	lw	a0,1700(a0) # 80008a28 <ticks_proc>
    8000238c:	00000097          	auipc	ra,0x0
    80002390:	e30080e7          	jalr	-464(ra) # 800021bc <check_pri_Update>
}
    80002394:	70a6                	ld	ra,104(sp)
    80002396:	7406                	ld	s0,96(sp)
    80002398:	64e6                	ld	s1,88(sp)
    8000239a:	6946                	ld	s2,80(sp)
    8000239c:	69a6                	ld	s3,72(sp)
    8000239e:	6a06                	ld	s4,64(sp)
    800023a0:	7ae2                	ld	s5,56(sp)
    800023a2:	7b42                	ld	s6,48(sp)
    800023a4:	7ba2                	ld	s7,40(sp)
    800023a6:	7c02                	ld	s8,32(sp)
    800023a8:	6ce2                	ld	s9,24(sp)
    800023aa:	6d42                	ld	s10,16(sp)
    800023ac:	6da2                	ld	s11,8(sp)
    800023ae:	6165                	addi	sp,sp,112
    800023b0:	8082                	ret

00000000800023b2 <sched>:
{
    800023b2:	7179                	addi	sp,sp,-48
    800023b4:	f406                	sd	ra,40(sp)
    800023b6:	f022                	sd	s0,32(sp)
    800023b8:	ec26                	sd	s1,24(sp)
    800023ba:	e84a                	sd	s2,16(sp)
    800023bc:	e44e                	sd	s3,8(sp)
    800023be:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	70e080e7          	jalr	1806(ra) # 80001ace <myproc>
    800023c8:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800023ca:	ffffe097          	auipc	ra,0xffffe
    800023ce:	7a6080e7          	jalr	1958(ra) # 80000b70 <holding>
    800023d2:	c53d                	beqz	a0,80002440 <sched+0x8e>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023d4:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    800023d6:	2781                	sext.w	a5,a5
    800023d8:	079e                	slli	a5,a5,0x7
    800023da:	0000f717          	auipc	a4,0xf
    800023de:	8c670713          	addi	a4,a4,-1850 # 80010ca0 <cpus>
    800023e2:	97ba                	add	a5,a5,a4
    800023e4:	5fb8                	lw	a4,120(a5)
    800023e6:	4785                	li	a5,1
    800023e8:	06f71463          	bne	a4,a5,80002450 <sched+0x9e>
    if (p->state == RUNNING)
    800023ec:	4c98                	lw	a4,24(s1)
    800023ee:	4791                	li	a5,4
    800023f0:	06f70863          	beq	a4,a5,80002460 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023f4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023f8:	8b89                	andi	a5,a5,2
    if (intr_get())
    800023fa:	ebbd                	bnez	a5,80002470 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023fc:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    800023fe:	0000f917          	auipc	s2,0xf
    80002402:	8a290913          	addi	s2,s2,-1886 # 80010ca0 <cpus>
    80002406:	2781                	sext.w	a5,a5
    80002408:	079e                	slli	a5,a5,0x7
    8000240a:	97ca                	add	a5,a5,s2
    8000240c:	07c7a983          	lw	s3,124(a5)
    80002410:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    80002412:	2581                	sext.w	a1,a1
    80002414:	059e                	slli	a1,a1,0x7
    80002416:	05a1                	addi	a1,a1,8
    80002418:	95ca                	add	a1,a1,s2
    8000241a:	06048513          	addi	a0,s1,96
    8000241e:	00001097          	auipc	ra,0x1
    80002422:	806080e7          	jalr	-2042(ra) # 80002c24 <swtch>
    80002426:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002428:	2781                	sext.w	a5,a5
    8000242a:	079e                	slli	a5,a5,0x7
    8000242c:	993e                	add	s2,s2,a5
    8000242e:	07392e23          	sw	s3,124(s2)
}
    80002432:	70a2                	ld	ra,40(sp)
    80002434:	7402                	ld	s0,32(sp)
    80002436:	64e2                	ld	s1,24(sp)
    80002438:	6942                	ld	s2,16(sp)
    8000243a:	69a2                	ld	s3,8(sp)
    8000243c:	6145                	addi	sp,sp,48
    8000243e:	8082                	ret
        panic("sched p->lock");
    80002440:	00006517          	auipc	a0,0x6
    80002444:	de850513          	addi	a0,a0,-536 # 80008228 <digits+0x1e8>
    80002448:	ffffe097          	auipc	ra,0xffffe
    8000244c:	0fc080e7          	jalr	252(ra) # 80000544 <panic>
        panic("sched locks");
    80002450:	00006517          	auipc	a0,0x6
    80002454:	de850513          	addi	a0,a0,-536 # 80008238 <digits+0x1f8>
    80002458:	ffffe097          	auipc	ra,0xffffe
    8000245c:	0ec080e7          	jalr	236(ra) # 80000544 <panic>
        panic("sched running");
    80002460:	00006517          	auipc	a0,0x6
    80002464:	de850513          	addi	a0,a0,-536 # 80008248 <digits+0x208>
    80002468:	ffffe097          	auipc	ra,0xffffe
    8000246c:	0dc080e7          	jalr	220(ra) # 80000544 <panic>
        panic("sched interruptible");
    80002470:	00006517          	auipc	a0,0x6
    80002474:	de850513          	addi	a0,a0,-536 # 80008258 <digits+0x218>
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	0cc080e7          	jalr	204(ra) # 80000544 <panic>

0000000080002480 <yield>:
{
    80002480:	1101                	addi	sp,sp,-32
    80002482:	ec06                	sd	ra,24(sp)
    80002484:	e822                	sd	s0,16(sp)
    80002486:	e426                	sd	s1,8(sp)
    80002488:	e04a                	sd	s2,0(sp)
    8000248a:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	642080e7          	jalr	1602(ra) # 80001ace <myproc>
    80002494:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002496:	ffffe097          	auipc	ra,0xffffe
    8000249a:	754080e7          	jalr	1876(ra) # 80000bea <acquire>
    p->state = RUNNABLE;
    8000249e:	478d                	li	a5,3
    800024a0:	cc9c                	sw	a5,24(s1)
    sched();
    800024a2:	00000097          	auipc	ra,0x0
    800024a6:	f10080e7          	jalr	-240(ra) # 800023b2 <sched>
    if(sched_pointer == available_schedulers[1].impl)
    800024aa:	00006717          	auipc	a4,0x6
    800024ae:	51e73703          	ld	a4,1310(a4) # 800089c8 <available_schedulers+0x30>
    800024b2:	00006797          	auipc	a5,0x6
    800024b6:	4967b783          	ld	a5,1174(a5) # 80008948 <sched_pointer>
    800024ba:	00f70d63          	beq	a4,a5,800024d4 <yield+0x54>
    release(&p->lock);
    800024be:	8526                	mv	a0,s1
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	7de080e7          	jalr	2014(ra) # 80000c9e <release>
}
    800024c8:	60e2                	ld	ra,24(sp)
    800024ca:	6442                	ld	s0,16(sp)
    800024cc:	64a2                	ld	s1,8(sp)
    800024ce:	6902                	ld	s2,0(sp)
    800024d0:	6105                	addi	sp,sp,32
    800024d2:	8082                	ret
    if(p->priority==0) 
    800024d4:	1684a783          	lw	a5,360(s1)
    800024d8:	efb1                	bnez	a5,80002534 <yield+0xb4>
        p->priority ++;
    800024da:	4785                	li	a5,1
    800024dc:	16f4a423          	sw	a5,360(s1)
        p->priUpgrade = ticks_proc;
    800024e0:	00006797          	auipc	a5,0x6
    800024e4:	5487a783          	lw	a5,1352(a5) # 80008a28 <ticks_proc>
    800024e8:	16f4a623          	sw	a5,364(s1)
        acquire(&priotable.lock);
    800024ec:	0000f917          	auipc	s2,0xf
    800024f0:	be490913          	addi	s2,s2,-1052 # 800110d0 <priotable>
    800024f4:	854a                	mv	a0,s2
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	6f4080e7          	jalr	1780(ra) # 80000bea <acquire>
        priotable.priCount[1]++;
    800024fe:	0000f697          	auipc	a3,0xf
    80002502:	7a268693          	addi	a3,a3,1954 # 80011ca0 <proc+0x7b0>
    80002506:	84c6a703          	lw	a4,-1972(a3)
    8000250a:	2705                	addiw	a4,a4,1
    8000250c:	0007079b          	sext.w	a5,a4
    80002510:	84e6a623          	sw	a4,-1972(a3)
        priotable.que[1][priotable.priCount[1]]=p;
    80002514:	04278793          	addi	a5,a5,66
    80002518:	078e                	slli	a5,a5,0x3
    8000251a:	0000e717          	auipc	a4,0xe
    8000251e:	78670713          	addi	a4,a4,1926 # 80010ca0 <cpus>
    80002522:	97ba                	add	a5,a5,a4
    80002524:	4297bc23          	sd	s1,1080(a5)
        release(&priotable.lock);
    80002528:	854a                	mv	a0,s2
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	774080e7          	jalr	1908(ra) # 80000c9e <release>
    80002532:	b771                	j	800024be <yield+0x3e>
        acquire(&priotable.lock);
    80002534:	0000f917          	auipc	s2,0xf
    80002538:	b9c90913          	addi	s2,s2,-1124 # 800110d0 <priotable>
    8000253c:	854a                	mv	a0,s2
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	6ac080e7          	jalr	1708(ra) # 80000bea <acquire>
        priotable.priCount[1]++;
    80002546:	0000f697          	auipc	a3,0xf
    8000254a:	75a68693          	addi	a3,a3,1882 # 80011ca0 <proc+0x7b0>
    8000254e:	84c6a703          	lw	a4,-1972(a3)
    80002552:	2705                	addiw	a4,a4,1
    80002554:	0007079b          	sext.w	a5,a4
    80002558:	84e6a623          	sw	a4,-1972(a3)
        priotable.que[1][priotable.priCount[1]]=p;
    8000255c:	04278793          	addi	a5,a5,66
    80002560:	078e                	slli	a5,a5,0x3
    80002562:	0000e717          	auipc	a4,0xe
    80002566:	73e70713          	addi	a4,a4,1854 # 80010ca0 <cpus>
    8000256a:	97ba                	add	a5,a5,a4
    8000256c:	4297bc23          	sd	s1,1080(a5)
        release(&priotable.lock);
    80002570:	854a                	mv	a0,s2
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	72c080e7          	jalr	1836(ra) # 80000c9e <release>
    8000257a:	b791                	j	800024be <yield+0x3e>

000000008000257c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000257c:	7179                	addi	sp,sp,-48
    8000257e:	f406                	sd	ra,40(sp)
    80002580:	f022                	sd	s0,32(sp)
    80002582:	ec26                	sd	s1,24(sp)
    80002584:	e84a                	sd	s2,16(sp)
    80002586:	e44e                	sd	s3,8(sp)
    80002588:	1800                	addi	s0,sp,48
    8000258a:	89aa                	mv	s3,a0
    8000258c:	892e                	mv	s2,a1
    struct proc *p = myproc();
    8000258e:	fffff097          	auipc	ra,0xfffff
    80002592:	540080e7          	jalr	1344(ra) # 80001ace <myproc>
    80002596:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	652080e7          	jalr	1618(ra) # 80000bea <acquire>
    release(lk);
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	6fc080e7          	jalr	1788(ra) # 80000c9e <release>

    // Go to sleep.
    p->chan = chan;
    800025aa:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800025ae:	4789                	li	a5,2
    800025b0:	cc9c                	sw	a5,24(s1)

    sched();
    800025b2:	00000097          	auipc	ra,0x0
    800025b6:	e00080e7          	jalr	-512(ra) # 800023b2 <sched>

    // Tidy up.
    p->chan = 0;
    800025ba:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    800025be:	8526                	mv	a0,s1
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	6de080e7          	jalr	1758(ra) # 80000c9e <release>
    acquire(lk);
    800025c8:	854a                	mv	a0,s2
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	620080e7          	jalr	1568(ra) # 80000bea <acquire>
}
    800025d2:	70a2                	ld	ra,40(sp)
    800025d4:	7402                	ld	s0,32(sp)
    800025d6:	64e2                	ld	s1,24(sp)
    800025d8:	6942                	ld	s2,16(sp)
    800025da:	69a2                	ld	s3,8(sp)
    800025dc:	6145                	addi	sp,sp,48
    800025de:	8082                	ret

00000000800025e0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800025e0:	7139                	addi	sp,sp,-64
    800025e2:	fc06                	sd	ra,56(sp)
    800025e4:	f822                	sd	s0,48(sp)
    800025e6:	f426                	sd	s1,40(sp)
    800025e8:	f04a                	sd	s2,32(sp)
    800025ea:	ec4e                	sd	s3,24(sp)
    800025ec:	e852                	sd	s4,16(sp)
    800025ee:	e456                	sd	s5,8(sp)
    800025f0:	0080                	addi	s0,sp,64
    800025f2:	8a2a                	mv	s4,a0
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++)
    800025f4:	0000f497          	auipc	s1,0xf
    800025f8:	efc48493          	addi	s1,s1,-260 # 800114f0 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    800025fc:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    800025fe:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002600:	00015917          	auipc	s2,0x15
    80002604:	af090913          	addi	s2,s2,-1296 # 800170f0 <tickslock>
    80002608:	a821                	j	80002620 <wakeup+0x40>
                p->state = RUNNABLE;
    8000260a:	0154ac23          	sw	s5,24(s1)
            }
            release(&p->lock);
    8000260e:	8526                	mv	a0,s1
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	68e080e7          	jalr	1678(ra) # 80000c9e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002618:	17048493          	addi	s1,s1,368
    8000261c:	03248463          	beq	s1,s2,80002644 <wakeup+0x64>
        if (p != myproc())
    80002620:	fffff097          	auipc	ra,0xfffff
    80002624:	4ae080e7          	jalr	1198(ra) # 80001ace <myproc>
    80002628:	fea488e3          	beq	s1,a0,80002618 <wakeup+0x38>
            acquire(&p->lock);
    8000262c:	8526                	mv	a0,s1
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	5bc080e7          	jalr	1468(ra) # 80000bea <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    80002636:	4c9c                	lw	a5,24(s1)
    80002638:	fd379be3          	bne	a5,s3,8000260e <wakeup+0x2e>
    8000263c:	709c                	ld	a5,32(s1)
    8000263e:	fd4798e3          	bne	a5,s4,8000260e <wakeup+0x2e>
    80002642:	b7e1                	j	8000260a <wakeup+0x2a>
        }
    }
}
    80002644:	70e2                	ld	ra,56(sp)
    80002646:	7442                	ld	s0,48(sp)
    80002648:	74a2                	ld	s1,40(sp)
    8000264a:	7902                	ld	s2,32(sp)
    8000264c:	69e2                	ld	s3,24(sp)
    8000264e:	6a42                	ld	s4,16(sp)
    80002650:	6aa2                	ld	s5,8(sp)
    80002652:	6121                	addi	sp,sp,64
    80002654:	8082                	ret

0000000080002656 <reparent>:
{
    80002656:	7179                	addi	sp,sp,-48
    80002658:	f406                	sd	ra,40(sp)
    8000265a:	f022                	sd	s0,32(sp)
    8000265c:	ec26                	sd	s1,24(sp)
    8000265e:	e84a                	sd	s2,16(sp)
    80002660:	e44e                	sd	s3,8(sp)
    80002662:	e052                	sd	s4,0(sp)
    80002664:	1800                	addi	s0,sp,48
    80002666:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002668:	0000f497          	auipc	s1,0xf
    8000266c:	e8848493          	addi	s1,s1,-376 # 800114f0 <proc>
            pp->parent = initproc;
    80002670:	00006a17          	auipc	s4,0x6
    80002674:	3c0a0a13          	addi	s4,s4,960 # 80008a30 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002678:	00015997          	auipc	s3,0x15
    8000267c:	a7898993          	addi	s3,s3,-1416 # 800170f0 <tickslock>
    80002680:	a029                	j	8000268a <reparent+0x34>
    80002682:	17048493          	addi	s1,s1,368
    80002686:	01348d63          	beq	s1,s3,800026a0 <reparent+0x4a>
        if (pp->parent == p)
    8000268a:	7c9c                	ld	a5,56(s1)
    8000268c:	ff279be3          	bne	a5,s2,80002682 <reparent+0x2c>
            pp->parent = initproc;
    80002690:	000a3503          	ld	a0,0(s4)
    80002694:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    80002696:	00000097          	auipc	ra,0x0
    8000269a:	f4a080e7          	jalr	-182(ra) # 800025e0 <wakeup>
    8000269e:	b7d5                	j	80002682 <reparent+0x2c>
}
    800026a0:	70a2                	ld	ra,40(sp)
    800026a2:	7402                	ld	s0,32(sp)
    800026a4:	64e2                	ld	s1,24(sp)
    800026a6:	6942                	ld	s2,16(sp)
    800026a8:	69a2                	ld	s3,8(sp)
    800026aa:	6a02                	ld	s4,0(sp)
    800026ac:	6145                	addi	sp,sp,48
    800026ae:	8082                	ret

00000000800026b0 <exit>:
{
    800026b0:	7179                	addi	sp,sp,-48
    800026b2:	f406                	sd	ra,40(sp)
    800026b4:	f022                	sd	s0,32(sp)
    800026b6:	ec26                	sd	s1,24(sp)
    800026b8:	e84a                	sd	s2,16(sp)
    800026ba:	e44e                	sd	s3,8(sp)
    800026bc:	e052                	sd	s4,0(sp)
    800026be:	1800                	addi	s0,sp,48
    800026c0:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    800026c2:	fffff097          	auipc	ra,0xfffff
    800026c6:	40c080e7          	jalr	1036(ra) # 80001ace <myproc>
    800026ca:	89aa                	mv	s3,a0
    if (p == initproc)
    800026cc:	00006797          	auipc	a5,0x6
    800026d0:	3647b783          	ld	a5,868(a5) # 80008a30 <initproc>
    800026d4:	0d050493          	addi	s1,a0,208
    800026d8:	15050913          	addi	s2,a0,336
    800026dc:	02a79363          	bne	a5,a0,80002702 <exit+0x52>
        panic("init exiting");
    800026e0:	00006517          	auipc	a0,0x6
    800026e4:	b9050513          	addi	a0,a0,-1136 # 80008270 <digits+0x230>
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	e5c080e7          	jalr	-420(ra) # 80000544 <panic>
            fileclose(f);
    800026f0:	00002097          	auipc	ra,0x2
    800026f4:	4c8080e7          	jalr	1224(ra) # 80004bb8 <fileclose>
            p->ofile[fd] = 0;
    800026f8:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    800026fc:	04a1                	addi	s1,s1,8
    800026fe:	01248563          	beq	s1,s2,80002708 <exit+0x58>
        if (p->ofile[fd])
    80002702:	6088                	ld	a0,0(s1)
    80002704:	f575                	bnez	a0,800026f0 <exit+0x40>
    80002706:	bfdd                	j	800026fc <exit+0x4c>
    begin_op();
    80002708:	00002097          	auipc	ra,0x2
    8000270c:	fe4080e7          	jalr	-28(ra) # 800046ec <begin_op>
    iput(p->cwd);
    80002710:	1509b503          	ld	a0,336(s3)
    80002714:	00001097          	auipc	ra,0x1
    80002718:	7d0080e7          	jalr	2000(ra) # 80003ee4 <iput>
    end_op();
    8000271c:	00002097          	auipc	ra,0x2
    80002720:	050080e7          	jalr	80(ra) # 8000476c <end_op>
    p->cwd = 0;
    80002724:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    80002728:	0000f497          	auipc	s1,0xf
    8000272c:	99048493          	addi	s1,s1,-1648 # 800110b8 <wait_lock>
    80002730:	8526                	mv	a0,s1
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	4b8080e7          	jalr	1208(ra) # 80000bea <acquire>
    reparent(p);
    8000273a:	854e                	mv	a0,s3
    8000273c:	00000097          	auipc	ra,0x0
    80002740:	f1a080e7          	jalr	-230(ra) # 80002656 <reparent>
    wakeup(p->parent);
    80002744:	0389b503          	ld	a0,56(s3)
    80002748:	00000097          	auipc	ra,0x0
    8000274c:	e98080e7          	jalr	-360(ra) # 800025e0 <wakeup>
    acquire(&p->lock);
    80002750:	854e                	mv	a0,s3
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	498080e7          	jalr	1176(ra) # 80000bea <acquire>
    p->xstate = status;
    8000275a:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    8000275e:	4795                	li	a5,5
    80002760:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    80002764:	8526                	mv	a0,s1
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	538080e7          	jalr	1336(ra) # 80000c9e <release>
    sched();
    8000276e:	00000097          	auipc	ra,0x0
    80002772:	c44080e7          	jalr	-956(ra) # 800023b2 <sched>
    panic("zombie exit");
    80002776:	00006517          	auipc	a0,0x6
    8000277a:	b0a50513          	addi	a0,a0,-1270 # 80008280 <digits+0x240>
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	dc6080e7          	jalr	-570(ra) # 80000544 <panic>

0000000080002786 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002786:	7179                	addi	sp,sp,-48
    80002788:	f406                	sd	ra,40(sp)
    8000278a:	f022                	sd	s0,32(sp)
    8000278c:	ec26                	sd	s1,24(sp)
    8000278e:	e84a                	sd	s2,16(sp)
    80002790:	e44e                	sd	s3,8(sp)
    80002792:	1800                	addi	s0,sp,48
    80002794:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002796:	0000f497          	auipc	s1,0xf
    8000279a:	d5a48493          	addi	s1,s1,-678 # 800114f0 <proc>
    8000279e:	00015997          	auipc	s3,0x15
    800027a2:	95298993          	addi	s3,s3,-1710 # 800170f0 <tickslock>
    {
        acquire(&p->lock);
    800027a6:	8526                	mv	a0,s1
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	442080e7          	jalr	1090(ra) # 80000bea <acquire>
        if (p->pid == pid)
    800027b0:	589c                	lw	a5,48(s1)
    800027b2:	01278d63          	beq	a5,s2,800027cc <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800027b6:	8526                	mv	a0,s1
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	4e6080e7          	jalr	1254(ra) # 80000c9e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800027c0:	17048493          	addi	s1,s1,368
    800027c4:	ff3491e3          	bne	s1,s3,800027a6 <kill+0x20>
    }
    return -1;
    800027c8:	557d                	li	a0,-1
    800027ca:	a829                	j	800027e4 <kill+0x5e>
            p->killed = 1;
    800027cc:	4785                	li	a5,1
    800027ce:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    800027d0:	4c98                	lw	a4,24(s1)
    800027d2:	4789                	li	a5,2
    800027d4:	00f70f63          	beq	a4,a5,800027f2 <kill+0x6c>
            release(&p->lock);
    800027d8:	8526                	mv	a0,s1
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	4c4080e7          	jalr	1220(ra) # 80000c9e <release>
            return 0;
    800027e2:	4501                	li	a0,0
}
    800027e4:	70a2                	ld	ra,40(sp)
    800027e6:	7402                	ld	s0,32(sp)
    800027e8:	64e2                	ld	s1,24(sp)
    800027ea:	6942                	ld	s2,16(sp)
    800027ec:	69a2                	ld	s3,8(sp)
    800027ee:	6145                	addi	sp,sp,48
    800027f0:	8082                	ret
                p->state = RUNNABLE;
    800027f2:	478d                	li	a5,3
    800027f4:	cc9c                	sw	a5,24(s1)
    800027f6:	b7cd                	j	800027d8 <kill+0x52>

00000000800027f8 <setkilled>:

void setkilled(struct proc *p)
{
    800027f8:	1101                	addi	sp,sp,-32
    800027fa:	ec06                	sd	ra,24(sp)
    800027fc:	e822                	sd	s0,16(sp)
    800027fe:	e426                	sd	s1,8(sp)
    80002800:	1000                	addi	s0,sp,32
    80002802:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	3e6080e7          	jalr	998(ra) # 80000bea <acquire>
    p->killed = 1;
    8000280c:	4785                	li	a5,1
    8000280e:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    80002810:	8526                	mv	a0,s1
    80002812:	ffffe097          	auipc	ra,0xffffe
    80002816:	48c080e7          	jalr	1164(ra) # 80000c9e <release>
}
    8000281a:	60e2                	ld	ra,24(sp)
    8000281c:	6442                	ld	s0,16(sp)
    8000281e:	64a2                	ld	s1,8(sp)
    80002820:	6105                	addi	sp,sp,32
    80002822:	8082                	ret

0000000080002824 <killed>:

int killed(struct proc *p)
{
    80002824:	1101                	addi	sp,sp,-32
    80002826:	ec06                	sd	ra,24(sp)
    80002828:	e822                	sd	s0,16(sp)
    8000282a:	e426                	sd	s1,8(sp)
    8000282c:	e04a                	sd	s2,0(sp)
    8000282e:	1000                	addi	s0,sp,32
    80002830:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	3b8080e7          	jalr	952(ra) # 80000bea <acquire>
    k = p->killed;
    8000283a:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    8000283e:	8526                	mv	a0,s1
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	45e080e7          	jalr	1118(ra) # 80000c9e <release>
    return k;
}
    80002848:	854a                	mv	a0,s2
    8000284a:	60e2                	ld	ra,24(sp)
    8000284c:	6442                	ld	s0,16(sp)
    8000284e:	64a2                	ld	s1,8(sp)
    80002850:	6902                	ld	s2,0(sp)
    80002852:	6105                	addi	sp,sp,32
    80002854:	8082                	ret

0000000080002856 <wait>:
{
    80002856:	715d                	addi	sp,sp,-80
    80002858:	e486                	sd	ra,72(sp)
    8000285a:	e0a2                	sd	s0,64(sp)
    8000285c:	fc26                	sd	s1,56(sp)
    8000285e:	f84a                	sd	s2,48(sp)
    80002860:	f44e                	sd	s3,40(sp)
    80002862:	f052                	sd	s4,32(sp)
    80002864:	ec56                	sd	s5,24(sp)
    80002866:	e85a                	sd	s6,16(sp)
    80002868:	e45e                	sd	s7,8(sp)
    8000286a:	e062                	sd	s8,0(sp)
    8000286c:	0880                	addi	s0,sp,80
    8000286e:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002870:	fffff097          	auipc	ra,0xfffff
    80002874:	25e080e7          	jalr	606(ra) # 80001ace <myproc>
    80002878:	892a                	mv	s2,a0
    acquire(&wait_lock);
    8000287a:	0000f517          	auipc	a0,0xf
    8000287e:	83e50513          	addi	a0,a0,-1986 # 800110b8 <wait_lock>
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	368080e7          	jalr	872(ra) # 80000bea <acquire>
        havekids = 0;
    8000288a:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    8000288c:	4a15                	li	s4,5
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000288e:	00015997          	auipc	s3,0x15
    80002892:	86298993          	addi	s3,s3,-1950 # 800170f0 <tickslock>
                havekids = 1;
    80002896:	4a85                	li	s5,1
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002898:	0000fc17          	auipc	s8,0xf
    8000289c:	820c0c13          	addi	s8,s8,-2016 # 800110b8 <wait_lock>
        havekids = 0;
    800028a0:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800028a2:	0000f497          	auipc	s1,0xf
    800028a6:	c4e48493          	addi	s1,s1,-946 # 800114f0 <proc>
    800028aa:	a0bd                	j	80002918 <wait+0xc2>
                    pid = pp->pid;
    800028ac:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800028b0:	000b0e63          	beqz	s6,800028cc <wait+0x76>
    800028b4:	4691                	li	a3,4
    800028b6:	02c48613          	addi	a2,s1,44
    800028ba:	85da                	mv	a1,s6
    800028bc:	05093503          	ld	a0,80(s2)
    800028c0:	fffff097          	auipc	ra,0xfffff
    800028c4:	dc4080e7          	jalr	-572(ra) # 80001684 <copyout>
    800028c8:	02054563          	bltz	a0,800028f2 <wait+0x9c>
                    freeproc(pp);
    800028cc:	8526                	mv	a0,s1
    800028ce:	fffff097          	auipc	ra,0xfffff
    800028d2:	3b2080e7          	jalr	946(ra) # 80001c80 <freeproc>
                    release(&pp->lock);
    800028d6:	8526                	mv	a0,s1
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	3c6080e7          	jalr	966(ra) # 80000c9e <release>
                    release(&wait_lock);
    800028e0:	0000e517          	auipc	a0,0xe
    800028e4:	7d850513          	addi	a0,a0,2008 # 800110b8 <wait_lock>
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	3b6080e7          	jalr	950(ra) # 80000c9e <release>
                    return pid;
    800028f0:	a0b5                	j	8000295c <wait+0x106>
                        release(&pp->lock);
    800028f2:	8526                	mv	a0,s1
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	3aa080e7          	jalr	938(ra) # 80000c9e <release>
                        release(&wait_lock);
    800028fc:	0000e517          	auipc	a0,0xe
    80002900:	7bc50513          	addi	a0,a0,1980 # 800110b8 <wait_lock>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	39a080e7          	jalr	922(ra) # 80000c9e <release>
                        return -1;
    8000290c:	59fd                	li	s3,-1
    8000290e:	a0b9                	j	8000295c <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002910:	17048493          	addi	s1,s1,368
    80002914:	03348463          	beq	s1,s3,8000293c <wait+0xe6>
            if (pp->parent == p)
    80002918:	7c9c                	ld	a5,56(s1)
    8000291a:	ff279be3          	bne	a5,s2,80002910 <wait+0xba>
                acquire(&pp->lock);
    8000291e:	8526                	mv	a0,s1
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	2ca080e7          	jalr	714(ra) # 80000bea <acquire>
                if (pp->state == ZOMBIE)
    80002928:	4c9c                	lw	a5,24(s1)
    8000292a:	f94781e3          	beq	a5,s4,800028ac <wait+0x56>
                release(&pp->lock);
    8000292e:	8526                	mv	a0,s1
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	36e080e7          	jalr	878(ra) # 80000c9e <release>
                havekids = 1;
    80002938:	8756                	mv	a4,s5
    8000293a:	bfd9                	j	80002910 <wait+0xba>
        if (!havekids || killed(p))
    8000293c:	c719                	beqz	a4,8000294a <wait+0xf4>
    8000293e:	854a                	mv	a0,s2
    80002940:	00000097          	auipc	ra,0x0
    80002944:	ee4080e7          	jalr	-284(ra) # 80002824 <killed>
    80002948:	c51d                	beqz	a0,80002976 <wait+0x120>
            release(&wait_lock);
    8000294a:	0000e517          	auipc	a0,0xe
    8000294e:	76e50513          	addi	a0,a0,1902 # 800110b8 <wait_lock>
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	34c080e7          	jalr	844(ra) # 80000c9e <release>
            return -1;
    8000295a:	59fd                	li	s3,-1
}
    8000295c:	854e                	mv	a0,s3
    8000295e:	60a6                	ld	ra,72(sp)
    80002960:	6406                	ld	s0,64(sp)
    80002962:	74e2                	ld	s1,56(sp)
    80002964:	7942                	ld	s2,48(sp)
    80002966:	79a2                	ld	s3,40(sp)
    80002968:	7a02                	ld	s4,32(sp)
    8000296a:	6ae2                	ld	s5,24(sp)
    8000296c:	6b42                	ld	s6,16(sp)
    8000296e:	6ba2                	ld	s7,8(sp)
    80002970:	6c02                	ld	s8,0(sp)
    80002972:	6161                	addi	sp,sp,80
    80002974:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002976:	85e2                	mv	a1,s8
    80002978:	854a                	mv	a0,s2
    8000297a:	00000097          	auipc	ra,0x0
    8000297e:	c02080e7          	jalr	-1022(ra) # 8000257c <sleep>
        havekids = 0;
    80002982:	bf39                	j	800028a0 <wait+0x4a>

0000000080002984 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002984:	7179                	addi	sp,sp,-48
    80002986:	f406                	sd	ra,40(sp)
    80002988:	f022                	sd	s0,32(sp)
    8000298a:	ec26                	sd	s1,24(sp)
    8000298c:	e84a                	sd	s2,16(sp)
    8000298e:	e44e                	sd	s3,8(sp)
    80002990:	e052                	sd	s4,0(sp)
    80002992:	1800                	addi	s0,sp,48
    80002994:	84aa                	mv	s1,a0
    80002996:	892e                	mv	s2,a1
    80002998:	89b2                	mv	s3,a2
    8000299a:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000299c:	fffff097          	auipc	ra,0xfffff
    800029a0:	132080e7          	jalr	306(ra) # 80001ace <myproc>
    if (user_dst)
    800029a4:	c08d                	beqz	s1,800029c6 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    800029a6:	86d2                	mv	a3,s4
    800029a8:	864e                	mv	a2,s3
    800029aa:	85ca                	mv	a1,s2
    800029ac:	6928                	ld	a0,80(a0)
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	cd6080e7          	jalr	-810(ra) # 80001684 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    800029b6:	70a2                	ld	ra,40(sp)
    800029b8:	7402                	ld	s0,32(sp)
    800029ba:	64e2                	ld	s1,24(sp)
    800029bc:	6942                	ld	s2,16(sp)
    800029be:	69a2                	ld	s3,8(sp)
    800029c0:	6a02                	ld	s4,0(sp)
    800029c2:	6145                	addi	sp,sp,48
    800029c4:	8082                	ret
        memmove((char *)dst, src, len);
    800029c6:	000a061b          	sext.w	a2,s4
    800029ca:	85ce                	mv	a1,s3
    800029cc:	854a                	mv	a0,s2
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	378080e7          	jalr	888(ra) # 80000d46 <memmove>
        return 0;
    800029d6:	8526                	mv	a0,s1
    800029d8:	bff9                	j	800029b6 <either_copyout+0x32>

00000000800029da <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800029da:	7179                	addi	sp,sp,-48
    800029dc:	f406                	sd	ra,40(sp)
    800029de:	f022                	sd	s0,32(sp)
    800029e0:	ec26                	sd	s1,24(sp)
    800029e2:	e84a                	sd	s2,16(sp)
    800029e4:	e44e                	sd	s3,8(sp)
    800029e6:	e052                	sd	s4,0(sp)
    800029e8:	1800                	addi	s0,sp,48
    800029ea:	892a                	mv	s2,a0
    800029ec:	84ae                	mv	s1,a1
    800029ee:	89b2                	mv	s3,a2
    800029f0:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800029f2:	fffff097          	auipc	ra,0xfffff
    800029f6:	0dc080e7          	jalr	220(ra) # 80001ace <myproc>
    if (user_src)
    800029fa:	c08d                	beqz	s1,80002a1c <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    800029fc:	86d2                	mv	a3,s4
    800029fe:	864e                	mv	a2,s3
    80002a00:	85ca                	mv	a1,s2
    80002a02:	6928                	ld	a0,80(a0)
    80002a04:	fffff097          	auipc	ra,0xfffff
    80002a08:	d0c080e7          	jalr	-756(ra) # 80001710 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    80002a0c:	70a2                	ld	ra,40(sp)
    80002a0e:	7402                	ld	s0,32(sp)
    80002a10:	64e2                	ld	s1,24(sp)
    80002a12:	6942                	ld	s2,16(sp)
    80002a14:	69a2                	ld	s3,8(sp)
    80002a16:	6a02                	ld	s4,0(sp)
    80002a18:	6145                	addi	sp,sp,48
    80002a1a:	8082                	ret
        memmove(dst, (char *)src, len);
    80002a1c:	000a061b          	sext.w	a2,s4
    80002a20:	85ce                	mv	a1,s3
    80002a22:	854a                	mv	a0,s2
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	322080e7          	jalr	802(ra) # 80000d46 <memmove>
        return 0;
    80002a2c:	8526                	mv	a0,s1
    80002a2e:	bff9                	j	80002a0c <either_copyin+0x32>

0000000080002a30 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002a30:	715d                	addi	sp,sp,-80
    80002a32:	e486                	sd	ra,72(sp)
    80002a34:	e0a2                	sd	s0,64(sp)
    80002a36:	fc26                	sd	s1,56(sp)
    80002a38:	f84a                	sd	s2,48(sp)
    80002a3a:	f44e                	sd	s3,40(sp)
    80002a3c:	f052                	sd	s4,32(sp)
    80002a3e:	ec56                	sd	s5,24(sp)
    80002a40:	e85a                	sd	s6,16(sp)
    80002a42:	e45e                	sd	s7,8(sp)
    80002a44:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    80002a46:	00005517          	auipc	a0,0x5
    80002a4a:	68250513          	addi	a0,a0,1666 # 800080c8 <digits+0x88>
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	b40080e7          	jalr	-1216(ra) # 8000058e <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002a56:	0000f497          	auipc	s1,0xf
    80002a5a:	bf248493          	addi	s1,s1,-1038 # 80011648 <proc+0x158>
    80002a5e:	00014917          	auipc	s2,0x14
    80002a62:	7ea90913          	addi	s2,s2,2026 # 80017248 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a66:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    80002a68:	00006997          	auipc	s3,0x6
    80002a6c:	82898993          	addi	s3,s3,-2008 # 80008290 <digits+0x250>
        printf("%d <%s %s", p->pid, state, p->name);
    80002a70:	00006a97          	auipc	s5,0x6
    80002a74:	828a8a93          	addi	s5,s5,-2008 # 80008298 <digits+0x258>
        printf("\n");
    80002a78:	00005a17          	auipc	s4,0x5
    80002a7c:	650a0a13          	addi	s4,s4,1616 # 800080c8 <digits+0x88>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a80:	00006b97          	auipc	s7,0x6
    80002a84:	928b8b93          	addi	s7,s7,-1752 # 800083a8 <states.1809>
    80002a88:	a00d                	j	80002aaa <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    80002a8a:	ed86a583          	lw	a1,-296(a3)
    80002a8e:	8556                	mv	a0,s5
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	afe080e7          	jalr	-1282(ra) # 8000058e <printf>
        printf("\n");
    80002a98:	8552                	mv	a0,s4
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	af4080e7          	jalr	-1292(ra) # 8000058e <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002aa2:	17048493          	addi	s1,s1,368
    80002aa6:	03248163          	beq	s1,s2,80002ac8 <procdump+0x98>
        if (p->state == UNUSED)
    80002aaa:	86a6                	mv	a3,s1
    80002aac:	ec04a783          	lw	a5,-320(s1)
    80002ab0:	dbed                	beqz	a5,80002aa2 <procdump+0x72>
            state = "???";
    80002ab2:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ab4:	fcfb6be3          	bltu	s6,a5,80002a8a <procdump+0x5a>
    80002ab8:	1782                	slli	a5,a5,0x20
    80002aba:	9381                	srli	a5,a5,0x20
    80002abc:	078e                	slli	a5,a5,0x3
    80002abe:	97de                	add	a5,a5,s7
    80002ac0:	6390                	ld	a2,0(a5)
    80002ac2:	f661                	bnez	a2,80002a8a <procdump+0x5a>
            state = "???";
    80002ac4:	864e                	mv	a2,s3
    80002ac6:	b7d1                	j	80002a8a <procdump+0x5a>
    }
}
    80002ac8:	60a6                	ld	ra,72(sp)
    80002aca:	6406                	ld	s0,64(sp)
    80002acc:	74e2                	ld	s1,56(sp)
    80002ace:	7942                	ld	s2,48(sp)
    80002ad0:	79a2                	ld	s3,40(sp)
    80002ad2:	7a02                	ld	s4,32(sp)
    80002ad4:	6ae2                	ld	s5,24(sp)
    80002ad6:	6b42                	ld	s6,16(sp)
    80002ad8:	6ba2                	ld	s7,8(sp)
    80002ada:	6161                	addi	sp,sp,80
    80002adc:	8082                	ret

0000000080002ade <schedls>:

void schedls()
{
    80002ade:	1101                	addi	sp,sp,-32
    80002ae0:	ec06                	sd	ra,24(sp)
    80002ae2:	e822                	sd	s0,16(sp)
    80002ae4:	e426                	sd	s1,8(sp)
    80002ae6:	1000                	addi	s0,sp,32
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002ae8:	00005517          	auipc	a0,0x5
    80002aec:	7c050513          	addi	a0,a0,1984 # 800082a8 <digits+0x268>
    80002af0:	ffffe097          	auipc	ra,0xffffe
    80002af4:	a9e080e7          	jalr	-1378(ra) # 8000058e <printf>
    printf("====================================\n");
    80002af8:	00005517          	auipc	a0,0x5
    80002afc:	7d850513          	addi	a0,a0,2008 # 800082d0 <digits+0x290>
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	a8e080e7          	jalr	-1394(ra) # 8000058e <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    80002b08:	00006717          	auipc	a4,0x6
    80002b0c:	ea073703          	ld	a4,-352(a4) # 800089a8 <available_schedulers+0x10>
    80002b10:	00006797          	auipc	a5,0x6
    80002b14:	e387b783          	ld	a5,-456(a5) # 80008948 <sched_pointer>
    80002b18:	08f70763          	beq	a4,a5,80002ba6 <schedls+0xc8>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002b1c:	00005517          	auipc	a0,0x5
    80002b20:	7dc50513          	addi	a0,a0,2012 # 800082f8 <digits+0x2b8>
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	a6a080e7          	jalr	-1430(ra) # 8000058e <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002b2c:	00006497          	auipc	s1,0x6
    80002b30:	e3448493          	addi	s1,s1,-460 # 80008960 <initcode>
    80002b34:	48b0                	lw	a2,80(s1)
    80002b36:	00006597          	auipc	a1,0x6
    80002b3a:	e6258593          	addi	a1,a1,-414 # 80008998 <available_schedulers>
    80002b3e:	00005517          	auipc	a0,0x5
    80002b42:	7ca50513          	addi	a0,a0,1994 # 80008308 <digits+0x2c8>
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	a48080e7          	jalr	-1464(ra) # 8000058e <printf>
        if (available_schedulers[i].impl == sched_pointer)
    80002b4e:	74b8                	ld	a4,104(s1)
    80002b50:	00006797          	auipc	a5,0x6
    80002b54:	df87b783          	ld	a5,-520(a5) # 80008948 <sched_pointer>
    80002b58:	06f70063          	beq	a4,a5,80002bb8 <schedls+0xda>
            printf("   \t");
    80002b5c:	00005517          	auipc	a0,0x5
    80002b60:	79c50513          	addi	a0,a0,1948 # 800082f8 <digits+0x2b8>
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	a2a080e7          	jalr	-1494(ra) # 8000058e <printf>
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002b6c:	00006617          	auipc	a2,0x6
    80002b70:	e6462603          	lw	a2,-412(a2) # 800089d0 <available_schedulers+0x38>
    80002b74:	00006597          	auipc	a1,0x6
    80002b78:	e4458593          	addi	a1,a1,-444 # 800089b8 <available_schedulers+0x20>
    80002b7c:	00005517          	auipc	a0,0x5
    80002b80:	78c50513          	addi	a0,a0,1932 # 80008308 <digits+0x2c8>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	a0a080e7          	jalr	-1526(ra) # 8000058e <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002b8c:	00005517          	auipc	a0,0x5
    80002b90:	78450513          	addi	a0,a0,1924 # 80008310 <digits+0x2d0>
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	9fa080e7          	jalr	-1542(ra) # 8000058e <printf>
}
    80002b9c:	60e2                	ld	ra,24(sp)
    80002b9e:	6442                	ld	s0,16(sp)
    80002ba0:	64a2                	ld	s1,8(sp)
    80002ba2:	6105                	addi	sp,sp,32
    80002ba4:	8082                	ret
            printf("[*]\t");
    80002ba6:	00005517          	auipc	a0,0x5
    80002baa:	75a50513          	addi	a0,a0,1882 # 80008300 <digits+0x2c0>
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	9e0080e7          	jalr	-1568(ra) # 8000058e <printf>
    80002bb6:	bf9d                	j	80002b2c <schedls+0x4e>
    80002bb8:	00005517          	auipc	a0,0x5
    80002bbc:	74850513          	addi	a0,a0,1864 # 80008300 <digits+0x2c0>
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	9ce080e7          	jalr	-1586(ra) # 8000058e <printf>
    80002bc8:	b755                	j	80002b6c <schedls+0x8e>

0000000080002bca <schedset>:

void schedset(int id)
{
    80002bca:	1141                	addi	sp,sp,-16
    80002bcc:	e406                	sd	ra,8(sp)
    80002bce:	e022                	sd	s0,0(sp)
    80002bd0:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002bd2:	4705                	li	a4,1
    80002bd4:	02a76f63          	bltu	a4,a0,80002c12 <schedset+0x48>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002bd8:	00551793          	slli	a5,a0,0x5
    80002bdc:	00006717          	auipc	a4,0x6
    80002be0:	d8470713          	addi	a4,a4,-636 # 80008960 <initcode>
    80002be4:	973e                	add	a4,a4,a5
    80002be6:	6738                	ld	a4,72(a4)
    80002be8:	00006697          	auipc	a3,0x6
    80002bec:	d6e6b023          	sd	a4,-672(a3) # 80008948 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002bf0:	00006597          	auipc	a1,0x6
    80002bf4:	da858593          	addi	a1,a1,-600 # 80008998 <available_schedulers>
    80002bf8:	95be                	add	a1,a1,a5
    80002bfa:	00005517          	auipc	a0,0x5
    80002bfe:	75650513          	addi	a0,a0,1878 # 80008350 <digits+0x310>
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	98c080e7          	jalr	-1652(ra) # 8000058e <printf>
    80002c0a:	60a2                	ld	ra,8(sp)
    80002c0c:	6402                	ld	s0,0(sp)
    80002c0e:	0141                	addi	sp,sp,16
    80002c10:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002c12:	00005517          	auipc	a0,0x5
    80002c16:	71650513          	addi	a0,a0,1814 # 80008328 <digits+0x2e8>
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	974080e7          	jalr	-1676(ra) # 8000058e <printf>
        return;
    80002c22:	b7e5                	j	80002c0a <schedset+0x40>

0000000080002c24 <swtch>:
    80002c24:	00153023          	sd	ra,0(a0)
    80002c28:	00253423          	sd	sp,8(a0)
    80002c2c:	e900                	sd	s0,16(a0)
    80002c2e:	ed04                	sd	s1,24(a0)
    80002c30:	03253023          	sd	s2,32(a0)
    80002c34:	03353423          	sd	s3,40(a0)
    80002c38:	03453823          	sd	s4,48(a0)
    80002c3c:	03553c23          	sd	s5,56(a0)
    80002c40:	05653023          	sd	s6,64(a0)
    80002c44:	05753423          	sd	s7,72(a0)
    80002c48:	05853823          	sd	s8,80(a0)
    80002c4c:	05953c23          	sd	s9,88(a0)
    80002c50:	07a53023          	sd	s10,96(a0)
    80002c54:	07b53423          	sd	s11,104(a0)
    80002c58:	0005b083          	ld	ra,0(a1)
    80002c5c:	0085b103          	ld	sp,8(a1)
    80002c60:	6980                	ld	s0,16(a1)
    80002c62:	6d84                	ld	s1,24(a1)
    80002c64:	0205b903          	ld	s2,32(a1)
    80002c68:	0285b983          	ld	s3,40(a1)
    80002c6c:	0305ba03          	ld	s4,48(a1)
    80002c70:	0385ba83          	ld	s5,56(a1)
    80002c74:	0405bb03          	ld	s6,64(a1)
    80002c78:	0485bb83          	ld	s7,72(a1)
    80002c7c:	0505bc03          	ld	s8,80(a1)
    80002c80:	0585bc83          	ld	s9,88(a1)
    80002c84:	0605bd03          	ld	s10,96(a1)
    80002c88:	0685bd83          	ld	s11,104(a1)
    80002c8c:	8082                	ret

0000000080002c8e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c8e:	1141                	addi	sp,sp,-16
    80002c90:	e406                	sd	ra,8(sp)
    80002c92:	e022                	sd	s0,0(sp)
    80002c94:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c96:	00005597          	auipc	a1,0x5
    80002c9a:	74258593          	addi	a1,a1,1858 # 800083d8 <states.1809+0x30>
    80002c9e:	00014517          	auipc	a0,0x14
    80002ca2:	45250513          	addi	a0,a0,1106 # 800170f0 <tickslock>
    80002ca6:	ffffe097          	auipc	ra,0xffffe
    80002caa:	eb4080e7          	jalr	-332(ra) # 80000b5a <initlock>
}
    80002cae:	60a2                	ld	ra,8(sp)
    80002cb0:	6402                	ld	s0,0(sp)
    80002cb2:	0141                	addi	sp,sp,16
    80002cb4:	8082                	ret

0000000080002cb6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002cb6:	1141                	addi	sp,sp,-16
    80002cb8:	e422                	sd	s0,8(sp)
    80002cba:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cbc:	00003797          	auipc	a5,0x3
    80002cc0:	53478793          	addi	a5,a5,1332 # 800061f0 <kernelvec>
    80002cc4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cc8:	6422                	ld	s0,8(sp)
    80002cca:	0141                	addi	sp,sp,16
    80002ccc:	8082                	ret

0000000080002cce <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002cce:	1141                	addi	sp,sp,-16
    80002cd0:	e406                	sd	ra,8(sp)
    80002cd2:	e022                	sd	s0,0(sp)
    80002cd4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	df8080e7          	jalr	-520(ra) # 80001ace <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cde:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ce2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ce4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002ce8:	00004617          	auipc	a2,0x4
    80002cec:	31860613          	addi	a2,a2,792 # 80007000 <_trampoline>
    80002cf0:	00004697          	auipc	a3,0x4
    80002cf4:	31068693          	addi	a3,a3,784 # 80007000 <_trampoline>
    80002cf8:	8e91                	sub	a3,a3,a2
    80002cfa:	040007b7          	lui	a5,0x4000
    80002cfe:	17fd                	addi	a5,a5,-1
    80002d00:	07b2                	slli	a5,a5,0xc
    80002d02:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d04:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d08:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d0a:	180026f3          	csrr	a3,satp
    80002d0e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d10:	6d38                	ld	a4,88(a0)
    80002d12:	6134                	ld	a3,64(a0)
    80002d14:	6585                	lui	a1,0x1
    80002d16:	96ae                	add	a3,a3,a1
    80002d18:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d1a:	6d38                	ld	a4,88(a0)
    80002d1c:	00000697          	auipc	a3,0x0
    80002d20:	13068693          	addi	a3,a3,304 # 80002e4c <usertrap>
    80002d24:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d26:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d28:	8692                	mv	a3,tp
    80002d2a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d2c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d30:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d34:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d38:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d3c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d3e:	6f18                	ld	a4,24(a4)
    80002d40:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d44:	6928                	ld	a0,80(a0)
    80002d46:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002d48:	00004717          	auipc	a4,0x4
    80002d4c:	35470713          	addi	a4,a4,852 # 8000709c <userret>
    80002d50:	8f11                	sub	a4,a4,a2
    80002d52:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002d54:	577d                	li	a4,-1
    80002d56:	177e                	slli	a4,a4,0x3f
    80002d58:	8d59                	or	a0,a0,a4
    80002d5a:	9782                	jalr	a5
}
    80002d5c:	60a2                	ld	ra,8(sp)
    80002d5e:	6402                	ld	s0,0(sp)
    80002d60:	0141                	addi	sp,sp,16
    80002d62:	8082                	ret

0000000080002d64 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d64:	1101                	addi	sp,sp,-32
    80002d66:	ec06                	sd	ra,24(sp)
    80002d68:	e822                	sd	s0,16(sp)
    80002d6a:	e426                	sd	s1,8(sp)
    80002d6c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d6e:	00014497          	auipc	s1,0x14
    80002d72:	38248493          	addi	s1,s1,898 # 800170f0 <tickslock>
    80002d76:	8526                	mv	a0,s1
    80002d78:	ffffe097          	auipc	ra,0xffffe
    80002d7c:	e72080e7          	jalr	-398(ra) # 80000bea <acquire>
  ticks++;
    80002d80:	00006517          	auipc	a0,0x6
    80002d84:	cb850513          	addi	a0,a0,-840 # 80008a38 <ticks>
    80002d88:	411c                	lw	a5,0(a0)
    80002d8a:	2785                	addiw	a5,a5,1
    80002d8c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	852080e7          	jalr	-1966(ra) # 800025e0 <wakeup>
  release(&tickslock);
    80002d96:	8526                	mv	a0,s1
    80002d98:	ffffe097          	auipc	ra,0xffffe
    80002d9c:	f06080e7          	jalr	-250(ra) # 80000c9e <release>
}
    80002da0:	60e2                	ld	ra,24(sp)
    80002da2:	6442                	ld	s0,16(sp)
    80002da4:	64a2                	ld	s1,8(sp)
    80002da6:	6105                	addi	sp,sp,32
    80002da8:	8082                	ret

0000000080002daa <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002daa:	1101                	addi	sp,sp,-32
    80002dac:	ec06                	sd	ra,24(sp)
    80002dae:	e822                	sd	s0,16(sp)
    80002db0:	e426                	sd	s1,8(sp)
    80002db2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002db4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002db8:	00074d63          	bltz	a4,80002dd2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002dbc:	57fd                	li	a5,-1
    80002dbe:	17fe                	slli	a5,a5,0x3f
    80002dc0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002dc2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002dc4:	06f70363          	beq	a4,a5,80002e2a <devintr+0x80>
  }
}
    80002dc8:	60e2                	ld	ra,24(sp)
    80002dca:	6442                	ld	s0,16(sp)
    80002dcc:	64a2                	ld	s1,8(sp)
    80002dce:	6105                	addi	sp,sp,32
    80002dd0:	8082                	ret
     (scause & 0xff) == 9){
    80002dd2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002dd6:	46a5                	li	a3,9
    80002dd8:	fed792e3          	bne	a5,a3,80002dbc <devintr+0x12>
    int irq = plic_claim();
    80002ddc:	00003097          	auipc	ra,0x3
    80002de0:	51c080e7          	jalr	1308(ra) # 800062f8 <plic_claim>
    80002de4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002de6:	47a9                	li	a5,10
    80002de8:	02f50763          	beq	a0,a5,80002e16 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002dec:	4785                	li	a5,1
    80002dee:	02f50963          	beq	a0,a5,80002e20 <devintr+0x76>
    return 1;
    80002df2:	4505                	li	a0,1
    } else if(irq){
    80002df4:	d8f1                	beqz	s1,80002dc8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002df6:	85a6                	mv	a1,s1
    80002df8:	00005517          	auipc	a0,0x5
    80002dfc:	5e850513          	addi	a0,a0,1512 # 800083e0 <states.1809+0x38>
    80002e00:	ffffd097          	auipc	ra,0xffffd
    80002e04:	78e080e7          	jalr	1934(ra) # 8000058e <printf>
      plic_complete(irq);
    80002e08:	8526                	mv	a0,s1
    80002e0a:	00003097          	auipc	ra,0x3
    80002e0e:	512080e7          	jalr	1298(ra) # 8000631c <plic_complete>
    return 1;
    80002e12:	4505                	li	a0,1
    80002e14:	bf55                	j	80002dc8 <devintr+0x1e>
      uartintr();
    80002e16:	ffffe097          	auipc	ra,0xffffe
    80002e1a:	b98080e7          	jalr	-1128(ra) # 800009ae <uartintr>
    80002e1e:	b7ed                	j	80002e08 <devintr+0x5e>
      virtio_disk_intr();
    80002e20:	00004097          	auipc	ra,0x4
    80002e24:	a26080e7          	jalr	-1498(ra) # 80006846 <virtio_disk_intr>
    80002e28:	b7c5                	j	80002e08 <devintr+0x5e>
    if(cpuid() == 0){
    80002e2a:	fffff097          	auipc	ra,0xfffff
    80002e2e:	c78080e7          	jalr	-904(ra) # 80001aa2 <cpuid>
    80002e32:	c901                	beqz	a0,80002e42 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e34:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e38:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e3a:	14479073          	csrw	sip,a5
    return 2;
    80002e3e:	4509                	li	a0,2
    80002e40:	b761                	j	80002dc8 <devintr+0x1e>
      clockintr();
    80002e42:	00000097          	auipc	ra,0x0
    80002e46:	f22080e7          	jalr	-222(ra) # 80002d64 <clockintr>
    80002e4a:	b7ed                	j	80002e34 <devintr+0x8a>

0000000080002e4c <usertrap>:
{
    80002e4c:	1101                	addi	sp,sp,-32
    80002e4e:	ec06                	sd	ra,24(sp)
    80002e50:	e822                	sd	s0,16(sp)
    80002e52:	e426                	sd	s1,8(sp)
    80002e54:	e04a                	sd	s2,0(sp)
    80002e56:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e58:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e5c:	1007f793          	andi	a5,a5,256
    80002e60:	e3b1                	bnez	a5,80002ea4 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e62:	00003797          	auipc	a5,0x3
    80002e66:	38e78793          	addi	a5,a5,910 # 800061f0 <kernelvec>
    80002e6a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	c60080e7          	jalr	-928(ra) # 80001ace <myproc>
    80002e76:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e78:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e7a:	14102773          	csrr	a4,sepc
    80002e7e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e80:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e84:	47a1                	li	a5,8
    80002e86:	02f70763          	beq	a4,a5,80002eb4 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002e8a:	00000097          	auipc	ra,0x0
    80002e8e:	f20080e7          	jalr	-224(ra) # 80002daa <devintr>
    80002e92:	892a                	mv	s2,a0
    80002e94:	c151                	beqz	a0,80002f18 <usertrap+0xcc>
  if(killed(p))
    80002e96:	8526                	mv	a0,s1
    80002e98:	00000097          	auipc	ra,0x0
    80002e9c:	98c080e7          	jalr	-1652(ra) # 80002824 <killed>
    80002ea0:	c929                	beqz	a0,80002ef2 <usertrap+0xa6>
    80002ea2:	a099                	j	80002ee8 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002ea4:	00005517          	auipc	a0,0x5
    80002ea8:	55c50513          	addi	a0,a0,1372 # 80008400 <states.1809+0x58>
    80002eac:	ffffd097          	auipc	ra,0xffffd
    80002eb0:	698080e7          	jalr	1688(ra) # 80000544 <panic>
    if(killed(p))
    80002eb4:	00000097          	auipc	ra,0x0
    80002eb8:	970080e7          	jalr	-1680(ra) # 80002824 <killed>
    80002ebc:	e921                	bnez	a0,80002f0c <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002ebe:	6cb8                	ld	a4,88(s1)
    80002ec0:	6f1c                	ld	a5,24(a4)
    80002ec2:	0791                	addi	a5,a5,4
    80002ec4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ec6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002eca:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ece:	10079073          	csrw	sstatus,a5
    syscall();
    80002ed2:	00000097          	auipc	ra,0x0
    80002ed6:	2d4080e7          	jalr	724(ra) # 800031a6 <syscall>
  if(killed(p))
    80002eda:	8526                	mv	a0,s1
    80002edc:	00000097          	auipc	ra,0x0
    80002ee0:	948080e7          	jalr	-1720(ra) # 80002824 <killed>
    80002ee4:	c911                	beqz	a0,80002ef8 <usertrap+0xac>
    80002ee6:	4901                	li	s2,0
    exit(-1);
    80002ee8:	557d                	li	a0,-1
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	7c6080e7          	jalr	1990(ra) # 800026b0 <exit>
  if(which_dev == 2)
    80002ef2:	4789                	li	a5,2
    80002ef4:	04f90f63          	beq	s2,a5,80002f52 <usertrap+0x106>
  usertrapret();
    80002ef8:	00000097          	auipc	ra,0x0
    80002efc:	dd6080e7          	jalr	-554(ra) # 80002cce <usertrapret>
}
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	64a2                	ld	s1,8(sp)
    80002f06:	6902                	ld	s2,0(sp)
    80002f08:	6105                	addi	sp,sp,32
    80002f0a:	8082                	ret
      exit(-1);
    80002f0c:	557d                	li	a0,-1
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	7a2080e7          	jalr	1954(ra) # 800026b0 <exit>
    80002f16:	b765                	j	80002ebe <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f18:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f1c:	5890                	lw	a2,48(s1)
    80002f1e:	00005517          	auipc	a0,0x5
    80002f22:	50250513          	addi	a0,a0,1282 # 80008420 <states.1809+0x78>
    80002f26:	ffffd097          	auipc	ra,0xffffd
    80002f2a:	668080e7          	jalr	1640(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f2e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f32:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f36:	00005517          	auipc	a0,0x5
    80002f3a:	51a50513          	addi	a0,a0,1306 # 80008450 <states.1809+0xa8>
    80002f3e:	ffffd097          	auipc	ra,0xffffd
    80002f42:	650080e7          	jalr	1616(ra) # 8000058e <printf>
    setkilled(p);
    80002f46:	8526                	mv	a0,s1
    80002f48:	00000097          	auipc	ra,0x0
    80002f4c:	8b0080e7          	jalr	-1872(ra) # 800027f8 <setkilled>
    80002f50:	b769                	j	80002eda <usertrap+0x8e>
    yield();
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	52e080e7          	jalr	1326(ra) # 80002480 <yield>
    80002f5a:	bf79                	j	80002ef8 <usertrap+0xac>

0000000080002f5c <kerneltrap>:
{
    80002f5c:	7179                	addi	sp,sp,-48
    80002f5e:	f406                	sd	ra,40(sp)
    80002f60:	f022                	sd	s0,32(sp)
    80002f62:	ec26                	sd	s1,24(sp)
    80002f64:	e84a                	sd	s2,16(sp)
    80002f66:	e44e                	sd	s3,8(sp)
    80002f68:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f6a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f6e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f72:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f76:	1004f793          	andi	a5,s1,256
    80002f7a:	cb85                	beqz	a5,80002faa <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f7c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f80:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f82:	ef85                	bnez	a5,80002fba <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f84:	00000097          	auipc	ra,0x0
    80002f88:	e26080e7          	jalr	-474(ra) # 80002daa <devintr>
    80002f8c:	cd1d                	beqz	a0,80002fca <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f8e:	4789                	li	a5,2
    80002f90:	06f50a63          	beq	a0,a5,80003004 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f94:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f98:	10049073          	csrw	sstatus,s1
}
    80002f9c:	70a2                	ld	ra,40(sp)
    80002f9e:	7402                	ld	s0,32(sp)
    80002fa0:	64e2                	ld	s1,24(sp)
    80002fa2:	6942                	ld	s2,16(sp)
    80002fa4:	69a2                	ld	s3,8(sp)
    80002fa6:	6145                	addi	sp,sp,48
    80002fa8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002faa:	00005517          	auipc	a0,0x5
    80002fae:	4c650513          	addi	a0,a0,1222 # 80008470 <states.1809+0xc8>
    80002fb2:	ffffd097          	auipc	ra,0xffffd
    80002fb6:	592080e7          	jalr	1426(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002fba:	00005517          	auipc	a0,0x5
    80002fbe:	4de50513          	addi	a0,a0,1246 # 80008498 <states.1809+0xf0>
    80002fc2:	ffffd097          	auipc	ra,0xffffd
    80002fc6:	582080e7          	jalr	1410(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002fca:	85ce                	mv	a1,s3
    80002fcc:	00005517          	auipc	a0,0x5
    80002fd0:	4ec50513          	addi	a0,a0,1260 # 800084b8 <states.1809+0x110>
    80002fd4:	ffffd097          	auipc	ra,0xffffd
    80002fd8:	5ba080e7          	jalr	1466(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fdc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fe0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fe4:	00005517          	auipc	a0,0x5
    80002fe8:	4e450513          	addi	a0,a0,1252 # 800084c8 <states.1809+0x120>
    80002fec:	ffffd097          	auipc	ra,0xffffd
    80002ff0:	5a2080e7          	jalr	1442(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002ff4:	00005517          	auipc	a0,0x5
    80002ff8:	4ec50513          	addi	a0,a0,1260 # 800084e0 <states.1809+0x138>
    80002ffc:	ffffd097          	auipc	ra,0xffffd
    80003000:	548080e7          	jalr	1352(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003004:	fffff097          	auipc	ra,0xfffff
    80003008:	aca080e7          	jalr	-1334(ra) # 80001ace <myproc>
    8000300c:	d541                	beqz	a0,80002f94 <kerneltrap+0x38>
    8000300e:	fffff097          	auipc	ra,0xfffff
    80003012:	ac0080e7          	jalr	-1344(ra) # 80001ace <myproc>
    80003016:	4d18                	lw	a4,24(a0)
    80003018:	4791                	li	a5,4
    8000301a:	f6f71de3          	bne	a4,a5,80002f94 <kerneltrap+0x38>
    yield();
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	462080e7          	jalr	1122(ra) # 80002480 <yield>
    80003026:	b7bd                	j	80002f94 <kerneltrap+0x38>

0000000080003028 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80003028:	1101                	addi	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	e426                	sd	s1,8(sp)
    80003030:	1000                	addi	s0,sp,32
    80003032:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80003034:	fffff097          	auipc	ra,0xfffff
    80003038:	a9a080e7          	jalr	-1382(ra) # 80001ace <myproc>
    switch (n)
    8000303c:	4795                	li	a5,5
    8000303e:	0497e163          	bltu	a5,s1,80003080 <argraw+0x58>
    80003042:	048a                	slli	s1,s1,0x2
    80003044:	00005717          	auipc	a4,0x5
    80003048:	4d470713          	addi	a4,a4,1236 # 80008518 <states.1809+0x170>
    8000304c:	94ba                	add	s1,s1,a4
    8000304e:	409c                	lw	a5,0(s1)
    80003050:	97ba                	add	a5,a5,a4
    80003052:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80003054:	6d3c                	ld	a5,88(a0)
    80003056:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80003058:	60e2                	ld	ra,24(sp)
    8000305a:	6442                	ld	s0,16(sp)
    8000305c:	64a2                	ld	s1,8(sp)
    8000305e:	6105                	addi	sp,sp,32
    80003060:	8082                	ret
        return p->trapframe->a1;
    80003062:	6d3c                	ld	a5,88(a0)
    80003064:	7fa8                	ld	a0,120(a5)
    80003066:	bfcd                	j	80003058 <argraw+0x30>
        return p->trapframe->a2;
    80003068:	6d3c                	ld	a5,88(a0)
    8000306a:	63c8                	ld	a0,128(a5)
    8000306c:	b7f5                	j	80003058 <argraw+0x30>
        return p->trapframe->a3;
    8000306e:	6d3c                	ld	a5,88(a0)
    80003070:	67c8                	ld	a0,136(a5)
    80003072:	b7dd                	j	80003058 <argraw+0x30>
        return p->trapframe->a4;
    80003074:	6d3c                	ld	a5,88(a0)
    80003076:	6bc8                	ld	a0,144(a5)
    80003078:	b7c5                	j	80003058 <argraw+0x30>
        return p->trapframe->a5;
    8000307a:	6d3c                	ld	a5,88(a0)
    8000307c:	6fc8                	ld	a0,152(a5)
    8000307e:	bfe9                	j	80003058 <argraw+0x30>
    panic("argraw");
    80003080:	00005517          	auipc	a0,0x5
    80003084:	47050513          	addi	a0,a0,1136 # 800084f0 <states.1809+0x148>
    80003088:	ffffd097          	auipc	ra,0xffffd
    8000308c:	4bc080e7          	jalr	1212(ra) # 80000544 <panic>

0000000080003090 <fetchaddr>:
{
    80003090:	1101                	addi	sp,sp,-32
    80003092:	ec06                	sd	ra,24(sp)
    80003094:	e822                	sd	s0,16(sp)
    80003096:	e426                	sd	s1,8(sp)
    80003098:	e04a                	sd	s2,0(sp)
    8000309a:	1000                	addi	s0,sp,32
    8000309c:	84aa                	mv	s1,a0
    8000309e:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800030a0:	fffff097          	auipc	ra,0xfffff
    800030a4:	a2e080e7          	jalr	-1490(ra) # 80001ace <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800030a8:	653c                	ld	a5,72(a0)
    800030aa:	02f4f863          	bgeu	s1,a5,800030da <fetchaddr+0x4a>
    800030ae:	00848713          	addi	a4,s1,8
    800030b2:	02e7e663          	bltu	a5,a4,800030de <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030b6:	46a1                	li	a3,8
    800030b8:	8626                	mv	a2,s1
    800030ba:	85ca                	mv	a1,s2
    800030bc:	6928                	ld	a0,80(a0)
    800030be:	ffffe097          	auipc	ra,0xffffe
    800030c2:	652080e7          	jalr	1618(ra) # 80001710 <copyin>
    800030c6:	00a03533          	snez	a0,a0
    800030ca:	40a00533          	neg	a0,a0
}
    800030ce:	60e2                	ld	ra,24(sp)
    800030d0:	6442                	ld	s0,16(sp)
    800030d2:	64a2                	ld	s1,8(sp)
    800030d4:	6902                	ld	s2,0(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret
        return -1;
    800030da:	557d                	li	a0,-1
    800030dc:	bfcd                	j	800030ce <fetchaddr+0x3e>
    800030de:	557d                	li	a0,-1
    800030e0:	b7fd                	j	800030ce <fetchaddr+0x3e>

00000000800030e2 <fetchstr>:
{
    800030e2:	7179                	addi	sp,sp,-48
    800030e4:	f406                	sd	ra,40(sp)
    800030e6:	f022                	sd	s0,32(sp)
    800030e8:	ec26                	sd	s1,24(sp)
    800030ea:	e84a                	sd	s2,16(sp)
    800030ec:	e44e                	sd	s3,8(sp)
    800030ee:	1800                	addi	s0,sp,48
    800030f0:	892a                	mv	s2,a0
    800030f2:	84ae                	mv	s1,a1
    800030f4:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	9d8080e7          	jalr	-1576(ra) # 80001ace <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    800030fe:	86ce                	mv	a3,s3
    80003100:	864a                	mv	a2,s2
    80003102:	85a6                	mv	a1,s1
    80003104:	6928                	ld	a0,80(a0)
    80003106:	ffffe097          	auipc	ra,0xffffe
    8000310a:	696080e7          	jalr	1686(ra) # 8000179c <copyinstr>
    8000310e:	00054e63          	bltz	a0,8000312a <fetchstr+0x48>
    return strlen(buf);
    80003112:	8526                	mv	a0,s1
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	d56080e7          	jalr	-682(ra) # 80000e6a <strlen>
}
    8000311c:	70a2                	ld	ra,40(sp)
    8000311e:	7402                	ld	s0,32(sp)
    80003120:	64e2                	ld	s1,24(sp)
    80003122:	6942                	ld	s2,16(sp)
    80003124:	69a2                	ld	s3,8(sp)
    80003126:	6145                	addi	sp,sp,48
    80003128:	8082                	ret
        return -1;
    8000312a:	557d                	li	a0,-1
    8000312c:	bfc5                	j	8000311c <fetchstr+0x3a>

000000008000312e <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    8000312e:	1101                	addi	sp,sp,-32
    80003130:	ec06                	sd	ra,24(sp)
    80003132:	e822                	sd	s0,16(sp)
    80003134:	e426                	sd	s1,8(sp)
    80003136:	1000                	addi	s0,sp,32
    80003138:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000313a:	00000097          	auipc	ra,0x0
    8000313e:	eee080e7          	jalr	-274(ra) # 80003028 <argraw>
    80003142:	c088                	sw	a0,0(s1)
}
    80003144:	60e2                	ld	ra,24(sp)
    80003146:	6442                	ld	s0,16(sp)
    80003148:	64a2                	ld	s1,8(sp)
    8000314a:	6105                	addi	sp,sp,32
    8000314c:	8082                	ret

000000008000314e <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    8000314e:	1101                	addi	sp,sp,-32
    80003150:	ec06                	sd	ra,24(sp)
    80003152:	e822                	sd	s0,16(sp)
    80003154:	e426                	sd	s1,8(sp)
    80003156:	1000                	addi	s0,sp,32
    80003158:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000315a:	00000097          	auipc	ra,0x0
    8000315e:	ece080e7          	jalr	-306(ra) # 80003028 <argraw>
    80003162:	e088                	sd	a0,0(s1)
}
    80003164:	60e2                	ld	ra,24(sp)
    80003166:	6442                	ld	s0,16(sp)
    80003168:	64a2                	ld	s1,8(sp)
    8000316a:	6105                	addi	sp,sp,32
    8000316c:	8082                	ret

000000008000316e <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    8000316e:	7179                	addi	sp,sp,-48
    80003170:	f406                	sd	ra,40(sp)
    80003172:	f022                	sd	s0,32(sp)
    80003174:	ec26                	sd	s1,24(sp)
    80003176:	e84a                	sd	s2,16(sp)
    80003178:	1800                	addi	s0,sp,48
    8000317a:	84ae                	mv	s1,a1
    8000317c:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    8000317e:	fd840593          	addi	a1,s0,-40
    80003182:	00000097          	auipc	ra,0x0
    80003186:	fcc080e7          	jalr	-52(ra) # 8000314e <argaddr>
    return fetchstr(addr, buf, max);
    8000318a:	864a                	mv	a2,s2
    8000318c:	85a6                	mv	a1,s1
    8000318e:	fd843503          	ld	a0,-40(s0)
    80003192:	00000097          	auipc	ra,0x0
    80003196:	f50080e7          	jalr	-176(ra) # 800030e2 <fetchstr>
}
    8000319a:	70a2                	ld	ra,40(sp)
    8000319c:	7402                	ld	s0,32(sp)
    8000319e:	64e2                	ld	s1,24(sp)
    800031a0:	6942                	ld	s2,16(sp)
    800031a2:	6145                	addi	sp,sp,48
    800031a4:	8082                	ret

00000000800031a6 <syscall>:
    [SYS_schedls] sys_schedls,
    [SYS_schedset] sys_schedset,
};

void syscall(void)
{
    800031a6:	1101                	addi	sp,sp,-32
    800031a8:	ec06                	sd	ra,24(sp)
    800031aa:	e822                	sd	s0,16(sp)
    800031ac:	e426                	sd	s1,8(sp)
    800031ae:	e04a                	sd	s2,0(sp)
    800031b0:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    800031b2:	fffff097          	auipc	ra,0xfffff
    800031b6:	91c080e7          	jalr	-1764(ra) # 80001ace <myproc>
    800031ba:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    800031bc:	05853903          	ld	s2,88(a0)
    800031c0:	0a893783          	ld	a5,168(s2)
    800031c4:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800031c8:	37fd                	addiw	a5,a5,-1
    800031ca:	475d                	li	a4,23
    800031cc:	00f76f63          	bltu	a4,a5,800031ea <syscall+0x44>
    800031d0:	00369713          	slli	a4,a3,0x3
    800031d4:	00005797          	auipc	a5,0x5
    800031d8:	35c78793          	addi	a5,a5,860 # 80008530 <syscalls>
    800031dc:	97ba                	add	a5,a5,a4
    800031de:	639c                	ld	a5,0(a5)
    800031e0:	c789                	beqz	a5,800031ea <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    800031e2:	9782                	jalr	a5
    800031e4:	06a93823          	sd	a0,112(s2)
    800031e8:	a839                	j	80003206 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    800031ea:	15848613          	addi	a2,s1,344
    800031ee:	588c                	lw	a1,48(s1)
    800031f0:	00005517          	auipc	a0,0x5
    800031f4:	30850513          	addi	a0,a0,776 # 800084f8 <states.1809+0x150>
    800031f8:	ffffd097          	auipc	ra,0xffffd
    800031fc:	396080e7          	jalr	918(ra) # 8000058e <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    80003200:	6cbc                	ld	a5,88(s1)
    80003202:	577d                	li	a4,-1
    80003204:	fbb8                	sd	a4,112(a5)
    }
}
    80003206:	60e2                	ld	ra,24(sp)
    80003208:	6442                	ld	s0,16(sp)
    8000320a:	64a2                	ld	s1,8(sp)
    8000320c:	6902                	ld	s2,0(sp)
    8000320e:	6105                	addi	sp,sp,32
    80003210:	8082                	ret

0000000080003212 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003212:	1101                	addi	sp,sp,-32
    80003214:	ec06                	sd	ra,24(sp)
    80003216:	e822                	sd	s0,16(sp)
    80003218:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    8000321a:	fec40593          	addi	a1,s0,-20
    8000321e:	4501                	li	a0,0
    80003220:	00000097          	auipc	ra,0x0
    80003224:	f0e080e7          	jalr	-242(ra) # 8000312e <argint>
    exit(n);
    80003228:	fec42503          	lw	a0,-20(s0)
    8000322c:	fffff097          	auipc	ra,0xfffff
    80003230:	484080e7          	jalr	1156(ra) # 800026b0 <exit>
    return 0; // not reached
}
    80003234:	4501                	li	a0,0
    80003236:	60e2                	ld	ra,24(sp)
    80003238:	6442                	ld	s0,16(sp)
    8000323a:	6105                	addi	sp,sp,32
    8000323c:	8082                	ret

000000008000323e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000323e:	1141                	addi	sp,sp,-16
    80003240:	e406                	sd	ra,8(sp)
    80003242:	e022                	sd	s0,0(sp)
    80003244:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80003246:	fffff097          	auipc	ra,0xfffff
    8000324a:	888080e7          	jalr	-1912(ra) # 80001ace <myproc>
}
    8000324e:	5908                	lw	a0,48(a0)
    80003250:	60a2                	ld	ra,8(sp)
    80003252:	6402                	ld	s0,0(sp)
    80003254:	0141                	addi	sp,sp,16
    80003256:	8082                	ret

0000000080003258 <sys_fork>:

uint64
sys_fork(void)
{
    80003258:	1141                	addi	sp,sp,-16
    8000325a:	e406                	sd	ra,8(sp)
    8000325c:	e022                	sd	s0,0(sp)
    8000325e:	0800                	addi	s0,sp,16
    return fork();
    80003260:	fffff097          	auipc	ra,0xfffff
    80003264:	dc4080e7          	jalr	-572(ra) # 80002024 <fork>
}
    80003268:	60a2                	ld	ra,8(sp)
    8000326a:	6402                	ld	s0,0(sp)
    8000326c:	0141                	addi	sp,sp,16
    8000326e:	8082                	ret

0000000080003270 <sys_wait>:

uint64
sys_wait(void)
{
    80003270:	1101                	addi	sp,sp,-32
    80003272:	ec06                	sd	ra,24(sp)
    80003274:	e822                	sd	s0,16(sp)
    80003276:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80003278:	fe840593          	addi	a1,s0,-24
    8000327c:	4501                	li	a0,0
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	ed0080e7          	jalr	-304(ra) # 8000314e <argaddr>
    return wait(p);
    80003286:	fe843503          	ld	a0,-24(s0)
    8000328a:	fffff097          	auipc	ra,0xfffff
    8000328e:	5cc080e7          	jalr	1484(ra) # 80002856 <wait>
}
    80003292:	60e2                	ld	ra,24(sp)
    80003294:	6442                	ld	s0,16(sp)
    80003296:	6105                	addi	sp,sp,32
    80003298:	8082                	ret

000000008000329a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000329a:	7179                	addi	sp,sp,-48
    8000329c:	f406                	sd	ra,40(sp)
    8000329e:	f022                	sd	s0,32(sp)
    800032a0:	ec26                	sd	s1,24(sp)
    800032a2:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    800032a4:	fdc40593          	addi	a1,s0,-36
    800032a8:	4501                	li	a0,0
    800032aa:	00000097          	auipc	ra,0x0
    800032ae:	e84080e7          	jalr	-380(ra) # 8000312e <argint>
    addr = myproc()->sz;
    800032b2:	fffff097          	auipc	ra,0xfffff
    800032b6:	81c080e7          	jalr	-2020(ra) # 80001ace <myproc>
    800032ba:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    800032bc:	fdc42503          	lw	a0,-36(s0)
    800032c0:	fffff097          	auipc	ra,0xfffff
    800032c4:	bb8080e7          	jalr	-1096(ra) # 80001e78 <growproc>
    800032c8:	00054863          	bltz	a0,800032d8 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    800032cc:	8526                	mv	a0,s1
    800032ce:	70a2                	ld	ra,40(sp)
    800032d0:	7402                	ld	s0,32(sp)
    800032d2:	64e2                	ld	s1,24(sp)
    800032d4:	6145                	addi	sp,sp,48
    800032d6:	8082                	ret
        return -1;
    800032d8:	54fd                	li	s1,-1
    800032da:	bfcd                	j	800032cc <sys_sbrk+0x32>

00000000800032dc <sys_sleep>:

uint64
sys_sleep(void)
{
    800032dc:	7139                	addi	sp,sp,-64
    800032de:	fc06                	sd	ra,56(sp)
    800032e0:	f822                	sd	s0,48(sp)
    800032e2:	f426                	sd	s1,40(sp)
    800032e4:	f04a                	sd	s2,32(sp)
    800032e6:	ec4e                	sd	s3,24(sp)
    800032e8:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800032ea:	fcc40593          	addi	a1,s0,-52
    800032ee:	4501                	li	a0,0
    800032f0:	00000097          	auipc	ra,0x0
    800032f4:	e3e080e7          	jalr	-450(ra) # 8000312e <argint>
    acquire(&tickslock);
    800032f8:	00014517          	auipc	a0,0x14
    800032fc:	df850513          	addi	a0,a0,-520 # 800170f0 <tickslock>
    80003300:	ffffe097          	auipc	ra,0xffffe
    80003304:	8ea080e7          	jalr	-1814(ra) # 80000bea <acquire>
    ticks0 = ticks;
    80003308:	00005917          	auipc	s2,0x5
    8000330c:	73092903          	lw	s2,1840(s2) # 80008a38 <ticks>
    while (ticks - ticks0 < n)
    80003310:	fcc42783          	lw	a5,-52(s0)
    80003314:	cf9d                	beqz	a5,80003352 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80003316:	00014997          	auipc	s3,0x14
    8000331a:	dda98993          	addi	s3,s3,-550 # 800170f0 <tickslock>
    8000331e:	00005497          	auipc	s1,0x5
    80003322:	71a48493          	addi	s1,s1,1818 # 80008a38 <ticks>
        if (killed(myproc()))
    80003326:	ffffe097          	auipc	ra,0xffffe
    8000332a:	7a8080e7          	jalr	1960(ra) # 80001ace <myproc>
    8000332e:	fffff097          	auipc	ra,0xfffff
    80003332:	4f6080e7          	jalr	1270(ra) # 80002824 <killed>
    80003336:	ed15                	bnez	a0,80003372 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    80003338:	85ce                	mv	a1,s3
    8000333a:	8526                	mv	a0,s1
    8000333c:	fffff097          	auipc	ra,0xfffff
    80003340:	240080e7          	jalr	576(ra) # 8000257c <sleep>
    while (ticks - ticks0 < n)
    80003344:	409c                	lw	a5,0(s1)
    80003346:	412787bb          	subw	a5,a5,s2
    8000334a:	fcc42703          	lw	a4,-52(s0)
    8000334e:	fce7ece3          	bltu	a5,a4,80003326 <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003352:	00014517          	auipc	a0,0x14
    80003356:	d9e50513          	addi	a0,a0,-610 # 800170f0 <tickslock>
    8000335a:	ffffe097          	auipc	ra,0xffffe
    8000335e:	944080e7          	jalr	-1724(ra) # 80000c9e <release>
    return 0;
    80003362:	4501                	li	a0,0
}
    80003364:	70e2                	ld	ra,56(sp)
    80003366:	7442                	ld	s0,48(sp)
    80003368:	74a2                	ld	s1,40(sp)
    8000336a:	7902                	ld	s2,32(sp)
    8000336c:	69e2                	ld	s3,24(sp)
    8000336e:	6121                	addi	sp,sp,64
    80003370:	8082                	ret
            release(&tickslock);
    80003372:	00014517          	auipc	a0,0x14
    80003376:	d7e50513          	addi	a0,a0,-642 # 800170f0 <tickslock>
    8000337a:	ffffe097          	auipc	ra,0xffffe
    8000337e:	924080e7          	jalr	-1756(ra) # 80000c9e <release>
            return -1;
    80003382:	557d                	li	a0,-1
    80003384:	b7c5                	j	80003364 <sys_sleep+0x88>

0000000080003386 <sys_kill>:

uint64
sys_kill(void)
{
    80003386:	1101                	addi	sp,sp,-32
    80003388:	ec06                	sd	ra,24(sp)
    8000338a:	e822                	sd	s0,16(sp)
    8000338c:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    8000338e:	fec40593          	addi	a1,s0,-20
    80003392:	4501                	li	a0,0
    80003394:	00000097          	auipc	ra,0x0
    80003398:	d9a080e7          	jalr	-614(ra) # 8000312e <argint>
    return kill(pid);
    8000339c:	fec42503          	lw	a0,-20(s0)
    800033a0:	fffff097          	auipc	ra,0xfffff
    800033a4:	3e6080e7          	jalr	998(ra) # 80002786 <kill>
}
    800033a8:	60e2                	ld	ra,24(sp)
    800033aa:	6442                	ld	s0,16(sp)
    800033ac:	6105                	addi	sp,sp,32
    800033ae:	8082                	ret

00000000800033b0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033b0:	1101                	addi	sp,sp,-32
    800033b2:	ec06                	sd	ra,24(sp)
    800033b4:	e822                	sd	s0,16(sp)
    800033b6:	e426                	sd	s1,8(sp)
    800033b8:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800033ba:	00014517          	auipc	a0,0x14
    800033be:	d3650513          	addi	a0,a0,-714 # 800170f0 <tickslock>
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	828080e7          	jalr	-2008(ra) # 80000bea <acquire>
    xticks = ticks;
    800033ca:	00005497          	auipc	s1,0x5
    800033ce:	66e4a483          	lw	s1,1646(s1) # 80008a38 <ticks>
    release(&tickslock);
    800033d2:	00014517          	auipc	a0,0x14
    800033d6:	d1e50513          	addi	a0,a0,-738 # 800170f0 <tickslock>
    800033da:	ffffe097          	auipc	ra,0xffffe
    800033de:	8c4080e7          	jalr	-1852(ra) # 80000c9e <release>
    return xticks;
}
    800033e2:	02049513          	slli	a0,s1,0x20
    800033e6:	9101                	srli	a0,a0,0x20
    800033e8:	60e2                	ld	ra,24(sp)
    800033ea:	6442                	ld	s0,16(sp)
    800033ec:	64a2                	ld	s1,8(sp)
    800033ee:	6105                	addi	sp,sp,32
    800033f0:	8082                	ret

00000000800033f2 <sys_ps>:

void *
sys_ps(void)
{
    800033f2:	1101                	addi	sp,sp,-32
    800033f4:	ec06                	sd	ra,24(sp)
    800033f6:	e822                	sd	s0,16(sp)
    800033f8:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800033fa:	fe042623          	sw	zero,-20(s0)
    800033fe:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    80003402:	fec40593          	addi	a1,s0,-20
    80003406:	4501                	li	a0,0
    80003408:	00000097          	auipc	ra,0x0
    8000340c:	d26080e7          	jalr	-730(ra) # 8000312e <argint>
    argint(1, &count);
    80003410:	fe840593          	addi	a1,s0,-24
    80003414:	4505                	li	a0,1
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	d18080e7          	jalr	-744(ra) # 8000312e <argint>
    return ps((uint8)start, (uint8)count);
    8000341e:	fe844583          	lbu	a1,-24(s0)
    80003422:	fec44503          	lbu	a0,-20(s0)
    80003426:	fffff097          	auipc	ra,0xfffff
    8000342a:	aae080e7          	jalr	-1362(ra) # 80001ed4 <ps>
}
    8000342e:	60e2                	ld	ra,24(sp)
    80003430:	6442                	ld	s0,16(sp)
    80003432:	6105                	addi	sp,sp,32
    80003434:	8082                	ret

0000000080003436 <sys_schedls>:

uint64 sys_schedls(void)
{
    80003436:	1141                	addi	sp,sp,-16
    80003438:	e406                	sd	ra,8(sp)
    8000343a:	e022                	sd	s0,0(sp)
    8000343c:	0800                	addi	s0,sp,16
    schedls();
    8000343e:	fffff097          	auipc	ra,0xfffff
    80003442:	6a0080e7          	jalr	1696(ra) # 80002ade <schedls>
    return 0;
}
    80003446:	4501                	li	a0,0
    80003448:	60a2                	ld	ra,8(sp)
    8000344a:	6402                	ld	s0,0(sp)
    8000344c:	0141                	addi	sp,sp,16
    8000344e:	8082                	ret

0000000080003450 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003450:	1101                	addi	sp,sp,-32
    80003452:	ec06                	sd	ra,24(sp)
    80003454:	e822                	sd	s0,16(sp)
    80003456:	1000                	addi	s0,sp,32
    int id = 0;
    80003458:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    8000345c:	fec40593          	addi	a1,s0,-20
    80003460:	4501                	li	a0,0
    80003462:	00000097          	auipc	ra,0x0
    80003466:	ccc080e7          	jalr	-820(ra) # 8000312e <argint>
    schedset(id - 1);
    8000346a:	fec42503          	lw	a0,-20(s0)
    8000346e:	357d                	addiw	a0,a0,-1
    80003470:	fffff097          	auipc	ra,0xfffff
    80003474:	75a080e7          	jalr	1882(ra) # 80002bca <schedset>
    return 0;
    80003478:	4501                	li	a0,0
    8000347a:	60e2                	ld	ra,24(sp)
    8000347c:	6442                	ld	s0,16(sp)
    8000347e:	6105                	addi	sp,sp,32
    80003480:	8082                	ret

0000000080003482 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003482:	7179                	addi	sp,sp,-48
    80003484:	f406                	sd	ra,40(sp)
    80003486:	f022                	sd	s0,32(sp)
    80003488:	ec26                	sd	s1,24(sp)
    8000348a:	e84a                	sd	s2,16(sp)
    8000348c:	e44e                	sd	s3,8(sp)
    8000348e:	e052                	sd	s4,0(sp)
    80003490:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003492:	00005597          	auipc	a1,0x5
    80003496:	16658593          	addi	a1,a1,358 # 800085f8 <syscalls+0xc8>
    8000349a:	00014517          	auipc	a0,0x14
    8000349e:	c6e50513          	addi	a0,a0,-914 # 80017108 <bcache>
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	6b8080e7          	jalr	1720(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034aa:	0001c797          	auipc	a5,0x1c
    800034ae:	c5e78793          	addi	a5,a5,-930 # 8001f108 <bcache+0x8000>
    800034b2:	0001c717          	auipc	a4,0x1c
    800034b6:	ebe70713          	addi	a4,a4,-322 # 8001f370 <bcache+0x8268>
    800034ba:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034be:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034c2:	00014497          	auipc	s1,0x14
    800034c6:	c5e48493          	addi	s1,s1,-930 # 80017120 <bcache+0x18>
    b->next = bcache.head.next;
    800034ca:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034cc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034ce:	00005a17          	auipc	s4,0x5
    800034d2:	132a0a13          	addi	s4,s4,306 # 80008600 <syscalls+0xd0>
    b->next = bcache.head.next;
    800034d6:	2b893783          	ld	a5,696(s2)
    800034da:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034dc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034e0:	85d2                	mv	a1,s4
    800034e2:	01048513          	addi	a0,s1,16
    800034e6:	00001097          	auipc	ra,0x1
    800034ea:	4c4080e7          	jalr	1220(ra) # 800049aa <initsleeplock>
    bcache.head.next->prev = b;
    800034ee:	2b893783          	ld	a5,696(s2)
    800034f2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034f4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034f8:	45848493          	addi	s1,s1,1112
    800034fc:	fd349de3          	bne	s1,s3,800034d6 <binit+0x54>
  }
}
    80003500:	70a2                	ld	ra,40(sp)
    80003502:	7402                	ld	s0,32(sp)
    80003504:	64e2                	ld	s1,24(sp)
    80003506:	6942                	ld	s2,16(sp)
    80003508:	69a2                	ld	s3,8(sp)
    8000350a:	6a02                	ld	s4,0(sp)
    8000350c:	6145                	addi	sp,sp,48
    8000350e:	8082                	ret

0000000080003510 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003510:	7179                	addi	sp,sp,-48
    80003512:	f406                	sd	ra,40(sp)
    80003514:	f022                	sd	s0,32(sp)
    80003516:	ec26                	sd	s1,24(sp)
    80003518:	e84a                	sd	s2,16(sp)
    8000351a:	e44e                	sd	s3,8(sp)
    8000351c:	1800                	addi	s0,sp,48
    8000351e:	89aa                	mv	s3,a0
    80003520:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003522:	00014517          	auipc	a0,0x14
    80003526:	be650513          	addi	a0,a0,-1050 # 80017108 <bcache>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	6c0080e7          	jalr	1728(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003532:	0001c497          	auipc	s1,0x1c
    80003536:	e8e4b483          	ld	s1,-370(s1) # 8001f3c0 <bcache+0x82b8>
    8000353a:	0001c797          	auipc	a5,0x1c
    8000353e:	e3678793          	addi	a5,a5,-458 # 8001f370 <bcache+0x8268>
    80003542:	02f48f63          	beq	s1,a5,80003580 <bread+0x70>
    80003546:	873e                	mv	a4,a5
    80003548:	a021                	j	80003550 <bread+0x40>
    8000354a:	68a4                	ld	s1,80(s1)
    8000354c:	02e48a63          	beq	s1,a4,80003580 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003550:	449c                	lw	a5,8(s1)
    80003552:	ff379ce3          	bne	a5,s3,8000354a <bread+0x3a>
    80003556:	44dc                	lw	a5,12(s1)
    80003558:	ff2799e3          	bne	a5,s2,8000354a <bread+0x3a>
      b->refcnt++;
    8000355c:	40bc                	lw	a5,64(s1)
    8000355e:	2785                	addiw	a5,a5,1
    80003560:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003562:	00014517          	auipc	a0,0x14
    80003566:	ba650513          	addi	a0,a0,-1114 # 80017108 <bcache>
    8000356a:	ffffd097          	auipc	ra,0xffffd
    8000356e:	734080e7          	jalr	1844(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003572:	01048513          	addi	a0,s1,16
    80003576:	00001097          	auipc	ra,0x1
    8000357a:	46e080e7          	jalr	1134(ra) # 800049e4 <acquiresleep>
      return b;
    8000357e:	a8b9                	j	800035dc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003580:	0001c497          	auipc	s1,0x1c
    80003584:	e384b483          	ld	s1,-456(s1) # 8001f3b8 <bcache+0x82b0>
    80003588:	0001c797          	auipc	a5,0x1c
    8000358c:	de878793          	addi	a5,a5,-536 # 8001f370 <bcache+0x8268>
    80003590:	00f48863          	beq	s1,a5,800035a0 <bread+0x90>
    80003594:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003596:	40bc                	lw	a5,64(s1)
    80003598:	cf81                	beqz	a5,800035b0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000359a:	64a4                	ld	s1,72(s1)
    8000359c:	fee49de3          	bne	s1,a4,80003596 <bread+0x86>
  panic("bget: no buffers");
    800035a0:	00005517          	auipc	a0,0x5
    800035a4:	06850513          	addi	a0,a0,104 # 80008608 <syscalls+0xd8>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	f9c080e7          	jalr	-100(ra) # 80000544 <panic>
      b->dev = dev;
    800035b0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800035b4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800035b8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035bc:	4785                	li	a5,1
    800035be:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035c0:	00014517          	auipc	a0,0x14
    800035c4:	b4850513          	addi	a0,a0,-1208 # 80017108 <bcache>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	6d6080e7          	jalr	1750(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800035d0:	01048513          	addi	a0,s1,16
    800035d4:	00001097          	auipc	ra,0x1
    800035d8:	410080e7          	jalr	1040(ra) # 800049e4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035dc:	409c                	lw	a5,0(s1)
    800035de:	cb89                	beqz	a5,800035f0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035e0:	8526                	mv	a0,s1
    800035e2:	70a2                	ld	ra,40(sp)
    800035e4:	7402                	ld	s0,32(sp)
    800035e6:	64e2                	ld	s1,24(sp)
    800035e8:	6942                	ld	s2,16(sp)
    800035ea:	69a2                	ld	s3,8(sp)
    800035ec:	6145                	addi	sp,sp,48
    800035ee:	8082                	ret
    virtio_disk_rw(b, 0);
    800035f0:	4581                	li	a1,0
    800035f2:	8526                	mv	a0,s1
    800035f4:	00003097          	auipc	ra,0x3
    800035f8:	fc4080e7          	jalr	-60(ra) # 800065b8 <virtio_disk_rw>
    b->valid = 1;
    800035fc:	4785                	li	a5,1
    800035fe:	c09c                	sw	a5,0(s1)
  return b;
    80003600:	b7c5                	j	800035e0 <bread+0xd0>

0000000080003602 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003602:	1101                	addi	sp,sp,-32
    80003604:	ec06                	sd	ra,24(sp)
    80003606:	e822                	sd	s0,16(sp)
    80003608:	e426                	sd	s1,8(sp)
    8000360a:	1000                	addi	s0,sp,32
    8000360c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000360e:	0541                	addi	a0,a0,16
    80003610:	00001097          	auipc	ra,0x1
    80003614:	46e080e7          	jalr	1134(ra) # 80004a7e <holdingsleep>
    80003618:	cd01                	beqz	a0,80003630 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000361a:	4585                	li	a1,1
    8000361c:	8526                	mv	a0,s1
    8000361e:	00003097          	auipc	ra,0x3
    80003622:	f9a080e7          	jalr	-102(ra) # 800065b8 <virtio_disk_rw>
}
    80003626:	60e2                	ld	ra,24(sp)
    80003628:	6442                	ld	s0,16(sp)
    8000362a:	64a2                	ld	s1,8(sp)
    8000362c:	6105                	addi	sp,sp,32
    8000362e:	8082                	ret
    panic("bwrite");
    80003630:	00005517          	auipc	a0,0x5
    80003634:	ff050513          	addi	a0,a0,-16 # 80008620 <syscalls+0xf0>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	f0c080e7          	jalr	-244(ra) # 80000544 <panic>

0000000080003640 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003640:	1101                	addi	sp,sp,-32
    80003642:	ec06                	sd	ra,24(sp)
    80003644:	e822                	sd	s0,16(sp)
    80003646:	e426                	sd	s1,8(sp)
    80003648:	e04a                	sd	s2,0(sp)
    8000364a:	1000                	addi	s0,sp,32
    8000364c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000364e:	01050913          	addi	s2,a0,16
    80003652:	854a                	mv	a0,s2
    80003654:	00001097          	auipc	ra,0x1
    80003658:	42a080e7          	jalr	1066(ra) # 80004a7e <holdingsleep>
    8000365c:	c92d                	beqz	a0,800036ce <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000365e:	854a                	mv	a0,s2
    80003660:	00001097          	auipc	ra,0x1
    80003664:	3da080e7          	jalr	986(ra) # 80004a3a <releasesleep>

  acquire(&bcache.lock);
    80003668:	00014517          	auipc	a0,0x14
    8000366c:	aa050513          	addi	a0,a0,-1376 # 80017108 <bcache>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	57a080e7          	jalr	1402(ra) # 80000bea <acquire>
  b->refcnt--;
    80003678:	40bc                	lw	a5,64(s1)
    8000367a:	37fd                	addiw	a5,a5,-1
    8000367c:	0007871b          	sext.w	a4,a5
    80003680:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003682:	eb05                	bnez	a4,800036b2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003684:	68bc                	ld	a5,80(s1)
    80003686:	64b8                	ld	a4,72(s1)
    80003688:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000368a:	64bc                	ld	a5,72(s1)
    8000368c:	68b8                	ld	a4,80(s1)
    8000368e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003690:	0001c797          	auipc	a5,0x1c
    80003694:	a7878793          	addi	a5,a5,-1416 # 8001f108 <bcache+0x8000>
    80003698:	2b87b703          	ld	a4,696(a5)
    8000369c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000369e:	0001c717          	auipc	a4,0x1c
    800036a2:	cd270713          	addi	a4,a4,-814 # 8001f370 <bcache+0x8268>
    800036a6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036a8:	2b87b703          	ld	a4,696(a5)
    800036ac:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036ae:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036b2:	00014517          	auipc	a0,0x14
    800036b6:	a5650513          	addi	a0,a0,-1450 # 80017108 <bcache>
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	5e4080e7          	jalr	1508(ra) # 80000c9e <release>
}
    800036c2:	60e2                	ld	ra,24(sp)
    800036c4:	6442                	ld	s0,16(sp)
    800036c6:	64a2                	ld	s1,8(sp)
    800036c8:	6902                	ld	s2,0(sp)
    800036ca:	6105                	addi	sp,sp,32
    800036cc:	8082                	ret
    panic("brelse");
    800036ce:	00005517          	auipc	a0,0x5
    800036d2:	f5a50513          	addi	a0,a0,-166 # 80008628 <syscalls+0xf8>
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	e6e080e7          	jalr	-402(ra) # 80000544 <panic>

00000000800036de <bpin>:

void
bpin(struct buf *b) {
    800036de:	1101                	addi	sp,sp,-32
    800036e0:	ec06                	sd	ra,24(sp)
    800036e2:	e822                	sd	s0,16(sp)
    800036e4:	e426                	sd	s1,8(sp)
    800036e6:	1000                	addi	s0,sp,32
    800036e8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036ea:	00014517          	auipc	a0,0x14
    800036ee:	a1e50513          	addi	a0,a0,-1506 # 80017108 <bcache>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	4f8080e7          	jalr	1272(ra) # 80000bea <acquire>
  b->refcnt++;
    800036fa:	40bc                	lw	a5,64(s1)
    800036fc:	2785                	addiw	a5,a5,1
    800036fe:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003700:	00014517          	auipc	a0,0x14
    80003704:	a0850513          	addi	a0,a0,-1528 # 80017108 <bcache>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	596080e7          	jalr	1430(ra) # 80000c9e <release>
}
    80003710:	60e2                	ld	ra,24(sp)
    80003712:	6442                	ld	s0,16(sp)
    80003714:	64a2                	ld	s1,8(sp)
    80003716:	6105                	addi	sp,sp,32
    80003718:	8082                	ret

000000008000371a <bunpin>:

void
bunpin(struct buf *b) {
    8000371a:	1101                	addi	sp,sp,-32
    8000371c:	ec06                	sd	ra,24(sp)
    8000371e:	e822                	sd	s0,16(sp)
    80003720:	e426                	sd	s1,8(sp)
    80003722:	1000                	addi	s0,sp,32
    80003724:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003726:	00014517          	auipc	a0,0x14
    8000372a:	9e250513          	addi	a0,a0,-1566 # 80017108 <bcache>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	4bc080e7          	jalr	1212(ra) # 80000bea <acquire>
  b->refcnt--;
    80003736:	40bc                	lw	a5,64(s1)
    80003738:	37fd                	addiw	a5,a5,-1
    8000373a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000373c:	00014517          	auipc	a0,0x14
    80003740:	9cc50513          	addi	a0,a0,-1588 # 80017108 <bcache>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	55a080e7          	jalr	1370(ra) # 80000c9e <release>
}
    8000374c:	60e2                	ld	ra,24(sp)
    8000374e:	6442                	ld	s0,16(sp)
    80003750:	64a2                	ld	s1,8(sp)
    80003752:	6105                	addi	sp,sp,32
    80003754:	8082                	ret

0000000080003756 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003756:	1101                	addi	sp,sp,-32
    80003758:	ec06                	sd	ra,24(sp)
    8000375a:	e822                	sd	s0,16(sp)
    8000375c:	e426                	sd	s1,8(sp)
    8000375e:	e04a                	sd	s2,0(sp)
    80003760:	1000                	addi	s0,sp,32
    80003762:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003764:	00d5d59b          	srliw	a1,a1,0xd
    80003768:	0001c797          	auipc	a5,0x1c
    8000376c:	07c7a783          	lw	a5,124(a5) # 8001f7e4 <sb+0x1c>
    80003770:	9dbd                	addw	a1,a1,a5
    80003772:	00000097          	auipc	ra,0x0
    80003776:	d9e080e7          	jalr	-610(ra) # 80003510 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000377a:	0074f713          	andi	a4,s1,7
    8000377e:	4785                	li	a5,1
    80003780:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003784:	14ce                	slli	s1,s1,0x33
    80003786:	90d9                	srli	s1,s1,0x36
    80003788:	00950733          	add	a4,a0,s1
    8000378c:	05874703          	lbu	a4,88(a4)
    80003790:	00e7f6b3          	and	a3,a5,a4
    80003794:	c69d                	beqz	a3,800037c2 <bfree+0x6c>
    80003796:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003798:	94aa                	add	s1,s1,a0
    8000379a:	fff7c793          	not	a5,a5
    8000379e:	8ff9                	and	a5,a5,a4
    800037a0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800037a4:	00001097          	auipc	ra,0x1
    800037a8:	120080e7          	jalr	288(ra) # 800048c4 <log_write>
  brelse(bp);
    800037ac:	854a                	mv	a0,s2
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	e92080e7          	jalr	-366(ra) # 80003640 <brelse>
}
    800037b6:	60e2                	ld	ra,24(sp)
    800037b8:	6442                	ld	s0,16(sp)
    800037ba:	64a2                	ld	s1,8(sp)
    800037bc:	6902                	ld	s2,0(sp)
    800037be:	6105                	addi	sp,sp,32
    800037c0:	8082                	ret
    panic("freeing free block");
    800037c2:	00005517          	auipc	a0,0x5
    800037c6:	e6e50513          	addi	a0,a0,-402 # 80008630 <syscalls+0x100>
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	d7a080e7          	jalr	-646(ra) # 80000544 <panic>

00000000800037d2 <balloc>:
{
    800037d2:	711d                	addi	sp,sp,-96
    800037d4:	ec86                	sd	ra,88(sp)
    800037d6:	e8a2                	sd	s0,80(sp)
    800037d8:	e4a6                	sd	s1,72(sp)
    800037da:	e0ca                	sd	s2,64(sp)
    800037dc:	fc4e                	sd	s3,56(sp)
    800037de:	f852                	sd	s4,48(sp)
    800037e0:	f456                	sd	s5,40(sp)
    800037e2:	f05a                	sd	s6,32(sp)
    800037e4:	ec5e                	sd	s7,24(sp)
    800037e6:	e862                	sd	s8,16(sp)
    800037e8:	e466                	sd	s9,8(sp)
    800037ea:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037ec:	0001c797          	auipc	a5,0x1c
    800037f0:	fe07a783          	lw	a5,-32(a5) # 8001f7cc <sb+0x4>
    800037f4:	10078163          	beqz	a5,800038f6 <balloc+0x124>
    800037f8:	8baa                	mv	s7,a0
    800037fa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037fc:	0001cb17          	auipc	s6,0x1c
    80003800:	fccb0b13          	addi	s6,s6,-52 # 8001f7c8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003804:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003806:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003808:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000380a:	6c89                	lui	s9,0x2
    8000380c:	a061                	j	80003894 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000380e:	974a                	add	a4,a4,s2
    80003810:	8fd5                	or	a5,a5,a3
    80003812:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003816:	854a                	mv	a0,s2
    80003818:	00001097          	auipc	ra,0x1
    8000381c:	0ac080e7          	jalr	172(ra) # 800048c4 <log_write>
        brelse(bp);
    80003820:	854a                	mv	a0,s2
    80003822:	00000097          	auipc	ra,0x0
    80003826:	e1e080e7          	jalr	-482(ra) # 80003640 <brelse>
  bp = bread(dev, bno);
    8000382a:	85a6                	mv	a1,s1
    8000382c:	855e                	mv	a0,s7
    8000382e:	00000097          	auipc	ra,0x0
    80003832:	ce2080e7          	jalr	-798(ra) # 80003510 <bread>
    80003836:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003838:	40000613          	li	a2,1024
    8000383c:	4581                	li	a1,0
    8000383e:	05850513          	addi	a0,a0,88
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	4a4080e7          	jalr	1188(ra) # 80000ce6 <memset>
  log_write(bp);
    8000384a:	854a                	mv	a0,s2
    8000384c:	00001097          	auipc	ra,0x1
    80003850:	078080e7          	jalr	120(ra) # 800048c4 <log_write>
  brelse(bp);
    80003854:	854a                	mv	a0,s2
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	dea080e7          	jalr	-534(ra) # 80003640 <brelse>
}
    8000385e:	8526                	mv	a0,s1
    80003860:	60e6                	ld	ra,88(sp)
    80003862:	6446                	ld	s0,80(sp)
    80003864:	64a6                	ld	s1,72(sp)
    80003866:	6906                	ld	s2,64(sp)
    80003868:	79e2                	ld	s3,56(sp)
    8000386a:	7a42                	ld	s4,48(sp)
    8000386c:	7aa2                	ld	s5,40(sp)
    8000386e:	7b02                	ld	s6,32(sp)
    80003870:	6be2                	ld	s7,24(sp)
    80003872:	6c42                	ld	s8,16(sp)
    80003874:	6ca2                	ld	s9,8(sp)
    80003876:	6125                	addi	sp,sp,96
    80003878:	8082                	ret
    brelse(bp);
    8000387a:	854a                	mv	a0,s2
    8000387c:	00000097          	auipc	ra,0x0
    80003880:	dc4080e7          	jalr	-572(ra) # 80003640 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003884:	015c87bb          	addw	a5,s9,s5
    80003888:	00078a9b          	sext.w	s5,a5
    8000388c:	004b2703          	lw	a4,4(s6)
    80003890:	06eaf363          	bgeu	s5,a4,800038f6 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003894:	41fad79b          	sraiw	a5,s5,0x1f
    80003898:	0137d79b          	srliw	a5,a5,0x13
    8000389c:	015787bb          	addw	a5,a5,s5
    800038a0:	40d7d79b          	sraiw	a5,a5,0xd
    800038a4:	01cb2583          	lw	a1,28(s6)
    800038a8:	9dbd                	addw	a1,a1,a5
    800038aa:	855e                	mv	a0,s7
    800038ac:	00000097          	auipc	ra,0x0
    800038b0:	c64080e7          	jalr	-924(ra) # 80003510 <bread>
    800038b4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038b6:	004b2503          	lw	a0,4(s6)
    800038ba:	000a849b          	sext.w	s1,s5
    800038be:	8662                	mv	a2,s8
    800038c0:	faa4fde3          	bgeu	s1,a0,8000387a <balloc+0xa8>
      m = 1 << (bi % 8);
    800038c4:	41f6579b          	sraiw	a5,a2,0x1f
    800038c8:	01d7d69b          	srliw	a3,a5,0x1d
    800038cc:	00c6873b          	addw	a4,a3,a2
    800038d0:	00777793          	andi	a5,a4,7
    800038d4:	9f95                	subw	a5,a5,a3
    800038d6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800038da:	4037571b          	sraiw	a4,a4,0x3
    800038de:	00e906b3          	add	a3,s2,a4
    800038e2:	0586c683          	lbu	a3,88(a3)
    800038e6:	00d7f5b3          	and	a1,a5,a3
    800038ea:	d195                	beqz	a1,8000380e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038ec:	2605                	addiw	a2,a2,1
    800038ee:	2485                	addiw	s1,s1,1
    800038f0:	fd4618e3          	bne	a2,s4,800038c0 <balloc+0xee>
    800038f4:	b759                	j	8000387a <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800038f6:	00005517          	auipc	a0,0x5
    800038fa:	d5250513          	addi	a0,a0,-686 # 80008648 <syscalls+0x118>
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	c90080e7          	jalr	-880(ra) # 8000058e <printf>
  return 0;
    80003906:	4481                	li	s1,0
    80003908:	bf99                	j	8000385e <balloc+0x8c>

000000008000390a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000390a:	7179                	addi	sp,sp,-48
    8000390c:	f406                	sd	ra,40(sp)
    8000390e:	f022                	sd	s0,32(sp)
    80003910:	ec26                	sd	s1,24(sp)
    80003912:	e84a                	sd	s2,16(sp)
    80003914:	e44e                	sd	s3,8(sp)
    80003916:	e052                	sd	s4,0(sp)
    80003918:	1800                	addi	s0,sp,48
    8000391a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000391c:	47ad                	li	a5,11
    8000391e:	02b7e763          	bltu	a5,a1,8000394c <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003922:	02059493          	slli	s1,a1,0x20
    80003926:	9081                	srli	s1,s1,0x20
    80003928:	048a                	slli	s1,s1,0x2
    8000392a:	94aa                	add	s1,s1,a0
    8000392c:	0504a903          	lw	s2,80(s1)
    80003930:	06091e63          	bnez	s2,800039ac <bmap+0xa2>
      addr = balloc(ip->dev);
    80003934:	4108                	lw	a0,0(a0)
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	e9c080e7          	jalr	-356(ra) # 800037d2 <balloc>
    8000393e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003942:	06090563          	beqz	s2,800039ac <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003946:	0524a823          	sw	s2,80(s1)
    8000394a:	a08d                	j	800039ac <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000394c:	ff45849b          	addiw	s1,a1,-12
    80003950:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003954:	0ff00793          	li	a5,255
    80003958:	08e7e563          	bltu	a5,a4,800039e2 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000395c:	08052903          	lw	s2,128(a0)
    80003960:	00091d63          	bnez	s2,8000397a <bmap+0x70>
      addr = balloc(ip->dev);
    80003964:	4108                	lw	a0,0(a0)
    80003966:	00000097          	auipc	ra,0x0
    8000396a:	e6c080e7          	jalr	-404(ra) # 800037d2 <balloc>
    8000396e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003972:	02090d63          	beqz	s2,800039ac <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003976:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000397a:	85ca                	mv	a1,s2
    8000397c:	0009a503          	lw	a0,0(s3)
    80003980:	00000097          	auipc	ra,0x0
    80003984:	b90080e7          	jalr	-1136(ra) # 80003510 <bread>
    80003988:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000398a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000398e:	02049593          	slli	a1,s1,0x20
    80003992:	9181                	srli	a1,a1,0x20
    80003994:	058a                	slli	a1,a1,0x2
    80003996:	00b784b3          	add	s1,a5,a1
    8000399a:	0004a903          	lw	s2,0(s1)
    8000399e:	02090063          	beqz	s2,800039be <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800039a2:	8552                	mv	a0,s4
    800039a4:	00000097          	auipc	ra,0x0
    800039a8:	c9c080e7          	jalr	-868(ra) # 80003640 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800039ac:	854a                	mv	a0,s2
    800039ae:	70a2                	ld	ra,40(sp)
    800039b0:	7402                	ld	s0,32(sp)
    800039b2:	64e2                	ld	s1,24(sp)
    800039b4:	6942                	ld	s2,16(sp)
    800039b6:	69a2                	ld	s3,8(sp)
    800039b8:	6a02                	ld	s4,0(sp)
    800039ba:	6145                	addi	sp,sp,48
    800039bc:	8082                	ret
      addr = balloc(ip->dev);
    800039be:	0009a503          	lw	a0,0(s3)
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	e10080e7          	jalr	-496(ra) # 800037d2 <balloc>
    800039ca:	0005091b          	sext.w	s2,a0
      if(addr){
    800039ce:	fc090ae3          	beqz	s2,800039a2 <bmap+0x98>
        a[bn] = addr;
    800039d2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800039d6:	8552                	mv	a0,s4
    800039d8:	00001097          	auipc	ra,0x1
    800039dc:	eec080e7          	jalr	-276(ra) # 800048c4 <log_write>
    800039e0:	b7c9                	j	800039a2 <bmap+0x98>
  panic("bmap: out of range");
    800039e2:	00005517          	auipc	a0,0x5
    800039e6:	c7e50513          	addi	a0,a0,-898 # 80008660 <syscalls+0x130>
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	b5a080e7          	jalr	-1190(ra) # 80000544 <panic>

00000000800039f2 <iget>:
{
    800039f2:	7179                	addi	sp,sp,-48
    800039f4:	f406                	sd	ra,40(sp)
    800039f6:	f022                	sd	s0,32(sp)
    800039f8:	ec26                	sd	s1,24(sp)
    800039fa:	e84a                	sd	s2,16(sp)
    800039fc:	e44e                	sd	s3,8(sp)
    800039fe:	e052                	sd	s4,0(sp)
    80003a00:	1800                	addi	s0,sp,48
    80003a02:	89aa                	mv	s3,a0
    80003a04:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a06:	0001c517          	auipc	a0,0x1c
    80003a0a:	de250513          	addi	a0,a0,-542 # 8001f7e8 <itable>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	1dc080e7          	jalr	476(ra) # 80000bea <acquire>
  empty = 0;
    80003a16:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a18:	0001c497          	auipc	s1,0x1c
    80003a1c:	de848493          	addi	s1,s1,-536 # 8001f800 <itable+0x18>
    80003a20:	0001e697          	auipc	a3,0x1e
    80003a24:	87068693          	addi	a3,a3,-1936 # 80021290 <log>
    80003a28:	a039                	j	80003a36 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a2a:	02090b63          	beqz	s2,80003a60 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a2e:	08848493          	addi	s1,s1,136
    80003a32:	02d48a63          	beq	s1,a3,80003a66 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a36:	449c                	lw	a5,8(s1)
    80003a38:	fef059e3          	blez	a5,80003a2a <iget+0x38>
    80003a3c:	4098                	lw	a4,0(s1)
    80003a3e:	ff3716e3          	bne	a4,s3,80003a2a <iget+0x38>
    80003a42:	40d8                	lw	a4,4(s1)
    80003a44:	ff4713e3          	bne	a4,s4,80003a2a <iget+0x38>
      ip->ref++;
    80003a48:	2785                	addiw	a5,a5,1
    80003a4a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a4c:	0001c517          	auipc	a0,0x1c
    80003a50:	d9c50513          	addi	a0,a0,-612 # 8001f7e8 <itable>
    80003a54:	ffffd097          	auipc	ra,0xffffd
    80003a58:	24a080e7          	jalr	586(ra) # 80000c9e <release>
      return ip;
    80003a5c:	8926                	mv	s2,s1
    80003a5e:	a03d                	j	80003a8c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a60:	f7f9                	bnez	a5,80003a2e <iget+0x3c>
    80003a62:	8926                	mv	s2,s1
    80003a64:	b7e9                	j	80003a2e <iget+0x3c>
  if(empty == 0)
    80003a66:	02090c63          	beqz	s2,80003a9e <iget+0xac>
  ip->dev = dev;
    80003a6a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a6e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a72:	4785                	li	a5,1
    80003a74:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a78:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a7c:	0001c517          	auipc	a0,0x1c
    80003a80:	d6c50513          	addi	a0,a0,-660 # 8001f7e8 <itable>
    80003a84:	ffffd097          	auipc	ra,0xffffd
    80003a88:	21a080e7          	jalr	538(ra) # 80000c9e <release>
}
    80003a8c:	854a                	mv	a0,s2
    80003a8e:	70a2                	ld	ra,40(sp)
    80003a90:	7402                	ld	s0,32(sp)
    80003a92:	64e2                	ld	s1,24(sp)
    80003a94:	6942                	ld	s2,16(sp)
    80003a96:	69a2                	ld	s3,8(sp)
    80003a98:	6a02                	ld	s4,0(sp)
    80003a9a:	6145                	addi	sp,sp,48
    80003a9c:	8082                	ret
    panic("iget: no inodes");
    80003a9e:	00005517          	auipc	a0,0x5
    80003aa2:	bda50513          	addi	a0,a0,-1062 # 80008678 <syscalls+0x148>
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	a9e080e7          	jalr	-1378(ra) # 80000544 <panic>

0000000080003aae <fsinit>:
fsinit(int dev) {
    80003aae:	7179                	addi	sp,sp,-48
    80003ab0:	f406                	sd	ra,40(sp)
    80003ab2:	f022                	sd	s0,32(sp)
    80003ab4:	ec26                	sd	s1,24(sp)
    80003ab6:	e84a                	sd	s2,16(sp)
    80003ab8:	e44e                	sd	s3,8(sp)
    80003aba:	1800                	addi	s0,sp,48
    80003abc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003abe:	4585                	li	a1,1
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	a50080e7          	jalr	-1456(ra) # 80003510 <bread>
    80003ac8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003aca:	0001c997          	auipc	s3,0x1c
    80003ace:	cfe98993          	addi	s3,s3,-770 # 8001f7c8 <sb>
    80003ad2:	02000613          	li	a2,32
    80003ad6:	05850593          	addi	a1,a0,88
    80003ada:	854e                	mv	a0,s3
    80003adc:	ffffd097          	auipc	ra,0xffffd
    80003ae0:	26a080e7          	jalr	618(ra) # 80000d46 <memmove>
  brelse(bp);
    80003ae4:	8526                	mv	a0,s1
    80003ae6:	00000097          	auipc	ra,0x0
    80003aea:	b5a080e7          	jalr	-1190(ra) # 80003640 <brelse>
  if(sb.magic != FSMAGIC)
    80003aee:	0009a703          	lw	a4,0(s3)
    80003af2:	102037b7          	lui	a5,0x10203
    80003af6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003afa:	02f71263          	bne	a4,a5,80003b1e <fsinit+0x70>
  initlog(dev, &sb);
    80003afe:	0001c597          	auipc	a1,0x1c
    80003b02:	cca58593          	addi	a1,a1,-822 # 8001f7c8 <sb>
    80003b06:	854a                	mv	a0,s2
    80003b08:	00001097          	auipc	ra,0x1
    80003b0c:	b40080e7          	jalr	-1216(ra) # 80004648 <initlog>
}
    80003b10:	70a2                	ld	ra,40(sp)
    80003b12:	7402                	ld	s0,32(sp)
    80003b14:	64e2                	ld	s1,24(sp)
    80003b16:	6942                	ld	s2,16(sp)
    80003b18:	69a2                	ld	s3,8(sp)
    80003b1a:	6145                	addi	sp,sp,48
    80003b1c:	8082                	ret
    panic("invalid file system");
    80003b1e:	00005517          	auipc	a0,0x5
    80003b22:	b6a50513          	addi	a0,a0,-1174 # 80008688 <syscalls+0x158>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	a1e080e7          	jalr	-1506(ra) # 80000544 <panic>

0000000080003b2e <iinit>:
{
    80003b2e:	7179                	addi	sp,sp,-48
    80003b30:	f406                	sd	ra,40(sp)
    80003b32:	f022                	sd	s0,32(sp)
    80003b34:	ec26                	sd	s1,24(sp)
    80003b36:	e84a                	sd	s2,16(sp)
    80003b38:	e44e                	sd	s3,8(sp)
    80003b3a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b3c:	00005597          	auipc	a1,0x5
    80003b40:	b6458593          	addi	a1,a1,-1180 # 800086a0 <syscalls+0x170>
    80003b44:	0001c517          	auipc	a0,0x1c
    80003b48:	ca450513          	addi	a0,a0,-860 # 8001f7e8 <itable>
    80003b4c:	ffffd097          	auipc	ra,0xffffd
    80003b50:	00e080e7          	jalr	14(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b54:	0001c497          	auipc	s1,0x1c
    80003b58:	cbc48493          	addi	s1,s1,-836 # 8001f810 <itable+0x28>
    80003b5c:	0001d997          	auipc	s3,0x1d
    80003b60:	74498993          	addi	s3,s3,1860 # 800212a0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b64:	00005917          	auipc	s2,0x5
    80003b68:	b4490913          	addi	s2,s2,-1212 # 800086a8 <syscalls+0x178>
    80003b6c:	85ca                	mv	a1,s2
    80003b6e:	8526                	mv	a0,s1
    80003b70:	00001097          	auipc	ra,0x1
    80003b74:	e3a080e7          	jalr	-454(ra) # 800049aa <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b78:	08848493          	addi	s1,s1,136
    80003b7c:	ff3498e3          	bne	s1,s3,80003b6c <iinit+0x3e>
}
    80003b80:	70a2                	ld	ra,40(sp)
    80003b82:	7402                	ld	s0,32(sp)
    80003b84:	64e2                	ld	s1,24(sp)
    80003b86:	6942                	ld	s2,16(sp)
    80003b88:	69a2                	ld	s3,8(sp)
    80003b8a:	6145                	addi	sp,sp,48
    80003b8c:	8082                	ret

0000000080003b8e <ialloc>:
{
    80003b8e:	715d                	addi	sp,sp,-80
    80003b90:	e486                	sd	ra,72(sp)
    80003b92:	e0a2                	sd	s0,64(sp)
    80003b94:	fc26                	sd	s1,56(sp)
    80003b96:	f84a                	sd	s2,48(sp)
    80003b98:	f44e                	sd	s3,40(sp)
    80003b9a:	f052                	sd	s4,32(sp)
    80003b9c:	ec56                	sd	s5,24(sp)
    80003b9e:	e85a                	sd	s6,16(sp)
    80003ba0:	e45e                	sd	s7,8(sp)
    80003ba2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ba4:	0001c717          	auipc	a4,0x1c
    80003ba8:	c3072703          	lw	a4,-976(a4) # 8001f7d4 <sb+0xc>
    80003bac:	4785                	li	a5,1
    80003bae:	04e7fa63          	bgeu	a5,a4,80003c02 <ialloc+0x74>
    80003bb2:	8aaa                	mv	s5,a0
    80003bb4:	8bae                	mv	s7,a1
    80003bb6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003bb8:	0001ca17          	auipc	s4,0x1c
    80003bbc:	c10a0a13          	addi	s4,s4,-1008 # 8001f7c8 <sb>
    80003bc0:	00048b1b          	sext.w	s6,s1
    80003bc4:	0044d593          	srli	a1,s1,0x4
    80003bc8:	018a2783          	lw	a5,24(s4)
    80003bcc:	9dbd                	addw	a1,a1,a5
    80003bce:	8556                	mv	a0,s5
    80003bd0:	00000097          	auipc	ra,0x0
    80003bd4:	940080e7          	jalr	-1728(ra) # 80003510 <bread>
    80003bd8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bda:	05850993          	addi	s3,a0,88
    80003bde:	00f4f793          	andi	a5,s1,15
    80003be2:	079a                	slli	a5,a5,0x6
    80003be4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003be6:	00099783          	lh	a5,0(s3)
    80003bea:	c3a1                	beqz	a5,80003c2a <ialloc+0x9c>
    brelse(bp);
    80003bec:	00000097          	auipc	ra,0x0
    80003bf0:	a54080e7          	jalr	-1452(ra) # 80003640 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bf4:	0485                	addi	s1,s1,1
    80003bf6:	00ca2703          	lw	a4,12(s4)
    80003bfa:	0004879b          	sext.w	a5,s1
    80003bfe:	fce7e1e3          	bltu	a5,a4,80003bc0 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003c02:	00005517          	auipc	a0,0x5
    80003c06:	aae50513          	addi	a0,a0,-1362 # 800086b0 <syscalls+0x180>
    80003c0a:	ffffd097          	auipc	ra,0xffffd
    80003c0e:	984080e7          	jalr	-1660(ra) # 8000058e <printf>
  return 0;
    80003c12:	4501                	li	a0,0
}
    80003c14:	60a6                	ld	ra,72(sp)
    80003c16:	6406                	ld	s0,64(sp)
    80003c18:	74e2                	ld	s1,56(sp)
    80003c1a:	7942                	ld	s2,48(sp)
    80003c1c:	79a2                	ld	s3,40(sp)
    80003c1e:	7a02                	ld	s4,32(sp)
    80003c20:	6ae2                	ld	s5,24(sp)
    80003c22:	6b42                	ld	s6,16(sp)
    80003c24:	6ba2                	ld	s7,8(sp)
    80003c26:	6161                	addi	sp,sp,80
    80003c28:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003c2a:	04000613          	li	a2,64
    80003c2e:	4581                	li	a1,0
    80003c30:	854e                	mv	a0,s3
    80003c32:	ffffd097          	auipc	ra,0xffffd
    80003c36:	0b4080e7          	jalr	180(ra) # 80000ce6 <memset>
      dip->type = type;
    80003c3a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c3e:	854a                	mv	a0,s2
    80003c40:	00001097          	auipc	ra,0x1
    80003c44:	c84080e7          	jalr	-892(ra) # 800048c4 <log_write>
      brelse(bp);
    80003c48:	854a                	mv	a0,s2
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	9f6080e7          	jalr	-1546(ra) # 80003640 <brelse>
      return iget(dev, inum);
    80003c52:	85da                	mv	a1,s6
    80003c54:	8556                	mv	a0,s5
    80003c56:	00000097          	auipc	ra,0x0
    80003c5a:	d9c080e7          	jalr	-612(ra) # 800039f2 <iget>
    80003c5e:	bf5d                	j	80003c14 <ialloc+0x86>

0000000080003c60 <iupdate>:
{
    80003c60:	1101                	addi	sp,sp,-32
    80003c62:	ec06                	sd	ra,24(sp)
    80003c64:	e822                	sd	s0,16(sp)
    80003c66:	e426                	sd	s1,8(sp)
    80003c68:	e04a                	sd	s2,0(sp)
    80003c6a:	1000                	addi	s0,sp,32
    80003c6c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c6e:	415c                	lw	a5,4(a0)
    80003c70:	0047d79b          	srliw	a5,a5,0x4
    80003c74:	0001c597          	auipc	a1,0x1c
    80003c78:	b6c5a583          	lw	a1,-1172(a1) # 8001f7e0 <sb+0x18>
    80003c7c:	9dbd                	addw	a1,a1,a5
    80003c7e:	4108                	lw	a0,0(a0)
    80003c80:	00000097          	auipc	ra,0x0
    80003c84:	890080e7          	jalr	-1904(ra) # 80003510 <bread>
    80003c88:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c8a:	05850793          	addi	a5,a0,88
    80003c8e:	40c8                	lw	a0,4(s1)
    80003c90:	893d                	andi	a0,a0,15
    80003c92:	051a                	slli	a0,a0,0x6
    80003c94:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c96:	04449703          	lh	a4,68(s1)
    80003c9a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c9e:	04649703          	lh	a4,70(s1)
    80003ca2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003ca6:	04849703          	lh	a4,72(s1)
    80003caa:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003cae:	04a49703          	lh	a4,74(s1)
    80003cb2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003cb6:	44f8                	lw	a4,76(s1)
    80003cb8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003cba:	03400613          	li	a2,52
    80003cbe:	05048593          	addi	a1,s1,80
    80003cc2:	0531                	addi	a0,a0,12
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	082080e7          	jalr	130(ra) # 80000d46 <memmove>
  log_write(bp);
    80003ccc:	854a                	mv	a0,s2
    80003cce:	00001097          	auipc	ra,0x1
    80003cd2:	bf6080e7          	jalr	-1034(ra) # 800048c4 <log_write>
  brelse(bp);
    80003cd6:	854a                	mv	a0,s2
    80003cd8:	00000097          	auipc	ra,0x0
    80003cdc:	968080e7          	jalr	-1688(ra) # 80003640 <brelse>
}
    80003ce0:	60e2                	ld	ra,24(sp)
    80003ce2:	6442                	ld	s0,16(sp)
    80003ce4:	64a2                	ld	s1,8(sp)
    80003ce6:	6902                	ld	s2,0(sp)
    80003ce8:	6105                	addi	sp,sp,32
    80003cea:	8082                	ret

0000000080003cec <idup>:
{
    80003cec:	1101                	addi	sp,sp,-32
    80003cee:	ec06                	sd	ra,24(sp)
    80003cf0:	e822                	sd	s0,16(sp)
    80003cf2:	e426                	sd	s1,8(sp)
    80003cf4:	1000                	addi	s0,sp,32
    80003cf6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cf8:	0001c517          	auipc	a0,0x1c
    80003cfc:	af050513          	addi	a0,a0,-1296 # 8001f7e8 <itable>
    80003d00:	ffffd097          	auipc	ra,0xffffd
    80003d04:	eea080e7          	jalr	-278(ra) # 80000bea <acquire>
  ip->ref++;
    80003d08:	449c                	lw	a5,8(s1)
    80003d0a:	2785                	addiw	a5,a5,1
    80003d0c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d0e:	0001c517          	auipc	a0,0x1c
    80003d12:	ada50513          	addi	a0,a0,-1318 # 8001f7e8 <itable>
    80003d16:	ffffd097          	auipc	ra,0xffffd
    80003d1a:	f88080e7          	jalr	-120(ra) # 80000c9e <release>
}
    80003d1e:	8526                	mv	a0,s1
    80003d20:	60e2                	ld	ra,24(sp)
    80003d22:	6442                	ld	s0,16(sp)
    80003d24:	64a2                	ld	s1,8(sp)
    80003d26:	6105                	addi	sp,sp,32
    80003d28:	8082                	ret

0000000080003d2a <ilock>:
{
    80003d2a:	1101                	addi	sp,sp,-32
    80003d2c:	ec06                	sd	ra,24(sp)
    80003d2e:	e822                	sd	s0,16(sp)
    80003d30:	e426                	sd	s1,8(sp)
    80003d32:	e04a                	sd	s2,0(sp)
    80003d34:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d36:	c115                	beqz	a0,80003d5a <ilock+0x30>
    80003d38:	84aa                	mv	s1,a0
    80003d3a:	451c                	lw	a5,8(a0)
    80003d3c:	00f05f63          	blez	a5,80003d5a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d40:	0541                	addi	a0,a0,16
    80003d42:	00001097          	auipc	ra,0x1
    80003d46:	ca2080e7          	jalr	-862(ra) # 800049e4 <acquiresleep>
  if(ip->valid == 0){
    80003d4a:	40bc                	lw	a5,64(s1)
    80003d4c:	cf99                	beqz	a5,80003d6a <ilock+0x40>
}
    80003d4e:	60e2                	ld	ra,24(sp)
    80003d50:	6442                	ld	s0,16(sp)
    80003d52:	64a2                	ld	s1,8(sp)
    80003d54:	6902                	ld	s2,0(sp)
    80003d56:	6105                	addi	sp,sp,32
    80003d58:	8082                	ret
    panic("ilock");
    80003d5a:	00005517          	auipc	a0,0x5
    80003d5e:	96e50513          	addi	a0,a0,-1682 # 800086c8 <syscalls+0x198>
    80003d62:	ffffc097          	auipc	ra,0xffffc
    80003d66:	7e2080e7          	jalr	2018(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d6a:	40dc                	lw	a5,4(s1)
    80003d6c:	0047d79b          	srliw	a5,a5,0x4
    80003d70:	0001c597          	auipc	a1,0x1c
    80003d74:	a705a583          	lw	a1,-1424(a1) # 8001f7e0 <sb+0x18>
    80003d78:	9dbd                	addw	a1,a1,a5
    80003d7a:	4088                	lw	a0,0(s1)
    80003d7c:	fffff097          	auipc	ra,0xfffff
    80003d80:	794080e7          	jalr	1940(ra) # 80003510 <bread>
    80003d84:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d86:	05850593          	addi	a1,a0,88
    80003d8a:	40dc                	lw	a5,4(s1)
    80003d8c:	8bbd                	andi	a5,a5,15
    80003d8e:	079a                	slli	a5,a5,0x6
    80003d90:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d92:	00059783          	lh	a5,0(a1)
    80003d96:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d9a:	00259783          	lh	a5,2(a1)
    80003d9e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003da2:	00459783          	lh	a5,4(a1)
    80003da6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003daa:	00659783          	lh	a5,6(a1)
    80003dae:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003db2:	459c                	lw	a5,8(a1)
    80003db4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003db6:	03400613          	li	a2,52
    80003dba:	05b1                	addi	a1,a1,12
    80003dbc:	05048513          	addi	a0,s1,80
    80003dc0:	ffffd097          	auipc	ra,0xffffd
    80003dc4:	f86080e7          	jalr	-122(ra) # 80000d46 <memmove>
    brelse(bp);
    80003dc8:	854a                	mv	a0,s2
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	876080e7          	jalr	-1930(ra) # 80003640 <brelse>
    ip->valid = 1;
    80003dd2:	4785                	li	a5,1
    80003dd4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003dd6:	04449783          	lh	a5,68(s1)
    80003dda:	fbb5                	bnez	a5,80003d4e <ilock+0x24>
      panic("ilock: no type");
    80003ddc:	00005517          	auipc	a0,0x5
    80003de0:	8f450513          	addi	a0,a0,-1804 # 800086d0 <syscalls+0x1a0>
    80003de4:	ffffc097          	auipc	ra,0xffffc
    80003de8:	760080e7          	jalr	1888(ra) # 80000544 <panic>

0000000080003dec <iunlock>:
{
    80003dec:	1101                	addi	sp,sp,-32
    80003dee:	ec06                	sd	ra,24(sp)
    80003df0:	e822                	sd	s0,16(sp)
    80003df2:	e426                	sd	s1,8(sp)
    80003df4:	e04a                	sd	s2,0(sp)
    80003df6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003df8:	c905                	beqz	a0,80003e28 <iunlock+0x3c>
    80003dfa:	84aa                	mv	s1,a0
    80003dfc:	01050913          	addi	s2,a0,16
    80003e00:	854a                	mv	a0,s2
    80003e02:	00001097          	auipc	ra,0x1
    80003e06:	c7c080e7          	jalr	-900(ra) # 80004a7e <holdingsleep>
    80003e0a:	cd19                	beqz	a0,80003e28 <iunlock+0x3c>
    80003e0c:	449c                	lw	a5,8(s1)
    80003e0e:	00f05d63          	blez	a5,80003e28 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e12:	854a                	mv	a0,s2
    80003e14:	00001097          	auipc	ra,0x1
    80003e18:	c26080e7          	jalr	-986(ra) # 80004a3a <releasesleep>
}
    80003e1c:	60e2                	ld	ra,24(sp)
    80003e1e:	6442                	ld	s0,16(sp)
    80003e20:	64a2                	ld	s1,8(sp)
    80003e22:	6902                	ld	s2,0(sp)
    80003e24:	6105                	addi	sp,sp,32
    80003e26:	8082                	ret
    panic("iunlock");
    80003e28:	00005517          	auipc	a0,0x5
    80003e2c:	8b850513          	addi	a0,a0,-1864 # 800086e0 <syscalls+0x1b0>
    80003e30:	ffffc097          	auipc	ra,0xffffc
    80003e34:	714080e7          	jalr	1812(ra) # 80000544 <panic>

0000000080003e38 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e38:	7179                	addi	sp,sp,-48
    80003e3a:	f406                	sd	ra,40(sp)
    80003e3c:	f022                	sd	s0,32(sp)
    80003e3e:	ec26                	sd	s1,24(sp)
    80003e40:	e84a                	sd	s2,16(sp)
    80003e42:	e44e                	sd	s3,8(sp)
    80003e44:	e052                	sd	s4,0(sp)
    80003e46:	1800                	addi	s0,sp,48
    80003e48:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e4a:	05050493          	addi	s1,a0,80
    80003e4e:	08050913          	addi	s2,a0,128
    80003e52:	a021                	j	80003e5a <itrunc+0x22>
    80003e54:	0491                	addi	s1,s1,4
    80003e56:	01248d63          	beq	s1,s2,80003e70 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e5a:	408c                	lw	a1,0(s1)
    80003e5c:	dde5                	beqz	a1,80003e54 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e5e:	0009a503          	lw	a0,0(s3)
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	8f4080e7          	jalr	-1804(ra) # 80003756 <bfree>
      ip->addrs[i] = 0;
    80003e6a:	0004a023          	sw	zero,0(s1)
    80003e6e:	b7dd                	j	80003e54 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e70:	0809a583          	lw	a1,128(s3)
    80003e74:	e185                	bnez	a1,80003e94 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e76:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e7a:	854e                	mv	a0,s3
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	de4080e7          	jalr	-540(ra) # 80003c60 <iupdate>
}
    80003e84:	70a2                	ld	ra,40(sp)
    80003e86:	7402                	ld	s0,32(sp)
    80003e88:	64e2                	ld	s1,24(sp)
    80003e8a:	6942                	ld	s2,16(sp)
    80003e8c:	69a2                	ld	s3,8(sp)
    80003e8e:	6a02                	ld	s4,0(sp)
    80003e90:	6145                	addi	sp,sp,48
    80003e92:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e94:	0009a503          	lw	a0,0(s3)
    80003e98:	fffff097          	auipc	ra,0xfffff
    80003e9c:	678080e7          	jalr	1656(ra) # 80003510 <bread>
    80003ea0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ea2:	05850493          	addi	s1,a0,88
    80003ea6:	45850913          	addi	s2,a0,1112
    80003eaa:	a811                	j	80003ebe <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003eac:	0009a503          	lw	a0,0(s3)
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	8a6080e7          	jalr	-1882(ra) # 80003756 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003eb8:	0491                	addi	s1,s1,4
    80003eba:	01248563          	beq	s1,s2,80003ec4 <itrunc+0x8c>
      if(a[j])
    80003ebe:	408c                	lw	a1,0(s1)
    80003ec0:	dde5                	beqz	a1,80003eb8 <itrunc+0x80>
    80003ec2:	b7ed                	j	80003eac <itrunc+0x74>
    brelse(bp);
    80003ec4:	8552                	mv	a0,s4
    80003ec6:	fffff097          	auipc	ra,0xfffff
    80003eca:	77a080e7          	jalr	1914(ra) # 80003640 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ece:	0809a583          	lw	a1,128(s3)
    80003ed2:	0009a503          	lw	a0,0(s3)
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	880080e7          	jalr	-1920(ra) # 80003756 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ede:	0809a023          	sw	zero,128(s3)
    80003ee2:	bf51                	j	80003e76 <itrunc+0x3e>

0000000080003ee4 <iput>:
{
    80003ee4:	1101                	addi	sp,sp,-32
    80003ee6:	ec06                	sd	ra,24(sp)
    80003ee8:	e822                	sd	s0,16(sp)
    80003eea:	e426                	sd	s1,8(sp)
    80003eec:	e04a                	sd	s2,0(sp)
    80003eee:	1000                	addi	s0,sp,32
    80003ef0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ef2:	0001c517          	auipc	a0,0x1c
    80003ef6:	8f650513          	addi	a0,a0,-1802 # 8001f7e8 <itable>
    80003efa:	ffffd097          	auipc	ra,0xffffd
    80003efe:	cf0080e7          	jalr	-784(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f02:	4498                	lw	a4,8(s1)
    80003f04:	4785                	li	a5,1
    80003f06:	02f70363          	beq	a4,a5,80003f2c <iput+0x48>
  ip->ref--;
    80003f0a:	449c                	lw	a5,8(s1)
    80003f0c:	37fd                	addiw	a5,a5,-1
    80003f0e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f10:	0001c517          	auipc	a0,0x1c
    80003f14:	8d850513          	addi	a0,a0,-1832 # 8001f7e8 <itable>
    80003f18:	ffffd097          	auipc	ra,0xffffd
    80003f1c:	d86080e7          	jalr	-634(ra) # 80000c9e <release>
}
    80003f20:	60e2                	ld	ra,24(sp)
    80003f22:	6442                	ld	s0,16(sp)
    80003f24:	64a2                	ld	s1,8(sp)
    80003f26:	6902                	ld	s2,0(sp)
    80003f28:	6105                	addi	sp,sp,32
    80003f2a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f2c:	40bc                	lw	a5,64(s1)
    80003f2e:	dff1                	beqz	a5,80003f0a <iput+0x26>
    80003f30:	04a49783          	lh	a5,74(s1)
    80003f34:	fbf9                	bnez	a5,80003f0a <iput+0x26>
    acquiresleep(&ip->lock);
    80003f36:	01048913          	addi	s2,s1,16
    80003f3a:	854a                	mv	a0,s2
    80003f3c:	00001097          	auipc	ra,0x1
    80003f40:	aa8080e7          	jalr	-1368(ra) # 800049e4 <acquiresleep>
    release(&itable.lock);
    80003f44:	0001c517          	auipc	a0,0x1c
    80003f48:	8a450513          	addi	a0,a0,-1884 # 8001f7e8 <itable>
    80003f4c:	ffffd097          	auipc	ra,0xffffd
    80003f50:	d52080e7          	jalr	-686(ra) # 80000c9e <release>
    itrunc(ip);
    80003f54:	8526                	mv	a0,s1
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	ee2080e7          	jalr	-286(ra) # 80003e38 <itrunc>
    ip->type = 0;
    80003f5e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f62:	8526                	mv	a0,s1
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	cfc080e7          	jalr	-772(ra) # 80003c60 <iupdate>
    ip->valid = 0;
    80003f6c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f70:	854a                	mv	a0,s2
    80003f72:	00001097          	auipc	ra,0x1
    80003f76:	ac8080e7          	jalr	-1336(ra) # 80004a3a <releasesleep>
    acquire(&itable.lock);
    80003f7a:	0001c517          	auipc	a0,0x1c
    80003f7e:	86e50513          	addi	a0,a0,-1938 # 8001f7e8 <itable>
    80003f82:	ffffd097          	auipc	ra,0xffffd
    80003f86:	c68080e7          	jalr	-920(ra) # 80000bea <acquire>
    80003f8a:	b741                	j	80003f0a <iput+0x26>

0000000080003f8c <iunlockput>:
{
    80003f8c:	1101                	addi	sp,sp,-32
    80003f8e:	ec06                	sd	ra,24(sp)
    80003f90:	e822                	sd	s0,16(sp)
    80003f92:	e426                	sd	s1,8(sp)
    80003f94:	1000                	addi	s0,sp,32
    80003f96:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	e54080e7          	jalr	-428(ra) # 80003dec <iunlock>
  iput(ip);
    80003fa0:	8526                	mv	a0,s1
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	f42080e7          	jalr	-190(ra) # 80003ee4 <iput>
}
    80003faa:	60e2                	ld	ra,24(sp)
    80003fac:	6442                	ld	s0,16(sp)
    80003fae:	64a2                	ld	s1,8(sp)
    80003fb0:	6105                	addi	sp,sp,32
    80003fb2:	8082                	ret

0000000080003fb4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003fb4:	1141                	addi	sp,sp,-16
    80003fb6:	e422                	sd	s0,8(sp)
    80003fb8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fba:	411c                	lw	a5,0(a0)
    80003fbc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fbe:	415c                	lw	a5,4(a0)
    80003fc0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fc2:	04451783          	lh	a5,68(a0)
    80003fc6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fca:	04a51783          	lh	a5,74(a0)
    80003fce:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fd2:	04c56783          	lwu	a5,76(a0)
    80003fd6:	e99c                	sd	a5,16(a1)
}
    80003fd8:	6422                	ld	s0,8(sp)
    80003fda:	0141                	addi	sp,sp,16
    80003fdc:	8082                	ret

0000000080003fde <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fde:	457c                	lw	a5,76(a0)
    80003fe0:	0ed7e963          	bltu	a5,a3,800040d2 <readi+0xf4>
{
    80003fe4:	7159                	addi	sp,sp,-112
    80003fe6:	f486                	sd	ra,104(sp)
    80003fe8:	f0a2                	sd	s0,96(sp)
    80003fea:	eca6                	sd	s1,88(sp)
    80003fec:	e8ca                	sd	s2,80(sp)
    80003fee:	e4ce                	sd	s3,72(sp)
    80003ff0:	e0d2                	sd	s4,64(sp)
    80003ff2:	fc56                	sd	s5,56(sp)
    80003ff4:	f85a                	sd	s6,48(sp)
    80003ff6:	f45e                	sd	s7,40(sp)
    80003ff8:	f062                	sd	s8,32(sp)
    80003ffa:	ec66                	sd	s9,24(sp)
    80003ffc:	e86a                	sd	s10,16(sp)
    80003ffe:	e46e                	sd	s11,8(sp)
    80004000:	1880                	addi	s0,sp,112
    80004002:	8b2a                	mv	s6,a0
    80004004:	8bae                	mv	s7,a1
    80004006:	8a32                	mv	s4,a2
    80004008:	84b6                	mv	s1,a3
    8000400a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000400c:	9f35                	addw	a4,a4,a3
    return 0;
    8000400e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004010:	0ad76063          	bltu	a4,a3,800040b0 <readi+0xd2>
  if(off + n > ip->size)
    80004014:	00e7f463          	bgeu	a5,a4,8000401c <readi+0x3e>
    n = ip->size - off;
    80004018:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000401c:	0a0a8963          	beqz	s5,800040ce <readi+0xf0>
    80004020:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004022:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004026:	5c7d                	li	s8,-1
    80004028:	a82d                	j	80004062 <readi+0x84>
    8000402a:	020d1d93          	slli	s11,s10,0x20
    8000402e:	020ddd93          	srli	s11,s11,0x20
    80004032:	05890613          	addi	a2,s2,88
    80004036:	86ee                	mv	a3,s11
    80004038:	963a                	add	a2,a2,a4
    8000403a:	85d2                	mv	a1,s4
    8000403c:	855e                	mv	a0,s7
    8000403e:	fffff097          	auipc	ra,0xfffff
    80004042:	946080e7          	jalr	-1722(ra) # 80002984 <either_copyout>
    80004046:	05850d63          	beq	a0,s8,800040a0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000404a:	854a                	mv	a0,s2
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	5f4080e7          	jalr	1524(ra) # 80003640 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004054:	013d09bb          	addw	s3,s10,s3
    80004058:	009d04bb          	addw	s1,s10,s1
    8000405c:	9a6e                	add	s4,s4,s11
    8000405e:	0559f763          	bgeu	s3,s5,800040ac <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004062:	00a4d59b          	srliw	a1,s1,0xa
    80004066:	855a                	mv	a0,s6
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	8a2080e7          	jalr	-1886(ra) # 8000390a <bmap>
    80004070:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004074:	cd85                	beqz	a1,800040ac <readi+0xce>
    bp = bread(ip->dev, addr);
    80004076:	000b2503          	lw	a0,0(s6)
    8000407a:	fffff097          	auipc	ra,0xfffff
    8000407e:	496080e7          	jalr	1174(ra) # 80003510 <bread>
    80004082:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004084:	3ff4f713          	andi	a4,s1,1023
    80004088:	40ec87bb          	subw	a5,s9,a4
    8000408c:	413a86bb          	subw	a3,s5,s3
    80004090:	8d3e                	mv	s10,a5
    80004092:	2781                	sext.w	a5,a5
    80004094:	0006861b          	sext.w	a2,a3
    80004098:	f8f679e3          	bgeu	a2,a5,8000402a <readi+0x4c>
    8000409c:	8d36                	mv	s10,a3
    8000409e:	b771                	j	8000402a <readi+0x4c>
      brelse(bp);
    800040a0:	854a                	mv	a0,s2
    800040a2:	fffff097          	auipc	ra,0xfffff
    800040a6:	59e080e7          	jalr	1438(ra) # 80003640 <brelse>
      tot = -1;
    800040aa:	59fd                	li	s3,-1
  }
  return tot;
    800040ac:	0009851b          	sext.w	a0,s3
}
    800040b0:	70a6                	ld	ra,104(sp)
    800040b2:	7406                	ld	s0,96(sp)
    800040b4:	64e6                	ld	s1,88(sp)
    800040b6:	6946                	ld	s2,80(sp)
    800040b8:	69a6                	ld	s3,72(sp)
    800040ba:	6a06                	ld	s4,64(sp)
    800040bc:	7ae2                	ld	s5,56(sp)
    800040be:	7b42                	ld	s6,48(sp)
    800040c0:	7ba2                	ld	s7,40(sp)
    800040c2:	7c02                	ld	s8,32(sp)
    800040c4:	6ce2                	ld	s9,24(sp)
    800040c6:	6d42                	ld	s10,16(sp)
    800040c8:	6da2                	ld	s11,8(sp)
    800040ca:	6165                	addi	sp,sp,112
    800040cc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040ce:	89d6                	mv	s3,s5
    800040d0:	bff1                	j	800040ac <readi+0xce>
    return 0;
    800040d2:	4501                	li	a0,0
}
    800040d4:	8082                	ret

00000000800040d6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040d6:	457c                	lw	a5,76(a0)
    800040d8:	10d7e863          	bltu	a5,a3,800041e8 <writei+0x112>
{
    800040dc:	7159                	addi	sp,sp,-112
    800040de:	f486                	sd	ra,104(sp)
    800040e0:	f0a2                	sd	s0,96(sp)
    800040e2:	eca6                	sd	s1,88(sp)
    800040e4:	e8ca                	sd	s2,80(sp)
    800040e6:	e4ce                	sd	s3,72(sp)
    800040e8:	e0d2                	sd	s4,64(sp)
    800040ea:	fc56                	sd	s5,56(sp)
    800040ec:	f85a                	sd	s6,48(sp)
    800040ee:	f45e                	sd	s7,40(sp)
    800040f0:	f062                	sd	s8,32(sp)
    800040f2:	ec66                	sd	s9,24(sp)
    800040f4:	e86a                	sd	s10,16(sp)
    800040f6:	e46e                	sd	s11,8(sp)
    800040f8:	1880                	addi	s0,sp,112
    800040fa:	8aaa                	mv	s5,a0
    800040fc:	8bae                	mv	s7,a1
    800040fe:	8a32                	mv	s4,a2
    80004100:	8936                	mv	s2,a3
    80004102:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004104:	00e687bb          	addw	a5,a3,a4
    80004108:	0ed7e263          	bltu	a5,a3,800041ec <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000410c:	00043737          	lui	a4,0x43
    80004110:	0ef76063          	bltu	a4,a5,800041f0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004114:	0c0b0863          	beqz	s6,800041e4 <writei+0x10e>
    80004118:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000411a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000411e:	5c7d                	li	s8,-1
    80004120:	a091                	j	80004164 <writei+0x8e>
    80004122:	020d1d93          	slli	s11,s10,0x20
    80004126:	020ddd93          	srli	s11,s11,0x20
    8000412a:	05848513          	addi	a0,s1,88
    8000412e:	86ee                	mv	a3,s11
    80004130:	8652                	mv	a2,s4
    80004132:	85de                	mv	a1,s7
    80004134:	953a                	add	a0,a0,a4
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	8a4080e7          	jalr	-1884(ra) # 800029da <either_copyin>
    8000413e:	07850263          	beq	a0,s8,800041a2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004142:	8526                	mv	a0,s1
    80004144:	00000097          	auipc	ra,0x0
    80004148:	780080e7          	jalr	1920(ra) # 800048c4 <log_write>
    brelse(bp);
    8000414c:	8526                	mv	a0,s1
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	4f2080e7          	jalr	1266(ra) # 80003640 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004156:	013d09bb          	addw	s3,s10,s3
    8000415a:	012d093b          	addw	s2,s10,s2
    8000415e:	9a6e                	add	s4,s4,s11
    80004160:	0569f663          	bgeu	s3,s6,800041ac <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004164:	00a9559b          	srliw	a1,s2,0xa
    80004168:	8556                	mv	a0,s5
    8000416a:	fffff097          	auipc	ra,0xfffff
    8000416e:	7a0080e7          	jalr	1952(ra) # 8000390a <bmap>
    80004172:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004176:	c99d                	beqz	a1,800041ac <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004178:	000aa503          	lw	a0,0(s5)
    8000417c:	fffff097          	auipc	ra,0xfffff
    80004180:	394080e7          	jalr	916(ra) # 80003510 <bread>
    80004184:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004186:	3ff97713          	andi	a4,s2,1023
    8000418a:	40ec87bb          	subw	a5,s9,a4
    8000418e:	413b06bb          	subw	a3,s6,s3
    80004192:	8d3e                	mv	s10,a5
    80004194:	2781                	sext.w	a5,a5
    80004196:	0006861b          	sext.w	a2,a3
    8000419a:	f8f674e3          	bgeu	a2,a5,80004122 <writei+0x4c>
    8000419e:	8d36                	mv	s10,a3
    800041a0:	b749                	j	80004122 <writei+0x4c>
      brelse(bp);
    800041a2:	8526                	mv	a0,s1
    800041a4:	fffff097          	auipc	ra,0xfffff
    800041a8:	49c080e7          	jalr	1180(ra) # 80003640 <brelse>
  }

  if(off > ip->size)
    800041ac:	04caa783          	lw	a5,76(s5)
    800041b0:	0127f463          	bgeu	a5,s2,800041b8 <writei+0xe2>
    ip->size = off;
    800041b4:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041b8:	8556                	mv	a0,s5
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	aa6080e7          	jalr	-1370(ra) # 80003c60 <iupdate>

  return tot;
    800041c2:	0009851b          	sext.w	a0,s3
}
    800041c6:	70a6                	ld	ra,104(sp)
    800041c8:	7406                	ld	s0,96(sp)
    800041ca:	64e6                	ld	s1,88(sp)
    800041cc:	6946                	ld	s2,80(sp)
    800041ce:	69a6                	ld	s3,72(sp)
    800041d0:	6a06                	ld	s4,64(sp)
    800041d2:	7ae2                	ld	s5,56(sp)
    800041d4:	7b42                	ld	s6,48(sp)
    800041d6:	7ba2                	ld	s7,40(sp)
    800041d8:	7c02                	ld	s8,32(sp)
    800041da:	6ce2                	ld	s9,24(sp)
    800041dc:	6d42                	ld	s10,16(sp)
    800041de:	6da2                	ld	s11,8(sp)
    800041e0:	6165                	addi	sp,sp,112
    800041e2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041e4:	89da                	mv	s3,s6
    800041e6:	bfc9                	j	800041b8 <writei+0xe2>
    return -1;
    800041e8:	557d                	li	a0,-1
}
    800041ea:	8082                	ret
    return -1;
    800041ec:	557d                	li	a0,-1
    800041ee:	bfe1                	j	800041c6 <writei+0xf0>
    return -1;
    800041f0:	557d                	li	a0,-1
    800041f2:	bfd1                	j	800041c6 <writei+0xf0>

00000000800041f4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041f4:	1141                	addi	sp,sp,-16
    800041f6:	e406                	sd	ra,8(sp)
    800041f8:	e022                	sd	s0,0(sp)
    800041fa:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041fc:	4639                	li	a2,14
    800041fe:	ffffd097          	auipc	ra,0xffffd
    80004202:	bc0080e7          	jalr	-1088(ra) # 80000dbe <strncmp>
}
    80004206:	60a2                	ld	ra,8(sp)
    80004208:	6402                	ld	s0,0(sp)
    8000420a:	0141                	addi	sp,sp,16
    8000420c:	8082                	ret

000000008000420e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000420e:	7139                	addi	sp,sp,-64
    80004210:	fc06                	sd	ra,56(sp)
    80004212:	f822                	sd	s0,48(sp)
    80004214:	f426                	sd	s1,40(sp)
    80004216:	f04a                	sd	s2,32(sp)
    80004218:	ec4e                	sd	s3,24(sp)
    8000421a:	e852                	sd	s4,16(sp)
    8000421c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000421e:	04451703          	lh	a4,68(a0)
    80004222:	4785                	li	a5,1
    80004224:	00f71a63          	bne	a4,a5,80004238 <dirlookup+0x2a>
    80004228:	892a                	mv	s2,a0
    8000422a:	89ae                	mv	s3,a1
    8000422c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000422e:	457c                	lw	a5,76(a0)
    80004230:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004232:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004234:	e79d                	bnez	a5,80004262 <dirlookup+0x54>
    80004236:	a8a5                	j	800042ae <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004238:	00004517          	auipc	a0,0x4
    8000423c:	4b050513          	addi	a0,a0,1200 # 800086e8 <syscalls+0x1b8>
    80004240:	ffffc097          	auipc	ra,0xffffc
    80004244:	304080e7          	jalr	772(ra) # 80000544 <panic>
      panic("dirlookup read");
    80004248:	00004517          	auipc	a0,0x4
    8000424c:	4b850513          	addi	a0,a0,1208 # 80008700 <syscalls+0x1d0>
    80004250:	ffffc097          	auipc	ra,0xffffc
    80004254:	2f4080e7          	jalr	756(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004258:	24c1                	addiw	s1,s1,16
    8000425a:	04c92783          	lw	a5,76(s2)
    8000425e:	04f4f763          	bgeu	s1,a5,800042ac <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004262:	4741                	li	a4,16
    80004264:	86a6                	mv	a3,s1
    80004266:	fc040613          	addi	a2,s0,-64
    8000426a:	4581                	li	a1,0
    8000426c:	854a                	mv	a0,s2
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	d70080e7          	jalr	-656(ra) # 80003fde <readi>
    80004276:	47c1                	li	a5,16
    80004278:	fcf518e3          	bne	a0,a5,80004248 <dirlookup+0x3a>
    if(de.inum == 0)
    8000427c:	fc045783          	lhu	a5,-64(s0)
    80004280:	dfe1                	beqz	a5,80004258 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004282:	fc240593          	addi	a1,s0,-62
    80004286:	854e                	mv	a0,s3
    80004288:	00000097          	auipc	ra,0x0
    8000428c:	f6c080e7          	jalr	-148(ra) # 800041f4 <namecmp>
    80004290:	f561                	bnez	a0,80004258 <dirlookup+0x4a>
      if(poff)
    80004292:	000a0463          	beqz	s4,8000429a <dirlookup+0x8c>
        *poff = off;
    80004296:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000429a:	fc045583          	lhu	a1,-64(s0)
    8000429e:	00092503          	lw	a0,0(s2)
    800042a2:	fffff097          	auipc	ra,0xfffff
    800042a6:	750080e7          	jalr	1872(ra) # 800039f2 <iget>
    800042aa:	a011                	j	800042ae <dirlookup+0xa0>
  return 0;
    800042ac:	4501                	li	a0,0
}
    800042ae:	70e2                	ld	ra,56(sp)
    800042b0:	7442                	ld	s0,48(sp)
    800042b2:	74a2                	ld	s1,40(sp)
    800042b4:	7902                	ld	s2,32(sp)
    800042b6:	69e2                	ld	s3,24(sp)
    800042b8:	6a42                	ld	s4,16(sp)
    800042ba:	6121                	addi	sp,sp,64
    800042bc:	8082                	ret

00000000800042be <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042be:	711d                	addi	sp,sp,-96
    800042c0:	ec86                	sd	ra,88(sp)
    800042c2:	e8a2                	sd	s0,80(sp)
    800042c4:	e4a6                	sd	s1,72(sp)
    800042c6:	e0ca                	sd	s2,64(sp)
    800042c8:	fc4e                	sd	s3,56(sp)
    800042ca:	f852                	sd	s4,48(sp)
    800042cc:	f456                	sd	s5,40(sp)
    800042ce:	f05a                	sd	s6,32(sp)
    800042d0:	ec5e                	sd	s7,24(sp)
    800042d2:	e862                	sd	s8,16(sp)
    800042d4:	e466                	sd	s9,8(sp)
    800042d6:	1080                	addi	s0,sp,96
    800042d8:	84aa                	mv	s1,a0
    800042da:	8b2e                	mv	s6,a1
    800042dc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042de:	00054703          	lbu	a4,0(a0)
    800042e2:	02f00793          	li	a5,47
    800042e6:	02f70363          	beq	a4,a5,8000430c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042ea:	ffffd097          	auipc	ra,0xffffd
    800042ee:	7e4080e7          	jalr	2020(ra) # 80001ace <myproc>
    800042f2:	15053503          	ld	a0,336(a0)
    800042f6:	00000097          	auipc	ra,0x0
    800042fa:	9f6080e7          	jalr	-1546(ra) # 80003cec <idup>
    800042fe:	89aa                	mv	s3,a0
  while(*path == '/')
    80004300:	02f00913          	li	s2,47
  len = path - s;
    80004304:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004306:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004308:	4c05                	li	s8,1
    8000430a:	a865                	j	800043c2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000430c:	4585                	li	a1,1
    8000430e:	4505                	li	a0,1
    80004310:	fffff097          	auipc	ra,0xfffff
    80004314:	6e2080e7          	jalr	1762(ra) # 800039f2 <iget>
    80004318:	89aa                	mv	s3,a0
    8000431a:	b7dd                	j	80004300 <namex+0x42>
      iunlockput(ip);
    8000431c:	854e                	mv	a0,s3
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	c6e080e7          	jalr	-914(ra) # 80003f8c <iunlockput>
      return 0;
    80004326:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004328:	854e                	mv	a0,s3
    8000432a:	60e6                	ld	ra,88(sp)
    8000432c:	6446                	ld	s0,80(sp)
    8000432e:	64a6                	ld	s1,72(sp)
    80004330:	6906                	ld	s2,64(sp)
    80004332:	79e2                	ld	s3,56(sp)
    80004334:	7a42                	ld	s4,48(sp)
    80004336:	7aa2                	ld	s5,40(sp)
    80004338:	7b02                	ld	s6,32(sp)
    8000433a:	6be2                	ld	s7,24(sp)
    8000433c:	6c42                	ld	s8,16(sp)
    8000433e:	6ca2                	ld	s9,8(sp)
    80004340:	6125                	addi	sp,sp,96
    80004342:	8082                	ret
      iunlock(ip);
    80004344:	854e                	mv	a0,s3
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	aa6080e7          	jalr	-1370(ra) # 80003dec <iunlock>
      return ip;
    8000434e:	bfe9                	j	80004328 <namex+0x6a>
      iunlockput(ip);
    80004350:	854e                	mv	a0,s3
    80004352:	00000097          	auipc	ra,0x0
    80004356:	c3a080e7          	jalr	-966(ra) # 80003f8c <iunlockput>
      return 0;
    8000435a:	89d2                	mv	s3,s4
    8000435c:	b7f1                	j	80004328 <namex+0x6a>
  len = path - s;
    8000435e:	40b48633          	sub	a2,s1,a1
    80004362:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004366:	094cd463          	bge	s9,s4,800043ee <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000436a:	4639                	li	a2,14
    8000436c:	8556                	mv	a0,s5
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	9d8080e7          	jalr	-1576(ra) # 80000d46 <memmove>
  while(*path == '/')
    80004376:	0004c783          	lbu	a5,0(s1)
    8000437a:	01279763          	bne	a5,s2,80004388 <namex+0xca>
    path++;
    8000437e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004380:	0004c783          	lbu	a5,0(s1)
    80004384:	ff278de3          	beq	a5,s2,8000437e <namex+0xc0>
    ilock(ip);
    80004388:	854e                	mv	a0,s3
    8000438a:	00000097          	auipc	ra,0x0
    8000438e:	9a0080e7          	jalr	-1632(ra) # 80003d2a <ilock>
    if(ip->type != T_DIR){
    80004392:	04499783          	lh	a5,68(s3)
    80004396:	f98793e3          	bne	a5,s8,8000431c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000439a:	000b0563          	beqz	s6,800043a4 <namex+0xe6>
    8000439e:	0004c783          	lbu	a5,0(s1)
    800043a2:	d3cd                	beqz	a5,80004344 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043a4:	865e                	mv	a2,s7
    800043a6:	85d6                	mv	a1,s5
    800043a8:	854e                	mv	a0,s3
    800043aa:	00000097          	auipc	ra,0x0
    800043ae:	e64080e7          	jalr	-412(ra) # 8000420e <dirlookup>
    800043b2:	8a2a                	mv	s4,a0
    800043b4:	dd51                	beqz	a0,80004350 <namex+0x92>
    iunlockput(ip);
    800043b6:	854e                	mv	a0,s3
    800043b8:	00000097          	auipc	ra,0x0
    800043bc:	bd4080e7          	jalr	-1068(ra) # 80003f8c <iunlockput>
    ip = next;
    800043c0:	89d2                	mv	s3,s4
  while(*path == '/')
    800043c2:	0004c783          	lbu	a5,0(s1)
    800043c6:	05279763          	bne	a5,s2,80004414 <namex+0x156>
    path++;
    800043ca:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043cc:	0004c783          	lbu	a5,0(s1)
    800043d0:	ff278de3          	beq	a5,s2,800043ca <namex+0x10c>
  if(*path == 0)
    800043d4:	c79d                	beqz	a5,80004402 <namex+0x144>
    path++;
    800043d6:	85a6                	mv	a1,s1
  len = path - s;
    800043d8:	8a5e                	mv	s4,s7
    800043da:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043dc:	01278963          	beq	a5,s2,800043ee <namex+0x130>
    800043e0:	dfbd                	beqz	a5,8000435e <namex+0xa0>
    path++;
    800043e2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043e4:	0004c783          	lbu	a5,0(s1)
    800043e8:	ff279ce3          	bne	a5,s2,800043e0 <namex+0x122>
    800043ec:	bf8d                	j	8000435e <namex+0xa0>
    memmove(name, s, len);
    800043ee:	2601                	sext.w	a2,a2
    800043f0:	8556                	mv	a0,s5
    800043f2:	ffffd097          	auipc	ra,0xffffd
    800043f6:	954080e7          	jalr	-1708(ra) # 80000d46 <memmove>
    name[len] = 0;
    800043fa:	9a56                	add	s4,s4,s5
    800043fc:	000a0023          	sb	zero,0(s4)
    80004400:	bf9d                	j	80004376 <namex+0xb8>
  if(nameiparent){
    80004402:	f20b03e3          	beqz	s6,80004328 <namex+0x6a>
    iput(ip);
    80004406:	854e                	mv	a0,s3
    80004408:	00000097          	auipc	ra,0x0
    8000440c:	adc080e7          	jalr	-1316(ra) # 80003ee4 <iput>
    return 0;
    80004410:	4981                	li	s3,0
    80004412:	bf19                	j	80004328 <namex+0x6a>
  if(*path == 0)
    80004414:	d7fd                	beqz	a5,80004402 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004416:	0004c783          	lbu	a5,0(s1)
    8000441a:	85a6                	mv	a1,s1
    8000441c:	b7d1                	j	800043e0 <namex+0x122>

000000008000441e <dirlink>:
{
    8000441e:	7139                	addi	sp,sp,-64
    80004420:	fc06                	sd	ra,56(sp)
    80004422:	f822                	sd	s0,48(sp)
    80004424:	f426                	sd	s1,40(sp)
    80004426:	f04a                	sd	s2,32(sp)
    80004428:	ec4e                	sd	s3,24(sp)
    8000442a:	e852                	sd	s4,16(sp)
    8000442c:	0080                	addi	s0,sp,64
    8000442e:	892a                	mv	s2,a0
    80004430:	8a2e                	mv	s4,a1
    80004432:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004434:	4601                	li	a2,0
    80004436:	00000097          	auipc	ra,0x0
    8000443a:	dd8080e7          	jalr	-552(ra) # 8000420e <dirlookup>
    8000443e:	e93d                	bnez	a0,800044b4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004440:	04c92483          	lw	s1,76(s2)
    80004444:	c49d                	beqz	s1,80004472 <dirlink+0x54>
    80004446:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004448:	4741                	li	a4,16
    8000444a:	86a6                	mv	a3,s1
    8000444c:	fc040613          	addi	a2,s0,-64
    80004450:	4581                	li	a1,0
    80004452:	854a                	mv	a0,s2
    80004454:	00000097          	auipc	ra,0x0
    80004458:	b8a080e7          	jalr	-1142(ra) # 80003fde <readi>
    8000445c:	47c1                	li	a5,16
    8000445e:	06f51163          	bne	a0,a5,800044c0 <dirlink+0xa2>
    if(de.inum == 0)
    80004462:	fc045783          	lhu	a5,-64(s0)
    80004466:	c791                	beqz	a5,80004472 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004468:	24c1                	addiw	s1,s1,16
    8000446a:	04c92783          	lw	a5,76(s2)
    8000446e:	fcf4ede3          	bltu	s1,a5,80004448 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004472:	4639                	li	a2,14
    80004474:	85d2                	mv	a1,s4
    80004476:	fc240513          	addi	a0,s0,-62
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	980080e7          	jalr	-1664(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80004482:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004486:	4741                	li	a4,16
    80004488:	86a6                	mv	a3,s1
    8000448a:	fc040613          	addi	a2,s0,-64
    8000448e:	4581                	li	a1,0
    80004490:	854a                	mv	a0,s2
    80004492:	00000097          	auipc	ra,0x0
    80004496:	c44080e7          	jalr	-956(ra) # 800040d6 <writei>
    8000449a:	1541                	addi	a0,a0,-16
    8000449c:	00a03533          	snez	a0,a0
    800044a0:	40a00533          	neg	a0,a0
}
    800044a4:	70e2                	ld	ra,56(sp)
    800044a6:	7442                	ld	s0,48(sp)
    800044a8:	74a2                	ld	s1,40(sp)
    800044aa:	7902                	ld	s2,32(sp)
    800044ac:	69e2                	ld	s3,24(sp)
    800044ae:	6a42                	ld	s4,16(sp)
    800044b0:	6121                	addi	sp,sp,64
    800044b2:	8082                	ret
    iput(ip);
    800044b4:	00000097          	auipc	ra,0x0
    800044b8:	a30080e7          	jalr	-1488(ra) # 80003ee4 <iput>
    return -1;
    800044bc:	557d                	li	a0,-1
    800044be:	b7dd                	j	800044a4 <dirlink+0x86>
      panic("dirlink read");
    800044c0:	00004517          	auipc	a0,0x4
    800044c4:	25050513          	addi	a0,a0,592 # 80008710 <syscalls+0x1e0>
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	07c080e7          	jalr	124(ra) # 80000544 <panic>

00000000800044d0 <namei>:

struct inode*
namei(char *path)
{
    800044d0:	1101                	addi	sp,sp,-32
    800044d2:	ec06                	sd	ra,24(sp)
    800044d4:	e822                	sd	s0,16(sp)
    800044d6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044d8:	fe040613          	addi	a2,s0,-32
    800044dc:	4581                	li	a1,0
    800044de:	00000097          	auipc	ra,0x0
    800044e2:	de0080e7          	jalr	-544(ra) # 800042be <namex>
}
    800044e6:	60e2                	ld	ra,24(sp)
    800044e8:	6442                	ld	s0,16(sp)
    800044ea:	6105                	addi	sp,sp,32
    800044ec:	8082                	ret

00000000800044ee <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044ee:	1141                	addi	sp,sp,-16
    800044f0:	e406                	sd	ra,8(sp)
    800044f2:	e022                	sd	s0,0(sp)
    800044f4:	0800                	addi	s0,sp,16
    800044f6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044f8:	4585                	li	a1,1
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	dc4080e7          	jalr	-572(ra) # 800042be <namex>
}
    80004502:	60a2                	ld	ra,8(sp)
    80004504:	6402                	ld	s0,0(sp)
    80004506:	0141                	addi	sp,sp,16
    80004508:	8082                	ret

000000008000450a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000450a:	1101                	addi	sp,sp,-32
    8000450c:	ec06                	sd	ra,24(sp)
    8000450e:	e822                	sd	s0,16(sp)
    80004510:	e426                	sd	s1,8(sp)
    80004512:	e04a                	sd	s2,0(sp)
    80004514:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004516:	0001d917          	auipc	s2,0x1d
    8000451a:	d7a90913          	addi	s2,s2,-646 # 80021290 <log>
    8000451e:	01892583          	lw	a1,24(s2)
    80004522:	02892503          	lw	a0,40(s2)
    80004526:	fffff097          	auipc	ra,0xfffff
    8000452a:	fea080e7          	jalr	-22(ra) # 80003510 <bread>
    8000452e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004530:	02c92683          	lw	a3,44(s2)
    80004534:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004536:	02d05763          	blez	a3,80004564 <write_head+0x5a>
    8000453a:	0001d797          	auipc	a5,0x1d
    8000453e:	d8678793          	addi	a5,a5,-634 # 800212c0 <log+0x30>
    80004542:	05c50713          	addi	a4,a0,92
    80004546:	36fd                	addiw	a3,a3,-1
    80004548:	1682                	slli	a3,a3,0x20
    8000454a:	9281                	srli	a3,a3,0x20
    8000454c:	068a                	slli	a3,a3,0x2
    8000454e:	0001d617          	auipc	a2,0x1d
    80004552:	d7660613          	addi	a2,a2,-650 # 800212c4 <log+0x34>
    80004556:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004558:	4390                	lw	a2,0(a5)
    8000455a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000455c:	0791                	addi	a5,a5,4
    8000455e:	0711                	addi	a4,a4,4
    80004560:	fed79ce3          	bne	a5,a3,80004558 <write_head+0x4e>
  }
  bwrite(buf);
    80004564:	8526                	mv	a0,s1
    80004566:	fffff097          	auipc	ra,0xfffff
    8000456a:	09c080e7          	jalr	156(ra) # 80003602 <bwrite>
  brelse(buf);
    8000456e:	8526                	mv	a0,s1
    80004570:	fffff097          	auipc	ra,0xfffff
    80004574:	0d0080e7          	jalr	208(ra) # 80003640 <brelse>
}
    80004578:	60e2                	ld	ra,24(sp)
    8000457a:	6442                	ld	s0,16(sp)
    8000457c:	64a2                	ld	s1,8(sp)
    8000457e:	6902                	ld	s2,0(sp)
    80004580:	6105                	addi	sp,sp,32
    80004582:	8082                	ret

0000000080004584 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004584:	0001d797          	auipc	a5,0x1d
    80004588:	d387a783          	lw	a5,-712(a5) # 800212bc <log+0x2c>
    8000458c:	0af05d63          	blez	a5,80004646 <install_trans+0xc2>
{
    80004590:	7139                	addi	sp,sp,-64
    80004592:	fc06                	sd	ra,56(sp)
    80004594:	f822                	sd	s0,48(sp)
    80004596:	f426                	sd	s1,40(sp)
    80004598:	f04a                	sd	s2,32(sp)
    8000459a:	ec4e                	sd	s3,24(sp)
    8000459c:	e852                	sd	s4,16(sp)
    8000459e:	e456                	sd	s5,8(sp)
    800045a0:	e05a                	sd	s6,0(sp)
    800045a2:	0080                	addi	s0,sp,64
    800045a4:	8b2a                	mv	s6,a0
    800045a6:	0001da97          	auipc	s5,0x1d
    800045aa:	d1aa8a93          	addi	s5,s5,-742 # 800212c0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ae:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045b0:	0001d997          	auipc	s3,0x1d
    800045b4:	ce098993          	addi	s3,s3,-800 # 80021290 <log>
    800045b8:	a035                	j	800045e4 <install_trans+0x60>
      bunpin(dbuf);
    800045ba:	8526                	mv	a0,s1
    800045bc:	fffff097          	auipc	ra,0xfffff
    800045c0:	15e080e7          	jalr	350(ra) # 8000371a <bunpin>
    brelse(lbuf);
    800045c4:	854a                	mv	a0,s2
    800045c6:	fffff097          	auipc	ra,0xfffff
    800045ca:	07a080e7          	jalr	122(ra) # 80003640 <brelse>
    brelse(dbuf);
    800045ce:	8526                	mv	a0,s1
    800045d0:	fffff097          	auipc	ra,0xfffff
    800045d4:	070080e7          	jalr	112(ra) # 80003640 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045d8:	2a05                	addiw	s4,s4,1
    800045da:	0a91                	addi	s5,s5,4
    800045dc:	02c9a783          	lw	a5,44(s3)
    800045e0:	04fa5963          	bge	s4,a5,80004632 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045e4:	0189a583          	lw	a1,24(s3)
    800045e8:	014585bb          	addw	a1,a1,s4
    800045ec:	2585                	addiw	a1,a1,1
    800045ee:	0289a503          	lw	a0,40(s3)
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	f1e080e7          	jalr	-226(ra) # 80003510 <bread>
    800045fa:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045fc:	000aa583          	lw	a1,0(s5)
    80004600:	0289a503          	lw	a0,40(s3)
    80004604:	fffff097          	auipc	ra,0xfffff
    80004608:	f0c080e7          	jalr	-244(ra) # 80003510 <bread>
    8000460c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000460e:	40000613          	li	a2,1024
    80004612:	05890593          	addi	a1,s2,88
    80004616:	05850513          	addi	a0,a0,88
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	72c080e7          	jalr	1836(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004622:	8526                	mv	a0,s1
    80004624:	fffff097          	auipc	ra,0xfffff
    80004628:	fde080e7          	jalr	-34(ra) # 80003602 <bwrite>
    if(recovering == 0)
    8000462c:	f80b1ce3          	bnez	s6,800045c4 <install_trans+0x40>
    80004630:	b769                	j	800045ba <install_trans+0x36>
}
    80004632:	70e2                	ld	ra,56(sp)
    80004634:	7442                	ld	s0,48(sp)
    80004636:	74a2                	ld	s1,40(sp)
    80004638:	7902                	ld	s2,32(sp)
    8000463a:	69e2                	ld	s3,24(sp)
    8000463c:	6a42                	ld	s4,16(sp)
    8000463e:	6aa2                	ld	s5,8(sp)
    80004640:	6b02                	ld	s6,0(sp)
    80004642:	6121                	addi	sp,sp,64
    80004644:	8082                	ret
    80004646:	8082                	ret

0000000080004648 <initlog>:
{
    80004648:	7179                	addi	sp,sp,-48
    8000464a:	f406                	sd	ra,40(sp)
    8000464c:	f022                	sd	s0,32(sp)
    8000464e:	ec26                	sd	s1,24(sp)
    80004650:	e84a                	sd	s2,16(sp)
    80004652:	e44e                	sd	s3,8(sp)
    80004654:	1800                	addi	s0,sp,48
    80004656:	892a                	mv	s2,a0
    80004658:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000465a:	0001d497          	auipc	s1,0x1d
    8000465e:	c3648493          	addi	s1,s1,-970 # 80021290 <log>
    80004662:	00004597          	auipc	a1,0x4
    80004666:	0be58593          	addi	a1,a1,190 # 80008720 <syscalls+0x1f0>
    8000466a:	8526                	mv	a0,s1
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	4ee080e7          	jalr	1262(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004674:	0149a583          	lw	a1,20(s3)
    80004678:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000467a:	0109a783          	lw	a5,16(s3)
    8000467e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004680:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004684:	854a                	mv	a0,s2
    80004686:	fffff097          	auipc	ra,0xfffff
    8000468a:	e8a080e7          	jalr	-374(ra) # 80003510 <bread>
  log.lh.n = lh->n;
    8000468e:	4d3c                	lw	a5,88(a0)
    80004690:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004692:	02f05563          	blez	a5,800046bc <initlog+0x74>
    80004696:	05c50713          	addi	a4,a0,92
    8000469a:	0001d697          	auipc	a3,0x1d
    8000469e:	c2668693          	addi	a3,a3,-986 # 800212c0 <log+0x30>
    800046a2:	37fd                	addiw	a5,a5,-1
    800046a4:	1782                	slli	a5,a5,0x20
    800046a6:	9381                	srli	a5,a5,0x20
    800046a8:	078a                	slli	a5,a5,0x2
    800046aa:	06050613          	addi	a2,a0,96
    800046ae:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800046b0:	4310                	lw	a2,0(a4)
    800046b2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800046b4:	0711                	addi	a4,a4,4
    800046b6:	0691                	addi	a3,a3,4
    800046b8:	fef71ce3          	bne	a4,a5,800046b0 <initlog+0x68>
  brelse(buf);
    800046bc:	fffff097          	auipc	ra,0xfffff
    800046c0:	f84080e7          	jalr	-124(ra) # 80003640 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046c4:	4505                	li	a0,1
    800046c6:	00000097          	auipc	ra,0x0
    800046ca:	ebe080e7          	jalr	-322(ra) # 80004584 <install_trans>
  log.lh.n = 0;
    800046ce:	0001d797          	auipc	a5,0x1d
    800046d2:	be07a723          	sw	zero,-1042(a5) # 800212bc <log+0x2c>
  write_head(); // clear the log
    800046d6:	00000097          	auipc	ra,0x0
    800046da:	e34080e7          	jalr	-460(ra) # 8000450a <write_head>
}
    800046de:	70a2                	ld	ra,40(sp)
    800046e0:	7402                	ld	s0,32(sp)
    800046e2:	64e2                	ld	s1,24(sp)
    800046e4:	6942                	ld	s2,16(sp)
    800046e6:	69a2                	ld	s3,8(sp)
    800046e8:	6145                	addi	sp,sp,48
    800046ea:	8082                	ret

00000000800046ec <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046ec:	1101                	addi	sp,sp,-32
    800046ee:	ec06                	sd	ra,24(sp)
    800046f0:	e822                	sd	s0,16(sp)
    800046f2:	e426                	sd	s1,8(sp)
    800046f4:	e04a                	sd	s2,0(sp)
    800046f6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046f8:	0001d517          	auipc	a0,0x1d
    800046fc:	b9850513          	addi	a0,a0,-1128 # 80021290 <log>
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	4ea080e7          	jalr	1258(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004708:	0001d497          	auipc	s1,0x1d
    8000470c:	b8848493          	addi	s1,s1,-1144 # 80021290 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004710:	4979                	li	s2,30
    80004712:	a039                	j	80004720 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004714:	85a6                	mv	a1,s1
    80004716:	8526                	mv	a0,s1
    80004718:	ffffe097          	auipc	ra,0xffffe
    8000471c:	e64080e7          	jalr	-412(ra) # 8000257c <sleep>
    if(log.committing){
    80004720:	50dc                	lw	a5,36(s1)
    80004722:	fbed                	bnez	a5,80004714 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004724:	509c                	lw	a5,32(s1)
    80004726:	0017871b          	addiw	a4,a5,1
    8000472a:	0007069b          	sext.w	a3,a4
    8000472e:	0027179b          	slliw	a5,a4,0x2
    80004732:	9fb9                	addw	a5,a5,a4
    80004734:	0017979b          	slliw	a5,a5,0x1
    80004738:	54d8                	lw	a4,44(s1)
    8000473a:	9fb9                	addw	a5,a5,a4
    8000473c:	00f95963          	bge	s2,a5,8000474e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004740:	85a6                	mv	a1,s1
    80004742:	8526                	mv	a0,s1
    80004744:	ffffe097          	auipc	ra,0xffffe
    80004748:	e38080e7          	jalr	-456(ra) # 8000257c <sleep>
    8000474c:	bfd1                	j	80004720 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000474e:	0001d517          	auipc	a0,0x1d
    80004752:	b4250513          	addi	a0,a0,-1214 # 80021290 <log>
    80004756:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	546080e7          	jalr	1350(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004760:	60e2                	ld	ra,24(sp)
    80004762:	6442                	ld	s0,16(sp)
    80004764:	64a2                	ld	s1,8(sp)
    80004766:	6902                	ld	s2,0(sp)
    80004768:	6105                	addi	sp,sp,32
    8000476a:	8082                	ret

000000008000476c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000476c:	7139                	addi	sp,sp,-64
    8000476e:	fc06                	sd	ra,56(sp)
    80004770:	f822                	sd	s0,48(sp)
    80004772:	f426                	sd	s1,40(sp)
    80004774:	f04a                	sd	s2,32(sp)
    80004776:	ec4e                	sd	s3,24(sp)
    80004778:	e852                	sd	s4,16(sp)
    8000477a:	e456                	sd	s5,8(sp)
    8000477c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000477e:	0001d497          	auipc	s1,0x1d
    80004782:	b1248493          	addi	s1,s1,-1262 # 80021290 <log>
    80004786:	8526                	mv	a0,s1
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	462080e7          	jalr	1122(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004790:	509c                	lw	a5,32(s1)
    80004792:	37fd                	addiw	a5,a5,-1
    80004794:	0007891b          	sext.w	s2,a5
    80004798:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000479a:	50dc                	lw	a5,36(s1)
    8000479c:	efb9                	bnez	a5,800047fa <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000479e:	06091663          	bnez	s2,8000480a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800047a2:	0001d497          	auipc	s1,0x1d
    800047a6:	aee48493          	addi	s1,s1,-1298 # 80021290 <log>
    800047aa:	4785                	li	a5,1
    800047ac:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047ae:	8526                	mv	a0,s1
    800047b0:	ffffc097          	auipc	ra,0xffffc
    800047b4:	4ee080e7          	jalr	1262(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047b8:	54dc                	lw	a5,44(s1)
    800047ba:	06f04763          	bgtz	a5,80004828 <end_op+0xbc>
    acquire(&log.lock);
    800047be:	0001d497          	auipc	s1,0x1d
    800047c2:	ad248493          	addi	s1,s1,-1326 # 80021290 <log>
    800047c6:	8526                	mv	a0,s1
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	422080e7          	jalr	1058(ra) # 80000bea <acquire>
    log.committing = 0;
    800047d0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047d4:	8526                	mv	a0,s1
    800047d6:	ffffe097          	auipc	ra,0xffffe
    800047da:	e0a080e7          	jalr	-502(ra) # 800025e0 <wakeup>
    release(&log.lock);
    800047de:	8526                	mv	a0,s1
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	4be080e7          	jalr	1214(ra) # 80000c9e <release>
}
    800047e8:	70e2                	ld	ra,56(sp)
    800047ea:	7442                	ld	s0,48(sp)
    800047ec:	74a2                	ld	s1,40(sp)
    800047ee:	7902                	ld	s2,32(sp)
    800047f0:	69e2                	ld	s3,24(sp)
    800047f2:	6a42                	ld	s4,16(sp)
    800047f4:	6aa2                	ld	s5,8(sp)
    800047f6:	6121                	addi	sp,sp,64
    800047f8:	8082                	ret
    panic("log.committing");
    800047fa:	00004517          	auipc	a0,0x4
    800047fe:	f2e50513          	addi	a0,a0,-210 # 80008728 <syscalls+0x1f8>
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	d42080e7          	jalr	-702(ra) # 80000544 <panic>
    wakeup(&log);
    8000480a:	0001d497          	auipc	s1,0x1d
    8000480e:	a8648493          	addi	s1,s1,-1402 # 80021290 <log>
    80004812:	8526                	mv	a0,s1
    80004814:	ffffe097          	auipc	ra,0xffffe
    80004818:	dcc080e7          	jalr	-564(ra) # 800025e0 <wakeup>
  release(&log.lock);
    8000481c:	8526                	mv	a0,s1
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	480080e7          	jalr	1152(ra) # 80000c9e <release>
  if(do_commit){
    80004826:	b7c9                	j	800047e8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004828:	0001da97          	auipc	s5,0x1d
    8000482c:	a98a8a93          	addi	s5,s5,-1384 # 800212c0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004830:	0001da17          	auipc	s4,0x1d
    80004834:	a60a0a13          	addi	s4,s4,-1440 # 80021290 <log>
    80004838:	018a2583          	lw	a1,24(s4)
    8000483c:	012585bb          	addw	a1,a1,s2
    80004840:	2585                	addiw	a1,a1,1
    80004842:	028a2503          	lw	a0,40(s4)
    80004846:	fffff097          	auipc	ra,0xfffff
    8000484a:	cca080e7          	jalr	-822(ra) # 80003510 <bread>
    8000484e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004850:	000aa583          	lw	a1,0(s5)
    80004854:	028a2503          	lw	a0,40(s4)
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	cb8080e7          	jalr	-840(ra) # 80003510 <bread>
    80004860:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004862:	40000613          	li	a2,1024
    80004866:	05850593          	addi	a1,a0,88
    8000486a:	05848513          	addi	a0,s1,88
    8000486e:	ffffc097          	auipc	ra,0xffffc
    80004872:	4d8080e7          	jalr	1240(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004876:	8526                	mv	a0,s1
    80004878:	fffff097          	auipc	ra,0xfffff
    8000487c:	d8a080e7          	jalr	-630(ra) # 80003602 <bwrite>
    brelse(from);
    80004880:	854e                	mv	a0,s3
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	dbe080e7          	jalr	-578(ra) # 80003640 <brelse>
    brelse(to);
    8000488a:	8526                	mv	a0,s1
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	db4080e7          	jalr	-588(ra) # 80003640 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004894:	2905                	addiw	s2,s2,1
    80004896:	0a91                	addi	s5,s5,4
    80004898:	02ca2783          	lw	a5,44(s4)
    8000489c:	f8f94ee3          	blt	s2,a5,80004838 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048a0:	00000097          	auipc	ra,0x0
    800048a4:	c6a080e7          	jalr	-918(ra) # 8000450a <write_head>
    install_trans(0); // Now install writes to home locations
    800048a8:	4501                	li	a0,0
    800048aa:	00000097          	auipc	ra,0x0
    800048ae:	cda080e7          	jalr	-806(ra) # 80004584 <install_trans>
    log.lh.n = 0;
    800048b2:	0001d797          	auipc	a5,0x1d
    800048b6:	a007a523          	sw	zero,-1526(a5) # 800212bc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048ba:	00000097          	auipc	ra,0x0
    800048be:	c50080e7          	jalr	-944(ra) # 8000450a <write_head>
    800048c2:	bdf5                	j	800047be <end_op+0x52>

00000000800048c4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048c4:	1101                	addi	sp,sp,-32
    800048c6:	ec06                	sd	ra,24(sp)
    800048c8:	e822                	sd	s0,16(sp)
    800048ca:	e426                	sd	s1,8(sp)
    800048cc:	e04a                	sd	s2,0(sp)
    800048ce:	1000                	addi	s0,sp,32
    800048d0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048d2:	0001d917          	auipc	s2,0x1d
    800048d6:	9be90913          	addi	s2,s2,-1602 # 80021290 <log>
    800048da:	854a                	mv	a0,s2
    800048dc:	ffffc097          	auipc	ra,0xffffc
    800048e0:	30e080e7          	jalr	782(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048e4:	02c92603          	lw	a2,44(s2)
    800048e8:	47f5                	li	a5,29
    800048ea:	06c7c563          	blt	a5,a2,80004954 <log_write+0x90>
    800048ee:	0001d797          	auipc	a5,0x1d
    800048f2:	9be7a783          	lw	a5,-1602(a5) # 800212ac <log+0x1c>
    800048f6:	37fd                	addiw	a5,a5,-1
    800048f8:	04f65e63          	bge	a2,a5,80004954 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048fc:	0001d797          	auipc	a5,0x1d
    80004900:	9b47a783          	lw	a5,-1612(a5) # 800212b0 <log+0x20>
    80004904:	06f05063          	blez	a5,80004964 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004908:	4781                	li	a5,0
    8000490a:	06c05563          	blez	a2,80004974 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000490e:	44cc                	lw	a1,12(s1)
    80004910:	0001d717          	auipc	a4,0x1d
    80004914:	9b070713          	addi	a4,a4,-1616 # 800212c0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004918:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000491a:	4314                	lw	a3,0(a4)
    8000491c:	04b68c63          	beq	a3,a1,80004974 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004920:	2785                	addiw	a5,a5,1
    80004922:	0711                	addi	a4,a4,4
    80004924:	fef61be3          	bne	a2,a5,8000491a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004928:	0621                	addi	a2,a2,8
    8000492a:	060a                	slli	a2,a2,0x2
    8000492c:	0001d797          	auipc	a5,0x1d
    80004930:	96478793          	addi	a5,a5,-1692 # 80021290 <log>
    80004934:	963e                	add	a2,a2,a5
    80004936:	44dc                	lw	a5,12(s1)
    80004938:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000493a:	8526                	mv	a0,s1
    8000493c:	fffff097          	auipc	ra,0xfffff
    80004940:	da2080e7          	jalr	-606(ra) # 800036de <bpin>
    log.lh.n++;
    80004944:	0001d717          	auipc	a4,0x1d
    80004948:	94c70713          	addi	a4,a4,-1716 # 80021290 <log>
    8000494c:	575c                	lw	a5,44(a4)
    8000494e:	2785                	addiw	a5,a5,1
    80004950:	d75c                	sw	a5,44(a4)
    80004952:	a835                	j	8000498e <log_write+0xca>
    panic("too big a transaction");
    80004954:	00004517          	auipc	a0,0x4
    80004958:	de450513          	addi	a0,a0,-540 # 80008738 <syscalls+0x208>
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	be8080e7          	jalr	-1048(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004964:	00004517          	auipc	a0,0x4
    80004968:	dec50513          	addi	a0,a0,-532 # 80008750 <syscalls+0x220>
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	bd8080e7          	jalr	-1064(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004974:	00878713          	addi	a4,a5,8
    80004978:	00271693          	slli	a3,a4,0x2
    8000497c:	0001d717          	auipc	a4,0x1d
    80004980:	91470713          	addi	a4,a4,-1772 # 80021290 <log>
    80004984:	9736                	add	a4,a4,a3
    80004986:	44d4                	lw	a3,12(s1)
    80004988:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000498a:	faf608e3          	beq	a2,a5,8000493a <log_write+0x76>
  }
  release(&log.lock);
    8000498e:	0001d517          	auipc	a0,0x1d
    80004992:	90250513          	addi	a0,a0,-1790 # 80021290 <log>
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	308080e7          	jalr	776(ra) # 80000c9e <release>
}
    8000499e:	60e2                	ld	ra,24(sp)
    800049a0:	6442                	ld	s0,16(sp)
    800049a2:	64a2                	ld	s1,8(sp)
    800049a4:	6902                	ld	s2,0(sp)
    800049a6:	6105                	addi	sp,sp,32
    800049a8:	8082                	ret

00000000800049aa <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049aa:	1101                	addi	sp,sp,-32
    800049ac:	ec06                	sd	ra,24(sp)
    800049ae:	e822                	sd	s0,16(sp)
    800049b0:	e426                	sd	s1,8(sp)
    800049b2:	e04a                	sd	s2,0(sp)
    800049b4:	1000                	addi	s0,sp,32
    800049b6:	84aa                	mv	s1,a0
    800049b8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049ba:	00004597          	auipc	a1,0x4
    800049be:	db658593          	addi	a1,a1,-586 # 80008770 <syscalls+0x240>
    800049c2:	0521                	addi	a0,a0,8
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	196080e7          	jalr	406(ra) # 80000b5a <initlock>
  lk->name = name;
    800049cc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049d0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049d4:	0204a423          	sw	zero,40(s1)
}
    800049d8:	60e2                	ld	ra,24(sp)
    800049da:	6442                	ld	s0,16(sp)
    800049dc:	64a2                	ld	s1,8(sp)
    800049de:	6902                	ld	s2,0(sp)
    800049e0:	6105                	addi	sp,sp,32
    800049e2:	8082                	ret

00000000800049e4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049e4:	1101                	addi	sp,sp,-32
    800049e6:	ec06                	sd	ra,24(sp)
    800049e8:	e822                	sd	s0,16(sp)
    800049ea:	e426                	sd	s1,8(sp)
    800049ec:	e04a                	sd	s2,0(sp)
    800049ee:	1000                	addi	s0,sp,32
    800049f0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049f2:	00850913          	addi	s2,a0,8
    800049f6:	854a                	mv	a0,s2
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	1f2080e7          	jalr	498(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004a00:	409c                	lw	a5,0(s1)
    80004a02:	cb89                	beqz	a5,80004a14 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a04:	85ca                	mv	a1,s2
    80004a06:	8526                	mv	a0,s1
    80004a08:	ffffe097          	auipc	ra,0xffffe
    80004a0c:	b74080e7          	jalr	-1164(ra) # 8000257c <sleep>
  while (lk->locked) {
    80004a10:	409c                	lw	a5,0(s1)
    80004a12:	fbed                	bnez	a5,80004a04 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a14:	4785                	li	a5,1
    80004a16:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a18:	ffffd097          	auipc	ra,0xffffd
    80004a1c:	0b6080e7          	jalr	182(ra) # 80001ace <myproc>
    80004a20:	591c                	lw	a5,48(a0)
    80004a22:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a24:	854a                	mv	a0,s2
    80004a26:	ffffc097          	auipc	ra,0xffffc
    80004a2a:	278080e7          	jalr	632(ra) # 80000c9e <release>
}
    80004a2e:	60e2                	ld	ra,24(sp)
    80004a30:	6442                	ld	s0,16(sp)
    80004a32:	64a2                	ld	s1,8(sp)
    80004a34:	6902                	ld	s2,0(sp)
    80004a36:	6105                	addi	sp,sp,32
    80004a38:	8082                	ret

0000000080004a3a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a3a:	1101                	addi	sp,sp,-32
    80004a3c:	ec06                	sd	ra,24(sp)
    80004a3e:	e822                	sd	s0,16(sp)
    80004a40:	e426                	sd	s1,8(sp)
    80004a42:	e04a                	sd	s2,0(sp)
    80004a44:	1000                	addi	s0,sp,32
    80004a46:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a48:	00850913          	addi	s2,a0,8
    80004a4c:	854a                	mv	a0,s2
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	19c080e7          	jalr	412(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004a56:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a5a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a5e:	8526                	mv	a0,s1
    80004a60:	ffffe097          	auipc	ra,0xffffe
    80004a64:	b80080e7          	jalr	-1152(ra) # 800025e0 <wakeup>
  release(&lk->lk);
    80004a68:	854a                	mv	a0,s2
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	234080e7          	jalr	564(ra) # 80000c9e <release>
}
    80004a72:	60e2                	ld	ra,24(sp)
    80004a74:	6442                	ld	s0,16(sp)
    80004a76:	64a2                	ld	s1,8(sp)
    80004a78:	6902                	ld	s2,0(sp)
    80004a7a:	6105                	addi	sp,sp,32
    80004a7c:	8082                	ret

0000000080004a7e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a7e:	7179                	addi	sp,sp,-48
    80004a80:	f406                	sd	ra,40(sp)
    80004a82:	f022                	sd	s0,32(sp)
    80004a84:	ec26                	sd	s1,24(sp)
    80004a86:	e84a                	sd	s2,16(sp)
    80004a88:	e44e                	sd	s3,8(sp)
    80004a8a:	1800                	addi	s0,sp,48
    80004a8c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a8e:	00850913          	addi	s2,a0,8
    80004a92:	854a                	mv	a0,s2
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	156080e7          	jalr	342(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a9c:	409c                	lw	a5,0(s1)
    80004a9e:	ef99                	bnez	a5,80004abc <holdingsleep+0x3e>
    80004aa0:	4481                	li	s1,0
  release(&lk->lk);
    80004aa2:	854a                	mv	a0,s2
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	1fa080e7          	jalr	506(ra) # 80000c9e <release>
  return r;
}
    80004aac:	8526                	mv	a0,s1
    80004aae:	70a2                	ld	ra,40(sp)
    80004ab0:	7402                	ld	s0,32(sp)
    80004ab2:	64e2                	ld	s1,24(sp)
    80004ab4:	6942                	ld	s2,16(sp)
    80004ab6:	69a2                	ld	s3,8(sp)
    80004ab8:	6145                	addi	sp,sp,48
    80004aba:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004abc:	0284a983          	lw	s3,40(s1)
    80004ac0:	ffffd097          	auipc	ra,0xffffd
    80004ac4:	00e080e7          	jalr	14(ra) # 80001ace <myproc>
    80004ac8:	5904                	lw	s1,48(a0)
    80004aca:	413484b3          	sub	s1,s1,s3
    80004ace:	0014b493          	seqz	s1,s1
    80004ad2:	bfc1                	j	80004aa2 <holdingsleep+0x24>

0000000080004ad4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ad4:	1141                	addi	sp,sp,-16
    80004ad6:	e406                	sd	ra,8(sp)
    80004ad8:	e022                	sd	s0,0(sp)
    80004ada:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004adc:	00004597          	auipc	a1,0x4
    80004ae0:	ca458593          	addi	a1,a1,-860 # 80008780 <syscalls+0x250>
    80004ae4:	0001d517          	auipc	a0,0x1d
    80004ae8:	8f450513          	addi	a0,a0,-1804 # 800213d8 <ftable>
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	06e080e7          	jalr	110(ra) # 80000b5a <initlock>
}
    80004af4:	60a2                	ld	ra,8(sp)
    80004af6:	6402                	ld	s0,0(sp)
    80004af8:	0141                	addi	sp,sp,16
    80004afa:	8082                	ret

0000000080004afc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004afc:	1101                	addi	sp,sp,-32
    80004afe:	ec06                	sd	ra,24(sp)
    80004b00:	e822                	sd	s0,16(sp)
    80004b02:	e426                	sd	s1,8(sp)
    80004b04:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b06:	0001d517          	auipc	a0,0x1d
    80004b0a:	8d250513          	addi	a0,a0,-1838 # 800213d8 <ftable>
    80004b0e:	ffffc097          	auipc	ra,0xffffc
    80004b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b16:	0001d497          	auipc	s1,0x1d
    80004b1a:	8da48493          	addi	s1,s1,-1830 # 800213f0 <ftable+0x18>
    80004b1e:	0001e717          	auipc	a4,0x1e
    80004b22:	87270713          	addi	a4,a4,-1934 # 80022390 <disk>
    if(f->ref == 0){
    80004b26:	40dc                	lw	a5,4(s1)
    80004b28:	cf99                	beqz	a5,80004b46 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b2a:	02848493          	addi	s1,s1,40
    80004b2e:	fee49ce3          	bne	s1,a4,80004b26 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b32:	0001d517          	auipc	a0,0x1d
    80004b36:	8a650513          	addi	a0,a0,-1882 # 800213d8 <ftable>
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	164080e7          	jalr	356(ra) # 80000c9e <release>
  return 0;
    80004b42:	4481                	li	s1,0
    80004b44:	a819                	j	80004b5a <filealloc+0x5e>
      f->ref = 1;
    80004b46:	4785                	li	a5,1
    80004b48:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b4a:	0001d517          	auipc	a0,0x1d
    80004b4e:	88e50513          	addi	a0,a0,-1906 # 800213d8 <ftable>
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	14c080e7          	jalr	332(ra) # 80000c9e <release>
}
    80004b5a:	8526                	mv	a0,s1
    80004b5c:	60e2                	ld	ra,24(sp)
    80004b5e:	6442                	ld	s0,16(sp)
    80004b60:	64a2                	ld	s1,8(sp)
    80004b62:	6105                	addi	sp,sp,32
    80004b64:	8082                	ret

0000000080004b66 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b66:	1101                	addi	sp,sp,-32
    80004b68:	ec06                	sd	ra,24(sp)
    80004b6a:	e822                	sd	s0,16(sp)
    80004b6c:	e426                	sd	s1,8(sp)
    80004b6e:	1000                	addi	s0,sp,32
    80004b70:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b72:	0001d517          	auipc	a0,0x1d
    80004b76:	86650513          	addi	a0,a0,-1946 # 800213d8 <ftable>
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	070080e7          	jalr	112(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004b82:	40dc                	lw	a5,4(s1)
    80004b84:	02f05263          	blez	a5,80004ba8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b88:	2785                	addiw	a5,a5,1
    80004b8a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b8c:	0001d517          	auipc	a0,0x1d
    80004b90:	84c50513          	addi	a0,a0,-1972 # 800213d8 <ftable>
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	10a080e7          	jalr	266(ra) # 80000c9e <release>
  return f;
}
    80004b9c:	8526                	mv	a0,s1
    80004b9e:	60e2                	ld	ra,24(sp)
    80004ba0:	6442                	ld	s0,16(sp)
    80004ba2:	64a2                	ld	s1,8(sp)
    80004ba4:	6105                	addi	sp,sp,32
    80004ba6:	8082                	ret
    panic("filedup");
    80004ba8:	00004517          	auipc	a0,0x4
    80004bac:	be050513          	addi	a0,a0,-1056 # 80008788 <syscalls+0x258>
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	994080e7          	jalr	-1644(ra) # 80000544 <panic>

0000000080004bb8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004bb8:	7139                	addi	sp,sp,-64
    80004bba:	fc06                	sd	ra,56(sp)
    80004bbc:	f822                	sd	s0,48(sp)
    80004bbe:	f426                	sd	s1,40(sp)
    80004bc0:	f04a                	sd	s2,32(sp)
    80004bc2:	ec4e                	sd	s3,24(sp)
    80004bc4:	e852                	sd	s4,16(sp)
    80004bc6:	e456                	sd	s5,8(sp)
    80004bc8:	0080                	addi	s0,sp,64
    80004bca:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bcc:	0001d517          	auipc	a0,0x1d
    80004bd0:	80c50513          	addi	a0,a0,-2036 # 800213d8 <ftable>
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	016080e7          	jalr	22(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004bdc:	40dc                	lw	a5,4(s1)
    80004bde:	06f05163          	blez	a5,80004c40 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004be2:	37fd                	addiw	a5,a5,-1
    80004be4:	0007871b          	sext.w	a4,a5
    80004be8:	c0dc                	sw	a5,4(s1)
    80004bea:	06e04363          	bgtz	a4,80004c50 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004bee:	0004a903          	lw	s2,0(s1)
    80004bf2:	0094ca83          	lbu	s5,9(s1)
    80004bf6:	0104ba03          	ld	s4,16(s1)
    80004bfa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bfe:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c02:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c06:	0001c517          	auipc	a0,0x1c
    80004c0a:	7d250513          	addi	a0,a0,2002 # 800213d8 <ftable>
    80004c0e:	ffffc097          	auipc	ra,0xffffc
    80004c12:	090080e7          	jalr	144(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004c16:	4785                	li	a5,1
    80004c18:	04f90d63          	beq	s2,a5,80004c72 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c1c:	3979                	addiw	s2,s2,-2
    80004c1e:	4785                	li	a5,1
    80004c20:	0527e063          	bltu	a5,s2,80004c60 <fileclose+0xa8>
    begin_op();
    80004c24:	00000097          	auipc	ra,0x0
    80004c28:	ac8080e7          	jalr	-1336(ra) # 800046ec <begin_op>
    iput(ff.ip);
    80004c2c:	854e                	mv	a0,s3
    80004c2e:	fffff097          	auipc	ra,0xfffff
    80004c32:	2b6080e7          	jalr	694(ra) # 80003ee4 <iput>
    end_op();
    80004c36:	00000097          	auipc	ra,0x0
    80004c3a:	b36080e7          	jalr	-1226(ra) # 8000476c <end_op>
    80004c3e:	a00d                	j	80004c60 <fileclose+0xa8>
    panic("fileclose");
    80004c40:	00004517          	auipc	a0,0x4
    80004c44:	b5050513          	addi	a0,a0,-1200 # 80008790 <syscalls+0x260>
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	8fc080e7          	jalr	-1796(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004c50:	0001c517          	auipc	a0,0x1c
    80004c54:	78850513          	addi	a0,a0,1928 # 800213d8 <ftable>
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	046080e7          	jalr	70(ra) # 80000c9e <release>
  }
}
    80004c60:	70e2                	ld	ra,56(sp)
    80004c62:	7442                	ld	s0,48(sp)
    80004c64:	74a2                	ld	s1,40(sp)
    80004c66:	7902                	ld	s2,32(sp)
    80004c68:	69e2                	ld	s3,24(sp)
    80004c6a:	6a42                	ld	s4,16(sp)
    80004c6c:	6aa2                	ld	s5,8(sp)
    80004c6e:	6121                	addi	sp,sp,64
    80004c70:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c72:	85d6                	mv	a1,s5
    80004c74:	8552                	mv	a0,s4
    80004c76:	00000097          	auipc	ra,0x0
    80004c7a:	34c080e7          	jalr	844(ra) # 80004fc2 <pipeclose>
    80004c7e:	b7cd                	j	80004c60 <fileclose+0xa8>

0000000080004c80 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c80:	715d                	addi	sp,sp,-80
    80004c82:	e486                	sd	ra,72(sp)
    80004c84:	e0a2                	sd	s0,64(sp)
    80004c86:	fc26                	sd	s1,56(sp)
    80004c88:	f84a                	sd	s2,48(sp)
    80004c8a:	f44e                	sd	s3,40(sp)
    80004c8c:	0880                	addi	s0,sp,80
    80004c8e:	84aa                	mv	s1,a0
    80004c90:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c92:	ffffd097          	auipc	ra,0xffffd
    80004c96:	e3c080e7          	jalr	-452(ra) # 80001ace <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c9a:	409c                	lw	a5,0(s1)
    80004c9c:	37f9                	addiw	a5,a5,-2
    80004c9e:	4705                	li	a4,1
    80004ca0:	04f76763          	bltu	a4,a5,80004cee <filestat+0x6e>
    80004ca4:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ca6:	6c88                	ld	a0,24(s1)
    80004ca8:	fffff097          	auipc	ra,0xfffff
    80004cac:	082080e7          	jalr	130(ra) # 80003d2a <ilock>
    stati(f->ip, &st);
    80004cb0:	fb840593          	addi	a1,s0,-72
    80004cb4:	6c88                	ld	a0,24(s1)
    80004cb6:	fffff097          	auipc	ra,0xfffff
    80004cba:	2fe080e7          	jalr	766(ra) # 80003fb4 <stati>
    iunlock(f->ip);
    80004cbe:	6c88                	ld	a0,24(s1)
    80004cc0:	fffff097          	auipc	ra,0xfffff
    80004cc4:	12c080e7          	jalr	300(ra) # 80003dec <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cc8:	46e1                	li	a3,24
    80004cca:	fb840613          	addi	a2,s0,-72
    80004cce:	85ce                	mv	a1,s3
    80004cd0:	05093503          	ld	a0,80(s2)
    80004cd4:	ffffd097          	auipc	ra,0xffffd
    80004cd8:	9b0080e7          	jalr	-1616(ra) # 80001684 <copyout>
    80004cdc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ce0:	60a6                	ld	ra,72(sp)
    80004ce2:	6406                	ld	s0,64(sp)
    80004ce4:	74e2                	ld	s1,56(sp)
    80004ce6:	7942                	ld	s2,48(sp)
    80004ce8:	79a2                	ld	s3,40(sp)
    80004cea:	6161                	addi	sp,sp,80
    80004cec:	8082                	ret
  return -1;
    80004cee:	557d                	li	a0,-1
    80004cf0:	bfc5                	j	80004ce0 <filestat+0x60>

0000000080004cf2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004cf2:	7179                	addi	sp,sp,-48
    80004cf4:	f406                	sd	ra,40(sp)
    80004cf6:	f022                	sd	s0,32(sp)
    80004cf8:	ec26                	sd	s1,24(sp)
    80004cfa:	e84a                	sd	s2,16(sp)
    80004cfc:	e44e                	sd	s3,8(sp)
    80004cfe:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d00:	00854783          	lbu	a5,8(a0)
    80004d04:	c3d5                	beqz	a5,80004da8 <fileread+0xb6>
    80004d06:	84aa                	mv	s1,a0
    80004d08:	89ae                	mv	s3,a1
    80004d0a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d0c:	411c                	lw	a5,0(a0)
    80004d0e:	4705                	li	a4,1
    80004d10:	04e78963          	beq	a5,a4,80004d62 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d14:	470d                	li	a4,3
    80004d16:	04e78d63          	beq	a5,a4,80004d70 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d1a:	4709                	li	a4,2
    80004d1c:	06e79e63          	bne	a5,a4,80004d98 <fileread+0xa6>
    ilock(f->ip);
    80004d20:	6d08                	ld	a0,24(a0)
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	008080e7          	jalr	8(ra) # 80003d2a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d2a:	874a                	mv	a4,s2
    80004d2c:	5094                	lw	a3,32(s1)
    80004d2e:	864e                	mv	a2,s3
    80004d30:	4585                	li	a1,1
    80004d32:	6c88                	ld	a0,24(s1)
    80004d34:	fffff097          	auipc	ra,0xfffff
    80004d38:	2aa080e7          	jalr	682(ra) # 80003fde <readi>
    80004d3c:	892a                	mv	s2,a0
    80004d3e:	00a05563          	blez	a0,80004d48 <fileread+0x56>
      f->off += r;
    80004d42:	509c                	lw	a5,32(s1)
    80004d44:	9fa9                	addw	a5,a5,a0
    80004d46:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d48:	6c88                	ld	a0,24(s1)
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	0a2080e7          	jalr	162(ra) # 80003dec <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d52:	854a                	mv	a0,s2
    80004d54:	70a2                	ld	ra,40(sp)
    80004d56:	7402                	ld	s0,32(sp)
    80004d58:	64e2                	ld	s1,24(sp)
    80004d5a:	6942                	ld	s2,16(sp)
    80004d5c:	69a2                	ld	s3,8(sp)
    80004d5e:	6145                	addi	sp,sp,48
    80004d60:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d62:	6908                	ld	a0,16(a0)
    80004d64:	00000097          	auipc	ra,0x0
    80004d68:	3ce080e7          	jalr	974(ra) # 80005132 <piperead>
    80004d6c:	892a                	mv	s2,a0
    80004d6e:	b7d5                	j	80004d52 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d70:	02451783          	lh	a5,36(a0)
    80004d74:	03079693          	slli	a3,a5,0x30
    80004d78:	92c1                	srli	a3,a3,0x30
    80004d7a:	4725                	li	a4,9
    80004d7c:	02d76863          	bltu	a4,a3,80004dac <fileread+0xba>
    80004d80:	0792                	slli	a5,a5,0x4
    80004d82:	0001c717          	auipc	a4,0x1c
    80004d86:	5b670713          	addi	a4,a4,1462 # 80021338 <devsw>
    80004d8a:	97ba                	add	a5,a5,a4
    80004d8c:	639c                	ld	a5,0(a5)
    80004d8e:	c38d                	beqz	a5,80004db0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d90:	4505                	li	a0,1
    80004d92:	9782                	jalr	a5
    80004d94:	892a                	mv	s2,a0
    80004d96:	bf75                	j	80004d52 <fileread+0x60>
    panic("fileread");
    80004d98:	00004517          	auipc	a0,0x4
    80004d9c:	a0850513          	addi	a0,a0,-1528 # 800087a0 <syscalls+0x270>
    80004da0:	ffffb097          	auipc	ra,0xffffb
    80004da4:	7a4080e7          	jalr	1956(ra) # 80000544 <panic>
    return -1;
    80004da8:	597d                	li	s2,-1
    80004daa:	b765                	j	80004d52 <fileread+0x60>
      return -1;
    80004dac:	597d                	li	s2,-1
    80004dae:	b755                	j	80004d52 <fileread+0x60>
    80004db0:	597d                	li	s2,-1
    80004db2:	b745                	j	80004d52 <fileread+0x60>

0000000080004db4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004db4:	715d                	addi	sp,sp,-80
    80004db6:	e486                	sd	ra,72(sp)
    80004db8:	e0a2                	sd	s0,64(sp)
    80004dba:	fc26                	sd	s1,56(sp)
    80004dbc:	f84a                	sd	s2,48(sp)
    80004dbe:	f44e                	sd	s3,40(sp)
    80004dc0:	f052                	sd	s4,32(sp)
    80004dc2:	ec56                	sd	s5,24(sp)
    80004dc4:	e85a                	sd	s6,16(sp)
    80004dc6:	e45e                	sd	s7,8(sp)
    80004dc8:	e062                	sd	s8,0(sp)
    80004dca:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004dcc:	00954783          	lbu	a5,9(a0)
    80004dd0:	10078663          	beqz	a5,80004edc <filewrite+0x128>
    80004dd4:	892a                	mv	s2,a0
    80004dd6:	8aae                	mv	s5,a1
    80004dd8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dda:	411c                	lw	a5,0(a0)
    80004ddc:	4705                	li	a4,1
    80004dde:	02e78263          	beq	a5,a4,80004e02 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004de2:	470d                	li	a4,3
    80004de4:	02e78663          	beq	a5,a4,80004e10 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004de8:	4709                	li	a4,2
    80004dea:	0ee79163          	bne	a5,a4,80004ecc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004dee:	0ac05d63          	blez	a2,80004ea8 <filewrite+0xf4>
    int i = 0;
    80004df2:	4981                	li	s3,0
    80004df4:	6b05                	lui	s6,0x1
    80004df6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004dfa:	6b85                	lui	s7,0x1
    80004dfc:	c00b8b9b          	addiw	s7,s7,-1024
    80004e00:	a861                	j	80004e98 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e02:	6908                	ld	a0,16(a0)
    80004e04:	00000097          	auipc	ra,0x0
    80004e08:	22e080e7          	jalr	558(ra) # 80005032 <pipewrite>
    80004e0c:	8a2a                	mv	s4,a0
    80004e0e:	a045                	j	80004eae <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e10:	02451783          	lh	a5,36(a0)
    80004e14:	03079693          	slli	a3,a5,0x30
    80004e18:	92c1                	srli	a3,a3,0x30
    80004e1a:	4725                	li	a4,9
    80004e1c:	0cd76263          	bltu	a4,a3,80004ee0 <filewrite+0x12c>
    80004e20:	0792                	slli	a5,a5,0x4
    80004e22:	0001c717          	auipc	a4,0x1c
    80004e26:	51670713          	addi	a4,a4,1302 # 80021338 <devsw>
    80004e2a:	97ba                	add	a5,a5,a4
    80004e2c:	679c                	ld	a5,8(a5)
    80004e2e:	cbdd                	beqz	a5,80004ee4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e30:	4505                	li	a0,1
    80004e32:	9782                	jalr	a5
    80004e34:	8a2a                	mv	s4,a0
    80004e36:	a8a5                	j	80004eae <filewrite+0xfa>
    80004e38:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e3c:	00000097          	auipc	ra,0x0
    80004e40:	8b0080e7          	jalr	-1872(ra) # 800046ec <begin_op>
      ilock(f->ip);
    80004e44:	01893503          	ld	a0,24(s2)
    80004e48:	fffff097          	auipc	ra,0xfffff
    80004e4c:	ee2080e7          	jalr	-286(ra) # 80003d2a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e50:	8762                	mv	a4,s8
    80004e52:	02092683          	lw	a3,32(s2)
    80004e56:	01598633          	add	a2,s3,s5
    80004e5a:	4585                	li	a1,1
    80004e5c:	01893503          	ld	a0,24(s2)
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	276080e7          	jalr	630(ra) # 800040d6 <writei>
    80004e68:	84aa                	mv	s1,a0
    80004e6a:	00a05763          	blez	a0,80004e78 <filewrite+0xc4>
        f->off += r;
    80004e6e:	02092783          	lw	a5,32(s2)
    80004e72:	9fa9                	addw	a5,a5,a0
    80004e74:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e78:	01893503          	ld	a0,24(s2)
    80004e7c:	fffff097          	auipc	ra,0xfffff
    80004e80:	f70080e7          	jalr	-144(ra) # 80003dec <iunlock>
      end_op();
    80004e84:	00000097          	auipc	ra,0x0
    80004e88:	8e8080e7          	jalr	-1816(ra) # 8000476c <end_op>

      if(r != n1){
    80004e8c:	009c1f63          	bne	s8,s1,80004eaa <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e90:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e94:	0149db63          	bge	s3,s4,80004eaa <filewrite+0xf6>
      int n1 = n - i;
    80004e98:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e9c:	84be                	mv	s1,a5
    80004e9e:	2781                	sext.w	a5,a5
    80004ea0:	f8fb5ce3          	bge	s6,a5,80004e38 <filewrite+0x84>
    80004ea4:	84de                	mv	s1,s7
    80004ea6:	bf49                	j	80004e38 <filewrite+0x84>
    int i = 0;
    80004ea8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004eaa:	013a1f63          	bne	s4,s3,80004ec8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004eae:	8552                	mv	a0,s4
    80004eb0:	60a6                	ld	ra,72(sp)
    80004eb2:	6406                	ld	s0,64(sp)
    80004eb4:	74e2                	ld	s1,56(sp)
    80004eb6:	7942                	ld	s2,48(sp)
    80004eb8:	79a2                	ld	s3,40(sp)
    80004eba:	7a02                	ld	s4,32(sp)
    80004ebc:	6ae2                	ld	s5,24(sp)
    80004ebe:	6b42                	ld	s6,16(sp)
    80004ec0:	6ba2                	ld	s7,8(sp)
    80004ec2:	6c02                	ld	s8,0(sp)
    80004ec4:	6161                	addi	sp,sp,80
    80004ec6:	8082                	ret
    ret = (i == n ? n : -1);
    80004ec8:	5a7d                	li	s4,-1
    80004eca:	b7d5                	j	80004eae <filewrite+0xfa>
    panic("filewrite");
    80004ecc:	00004517          	auipc	a0,0x4
    80004ed0:	8e450513          	addi	a0,a0,-1820 # 800087b0 <syscalls+0x280>
    80004ed4:	ffffb097          	auipc	ra,0xffffb
    80004ed8:	670080e7          	jalr	1648(ra) # 80000544 <panic>
    return -1;
    80004edc:	5a7d                	li	s4,-1
    80004ede:	bfc1                	j	80004eae <filewrite+0xfa>
      return -1;
    80004ee0:	5a7d                	li	s4,-1
    80004ee2:	b7f1                	j	80004eae <filewrite+0xfa>
    80004ee4:	5a7d                	li	s4,-1
    80004ee6:	b7e1                	j	80004eae <filewrite+0xfa>

0000000080004ee8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ee8:	7179                	addi	sp,sp,-48
    80004eea:	f406                	sd	ra,40(sp)
    80004eec:	f022                	sd	s0,32(sp)
    80004eee:	ec26                	sd	s1,24(sp)
    80004ef0:	e84a                	sd	s2,16(sp)
    80004ef2:	e44e                	sd	s3,8(sp)
    80004ef4:	e052                	sd	s4,0(sp)
    80004ef6:	1800                	addi	s0,sp,48
    80004ef8:	84aa                	mv	s1,a0
    80004efa:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004efc:	0005b023          	sd	zero,0(a1)
    80004f00:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f04:	00000097          	auipc	ra,0x0
    80004f08:	bf8080e7          	jalr	-1032(ra) # 80004afc <filealloc>
    80004f0c:	e088                	sd	a0,0(s1)
    80004f0e:	c551                	beqz	a0,80004f9a <pipealloc+0xb2>
    80004f10:	00000097          	auipc	ra,0x0
    80004f14:	bec080e7          	jalr	-1044(ra) # 80004afc <filealloc>
    80004f18:	00aa3023          	sd	a0,0(s4)
    80004f1c:	c92d                	beqz	a0,80004f8e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f1e:	ffffc097          	auipc	ra,0xffffc
    80004f22:	bdc080e7          	jalr	-1060(ra) # 80000afa <kalloc>
    80004f26:	892a                	mv	s2,a0
    80004f28:	c125                	beqz	a0,80004f88 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f2a:	4985                	li	s3,1
    80004f2c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f30:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f34:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f38:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f3c:	00004597          	auipc	a1,0x4
    80004f40:	88458593          	addi	a1,a1,-1916 # 800087c0 <syscalls+0x290>
    80004f44:	ffffc097          	auipc	ra,0xffffc
    80004f48:	c16080e7          	jalr	-1002(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004f4c:	609c                	ld	a5,0(s1)
    80004f4e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f52:	609c                	ld	a5,0(s1)
    80004f54:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f58:	609c                	ld	a5,0(s1)
    80004f5a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f5e:	609c                	ld	a5,0(s1)
    80004f60:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f64:	000a3783          	ld	a5,0(s4)
    80004f68:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f6c:	000a3783          	ld	a5,0(s4)
    80004f70:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f74:	000a3783          	ld	a5,0(s4)
    80004f78:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f7c:	000a3783          	ld	a5,0(s4)
    80004f80:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f84:	4501                	li	a0,0
    80004f86:	a025                	j	80004fae <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f88:	6088                	ld	a0,0(s1)
    80004f8a:	e501                	bnez	a0,80004f92 <pipealloc+0xaa>
    80004f8c:	a039                	j	80004f9a <pipealloc+0xb2>
    80004f8e:	6088                	ld	a0,0(s1)
    80004f90:	c51d                	beqz	a0,80004fbe <pipealloc+0xd6>
    fileclose(*f0);
    80004f92:	00000097          	auipc	ra,0x0
    80004f96:	c26080e7          	jalr	-986(ra) # 80004bb8 <fileclose>
  if(*f1)
    80004f9a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f9e:	557d                	li	a0,-1
  if(*f1)
    80004fa0:	c799                	beqz	a5,80004fae <pipealloc+0xc6>
    fileclose(*f1);
    80004fa2:	853e                	mv	a0,a5
    80004fa4:	00000097          	auipc	ra,0x0
    80004fa8:	c14080e7          	jalr	-1004(ra) # 80004bb8 <fileclose>
  return -1;
    80004fac:	557d                	li	a0,-1
}
    80004fae:	70a2                	ld	ra,40(sp)
    80004fb0:	7402                	ld	s0,32(sp)
    80004fb2:	64e2                	ld	s1,24(sp)
    80004fb4:	6942                	ld	s2,16(sp)
    80004fb6:	69a2                	ld	s3,8(sp)
    80004fb8:	6a02                	ld	s4,0(sp)
    80004fba:	6145                	addi	sp,sp,48
    80004fbc:	8082                	ret
  return -1;
    80004fbe:	557d                	li	a0,-1
    80004fc0:	b7fd                	j	80004fae <pipealloc+0xc6>

0000000080004fc2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fc2:	1101                	addi	sp,sp,-32
    80004fc4:	ec06                	sd	ra,24(sp)
    80004fc6:	e822                	sd	s0,16(sp)
    80004fc8:	e426                	sd	s1,8(sp)
    80004fca:	e04a                	sd	s2,0(sp)
    80004fcc:	1000                	addi	s0,sp,32
    80004fce:	84aa                	mv	s1,a0
    80004fd0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fd2:	ffffc097          	auipc	ra,0xffffc
    80004fd6:	c18080e7          	jalr	-1000(ra) # 80000bea <acquire>
  if(writable){
    80004fda:	02090d63          	beqz	s2,80005014 <pipeclose+0x52>
    pi->writeopen = 0;
    80004fde:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fe2:	21848513          	addi	a0,s1,536
    80004fe6:	ffffd097          	auipc	ra,0xffffd
    80004fea:	5fa080e7          	jalr	1530(ra) # 800025e0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fee:	2204b783          	ld	a5,544(s1)
    80004ff2:	eb95                	bnez	a5,80005026 <pipeclose+0x64>
    release(&pi->lock);
    80004ff4:	8526                	mv	a0,s1
    80004ff6:	ffffc097          	auipc	ra,0xffffc
    80004ffa:	ca8080e7          	jalr	-856(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004ffe:	8526                	mv	a0,s1
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	9fe080e7          	jalr	-1538(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80005008:	60e2                	ld	ra,24(sp)
    8000500a:	6442                	ld	s0,16(sp)
    8000500c:	64a2                	ld	s1,8(sp)
    8000500e:	6902                	ld	s2,0(sp)
    80005010:	6105                	addi	sp,sp,32
    80005012:	8082                	ret
    pi->readopen = 0;
    80005014:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005018:	21c48513          	addi	a0,s1,540
    8000501c:	ffffd097          	auipc	ra,0xffffd
    80005020:	5c4080e7          	jalr	1476(ra) # 800025e0 <wakeup>
    80005024:	b7e9                	j	80004fee <pipeclose+0x2c>
    release(&pi->lock);
    80005026:	8526                	mv	a0,s1
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	c76080e7          	jalr	-906(ra) # 80000c9e <release>
}
    80005030:	bfe1                	j	80005008 <pipeclose+0x46>

0000000080005032 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005032:	7159                	addi	sp,sp,-112
    80005034:	f486                	sd	ra,104(sp)
    80005036:	f0a2                	sd	s0,96(sp)
    80005038:	eca6                	sd	s1,88(sp)
    8000503a:	e8ca                	sd	s2,80(sp)
    8000503c:	e4ce                	sd	s3,72(sp)
    8000503e:	e0d2                	sd	s4,64(sp)
    80005040:	fc56                	sd	s5,56(sp)
    80005042:	f85a                	sd	s6,48(sp)
    80005044:	f45e                	sd	s7,40(sp)
    80005046:	f062                	sd	s8,32(sp)
    80005048:	ec66                	sd	s9,24(sp)
    8000504a:	1880                	addi	s0,sp,112
    8000504c:	84aa                	mv	s1,a0
    8000504e:	8aae                	mv	s5,a1
    80005050:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005052:	ffffd097          	auipc	ra,0xffffd
    80005056:	a7c080e7          	jalr	-1412(ra) # 80001ace <myproc>
    8000505a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000505c:	8526                	mv	a0,s1
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	b8c080e7          	jalr	-1140(ra) # 80000bea <acquire>
  while(i < n){
    80005066:	0d405463          	blez	s4,8000512e <pipewrite+0xfc>
    8000506a:	8ba6                	mv	s7,s1
  int i = 0;
    8000506c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000506e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005070:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005074:	21c48c13          	addi	s8,s1,540
    80005078:	a08d                	j	800050da <pipewrite+0xa8>
      release(&pi->lock);
    8000507a:	8526                	mv	a0,s1
    8000507c:	ffffc097          	auipc	ra,0xffffc
    80005080:	c22080e7          	jalr	-990(ra) # 80000c9e <release>
      return -1;
    80005084:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005086:	854a                	mv	a0,s2
    80005088:	70a6                	ld	ra,104(sp)
    8000508a:	7406                	ld	s0,96(sp)
    8000508c:	64e6                	ld	s1,88(sp)
    8000508e:	6946                	ld	s2,80(sp)
    80005090:	69a6                	ld	s3,72(sp)
    80005092:	6a06                	ld	s4,64(sp)
    80005094:	7ae2                	ld	s5,56(sp)
    80005096:	7b42                	ld	s6,48(sp)
    80005098:	7ba2                	ld	s7,40(sp)
    8000509a:	7c02                	ld	s8,32(sp)
    8000509c:	6ce2                	ld	s9,24(sp)
    8000509e:	6165                	addi	sp,sp,112
    800050a0:	8082                	ret
      wakeup(&pi->nread);
    800050a2:	8566                	mv	a0,s9
    800050a4:	ffffd097          	auipc	ra,0xffffd
    800050a8:	53c080e7          	jalr	1340(ra) # 800025e0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050ac:	85de                	mv	a1,s7
    800050ae:	8562                	mv	a0,s8
    800050b0:	ffffd097          	auipc	ra,0xffffd
    800050b4:	4cc080e7          	jalr	1228(ra) # 8000257c <sleep>
    800050b8:	a839                	j	800050d6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050ba:	21c4a783          	lw	a5,540(s1)
    800050be:	0017871b          	addiw	a4,a5,1
    800050c2:	20e4ae23          	sw	a4,540(s1)
    800050c6:	1ff7f793          	andi	a5,a5,511
    800050ca:	97a6                	add	a5,a5,s1
    800050cc:	f9f44703          	lbu	a4,-97(s0)
    800050d0:	00e78c23          	sb	a4,24(a5)
      i++;
    800050d4:	2905                	addiw	s2,s2,1
  while(i < n){
    800050d6:	05495063          	bge	s2,s4,80005116 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    800050da:	2204a783          	lw	a5,544(s1)
    800050de:	dfd1                	beqz	a5,8000507a <pipewrite+0x48>
    800050e0:	854e                	mv	a0,s3
    800050e2:	ffffd097          	auipc	ra,0xffffd
    800050e6:	742080e7          	jalr	1858(ra) # 80002824 <killed>
    800050ea:	f941                	bnez	a0,8000507a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050ec:	2184a783          	lw	a5,536(s1)
    800050f0:	21c4a703          	lw	a4,540(s1)
    800050f4:	2007879b          	addiw	a5,a5,512
    800050f8:	faf705e3          	beq	a4,a5,800050a2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050fc:	4685                	li	a3,1
    800050fe:	01590633          	add	a2,s2,s5
    80005102:	f9f40593          	addi	a1,s0,-97
    80005106:	0509b503          	ld	a0,80(s3)
    8000510a:	ffffc097          	auipc	ra,0xffffc
    8000510e:	606080e7          	jalr	1542(ra) # 80001710 <copyin>
    80005112:	fb6514e3          	bne	a0,s6,800050ba <pipewrite+0x88>
  wakeup(&pi->nread);
    80005116:	21848513          	addi	a0,s1,536
    8000511a:	ffffd097          	auipc	ra,0xffffd
    8000511e:	4c6080e7          	jalr	1222(ra) # 800025e0 <wakeup>
  release(&pi->lock);
    80005122:	8526                	mv	a0,s1
    80005124:	ffffc097          	auipc	ra,0xffffc
    80005128:	b7a080e7          	jalr	-1158(ra) # 80000c9e <release>
  return i;
    8000512c:	bfa9                	j	80005086 <pipewrite+0x54>
  int i = 0;
    8000512e:	4901                	li	s2,0
    80005130:	b7dd                	j	80005116 <pipewrite+0xe4>

0000000080005132 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005132:	715d                	addi	sp,sp,-80
    80005134:	e486                	sd	ra,72(sp)
    80005136:	e0a2                	sd	s0,64(sp)
    80005138:	fc26                	sd	s1,56(sp)
    8000513a:	f84a                	sd	s2,48(sp)
    8000513c:	f44e                	sd	s3,40(sp)
    8000513e:	f052                	sd	s4,32(sp)
    80005140:	ec56                	sd	s5,24(sp)
    80005142:	e85a                	sd	s6,16(sp)
    80005144:	0880                	addi	s0,sp,80
    80005146:	84aa                	mv	s1,a0
    80005148:	892e                	mv	s2,a1
    8000514a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000514c:	ffffd097          	auipc	ra,0xffffd
    80005150:	982080e7          	jalr	-1662(ra) # 80001ace <myproc>
    80005154:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005156:	8b26                	mv	s6,s1
    80005158:	8526                	mv	a0,s1
    8000515a:	ffffc097          	auipc	ra,0xffffc
    8000515e:	a90080e7          	jalr	-1392(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005162:	2184a703          	lw	a4,536(s1)
    80005166:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000516a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000516e:	02f71763          	bne	a4,a5,8000519c <piperead+0x6a>
    80005172:	2244a783          	lw	a5,548(s1)
    80005176:	c39d                	beqz	a5,8000519c <piperead+0x6a>
    if(killed(pr)){
    80005178:	8552                	mv	a0,s4
    8000517a:	ffffd097          	auipc	ra,0xffffd
    8000517e:	6aa080e7          	jalr	1706(ra) # 80002824 <killed>
    80005182:	e941                	bnez	a0,80005212 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005184:	85da                	mv	a1,s6
    80005186:	854e                	mv	a0,s3
    80005188:	ffffd097          	auipc	ra,0xffffd
    8000518c:	3f4080e7          	jalr	1012(ra) # 8000257c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005190:	2184a703          	lw	a4,536(s1)
    80005194:	21c4a783          	lw	a5,540(s1)
    80005198:	fcf70de3          	beq	a4,a5,80005172 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000519c:	09505263          	blez	s5,80005220 <piperead+0xee>
    800051a0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051a2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800051a4:	2184a783          	lw	a5,536(s1)
    800051a8:	21c4a703          	lw	a4,540(s1)
    800051ac:	02f70d63          	beq	a4,a5,800051e6 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051b0:	0017871b          	addiw	a4,a5,1
    800051b4:	20e4ac23          	sw	a4,536(s1)
    800051b8:	1ff7f793          	andi	a5,a5,511
    800051bc:	97a6                	add	a5,a5,s1
    800051be:	0187c783          	lbu	a5,24(a5)
    800051c2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051c6:	4685                	li	a3,1
    800051c8:	fbf40613          	addi	a2,s0,-65
    800051cc:	85ca                	mv	a1,s2
    800051ce:	050a3503          	ld	a0,80(s4)
    800051d2:	ffffc097          	auipc	ra,0xffffc
    800051d6:	4b2080e7          	jalr	1202(ra) # 80001684 <copyout>
    800051da:	01650663          	beq	a0,s6,800051e6 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051de:	2985                	addiw	s3,s3,1
    800051e0:	0905                	addi	s2,s2,1
    800051e2:	fd3a91e3          	bne	s5,s3,800051a4 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051e6:	21c48513          	addi	a0,s1,540
    800051ea:	ffffd097          	auipc	ra,0xffffd
    800051ee:	3f6080e7          	jalr	1014(ra) # 800025e0 <wakeup>
  release(&pi->lock);
    800051f2:	8526                	mv	a0,s1
    800051f4:	ffffc097          	auipc	ra,0xffffc
    800051f8:	aaa080e7          	jalr	-1366(ra) # 80000c9e <release>
  return i;
}
    800051fc:	854e                	mv	a0,s3
    800051fe:	60a6                	ld	ra,72(sp)
    80005200:	6406                	ld	s0,64(sp)
    80005202:	74e2                	ld	s1,56(sp)
    80005204:	7942                	ld	s2,48(sp)
    80005206:	79a2                	ld	s3,40(sp)
    80005208:	7a02                	ld	s4,32(sp)
    8000520a:	6ae2                	ld	s5,24(sp)
    8000520c:	6b42                	ld	s6,16(sp)
    8000520e:	6161                	addi	sp,sp,80
    80005210:	8082                	ret
      release(&pi->lock);
    80005212:	8526                	mv	a0,s1
    80005214:	ffffc097          	auipc	ra,0xffffc
    80005218:	a8a080e7          	jalr	-1398(ra) # 80000c9e <release>
      return -1;
    8000521c:	59fd                	li	s3,-1
    8000521e:	bff9                	j	800051fc <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005220:	4981                	li	s3,0
    80005222:	b7d1                	j	800051e6 <piperead+0xb4>

0000000080005224 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005224:	1141                	addi	sp,sp,-16
    80005226:	e422                	sd	s0,8(sp)
    80005228:	0800                	addi	s0,sp,16
    8000522a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000522c:	8905                	andi	a0,a0,1
    8000522e:	c111                	beqz	a0,80005232 <flags2perm+0xe>
      perm = PTE_X;
    80005230:	4521                	li	a0,8
    if(flags & 0x2)
    80005232:	8b89                	andi	a5,a5,2
    80005234:	c399                	beqz	a5,8000523a <flags2perm+0x16>
      perm |= PTE_W;
    80005236:	00456513          	ori	a0,a0,4
    return perm;
}
    8000523a:	6422                	ld	s0,8(sp)
    8000523c:	0141                	addi	sp,sp,16
    8000523e:	8082                	ret

0000000080005240 <exec>:

int
exec(char *path, char **argv)
{
    80005240:	df010113          	addi	sp,sp,-528
    80005244:	20113423          	sd	ra,520(sp)
    80005248:	20813023          	sd	s0,512(sp)
    8000524c:	ffa6                	sd	s1,504(sp)
    8000524e:	fbca                	sd	s2,496(sp)
    80005250:	f7ce                	sd	s3,488(sp)
    80005252:	f3d2                	sd	s4,480(sp)
    80005254:	efd6                	sd	s5,472(sp)
    80005256:	ebda                	sd	s6,464(sp)
    80005258:	e7de                	sd	s7,456(sp)
    8000525a:	e3e2                	sd	s8,448(sp)
    8000525c:	ff66                	sd	s9,440(sp)
    8000525e:	fb6a                	sd	s10,432(sp)
    80005260:	f76e                	sd	s11,424(sp)
    80005262:	0c00                	addi	s0,sp,528
    80005264:	84aa                	mv	s1,a0
    80005266:	dea43c23          	sd	a0,-520(s0)
    8000526a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000526e:	ffffd097          	auipc	ra,0xffffd
    80005272:	860080e7          	jalr	-1952(ra) # 80001ace <myproc>
    80005276:	892a                	mv	s2,a0

  begin_op();
    80005278:	fffff097          	auipc	ra,0xfffff
    8000527c:	474080e7          	jalr	1140(ra) # 800046ec <begin_op>

  if((ip = namei(path)) == 0){
    80005280:	8526                	mv	a0,s1
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	24e080e7          	jalr	590(ra) # 800044d0 <namei>
    8000528a:	c92d                	beqz	a0,800052fc <exec+0xbc>
    8000528c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	a9c080e7          	jalr	-1380(ra) # 80003d2a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005296:	04000713          	li	a4,64
    8000529a:	4681                	li	a3,0
    8000529c:	e5040613          	addi	a2,s0,-432
    800052a0:	4581                	li	a1,0
    800052a2:	8526                	mv	a0,s1
    800052a4:	fffff097          	auipc	ra,0xfffff
    800052a8:	d3a080e7          	jalr	-710(ra) # 80003fde <readi>
    800052ac:	04000793          	li	a5,64
    800052b0:	00f51a63          	bne	a0,a5,800052c4 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800052b4:	e5042703          	lw	a4,-432(s0)
    800052b8:	464c47b7          	lui	a5,0x464c4
    800052bc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052c0:	04f70463          	beq	a4,a5,80005308 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052c4:	8526                	mv	a0,s1
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	cc6080e7          	jalr	-826(ra) # 80003f8c <iunlockput>
    end_op();
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	49e080e7          	jalr	1182(ra) # 8000476c <end_op>
  }
  return -1;
    800052d6:	557d                	li	a0,-1
}
    800052d8:	20813083          	ld	ra,520(sp)
    800052dc:	20013403          	ld	s0,512(sp)
    800052e0:	74fe                	ld	s1,504(sp)
    800052e2:	795e                	ld	s2,496(sp)
    800052e4:	79be                	ld	s3,488(sp)
    800052e6:	7a1e                	ld	s4,480(sp)
    800052e8:	6afe                	ld	s5,472(sp)
    800052ea:	6b5e                	ld	s6,464(sp)
    800052ec:	6bbe                	ld	s7,456(sp)
    800052ee:	6c1e                	ld	s8,448(sp)
    800052f0:	7cfa                	ld	s9,440(sp)
    800052f2:	7d5a                	ld	s10,432(sp)
    800052f4:	7dba                	ld	s11,424(sp)
    800052f6:	21010113          	addi	sp,sp,528
    800052fa:	8082                	ret
    end_op();
    800052fc:	fffff097          	auipc	ra,0xfffff
    80005300:	470080e7          	jalr	1136(ra) # 8000476c <end_op>
    return -1;
    80005304:	557d                	li	a0,-1
    80005306:	bfc9                	j	800052d8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005308:	854a                	mv	a0,s2
    8000530a:	ffffd097          	auipc	ra,0xffffd
    8000530e:	888080e7          	jalr	-1912(ra) # 80001b92 <proc_pagetable>
    80005312:	8baa                	mv	s7,a0
    80005314:	d945                	beqz	a0,800052c4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005316:	e7042983          	lw	s3,-400(s0)
    8000531a:	e8845783          	lhu	a5,-376(s0)
    8000531e:	c7ad                	beqz	a5,80005388 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005320:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005322:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005324:	6c85                	lui	s9,0x1
    80005326:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000532a:	def43823          	sd	a5,-528(s0)
    8000532e:	ac0d                	j	80005560 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005330:	00003517          	auipc	a0,0x3
    80005334:	49850513          	addi	a0,a0,1176 # 800087c8 <syscalls+0x298>
    80005338:	ffffb097          	auipc	ra,0xffffb
    8000533c:	20c080e7          	jalr	524(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005340:	8756                	mv	a4,s5
    80005342:	012d86bb          	addw	a3,s11,s2
    80005346:	4581                	li	a1,0
    80005348:	8526                	mv	a0,s1
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	c94080e7          	jalr	-876(ra) # 80003fde <readi>
    80005352:	2501                	sext.w	a0,a0
    80005354:	1aaa9a63          	bne	s5,a0,80005508 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80005358:	6785                	lui	a5,0x1
    8000535a:	0127893b          	addw	s2,a5,s2
    8000535e:	77fd                	lui	a5,0xfffff
    80005360:	01478a3b          	addw	s4,a5,s4
    80005364:	1f897563          	bgeu	s2,s8,8000554e <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80005368:	02091593          	slli	a1,s2,0x20
    8000536c:	9181                	srli	a1,a1,0x20
    8000536e:	95ea                	add	a1,a1,s10
    80005370:	855e                	mv	a0,s7
    80005372:	ffffc097          	auipc	ra,0xffffc
    80005376:	d06080e7          	jalr	-762(ra) # 80001078 <walkaddr>
    8000537a:	862a                	mv	a2,a0
    if(pa == 0)
    8000537c:	d955                	beqz	a0,80005330 <exec+0xf0>
      n = PGSIZE;
    8000537e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005380:	fd9a70e3          	bgeu	s4,s9,80005340 <exec+0x100>
      n = sz - i;
    80005384:	8ad2                	mv	s5,s4
    80005386:	bf6d                	j	80005340 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005388:	4a01                	li	s4,0
  iunlockput(ip);
    8000538a:	8526                	mv	a0,s1
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	c00080e7          	jalr	-1024(ra) # 80003f8c <iunlockput>
  end_op();
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	3d8080e7          	jalr	984(ra) # 8000476c <end_op>
  p = myproc();
    8000539c:	ffffc097          	auipc	ra,0xffffc
    800053a0:	732080e7          	jalr	1842(ra) # 80001ace <myproc>
    800053a4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800053a6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800053aa:	6785                	lui	a5,0x1
    800053ac:	17fd                	addi	a5,a5,-1
    800053ae:	9a3e                	add	s4,s4,a5
    800053b0:	757d                	lui	a0,0xfffff
    800053b2:	00aa77b3          	and	a5,s4,a0
    800053b6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800053ba:	4691                	li	a3,4
    800053bc:	6609                	lui	a2,0x2
    800053be:	963e                	add	a2,a2,a5
    800053c0:	85be                	mv	a1,a5
    800053c2:	855e                	mv	a0,s7
    800053c4:	ffffc097          	auipc	ra,0xffffc
    800053c8:	068080e7          	jalr	104(ra) # 8000142c <uvmalloc>
    800053cc:	8b2a                	mv	s6,a0
  ip = 0;
    800053ce:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800053d0:	12050c63          	beqz	a0,80005508 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053d4:	75f9                	lui	a1,0xffffe
    800053d6:	95aa                	add	a1,a1,a0
    800053d8:	855e                	mv	a0,s7
    800053da:	ffffc097          	auipc	ra,0xffffc
    800053de:	278080e7          	jalr	632(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    800053e2:	7c7d                	lui	s8,0xfffff
    800053e4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800053e6:	e0043783          	ld	a5,-512(s0)
    800053ea:	6388                	ld	a0,0(a5)
    800053ec:	c535                	beqz	a0,80005458 <exec+0x218>
    800053ee:	e9040993          	addi	s3,s0,-368
    800053f2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053f6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800053f8:	ffffc097          	auipc	ra,0xffffc
    800053fc:	a72080e7          	jalr	-1422(ra) # 80000e6a <strlen>
    80005400:	2505                	addiw	a0,a0,1
    80005402:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005406:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000540a:	13896663          	bltu	s2,s8,80005536 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000540e:	e0043d83          	ld	s11,-512(s0)
    80005412:	000dba03          	ld	s4,0(s11)
    80005416:	8552                	mv	a0,s4
    80005418:	ffffc097          	auipc	ra,0xffffc
    8000541c:	a52080e7          	jalr	-1454(ra) # 80000e6a <strlen>
    80005420:	0015069b          	addiw	a3,a0,1
    80005424:	8652                	mv	a2,s4
    80005426:	85ca                	mv	a1,s2
    80005428:	855e                	mv	a0,s7
    8000542a:	ffffc097          	auipc	ra,0xffffc
    8000542e:	25a080e7          	jalr	602(ra) # 80001684 <copyout>
    80005432:	10054663          	bltz	a0,8000553e <exec+0x2fe>
    ustack[argc] = sp;
    80005436:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000543a:	0485                	addi	s1,s1,1
    8000543c:	008d8793          	addi	a5,s11,8
    80005440:	e0f43023          	sd	a5,-512(s0)
    80005444:	008db503          	ld	a0,8(s11)
    80005448:	c911                	beqz	a0,8000545c <exec+0x21c>
    if(argc >= MAXARG)
    8000544a:	09a1                	addi	s3,s3,8
    8000544c:	fb3c96e3          	bne	s9,s3,800053f8 <exec+0x1b8>
  sz = sz1;
    80005450:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005454:	4481                	li	s1,0
    80005456:	a84d                	j	80005508 <exec+0x2c8>
  sp = sz;
    80005458:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000545a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000545c:	00349793          	slli	a5,s1,0x3
    80005460:	f9040713          	addi	a4,s0,-112
    80005464:	97ba                	add	a5,a5,a4
    80005466:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000546a:	00148693          	addi	a3,s1,1
    8000546e:	068e                	slli	a3,a3,0x3
    80005470:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005474:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005478:	01897663          	bgeu	s2,s8,80005484 <exec+0x244>
  sz = sz1;
    8000547c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005480:	4481                	li	s1,0
    80005482:	a059                	j	80005508 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005484:	e9040613          	addi	a2,s0,-368
    80005488:	85ca                	mv	a1,s2
    8000548a:	855e                	mv	a0,s7
    8000548c:	ffffc097          	auipc	ra,0xffffc
    80005490:	1f8080e7          	jalr	504(ra) # 80001684 <copyout>
    80005494:	0a054963          	bltz	a0,80005546 <exec+0x306>
  p->trapframe->a1 = sp;
    80005498:	058ab783          	ld	a5,88(s5)
    8000549c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800054a0:	df843783          	ld	a5,-520(s0)
    800054a4:	0007c703          	lbu	a4,0(a5)
    800054a8:	cf11                	beqz	a4,800054c4 <exec+0x284>
    800054aa:	0785                	addi	a5,a5,1
    if(*s == '/')
    800054ac:	02f00693          	li	a3,47
    800054b0:	a039                	j	800054be <exec+0x27e>
      last = s+1;
    800054b2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800054b6:	0785                	addi	a5,a5,1
    800054b8:	fff7c703          	lbu	a4,-1(a5)
    800054bc:	c701                	beqz	a4,800054c4 <exec+0x284>
    if(*s == '/')
    800054be:	fed71ce3          	bne	a4,a3,800054b6 <exec+0x276>
    800054c2:	bfc5                	j	800054b2 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    800054c4:	4641                	li	a2,16
    800054c6:	df843583          	ld	a1,-520(s0)
    800054ca:	158a8513          	addi	a0,s5,344
    800054ce:	ffffc097          	auipc	ra,0xffffc
    800054d2:	96a080e7          	jalr	-1686(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    800054d6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800054da:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800054de:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054e2:	058ab783          	ld	a5,88(s5)
    800054e6:	e6843703          	ld	a4,-408(s0)
    800054ea:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054ec:	058ab783          	ld	a5,88(s5)
    800054f0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054f4:	85ea                	mv	a1,s10
    800054f6:	ffffc097          	auipc	ra,0xffffc
    800054fa:	738080e7          	jalr	1848(ra) # 80001c2e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054fe:	0004851b          	sext.w	a0,s1
    80005502:	bbd9                	j	800052d8 <exec+0x98>
    80005504:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005508:	e0843583          	ld	a1,-504(s0)
    8000550c:	855e                	mv	a0,s7
    8000550e:	ffffc097          	auipc	ra,0xffffc
    80005512:	720080e7          	jalr	1824(ra) # 80001c2e <proc_freepagetable>
  if(ip){
    80005516:	da0497e3          	bnez	s1,800052c4 <exec+0x84>
  return -1;
    8000551a:	557d                	li	a0,-1
    8000551c:	bb75                	j	800052d8 <exec+0x98>
    8000551e:	e1443423          	sd	s4,-504(s0)
    80005522:	b7dd                	j	80005508 <exec+0x2c8>
    80005524:	e1443423          	sd	s4,-504(s0)
    80005528:	b7c5                	j	80005508 <exec+0x2c8>
    8000552a:	e1443423          	sd	s4,-504(s0)
    8000552e:	bfe9                	j	80005508 <exec+0x2c8>
    80005530:	e1443423          	sd	s4,-504(s0)
    80005534:	bfd1                	j	80005508 <exec+0x2c8>
  sz = sz1;
    80005536:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000553a:	4481                	li	s1,0
    8000553c:	b7f1                	j	80005508 <exec+0x2c8>
  sz = sz1;
    8000553e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005542:	4481                	li	s1,0
    80005544:	b7d1                	j	80005508 <exec+0x2c8>
  sz = sz1;
    80005546:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000554a:	4481                	li	s1,0
    8000554c:	bf75                	j	80005508 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000554e:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005552:	2b05                	addiw	s6,s6,1
    80005554:	0389899b          	addiw	s3,s3,56
    80005558:	e8845783          	lhu	a5,-376(s0)
    8000555c:	e2fb57e3          	bge	s6,a5,8000538a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005560:	2981                	sext.w	s3,s3
    80005562:	03800713          	li	a4,56
    80005566:	86ce                	mv	a3,s3
    80005568:	e1840613          	addi	a2,s0,-488
    8000556c:	4581                	li	a1,0
    8000556e:	8526                	mv	a0,s1
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	a6e080e7          	jalr	-1426(ra) # 80003fde <readi>
    80005578:	03800793          	li	a5,56
    8000557c:	f8f514e3          	bne	a0,a5,80005504 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005580:	e1842783          	lw	a5,-488(s0)
    80005584:	4705                	li	a4,1
    80005586:	fce796e3          	bne	a5,a4,80005552 <exec+0x312>
    if(ph.memsz < ph.filesz)
    8000558a:	e4043903          	ld	s2,-448(s0)
    8000558e:	e3843783          	ld	a5,-456(s0)
    80005592:	f8f966e3          	bltu	s2,a5,8000551e <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005596:	e2843783          	ld	a5,-472(s0)
    8000559a:	993e                	add	s2,s2,a5
    8000559c:	f8f964e3          	bltu	s2,a5,80005524 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    800055a0:	df043703          	ld	a4,-528(s0)
    800055a4:	8ff9                	and	a5,a5,a4
    800055a6:	f3d1                	bnez	a5,8000552a <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055a8:	e1c42503          	lw	a0,-484(s0)
    800055ac:	00000097          	auipc	ra,0x0
    800055b0:	c78080e7          	jalr	-904(ra) # 80005224 <flags2perm>
    800055b4:	86aa                	mv	a3,a0
    800055b6:	864a                	mv	a2,s2
    800055b8:	85d2                	mv	a1,s4
    800055ba:	855e                	mv	a0,s7
    800055bc:	ffffc097          	auipc	ra,0xffffc
    800055c0:	e70080e7          	jalr	-400(ra) # 8000142c <uvmalloc>
    800055c4:	e0a43423          	sd	a0,-504(s0)
    800055c8:	d525                	beqz	a0,80005530 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800055ca:	e2843d03          	ld	s10,-472(s0)
    800055ce:	e2042d83          	lw	s11,-480(s0)
    800055d2:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800055d6:	f60c0ce3          	beqz	s8,8000554e <exec+0x30e>
    800055da:	8a62                	mv	s4,s8
    800055dc:	4901                	li	s2,0
    800055de:	b369                	j	80005368 <exec+0x128>

00000000800055e0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055e0:	7179                	addi	sp,sp,-48
    800055e2:	f406                	sd	ra,40(sp)
    800055e4:	f022                	sd	s0,32(sp)
    800055e6:	ec26                	sd	s1,24(sp)
    800055e8:	e84a                	sd	s2,16(sp)
    800055ea:	1800                	addi	s0,sp,48
    800055ec:	892e                	mv	s2,a1
    800055ee:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800055f0:	fdc40593          	addi	a1,s0,-36
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	b3a080e7          	jalr	-1222(ra) # 8000312e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055fc:	fdc42703          	lw	a4,-36(s0)
    80005600:	47bd                	li	a5,15
    80005602:	02e7eb63          	bltu	a5,a4,80005638 <argfd+0x58>
    80005606:	ffffc097          	auipc	ra,0xffffc
    8000560a:	4c8080e7          	jalr	1224(ra) # 80001ace <myproc>
    8000560e:	fdc42703          	lw	a4,-36(s0)
    80005612:	01a70793          	addi	a5,a4,26
    80005616:	078e                	slli	a5,a5,0x3
    80005618:	953e                	add	a0,a0,a5
    8000561a:	611c                	ld	a5,0(a0)
    8000561c:	c385                	beqz	a5,8000563c <argfd+0x5c>
    return -1;
  if(pfd)
    8000561e:	00090463          	beqz	s2,80005626 <argfd+0x46>
    *pfd = fd;
    80005622:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005626:	4501                	li	a0,0
  if(pf)
    80005628:	c091                	beqz	s1,8000562c <argfd+0x4c>
    *pf = f;
    8000562a:	e09c                	sd	a5,0(s1)
}
    8000562c:	70a2                	ld	ra,40(sp)
    8000562e:	7402                	ld	s0,32(sp)
    80005630:	64e2                	ld	s1,24(sp)
    80005632:	6942                	ld	s2,16(sp)
    80005634:	6145                	addi	sp,sp,48
    80005636:	8082                	ret
    return -1;
    80005638:	557d                	li	a0,-1
    8000563a:	bfcd                	j	8000562c <argfd+0x4c>
    8000563c:	557d                	li	a0,-1
    8000563e:	b7fd                	j	8000562c <argfd+0x4c>

0000000080005640 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005640:	1101                	addi	sp,sp,-32
    80005642:	ec06                	sd	ra,24(sp)
    80005644:	e822                	sd	s0,16(sp)
    80005646:	e426                	sd	s1,8(sp)
    80005648:	1000                	addi	s0,sp,32
    8000564a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000564c:	ffffc097          	auipc	ra,0xffffc
    80005650:	482080e7          	jalr	1154(ra) # 80001ace <myproc>
    80005654:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005656:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdcc00>
    8000565a:	4501                	li	a0,0
    8000565c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000565e:	6398                	ld	a4,0(a5)
    80005660:	cb19                	beqz	a4,80005676 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005662:	2505                	addiw	a0,a0,1
    80005664:	07a1                	addi	a5,a5,8
    80005666:	fed51ce3          	bne	a0,a3,8000565e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000566a:	557d                	li	a0,-1
}
    8000566c:	60e2                	ld	ra,24(sp)
    8000566e:	6442                	ld	s0,16(sp)
    80005670:	64a2                	ld	s1,8(sp)
    80005672:	6105                	addi	sp,sp,32
    80005674:	8082                	ret
      p->ofile[fd] = f;
    80005676:	01a50793          	addi	a5,a0,26
    8000567a:	078e                	slli	a5,a5,0x3
    8000567c:	963e                	add	a2,a2,a5
    8000567e:	e204                	sd	s1,0(a2)
      return fd;
    80005680:	b7f5                	j	8000566c <fdalloc+0x2c>

0000000080005682 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005682:	715d                	addi	sp,sp,-80
    80005684:	e486                	sd	ra,72(sp)
    80005686:	e0a2                	sd	s0,64(sp)
    80005688:	fc26                	sd	s1,56(sp)
    8000568a:	f84a                	sd	s2,48(sp)
    8000568c:	f44e                	sd	s3,40(sp)
    8000568e:	f052                	sd	s4,32(sp)
    80005690:	ec56                	sd	s5,24(sp)
    80005692:	e85a                	sd	s6,16(sp)
    80005694:	0880                	addi	s0,sp,80
    80005696:	8b2e                	mv	s6,a1
    80005698:	89b2                	mv	s3,a2
    8000569a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000569c:	fb040593          	addi	a1,s0,-80
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	e4e080e7          	jalr	-434(ra) # 800044ee <nameiparent>
    800056a8:	84aa                	mv	s1,a0
    800056aa:	16050063          	beqz	a0,8000580a <create+0x188>
    return 0;

  ilock(dp);
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	67c080e7          	jalr	1660(ra) # 80003d2a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800056b6:	4601                	li	a2,0
    800056b8:	fb040593          	addi	a1,s0,-80
    800056bc:	8526                	mv	a0,s1
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	b50080e7          	jalr	-1200(ra) # 8000420e <dirlookup>
    800056c6:	8aaa                	mv	s5,a0
    800056c8:	c931                	beqz	a0,8000571c <create+0x9a>
    iunlockput(dp);
    800056ca:	8526                	mv	a0,s1
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	8c0080e7          	jalr	-1856(ra) # 80003f8c <iunlockput>
    ilock(ip);
    800056d4:	8556                	mv	a0,s5
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	654080e7          	jalr	1620(ra) # 80003d2a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056de:	000b059b          	sext.w	a1,s6
    800056e2:	4789                	li	a5,2
    800056e4:	02f59563          	bne	a1,a5,8000570e <create+0x8c>
    800056e8:	044ad783          	lhu	a5,68(s5)
    800056ec:	37f9                	addiw	a5,a5,-2
    800056ee:	17c2                	slli	a5,a5,0x30
    800056f0:	93c1                	srli	a5,a5,0x30
    800056f2:	4705                	li	a4,1
    800056f4:	00f76d63          	bltu	a4,a5,8000570e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800056f8:	8556                	mv	a0,s5
    800056fa:	60a6                	ld	ra,72(sp)
    800056fc:	6406                	ld	s0,64(sp)
    800056fe:	74e2                	ld	s1,56(sp)
    80005700:	7942                	ld	s2,48(sp)
    80005702:	79a2                	ld	s3,40(sp)
    80005704:	7a02                	ld	s4,32(sp)
    80005706:	6ae2                	ld	s5,24(sp)
    80005708:	6b42                	ld	s6,16(sp)
    8000570a:	6161                	addi	sp,sp,80
    8000570c:	8082                	ret
    iunlockput(ip);
    8000570e:	8556                	mv	a0,s5
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	87c080e7          	jalr	-1924(ra) # 80003f8c <iunlockput>
    return 0;
    80005718:	4a81                	li	s5,0
    8000571a:	bff9                	j	800056f8 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000571c:	85da                	mv	a1,s6
    8000571e:	4088                	lw	a0,0(s1)
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	46e080e7          	jalr	1134(ra) # 80003b8e <ialloc>
    80005728:	8a2a                	mv	s4,a0
    8000572a:	c921                	beqz	a0,8000577a <create+0xf8>
  ilock(ip);
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	5fe080e7          	jalr	1534(ra) # 80003d2a <ilock>
  ip->major = major;
    80005734:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005738:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000573c:	4785                	li	a5,1
    8000573e:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005742:	8552                	mv	a0,s4
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	51c080e7          	jalr	1308(ra) # 80003c60 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000574c:	000b059b          	sext.w	a1,s6
    80005750:	4785                	li	a5,1
    80005752:	02f58b63          	beq	a1,a5,80005788 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005756:	004a2603          	lw	a2,4(s4)
    8000575a:	fb040593          	addi	a1,s0,-80
    8000575e:	8526                	mv	a0,s1
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	cbe080e7          	jalr	-834(ra) # 8000441e <dirlink>
    80005768:	06054f63          	bltz	a0,800057e6 <create+0x164>
  iunlockput(dp);
    8000576c:	8526                	mv	a0,s1
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	81e080e7          	jalr	-2018(ra) # 80003f8c <iunlockput>
  return ip;
    80005776:	8ad2                	mv	s5,s4
    80005778:	b741                	j	800056f8 <create+0x76>
    iunlockput(dp);
    8000577a:	8526                	mv	a0,s1
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	810080e7          	jalr	-2032(ra) # 80003f8c <iunlockput>
    return 0;
    80005784:	8ad2                	mv	s5,s4
    80005786:	bf8d                	j	800056f8 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005788:	004a2603          	lw	a2,4(s4)
    8000578c:	00003597          	auipc	a1,0x3
    80005790:	05c58593          	addi	a1,a1,92 # 800087e8 <syscalls+0x2b8>
    80005794:	8552                	mv	a0,s4
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	c88080e7          	jalr	-888(ra) # 8000441e <dirlink>
    8000579e:	04054463          	bltz	a0,800057e6 <create+0x164>
    800057a2:	40d0                	lw	a2,4(s1)
    800057a4:	00003597          	auipc	a1,0x3
    800057a8:	04c58593          	addi	a1,a1,76 # 800087f0 <syscalls+0x2c0>
    800057ac:	8552                	mv	a0,s4
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	c70080e7          	jalr	-912(ra) # 8000441e <dirlink>
    800057b6:	02054863          	bltz	a0,800057e6 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800057ba:	004a2603          	lw	a2,4(s4)
    800057be:	fb040593          	addi	a1,s0,-80
    800057c2:	8526                	mv	a0,s1
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	c5a080e7          	jalr	-934(ra) # 8000441e <dirlink>
    800057cc:	00054d63          	bltz	a0,800057e6 <create+0x164>
    dp->nlink++;  // for ".."
    800057d0:	04a4d783          	lhu	a5,74(s1)
    800057d4:	2785                	addiw	a5,a5,1
    800057d6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057da:	8526                	mv	a0,s1
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	484080e7          	jalr	1156(ra) # 80003c60 <iupdate>
    800057e4:	b761                	j	8000576c <create+0xea>
  ip->nlink = 0;
    800057e6:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800057ea:	8552                	mv	a0,s4
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	474080e7          	jalr	1140(ra) # 80003c60 <iupdate>
  iunlockput(ip);
    800057f4:	8552                	mv	a0,s4
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	796080e7          	jalr	1942(ra) # 80003f8c <iunlockput>
  iunlockput(dp);
    800057fe:	8526                	mv	a0,s1
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	78c080e7          	jalr	1932(ra) # 80003f8c <iunlockput>
  return 0;
    80005808:	bdc5                	j	800056f8 <create+0x76>
    return 0;
    8000580a:	8aaa                	mv	s5,a0
    8000580c:	b5f5                	j	800056f8 <create+0x76>

000000008000580e <sys_dup>:
{
    8000580e:	7179                	addi	sp,sp,-48
    80005810:	f406                	sd	ra,40(sp)
    80005812:	f022                	sd	s0,32(sp)
    80005814:	ec26                	sd	s1,24(sp)
    80005816:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005818:	fd840613          	addi	a2,s0,-40
    8000581c:	4581                	li	a1,0
    8000581e:	4501                	li	a0,0
    80005820:	00000097          	auipc	ra,0x0
    80005824:	dc0080e7          	jalr	-576(ra) # 800055e0 <argfd>
    return -1;
    80005828:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000582a:	02054363          	bltz	a0,80005850 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000582e:	fd843503          	ld	a0,-40(s0)
    80005832:	00000097          	auipc	ra,0x0
    80005836:	e0e080e7          	jalr	-498(ra) # 80005640 <fdalloc>
    8000583a:	84aa                	mv	s1,a0
    return -1;
    8000583c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000583e:	00054963          	bltz	a0,80005850 <sys_dup+0x42>
  filedup(f);
    80005842:	fd843503          	ld	a0,-40(s0)
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	320080e7          	jalr	800(ra) # 80004b66 <filedup>
  return fd;
    8000584e:	87a6                	mv	a5,s1
}
    80005850:	853e                	mv	a0,a5
    80005852:	70a2                	ld	ra,40(sp)
    80005854:	7402                	ld	s0,32(sp)
    80005856:	64e2                	ld	s1,24(sp)
    80005858:	6145                	addi	sp,sp,48
    8000585a:	8082                	ret

000000008000585c <sys_read>:
{
    8000585c:	7179                	addi	sp,sp,-48
    8000585e:	f406                	sd	ra,40(sp)
    80005860:	f022                	sd	s0,32(sp)
    80005862:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005864:	fd840593          	addi	a1,s0,-40
    80005868:	4505                	li	a0,1
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	8e4080e7          	jalr	-1820(ra) # 8000314e <argaddr>
  argint(2, &n);
    80005872:	fe440593          	addi	a1,s0,-28
    80005876:	4509                	li	a0,2
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	8b6080e7          	jalr	-1866(ra) # 8000312e <argint>
  if(argfd(0, 0, &f) < 0)
    80005880:	fe840613          	addi	a2,s0,-24
    80005884:	4581                	li	a1,0
    80005886:	4501                	li	a0,0
    80005888:	00000097          	auipc	ra,0x0
    8000588c:	d58080e7          	jalr	-680(ra) # 800055e0 <argfd>
    80005890:	87aa                	mv	a5,a0
    return -1;
    80005892:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005894:	0007cc63          	bltz	a5,800058ac <sys_read+0x50>
  return fileread(f, p, n);
    80005898:	fe442603          	lw	a2,-28(s0)
    8000589c:	fd843583          	ld	a1,-40(s0)
    800058a0:	fe843503          	ld	a0,-24(s0)
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	44e080e7          	jalr	1102(ra) # 80004cf2 <fileread>
}
    800058ac:	70a2                	ld	ra,40(sp)
    800058ae:	7402                	ld	s0,32(sp)
    800058b0:	6145                	addi	sp,sp,48
    800058b2:	8082                	ret

00000000800058b4 <sys_write>:
{
    800058b4:	7179                	addi	sp,sp,-48
    800058b6:	f406                	sd	ra,40(sp)
    800058b8:	f022                	sd	s0,32(sp)
    800058ba:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800058bc:	fd840593          	addi	a1,s0,-40
    800058c0:	4505                	li	a0,1
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	88c080e7          	jalr	-1908(ra) # 8000314e <argaddr>
  argint(2, &n);
    800058ca:	fe440593          	addi	a1,s0,-28
    800058ce:	4509                	li	a0,2
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	85e080e7          	jalr	-1954(ra) # 8000312e <argint>
  if(argfd(0, 0, &f) < 0)
    800058d8:	fe840613          	addi	a2,s0,-24
    800058dc:	4581                	li	a1,0
    800058de:	4501                	li	a0,0
    800058e0:	00000097          	auipc	ra,0x0
    800058e4:	d00080e7          	jalr	-768(ra) # 800055e0 <argfd>
    800058e8:	87aa                	mv	a5,a0
    return -1;
    800058ea:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058ec:	0007cc63          	bltz	a5,80005904 <sys_write+0x50>
  return filewrite(f, p, n);
    800058f0:	fe442603          	lw	a2,-28(s0)
    800058f4:	fd843583          	ld	a1,-40(s0)
    800058f8:	fe843503          	ld	a0,-24(s0)
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	4b8080e7          	jalr	1208(ra) # 80004db4 <filewrite>
}
    80005904:	70a2                	ld	ra,40(sp)
    80005906:	7402                	ld	s0,32(sp)
    80005908:	6145                	addi	sp,sp,48
    8000590a:	8082                	ret

000000008000590c <sys_close>:
{
    8000590c:	1101                	addi	sp,sp,-32
    8000590e:	ec06                	sd	ra,24(sp)
    80005910:	e822                	sd	s0,16(sp)
    80005912:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005914:	fe040613          	addi	a2,s0,-32
    80005918:	fec40593          	addi	a1,s0,-20
    8000591c:	4501                	li	a0,0
    8000591e:	00000097          	auipc	ra,0x0
    80005922:	cc2080e7          	jalr	-830(ra) # 800055e0 <argfd>
    return -1;
    80005926:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005928:	02054463          	bltz	a0,80005950 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000592c:	ffffc097          	auipc	ra,0xffffc
    80005930:	1a2080e7          	jalr	418(ra) # 80001ace <myproc>
    80005934:	fec42783          	lw	a5,-20(s0)
    80005938:	07e9                	addi	a5,a5,26
    8000593a:	078e                	slli	a5,a5,0x3
    8000593c:	97aa                	add	a5,a5,a0
    8000593e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005942:	fe043503          	ld	a0,-32(s0)
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	272080e7          	jalr	626(ra) # 80004bb8 <fileclose>
  return 0;
    8000594e:	4781                	li	a5,0
}
    80005950:	853e                	mv	a0,a5
    80005952:	60e2                	ld	ra,24(sp)
    80005954:	6442                	ld	s0,16(sp)
    80005956:	6105                	addi	sp,sp,32
    80005958:	8082                	ret

000000008000595a <sys_fstat>:
{
    8000595a:	1101                	addi	sp,sp,-32
    8000595c:	ec06                	sd	ra,24(sp)
    8000595e:	e822                	sd	s0,16(sp)
    80005960:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005962:	fe040593          	addi	a1,s0,-32
    80005966:	4505                	li	a0,1
    80005968:	ffffd097          	auipc	ra,0xffffd
    8000596c:	7e6080e7          	jalr	2022(ra) # 8000314e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005970:	fe840613          	addi	a2,s0,-24
    80005974:	4581                	li	a1,0
    80005976:	4501                	li	a0,0
    80005978:	00000097          	auipc	ra,0x0
    8000597c:	c68080e7          	jalr	-920(ra) # 800055e0 <argfd>
    80005980:	87aa                	mv	a5,a0
    return -1;
    80005982:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005984:	0007ca63          	bltz	a5,80005998 <sys_fstat+0x3e>
  return filestat(f, st);
    80005988:	fe043583          	ld	a1,-32(s0)
    8000598c:	fe843503          	ld	a0,-24(s0)
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	2f0080e7          	jalr	752(ra) # 80004c80 <filestat>
}
    80005998:	60e2                	ld	ra,24(sp)
    8000599a:	6442                	ld	s0,16(sp)
    8000599c:	6105                	addi	sp,sp,32
    8000599e:	8082                	ret

00000000800059a0 <sys_link>:
{
    800059a0:	7169                	addi	sp,sp,-304
    800059a2:	f606                	sd	ra,296(sp)
    800059a4:	f222                	sd	s0,288(sp)
    800059a6:	ee26                	sd	s1,280(sp)
    800059a8:	ea4a                	sd	s2,272(sp)
    800059aa:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059ac:	08000613          	li	a2,128
    800059b0:	ed040593          	addi	a1,s0,-304
    800059b4:	4501                	li	a0,0
    800059b6:	ffffd097          	auipc	ra,0xffffd
    800059ba:	7b8080e7          	jalr	1976(ra) # 8000316e <argstr>
    return -1;
    800059be:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059c0:	10054e63          	bltz	a0,80005adc <sys_link+0x13c>
    800059c4:	08000613          	li	a2,128
    800059c8:	f5040593          	addi	a1,s0,-176
    800059cc:	4505                	li	a0,1
    800059ce:	ffffd097          	auipc	ra,0xffffd
    800059d2:	7a0080e7          	jalr	1952(ra) # 8000316e <argstr>
    return -1;
    800059d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059d8:	10054263          	bltz	a0,80005adc <sys_link+0x13c>
  begin_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	d10080e7          	jalr	-752(ra) # 800046ec <begin_op>
  if((ip = namei(old)) == 0){
    800059e4:	ed040513          	addi	a0,s0,-304
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	ae8080e7          	jalr	-1304(ra) # 800044d0 <namei>
    800059f0:	84aa                	mv	s1,a0
    800059f2:	c551                	beqz	a0,80005a7e <sys_link+0xde>
  ilock(ip);
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	336080e7          	jalr	822(ra) # 80003d2a <ilock>
  if(ip->type == T_DIR){
    800059fc:	04449703          	lh	a4,68(s1)
    80005a00:	4785                	li	a5,1
    80005a02:	08f70463          	beq	a4,a5,80005a8a <sys_link+0xea>
  ip->nlink++;
    80005a06:	04a4d783          	lhu	a5,74(s1)
    80005a0a:	2785                	addiw	a5,a5,1
    80005a0c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a10:	8526                	mv	a0,s1
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	24e080e7          	jalr	590(ra) # 80003c60 <iupdate>
  iunlock(ip);
    80005a1a:	8526                	mv	a0,s1
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	3d0080e7          	jalr	976(ra) # 80003dec <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a24:	fd040593          	addi	a1,s0,-48
    80005a28:	f5040513          	addi	a0,s0,-176
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	ac2080e7          	jalr	-1342(ra) # 800044ee <nameiparent>
    80005a34:	892a                	mv	s2,a0
    80005a36:	c935                	beqz	a0,80005aaa <sys_link+0x10a>
  ilock(dp);
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	2f2080e7          	jalr	754(ra) # 80003d2a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a40:	00092703          	lw	a4,0(s2)
    80005a44:	409c                	lw	a5,0(s1)
    80005a46:	04f71d63          	bne	a4,a5,80005aa0 <sys_link+0x100>
    80005a4a:	40d0                	lw	a2,4(s1)
    80005a4c:	fd040593          	addi	a1,s0,-48
    80005a50:	854a                	mv	a0,s2
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	9cc080e7          	jalr	-1588(ra) # 8000441e <dirlink>
    80005a5a:	04054363          	bltz	a0,80005aa0 <sys_link+0x100>
  iunlockput(dp);
    80005a5e:	854a                	mv	a0,s2
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	52c080e7          	jalr	1324(ra) # 80003f8c <iunlockput>
  iput(ip);
    80005a68:	8526                	mv	a0,s1
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	47a080e7          	jalr	1146(ra) # 80003ee4 <iput>
  end_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	cfa080e7          	jalr	-774(ra) # 8000476c <end_op>
  return 0;
    80005a7a:	4781                	li	a5,0
    80005a7c:	a085                	j	80005adc <sys_link+0x13c>
    end_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	cee080e7          	jalr	-786(ra) # 8000476c <end_op>
    return -1;
    80005a86:	57fd                	li	a5,-1
    80005a88:	a891                	j	80005adc <sys_link+0x13c>
    iunlockput(ip);
    80005a8a:	8526                	mv	a0,s1
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	500080e7          	jalr	1280(ra) # 80003f8c <iunlockput>
    end_op();
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	cd8080e7          	jalr	-808(ra) # 8000476c <end_op>
    return -1;
    80005a9c:	57fd                	li	a5,-1
    80005a9e:	a83d                	j	80005adc <sys_link+0x13c>
    iunlockput(dp);
    80005aa0:	854a                	mv	a0,s2
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	4ea080e7          	jalr	1258(ra) # 80003f8c <iunlockput>
  ilock(ip);
    80005aaa:	8526                	mv	a0,s1
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	27e080e7          	jalr	638(ra) # 80003d2a <ilock>
  ip->nlink--;
    80005ab4:	04a4d783          	lhu	a5,74(s1)
    80005ab8:	37fd                	addiw	a5,a5,-1
    80005aba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005abe:	8526                	mv	a0,s1
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	1a0080e7          	jalr	416(ra) # 80003c60 <iupdate>
  iunlockput(ip);
    80005ac8:	8526                	mv	a0,s1
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	4c2080e7          	jalr	1218(ra) # 80003f8c <iunlockput>
  end_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	c9a080e7          	jalr	-870(ra) # 8000476c <end_op>
  return -1;
    80005ada:	57fd                	li	a5,-1
}
    80005adc:	853e                	mv	a0,a5
    80005ade:	70b2                	ld	ra,296(sp)
    80005ae0:	7412                	ld	s0,288(sp)
    80005ae2:	64f2                	ld	s1,280(sp)
    80005ae4:	6952                	ld	s2,272(sp)
    80005ae6:	6155                	addi	sp,sp,304
    80005ae8:	8082                	ret

0000000080005aea <sys_unlink>:
{
    80005aea:	7151                	addi	sp,sp,-240
    80005aec:	f586                	sd	ra,232(sp)
    80005aee:	f1a2                	sd	s0,224(sp)
    80005af0:	eda6                	sd	s1,216(sp)
    80005af2:	e9ca                	sd	s2,208(sp)
    80005af4:	e5ce                	sd	s3,200(sp)
    80005af6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005af8:	08000613          	li	a2,128
    80005afc:	f3040593          	addi	a1,s0,-208
    80005b00:	4501                	li	a0,0
    80005b02:	ffffd097          	auipc	ra,0xffffd
    80005b06:	66c080e7          	jalr	1644(ra) # 8000316e <argstr>
    80005b0a:	18054163          	bltz	a0,80005c8c <sys_unlink+0x1a2>
  begin_op();
    80005b0e:	fffff097          	auipc	ra,0xfffff
    80005b12:	bde080e7          	jalr	-1058(ra) # 800046ec <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b16:	fb040593          	addi	a1,s0,-80
    80005b1a:	f3040513          	addi	a0,s0,-208
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	9d0080e7          	jalr	-1584(ra) # 800044ee <nameiparent>
    80005b26:	84aa                	mv	s1,a0
    80005b28:	c979                	beqz	a0,80005bfe <sys_unlink+0x114>
  ilock(dp);
    80005b2a:	ffffe097          	auipc	ra,0xffffe
    80005b2e:	200080e7          	jalr	512(ra) # 80003d2a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b32:	00003597          	auipc	a1,0x3
    80005b36:	cb658593          	addi	a1,a1,-842 # 800087e8 <syscalls+0x2b8>
    80005b3a:	fb040513          	addi	a0,s0,-80
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	6b6080e7          	jalr	1718(ra) # 800041f4 <namecmp>
    80005b46:	14050a63          	beqz	a0,80005c9a <sys_unlink+0x1b0>
    80005b4a:	00003597          	auipc	a1,0x3
    80005b4e:	ca658593          	addi	a1,a1,-858 # 800087f0 <syscalls+0x2c0>
    80005b52:	fb040513          	addi	a0,s0,-80
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	69e080e7          	jalr	1694(ra) # 800041f4 <namecmp>
    80005b5e:	12050e63          	beqz	a0,80005c9a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b62:	f2c40613          	addi	a2,s0,-212
    80005b66:	fb040593          	addi	a1,s0,-80
    80005b6a:	8526                	mv	a0,s1
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	6a2080e7          	jalr	1698(ra) # 8000420e <dirlookup>
    80005b74:	892a                	mv	s2,a0
    80005b76:	12050263          	beqz	a0,80005c9a <sys_unlink+0x1b0>
  ilock(ip);
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	1b0080e7          	jalr	432(ra) # 80003d2a <ilock>
  if(ip->nlink < 1)
    80005b82:	04a91783          	lh	a5,74(s2)
    80005b86:	08f05263          	blez	a5,80005c0a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b8a:	04491703          	lh	a4,68(s2)
    80005b8e:	4785                	li	a5,1
    80005b90:	08f70563          	beq	a4,a5,80005c1a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b94:	4641                	li	a2,16
    80005b96:	4581                	li	a1,0
    80005b98:	fc040513          	addi	a0,s0,-64
    80005b9c:	ffffb097          	auipc	ra,0xffffb
    80005ba0:	14a080e7          	jalr	330(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ba4:	4741                	li	a4,16
    80005ba6:	f2c42683          	lw	a3,-212(s0)
    80005baa:	fc040613          	addi	a2,s0,-64
    80005bae:	4581                	li	a1,0
    80005bb0:	8526                	mv	a0,s1
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	524080e7          	jalr	1316(ra) # 800040d6 <writei>
    80005bba:	47c1                	li	a5,16
    80005bbc:	0af51563          	bne	a0,a5,80005c66 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005bc0:	04491703          	lh	a4,68(s2)
    80005bc4:	4785                	li	a5,1
    80005bc6:	0af70863          	beq	a4,a5,80005c76 <sys_unlink+0x18c>
  iunlockput(dp);
    80005bca:	8526                	mv	a0,s1
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	3c0080e7          	jalr	960(ra) # 80003f8c <iunlockput>
  ip->nlink--;
    80005bd4:	04a95783          	lhu	a5,74(s2)
    80005bd8:	37fd                	addiw	a5,a5,-1
    80005bda:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005bde:	854a                	mv	a0,s2
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	080080e7          	jalr	128(ra) # 80003c60 <iupdate>
  iunlockput(ip);
    80005be8:	854a                	mv	a0,s2
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	3a2080e7          	jalr	930(ra) # 80003f8c <iunlockput>
  end_op();
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	b7a080e7          	jalr	-1158(ra) # 8000476c <end_op>
  return 0;
    80005bfa:	4501                	li	a0,0
    80005bfc:	a84d                	j	80005cae <sys_unlink+0x1c4>
    end_op();
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	b6e080e7          	jalr	-1170(ra) # 8000476c <end_op>
    return -1;
    80005c06:	557d                	li	a0,-1
    80005c08:	a05d                	j	80005cae <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c0a:	00003517          	auipc	a0,0x3
    80005c0e:	bee50513          	addi	a0,a0,-1042 # 800087f8 <syscalls+0x2c8>
    80005c12:	ffffb097          	auipc	ra,0xffffb
    80005c16:	932080e7          	jalr	-1742(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c1a:	04c92703          	lw	a4,76(s2)
    80005c1e:	02000793          	li	a5,32
    80005c22:	f6e7f9e3          	bgeu	a5,a4,80005b94 <sys_unlink+0xaa>
    80005c26:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c2a:	4741                	li	a4,16
    80005c2c:	86ce                	mv	a3,s3
    80005c2e:	f1840613          	addi	a2,s0,-232
    80005c32:	4581                	li	a1,0
    80005c34:	854a                	mv	a0,s2
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	3a8080e7          	jalr	936(ra) # 80003fde <readi>
    80005c3e:	47c1                	li	a5,16
    80005c40:	00f51b63          	bne	a0,a5,80005c56 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c44:	f1845783          	lhu	a5,-232(s0)
    80005c48:	e7a1                	bnez	a5,80005c90 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c4a:	29c1                	addiw	s3,s3,16
    80005c4c:	04c92783          	lw	a5,76(s2)
    80005c50:	fcf9ede3          	bltu	s3,a5,80005c2a <sys_unlink+0x140>
    80005c54:	b781                	j	80005b94 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c56:	00003517          	auipc	a0,0x3
    80005c5a:	bba50513          	addi	a0,a0,-1094 # 80008810 <syscalls+0x2e0>
    80005c5e:	ffffb097          	auipc	ra,0xffffb
    80005c62:	8e6080e7          	jalr	-1818(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005c66:	00003517          	auipc	a0,0x3
    80005c6a:	bc250513          	addi	a0,a0,-1086 # 80008828 <syscalls+0x2f8>
    80005c6e:	ffffb097          	auipc	ra,0xffffb
    80005c72:	8d6080e7          	jalr	-1834(ra) # 80000544 <panic>
    dp->nlink--;
    80005c76:	04a4d783          	lhu	a5,74(s1)
    80005c7a:	37fd                	addiw	a5,a5,-1
    80005c7c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c80:	8526                	mv	a0,s1
    80005c82:	ffffe097          	auipc	ra,0xffffe
    80005c86:	fde080e7          	jalr	-34(ra) # 80003c60 <iupdate>
    80005c8a:	b781                	j	80005bca <sys_unlink+0xe0>
    return -1;
    80005c8c:	557d                	li	a0,-1
    80005c8e:	a005                	j	80005cae <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c90:	854a                	mv	a0,s2
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	2fa080e7          	jalr	762(ra) # 80003f8c <iunlockput>
  iunlockput(dp);
    80005c9a:	8526                	mv	a0,s1
    80005c9c:	ffffe097          	auipc	ra,0xffffe
    80005ca0:	2f0080e7          	jalr	752(ra) # 80003f8c <iunlockput>
  end_op();
    80005ca4:	fffff097          	auipc	ra,0xfffff
    80005ca8:	ac8080e7          	jalr	-1336(ra) # 8000476c <end_op>
  return -1;
    80005cac:	557d                	li	a0,-1
}
    80005cae:	70ae                	ld	ra,232(sp)
    80005cb0:	740e                	ld	s0,224(sp)
    80005cb2:	64ee                	ld	s1,216(sp)
    80005cb4:	694e                	ld	s2,208(sp)
    80005cb6:	69ae                	ld	s3,200(sp)
    80005cb8:	616d                	addi	sp,sp,240
    80005cba:	8082                	ret

0000000080005cbc <sys_open>:

uint64
sys_open(void)
{
    80005cbc:	7131                	addi	sp,sp,-192
    80005cbe:	fd06                	sd	ra,184(sp)
    80005cc0:	f922                	sd	s0,176(sp)
    80005cc2:	f526                	sd	s1,168(sp)
    80005cc4:	f14a                	sd	s2,160(sp)
    80005cc6:	ed4e                	sd	s3,152(sp)
    80005cc8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005cca:	f4c40593          	addi	a1,s0,-180
    80005cce:	4505                	li	a0,1
    80005cd0:	ffffd097          	auipc	ra,0xffffd
    80005cd4:	45e080e7          	jalr	1118(ra) # 8000312e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cd8:	08000613          	li	a2,128
    80005cdc:	f5040593          	addi	a1,s0,-176
    80005ce0:	4501                	li	a0,0
    80005ce2:	ffffd097          	auipc	ra,0xffffd
    80005ce6:	48c080e7          	jalr	1164(ra) # 8000316e <argstr>
    80005cea:	87aa                	mv	a5,a0
    return -1;
    80005cec:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cee:	0a07c963          	bltz	a5,80005da0 <sys_open+0xe4>

  begin_op();
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	9fa080e7          	jalr	-1542(ra) # 800046ec <begin_op>

  if(omode & O_CREATE){
    80005cfa:	f4c42783          	lw	a5,-180(s0)
    80005cfe:	2007f793          	andi	a5,a5,512
    80005d02:	cfc5                	beqz	a5,80005dba <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d04:	4681                	li	a3,0
    80005d06:	4601                	li	a2,0
    80005d08:	4589                	li	a1,2
    80005d0a:	f5040513          	addi	a0,s0,-176
    80005d0e:	00000097          	auipc	ra,0x0
    80005d12:	974080e7          	jalr	-1676(ra) # 80005682 <create>
    80005d16:	84aa                	mv	s1,a0
    if(ip == 0){
    80005d18:	c959                	beqz	a0,80005dae <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d1a:	04449703          	lh	a4,68(s1)
    80005d1e:	478d                	li	a5,3
    80005d20:	00f71763          	bne	a4,a5,80005d2e <sys_open+0x72>
    80005d24:	0464d703          	lhu	a4,70(s1)
    80005d28:	47a5                	li	a5,9
    80005d2a:	0ce7ed63          	bltu	a5,a4,80005e04 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	dce080e7          	jalr	-562(ra) # 80004afc <filealloc>
    80005d36:	89aa                	mv	s3,a0
    80005d38:	10050363          	beqz	a0,80005e3e <sys_open+0x182>
    80005d3c:	00000097          	auipc	ra,0x0
    80005d40:	904080e7          	jalr	-1788(ra) # 80005640 <fdalloc>
    80005d44:	892a                	mv	s2,a0
    80005d46:	0e054763          	bltz	a0,80005e34 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d4a:	04449703          	lh	a4,68(s1)
    80005d4e:	478d                	li	a5,3
    80005d50:	0cf70563          	beq	a4,a5,80005e1a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d54:	4789                	li	a5,2
    80005d56:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d5a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d5e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d62:	f4c42783          	lw	a5,-180(s0)
    80005d66:	0017c713          	xori	a4,a5,1
    80005d6a:	8b05                	andi	a4,a4,1
    80005d6c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d70:	0037f713          	andi	a4,a5,3
    80005d74:	00e03733          	snez	a4,a4
    80005d78:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d7c:	4007f793          	andi	a5,a5,1024
    80005d80:	c791                	beqz	a5,80005d8c <sys_open+0xd0>
    80005d82:	04449703          	lh	a4,68(s1)
    80005d86:	4789                	li	a5,2
    80005d88:	0af70063          	beq	a4,a5,80005e28 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d8c:	8526                	mv	a0,s1
    80005d8e:	ffffe097          	auipc	ra,0xffffe
    80005d92:	05e080e7          	jalr	94(ra) # 80003dec <iunlock>
  end_op();
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	9d6080e7          	jalr	-1578(ra) # 8000476c <end_op>

  return fd;
    80005d9e:	854a                	mv	a0,s2
}
    80005da0:	70ea                	ld	ra,184(sp)
    80005da2:	744a                	ld	s0,176(sp)
    80005da4:	74aa                	ld	s1,168(sp)
    80005da6:	790a                	ld	s2,160(sp)
    80005da8:	69ea                	ld	s3,152(sp)
    80005daa:	6129                	addi	sp,sp,192
    80005dac:	8082                	ret
      end_op();
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	9be080e7          	jalr	-1602(ra) # 8000476c <end_op>
      return -1;
    80005db6:	557d                	li	a0,-1
    80005db8:	b7e5                	j	80005da0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005dba:	f5040513          	addi	a0,s0,-176
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	712080e7          	jalr	1810(ra) # 800044d0 <namei>
    80005dc6:	84aa                	mv	s1,a0
    80005dc8:	c905                	beqz	a0,80005df8 <sys_open+0x13c>
    ilock(ip);
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	f60080e7          	jalr	-160(ra) # 80003d2a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005dd2:	04449703          	lh	a4,68(s1)
    80005dd6:	4785                	li	a5,1
    80005dd8:	f4f711e3          	bne	a4,a5,80005d1a <sys_open+0x5e>
    80005ddc:	f4c42783          	lw	a5,-180(s0)
    80005de0:	d7b9                	beqz	a5,80005d2e <sys_open+0x72>
      iunlockput(ip);
    80005de2:	8526                	mv	a0,s1
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	1a8080e7          	jalr	424(ra) # 80003f8c <iunlockput>
      end_op();
    80005dec:	fffff097          	auipc	ra,0xfffff
    80005df0:	980080e7          	jalr	-1664(ra) # 8000476c <end_op>
      return -1;
    80005df4:	557d                	li	a0,-1
    80005df6:	b76d                	j	80005da0 <sys_open+0xe4>
      end_op();
    80005df8:	fffff097          	auipc	ra,0xfffff
    80005dfc:	974080e7          	jalr	-1676(ra) # 8000476c <end_op>
      return -1;
    80005e00:	557d                	li	a0,-1
    80005e02:	bf79                	j	80005da0 <sys_open+0xe4>
    iunlockput(ip);
    80005e04:	8526                	mv	a0,s1
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	186080e7          	jalr	390(ra) # 80003f8c <iunlockput>
    end_op();
    80005e0e:	fffff097          	auipc	ra,0xfffff
    80005e12:	95e080e7          	jalr	-1698(ra) # 8000476c <end_op>
    return -1;
    80005e16:	557d                	li	a0,-1
    80005e18:	b761                	j	80005da0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e1a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e1e:	04649783          	lh	a5,70(s1)
    80005e22:	02f99223          	sh	a5,36(s3)
    80005e26:	bf25                	j	80005d5e <sys_open+0xa2>
    itrunc(ip);
    80005e28:	8526                	mv	a0,s1
    80005e2a:	ffffe097          	auipc	ra,0xffffe
    80005e2e:	00e080e7          	jalr	14(ra) # 80003e38 <itrunc>
    80005e32:	bfa9                	j	80005d8c <sys_open+0xd0>
      fileclose(f);
    80005e34:	854e                	mv	a0,s3
    80005e36:	fffff097          	auipc	ra,0xfffff
    80005e3a:	d82080e7          	jalr	-638(ra) # 80004bb8 <fileclose>
    iunlockput(ip);
    80005e3e:	8526                	mv	a0,s1
    80005e40:	ffffe097          	auipc	ra,0xffffe
    80005e44:	14c080e7          	jalr	332(ra) # 80003f8c <iunlockput>
    end_op();
    80005e48:	fffff097          	auipc	ra,0xfffff
    80005e4c:	924080e7          	jalr	-1756(ra) # 8000476c <end_op>
    return -1;
    80005e50:	557d                	li	a0,-1
    80005e52:	b7b9                	j	80005da0 <sys_open+0xe4>

0000000080005e54 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e54:	7175                	addi	sp,sp,-144
    80005e56:	e506                	sd	ra,136(sp)
    80005e58:	e122                	sd	s0,128(sp)
    80005e5a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e5c:	fffff097          	auipc	ra,0xfffff
    80005e60:	890080e7          	jalr	-1904(ra) # 800046ec <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e64:	08000613          	li	a2,128
    80005e68:	f7040593          	addi	a1,s0,-144
    80005e6c:	4501                	li	a0,0
    80005e6e:	ffffd097          	auipc	ra,0xffffd
    80005e72:	300080e7          	jalr	768(ra) # 8000316e <argstr>
    80005e76:	02054963          	bltz	a0,80005ea8 <sys_mkdir+0x54>
    80005e7a:	4681                	li	a3,0
    80005e7c:	4601                	li	a2,0
    80005e7e:	4585                	li	a1,1
    80005e80:	f7040513          	addi	a0,s0,-144
    80005e84:	fffff097          	auipc	ra,0xfffff
    80005e88:	7fe080e7          	jalr	2046(ra) # 80005682 <create>
    80005e8c:	cd11                	beqz	a0,80005ea8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e8e:	ffffe097          	auipc	ra,0xffffe
    80005e92:	0fe080e7          	jalr	254(ra) # 80003f8c <iunlockput>
  end_op();
    80005e96:	fffff097          	auipc	ra,0xfffff
    80005e9a:	8d6080e7          	jalr	-1834(ra) # 8000476c <end_op>
  return 0;
    80005e9e:	4501                	li	a0,0
}
    80005ea0:	60aa                	ld	ra,136(sp)
    80005ea2:	640a                	ld	s0,128(sp)
    80005ea4:	6149                	addi	sp,sp,144
    80005ea6:	8082                	ret
    end_op();
    80005ea8:	fffff097          	auipc	ra,0xfffff
    80005eac:	8c4080e7          	jalr	-1852(ra) # 8000476c <end_op>
    return -1;
    80005eb0:	557d                	li	a0,-1
    80005eb2:	b7fd                	j	80005ea0 <sys_mkdir+0x4c>

0000000080005eb4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005eb4:	7135                	addi	sp,sp,-160
    80005eb6:	ed06                	sd	ra,152(sp)
    80005eb8:	e922                	sd	s0,144(sp)
    80005eba:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ebc:	fffff097          	auipc	ra,0xfffff
    80005ec0:	830080e7          	jalr	-2000(ra) # 800046ec <begin_op>
  argint(1, &major);
    80005ec4:	f6c40593          	addi	a1,s0,-148
    80005ec8:	4505                	li	a0,1
    80005eca:	ffffd097          	auipc	ra,0xffffd
    80005ece:	264080e7          	jalr	612(ra) # 8000312e <argint>
  argint(2, &minor);
    80005ed2:	f6840593          	addi	a1,s0,-152
    80005ed6:	4509                	li	a0,2
    80005ed8:	ffffd097          	auipc	ra,0xffffd
    80005edc:	256080e7          	jalr	598(ra) # 8000312e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ee0:	08000613          	li	a2,128
    80005ee4:	f7040593          	addi	a1,s0,-144
    80005ee8:	4501                	li	a0,0
    80005eea:	ffffd097          	auipc	ra,0xffffd
    80005eee:	284080e7          	jalr	644(ra) # 8000316e <argstr>
    80005ef2:	02054b63          	bltz	a0,80005f28 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ef6:	f6841683          	lh	a3,-152(s0)
    80005efa:	f6c41603          	lh	a2,-148(s0)
    80005efe:	458d                	li	a1,3
    80005f00:	f7040513          	addi	a0,s0,-144
    80005f04:	fffff097          	auipc	ra,0xfffff
    80005f08:	77e080e7          	jalr	1918(ra) # 80005682 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f0c:	cd11                	beqz	a0,80005f28 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f0e:	ffffe097          	auipc	ra,0xffffe
    80005f12:	07e080e7          	jalr	126(ra) # 80003f8c <iunlockput>
  end_op();
    80005f16:	fffff097          	auipc	ra,0xfffff
    80005f1a:	856080e7          	jalr	-1962(ra) # 8000476c <end_op>
  return 0;
    80005f1e:	4501                	li	a0,0
}
    80005f20:	60ea                	ld	ra,152(sp)
    80005f22:	644a                	ld	s0,144(sp)
    80005f24:	610d                	addi	sp,sp,160
    80005f26:	8082                	ret
    end_op();
    80005f28:	fffff097          	auipc	ra,0xfffff
    80005f2c:	844080e7          	jalr	-1980(ra) # 8000476c <end_op>
    return -1;
    80005f30:	557d                	li	a0,-1
    80005f32:	b7fd                	j	80005f20 <sys_mknod+0x6c>

0000000080005f34 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f34:	7135                	addi	sp,sp,-160
    80005f36:	ed06                	sd	ra,152(sp)
    80005f38:	e922                	sd	s0,144(sp)
    80005f3a:	e526                	sd	s1,136(sp)
    80005f3c:	e14a                	sd	s2,128(sp)
    80005f3e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f40:	ffffc097          	auipc	ra,0xffffc
    80005f44:	b8e080e7          	jalr	-1138(ra) # 80001ace <myproc>
    80005f48:	892a                	mv	s2,a0
  
  begin_op();
    80005f4a:	ffffe097          	auipc	ra,0xffffe
    80005f4e:	7a2080e7          	jalr	1954(ra) # 800046ec <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f52:	08000613          	li	a2,128
    80005f56:	f6040593          	addi	a1,s0,-160
    80005f5a:	4501                	li	a0,0
    80005f5c:	ffffd097          	auipc	ra,0xffffd
    80005f60:	212080e7          	jalr	530(ra) # 8000316e <argstr>
    80005f64:	04054b63          	bltz	a0,80005fba <sys_chdir+0x86>
    80005f68:	f6040513          	addi	a0,s0,-160
    80005f6c:	ffffe097          	auipc	ra,0xffffe
    80005f70:	564080e7          	jalr	1380(ra) # 800044d0 <namei>
    80005f74:	84aa                	mv	s1,a0
    80005f76:	c131                	beqz	a0,80005fba <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f78:	ffffe097          	auipc	ra,0xffffe
    80005f7c:	db2080e7          	jalr	-590(ra) # 80003d2a <ilock>
  if(ip->type != T_DIR){
    80005f80:	04449703          	lh	a4,68(s1)
    80005f84:	4785                	li	a5,1
    80005f86:	04f71063          	bne	a4,a5,80005fc6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f8a:	8526                	mv	a0,s1
    80005f8c:	ffffe097          	auipc	ra,0xffffe
    80005f90:	e60080e7          	jalr	-416(ra) # 80003dec <iunlock>
  iput(p->cwd);
    80005f94:	15093503          	ld	a0,336(s2)
    80005f98:	ffffe097          	auipc	ra,0xffffe
    80005f9c:	f4c080e7          	jalr	-180(ra) # 80003ee4 <iput>
  end_op();
    80005fa0:	ffffe097          	auipc	ra,0xffffe
    80005fa4:	7cc080e7          	jalr	1996(ra) # 8000476c <end_op>
  p->cwd = ip;
    80005fa8:	14993823          	sd	s1,336(s2)
  return 0;
    80005fac:	4501                	li	a0,0
}
    80005fae:	60ea                	ld	ra,152(sp)
    80005fb0:	644a                	ld	s0,144(sp)
    80005fb2:	64aa                	ld	s1,136(sp)
    80005fb4:	690a                	ld	s2,128(sp)
    80005fb6:	610d                	addi	sp,sp,160
    80005fb8:	8082                	ret
    end_op();
    80005fba:	ffffe097          	auipc	ra,0xffffe
    80005fbe:	7b2080e7          	jalr	1970(ra) # 8000476c <end_op>
    return -1;
    80005fc2:	557d                	li	a0,-1
    80005fc4:	b7ed                	j	80005fae <sys_chdir+0x7a>
    iunlockput(ip);
    80005fc6:	8526                	mv	a0,s1
    80005fc8:	ffffe097          	auipc	ra,0xffffe
    80005fcc:	fc4080e7          	jalr	-60(ra) # 80003f8c <iunlockput>
    end_op();
    80005fd0:	ffffe097          	auipc	ra,0xffffe
    80005fd4:	79c080e7          	jalr	1948(ra) # 8000476c <end_op>
    return -1;
    80005fd8:	557d                	li	a0,-1
    80005fda:	bfd1                	j	80005fae <sys_chdir+0x7a>

0000000080005fdc <sys_exec>:

uint64
sys_exec(void)
{
    80005fdc:	7145                	addi	sp,sp,-464
    80005fde:	e786                	sd	ra,456(sp)
    80005fe0:	e3a2                	sd	s0,448(sp)
    80005fe2:	ff26                	sd	s1,440(sp)
    80005fe4:	fb4a                	sd	s2,432(sp)
    80005fe6:	f74e                	sd	s3,424(sp)
    80005fe8:	f352                	sd	s4,416(sp)
    80005fea:	ef56                	sd	s5,408(sp)
    80005fec:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005fee:	e3840593          	addi	a1,s0,-456
    80005ff2:	4505                	li	a0,1
    80005ff4:	ffffd097          	auipc	ra,0xffffd
    80005ff8:	15a080e7          	jalr	346(ra) # 8000314e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ffc:	08000613          	li	a2,128
    80006000:	f4040593          	addi	a1,s0,-192
    80006004:	4501                	li	a0,0
    80006006:	ffffd097          	auipc	ra,0xffffd
    8000600a:	168080e7          	jalr	360(ra) # 8000316e <argstr>
    8000600e:	87aa                	mv	a5,a0
    return -1;
    80006010:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006012:	0c07c263          	bltz	a5,800060d6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006016:	10000613          	li	a2,256
    8000601a:	4581                	li	a1,0
    8000601c:	e4040513          	addi	a0,s0,-448
    80006020:	ffffb097          	auipc	ra,0xffffb
    80006024:	cc6080e7          	jalr	-826(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006028:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000602c:	89a6                	mv	s3,s1
    8000602e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006030:	02000a13          	li	s4,32
    80006034:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006038:	00391513          	slli	a0,s2,0x3
    8000603c:	e3040593          	addi	a1,s0,-464
    80006040:	e3843783          	ld	a5,-456(s0)
    80006044:	953e                	add	a0,a0,a5
    80006046:	ffffd097          	auipc	ra,0xffffd
    8000604a:	04a080e7          	jalr	74(ra) # 80003090 <fetchaddr>
    8000604e:	02054a63          	bltz	a0,80006082 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006052:	e3043783          	ld	a5,-464(s0)
    80006056:	c3b9                	beqz	a5,8000609c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006058:	ffffb097          	auipc	ra,0xffffb
    8000605c:	aa2080e7          	jalr	-1374(ra) # 80000afa <kalloc>
    80006060:	85aa                	mv	a1,a0
    80006062:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006066:	cd11                	beqz	a0,80006082 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006068:	6605                	lui	a2,0x1
    8000606a:	e3043503          	ld	a0,-464(s0)
    8000606e:	ffffd097          	auipc	ra,0xffffd
    80006072:	074080e7          	jalr	116(ra) # 800030e2 <fetchstr>
    80006076:	00054663          	bltz	a0,80006082 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    8000607a:	0905                	addi	s2,s2,1
    8000607c:	09a1                	addi	s3,s3,8
    8000607e:	fb491be3          	bne	s2,s4,80006034 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006082:	10048913          	addi	s2,s1,256
    80006086:	6088                	ld	a0,0(s1)
    80006088:	c531                	beqz	a0,800060d4 <sys_exec+0xf8>
    kfree(argv[i]);
    8000608a:	ffffb097          	auipc	ra,0xffffb
    8000608e:	974080e7          	jalr	-1676(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006092:	04a1                	addi	s1,s1,8
    80006094:	ff2499e3          	bne	s1,s2,80006086 <sys_exec+0xaa>
  return -1;
    80006098:	557d                	li	a0,-1
    8000609a:	a835                	j	800060d6 <sys_exec+0xfa>
      argv[i] = 0;
    8000609c:	0a8e                	slli	s5,s5,0x3
    8000609e:	fc040793          	addi	a5,s0,-64
    800060a2:	9abe                	add	s5,s5,a5
    800060a4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800060a8:	e4040593          	addi	a1,s0,-448
    800060ac:	f4040513          	addi	a0,s0,-192
    800060b0:	fffff097          	auipc	ra,0xfffff
    800060b4:	190080e7          	jalr	400(ra) # 80005240 <exec>
    800060b8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060ba:	10048993          	addi	s3,s1,256
    800060be:	6088                	ld	a0,0(s1)
    800060c0:	c901                	beqz	a0,800060d0 <sys_exec+0xf4>
    kfree(argv[i]);
    800060c2:	ffffb097          	auipc	ra,0xffffb
    800060c6:	93c080e7          	jalr	-1732(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060ca:	04a1                	addi	s1,s1,8
    800060cc:	ff3499e3          	bne	s1,s3,800060be <sys_exec+0xe2>
  return ret;
    800060d0:	854a                	mv	a0,s2
    800060d2:	a011                	j	800060d6 <sys_exec+0xfa>
  return -1;
    800060d4:	557d                	li	a0,-1
}
    800060d6:	60be                	ld	ra,456(sp)
    800060d8:	641e                	ld	s0,448(sp)
    800060da:	74fa                	ld	s1,440(sp)
    800060dc:	795a                	ld	s2,432(sp)
    800060de:	79ba                	ld	s3,424(sp)
    800060e0:	7a1a                	ld	s4,416(sp)
    800060e2:	6afa                	ld	s5,408(sp)
    800060e4:	6179                	addi	sp,sp,464
    800060e6:	8082                	ret

00000000800060e8 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060e8:	7139                	addi	sp,sp,-64
    800060ea:	fc06                	sd	ra,56(sp)
    800060ec:	f822                	sd	s0,48(sp)
    800060ee:	f426                	sd	s1,40(sp)
    800060f0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060f2:	ffffc097          	auipc	ra,0xffffc
    800060f6:	9dc080e7          	jalr	-1572(ra) # 80001ace <myproc>
    800060fa:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800060fc:	fd840593          	addi	a1,s0,-40
    80006100:	4501                	li	a0,0
    80006102:	ffffd097          	auipc	ra,0xffffd
    80006106:	04c080e7          	jalr	76(ra) # 8000314e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000610a:	fc840593          	addi	a1,s0,-56
    8000610e:	fd040513          	addi	a0,s0,-48
    80006112:	fffff097          	auipc	ra,0xfffff
    80006116:	dd6080e7          	jalr	-554(ra) # 80004ee8 <pipealloc>
    return -1;
    8000611a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000611c:	0c054463          	bltz	a0,800061e4 <sys_pipe+0xfc>
  fd0 = -1;
    80006120:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006124:	fd043503          	ld	a0,-48(s0)
    80006128:	fffff097          	auipc	ra,0xfffff
    8000612c:	518080e7          	jalr	1304(ra) # 80005640 <fdalloc>
    80006130:	fca42223          	sw	a0,-60(s0)
    80006134:	08054b63          	bltz	a0,800061ca <sys_pipe+0xe2>
    80006138:	fc843503          	ld	a0,-56(s0)
    8000613c:	fffff097          	auipc	ra,0xfffff
    80006140:	504080e7          	jalr	1284(ra) # 80005640 <fdalloc>
    80006144:	fca42023          	sw	a0,-64(s0)
    80006148:	06054863          	bltz	a0,800061b8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000614c:	4691                	li	a3,4
    8000614e:	fc440613          	addi	a2,s0,-60
    80006152:	fd843583          	ld	a1,-40(s0)
    80006156:	68a8                	ld	a0,80(s1)
    80006158:	ffffb097          	auipc	ra,0xffffb
    8000615c:	52c080e7          	jalr	1324(ra) # 80001684 <copyout>
    80006160:	02054063          	bltz	a0,80006180 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006164:	4691                	li	a3,4
    80006166:	fc040613          	addi	a2,s0,-64
    8000616a:	fd843583          	ld	a1,-40(s0)
    8000616e:	0591                	addi	a1,a1,4
    80006170:	68a8                	ld	a0,80(s1)
    80006172:	ffffb097          	auipc	ra,0xffffb
    80006176:	512080e7          	jalr	1298(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000617a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000617c:	06055463          	bgez	a0,800061e4 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006180:	fc442783          	lw	a5,-60(s0)
    80006184:	07e9                	addi	a5,a5,26
    80006186:	078e                	slli	a5,a5,0x3
    80006188:	97a6                	add	a5,a5,s1
    8000618a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000618e:	fc042503          	lw	a0,-64(s0)
    80006192:	0569                	addi	a0,a0,26
    80006194:	050e                	slli	a0,a0,0x3
    80006196:	94aa                	add	s1,s1,a0
    80006198:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000619c:	fd043503          	ld	a0,-48(s0)
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	a18080e7          	jalr	-1512(ra) # 80004bb8 <fileclose>
    fileclose(wf);
    800061a8:	fc843503          	ld	a0,-56(s0)
    800061ac:	fffff097          	auipc	ra,0xfffff
    800061b0:	a0c080e7          	jalr	-1524(ra) # 80004bb8 <fileclose>
    return -1;
    800061b4:	57fd                	li	a5,-1
    800061b6:	a03d                	j	800061e4 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800061b8:	fc442783          	lw	a5,-60(s0)
    800061bc:	0007c763          	bltz	a5,800061ca <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800061c0:	07e9                	addi	a5,a5,26
    800061c2:	078e                	slli	a5,a5,0x3
    800061c4:	94be                	add	s1,s1,a5
    800061c6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800061ca:	fd043503          	ld	a0,-48(s0)
    800061ce:	fffff097          	auipc	ra,0xfffff
    800061d2:	9ea080e7          	jalr	-1558(ra) # 80004bb8 <fileclose>
    fileclose(wf);
    800061d6:	fc843503          	ld	a0,-56(s0)
    800061da:	fffff097          	auipc	ra,0xfffff
    800061de:	9de080e7          	jalr	-1570(ra) # 80004bb8 <fileclose>
    return -1;
    800061e2:	57fd                	li	a5,-1
}
    800061e4:	853e                	mv	a0,a5
    800061e6:	70e2                	ld	ra,56(sp)
    800061e8:	7442                	ld	s0,48(sp)
    800061ea:	74a2                	ld	s1,40(sp)
    800061ec:	6121                	addi	sp,sp,64
    800061ee:	8082                	ret

00000000800061f0 <kernelvec>:
    800061f0:	7111                	addi	sp,sp,-256
    800061f2:	e006                	sd	ra,0(sp)
    800061f4:	e40a                	sd	sp,8(sp)
    800061f6:	e80e                	sd	gp,16(sp)
    800061f8:	ec12                	sd	tp,24(sp)
    800061fa:	f016                	sd	t0,32(sp)
    800061fc:	f41a                	sd	t1,40(sp)
    800061fe:	f81e                	sd	t2,48(sp)
    80006200:	fc22                	sd	s0,56(sp)
    80006202:	e0a6                	sd	s1,64(sp)
    80006204:	e4aa                	sd	a0,72(sp)
    80006206:	e8ae                	sd	a1,80(sp)
    80006208:	ecb2                	sd	a2,88(sp)
    8000620a:	f0b6                	sd	a3,96(sp)
    8000620c:	f4ba                	sd	a4,104(sp)
    8000620e:	f8be                	sd	a5,112(sp)
    80006210:	fcc2                	sd	a6,120(sp)
    80006212:	e146                	sd	a7,128(sp)
    80006214:	e54a                	sd	s2,136(sp)
    80006216:	e94e                	sd	s3,144(sp)
    80006218:	ed52                	sd	s4,152(sp)
    8000621a:	f156                	sd	s5,160(sp)
    8000621c:	f55a                	sd	s6,168(sp)
    8000621e:	f95e                	sd	s7,176(sp)
    80006220:	fd62                	sd	s8,184(sp)
    80006222:	e1e6                	sd	s9,192(sp)
    80006224:	e5ea                	sd	s10,200(sp)
    80006226:	e9ee                	sd	s11,208(sp)
    80006228:	edf2                	sd	t3,216(sp)
    8000622a:	f1f6                	sd	t4,224(sp)
    8000622c:	f5fa                	sd	t5,232(sp)
    8000622e:	f9fe                	sd	t6,240(sp)
    80006230:	d2dfc0ef          	jal	ra,80002f5c <kerneltrap>
    80006234:	6082                	ld	ra,0(sp)
    80006236:	6122                	ld	sp,8(sp)
    80006238:	61c2                	ld	gp,16(sp)
    8000623a:	7282                	ld	t0,32(sp)
    8000623c:	7322                	ld	t1,40(sp)
    8000623e:	73c2                	ld	t2,48(sp)
    80006240:	7462                	ld	s0,56(sp)
    80006242:	6486                	ld	s1,64(sp)
    80006244:	6526                	ld	a0,72(sp)
    80006246:	65c6                	ld	a1,80(sp)
    80006248:	6666                	ld	a2,88(sp)
    8000624a:	7686                	ld	a3,96(sp)
    8000624c:	7726                	ld	a4,104(sp)
    8000624e:	77c6                	ld	a5,112(sp)
    80006250:	7866                	ld	a6,120(sp)
    80006252:	688a                	ld	a7,128(sp)
    80006254:	692a                	ld	s2,136(sp)
    80006256:	69ca                	ld	s3,144(sp)
    80006258:	6a6a                	ld	s4,152(sp)
    8000625a:	7a8a                	ld	s5,160(sp)
    8000625c:	7b2a                	ld	s6,168(sp)
    8000625e:	7bca                	ld	s7,176(sp)
    80006260:	7c6a                	ld	s8,184(sp)
    80006262:	6c8e                	ld	s9,192(sp)
    80006264:	6d2e                	ld	s10,200(sp)
    80006266:	6dce                	ld	s11,208(sp)
    80006268:	6e6e                	ld	t3,216(sp)
    8000626a:	7e8e                	ld	t4,224(sp)
    8000626c:	7f2e                	ld	t5,232(sp)
    8000626e:	7fce                	ld	t6,240(sp)
    80006270:	6111                	addi	sp,sp,256
    80006272:	10200073          	sret
    80006276:	00000013          	nop
    8000627a:	00000013          	nop
    8000627e:	0001                	nop

0000000080006280 <timervec>:
    80006280:	34051573          	csrrw	a0,mscratch,a0
    80006284:	e10c                	sd	a1,0(a0)
    80006286:	e510                	sd	a2,8(a0)
    80006288:	e914                	sd	a3,16(a0)
    8000628a:	6d0c                	ld	a1,24(a0)
    8000628c:	7110                	ld	a2,32(a0)
    8000628e:	6194                	ld	a3,0(a1)
    80006290:	96b2                	add	a3,a3,a2
    80006292:	e194                	sd	a3,0(a1)
    80006294:	4589                	li	a1,2
    80006296:	14459073          	csrw	sip,a1
    8000629a:	6914                	ld	a3,16(a0)
    8000629c:	6510                	ld	a2,8(a0)
    8000629e:	610c                	ld	a1,0(a0)
    800062a0:	34051573          	csrrw	a0,mscratch,a0
    800062a4:	30200073          	mret
	...

00000000800062aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062aa:	1141                	addi	sp,sp,-16
    800062ac:	e422                	sd	s0,8(sp)
    800062ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062b0:	0c0007b7          	lui	a5,0xc000
    800062b4:	4705                	li	a4,1
    800062b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062b8:	c3d8                	sw	a4,4(a5)
}
    800062ba:	6422                	ld	s0,8(sp)
    800062bc:	0141                	addi	sp,sp,16
    800062be:	8082                	ret

00000000800062c0 <plicinithart>:

void
plicinithart(void)
{
    800062c0:	1141                	addi	sp,sp,-16
    800062c2:	e406                	sd	ra,8(sp)
    800062c4:	e022                	sd	s0,0(sp)
    800062c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062c8:	ffffb097          	auipc	ra,0xffffb
    800062cc:	7da080e7          	jalr	2010(ra) # 80001aa2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062d0:	0085171b          	slliw	a4,a0,0x8
    800062d4:	0c0027b7          	lui	a5,0xc002
    800062d8:	97ba                	add	a5,a5,a4
    800062da:	40200713          	li	a4,1026
    800062de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062e2:	00d5151b          	slliw	a0,a0,0xd
    800062e6:	0c2017b7          	lui	a5,0xc201
    800062ea:	953e                	add	a0,a0,a5
    800062ec:	00052023          	sw	zero,0(a0)
}
    800062f0:	60a2                	ld	ra,8(sp)
    800062f2:	6402                	ld	s0,0(sp)
    800062f4:	0141                	addi	sp,sp,16
    800062f6:	8082                	ret

00000000800062f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062f8:	1141                	addi	sp,sp,-16
    800062fa:	e406                	sd	ra,8(sp)
    800062fc:	e022                	sd	s0,0(sp)
    800062fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006300:	ffffb097          	auipc	ra,0xffffb
    80006304:	7a2080e7          	jalr	1954(ra) # 80001aa2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006308:	00d5179b          	slliw	a5,a0,0xd
    8000630c:	0c201537          	lui	a0,0xc201
    80006310:	953e                	add	a0,a0,a5
  return irq;
}
    80006312:	4148                	lw	a0,4(a0)
    80006314:	60a2                	ld	ra,8(sp)
    80006316:	6402                	ld	s0,0(sp)
    80006318:	0141                	addi	sp,sp,16
    8000631a:	8082                	ret

000000008000631c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000631c:	1101                	addi	sp,sp,-32
    8000631e:	ec06                	sd	ra,24(sp)
    80006320:	e822                	sd	s0,16(sp)
    80006322:	e426                	sd	s1,8(sp)
    80006324:	1000                	addi	s0,sp,32
    80006326:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006328:	ffffb097          	auipc	ra,0xffffb
    8000632c:	77a080e7          	jalr	1914(ra) # 80001aa2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006330:	00d5151b          	slliw	a0,a0,0xd
    80006334:	0c2017b7          	lui	a5,0xc201
    80006338:	97aa                	add	a5,a5,a0
    8000633a:	c3c4                	sw	s1,4(a5)
}
    8000633c:	60e2                	ld	ra,24(sp)
    8000633e:	6442                	ld	s0,16(sp)
    80006340:	64a2                	ld	s1,8(sp)
    80006342:	6105                	addi	sp,sp,32
    80006344:	8082                	ret

0000000080006346 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006346:	1141                	addi	sp,sp,-16
    80006348:	e406                	sd	ra,8(sp)
    8000634a:	e022                	sd	s0,0(sp)
    8000634c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000634e:	479d                	li	a5,7
    80006350:	04a7cc63          	blt	a5,a0,800063a8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006354:	0001c797          	auipc	a5,0x1c
    80006358:	03c78793          	addi	a5,a5,60 # 80022390 <disk>
    8000635c:	97aa                	add	a5,a5,a0
    8000635e:	0187c783          	lbu	a5,24(a5)
    80006362:	ebb9                	bnez	a5,800063b8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006364:	00451613          	slli	a2,a0,0x4
    80006368:	0001c797          	auipc	a5,0x1c
    8000636c:	02878793          	addi	a5,a5,40 # 80022390 <disk>
    80006370:	6394                	ld	a3,0(a5)
    80006372:	96b2                	add	a3,a3,a2
    80006374:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006378:	6398                	ld	a4,0(a5)
    8000637a:	9732                	add	a4,a4,a2
    8000637c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006380:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006384:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006388:	953e                	add	a0,a0,a5
    8000638a:	4785                	li	a5,1
    8000638c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006390:	0001c517          	auipc	a0,0x1c
    80006394:	01850513          	addi	a0,a0,24 # 800223a8 <disk+0x18>
    80006398:	ffffc097          	auipc	ra,0xffffc
    8000639c:	248080e7          	jalr	584(ra) # 800025e0 <wakeup>
}
    800063a0:	60a2                	ld	ra,8(sp)
    800063a2:	6402                	ld	s0,0(sp)
    800063a4:	0141                	addi	sp,sp,16
    800063a6:	8082                	ret
    panic("free_desc 1");
    800063a8:	00002517          	auipc	a0,0x2
    800063ac:	49050513          	addi	a0,a0,1168 # 80008838 <syscalls+0x308>
    800063b0:	ffffa097          	auipc	ra,0xffffa
    800063b4:	194080e7          	jalr	404(ra) # 80000544 <panic>
    panic("free_desc 2");
    800063b8:	00002517          	auipc	a0,0x2
    800063bc:	49050513          	addi	a0,a0,1168 # 80008848 <syscalls+0x318>
    800063c0:	ffffa097          	auipc	ra,0xffffa
    800063c4:	184080e7          	jalr	388(ra) # 80000544 <panic>

00000000800063c8 <virtio_disk_init>:
{
    800063c8:	1101                	addi	sp,sp,-32
    800063ca:	ec06                	sd	ra,24(sp)
    800063cc:	e822                	sd	s0,16(sp)
    800063ce:	e426                	sd	s1,8(sp)
    800063d0:	e04a                	sd	s2,0(sp)
    800063d2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063d4:	00002597          	auipc	a1,0x2
    800063d8:	48458593          	addi	a1,a1,1156 # 80008858 <syscalls+0x328>
    800063dc:	0001c517          	auipc	a0,0x1c
    800063e0:	0dc50513          	addi	a0,a0,220 # 800224b8 <disk+0x128>
    800063e4:	ffffa097          	auipc	ra,0xffffa
    800063e8:	776080e7          	jalr	1910(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063ec:	100017b7          	lui	a5,0x10001
    800063f0:	4398                	lw	a4,0(a5)
    800063f2:	2701                	sext.w	a4,a4
    800063f4:	747277b7          	lui	a5,0x74727
    800063f8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063fc:	14f71e63          	bne	a4,a5,80006558 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006400:	100017b7          	lui	a5,0x10001
    80006404:	43dc                	lw	a5,4(a5)
    80006406:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006408:	4709                	li	a4,2
    8000640a:	14e79763          	bne	a5,a4,80006558 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000640e:	100017b7          	lui	a5,0x10001
    80006412:	479c                	lw	a5,8(a5)
    80006414:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006416:	14e79163          	bne	a5,a4,80006558 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000641a:	100017b7          	lui	a5,0x10001
    8000641e:	47d8                	lw	a4,12(a5)
    80006420:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006422:	554d47b7          	lui	a5,0x554d4
    80006426:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000642a:	12f71763          	bne	a4,a5,80006558 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000642e:	100017b7          	lui	a5,0x10001
    80006432:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006436:	4705                	li	a4,1
    80006438:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000643a:	470d                	li	a4,3
    8000643c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000643e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006440:	c7ffe737          	lui	a4,0xc7ffe
    80006444:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc28f>
    80006448:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000644a:	2701                	sext.w	a4,a4
    8000644c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000644e:	472d                	li	a4,11
    80006450:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006452:	0707a903          	lw	s2,112(a5)
    80006456:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006458:	00897793          	andi	a5,s2,8
    8000645c:	10078663          	beqz	a5,80006568 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006460:	100017b7          	lui	a5,0x10001
    80006464:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006468:	43fc                	lw	a5,68(a5)
    8000646a:	2781                	sext.w	a5,a5
    8000646c:	10079663          	bnez	a5,80006578 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006470:	100017b7          	lui	a5,0x10001
    80006474:	5bdc                	lw	a5,52(a5)
    80006476:	2781                	sext.w	a5,a5
  if(max == 0)
    80006478:	10078863          	beqz	a5,80006588 <virtio_disk_init+0x1c0>
  if(max < NUM)
    8000647c:	471d                	li	a4,7
    8000647e:	10f77d63          	bgeu	a4,a5,80006598 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006482:	ffffa097          	auipc	ra,0xffffa
    80006486:	678080e7          	jalr	1656(ra) # 80000afa <kalloc>
    8000648a:	0001c497          	auipc	s1,0x1c
    8000648e:	f0648493          	addi	s1,s1,-250 # 80022390 <disk>
    80006492:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006494:	ffffa097          	auipc	ra,0xffffa
    80006498:	666080e7          	jalr	1638(ra) # 80000afa <kalloc>
    8000649c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000649e:	ffffa097          	auipc	ra,0xffffa
    800064a2:	65c080e7          	jalr	1628(ra) # 80000afa <kalloc>
    800064a6:	87aa                	mv	a5,a0
    800064a8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800064aa:	6088                	ld	a0,0(s1)
    800064ac:	cd75                	beqz	a0,800065a8 <virtio_disk_init+0x1e0>
    800064ae:	0001c717          	auipc	a4,0x1c
    800064b2:	eea73703          	ld	a4,-278(a4) # 80022398 <disk+0x8>
    800064b6:	cb6d                	beqz	a4,800065a8 <virtio_disk_init+0x1e0>
    800064b8:	cbe5                	beqz	a5,800065a8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    800064ba:	6605                	lui	a2,0x1
    800064bc:	4581                	li	a1,0
    800064be:	ffffb097          	auipc	ra,0xffffb
    800064c2:	828080e7          	jalr	-2008(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    800064c6:	0001c497          	auipc	s1,0x1c
    800064ca:	eca48493          	addi	s1,s1,-310 # 80022390 <disk>
    800064ce:	6605                	lui	a2,0x1
    800064d0:	4581                	li	a1,0
    800064d2:	6488                	ld	a0,8(s1)
    800064d4:	ffffb097          	auipc	ra,0xffffb
    800064d8:	812080e7          	jalr	-2030(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    800064dc:	6605                	lui	a2,0x1
    800064de:	4581                	li	a1,0
    800064e0:	6888                	ld	a0,16(s1)
    800064e2:	ffffb097          	auipc	ra,0xffffb
    800064e6:	804080e7          	jalr	-2044(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800064ea:	100017b7          	lui	a5,0x10001
    800064ee:	4721                	li	a4,8
    800064f0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800064f2:	4098                	lw	a4,0(s1)
    800064f4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800064f8:	40d8                	lw	a4,4(s1)
    800064fa:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800064fe:	6498                	ld	a4,8(s1)
    80006500:	0007069b          	sext.w	a3,a4
    80006504:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006508:	9701                	srai	a4,a4,0x20
    8000650a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000650e:	6898                	ld	a4,16(s1)
    80006510:	0007069b          	sext.w	a3,a4
    80006514:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006518:	9701                	srai	a4,a4,0x20
    8000651a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000651e:	4685                	li	a3,1
    80006520:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006522:	4705                	li	a4,1
    80006524:	00d48c23          	sb	a3,24(s1)
    80006528:	00e48ca3          	sb	a4,25(s1)
    8000652c:	00e48d23          	sb	a4,26(s1)
    80006530:	00e48da3          	sb	a4,27(s1)
    80006534:	00e48e23          	sb	a4,28(s1)
    80006538:	00e48ea3          	sb	a4,29(s1)
    8000653c:	00e48f23          	sb	a4,30(s1)
    80006540:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006544:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006548:	0727a823          	sw	s2,112(a5)
}
    8000654c:	60e2                	ld	ra,24(sp)
    8000654e:	6442                	ld	s0,16(sp)
    80006550:	64a2                	ld	s1,8(sp)
    80006552:	6902                	ld	s2,0(sp)
    80006554:	6105                	addi	sp,sp,32
    80006556:	8082                	ret
    panic("could not find virtio disk");
    80006558:	00002517          	auipc	a0,0x2
    8000655c:	31050513          	addi	a0,a0,784 # 80008868 <syscalls+0x338>
    80006560:	ffffa097          	auipc	ra,0xffffa
    80006564:	fe4080e7          	jalr	-28(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006568:	00002517          	auipc	a0,0x2
    8000656c:	32050513          	addi	a0,a0,800 # 80008888 <syscalls+0x358>
    80006570:	ffffa097          	auipc	ra,0xffffa
    80006574:	fd4080e7          	jalr	-44(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006578:	00002517          	auipc	a0,0x2
    8000657c:	33050513          	addi	a0,a0,816 # 800088a8 <syscalls+0x378>
    80006580:	ffffa097          	auipc	ra,0xffffa
    80006584:	fc4080e7          	jalr	-60(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006588:	00002517          	auipc	a0,0x2
    8000658c:	34050513          	addi	a0,a0,832 # 800088c8 <syscalls+0x398>
    80006590:	ffffa097          	auipc	ra,0xffffa
    80006594:	fb4080e7          	jalr	-76(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006598:	00002517          	auipc	a0,0x2
    8000659c:	35050513          	addi	a0,a0,848 # 800088e8 <syscalls+0x3b8>
    800065a0:	ffffa097          	auipc	ra,0xffffa
    800065a4:	fa4080e7          	jalr	-92(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800065a8:	00002517          	auipc	a0,0x2
    800065ac:	36050513          	addi	a0,a0,864 # 80008908 <syscalls+0x3d8>
    800065b0:	ffffa097          	auipc	ra,0xffffa
    800065b4:	f94080e7          	jalr	-108(ra) # 80000544 <panic>

00000000800065b8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065b8:	7159                	addi	sp,sp,-112
    800065ba:	f486                	sd	ra,104(sp)
    800065bc:	f0a2                	sd	s0,96(sp)
    800065be:	eca6                	sd	s1,88(sp)
    800065c0:	e8ca                	sd	s2,80(sp)
    800065c2:	e4ce                	sd	s3,72(sp)
    800065c4:	e0d2                	sd	s4,64(sp)
    800065c6:	fc56                	sd	s5,56(sp)
    800065c8:	f85a                	sd	s6,48(sp)
    800065ca:	f45e                	sd	s7,40(sp)
    800065cc:	f062                	sd	s8,32(sp)
    800065ce:	ec66                	sd	s9,24(sp)
    800065d0:	e86a                	sd	s10,16(sp)
    800065d2:	1880                	addi	s0,sp,112
    800065d4:	892a                	mv	s2,a0
    800065d6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065d8:	00c52c83          	lw	s9,12(a0)
    800065dc:	001c9c9b          	slliw	s9,s9,0x1
    800065e0:	1c82                	slli	s9,s9,0x20
    800065e2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800065e6:	0001c517          	auipc	a0,0x1c
    800065ea:	ed250513          	addi	a0,a0,-302 # 800224b8 <disk+0x128>
    800065ee:	ffffa097          	auipc	ra,0xffffa
    800065f2:	5fc080e7          	jalr	1532(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    800065f6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800065f8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800065fa:	0001cb17          	auipc	s6,0x1c
    800065fe:	d96b0b13          	addi	s6,s6,-618 # 80022390 <disk>
  for(int i = 0; i < 3; i++){
    80006602:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006604:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006606:	0001cc17          	auipc	s8,0x1c
    8000660a:	eb2c0c13          	addi	s8,s8,-334 # 800224b8 <disk+0x128>
    8000660e:	a8b5                	j	8000668a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006610:	00fb06b3          	add	a3,s6,a5
    80006614:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006618:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000661a:	0207c563          	bltz	a5,80006644 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000661e:	2485                	addiw	s1,s1,1
    80006620:	0711                	addi	a4,a4,4
    80006622:	1f548a63          	beq	s1,s5,80006816 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006626:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006628:	0001c697          	auipc	a3,0x1c
    8000662c:	d6868693          	addi	a3,a3,-664 # 80022390 <disk>
    80006630:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006632:	0186c583          	lbu	a1,24(a3)
    80006636:	fde9                	bnez	a1,80006610 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006638:	2785                	addiw	a5,a5,1
    8000663a:	0685                	addi	a3,a3,1
    8000663c:	ff779be3          	bne	a5,s7,80006632 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006640:	57fd                	li	a5,-1
    80006642:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006644:	02905a63          	blez	s1,80006678 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006648:	f9042503          	lw	a0,-112(s0)
    8000664c:	00000097          	auipc	ra,0x0
    80006650:	cfa080e7          	jalr	-774(ra) # 80006346 <free_desc>
      for(int j = 0; j < i; j++)
    80006654:	4785                	li	a5,1
    80006656:	0297d163          	bge	a5,s1,80006678 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000665a:	f9442503          	lw	a0,-108(s0)
    8000665e:	00000097          	auipc	ra,0x0
    80006662:	ce8080e7          	jalr	-792(ra) # 80006346 <free_desc>
      for(int j = 0; j < i; j++)
    80006666:	4789                	li	a5,2
    80006668:	0097d863          	bge	a5,s1,80006678 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000666c:	f9842503          	lw	a0,-104(s0)
    80006670:	00000097          	auipc	ra,0x0
    80006674:	cd6080e7          	jalr	-810(ra) # 80006346 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006678:	85e2                	mv	a1,s8
    8000667a:	0001c517          	auipc	a0,0x1c
    8000667e:	d2e50513          	addi	a0,a0,-722 # 800223a8 <disk+0x18>
    80006682:	ffffc097          	auipc	ra,0xffffc
    80006686:	efa080e7          	jalr	-262(ra) # 8000257c <sleep>
  for(int i = 0; i < 3; i++){
    8000668a:	f9040713          	addi	a4,s0,-112
    8000668e:	84ce                	mv	s1,s3
    80006690:	bf59                	j	80006626 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006692:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006696:	00479693          	slli	a3,a5,0x4
    8000669a:	0001c797          	auipc	a5,0x1c
    8000669e:	cf678793          	addi	a5,a5,-778 # 80022390 <disk>
    800066a2:	97b6                	add	a5,a5,a3
    800066a4:	4685                	li	a3,1
    800066a6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066a8:	0001c597          	auipc	a1,0x1c
    800066ac:	ce858593          	addi	a1,a1,-792 # 80022390 <disk>
    800066b0:	00a60793          	addi	a5,a2,10
    800066b4:	0792                	slli	a5,a5,0x4
    800066b6:	97ae                	add	a5,a5,a1
    800066b8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800066bc:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066c0:	f6070693          	addi	a3,a4,-160
    800066c4:	619c                	ld	a5,0(a1)
    800066c6:	97b6                	add	a5,a5,a3
    800066c8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066ca:	6188                	ld	a0,0(a1)
    800066cc:	96aa                	add	a3,a3,a0
    800066ce:	47c1                	li	a5,16
    800066d0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066d2:	4785                	li	a5,1
    800066d4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800066d8:	f9442783          	lw	a5,-108(s0)
    800066dc:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800066e0:	0792                	slli	a5,a5,0x4
    800066e2:	953e                	add	a0,a0,a5
    800066e4:	05890693          	addi	a3,s2,88
    800066e8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800066ea:	6188                	ld	a0,0(a1)
    800066ec:	97aa                	add	a5,a5,a0
    800066ee:	40000693          	li	a3,1024
    800066f2:	c794                	sw	a3,8(a5)
  if(write)
    800066f4:	100d0d63          	beqz	s10,8000680e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800066f8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800066fc:	00c7d683          	lhu	a3,12(a5)
    80006700:	0016e693          	ori	a3,a3,1
    80006704:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006708:	f9842583          	lw	a1,-104(s0)
    8000670c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006710:	0001c697          	auipc	a3,0x1c
    80006714:	c8068693          	addi	a3,a3,-896 # 80022390 <disk>
    80006718:	00260793          	addi	a5,a2,2
    8000671c:	0792                	slli	a5,a5,0x4
    8000671e:	97b6                	add	a5,a5,a3
    80006720:	587d                	li	a6,-1
    80006722:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006726:	0592                	slli	a1,a1,0x4
    80006728:	952e                	add	a0,a0,a1
    8000672a:	f9070713          	addi	a4,a4,-112
    8000672e:	9736                	add	a4,a4,a3
    80006730:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006732:	6298                	ld	a4,0(a3)
    80006734:	972e                	add	a4,a4,a1
    80006736:	4585                	li	a1,1
    80006738:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000673a:	4509                	li	a0,2
    8000673c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006740:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006744:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006748:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000674c:	6698                	ld	a4,8(a3)
    8000674e:	00275783          	lhu	a5,2(a4)
    80006752:	8b9d                	andi	a5,a5,7
    80006754:	0786                	slli	a5,a5,0x1
    80006756:	97ba                	add	a5,a5,a4
    80006758:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000675c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006760:	6698                	ld	a4,8(a3)
    80006762:	00275783          	lhu	a5,2(a4)
    80006766:	2785                	addiw	a5,a5,1
    80006768:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000676c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006770:	100017b7          	lui	a5,0x10001
    80006774:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006778:	00492703          	lw	a4,4(s2)
    8000677c:	4785                	li	a5,1
    8000677e:	02f71163          	bne	a4,a5,800067a0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006782:	0001c997          	auipc	s3,0x1c
    80006786:	d3698993          	addi	s3,s3,-714 # 800224b8 <disk+0x128>
  while(b->disk == 1) {
    8000678a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000678c:	85ce                	mv	a1,s3
    8000678e:	854a                	mv	a0,s2
    80006790:	ffffc097          	auipc	ra,0xffffc
    80006794:	dec080e7          	jalr	-532(ra) # 8000257c <sleep>
  while(b->disk == 1) {
    80006798:	00492783          	lw	a5,4(s2)
    8000679c:	fe9788e3          	beq	a5,s1,8000678c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800067a0:	f9042903          	lw	s2,-112(s0)
    800067a4:	00290793          	addi	a5,s2,2
    800067a8:	00479713          	slli	a4,a5,0x4
    800067ac:	0001c797          	auipc	a5,0x1c
    800067b0:	be478793          	addi	a5,a5,-1052 # 80022390 <disk>
    800067b4:	97ba                	add	a5,a5,a4
    800067b6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800067ba:	0001c997          	auipc	s3,0x1c
    800067be:	bd698993          	addi	s3,s3,-1066 # 80022390 <disk>
    800067c2:	00491713          	slli	a4,s2,0x4
    800067c6:	0009b783          	ld	a5,0(s3)
    800067ca:	97ba                	add	a5,a5,a4
    800067cc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800067d0:	854a                	mv	a0,s2
    800067d2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800067d6:	00000097          	auipc	ra,0x0
    800067da:	b70080e7          	jalr	-1168(ra) # 80006346 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800067de:	8885                	andi	s1,s1,1
    800067e0:	f0ed                	bnez	s1,800067c2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800067e2:	0001c517          	auipc	a0,0x1c
    800067e6:	cd650513          	addi	a0,a0,-810 # 800224b8 <disk+0x128>
    800067ea:	ffffa097          	auipc	ra,0xffffa
    800067ee:	4b4080e7          	jalr	1204(ra) # 80000c9e <release>
}
    800067f2:	70a6                	ld	ra,104(sp)
    800067f4:	7406                	ld	s0,96(sp)
    800067f6:	64e6                	ld	s1,88(sp)
    800067f8:	6946                	ld	s2,80(sp)
    800067fa:	69a6                	ld	s3,72(sp)
    800067fc:	6a06                	ld	s4,64(sp)
    800067fe:	7ae2                	ld	s5,56(sp)
    80006800:	7b42                	ld	s6,48(sp)
    80006802:	7ba2                	ld	s7,40(sp)
    80006804:	7c02                	ld	s8,32(sp)
    80006806:	6ce2                	ld	s9,24(sp)
    80006808:	6d42                	ld	s10,16(sp)
    8000680a:	6165                	addi	sp,sp,112
    8000680c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000680e:	4689                	li	a3,2
    80006810:	00d79623          	sh	a3,12(a5)
    80006814:	b5e5                	j	800066fc <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006816:	f9042603          	lw	a2,-112(s0)
    8000681a:	00a60713          	addi	a4,a2,10
    8000681e:	0712                	slli	a4,a4,0x4
    80006820:	0001c517          	auipc	a0,0x1c
    80006824:	b7850513          	addi	a0,a0,-1160 # 80022398 <disk+0x8>
    80006828:	953a                	add	a0,a0,a4
  if(write)
    8000682a:	e60d14e3          	bnez	s10,80006692 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000682e:	00a60793          	addi	a5,a2,10
    80006832:	00479693          	slli	a3,a5,0x4
    80006836:	0001c797          	auipc	a5,0x1c
    8000683a:	b5a78793          	addi	a5,a5,-1190 # 80022390 <disk>
    8000683e:	97b6                	add	a5,a5,a3
    80006840:	0007a423          	sw	zero,8(a5)
    80006844:	b595                	j	800066a8 <virtio_disk_rw+0xf0>

0000000080006846 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006846:	1101                	addi	sp,sp,-32
    80006848:	ec06                	sd	ra,24(sp)
    8000684a:	e822                	sd	s0,16(sp)
    8000684c:	e426                	sd	s1,8(sp)
    8000684e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006850:	0001c497          	auipc	s1,0x1c
    80006854:	b4048493          	addi	s1,s1,-1216 # 80022390 <disk>
    80006858:	0001c517          	auipc	a0,0x1c
    8000685c:	c6050513          	addi	a0,a0,-928 # 800224b8 <disk+0x128>
    80006860:	ffffa097          	auipc	ra,0xffffa
    80006864:	38a080e7          	jalr	906(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006868:	10001737          	lui	a4,0x10001
    8000686c:	533c                	lw	a5,96(a4)
    8000686e:	8b8d                	andi	a5,a5,3
    80006870:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006872:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006876:	689c                	ld	a5,16(s1)
    80006878:	0204d703          	lhu	a4,32(s1)
    8000687c:	0027d783          	lhu	a5,2(a5)
    80006880:	04f70863          	beq	a4,a5,800068d0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006884:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006888:	6898                	ld	a4,16(s1)
    8000688a:	0204d783          	lhu	a5,32(s1)
    8000688e:	8b9d                	andi	a5,a5,7
    80006890:	078e                	slli	a5,a5,0x3
    80006892:	97ba                	add	a5,a5,a4
    80006894:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006896:	00278713          	addi	a4,a5,2
    8000689a:	0712                	slli	a4,a4,0x4
    8000689c:	9726                	add	a4,a4,s1
    8000689e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800068a2:	e721                	bnez	a4,800068ea <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800068a4:	0789                	addi	a5,a5,2
    800068a6:	0792                	slli	a5,a5,0x4
    800068a8:	97a6                	add	a5,a5,s1
    800068aa:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800068ac:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800068b0:	ffffc097          	auipc	ra,0xffffc
    800068b4:	d30080e7          	jalr	-720(ra) # 800025e0 <wakeup>

    disk.used_idx += 1;
    800068b8:	0204d783          	lhu	a5,32(s1)
    800068bc:	2785                	addiw	a5,a5,1
    800068be:	17c2                	slli	a5,a5,0x30
    800068c0:	93c1                	srli	a5,a5,0x30
    800068c2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068c6:	6898                	ld	a4,16(s1)
    800068c8:	00275703          	lhu	a4,2(a4)
    800068cc:	faf71ce3          	bne	a4,a5,80006884 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800068d0:	0001c517          	auipc	a0,0x1c
    800068d4:	be850513          	addi	a0,a0,-1048 # 800224b8 <disk+0x128>
    800068d8:	ffffa097          	auipc	ra,0xffffa
    800068dc:	3c6080e7          	jalr	966(ra) # 80000c9e <release>
}
    800068e0:	60e2                	ld	ra,24(sp)
    800068e2:	6442                	ld	s0,16(sp)
    800068e4:	64a2                	ld	s1,8(sp)
    800068e6:	6105                	addi	sp,sp,32
    800068e8:	8082                	ret
      panic("virtio_disk_intr status");
    800068ea:	00002517          	auipc	a0,0x2
    800068ee:	03650513          	addi	a0,a0,54 # 80008920 <syscalls+0x3f0>
    800068f2:	ffffa097          	auipc	ra,0xffffa
    800068f6:	c52080e7          	jalr	-942(ra) # 80000544 <panic>
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

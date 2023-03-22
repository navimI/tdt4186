
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8f013103          	ld	sp,-1808(sp) # 800088f0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	8fe70713          	addi	a4,a4,-1794 # 80008950 <timer_scratch>
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
    80000068:	c3c78793          	addi	a5,a5,-964 # 80005ca0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca3f>
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
int
consolewrite(int user_src, uint64 src, int n)
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

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	39c080e7          	jalr	924(ra) # 800024c8 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
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
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
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
    80000190:	90450513          	addi	a0,a0,-1788 # 80010a90 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	8f448493          	addi	s1,s1,-1804 # 80010a90 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	98290913          	addi	s2,s2,-1662 # 80010b28 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	146080e7          	jalr	326(ra) # 80002312 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	e90080e7          	jalr	-368(ra) # 8000206a <sleep>
    while(cons.r == cons.w){
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
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	25c080e7          	jalr	604(ra) # 80002472 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	86650513          	addi	a0,a0,-1946 # 80010a90 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	85050513          	addi	a0,a0,-1968 # 80010a90 <cons>
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
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	8af72823          	sw	a5,-1872(a4) # 80010b28 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
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
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00010517          	auipc	a0,0x10
    800002d6:	7be50513          	addi	a0,a0,1982 # 80010a90 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	226080e7          	jalr	550(ra) # 8000251e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00010517          	auipc	a0,0x10
    80000304:	79050513          	addi	a0,a0,1936 # 80010a90 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00010717          	auipc	a4,0x10
    80000328:	76c70713          	addi	a4,a4,1900 # 80010a90 <cons>
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
    8000034e:	00010797          	auipc	a5,0x10
    80000352:	74278793          	addi	a5,a5,1858 # 80010a90 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00010797          	auipc	a5,0x10
    80000380:	7ac7a783          	lw	a5,1964(a5) # 80010b28 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	70070713          	addi	a4,a4,1792 # 80010a90 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	6f048493          	addi	s1,s1,1776 # 80010a90 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00010717          	auipc	a4,0x10
    800003e0:	6b470713          	addi	a4,a4,1716 # 80010a90 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00010717          	auipc	a4,0x10
    800003f6:	72f72f23          	sw	a5,1854(a4) # 80010b30 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	67878793          	addi	a5,a5,1656 # 80010a90 <cons>
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
    80000440:	6ec7a823          	sw	a2,1776(a5) # 80010b2c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	6e450513          	addi	a0,a0,1764 # 80010b28 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	c82080e7          	jalr	-894(ra) # 800020ce <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	62a50513          	addi	a0,a0,1578 # 80010a90 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00020797          	auipc	a5,0x20
    80000482:	7aa78793          	addi	a5,a5,1962 # 80020c28 <devsw>
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
    80000554:	6007a023          	sw	zero,1536(a5) # 80010b50 <pr+0x18>
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
    80000588:	38f72623          	sw	a5,908(a4) # 80008910 <panicked>
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
    800005c4:	590dad83          	lw	s11,1424(s11) # 80010b50 <pr+0x18>
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
    80000602:	53a50513          	addi	a0,a0,1338 # 80010b38 <pr>
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
    80000766:	3d650513          	addi	a0,a0,982 # 80010b38 <pr>
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
    80000782:	3ba48493          	addi	s1,s1,954 # 80010b38 <pr>
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
    800007e2:	37a50513          	addi	a0,a0,890 # 80010b58 <uart_tx_lock>
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
    8000080e:	1067a783          	lw	a5,262(a5) # 80008910 <panicked>
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
    8000084a:	0d273703          	ld	a4,210(a4) # 80008918 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	0d27b783          	ld	a5,210(a5) # 80008920 <uart_tx_w>
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
    80000874:	2e8a0a13          	addi	s4,s4,744 # 80010b58 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	0a048493          	addi	s1,s1,160 # 80008918 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	0a098993          	addi	s3,s3,160 # 80008920 <uart_tx_w>
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
    800008aa:	828080e7          	jalr	-2008(ra) # 800020ce <wakeup>
    
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
    800008e6:	27650513          	addi	a0,a0,630 # 80010b58 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	01e7a783          	lw	a5,30(a5) # 80008910 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	0247b783          	ld	a5,36(a5) # 80008920 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	01473703          	ld	a4,20(a4) # 80008918 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	248a0a13          	addi	s4,s4,584 # 80010b58 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	00048493          	mv	s1,s1
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	00090913          	mv	s2,s2
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	73a080e7          	jalr	1850(ra) # 8000206a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2) # 80008920 <uart_tx_w>
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	21248493          	addi	s1,s1,530 # 80010b58 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	fcf73323          	sd	a5,-58(a4) # 80008920 <uart_tx_w>
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
    800009d4:	18848493          	addi	s1,s1,392 # 80010b58 <uart_tx_lock>
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
    80000a12:	00021797          	auipc	a5,0x21
    80000a16:	3ae78793          	addi	a5,a5,942 # 80021dc0 <end>
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
    80000a36:	15e90913          	addi	s2,s2,350 # 80010b90 <kmem>
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
    80000ad2:	0c250513          	addi	a0,a0,194 # 80010b90 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00021517          	auipc	a0,0x21
    80000ae6:	2de50513          	addi	a0,a0,734 # 80021dc0 <end>
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
    80000b08:	08c48493          	addi	s1,s1,140 # 80010b90 <kmem>
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
    80000b20:	07450513          	addi	a0,a0,116 # 80010b90 <kmem>
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
    80000b4c:	04850513          	addi	a0,a0,72 # 80010b90 <kmem>
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
    80000b88:	e26080e7          	jalr	-474(ra) # 800019aa <mycpu>
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
    80000bba:	df4080e7          	jalr	-524(ra) # 800019aa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	de8080e7          	jalr	-536(ra) # 800019aa <mycpu>
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
    80000bde:	dd0080e7          	jalr	-560(ra) # 800019aa <mycpu>
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
    80000c1e:	d90080e7          	jalr	-624(ra) # 800019aa <mycpu>
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
    80000c4a:	d64080e7          	jalr	-668(ra) # 800019aa <mycpu>
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
    80000ea0:	afe080e7          	jalr	-1282(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	a8470713          	addi	a4,a4,-1404 # 80008928 <started>
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
    80000ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
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
    80000ede:	85a080e7          	jalr	-1958(ra) # 80002734 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	dfe080e7          	jalr	-514(ra) # 80005ce0 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	fce080e7          	jalr	-50(ra) # 80001eb8 <scheduler>
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
    80000f4e:	99c080e7          	jalr	-1636(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00001097          	auipc	ra,0x1
    80000f56:	7ba080e7          	jalr	1978(ra) # 8000270c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	7da080e7          	jalr	2010(ra) # 80002734 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	d68080e7          	jalr	-664(ra) # 80005cca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	d76080e7          	jalr	-650(ra) # 80005ce0 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	f30080e7          	jalr	-208(ra) # 80002ea2 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	5d4080e7          	jalr	1492(ra) # 8000354e <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	572080e7          	jalr	1394(ra) # 800044f4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	e5e080e7          	jalr	-418(ra) # 80005de8 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d0c080e7          	jalr	-756(ra) # 80001c9e <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	98f72423          	sw	a5,-1656(a4) # 80008928 <started>
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
    80000fb8:	97c7b783          	ld	a5,-1668(a5) # 80008930 <kernel_pagetable>
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
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
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
    80001274:	6ca7b023          	sd	a0,1728(a5) # 80008930 <kernel_pagetable>
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

0000000080001850 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
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
    80001864:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	0000f497          	auipc	s1,0xf
    8000186a:	77a48493          	addi	s1,s1,1914 # 80010fe0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001880:	00015a17          	auipc	s4,0x15
    80001884:	160a0a13          	addi	s4,s4,352 # 800169e0 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if(pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	858d                	srai	a1,a1,0x3
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ba:	16848493          	addi	s1,s1,360
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8e658593          	addi	a1,a1,-1818 # 800081e0 <digits+0x1a0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	2ae50513          	addi	a0,a0,686 # 80010bb0 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	2ae50513          	addi	a0,a0,686 # 80010bc8 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	0000f497          	auipc	s1,0xf
    8000192e:	6b648493          	addi	s1,s1,1718 # 80010fe0 <proc>
      initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8c6b0b13          	addi	s6,s6,-1850 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194c:	00015997          	auipc	s3,0x15
    80001950:	09498993          	addi	s3,s3,148 # 800169e0 <tickslock>
      initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	878d                	srai	a5,a5,0x3
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	16848493          	addi	s1,s1,360
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	22a50513          	addi	a0,a0,554 # 80010be0 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ce080e7          	jalr	462(ra) # 80000b9e <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	1d270713          	addi	a4,a4,466 # 80010bb0 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	254080e7          	jalr	596(ra) # 80000c3e <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	290080e7          	jalr	656(ra) # 80000c9e <release>

  if (first) {
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e8a7a783          	lw	a5,-374(a5) # 800088a0 <first.1680>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	d2c080e7          	jalr	-724(ra) # 8000274c <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	e607a823          	sw	zero,-400(a5) # 800088a0 <first.1680>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	a94080e7          	jalr	-1388(ra) # 800034ce <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	16090913          	addi	s2,s2,352 # 80010bb0 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	e4278793          	addi	a5,a5,-446 # 800088a4 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	22a080e7          	jalr	554(ra) # 80000c9e <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8ac080e7          	jalr	-1876(ra) # 80001344 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	602080e7          	jalr	1538(ra) # 800010ba <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	05893683          	ld	a3,88(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e4080e7          	jalr	1508(ra) # 800010ba <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	772080e7          	jalr	1906(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73e080e7          	jalr	1854(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	728080e7          	jalr	1832(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b84:	6d28                	ld	a0,88(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001b90:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b94:	68a8                	ld	a0,80(s1)
    80001b96:	c511                	beqz	a0,80001ba2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b98:	64ac                	ld	a1,72(s1)
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	f8c080e7          	jalr	-116(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001ba2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001baa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bae:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bbe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc2:	0004ac23          	sw	zero,24(s1)
}
    80001bc6:	60e2                	ld	ra,24(sp)
    80001bc8:	6442                	ld	s0,16(sp)
    80001bca:	64a2                	ld	s1,8(sp)
    80001bcc:	6105                	addi	sp,sp,32
    80001bce:	8082                	ret

0000000080001bd0 <allocproc>:
{
    80001bd0:	1101                	addi	sp,sp,-32
    80001bd2:	ec06                	sd	ra,24(sp)
    80001bd4:	e822                	sd	s0,16(sp)
    80001bd6:	e426                	sd	s1,8(sp)
    80001bd8:	e04a                	sd	s2,0(sp)
    80001bda:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bdc:	0000f497          	auipc	s1,0xf
    80001be0:	40448493          	addi	s1,s1,1028 # 80010fe0 <proc>
    80001be4:	00015917          	auipc	s2,0x15
    80001be8:	dfc90913          	addi	s2,s2,-516 # 800169e0 <tickslock>
    acquire(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ffc080e7          	jalr	-4(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001bf6:	4c9c                	lw	a5,24(s1)
    80001bf8:	cf81                	beqz	a5,80001c10 <allocproc+0x40>
      release(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0a2080e7          	jalr	162(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c04:	16848493          	addi	s1,s1,360
    80001c08:	ff2492e3          	bne	s1,s2,80001bec <allocproc+0x1c>
  return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	a889                	j	80001c60 <allocproc+0x90>
  p->pid = allocpid();
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	e34080e7          	jalr	-460(ra) # 80001a44 <allocpid>
    80001c18:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1a:	4785                	li	a5,1
    80001c1c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	edc080e7          	jalr	-292(ra) # 80000afa <kalloc>
    80001c26:	892a                	mv	s2,a0
    80001c28:	eca8                	sd	a0,88(s1)
    80001c2a:	c131                	beqz	a0,80001c6e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	e5c080e7          	jalr	-420(ra) # 80001a8a <proc_pagetable>
    80001c36:	892a                	mv	s2,a0
    80001c38:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c3a:	c531                	beqz	a0,80001c86 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c3c:	07000613          	li	a2,112
    80001c40:	4581                	li	a1,0
    80001c42:	06048513          	addi	a0,s1,96
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	0a0080e7          	jalr	160(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c4e:	00000797          	auipc	a5,0x0
    80001c52:	db078793          	addi	a5,a5,-592 # 800019fe <forkret>
    80001c56:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c58:	60bc                	ld	a5,64(s1)
    80001c5a:	6705                	lui	a4,0x1
    80001c5c:	97ba                	add	a5,a5,a4
    80001c5e:	f4bc                	sd	a5,104(s1)
}
    80001c60:	8526                	mv	a0,s1
    80001c62:	60e2                	ld	ra,24(sp)
    80001c64:	6442                	ld	s0,16(sp)
    80001c66:	64a2                	ld	s1,8(sp)
    80001c68:	6902                	ld	s2,0(sp)
    80001c6a:	6105                	addi	sp,sp,32
    80001c6c:	8082                	ret
    freeproc(p);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	00000097          	auipc	ra,0x0
    80001c74:	f08080e7          	jalr	-248(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	024080e7          	jalr	36(ra) # 80000c9e <release>
    return 0;
    80001c82:	84ca                	mv	s1,s2
    80001c84:	bff1                	j	80001c60 <allocproc+0x90>
    freeproc(p);
    80001c86:	8526                	mv	a0,s1
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	ef0080e7          	jalr	-272(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c90:	8526                	mv	a0,s1
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	00c080e7          	jalr	12(ra) # 80000c9e <release>
    return 0;
    80001c9a:	84ca                	mv	s1,s2
    80001c9c:	b7d1                	j	80001c60 <allocproc+0x90>

0000000080001c9e <userinit>:
{
    80001c9e:	1101                	addi	sp,sp,-32
    80001ca0:	ec06                	sd	ra,24(sp)
    80001ca2:	e822                	sd	s0,16(sp)
    80001ca4:	e426                	sd	s1,8(sp)
    80001ca6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	f28080e7          	jalr	-216(ra) # 80001bd0 <allocproc>
    80001cb0:	84aa                	mv	s1,a0
  initproc = p;
    80001cb2:	00007797          	auipc	a5,0x7
    80001cb6:	c8a7b323          	sd	a0,-890(a5) # 80008938 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cba:	03400613          	li	a2,52
    80001cbe:	00007597          	auipc	a1,0x7
    80001cc2:	bf258593          	addi	a1,a1,-1038 # 800088b0 <initcode>
    80001cc6:	6928                	ld	a0,80(a0)
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	6aa080e7          	jalr	1706(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001cd0:	6785                	lui	a5,0x1
    80001cd2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cda:	6cb8                	ld	a4,88(s1)
    80001cdc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cde:	4641                	li	a2,16
    80001ce0:	00006597          	auipc	a1,0x6
    80001ce4:	52058593          	addi	a1,a1,1312 # 80008200 <digits+0x1c0>
    80001ce8:	15848513          	addi	a0,s1,344
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	14c080e7          	jalr	332(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001cf4:	00006517          	auipc	a0,0x6
    80001cf8:	51c50513          	addi	a0,a0,1308 # 80008210 <digits+0x1d0>
    80001cfc:	00002097          	auipc	ra,0x2
    80001d00:	1f4080e7          	jalr	500(ra) # 80003ef0 <namei>
    80001d04:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d08:	478d                	li	a5,3
    80001d0a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	f90080e7          	jalr	-112(ra) # 80000c9e <release>
}
    80001d16:	60e2                	ld	ra,24(sp)
    80001d18:	6442                	ld	s0,16(sp)
    80001d1a:	64a2                	ld	s1,8(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret

0000000080001d20 <growproc>:
{
    80001d20:	1101                	addi	sp,sp,-32
    80001d22:	ec06                	sd	ra,24(sp)
    80001d24:	e822                	sd	s0,16(sp)
    80001d26:	e426                	sd	s1,8(sp)
    80001d28:	e04a                	sd	s2,0(sp)
    80001d2a:	1000                	addi	s0,sp,32
    80001d2c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d2e:	00000097          	auipc	ra,0x0
    80001d32:	c98080e7          	jalr	-872(ra) # 800019c6 <myproc>
    80001d36:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d38:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d3a:	01204c63          	bgtz	s2,80001d52 <growproc+0x32>
  } else if(n < 0){
    80001d3e:	02094663          	bltz	s2,80001d6a <growproc+0x4a>
  p->sz = sz;
    80001d42:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d44:	4501                	li	a0,0
}
    80001d46:	60e2                	ld	ra,24(sp)
    80001d48:	6442                	ld	s0,16(sp)
    80001d4a:	64a2                	ld	s1,8(sp)
    80001d4c:	6902                	ld	s2,0(sp)
    80001d4e:	6105                	addi	sp,sp,32
    80001d50:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d52:	4691                	li	a3,4
    80001d54:	00b90633          	add	a2,s2,a1
    80001d58:	6928                	ld	a0,80(a0)
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	6d2080e7          	jalr	1746(ra) # 8000142c <uvmalloc>
    80001d62:	85aa                	mv	a1,a0
    80001d64:	fd79                	bnez	a0,80001d42 <growproc+0x22>
      return -1;
    80001d66:	557d                	li	a0,-1
    80001d68:	bff9                	j	80001d46 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d6a:	00b90633          	add	a2,s2,a1
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	674080e7          	jalr	1652(ra) # 800013e4 <uvmdealloc>
    80001d78:	85aa                	mv	a1,a0
    80001d7a:	b7e1                	j	80001d42 <growproc+0x22>

0000000080001d7c <fork>:
{
    80001d7c:	7179                	addi	sp,sp,-48
    80001d7e:	f406                	sd	ra,40(sp)
    80001d80:	f022                	sd	s0,32(sp)
    80001d82:	ec26                	sd	s1,24(sp)
    80001d84:	e84a                	sd	s2,16(sp)
    80001d86:	e44e                	sd	s3,8(sp)
    80001d88:	e052                	sd	s4,0(sp)
    80001d8a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	c3a080e7          	jalr	-966(ra) # 800019c6 <myproc>
    80001d94:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	e3a080e7          	jalr	-454(ra) # 80001bd0 <allocproc>
    80001d9e:	10050b63          	beqz	a0,80001eb4 <fork+0x138>
    80001da2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da4:	04893603          	ld	a2,72(s2)
    80001da8:	692c                	ld	a1,80(a0)
    80001daa:	05093503          	ld	a0,80(s2)
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	7d2080e7          	jalr	2002(ra) # 80001580 <uvmcopy>
    80001db6:	04054663          	bltz	a0,80001e02 <fork+0x86>
  np->sz = p->sz;
    80001dba:	04893783          	ld	a5,72(s2)
    80001dbe:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc2:	05893683          	ld	a3,88(s2)
    80001dc6:	87b6                	mv	a5,a3
    80001dc8:	0589b703          	ld	a4,88(s3)
    80001dcc:	12068693          	addi	a3,a3,288
    80001dd0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd4:	6788                	ld	a0,8(a5)
    80001dd6:	6b8c                	ld	a1,16(a5)
    80001dd8:	6f90                	ld	a2,24(a5)
    80001dda:	01073023          	sd	a6,0(a4)
    80001dde:	e708                	sd	a0,8(a4)
    80001de0:	eb0c                	sd	a1,16(a4)
    80001de2:	ef10                	sd	a2,24(a4)
    80001de4:	02078793          	addi	a5,a5,32
    80001de8:	02070713          	addi	a4,a4,32
    80001dec:	fed792e3          	bne	a5,a3,80001dd0 <fork+0x54>
  np->trapframe->a0 = 0;
    80001df0:	0589b783          	ld	a5,88(s3)
    80001df4:	0607b823          	sd	zero,112(a5)
    80001df8:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dfc:	15000a13          	li	s4,336
    80001e00:	a03d                	j	80001e2e <fork+0xb2>
    freeproc(np);
    80001e02:	854e                	mv	a0,s3
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	d74080e7          	jalr	-652(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e0c:	854e                	mv	a0,s3
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	e90080e7          	jalr	-368(ra) # 80000c9e <release>
    return -1;
    80001e16:	5a7d                	li	s4,-1
    80001e18:	a069                	j	80001ea2 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1a:	00002097          	auipc	ra,0x2
    80001e1e:	76c080e7          	jalr	1900(ra) # 80004586 <filedup>
    80001e22:	009987b3          	add	a5,s3,s1
    80001e26:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e28:	04a1                	addi	s1,s1,8
    80001e2a:	01448763          	beq	s1,s4,80001e38 <fork+0xbc>
    if(p->ofile[i])
    80001e2e:	009907b3          	add	a5,s2,s1
    80001e32:	6388                	ld	a0,0(a5)
    80001e34:	f17d                	bnez	a0,80001e1a <fork+0x9e>
    80001e36:	bfcd                	j	80001e28 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e38:	15093503          	ld	a0,336(s2)
    80001e3c:	00002097          	auipc	ra,0x2
    80001e40:	8d0080e7          	jalr	-1840(ra) # 8000370c <idup>
    80001e44:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e48:	4641                	li	a2,16
    80001e4a:	15890593          	addi	a1,s2,344
    80001e4e:	15898513          	addi	a0,s3,344
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	fe6080e7          	jalr	-26(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e5a:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e5e:	854e                	mv	a0,s3
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	e3e080e7          	jalr	-450(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001e68:	0000f497          	auipc	s1,0xf
    80001e6c:	d6048493          	addi	s1,s1,-672 # 80010bc8 <wait_lock>
    80001e70:	8526                	mv	a0,s1
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d78080e7          	jalr	-648(ra) # 80000bea <acquire>
  np->parent = p;
    80001e7a:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e7e:	8526                	mv	a0,s1
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	e1e080e7          	jalr	-482(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001e88:	854e                	mv	a0,s3
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	d60080e7          	jalr	-672(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001e92:	478d                	li	a5,3
    80001e94:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e98:	854e                	mv	a0,s3
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	e04080e7          	jalr	-508(ra) # 80000c9e <release>
}
    80001ea2:	8552                	mv	a0,s4
    80001ea4:	70a2                	ld	ra,40(sp)
    80001ea6:	7402                	ld	s0,32(sp)
    80001ea8:	64e2                	ld	s1,24(sp)
    80001eaa:	6942                	ld	s2,16(sp)
    80001eac:	69a2                	ld	s3,8(sp)
    80001eae:	6a02                	ld	s4,0(sp)
    80001eb0:	6145                	addi	sp,sp,48
    80001eb2:	8082                	ret
    return -1;
    80001eb4:	5a7d                	li	s4,-1
    80001eb6:	b7f5                	j	80001ea2 <fork+0x126>

0000000080001eb8 <scheduler>:
{
    80001eb8:	7139                	addi	sp,sp,-64
    80001eba:	fc06                	sd	ra,56(sp)
    80001ebc:	f822                	sd	s0,48(sp)
    80001ebe:	f426                	sd	s1,40(sp)
    80001ec0:	f04a                	sd	s2,32(sp)
    80001ec2:	ec4e                	sd	s3,24(sp)
    80001ec4:	e852                	sd	s4,16(sp)
    80001ec6:	e456                	sd	s5,8(sp)
    80001ec8:	e05a                	sd	s6,0(sp)
    80001eca:	0080                	addi	s0,sp,64
    80001ecc:	8792                	mv	a5,tp
  int id = r_tp();
    80001ece:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ed0:	00779a93          	slli	s5,a5,0x7
    80001ed4:	0000f717          	auipc	a4,0xf
    80001ed8:	cdc70713          	addi	a4,a4,-804 # 80010bb0 <pid_lock>
    80001edc:	9756                	add	a4,a4,s5
    80001ede:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ee2:	0000f717          	auipc	a4,0xf
    80001ee6:	d0670713          	addi	a4,a4,-762 # 80010be8 <cpus+0x8>
    80001eea:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001eec:	498d                	li	s3,3
        p->state = RUNNING;
    80001eee:	4b11                	li	s6,4
        c->proc = p;
    80001ef0:	079e                	slli	a5,a5,0x7
    80001ef2:	0000fa17          	auipc	s4,0xf
    80001ef6:	cbea0a13          	addi	s4,s4,-834 # 80010bb0 <pid_lock>
    80001efa:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001efc:	00015917          	auipc	s2,0x15
    80001f00:	ae490913          	addi	s2,s2,-1308 # 800169e0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f04:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f08:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f0c:	10079073          	csrw	sstatus,a5
    80001f10:	0000f497          	auipc	s1,0xf
    80001f14:	0d048493          	addi	s1,s1,208 # 80010fe0 <proc>
    80001f18:	a03d                	j	80001f46 <scheduler+0x8e>
        p->state = RUNNING;
    80001f1a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f1e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f22:	06048593          	addi	a1,s1,96
    80001f26:	8556                	mv	a0,s5
    80001f28:	00000097          	auipc	ra,0x0
    80001f2c:	77a080e7          	jalr	1914(ra) # 800026a2 <swtch>
        c->proc = 0;
    80001f30:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	d68080e7          	jalr	-664(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f3e:	16848493          	addi	s1,s1,360
    80001f42:	fd2481e3          	beq	s1,s2,80001f04 <scheduler+0x4c>
      acquire(&p->lock);
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	ca2080e7          	jalr	-862(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    80001f50:	4c9c                	lw	a5,24(s1)
    80001f52:	ff3791e3          	bne	a5,s3,80001f34 <scheduler+0x7c>
    80001f56:	b7d1                	j	80001f1a <scheduler+0x62>

0000000080001f58 <sched>:
{
    80001f58:	7179                	addi	sp,sp,-48
    80001f5a:	f406                	sd	ra,40(sp)
    80001f5c:	f022                	sd	s0,32(sp)
    80001f5e:	ec26                	sd	s1,24(sp)
    80001f60:	e84a                	sd	s2,16(sp)
    80001f62:	e44e                	sd	s3,8(sp)
    80001f64:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	a60080e7          	jalr	-1440(ra) # 800019c6 <myproc>
    80001f6e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	c00080e7          	jalr	-1024(ra) # 80000b70 <holding>
    80001f78:	c93d                	beqz	a0,80001fee <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f7a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f7c:	2781                	sext.w	a5,a5
    80001f7e:	079e                	slli	a5,a5,0x7
    80001f80:	0000f717          	auipc	a4,0xf
    80001f84:	c3070713          	addi	a4,a4,-976 # 80010bb0 <pid_lock>
    80001f88:	97ba                	add	a5,a5,a4
    80001f8a:	0a87a703          	lw	a4,168(a5)
    80001f8e:	4785                	li	a5,1
    80001f90:	06f71763          	bne	a4,a5,80001ffe <sched+0xa6>
  if(p->state == RUNNING)
    80001f94:	4c98                	lw	a4,24(s1)
    80001f96:	4791                	li	a5,4
    80001f98:	06f70b63          	beq	a4,a5,8000200e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fa0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fa2:	efb5                	bnez	a5,8000201e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fa6:	0000f917          	auipc	s2,0xf
    80001faa:	c0a90913          	addi	s2,s2,-1014 # 80010bb0 <pid_lock>
    80001fae:	2781                	sext.w	a5,a5
    80001fb0:	079e                	slli	a5,a5,0x7
    80001fb2:	97ca                	add	a5,a5,s2
    80001fb4:	0ac7a983          	lw	s3,172(a5)
    80001fb8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fba:	2781                	sext.w	a5,a5
    80001fbc:	079e                	slli	a5,a5,0x7
    80001fbe:	0000f597          	auipc	a1,0xf
    80001fc2:	c2a58593          	addi	a1,a1,-982 # 80010be8 <cpus+0x8>
    80001fc6:	95be                	add	a1,a1,a5
    80001fc8:	06048513          	addi	a0,s1,96
    80001fcc:	00000097          	auipc	ra,0x0
    80001fd0:	6d6080e7          	jalr	1750(ra) # 800026a2 <swtch>
    80001fd4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fd6:	2781                	sext.w	a5,a5
    80001fd8:	079e                	slli	a5,a5,0x7
    80001fda:	97ca                	add	a5,a5,s2
    80001fdc:	0b37a623          	sw	s3,172(a5)
}
    80001fe0:	70a2                	ld	ra,40(sp)
    80001fe2:	7402                	ld	s0,32(sp)
    80001fe4:	64e2                	ld	s1,24(sp)
    80001fe6:	6942                	ld	s2,16(sp)
    80001fe8:	69a2                	ld	s3,8(sp)
    80001fea:	6145                	addi	sp,sp,48
    80001fec:	8082                	ret
    panic("sched p->lock");
    80001fee:	00006517          	auipc	a0,0x6
    80001ff2:	22a50513          	addi	a0,a0,554 # 80008218 <digits+0x1d8>
    80001ff6:	ffffe097          	auipc	ra,0xffffe
    80001ffa:	54e080e7          	jalr	1358(ra) # 80000544 <panic>
    panic("sched locks");
    80001ffe:	00006517          	auipc	a0,0x6
    80002002:	22a50513          	addi	a0,a0,554 # 80008228 <digits+0x1e8>
    80002006:	ffffe097          	auipc	ra,0xffffe
    8000200a:	53e080e7          	jalr	1342(ra) # 80000544 <panic>
    panic("sched running");
    8000200e:	00006517          	auipc	a0,0x6
    80002012:	22a50513          	addi	a0,a0,554 # 80008238 <digits+0x1f8>
    80002016:	ffffe097          	auipc	ra,0xffffe
    8000201a:	52e080e7          	jalr	1326(ra) # 80000544 <panic>
    panic("sched interruptible");
    8000201e:	00006517          	auipc	a0,0x6
    80002022:	22a50513          	addi	a0,a0,554 # 80008248 <digits+0x208>
    80002026:	ffffe097          	auipc	ra,0xffffe
    8000202a:	51e080e7          	jalr	1310(ra) # 80000544 <panic>

000000008000202e <yield>:
{
    8000202e:	1101                	addi	sp,sp,-32
    80002030:	ec06                	sd	ra,24(sp)
    80002032:	e822                	sd	s0,16(sp)
    80002034:	e426                	sd	s1,8(sp)
    80002036:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	98e080e7          	jalr	-1650(ra) # 800019c6 <myproc>
    80002040:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	ba8080e7          	jalr	-1112(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    8000204a:	478d                	li	a5,3
    8000204c:	cc9c                	sw	a5,24(s1)
  sched();
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	f0a080e7          	jalr	-246(ra) # 80001f58 <sched>
  release(&p->lock);
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	c46080e7          	jalr	-954(ra) # 80000c9e <release>
}
    80002060:	60e2                	ld	ra,24(sp)
    80002062:	6442                	ld	s0,16(sp)
    80002064:	64a2                	ld	s1,8(sp)
    80002066:	6105                	addi	sp,sp,32
    80002068:	8082                	ret

000000008000206a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000206a:	7179                	addi	sp,sp,-48
    8000206c:	f406                	sd	ra,40(sp)
    8000206e:	f022                	sd	s0,32(sp)
    80002070:	ec26                	sd	s1,24(sp)
    80002072:	e84a                	sd	s2,16(sp)
    80002074:	e44e                	sd	s3,8(sp)
    80002076:	1800                	addi	s0,sp,48
    80002078:	89aa                	mv	s3,a0
    8000207a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	94a080e7          	jalr	-1718(ra) # 800019c6 <myproc>
    80002084:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b64080e7          	jalr	-1180(ra) # 80000bea <acquire>
  release(lk);
    8000208e:	854a                	mv	a0,s2
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	c0e080e7          	jalr	-1010(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002098:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000209c:	4789                	li	a5,2
    8000209e:	cc9c                	sw	a5,24(s1)

  sched();
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	eb8080e7          	jalr	-328(ra) # 80001f58 <sched>

  // Tidy up.
  p->chan = 0;
    800020a8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020ac:	8526                	mv	a0,s1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	bf0080e7          	jalr	-1040(ra) # 80000c9e <release>
  acquire(lk);
    800020b6:	854a                	mv	a0,s2
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	b32080e7          	jalr	-1230(ra) # 80000bea <acquire>
}
    800020c0:	70a2                	ld	ra,40(sp)
    800020c2:	7402                	ld	s0,32(sp)
    800020c4:	64e2                	ld	s1,24(sp)
    800020c6:	6942                	ld	s2,16(sp)
    800020c8:	69a2                	ld	s3,8(sp)
    800020ca:	6145                	addi	sp,sp,48
    800020cc:	8082                	ret

00000000800020ce <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020ce:	7139                	addi	sp,sp,-64
    800020d0:	fc06                	sd	ra,56(sp)
    800020d2:	f822                	sd	s0,48(sp)
    800020d4:	f426                	sd	s1,40(sp)
    800020d6:	f04a                	sd	s2,32(sp)
    800020d8:	ec4e                	sd	s3,24(sp)
    800020da:	e852                	sd	s4,16(sp)
    800020dc:	e456                	sd	s5,8(sp)
    800020de:	0080                	addi	s0,sp,64
    800020e0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020e2:	0000f497          	auipc	s1,0xf
    800020e6:	efe48493          	addi	s1,s1,-258 # 80010fe0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020ea:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020ec:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ee:	00015917          	auipc	s2,0x15
    800020f2:	8f290913          	addi	s2,s2,-1806 # 800169e0 <tickslock>
    800020f6:	a821                	j	8000210e <wakeup+0x40>
        p->state = RUNNABLE;
    800020f8:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800020fc:	8526                	mv	a0,s1
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	ba0080e7          	jalr	-1120(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002106:	16848493          	addi	s1,s1,360
    8000210a:	03248463          	beq	s1,s2,80002132 <wakeup+0x64>
    if(p != myproc()){
    8000210e:	00000097          	auipc	ra,0x0
    80002112:	8b8080e7          	jalr	-1864(ra) # 800019c6 <myproc>
    80002116:	fea488e3          	beq	s1,a0,80002106 <wakeup+0x38>
      acquire(&p->lock);
    8000211a:	8526                	mv	a0,s1
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	ace080e7          	jalr	-1330(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002124:	4c9c                	lw	a5,24(s1)
    80002126:	fd379be3          	bne	a5,s3,800020fc <wakeup+0x2e>
    8000212a:	709c                	ld	a5,32(s1)
    8000212c:	fd4798e3          	bne	a5,s4,800020fc <wakeup+0x2e>
    80002130:	b7e1                	j	800020f8 <wakeup+0x2a>
    }
  }
}
    80002132:	70e2                	ld	ra,56(sp)
    80002134:	7442                	ld	s0,48(sp)
    80002136:	74a2                	ld	s1,40(sp)
    80002138:	7902                	ld	s2,32(sp)
    8000213a:	69e2                	ld	s3,24(sp)
    8000213c:	6a42                	ld	s4,16(sp)
    8000213e:	6aa2                	ld	s5,8(sp)
    80002140:	6121                	addi	sp,sp,64
    80002142:	8082                	ret

0000000080002144 <reparent>:
{
    80002144:	7179                	addi	sp,sp,-48
    80002146:	f406                	sd	ra,40(sp)
    80002148:	f022                	sd	s0,32(sp)
    8000214a:	ec26                	sd	s1,24(sp)
    8000214c:	e84a                	sd	s2,16(sp)
    8000214e:	e44e                	sd	s3,8(sp)
    80002150:	e052                	sd	s4,0(sp)
    80002152:	1800                	addi	s0,sp,48
    80002154:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002156:	0000f497          	auipc	s1,0xf
    8000215a:	e8a48493          	addi	s1,s1,-374 # 80010fe0 <proc>
      pp->parent = initproc;
    8000215e:	00006a17          	auipc	s4,0x6
    80002162:	7daa0a13          	addi	s4,s4,2010 # 80008938 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002166:	00015997          	auipc	s3,0x15
    8000216a:	87a98993          	addi	s3,s3,-1926 # 800169e0 <tickslock>
    8000216e:	a029                	j	80002178 <reparent+0x34>
    80002170:	16848493          	addi	s1,s1,360
    80002174:	01348d63          	beq	s1,s3,8000218e <reparent+0x4a>
    if(pp->parent == p){
    80002178:	7c9c                	ld	a5,56(s1)
    8000217a:	ff279be3          	bne	a5,s2,80002170 <reparent+0x2c>
      pp->parent = initproc;
    8000217e:	000a3503          	ld	a0,0(s4)
    80002182:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002184:	00000097          	auipc	ra,0x0
    80002188:	f4a080e7          	jalr	-182(ra) # 800020ce <wakeup>
    8000218c:	b7d5                	j	80002170 <reparent+0x2c>
}
    8000218e:	70a2                	ld	ra,40(sp)
    80002190:	7402                	ld	s0,32(sp)
    80002192:	64e2                	ld	s1,24(sp)
    80002194:	6942                	ld	s2,16(sp)
    80002196:	69a2                	ld	s3,8(sp)
    80002198:	6a02                	ld	s4,0(sp)
    8000219a:	6145                	addi	sp,sp,48
    8000219c:	8082                	ret

000000008000219e <exit>:
{
    8000219e:	7179                	addi	sp,sp,-48
    800021a0:	f406                	sd	ra,40(sp)
    800021a2:	f022                	sd	s0,32(sp)
    800021a4:	ec26                	sd	s1,24(sp)
    800021a6:	e84a                	sd	s2,16(sp)
    800021a8:	e44e                	sd	s3,8(sp)
    800021aa:	e052                	sd	s4,0(sp)
    800021ac:	1800                	addi	s0,sp,48
    800021ae:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021b0:	00000097          	auipc	ra,0x0
    800021b4:	816080e7          	jalr	-2026(ra) # 800019c6 <myproc>
    800021b8:	89aa                	mv	s3,a0
  if(p == initproc)
    800021ba:	00006797          	auipc	a5,0x6
    800021be:	77e7b783          	ld	a5,1918(a5) # 80008938 <initproc>
    800021c2:	0d050493          	addi	s1,a0,208
    800021c6:	15050913          	addi	s2,a0,336
    800021ca:	02a79363          	bne	a5,a0,800021f0 <exit+0x52>
    panic("init exiting");
    800021ce:	00006517          	auipc	a0,0x6
    800021d2:	09250513          	addi	a0,a0,146 # 80008260 <digits+0x220>
    800021d6:	ffffe097          	auipc	ra,0xffffe
    800021da:	36e080e7          	jalr	878(ra) # 80000544 <panic>
      fileclose(f);
    800021de:	00002097          	auipc	ra,0x2
    800021e2:	3fa080e7          	jalr	1018(ra) # 800045d8 <fileclose>
      p->ofile[fd] = 0;
    800021e6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021ea:	04a1                	addi	s1,s1,8
    800021ec:	01248563          	beq	s1,s2,800021f6 <exit+0x58>
    if(p->ofile[fd]){
    800021f0:	6088                	ld	a0,0(s1)
    800021f2:	f575                	bnez	a0,800021de <exit+0x40>
    800021f4:	bfdd                	j	800021ea <exit+0x4c>
  begin_op();
    800021f6:	00002097          	auipc	ra,0x2
    800021fa:	f16080e7          	jalr	-234(ra) # 8000410c <begin_op>
  iput(p->cwd);
    800021fe:	1509b503          	ld	a0,336(s3)
    80002202:	00001097          	auipc	ra,0x1
    80002206:	702080e7          	jalr	1794(ra) # 80003904 <iput>
  end_op();
    8000220a:	00002097          	auipc	ra,0x2
    8000220e:	f82080e7          	jalr	-126(ra) # 8000418c <end_op>
  p->cwd = 0;
    80002212:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002216:	0000f497          	auipc	s1,0xf
    8000221a:	9b248493          	addi	s1,s1,-1614 # 80010bc8 <wait_lock>
    8000221e:	8526                	mv	a0,s1
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	9ca080e7          	jalr	-1590(ra) # 80000bea <acquire>
  reparent(p);
    80002228:	854e                	mv	a0,s3
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	f1a080e7          	jalr	-230(ra) # 80002144 <reparent>
  wakeup(p->parent);
    80002232:	0389b503          	ld	a0,56(s3)
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	e98080e7          	jalr	-360(ra) # 800020ce <wakeup>
  acquire(&p->lock);
    8000223e:	854e                	mv	a0,s3
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	9aa080e7          	jalr	-1622(ra) # 80000bea <acquire>
  p->xstate = status;
    80002248:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000224c:	4795                	li	a5,5
    8000224e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002252:	8526                	mv	a0,s1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	a4a080e7          	jalr	-1462(ra) # 80000c9e <release>
  sched();
    8000225c:	00000097          	auipc	ra,0x0
    80002260:	cfc080e7          	jalr	-772(ra) # 80001f58 <sched>
  panic("zombie exit");
    80002264:	00006517          	auipc	a0,0x6
    80002268:	00c50513          	addi	a0,a0,12 # 80008270 <digits+0x230>
    8000226c:	ffffe097          	auipc	ra,0xffffe
    80002270:	2d8080e7          	jalr	728(ra) # 80000544 <panic>

0000000080002274 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002274:	7179                	addi	sp,sp,-48
    80002276:	f406                	sd	ra,40(sp)
    80002278:	f022                	sd	s0,32(sp)
    8000227a:	ec26                	sd	s1,24(sp)
    8000227c:	e84a                	sd	s2,16(sp)
    8000227e:	e44e                	sd	s3,8(sp)
    80002280:	1800                	addi	s0,sp,48
    80002282:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002284:	0000f497          	auipc	s1,0xf
    80002288:	d5c48493          	addi	s1,s1,-676 # 80010fe0 <proc>
    8000228c:	00014997          	auipc	s3,0x14
    80002290:	75498993          	addi	s3,s3,1876 # 800169e0 <tickslock>
    acquire(&p->lock);
    80002294:	8526                	mv	a0,s1
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	954080e7          	jalr	-1708(ra) # 80000bea <acquire>
    if(p->pid == pid){
    8000229e:	589c                	lw	a5,48(s1)
    800022a0:	01278d63          	beq	a5,s2,800022ba <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	9f8080e7          	jalr	-1544(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022ae:	16848493          	addi	s1,s1,360
    800022b2:	ff3491e3          	bne	s1,s3,80002294 <kill+0x20>
  }
  return -1;
    800022b6:	557d                	li	a0,-1
    800022b8:	a829                	j	800022d2 <kill+0x5e>
      p->killed = 1;
    800022ba:	4785                	li	a5,1
    800022bc:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022be:	4c98                	lw	a4,24(s1)
    800022c0:	4789                	li	a5,2
    800022c2:	00f70f63          	beq	a4,a5,800022e0 <kill+0x6c>
      release(&p->lock);
    800022c6:	8526                	mv	a0,s1
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	9d6080e7          	jalr	-1578(ra) # 80000c9e <release>
      return 0;
    800022d0:	4501                	li	a0,0
}
    800022d2:	70a2                	ld	ra,40(sp)
    800022d4:	7402                	ld	s0,32(sp)
    800022d6:	64e2                	ld	s1,24(sp)
    800022d8:	6942                	ld	s2,16(sp)
    800022da:	69a2                	ld	s3,8(sp)
    800022dc:	6145                	addi	sp,sp,48
    800022de:	8082                	ret
        p->state = RUNNABLE;
    800022e0:	478d                	li	a5,3
    800022e2:	cc9c                	sw	a5,24(s1)
    800022e4:	b7cd                	j	800022c6 <kill+0x52>

00000000800022e6 <setkilled>:

void
setkilled(struct proc *p)
{
    800022e6:	1101                	addi	sp,sp,-32
    800022e8:	ec06                	sd	ra,24(sp)
    800022ea:	e822                	sd	s0,16(sp)
    800022ec:	e426                	sd	s1,8(sp)
    800022ee:	1000                	addi	s0,sp,32
    800022f0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	8f8080e7          	jalr	-1800(ra) # 80000bea <acquire>
  p->killed = 1;
    800022fa:	4785                	li	a5,1
    800022fc:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022fe:	8526                	mv	a0,s1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	99e080e7          	jalr	-1634(ra) # 80000c9e <release>
}
    80002308:	60e2                	ld	ra,24(sp)
    8000230a:	6442                	ld	s0,16(sp)
    8000230c:	64a2                	ld	s1,8(sp)
    8000230e:	6105                	addi	sp,sp,32
    80002310:	8082                	ret

0000000080002312 <killed>:

int
killed(struct proc *p)
{
    80002312:	1101                	addi	sp,sp,-32
    80002314:	ec06                	sd	ra,24(sp)
    80002316:	e822                	sd	s0,16(sp)
    80002318:	e426                	sd	s1,8(sp)
    8000231a:	e04a                	sd	s2,0(sp)
    8000231c:	1000                	addi	s0,sp,32
    8000231e:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	8ca080e7          	jalr	-1846(ra) # 80000bea <acquire>
  k = p->killed;
    80002328:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	970080e7          	jalr	-1680(ra) # 80000c9e <release>
  return k;
}
    80002336:	854a                	mv	a0,s2
    80002338:	60e2                	ld	ra,24(sp)
    8000233a:	6442                	ld	s0,16(sp)
    8000233c:	64a2                	ld	s1,8(sp)
    8000233e:	6902                	ld	s2,0(sp)
    80002340:	6105                	addi	sp,sp,32
    80002342:	8082                	ret

0000000080002344 <wait>:
{
    80002344:	715d                	addi	sp,sp,-80
    80002346:	e486                	sd	ra,72(sp)
    80002348:	e0a2                	sd	s0,64(sp)
    8000234a:	fc26                	sd	s1,56(sp)
    8000234c:	f84a                	sd	s2,48(sp)
    8000234e:	f44e                	sd	s3,40(sp)
    80002350:	f052                	sd	s4,32(sp)
    80002352:	ec56                	sd	s5,24(sp)
    80002354:	e85a                	sd	s6,16(sp)
    80002356:	e45e                	sd	s7,8(sp)
    80002358:	e062                	sd	s8,0(sp)
    8000235a:	0880                	addi	s0,sp,80
    8000235c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	668080e7          	jalr	1640(ra) # 800019c6 <myproc>
    80002366:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002368:	0000f517          	auipc	a0,0xf
    8000236c:	86050513          	addi	a0,a0,-1952 # 80010bc8 <wait_lock>
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	87a080e7          	jalr	-1926(ra) # 80000bea <acquire>
    havekids = 0;
    80002378:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000237a:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237c:	00014997          	auipc	s3,0x14
    80002380:	66498993          	addi	s3,s3,1636 # 800169e0 <tickslock>
        havekids = 1;
    80002384:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002386:	0000fc17          	auipc	s8,0xf
    8000238a:	842c0c13          	addi	s8,s8,-1982 # 80010bc8 <wait_lock>
    havekids = 0;
    8000238e:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002390:	0000f497          	auipc	s1,0xf
    80002394:	c5048493          	addi	s1,s1,-944 # 80010fe0 <proc>
    80002398:	a0bd                	j	80002406 <wait+0xc2>
          pid = pp->pid;
    8000239a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000239e:	000b0e63          	beqz	s6,800023ba <wait+0x76>
    800023a2:	4691                	li	a3,4
    800023a4:	02c48613          	addi	a2,s1,44
    800023a8:	85da                	mv	a1,s6
    800023aa:	05093503          	ld	a0,80(s2)
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	2d6080e7          	jalr	726(ra) # 80001684 <copyout>
    800023b6:	02054563          	bltz	a0,800023e0 <wait+0x9c>
          freeproc(pp);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	7bc080e7          	jalr	1980(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	8d8080e7          	jalr	-1832(ra) # 80000c9e <release>
          release(&wait_lock);
    800023ce:	0000e517          	auipc	a0,0xe
    800023d2:	7fa50513          	addi	a0,a0,2042 # 80010bc8 <wait_lock>
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	8c8080e7          	jalr	-1848(ra) # 80000c9e <release>
          return pid;
    800023de:	a0b5                	j	8000244a <wait+0x106>
            release(&pp->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8bc080e7          	jalr	-1860(ra) # 80000c9e <release>
            release(&wait_lock);
    800023ea:	0000e517          	auipc	a0,0xe
    800023ee:	7de50513          	addi	a0,a0,2014 # 80010bc8 <wait_lock>
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8ac080e7          	jalr	-1876(ra) # 80000c9e <release>
            return -1;
    800023fa:	59fd                	li	s3,-1
    800023fc:	a0b9                	j	8000244a <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023fe:	16848493          	addi	s1,s1,360
    80002402:	03348463          	beq	s1,s3,8000242a <wait+0xe6>
      if(pp->parent == p){
    80002406:	7c9c                	ld	a5,56(s1)
    80002408:	ff279be3          	bne	a5,s2,800023fe <wait+0xba>
        acquire(&pp->lock);
    8000240c:	8526                	mv	a0,s1
    8000240e:	ffffe097          	auipc	ra,0xffffe
    80002412:	7dc080e7          	jalr	2012(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    80002416:	4c9c                	lw	a5,24(s1)
    80002418:	f94781e3          	beq	a5,s4,8000239a <wait+0x56>
        release(&pp->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	880080e7          	jalr	-1920(ra) # 80000c9e <release>
        havekids = 1;
    80002426:	8756                	mv	a4,s5
    80002428:	bfd9                	j	800023fe <wait+0xba>
    if(!havekids || killed(p)){
    8000242a:	c719                	beqz	a4,80002438 <wait+0xf4>
    8000242c:	854a                	mv	a0,s2
    8000242e:	00000097          	auipc	ra,0x0
    80002432:	ee4080e7          	jalr	-284(ra) # 80002312 <killed>
    80002436:	c51d                	beqz	a0,80002464 <wait+0x120>
      release(&wait_lock);
    80002438:	0000e517          	auipc	a0,0xe
    8000243c:	79050513          	addi	a0,a0,1936 # 80010bc8 <wait_lock>
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	85e080e7          	jalr	-1954(ra) # 80000c9e <release>
      return -1;
    80002448:	59fd                	li	s3,-1
}
    8000244a:	854e                	mv	a0,s3
    8000244c:	60a6                	ld	ra,72(sp)
    8000244e:	6406                	ld	s0,64(sp)
    80002450:	74e2                	ld	s1,56(sp)
    80002452:	7942                	ld	s2,48(sp)
    80002454:	79a2                	ld	s3,40(sp)
    80002456:	7a02                	ld	s4,32(sp)
    80002458:	6ae2                	ld	s5,24(sp)
    8000245a:	6b42                	ld	s6,16(sp)
    8000245c:	6ba2                	ld	s7,8(sp)
    8000245e:	6c02                	ld	s8,0(sp)
    80002460:	6161                	addi	sp,sp,80
    80002462:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002464:	85e2                	mv	a1,s8
    80002466:	854a                	mv	a0,s2
    80002468:	00000097          	auipc	ra,0x0
    8000246c:	c02080e7          	jalr	-1022(ra) # 8000206a <sleep>
    havekids = 0;
    80002470:	bf39                	j	8000238e <wait+0x4a>

0000000080002472 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002472:	7179                	addi	sp,sp,-48
    80002474:	f406                	sd	ra,40(sp)
    80002476:	f022                	sd	s0,32(sp)
    80002478:	ec26                	sd	s1,24(sp)
    8000247a:	e84a                	sd	s2,16(sp)
    8000247c:	e44e                	sd	s3,8(sp)
    8000247e:	e052                	sd	s4,0(sp)
    80002480:	1800                	addi	s0,sp,48
    80002482:	84aa                	mv	s1,a0
    80002484:	892e                	mv	s2,a1
    80002486:	89b2                	mv	s3,a2
    80002488:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	53c080e7          	jalr	1340(ra) # 800019c6 <myproc>
  if(user_dst){
    80002492:	c08d                	beqz	s1,800024b4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002494:	86d2                	mv	a3,s4
    80002496:	864e                	mv	a2,s3
    80002498:	85ca                	mv	a1,s2
    8000249a:	6928                	ld	a0,80(a0)
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	1e8080e7          	jalr	488(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024a4:	70a2                	ld	ra,40(sp)
    800024a6:	7402                	ld	s0,32(sp)
    800024a8:	64e2                	ld	s1,24(sp)
    800024aa:	6942                	ld	s2,16(sp)
    800024ac:	69a2                	ld	s3,8(sp)
    800024ae:	6a02                	ld	s4,0(sp)
    800024b0:	6145                	addi	sp,sp,48
    800024b2:	8082                	ret
    memmove((char *)dst, src, len);
    800024b4:	000a061b          	sext.w	a2,s4
    800024b8:	85ce                	mv	a1,s3
    800024ba:	854a                	mv	a0,s2
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	88a080e7          	jalr	-1910(ra) # 80000d46 <memmove>
    return 0;
    800024c4:	8526                	mv	a0,s1
    800024c6:	bff9                	j	800024a4 <either_copyout+0x32>

00000000800024c8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024c8:	7179                	addi	sp,sp,-48
    800024ca:	f406                	sd	ra,40(sp)
    800024cc:	f022                	sd	s0,32(sp)
    800024ce:	ec26                	sd	s1,24(sp)
    800024d0:	e84a                	sd	s2,16(sp)
    800024d2:	e44e                	sd	s3,8(sp)
    800024d4:	e052                	sd	s4,0(sp)
    800024d6:	1800                	addi	s0,sp,48
    800024d8:	892a                	mv	s2,a0
    800024da:	84ae                	mv	s1,a1
    800024dc:	89b2                	mv	s3,a2
    800024de:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	4e6080e7          	jalr	1254(ra) # 800019c6 <myproc>
  if(user_src){
    800024e8:	c08d                	beqz	s1,8000250a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024ea:	86d2                	mv	a3,s4
    800024ec:	864e                	mv	a2,s3
    800024ee:	85ca                	mv	a1,s2
    800024f0:	6928                	ld	a0,80(a0)
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	21e080e7          	jalr	542(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024fa:	70a2                	ld	ra,40(sp)
    800024fc:	7402                	ld	s0,32(sp)
    800024fe:	64e2                	ld	s1,24(sp)
    80002500:	6942                	ld	s2,16(sp)
    80002502:	69a2                	ld	s3,8(sp)
    80002504:	6a02                	ld	s4,0(sp)
    80002506:	6145                	addi	sp,sp,48
    80002508:	8082                	ret
    memmove(dst, (char*)src, len);
    8000250a:	000a061b          	sext.w	a2,s4
    8000250e:	85ce                	mv	a1,s3
    80002510:	854a                	mv	a0,s2
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	834080e7          	jalr	-1996(ra) # 80000d46 <memmove>
    return 0;
    8000251a:	8526                	mv	a0,s1
    8000251c:	bff9                	j	800024fa <either_copyin+0x32>

000000008000251e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000251e:	715d                	addi	sp,sp,-80
    80002520:	e486                	sd	ra,72(sp)
    80002522:	e0a2                	sd	s0,64(sp)
    80002524:	fc26                	sd	s1,56(sp)
    80002526:	f84a                	sd	s2,48(sp)
    80002528:	f44e                	sd	s3,40(sp)
    8000252a:	f052                	sd	s4,32(sp)
    8000252c:	ec56                	sd	s5,24(sp)
    8000252e:	e85a                	sd	s6,16(sp)
    80002530:	e45e                	sd	s7,8(sp)
    80002532:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002534:	00006517          	auipc	a0,0x6
    80002538:	b9450513          	addi	a0,a0,-1132 # 800080c8 <digits+0x88>
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	052080e7          	jalr	82(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002544:	0000f497          	auipc	s1,0xf
    80002548:	bf448493          	addi	s1,s1,-1036 # 80011138 <proc+0x158>
    8000254c:	00014917          	auipc	s2,0x14
    80002550:	5ec90913          	addi	s2,s2,1516 # 80016b38 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002554:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002556:	00006997          	auipc	s3,0x6
    8000255a:	d2a98993          	addi	s3,s3,-726 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000255e:	00006a97          	auipc	s5,0x6
    80002562:	d2aa8a93          	addi	s5,s5,-726 # 80008288 <digits+0x248>
    printf("\n");
    80002566:	00006a17          	auipc	s4,0x6
    8000256a:	b62a0a13          	addi	s4,s4,-1182 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000256e:	00006b97          	auipc	s7,0x6
    80002572:	d6ab8b93          	addi	s7,s7,-662 # 800082d8 <states.1724>
    80002576:	a00d                	j	80002598 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002578:	ed86a583          	lw	a1,-296(a3)
    8000257c:	8556                	mv	a0,s5
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	010080e7          	jalr	16(ra) # 8000058e <printf>
    printf("\n");
    80002586:	8552                	mv	a0,s4
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	006080e7          	jalr	6(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002590:	16848493          	addi	s1,s1,360
    80002594:	03248163          	beq	s1,s2,800025b6 <procdump+0x98>
    if(p->state == UNUSED)
    80002598:	86a6                	mv	a3,s1
    8000259a:	ec04a783          	lw	a5,-320(s1)
    8000259e:	dbed                	beqz	a5,80002590 <procdump+0x72>
      state = "???";
    800025a0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a2:	fcfb6be3          	bltu	s6,a5,80002578 <procdump+0x5a>
    800025a6:	1782                	slli	a5,a5,0x20
    800025a8:	9381                	srli	a5,a5,0x20
    800025aa:	078e                	slli	a5,a5,0x3
    800025ac:	97de                	add	a5,a5,s7
    800025ae:	6390                	ld	a2,0(a5)
    800025b0:	f661                	bnez	a2,80002578 <procdump+0x5a>
      state = "???";
    800025b2:	864e                	mv	a2,s3
    800025b4:	b7d1                	j	80002578 <procdump+0x5a>
  }
}
    800025b6:	60a6                	ld	ra,72(sp)
    800025b8:	6406                	ld	s0,64(sp)
    800025ba:	74e2                	ld	s1,56(sp)
    800025bc:	7942                	ld	s2,48(sp)
    800025be:	79a2                	ld	s3,40(sp)
    800025c0:	7a02                	ld	s4,32(sp)
    800025c2:	6ae2                	ld	s5,24(sp)
    800025c4:	6b42                	ld	s6,16(sp)
    800025c6:	6ba2                	ld	s7,8(sp)
    800025c8:	6161                	addi	sp,sp,80
    800025ca:	8082                	ret

00000000800025cc <scps>:

void
scps(void)
{
    800025cc:	711d                	addi	sp,sp,-96
    800025ce:	ec86                	sd	ra,88(sp)
    800025d0:	e8a2                	sd	s0,80(sp)
    800025d2:	e4a6                	sd	s1,72(sp)
    800025d4:	e0ca                	sd	s2,64(sp)
    800025d6:	fc4e                	sd	s3,56(sp)
    800025d8:	f852                	sd	s4,48(sp)
    800025da:	f456                	sd	s5,40(sp)
    800025dc:	f05a                	sd	s6,32(sp)
    800025de:	ec5e                	sd	s7,24(sp)
    800025e0:	e862                	sd	s8,16(sp)
    800025e2:	e466                	sd	s9,8(sp)
    800025e4:	1080                	addi	s0,sp,96
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  int state;

  printf("\n");
    800025e6:	00006517          	auipc	a0,0x6
    800025ea:	ae250513          	addi	a0,a0,-1310 # 800080c8 <digits+0x88>
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	fa0080e7          	jalr	-96(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f6:	0000f497          	auipc	s1,0xf
    800025fa:	9ea48493          	addi	s1,s1,-1558 # 80010fe0 <proc>
    if(p->state == UNUSED)
    {
      release(&p->lock);
      continue;
    }
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025fe:	4b95                	li	s7,5
      state = p->state;
    else
      state = -1;
    80002600:	59fd                	li	s3,-1
    release(&p->lock);
    printf("%s (%d): %d", p->name, p->pid, state);
    80002602:	00006b17          	auipc	s6,0x6
    80002606:	c96b0b13          	addi	s6,s6,-874 # 80008298 <digits+0x258>
    printf("\n");
    8000260a:	00006a97          	auipc	s5,0x6
    8000260e:	abea8a93          	addi	s5,s5,-1346 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002612:	00006c17          	auipc	s8,0x6
    80002616:	cc6c0c13          	addi	s8,s8,-826 # 800082d8 <states.1724>
  for(p = proc; p < &proc[NPROC]; p++){
    8000261a:	00014a17          	auipc	s4,0x14
    8000261e:	3c6a0a13          	addi	s4,s4,966 # 800169e0 <tickslock>
    80002622:	a835                	j	8000265e <scps+0x92>
      release(&p->lock);
    80002624:	8526                	mv	a0,s1
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	678080e7          	jalr	1656(ra) # 80000c9e <release>
      continue;
    8000262e:	a025                	j	80002656 <scps+0x8a>
    release(&p->lock);
    80002630:	8526                	mv	a0,s1
    80002632:	ffffe097          	auipc	ra,0xffffe
    80002636:	66c080e7          	jalr	1644(ra) # 80000c9e <release>
    printf("%s (%d): %d", p->name, p->pid, state);
    8000263a:	86e6                	mv	a3,s9
    8000263c:	5890                	lw	a2,48(s1)
    8000263e:	15890593          	addi	a1,s2,344
    80002642:	855a                	mv	a0,s6
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	f4a080e7          	jalr	-182(ra) # 8000058e <printf>
    printf("\n");
    8000264c:	8556                	mv	a0,s5
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	f40080e7          	jalr	-192(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002656:	16848493          	addi	s1,s1,360
    8000265a:	03448763          	beq	s1,s4,80002688 <scps+0xbc>
    acquire(&p->lock);
    8000265e:	8926                	mv	s2,s1
    80002660:	8526                	mv	a0,s1
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	588080e7          	jalr	1416(ra) # 80000bea <acquire>
    if(p->state == UNUSED)
    8000266a:	4c9c                	lw	a5,24(s1)
    8000266c:	dfc5                	beqz	a5,80002624 <scps+0x58>
      state = -1;
    8000266e:	8cce                	mv	s9,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002670:	fcfbe0e3          	bltu	s7,a5,80002630 <scps+0x64>
    80002674:	02079713          	slli	a4,a5,0x20
    80002678:	9301                	srli	a4,a4,0x20
    8000267a:	070e                	slli	a4,a4,0x3
    8000267c:	9762                	add	a4,a4,s8
    8000267e:	7b18                	ld	a4,48(a4)
    80002680:	db45                	beqz	a4,80002630 <scps+0x64>
      state = p->state;
    80002682:	00078c9b          	sext.w	s9,a5
    80002686:	b76d                	j	80002630 <scps+0x64>
  }
    80002688:	60e6                	ld	ra,88(sp)
    8000268a:	6446                	ld	s0,80(sp)
    8000268c:	64a6                	ld	s1,72(sp)
    8000268e:	6906                	ld	s2,64(sp)
    80002690:	79e2                	ld	s3,56(sp)
    80002692:	7a42                	ld	s4,48(sp)
    80002694:	7aa2                	ld	s5,40(sp)
    80002696:	7b02                	ld	s6,32(sp)
    80002698:	6be2                	ld	s7,24(sp)
    8000269a:	6c42                	ld	s8,16(sp)
    8000269c:	6ca2                	ld	s9,8(sp)
    8000269e:	6125                	addi	sp,sp,96
    800026a0:	8082                	ret

00000000800026a2 <swtch>:
    800026a2:	00153023          	sd	ra,0(a0)
    800026a6:	00253423          	sd	sp,8(a0)
    800026aa:	e900                	sd	s0,16(a0)
    800026ac:	ed04                	sd	s1,24(a0)
    800026ae:	03253023          	sd	s2,32(a0)
    800026b2:	03353423          	sd	s3,40(a0)
    800026b6:	03453823          	sd	s4,48(a0)
    800026ba:	03553c23          	sd	s5,56(a0)
    800026be:	05653023          	sd	s6,64(a0)
    800026c2:	05753423          	sd	s7,72(a0)
    800026c6:	05853823          	sd	s8,80(a0)
    800026ca:	05953c23          	sd	s9,88(a0)
    800026ce:	07a53023          	sd	s10,96(a0)
    800026d2:	07b53423          	sd	s11,104(a0)
    800026d6:	0005b083          	ld	ra,0(a1)
    800026da:	0085b103          	ld	sp,8(a1)
    800026de:	6980                	ld	s0,16(a1)
    800026e0:	6d84                	ld	s1,24(a1)
    800026e2:	0205b903          	ld	s2,32(a1)
    800026e6:	0285b983          	ld	s3,40(a1)
    800026ea:	0305ba03          	ld	s4,48(a1)
    800026ee:	0385ba83          	ld	s5,56(a1)
    800026f2:	0405bb03          	ld	s6,64(a1)
    800026f6:	0485bb83          	ld	s7,72(a1)
    800026fa:	0505bc03          	ld	s8,80(a1)
    800026fe:	0585bc83          	ld	s9,88(a1)
    80002702:	0605bd03          	ld	s10,96(a1)
    80002706:	0685bd83          	ld	s11,104(a1)
    8000270a:	8082                	ret

000000008000270c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000270c:	1141                	addi	sp,sp,-16
    8000270e:	e406                	sd	ra,8(sp)
    80002710:	e022                	sd	s0,0(sp)
    80002712:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002714:	00006597          	auipc	a1,0x6
    80002718:	c2458593          	addi	a1,a1,-988 # 80008338 <states.1734+0x30>
    8000271c:	00014517          	auipc	a0,0x14
    80002720:	2c450513          	addi	a0,a0,708 # 800169e0 <tickslock>
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	436080e7          	jalr	1078(ra) # 80000b5a <initlock>
}
    8000272c:	60a2                	ld	ra,8(sp)
    8000272e:	6402                	ld	s0,0(sp)
    80002730:	0141                	addi	sp,sp,16
    80002732:	8082                	ret

0000000080002734 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002734:	1141                	addi	sp,sp,-16
    80002736:	e422                	sd	s0,8(sp)
    80002738:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000273a:	00003797          	auipc	a5,0x3
    8000273e:	4d678793          	addi	a5,a5,1238 # 80005c10 <kernelvec>
    80002742:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002746:	6422                	ld	s0,8(sp)
    80002748:	0141                	addi	sp,sp,16
    8000274a:	8082                	ret

000000008000274c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000274c:	1141                	addi	sp,sp,-16
    8000274e:	e406                	sd	ra,8(sp)
    80002750:	e022                	sd	s0,0(sp)
    80002752:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002754:	fffff097          	auipc	ra,0xfffff
    80002758:	272080e7          	jalr	626(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000275c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002760:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002762:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002766:	00005617          	auipc	a2,0x5
    8000276a:	89a60613          	addi	a2,a2,-1894 # 80007000 <_trampoline>
    8000276e:	00005697          	auipc	a3,0x5
    80002772:	89268693          	addi	a3,a3,-1902 # 80007000 <_trampoline>
    80002776:	8e91                	sub	a3,a3,a2
    80002778:	040007b7          	lui	a5,0x4000
    8000277c:	17fd                	addi	a5,a5,-1
    8000277e:	07b2                	slli	a5,a5,0xc
    80002780:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002782:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002786:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002788:	180026f3          	csrr	a3,satp
    8000278c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000278e:	6d38                	ld	a4,88(a0)
    80002790:	6134                	ld	a3,64(a0)
    80002792:	6585                	lui	a1,0x1
    80002794:	96ae                	add	a3,a3,a1
    80002796:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002798:	6d38                	ld	a4,88(a0)
    8000279a:	00000697          	auipc	a3,0x0
    8000279e:	13068693          	addi	a3,a3,304 # 800028ca <usertrap>
    800027a2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027a4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027a6:	8692                	mv	a3,tp
    800027a8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027aa:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027ae:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027b2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027b6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027ba:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027bc:	6f18                	ld	a4,24(a4)
    800027be:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027c2:	6928                	ld	a0,80(a0)
    800027c4:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800027c6:	00005717          	auipc	a4,0x5
    800027ca:	8d670713          	addi	a4,a4,-1834 # 8000709c <userret>
    800027ce:	8f11                	sub	a4,a4,a2
    800027d0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800027d2:	577d                	li	a4,-1
    800027d4:	177e                	slli	a4,a4,0x3f
    800027d6:	8d59                	or	a0,a0,a4
    800027d8:	9782                	jalr	a5
}
    800027da:	60a2                	ld	ra,8(sp)
    800027dc:	6402                	ld	s0,0(sp)
    800027de:	0141                	addi	sp,sp,16
    800027e0:	8082                	ret

00000000800027e2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027e2:	1101                	addi	sp,sp,-32
    800027e4:	ec06                	sd	ra,24(sp)
    800027e6:	e822                	sd	s0,16(sp)
    800027e8:	e426                	sd	s1,8(sp)
    800027ea:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027ec:	00014497          	auipc	s1,0x14
    800027f0:	1f448493          	addi	s1,s1,500 # 800169e0 <tickslock>
    800027f4:	8526                	mv	a0,s1
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	3f4080e7          	jalr	1012(ra) # 80000bea <acquire>
  ticks++;
    800027fe:	00006517          	auipc	a0,0x6
    80002802:	14250513          	addi	a0,a0,322 # 80008940 <ticks>
    80002806:	411c                	lw	a5,0(a0)
    80002808:	2785                	addiw	a5,a5,1
    8000280a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000280c:	00000097          	auipc	ra,0x0
    80002810:	8c2080e7          	jalr	-1854(ra) # 800020ce <wakeup>
  release(&tickslock);
    80002814:	8526                	mv	a0,s1
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	488080e7          	jalr	1160(ra) # 80000c9e <release>
}
    8000281e:	60e2                	ld	ra,24(sp)
    80002820:	6442                	ld	s0,16(sp)
    80002822:	64a2                	ld	s1,8(sp)
    80002824:	6105                	addi	sp,sp,32
    80002826:	8082                	ret

0000000080002828 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002828:	1101                	addi	sp,sp,-32
    8000282a:	ec06                	sd	ra,24(sp)
    8000282c:	e822                	sd	s0,16(sp)
    8000282e:	e426                	sd	s1,8(sp)
    80002830:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002832:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002836:	00074d63          	bltz	a4,80002850 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000283a:	57fd                	li	a5,-1
    8000283c:	17fe                	slli	a5,a5,0x3f
    8000283e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002840:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002842:	06f70363          	beq	a4,a5,800028a8 <devintr+0x80>
  }
}
    80002846:	60e2                	ld	ra,24(sp)
    80002848:	6442                	ld	s0,16(sp)
    8000284a:	64a2                	ld	s1,8(sp)
    8000284c:	6105                	addi	sp,sp,32
    8000284e:	8082                	ret
     (scause & 0xff) == 9){
    80002850:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002854:	46a5                	li	a3,9
    80002856:	fed792e3          	bne	a5,a3,8000283a <devintr+0x12>
    int irq = plic_claim();
    8000285a:	00003097          	auipc	ra,0x3
    8000285e:	4be080e7          	jalr	1214(ra) # 80005d18 <plic_claim>
    80002862:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002864:	47a9                	li	a5,10
    80002866:	02f50763          	beq	a0,a5,80002894 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000286a:	4785                	li	a5,1
    8000286c:	02f50963          	beq	a0,a5,8000289e <devintr+0x76>
    return 1;
    80002870:	4505                	li	a0,1
    } else if(irq){
    80002872:	d8f1                	beqz	s1,80002846 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002874:	85a6                	mv	a1,s1
    80002876:	00006517          	auipc	a0,0x6
    8000287a:	aca50513          	addi	a0,a0,-1334 # 80008340 <states.1734+0x38>
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	d10080e7          	jalr	-752(ra) # 8000058e <printf>
      plic_complete(irq);
    80002886:	8526                	mv	a0,s1
    80002888:	00003097          	auipc	ra,0x3
    8000288c:	4b4080e7          	jalr	1204(ra) # 80005d3c <plic_complete>
    return 1;
    80002890:	4505                	li	a0,1
    80002892:	bf55                	j	80002846 <devintr+0x1e>
      uartintr();
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	11a080e7          	jalr	282(ra) # 800009ae <uartintr>
    8000289c:	b7ed                	j	80002886 <devintr+0x5e>
      virtio_disk_intr();
    8000289e:	00004097          	auipc	ra,0x4
    800028a2:	9c8080e7          	jalr	-1592(ra) # 80006266 <virtio_disk_intr>
    800028a6:	b7c5                	j	80002886 <devintr+0x5e>
    if(cpuid() == 0){
    800028a8:	fffff097          	auipc	ra,0xfffff
    800028ac:	0f2080e7          	jalr	242(ra) # 8000199a <cpuid>
    800028b0:	c901                	beqz	a0,800028c0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028b2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028b6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028b8:	14479073          	csrw	sip,a5
    return 2;
    800028bc:	4509                	li	a0,2
    800028be:	b761                	j	80002846 <devintr+0x1e>
      clockintr();
    800028c0:	00000097          	auipc	ra,0x0
    800028c4:	f22080e7          	jalr	-222(ra) # 800027e2 <clockintr>
    800028c8:	b7ed                	j	800028b2 <devintr+0x8a>

00000000800028ca <usertrap>:
{
    800028ca:	1101                	addi	sp,sp,-32
    800028cc:	ec06                	sd	ra,24(sp)
    800028ce:	e822                	sd	s0,16(sp)
    800028d0:	e426                	sd	s1,8(sp)
    800028d2:	e04a                	sd	s2,0(sp)
    800028d4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028da:	1007f793          	andi	a5,a5,256
    800028de:	e3b1                	bnez	a5,80002922 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028e0:	00003797          	auipc	a5,0x3
    800028e4:	33078793          	addi	a5,a5,816 # 80005c10 <kernelvec>
    800028e8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028ec:	fffff097          	auipc	ra,0xfffff
    800028f0:	0da080e7          	jalr	218(ra) # 800019c6 <myproc>
    800028f4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028f6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028f8:	14102773          	csrr	a4,sepc
    800028fc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028fe:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002902:	47a1                	li	a5,8
    80002904:	02f70763          	beq	a4,a5,80002932 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002908:	00000097          	auipc	ra,0x0
    8000290c:	f20080e7          	jalr	-224(ra) # 80002828 <devintr>
    80002910:	892a                	mv	s2,a0
    80002912:	c151                	beqz	a0,80002996 <usertrap+0xcc>
  if(killed(p))
    80002914:	8526                	mv	a0,s1
    80002916:	00000097          	auipc	ra,0x0
    8000291a:	9fc080e7          	jalr	-1540(ra) # 80002312 <killed>
    8000291e:	c929                	beqz	a0,80002970 <usertrap+0xa6>
    80002920:	a099                	j	80002966 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002922:	00006517          	auipc	a0,0x6
    80002926:	a3e50513          	addi	a0,a0,-1474 # 80008360 <states.1734+0x58>
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	c1a080e7          	jalr	-998(ra) # 80000544 <panic>
    if(killed(p))
    80002932:	00000097          	auipc	ra,0x0
    80002936:	9e0080e7          	jalr	-1568(ra) # 80002312 <killed>
    8000293a:	e921                	bnez	a0,8000298a <usertrap+0xc0>
    p->trapframe->epc += 4;
    8000293c:	6cb8                	ld	a4,88(s1)
    8000293e:	6f1c                	ld	a5,24(a4)
    80002940:	0791                	addi	a5,a5,4
    80002942:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002944:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002948:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000294c:	10079073          	csrw	sstatus,a5
    syscall();
    80002950:	00000097          	auipc	ra,0x0
    80002954:	2ec080e7          	jalr	748(ra) # 80002c3c <syscall>
  if(killed(p))
    80002958:	8526                	mv	a0,s1
    8000295a:	00000097          	auipc	ra,0x0
    8000295e:	9b8080e7          	jalr	-1608(ra) # 80002312 <killed>
    80002962:	c911                	beqz	a0,80002976 <usertrap+0xac>
    80002964:	4901                	li	s2,0
    exit(-1);
    80002966:	557d                	li	a0,-1
    80002968:	00000097          	auipc	ra,0x0
    8000296c:	836080e7          	jalr	-1994(ra) # 8000219e <exit>
  if(which_dev == 2){
    80002970:	4789                	li	a5,2
    80002972:	04f90f63          	beq	s2,a5,800029d0 <usertrap+0x106>
  usertrapret();
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	dd6080e7          	jalr	-554(ra) # 8000274c <usertrapret>
}
    8000297e:	60e2                	ld	ra,24(sp)
    80002980:	6442                	ld	s0,16(sp)
    80002982:	64a2                	ld	s1,8(sp)
    80002984:	6902                	ld	s2,0(sp)
    80002986:	6105                	addi	sp,sp,32
    80002988:	8082                	ret
      exit(-1);
    8000298a:	557d                	li	a0,-1
    8000298c:	00000097          	auipc	ra,0x0
    80002990:	812080e7          	jalr	-2030(ra) # 8000219e <exit>
    80002994:	b765                	j	8000293c <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002996:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000299a:	5890                	lw	a2,48(s1)
    8000299c:	00006517          	auipc	a0,0x6
    800029a0:	9e450513          	addi	a0,a0,-1564 # 80008380 <states.1734+0x78>
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	bea080e7          	jalr	-1046(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ac:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029b0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029b4:	00006517          	auipc	a0,0x6
    800029b8:	9fc50513          	addi	a0,a0,-1540 # 800083b0 <states.1734+0xa8>
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	bd2080e7          	jalr	-1070(ra) # 8000058e <printf>
    setkilled(p);
    800029c4:	8526                	mv	a0,s1
    800029c6:	00000097          	auipc	ra,0x0
    800029ca:	920080e7          	jalr	-1760(ra) # 800022e6 <setkilled>
    800029ce:	b769                	j	80002958 <usertrap+0x8e>
    printf("timer interrupt %d",ticks);
    800029d0:	00006597          	auipc	a1,0x6
    800029d4:	f705a583          	lw	a1,-144(a1) # 80008940 <ticks>
    800029d8:	00006517          	auipc	a0,0x6
    800029dc:	9f850513          	addi	a0,a0,-1544 # 800083d0 <states.1734+0xc8>
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	bae080e7          	jalr	-1106(ra) # 8000058e <printf>
    yield();}
    800029e8:	fffff097          	auipc	ra,0xfffff
    800029ec:	646080e7          	jalr	1606(ra) # 8000202e <yield>
    800029f0:	b759                	j	80002976 <usertrap+0xac>

00000000800029f2 <kerneltrap>:
{
    800029f2:	7179                	addi	sp,sp,-48
    800029f4:	f406                	sd	ra,40(sp)
    800029f6:	f022                	sd	s0,32(sp)
    800029f8:	ec26                	sd	s1,24(sp)
    800029fa:	e84a                	sd	s2,16(sp)
    800029fc:	e44e                	sd	s3,8(sp)
    800029fe:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a00:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a04:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a08:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a0c:	1004f793          	andi	a5,s1,256
    80002a10:	cb85                	beqz	a5,80002a40 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a12:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a16:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a18:	ef85                	bnez	a5,80002a50 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a1a:	00000097          	auipc	ra,0x0
    80002a1e:	e0e080e7          	jalr	-498(ra) # 80002828 <devintr>
    80002a22:	cd1d                	beqz	a0,80002a60 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a24:	4789                	li	a5,2
    80002a26:	06f50a63          	beq	a0,a5,80002a9a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a2a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a2e:	10049073          	csrw	sstatus,s1
}
    80002a32:	70a2                	ld	ra,40(sp)
    80002a34:	7402                	ld	s0,32(sp)
    80002a36:	64e2                	ld	s1,24(sp)
    80002a38:	6942                	ld	s2,16(sp)
    80002a3a:	69a2                	ld	s3,8(sp)
    80002a3c:	6145                	addi	sp,sp,48
    80002a3e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	9a850513          	addi	a0,a0,-1624 # 800083e8 <states.1734+0xe0>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	afc080e7          	jalr	-1284(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a50:	00006517          	auipc	a0,0x6
    80002a54:	9c050513          	addi	a0,a0,-1600 # 80008410 <states.1734+0x108>
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	aec080e7          	jalr	-1300(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002a60:	85ce                	mv	a1,s3
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	9ce50513          	addi	a0,a0,-1586 # 80008430 <states.1734+0x128>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	b24080e7          	jalr	-1244(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a72:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a76:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	9c650513          	addi	a0,a0,-1594 # 80008440 <states.1734+0x138>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	b0c080e7          	jalr	-1268(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002a8a:	00006517          	auipc	a0,0x6
    80002a8e:	9ce50513          	addi	a0,a0,-1586 # 80008458 <states.1734+0x150>
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	ab2080e7          	jalr	-1358(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a9a:	fffff097          	auipc	ra,0xfffff
    80002a9e:	f2c080e7          	jalr	-212(ra) # 800019c6 <myproc>
    80002aa2:	d541                	beqz	a0,80002a2a <kerneltrap+0x38>
    80002aa4:	fffff097          	auipc	ra,0xfffff
    80002aa8:	f22080e7          	jalr	-222(ra) # 800019c6 <myproc>
    80002aac:	4d18                	lw	a4,24(a0)
    80002aae:	4791                	li	a5,4
    80002ab0:	f6f71de3          	bne	a4,a5,80002a2a <kerneltrap+0x38>
    yield();
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	57a080e7          	jalr	1402(ra) # 8000202e <yield>
    80002abc:	b7bd                	j	80002a2a <kerneltrap+0x38>

0000000080002abe <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002abe:	1101                	addi	sp,sp,-32
    80002ac0:	ec06                	sd	ra,24(sp)
    80002ac2:	e822                	sd	s0,16(sp)
    80002ac4:	e426                	sd	s1,8(sp)
    80002ac6:	1000                	addi	s0,sp,32
    80002ac8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	efc080e7          	jalr	-260(ra) # 800019c6 <myproc>
  switch (n) {
    80002ad2:	4795                	li	a5,5
    80002ad4:	0497e163          	bltu	a5,s1,80002b16 <argraw+0x58>
    80002ad8:	048a                	slli	s1,s1,0x2
    80002ada:	00006717          	auipc	a4,0x6
    80002ade:	9b670713          	addi	a4,a4,-1610 # 80008490 <states.1734+0x188>
    80002ae2:	94ba                	add	s1,s1,a4
    80002ae4:	409c                	lw	a5,0(s1)
    80002ae6:	97ba                	add	a5,a5,a4
    80002ae8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002aea:	6d3c                	ld	a5,88(a0)
    80002aec:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aee:	60e2                	ld	ra,24(sp)
    80002af0:	6442                	ld	s0,16(sp)
    80002af2:	64a2                	ld	s1,8(sp)
    80002af4:	6105                	addi	sp,sp,32
    80002af6:	8082                	ret
    return p->trapframe->a1;
    80002af8:	6d3c                	ld	a5,88(a0)
    80002afa:	7fa8                	ld	a0,120(a5)
    80002afc:	bfcd                	j	80002aee <argraw+0x30>
    return p->trapframe->a2;
    80002afe:	6d3c                	ld	a5,88(a0)
    80002b00:	63c8                	ld	a0,128(a5)
    80002b02:	b7f5                	j	80002aee <argraw+0x30>
    return p->trapframe->a3;
    80002b04:	6d3c                	ld	a5,88(a0)
    80002b06:	67c8                	ld	a0,136(a5)
    80002b08:	b7dd                	j	80002aee <argraw+0x30>
    return p->trapframe->a4;
    80002b0a:	6d3c                	ld	a5,88(a0)
    80002b0c:	6bc8                	ld	a0,144(a5)
    80002b0e:	b7c5                	j	80002aee <argraw+0x30>
    return p->trapframe->a5;
    80002b10:	6d3c                	ld	a5,88(a0)
    80002b12:	6fc8                	ld	a0,152(a5)
    80002b14:	bfe9                	j	80002aee <argraw+0x30>
  panic("argraw");
    80002b16:	00006517          	auipc	a0,0x6
    80002b1a:	95250513          	addi	a0,a0,-1710 # 80008468 <states.1734+0x160>
    80002b1e:	ffffe097          	auipc	ra,0xffffe
    80002b22:	a26080e7          	jalr	-1498(ra) # 80000544 <panic>

0000000080002b26 <fetchaddr>:
{
    80002b26:	1101                	addi	sp,sp,-32
    80002b28:	ec06                	sd	ra,24(sp)
    80002b2a:	e822                	sd	s0,16(sp)
    80002b2c:	e426                	sd	s1,8(sp)
    80002b2e:	e04a                	sd	s2,0(sp)
    80002b30:	1000                	addi	s0,sp,32
    80002b32:	84aa                	mv	s1,a0
    80002b34:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	e90080e7          	jalr	-368(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b3e:	653c                	ld	a5,72(a0)
    80002b40:	02f4f863          	bgeu	s1,a5,80002b70 <fetchaddr+0x4a>
    80002b44:	00848713          	addi	a4,s1,8
    80002b48:	02e7e663          	bltu	a5,a4,80002b74 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b4c:	46a1                	li	a3,8
    80002b4e:	8626                	mv	a2,s1
    80002b50:	85ca                	mv	a1,s2
    80002b52:	6928                	ld	a0,80(a0)
    80002b54:	fffff097          	auipc	ra,0xfffff
    80002b58:	bbc080e7          	jalr	-1092(ra) # 80001710 <copyin>
    80002b5c:	00a03533          	snez	a0,a0
    80002b60:	40a00533          	neg	a0,a0
}
    80002b64:	60e2                	ld	ra,24(sp)
    80002b66:	6442                	ld	s0,16(sp)
    80002b68:	64a2                	ld	s1,8(sp)
    80002b6a:	6902                	ld	s2,0(sp)
    80002b6c:	6105                	addi	sp,sp,32
    80002b6e:	8082                	ret
    return -1;
    80002b70:	557d                	li	a0,-1
    80002b72:	bfcd                	j	80002b64 <fetchaddr+0x3e>
    80002b74:	557d                	li	a0,-1
    80002b76:	b7fd                	j	80002b64 <fetchaddr+0x3e>

0000000080002b78 <fetchstr>:
{
    80002b78:	7179                	addi	sp,sp,-48
    80002b7a:	f406                	sd	ra,40(sp)
    80002b7c:	f022                	sd	s0,32(sp)
    80002b7e:	ec26                	sd	s1,24(sp)
    80002b80:	e84a                	sd	s2,16(sp)
    80002b82:	e44e                	sd	s3,8(sp)
    80002b84:	1800                	addi	s0,sp,48
    80002b86:	892a                	mv	s2,a0
    80002b88:	84ae                	mv	s1,a1
    80002b8a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	e3a080e7          	jalr	-454(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b94:	86ce                	mv	a3,s3
    80002b96:	864a                	mv	a2,s2
    80002b98:	85a6                	mv	a1,s1
    80002b9a:	6928                	ld	a0,80(a0)
    80002b9c:	fffff097          	auipc	ra,0xfffff
    80002ba0:	c00080e7          	jalr	-1024(ra) # 8000179c <copyinstr>
    80002ba4:	00054e63          	bltz	a0,80002bc0 <fetchstr+0x48>
  return strlen(buf);
    80002ba8:	8526                	mv	a0,s1
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	2c0080e7          	jalr	704(ra) # 80000e6a <strlen>
}
    80002bb2:	70a2                	ld	ra,40(sp)
    80002bb4:	7402                	ld	s0,32(sp)
    80002bb6:	64e2                	ld	s1,24(sp)
    80002bb8:	6942                	ld	s2,16(sp)
    80002bba:	69a2                	ld	s3,8(sp)
    80002bbc:	6145                	addi	sp,sp,48
    80002bbe:	8082                	ret
    return -1;
    80002bc0:	557d                	li	a0,-1
    80002bc2:	bfc5                	j	80002bb2 <fetchstr+0x3a>

0000000080002bc4 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002bc4:	1101                	addi	sp,sp,-32
    80002bc6:	ec06                	sd	ra,24(sp)
    80002bc8:	e822                	sd	s0,16(sp)
    80002bca:	e426                	sd	s1,8(sp)
    80002bcc:	1000                	addi	s0,sp,32
    80002bce:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bd0:	00000097          	auipc	ra,0x0
    80002bd4:	eee080e7          	jalr	-274(ra) # 80002abe <argraw>
    80002bd8:	c088                	sw	a0,0(s1)
}
    80002bda:	60e2                	ld	ra,24(sp)
    80002bdc:	6442                	ld	s0,16(sp)
    80002bde:	64a2                	ld	s1,8(sp)
    80002be0:	6105                	addi	sp,sp,32
    80002be2:	8082                	ret

0000000080002be4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002be4:	1101                	addi	sp,sp,-32
    80002be6:	ec06                	sd	ra,24(sp)
    80002be8:	e822                	sd	s0,16(sp)
    80002bea:	e426                	sd	s1,8(sp)
    80002bec:	1000                	addi	s0,sp,32
    80002bee:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bf0:	00000097          	auipc	ra,0x0
    80002bf4:	ece080e7          	jalr	-306(ra) # 80002abe <argraw>
    80002bf8:	e088                	sd	a0,0(s1)
}
    80002bfa:	60e2                	ld	ra,24(sp)
    80002bfc:	6442                	ld	s0,16(sp)
    80002bfe:	64a2                	ld	s1,8(sp)
    80002c00:	6105                	addi	sp,sp,32
    80002c02:	8082                	ret

0000000080002c04 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c04:	7179                	addi	sp,sp,-48
    80002c06:	f406                	sd	ra,40(sp)
    80002c08:	f022                	sd	s0,32(sp)
    80002c0a:	ec26                	sd	s1,24(sp)
    80002c0c:	e84a                	sd	s2,16(sp)
    80002c0e:	1800                	addi	s0,sp,48
    80002c10:	84ae                	mv	s1,a1
    80002c12:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c14:	fd840593          	addi	a1,s0,-40
    80002c18:	00000097          	auipc	ra,0x0
    80002c1c:	fcc080e7          	jalr	-52(ra) # 80002be4 <argaddr>
  return fetchstr(addr, buf, max);
    80002c20:	864a                	mv	a2,s2
    80002c22:	85a6                	mv	a1,s1
    80002c24:	fd843503          	ld	a0,-40(s0)
    80002c28:	00000097          	auipc	ra,0x0
    80002c2c:	f50080e7          	jalr	-176(ra) # 80002b78 <fetchstr>
}
    80002c30:	70a2                	ld	ra,40(sp)
    80002c32:	7402                	ld	s0,32(sp)
    80002c34:	64e2                	ld	s1,24(sp)
    80002c36:	6942                	ld	s2,16(sp)
    80002c38:	6145                	addi	sp,sp,48
    80002c3a:	8082                	ret

0000000080002c3c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c3c:	1101                	addi	sp,sp,-32
    80002c3e:	ec06                	sd	ra,24(sp)
    80002c40:	e822                	sd	s0,16(sp)
    80002c42:	e426                	sd	s1,8(sp)
    80002c44:	e04a                	sd	s2,0(sp)
    80002c46:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c48:	fffff097          	auipc	ra,0xfffff
    80002c4c:	d7e080e7          	jalr	-642(ra) # 800019c6 <myproc>
    80002c50:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c52:	05853903          	ld	s2,88(a0)
    80002c56:	0a893783          	ld	a5,168(s2)
    80002c5a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c5e:	37fd                	addiw	a5,a5,-1
    80002c60:	4755                	li	a4,21
    80002c62:	00f76f63          	bltu	a4,a5,80002c80 <syscall+0x44>
    80002c66:	00369713          	slli	a4,a3,0x3
    80002c6a:	00006797          	auipc	a5,0x6
    80002c6e:	83e78793          	addi	a5,a5,-1986 # 800084a8 <syscalls>
    80002c72:	97ba                	add	a5,a5,a4
    80002c74:	639c                	ld	a5,0(a5)
    80002c76:	c789                	beqz	a5,80002c80 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c78:	9782                	jalr	a5
    80002c7a:	06a93823          	sd	a0,112(s2)
    80002c7e:	a839                	j	80002c9c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c80:	15848613          	addi	a2,s1,344
    80002c84:	588c                	lw	a1,48(s1)
    80002c86:	00005517          	auipc	a0,0x5
    80002c8a:	7ea50513          	addi	a0,a0,2026 # 80008470 <states.1734+0x168>
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	900080e7          	jalr	-1792(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c96:	6cbc                	ld	a5,88(s1)
    80002c98:	577d                	li	a4,-1
    80002c9a:	fbb8                	sd	a4,112(a5)
  }
}
    80002c9c:	60e2                	ld	ra,24(sp)
    80002c9e:	6442                	ld	s0,16(sp)
    80002ca0:	64a2                	ld	s1,8(sp)
    80002ca2:	6902                	ld	s2,0(sp)
    80002ca4:	6105                	addi	sp,sp,32
    80002ca6:	8082                	ret

0000000080002ca8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ca8:	1101                	addi	sp,sp,-32
    80002caa:	ec06                	sd	ra,24(sp)
    80002cac:	e822                	sd	s0,16(sp)
    80002cae:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002cb0:	fec40593          	addi	a1,s0,-20
    80002cb4:	4501                	li	a0,0
    80002cb6:	00000097          	auipc	ra,0x0
    80002cba:	f0e080e7          	jalr	-242(ra) # 80002bc4 <argint>
  exit(n);
    80002cbe:	fec42503          	lw	a0,-20(s0)
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	4dc080e7          	jalr	1244(ra) # 8000219e <exit>
  return 0;  // not reached
}
    80002cca:	4501                	li	a0,0
    80002ccc:	60e2                	ld	ra,24(sp)
    80002cce:	6442                	ld	s0,16(sp)
    80002cd0:	6105                	addi	sp,sp,32
    80002cd2:	8082                	ret

0000000080002cd4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cd4:	1141                	addi	sp,sp,-16
    80002cd6:	e406                	sd	ra,8(sp)
    80002cd8:	e022                	sd	s0,0(sp)
    80002cda:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	cea080e7          	jalr	-790(ra) # 800019c6 <myproc>
}
    80002ce4:	5908                	lw	a0,48(a0)
    80002ce6:	60a2                	ld	ra,8(sp)
    80002ce8:	6402                	ld	s0,0(sp)
    80002cea:	0141                	addi	sp,sp,16
    80002cec:	8082                	ret

0000000080002cee <sys_fork>:

uint64
sys_fork(void)
{
    80002cee:	1141                	addi	sp,sp,-16
    80002cf0:	e406                	sd	ra,8(sp)
    80002cf2:	e022                	sd	s0,0(sp)
    80002cf4:	0800                	addi	s0,sp,16
  return fork();
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	086080e7          	jalr	134(ra) # 80001d7c <fork>
}
    80002cfe:	60a2                	ld	ra,8(sp)
    80002d00:	6402                	ld	s0,0(sp)
    80002d02:	0141                	addi	sp,sp,16
    80002d04:	8082                	ret

0000000080002d06 <sys_wait>:

uint64
sys_wait(void)
{
    80002d06:	1101                	addi	sp,sp,-32
    80002d08:	ec06                	sd	ra,24(sp)
    80002d0a:	e822                	sd	s0,16(sp)
    80002d0c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d0e:	fe840593          	addi	a1,s0,-24
    80002d12:	4501                	li	a0,0
    80002d14:	00000097          	auipc	ra,0x0
    80002d18:	ed0080e7          	jalr	-304(ra) # 80002be4 <argaddr>
  return wait(p);
    80002d1c:	fe843503          	ld	a0,-24(s0)
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	624080e7          	jalr	1572(ra) # 80002344 <wait>
}
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	6105                	addi	sp,sp,32
    80002d2e:	8082                	ret

0000000080002d30 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d30:	7179                	addi	sp,sp,-48
    80002d32:	f406                	sd	ra,40(sp)
    80002d34:	f022                	sd	s0,32(sp)
    80002d36:	ec26                	sd	s1,24(sp)
    80002d38:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d3a:	fdc40593          	addi	a1,s0,-36
    80002d3e:	4501                	li	a0,0
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	e84080e7          	jalr	-380(ra) # 80002bc4 <argint>
  addr = myproc()->sz;
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	c7e080e7          	jalr	-898(ra) # 800019c6 <myproc>
    80002d50:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d52:	fdc42503          	lw	a0,-36(s0)
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	fca080e7          	jalr	-54(ra) # 80001d20 <growproc>
    80002d5e:	00054863          	bltz	a0,80002d6e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d62:	8526                	mv	a0,s1
    80002d64:	70a2                	ld	ra,40(sp)
    80002d66:	7402                	ld	s0,32(sp)
    80002d68:	64e2                	ld	s1,24(sp)
    80002d6a:	6145                	addi	sp,sp,48
    80002d6c:	8082                	ret
    return -1;
    80002d6e:	54fd                	li	s1,-1
    80002d70:	bfcd                	j	80002d62 <sys_sbrk+0x32>

0000000080002d72 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d72:	7139                	addi	sp,sp,-64
    80002d74:	fc06                	sd	ra,56(sp)
    80002d76:	f822                	sd	s0,48(sp)
    80002d78:	f426                	sd	s1,40(sp)
    80002d7a:	f04a                	sd	s2,32(sp)
    80002d7c:	ec4e                	sd	s3,24(sp)
    80002d7e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d80:	fcc40593          	addi	a1,s0,-52
    80002d84:	4501                	li	a0,0
    80002d86:	00000097          	auipc	ra,0x0
    80002d8a:	e3e080e7          	jalr	-450(ra) # 80002bc4 <argint>
  acquire(&tickslock);
    80002d8e:	00014517          	auipc	a0,0x14
    80002d92:	c5250513          	addi	a0,a0,-942 # 800169e0 <tickslock>
    80002d96:	ffffe097          	auipc	ra,0xffffe
    80002d9a:	e54080e7          	jalr	-428(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002d9e:	00006917          	auipc	s2,0x6
    80002da2:	ba292903          	lw	s2,-1118(s2) # 80008940 <ticks>
  while(ticks - ticks0 < n){
    80002da6:	fcc42783          	lw	a5,-52(s0)
    80002daa:	cf9d                	beqz	a5,80002de8 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dac:	00014997          	auipc	s3,0x14
    80002db0:	c3498993          	addi	s3,s3,-972 # 800169e0 <tickslock>
    80002db4:	00006497          	auipc	s1,0x6
    80002db8:	b8c48493          	addi	s1,s1,-1140 # 80008940 <ticks>
    if(killed(myproc())){
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	c0a080e7          	jalr	-1014(ra) # 800019c6 <myproc>
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	54e080e7          	jalr	1358(ra) # 80002312 <killed>
    80002dcc:	ed15                	bnez	a0,80002e08 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002dce:	85ce                	mv	a1,s3
    80002dd0:	8526                	mv	a0,s1
    80002dd2:	fffff097          	auipc	ra,0xfffff
    80002dd6:	298080e7          	jalr	664(ra) # 8000206a <sleep>
  while(ticks - ticks0 < n){
    80002dda:	409c                	lw	a5,0(s1)
    80002ddc:	412787bb          	subw	a5,a5,s2
    80002de0:	fcc42703          	lw	a4,-52(s0)
    80002de4:	fce7ece3          	bltu	a5,a4,80002dbc <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002de8:	00014517          	auipc	a0,0x14
    80002dec:	bf850513          	addi	a0,a0,-1032 # 800169e0 <tickslock>
    80002df0:	ffffe097          	auipc	ra,0xffffe
    80002df4:	eae080e7          	jalr	-338(ra) # 80000c9e <release>
  return 0;
    80002df8:	4501                	li	a0,0
}
    80002dfa:	70e2                	ld	ra,56(sp)
    80002dfc:	7442                	ld	s0,48(sp)
    80002dfe:	74a2                	ld	s1,40(sp)
    80002e00:	7902                	ld	s2,32(sp)
    80002e02:	69e2                	ld	s3,24(sp)
    80002e04:	6121                	addi	sp,sp,64
    80002e06:	8082                	ret
      release(&tickslock);
    80002e08:	00014517          	auipc	a0,0x14
    80002e0c:	bd850513          	addi	a0,a0,-1064 # 800169e0 <tickslock>
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	e8e080e7          	jalr	-370(ra) # 80000c9e <release>
      return -1;
    80002e18:	557d                	li	a0,-1
    80002e1a:	b7c5                	j	80002dfa <sys_sleep+0x88>

0000000080002e1c <sys_scps>:

uint64
sys_scps(void)
{
    80002e1c:	1141                	addi	sp,sp,-16
    80002e1e:	e406                	sd	ra,8(sp)
    80002e20:	e022                	sd	s0,0(sp)
    80002e22:	0800                	addi	s0,sp,16
  scps();
    80002e24:	fffff097          	auipc	ra,0xfffff
    80002e28:	7a8080e7          	jalr	1960(ra) # 800025cc <scps>
  return 0;
}
    80002e2c:	4501                	li	a0,0
    80002e2e:	60a2                	ld	ra,8(sp)
    80002e30:	6402                	ld	s0,0(sp)
    80002e32:	0141                	addi	sp,sp,16
    80002e34:	8082                	ret

0000000080002e36 <sys_kill>:

uint64
sys_kill(void)
{
    80002e36:	1101                	addi	sp,sp,-32
    80002e38:	ec06                	sd	ra,24(sp)
    80002e3a:	e822                	sd	s0,16(sp)
    80002e3c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e3e:	fec40593          	addi	a1,s0,-20
    80002e42:	4501                	li	a0,0
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	d80080e7          	jalr	-640(ra) # 80002bc4 <argint>
  return kill(pid);
    80002e4c:	fec42503          	lw	a0,-20(s0)
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	424080e7          	jalr	1060(ra) # 80002274 <kill>
}
    80002e58:	60e2                	ld	ra,24(sp)
    80002e5a:	6442                	ld	s0,16(sp)
    80002e5c:	6105                	addi	sp,sp,32
    80002e5e:	8082                	ret

0000000080002e60 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e60:	1101                	addi	sp,sp,-32
    80002e62:	ec06                	sd	ra,24(sp)
    80002e64:	e822                	sd	s0,16(sp)
    80002e66:	e426                	sd	s1,8(sp)
    80002e68:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e6a:	00014517          	auipc	a0,0x14
    80002e6e:	b7650513          	addi	a0,a0,-1162 # 800169e0 <tickslock>
    80002e72:	ffffe097          	auipc	ra,0xffffe
    80002e76:	d78080e7          	jalr	-648(ra) # 80000bea <acquire>
  xticks = ticks;
    80002e7a:	00006497          	auipc	s1,0x6
    80002e7e:	ac64a483          	lw	s1,-1338(s1) # 80008940 <ticks>
  release(&tickslock);
    80002e82:	00014517          	auipc	a0,0x14
    80002e86:	b5e50513          	addi	a0,a0,-1186 # 800169e0 <tickslock>
    80002e8a:	ffffe097          	auipc	ra,0xffffe
    80002e8e:	e14080e7          	jalr	-492(ra) # 80000c9e <release>
  return xticks;
}
    80002e92:	02049513          	slli	a0,s1,0x20
    80002e96:	9101                	srli	a0,a0,0x20
    80002e98:	60e2                	ld	ra,24(sp)
    80002e9a:	6442                	ld	s0,16(sp)
    80002e9c:	64a2                	ld	s1,8(sp)
    80002e9e:	6105                	addi	sp,sp,32
    80002ea0:	8082                	ret

0000000080002ea2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ea2:	7179                	addi	sp,sp,-48
    80002ea4:	f406                	sd	ra,40(sp)
    80002ea6:	f022                	sd	s0,32(sp)
    80002ea8:	ec26                	sd	s1,24(sp)
    80002eaa:	e84a                	sd	s2,16(sp)
    80002eac:	e44e                	sd	s3,8(sp)
    80002eae:	e052                	sd	s4,0(sp)
    80002eb0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002eb2:	00005597          	auipc	a1,0x5
    80002eb6:	6ae58593          	addi	a1,a1,1710 # 80008560 <syscalls+0xb8>
    80002eba:	00014517          	auipc	a0,0x14
    80002ebe:	b3e50513          	addi	a0,a0,-1218 # 800169f8 <bcache>
    80002ec2:	ffffe097          	auipc	ra,0xffffe
    80002ec6:	c98080e7          	jalr	-872(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eca:	0001c797          	auipc	a5,0x1c
    80002ece:	b2e78793          	addi	a5,a5,-1234 # 8001e9f8 <bcache+0x8000>
    80002ed2:	0001c717          	auipc	a4,0x1c
    80002ed6:	d8e70713          	addi	a4,a4,-626 # 8001ec60 <bcache+0x8268>
    80002eda:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ede:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ee2:	00014497          	auipc	s1,0x14
    80002ee6:	b2e48493          	addi	s1,s1,-1234 # 80016a10 <bcache+0x18>
    b->next = bcache.head.next;
    80002eea:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002eec:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002eee:	00005a17          	auipc	s4,0x5
    80002ef2:	67aa0a13          	addi	s4,s4,1658 # 80008568 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002ef6:	2b893783          	ld	a5,696(s2)
    80002efa:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002efc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f00:	85d2                	mv	a1,s4
    80002f02:	01048513          	addi	a0,s1,16
    80002f06:	00001097          	auipc	ra,0x1
    80002f0a:	4c4080e7          	jalr	1220(ra) # 800043ca <initsleeplock>
    bcache.head.next->prev = b;
    80002f0e:	2b893783          	ld	a5,696(s2)
    80002f12:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f14:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f18:	45848493          	addi	s1,s1,1112
    80002f1c:	fd349de3          	bne	s1,s3,80002ef6 <binit+0x54>
  }
}
    80002f20:	70a2                	ld	ra,40(sp)
    80002f22:	7402                	ld	s0,32(sp)
    80002f24:	64e2                	ld	s1,24(sp)
    80002f26:	6942                	ld	s2,16(sp)
    80002f28:	69a2                	ld	s3,8(sp)
    80002f2a:	6a02                	ld	s4,0(sp)
    80002f2c:	6145                	addi	sp,sp,48
    80002f2e:	8082                	ret

0000000080002f30 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f30:	7179                	addi	sp,sp,-48
    80002f32:	f406                	sd	ra,40(sp)
    80002f34:	f022                	sd	s0,32(sp)
    80002f36:	ec26                	sd	s1,24(sp)
    80002f38:	e84a                	sd	s2,16(sp)
    80002f3a:	e44e                	sd	s3,8(sp)
    80002f3c:	1800                	addi	s0,sp,48
    80002f3e:	89aa                	mv	s3,a0
    80002f40:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f42:	00014517          	auipc	a0,0x14
    80002f46:	ab650513          	addi	a0,a0,-1354 # 800169f8 <bcache>
    80002f4a:	ffffe097          	auipc	ra,0xffffe
    80002f4e:	ca0080e7          	jalr	-864(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f52:	0001c497          	auipc	s1,0x1c
    80002f56:	d5e4b483          	ld	s1,-674(s1) # 8001ecb0 <bcache+0x82b8>
    80002f5a:	0001c797          	auipc	a5,0x1c
    80002f5e:	d0678793          	addi	a5,a5,-762 # 8001ec60 <bcache+0x8268>
    80002f62:	02f48f63          	beq	s1,a5,80002fa0 <bread+0x70>
    80002f66:	873e                	mv	a4,a5
    80002f68:	a021                	j	80002f70 <bread+0x40>
    80002f6a:	68a4                	ld	s1,80(s1)
    80002f6c:	02e48a63          	beq	s1,a4,80002fa0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f70:	449c                	lw	a5,8(s1)
    80002f72:	ff379ce3          	bne	a5,s3,80002f6a <bread+0x3a>
    80002f76:	44dc                	lw	a5,12(s1)
    80002f78:	ff2799e3          	bne	a5,s2,80002f6a <bread+0x3a>
      b->refcnt++;
    80002f7c:	40bc                	lw	a5,64(s1)
    80002f7e:	2785                	addiw	a5,a5,1
    80002f80:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f82:	00014517          	auipc	a0,0x14
    80002f86:	a7650513          	addi	a0,a0,-1418 # 800169f8 <bcache>
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	d14080e7          	jalr	-748(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80002f92:	01048513          	addi	a0,s1,16
    80002f96:	00001097          	auipc	ra,0x1
    80002f9a:	46e080e7          	jalr	1134(ra) # 80004404 <acquiresleep>
      return b;
    80002f9e:	a8b9                	j	80002ffc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fa0:	0001c497          	auipc	s1,0x1c
    80002fa4:	d084b483          	ld	s1,-760(s1) # 8001eca8 <bcache+0x82b0>
    80002fa8:	0001c797          	auipc	a5,0x1c
    80002fac:	cb878793          	addi	a5,a5,-840 # 8001ec60 <bcache+0x8268>
    80002fb0:	00f48863          	beq	s1,a5,80002fc0 <bread+0x90>
    80002fb4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fb6:	40bc                	lw	a5,64(s1)
    80002fb8:	cf81                	beqz	a5,80002fd0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fba:	64a4                	ld	s1,72(s1)
    80002fbc:	fee49de3          	bne	s1,a4,80002fb6 <bread+0x86>
  panic("bget: no buffers");
    80002fc0:	00005517          	auipc	a0,0x5
    80002fc4:	5b050513          	addi	a0,a0,1456 # 80008570 <syscalls+0xc8>
    80002fc8:	ffffd097          	auipc	ra,0xffffd
    80002fcc:	57c080e7          	jalr	1404(ra) # 80000544 <panic>
      b->dev = dev;
    80002fd0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fd4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fd8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fdc:	4785                	li	a5,1
    80002fde:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe0:	00014517          	auipc	a0,0x14
    80002fe4:	a1850513          	addi	a0,a0,-1512 # 800169f8 <bcache>
    80002fe8:	ffffe097          	auipc	ra,0xffffe
    80002fec:	cb6080e7          	jalr	-842(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80002ff0:	01048513          	addi	a0,s1,16
    80002ff4:	00001097          	auipc	ra,0x1
    80002ff8:	410080e7          	jalr	1040(ra) # 80004404 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ffc:	409c                	lw	a5,0(s1)
    80002ffe:	cb89                	beqz	a5,80003010 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003000:	8526                	mv	a0,s1
    80003002:	70a2                	ld	ra,40(sp)
    80003004:	7402                	ld	s0,32(sp)
    80003006:	64e2                	ld	s1,24(sp)
    80003008:	6942                	ld	s2,16(sp)
    8000300a:	69a2                	ld	s3,8(sp)
    8000300c:	6145                	addi	sp,sp,48
    8000300e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003010:	4581                	li	a1,0
    80003012:	8526                	mv	a0,s1
    80003014:	00003097          	auipc	ra,0x3
    80003018:	fc4080e7          	jalr	-60(ra) # 80005fd8 <virtio_disk_rw>
    b->valid = 1;
    8000301c:	4785                	li	a5,1
    8000301e:	c09c                	sw	a5,0(s1)
  return b;
    80003020:	b7c5                	j	80003000 <bread+0xd0>

0000000080003022 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003022:	1101                	addi	sp,sp,-32
    80003024:	ec06                	sd	ra,24(sp)
    80003026:	e822                	sd	s0,16(sp)
    80003028:	e426                	sd	s1,8(sp)
    8000302a:	1000                	addi	s0,sp,32
    8000302c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000302e:	0541                	addi	a0,a0,16
    80003030:	00001097          	auipc	ra,0x1
    80003034:	46e080e7          	jalr	1134(ra) # 8000449e <holdingsleep>
    80003038:	cd01                	beqz	a0,80003050 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000303a:	4585                	li	a1,1
    8000303c:	8526                	mv	a0,s1
    8000303e:	00003097          	auipc	ra,0x3
    80003042:	f9a080e7          	jalr	-102(ra) # 80005fd8 <virtio_disk_rw>
}
    80003046:	60e2                	ld	ra,24(sp)
    80003048:	6442                	ld	s0,16(sp)
    8000304a:	64a2                	ld	s1,8(sp)
    8000304c:	6105                	addi	sp,sp,32
    8000304e:	8082                	ret
    panic("bwrite");
    80003050:	00005517          	auipc	a0,0x5
    80003054:	53850513          	addi	a0,a0,1336 # 80008588 <syscalls+0xe0>
    80003058:	ffffd097          	auipc	ra,0xffffd
    8000305c:	4ec080e7          	jalr	1260(ra) # 80000544 <panic>

0000000080003060 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003060:	1101                	addi	sp,sp,-32
    80003062:	ec06                	sd	ra,24(sp)
    80003064:	e822                	sd	s0,16(sp)
    80003066:	e426                	sd	s1,8(sp)
    80003068:	e04a                	sd	s2,0(sp)
    8000306a:	1000                	addi	s0,sp,32
    8000306c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000306e:	01050913          	addi	s2,a0,16
    80003072:	854a                	mv	a0,s2
    80003074:	00001097          	auipc	ra,0x1
    80003078:	42a080e7          	jalr	1066(ra) # 8000449e <holdingsleep>
    8000307c:	c92d                	beqz	a0,800030ee <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000307e:	854a                	mv	a0,s2
    80003080:	00001097          	auipc	ra,0x1
    80003084:	3da080e7          	jalr	986(ra) # 8000445a <releasesleep>

  acquire(&bcache.lock);
    80003088:	00014517          	auipc	a0,0x14
    8000308c:	97050513          	addi	a0,a0,-1680 # 800169f8 <bcache>
    80003090:	ffffe097          	auipc	ra,0xffffe
    80003094:	b5a080e7          	jalr	-1190(ra) # 80000bea <acquire>
  b->refcnt--;
    80003098:	40bc                	lw	a5,64(s1)
    8000309a:	37fd                	addiw	a5,a5,-1
    8000309c:	0007871b          	sext.w	a4,a5
    800030a0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030a2:	eb05                	bnez	a4,800030d2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030a4:	68bc                	ld	a5,80(s1)
    800030a6:	64b8                	ld	a4,72(s1)
    800030a8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030aa:	64bc                	ld	a5,72(s1)
    800030ac:	68b8                	ld	a4,80(s1)
    800030ae:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030b0:	0001c797          	auipc	a5,0x1c
    800030b4:	94878793          	addi	a5,a5,-1720 # 8001e9f8 <bcache+0x8000>
    800030b8:	2b87b703          	ld	a4,696(a5)
    800030bc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030be:	0001c717          	auipc	a4,0x1c
    800030c2:	ba270713          	addi	a4,a4,-1118 # 8001ec60 <bcache+0x8268>
    800030c6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030c8:	2b87b703          	ld	a4,696(a5)
    800030cc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030ce:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030d2:	00014517          	auipc	a0,0x14
    800030d6:	92650513          	addi	a0,a0,-1754 # 800169f8 <bcache>
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	bc4080e7          	jalr	-1084(ra) # 80000c9e <release>
}
    800030e2:	60e2                	ld	ra,24(sp)
    800030e4:	6442                	ld	s0,16(sp)
    800030e6:	64a2                	ld	s1,8(sp)
    800030e8:	6902                	ld	s2,0(sp)
    800030ea:	6105                	addi	sp,sp,32
    800030ec:	8082                	ret
    panic("brelse");
    800030ee:	00005517          	auipc	a0,0x5
    800030f2:	4a250513          	addi	a0,a0,1186 # 80008590 <syscalls+0xe8>
    800030f6:	ffffd097          	auipc	ra,0xffffd
    800030fa:	44e080e7          	jalr	1102(ra) # 80000544 <panic>

00000000800030fe <bpin>:

void
bpin(struct buf *b) {
    800030fe:	1101                	addi	sp,sp,-32
    80003100:	ec06                	sd	ra,24(sp)
    80003102:	e822                	sd	s0,16(sp)
    80003104:	e426                	sd	s1,8(sp)
    80003106:	1000                	addi	s0,sp,32
    80003108:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000310a:	00014517          	auipc	a0,0x14
    8000310e:	8ee50513          	addi	a0,a0,-1810 # 800169f8 <bcache>
    80003112:	ffffe097          	auipc	ra,0xffffe
    80003116:	ad8080e7          	jalr	-1320(ra) # 80000bea <acquire>
  b->refcnt++;
    8000311a:	40bc                	lw	a5,64(s1)
    8000311c:	2785                	addiw	a5,a5,1
    8000311e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003120:	00014517          	auipc	a0,0x14
    80003124:	8d850513          	addi	a0,a0,-1832 # 800169f8 <bcache>
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	b76080e7          	jalr	-1162(ra) # 80000c9e <release>
}
    80003130:	60e2                	ld	ra,24(sp)
    80003132:	6442                	ld	s0,16(sp)
    80003134:	64a2                	ld	s1,8(sp)
    80003136:	6105                	addi	sp,sp,32
    80003138:	8082                	ret

000000008000313a <bunpin>:

void
bunpin(struct buf *b) {
    8000313a:	1101                	addi	sp,sp,-32
    8000313c:	ec06                	sd	ra,24(sp)
    8000313e:	e822                	sd	s0,16(sp)
    80003140:	e426                	sd	s1,8(sp)
    80003142:	1000                	addi	s0,sp,32
    80003144:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003146:	00014517          	auipc	a0,0x14
    8000314a:	8b250513          	addi	a0,a0,-1870 # 800169f8 <bcache>
    8000314e:	ffffe097          	auipc	ra,0xffffe
    80003152:	a9c080e7          	jalr	-1380(ra) # 80000bea <acquire>
  b->refcnt--;
    80003156:	40bc                	lw	a5,64(s1)
    80003158:	37fd                	addiw	a5,a5,-1
    8000315a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000315c:	00014517          	auipc	a0,0x14
    80003160:	89c50513          	addi	a0,a0,-1892 # 800169f8 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	b3a080e7          	jalr	-1222(ra) # 80000c9e <release>
}
    8000316c:	60e2                	ld	ra,24(sp)
    8000316e:	6442                	ld	s0,16(sp)
    80003170:	64a2                	ld	s1,8(sp)
    80003172:	6105                	addi	sp,sp,32
    80003174:	8082                	ret

0000000080003176 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003176:	1101                	addi	sp,sp,-32
    80003178:	ec06                	sd	ra,24(sp)
    8000317a:	e822                	sd	s0,16(sp)
    8000317c:	e426                	sd	s1,8(sp)
    8000317e:	e04a                	sd	s2,0(sp)
    80003180:	1000                	addi	s0,sp,32
    80003182:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003184:	00d5d59b          	srliw	a1,a1,0xd
    80003188:	0001c797          	auipc	a5,0x1c
    8000318c:	f4c7a783          	lw	a5,-180(a5) # 8001f0d4 <sb+0x1c>
    80003190:	9dbd                	addw	a1,a1,a5
    80003192:	00000097          	auipc	ra,0x0
    80003196:	d9e080e7          	jalr	-610(ra) # 80002f30 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000319a:	0074f713          	andi	a4,s1,7
    8000319e:	4785                	li	a5,1
    800031a0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031a4:	14ce                	slli	s1,s1,0x33
    800031a6:	90d9                	srli	s1,s1,0x36
    800031a8:	00950733          	add	a4,a0,s1
    800031ac:	05874703          	lbu	a4,88(a4)
    800031b0:	00e7f6b3          	and	a3,a5,a4
    800031b4:	c69d                	beqz	a3,800031e2 <bfree+0x6c>
    800031b6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031b8:	94aa                	add	s1,s1,a0
    800031ba:	fff7c793          	not	a5,a5
    800031be:	8ff9                	and	a5,a5,a4
    800031c0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031c4:	00001097          	auipc	ra,0x1
    800031c8:	120080e7          	jalr	288(ra) # 800042e4 <log_write>
  brelse(bp);
    800031cc:	854a                	mv	a0,s2
    800031ce:	00000097          	auipc	ra,0x0
    800031d2:	e92080e7          	jalr	-366(ra) # 80003060 <brelse>
}
    800031d6:	60e2                	ld	ra,24(sp)
    800031d8:	6442                	ld	s0,16(sp)
    800031da:	64a2                	ld	s1,8(sp)
    800031dc:	6902                	ld	s2,0(sp)
    800031de:	6105                	addi	sp,sp,32
    800031e0:	8082                	ret
    panic("freeing free block");
    800031e2:	00005517          	auipc	a0,0x5
    800031e6:	3b650513          	addi	a0,a0,950 # 80008598 <syscalls+0xf0>
    800031ea:	ffffd097          	auipc	ra,0xffffd
    800031ee:	35a080e7          	jalr	858(ra) # 80000544 <panic>

00000000800031f2 <balloc>:
{
    800031f2:	711d                	addi	sp,sp,-96
    800031f4:	ec86                	sd	ra,88(sp)
    800031f6:	e8a2                	sd	s0,80(sp)
    800031f8:	e4a6                	sd	s1,72(sp)
    800031fa:	e0ca                	sd	s2,64(sp)
    800031fc:	fc4e                	sd	s3,56(sp)
    800031fe:	f852                	sd	s4,48(sp)
    80003200:	f456                	sd	s5,40(sp)
    80003202:	f05a                	sd	s6,32(sp)
    80003204:	ec5e                	sd	s7,24(sp)
    80003206:	e862                	sd	s8,16(sp)
    80003208:	e466                	sd	s9,8(sp)
    8000320a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000320c:	0001c797          	auipc	a5,0x1c
    80003210:	eb07a783          	lw	a5,-336(a5) # 8001f0bc <sb+0x4>
    80003214:	10078163          	beqz	a5,80003316 <balloc+0x124>
    80003218:	8baa                	mv	s7,a0
    8000321a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000321c:	0001cb17          	auipc	s6,0x1c
    80003220:	e9cb0b13          	addi	s6,s6,-356 # 8001f0b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003224:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003226:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003228:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000322a:	6c89                	lui	s9,0x2
    8000322c:	a061                	j	800032b4 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000322e:	974a                	add	a4,a4,s2
    80003230:	8fd5                	or	a5,a5,a3
    80003232:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003236:	854a                	mv	a0,s2
    80003238:	00001097          	auipc	ra,0x1
    8000323c:	0ac080e7          	jalr	172(ra) # 800042e4 <log_write>
        brelse(bp);
    80003240:	854a                	mv	a0,s2
    80003242:	00000097          	auipc	ra,0x0
    80003246:	e1e080e7          	jalr	-482(ra) # 80003060 <brelse>
  bp = bread(dev, bno);
    8000324a:	85a6                	mv	a1,s1
    8000324c:	855e                	mv	a0,s7
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	ce2080e7          	jalr	-798(ra) # 80002f30 <bread>
    80003256:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003258:	40000613          	li	a2,1024
    8000325c:	4581                	li	a1,0
    8000325e:	05850513          	addi	a0,a0,88
    80003262:	ffffe097          	auipc	ra,0xffffe
    80003266:	a84080e7          	jalr	-1404(ra) # 80000ce6 <memset>
  log_write(bp);
    8000326a:	854a                	mv	a0,s2
    8000326c:	00001097          	auipc	ra,0x1
    80003270:	078080e7          	jalr	120(ra) # 800042e4 <log_write>
  brelse(bp);
    80003274:	854a                	mv	a0,s2
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	dea080e7          	jalr	-534(ra) # 80003060 <brelse>
}
    8000327e:	8526                	mv	a0,s1
    80003280:	60e6                	ld	ra,88(sp)
    80003282:	6446                	ld	s0,80(sp)
    80003284:	64a6                	ld	s1,72(sp)
    80003286:	6906                	ld	s2,64(sp)
    80003288:	79e2                	ld	s3,56(sp)
    8000328a:	7a42                	ld	s4,48(sp)
    8000328c:	7aa2                	ld	s5,40(sp)
    8000328e:	7b02                	ld	s6,32(sp)
    80003290:	6be2                	ld	s7,24(sp)
    80003292:	6c42                	ld	s8,16(sp)
    80003294:	6ca2                	ld	s9,8(sp)
    80003296:	6125                	addi	sp,sp,96
    80003298:	8082                	ret
    brelse(bp);
    8000329a:	854a                	mv	a0,s2
    8000329c:	00000097          	auipc	ra,0x0
    800032a0:	dc4080e7          	jalr	-572(ra) # 80003060 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032a4:	015c87bb          	addw	a5,s9,s5
    800032a8:	00078a9b          	sext.w	s5,a5
    800032ac:	004b2703          	lw	a4,4(s6)
    800032b0:	06eaf363          	bgeu	s5,a4,80003316 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800032b4:	41fad79b          	sraiw	a5,s5,0x1f
    800032b8:	0137d79b          	srliw	a5,a5,0x13
    800032bc:	015787bb          	addw	a5,a5,s5
    800032c0:	40d7d79b          	sraiw	a5,a5,0xd
    800032c4:	01cb2583          	lw	a1,28(s6)
    800032c8:	9dbd                	addw	a1,a1,a5
    800032ca:	855e                	mv	a0,s7
    800032cc:	00000097          	auipc	ra,0x0
    800032d0:	c64080e7          	jalr	-924(ra) # 80002f30 <bread>
    800032d4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d6:	004b2503          	lw	a0,4(s6)
    800032da:	000a849b          	sext.w	s1,s5
    800032de:	8662                	mv	a2,s8
    800032e0:	faa4fde3          	bgeu	s1,a0,8000329a <balloc+0xa8>
      m = 1 << (bi % 8);
    800032e4:	41f6579b          	sraiw	a5,a2,0x1f
    800032e8:	01d7d69b          	srliw	a3,a5,0x1d
    800032ec:	00c6873b          	addw	a4,a3,a2
    800032f0:	00777793          	andi	a5,a4,7
    800032f4:	9f95                	subw	a5,a5,a3
    800032f6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032fa:	4037571b          	sraiw	a4,a4,0x3
    800032fe:	00e906b3          	add	a3,s2,a4
    80003302:	0586c683          	lbu	a3,88(a3)
    80003306:	00d7f5b3          	and	a1,a5,a3
    8000330a:	d195                	beqz	a1,8000322e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000330c:	2605                	addiw	a2,a2,1
    8000330e:	2485                	addiw	s1,s1,1
    80003310:	fd4618e3          	bne	a2,s4,800032e0 <balloc+0xee>
    80003314:	b759                	j	8000329a <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003316:	00005517          	auipc	a0,0x5
    8000331a:	29a50513          	addi	a0,a0,666 # 800085b0 <syscalls+0x108>
    8000331e:	ffffd097          	auipc	ra,0xffffd
    80003322:	270080e7          	jalr	624(ra) # 8000058e <printf>
  return 0;
    80003326:	4481                	li	s1,0
    80003328:	bf99                	j	8000327e <balloc+0x8c>

000000008000332a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000332a:	7179                	addi	sp,sp,-48
    8000332c:	f406                	sd	ra,40(sp)
    8000332e:	f022                	sd	s0,32(sp)
    80003330:	ec26                	sd	s1,24(sp)
    80003332:	e84a                	sd	s2,16(sp)
    80003334:	e44e                	sd	s3,8(sp)
    80003336:	e052                	sd	s4,0(sp)
    80003338:	1800                	addi	s0,sp,48
    8000333a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000333c:	47ad                	li	a5,11
    8000333e:	02b7e763          	bltu	a5,a1,8000336c <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003342:	02059493          	slli	s1,a1,0x20
    80003346:	9081                	srli	s1,s1,0x20
    80003348:	048a                	slli	s1,s1,0x2
    8000334a:	94aa                	add	s1,s1,a0
    8000334c:	0504a903          	lw	s2,80(s1)
    80003350:	06091e63          	bnez	s2,800033cc <bmap+0xa2>
      addr = balloc(ip->dev);
    80003354:	4108                	lw	a0,0(a0)
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	e9c080e7          	jalr	-356(ra) # 800031f2 <balloc>
    8000335e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003362:	06090563          	beqz	s2,800033cc <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003366:	0524a823          	sw	s2,80(s1)
    8000336a:	a08d                	j	800033cc <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000336c:	ff45849b          	addiw	s1,a1,-12
    80003370:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003374:	0ff00793          	li	a5,255
    80003378:	08e7e563          	bltu	a5,a4,80003402 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000337c:	08052903          	lw	s2,128(a0)
    80003380:	00091d63          	bnez	s2,8000339a <bmap+0x70>
      addr = balloc(ip->dev);
    80003384:	4108                	lw	a0,0(a0)
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	e6c080e7          	jalr	-404(ra) # 800031f2 <balloc>
    8000338e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003392:	02090d63          	beqz	s2,800033cc <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003396:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000339a:	85ca                	mv	a1,s2
    8000339c:	0009a503          	lw	a0,0(s3)
    800033a0:	00000097          	auipc	ra,0x0
    800033a4:	b90080e7          	jalr	-1136(ra) # 80002f30 <bread>
    800033a8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033aa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033ae:	02049593          	slli	a1,s1,0x20
    800033b2:	9181                	srli	a1,a1,0x20
    800033b4:	058a                	slli	a1,a1,0x2
    800033b6:	00b784b3          	add	s1,a5,a1
    800033ba:	0004a903          	lw	s2,0(s1)
    800033be:	02090063          	beqz	s2,800033de <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033c2:	8552                	mv	a0,s4
    800033c4:	00000097          	auipc	ra,0x0
    800033c8:	c9c080e7          	jalr	-868(ra) # 80003060 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033cc:	854a                	mv	a0,s2
    800033ce:	70a2                	ld	ra,40(sp)
    800033d0:	7402                	ld	s0,32(sp)
    800033d2:	64e2                	ld	s1,24(sp)
    800033d4:	6942                	ld	s2,16(sp)
    800033d6:	69a2                	ld	s3,8(sp)
    800033d8:	6a02                	ld	s4,0(sp)
    800033da:	6145                	addi	sp,sp,48
    800033dc:	8082                	ret
      addr = balloc(ip->dev);
    800033de:	0009a503          	lw	a0,0(s3)
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	e10080e7          	jalr	-496(ra) # 800031f2 <balloc>
    800033ea:	0005091b          	sext.w	s2,a0
      if(addr){
    800033ee:	fc090ae3          	beqz	s2,800033c2 <bmap+0x98>
        a[bn] = addr;
    800033f2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800033f6:	8552                	mv	a0,s4
    800033f8:	00001097          	auipc	ra,0x1
    800033fc:	eec080e7          	jalr	-276(ra) # 800042e4 <log_write>
    80003400:	b7c9                	j	800033c2 <bmap+0x98>
  panic("bmap: out of range");
    80003402:	00005517          	auipc	a0,0x5
    80003406:	1c650513          	addi	a0,a0,454 # 800085c8 <syscalls+0x120>
    8000340a:	ffffd097          	auipc	ra,0xffffd
    8000340e:	13a080e7          	jalr	314(ra) # 80000544 <panic>

0000000080003412 <iget>:
{
    80003412:	7179                	addi	sp,sp,-48
    80003414:	f406                	sd	ra,40(sp)
    80003416:	f022                	sd	s0,32(sp)
    80003418:	ec26                	sd	s1,24(sp)
    8000341a:	e84a                	sd	s2,16(sp)
    8000341c:	e44e                	sd	s3,8(sp)
    8000341e:	e052                	sd	s4,0(sp)
    80003420:	1800                	addi	s0,sp,48
    80003422:	89aa                	mv	s3,a0
    80003424:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003426:	0001c517          	auipc	a0,0x1c
    8000342a:	cb250513          	addi	a0,a0,-846 # 8001f0d8 <itable>
    8000342e:	ffffd097          	auipc	ra,0xffffd
    80003432:	7bc080e7          	jalr	1980(ra) # 80000bea <acquire>
  empty = 0;
    80003436:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003438:	0001c497          	auipc	s1,0x1c
    8000343c:	cb848493          	addi	s1,s1,-840 # 8001f0f0 <itable+0x18>
    80003440:	0001d697          	auipc	a3,0x1d
    80003444:	74068693          	addi	a3,a3,1856 # 80020b80 <log>
    80003448:	a039                	j	80003456 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000344a:	02090b63          	beqz	s2,80003480 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000344e:	08848493          	addi	s1,s1,136
    80003452:	02d48a63          	beq	s1,a3,80003486 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003456:	449c                	lw	a5,8(s1)
    80003458:	fef059e3          	blez	a5,8000344a <iget+0x38>
    8000345c:	4098                	lw	a4,0(s1)
    8000345e:	ff3716e3          	bne	a4,s3,8000344a <iget+0x38>
    80003462:	40d8                	lw	a4,4(s1)
    80003464:	ff4713e3          	bne	a4,s4,8000344a <iget+0x38>
      ip->ref++;
    80003468:	2785                	addiw	a5,a5,1
    8000346a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000346c:	0001c517          	auipc	a0,0x1c
    80003470:	c6c50513          	addi	a0,a0,-916 # 8001f0d8 <itable>
    80003474:	ffffe097          	auipc	ra,0xffffe
    80003478:	82a080e7          	jalr	-2006(ra) # 80000c9e <release>
      return ip;
    8000347c:	8926                	mv	s2,s1
    8000347e:	a03d                	j	800034ac <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003480:	f7f9                	bnez	a5,8000344e <iget+0x3c>
    80003482:	8926                	mv	s2,s1
    80003484:	b7e9                	j	8000344e <iget+0x3c>
  if(empty == 0)
    80003486:	02090c63          	beqz	s2,800034be <iget+0xac>
  ip->dev = dev;
    8000348a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000348e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003492:	4785                	li	a5,1
    80003494:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003498:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000349c:	0001c517          	auipc	a0,0x1c
    800034a0:	c3c50513          	addi	a0,a0,-964 # 8001f0d8 <itable>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	7fa080e7          	jalr	2042(ra) # 80000c9e <release>
}
    800034ac:	854a                	mv	a0,s2
    800034ae:	70a2                	ld	ra,40(sp)
    800034b0:	7402                	ld	s0,32(sp)
    800034b2:	64e2                	ld	s1,24(sp)
    800034b4:	6942                	ld	s2,16(sp)
    800034b6:	69a2                	ld	s3,8(sp)
    800034b8:	6a02                	ld	s4,0(sp)
    800034ba:	6145                	addi	sp,sp,48
    800034bc:	8082                	ret
    panic("iget: no inodes");
    800034be:	00005517          	auipc	a0,0x5
    800034c2:	12250513          	addi	a0,a0,290 # 800085e0 <syscalls+0x138>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	07e080e7          	jalr	126(ra) # 80000544 <panic>

00000000800034ce <fsinit>:
fsinit(int dev) {
    800034ce:	7179                	addi	sp,sp,-48
    800034d0:	f406                	sd	ra,40(sp)
    800034d2:	f022                	sd	s0,32(sp)
    800034d4:	ec26                	sd	s1,24(sp)
    800034d6:	e84a                	sd	s2,16(sp)
    800034d8:	e44e                	sd	s3,8(sp)
    800034da:	1800                	addi	s0,sp,48
    800034dc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034de:	4585                	li	a1,1
    800034e0:	00000097          	auipc	ra,0x0
    800034e4:	a50080e7          	jalr	-1456(ra) # 80002f30 <bread>
    800034e8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034ea:	0001c997          	auipc	s3,0x1c
    800034ee:	bce98993          	addi	s3,s3,-1074 # 8001f0b8 <sb>
    800034f2:	02000613          	li	a2,32
    800034f6:	05850593          	addi	a1,a0,88
    800034fa:	854e                	mv	a0,s3
    800034fc:	ffffe097          	auipc	ra,0xffffe
    80003500:	84a080e7          	jalr	-1974(ra) # 80000d46 <memmove>
  brelse(bp);
    80003504:	8526                	mv	a0,s1
    80003506:	00000097          	auipc	ra,0x0
    8000350a:	b5a080e7          	jalr	-1190(ra) # 80003060 <brelse>
  if(sb.magic != FSMAGIC)
    8000350e:	0009a703          	lw	a4,0(s3)
    80003512:	102037b7          	lui	a5,0x10203
    80003516:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000351a:	02f71263          	bne	a4,a5,8000353e <fsinit+0x70>
  initlog(dev, &sb);
    8000351e:	0001c597          	auipc	a1,0x1c
    80003522:	b9a58593          	addi	a1,a1,-1126 # 8001f0b8 <sb>
    80003526:	854a                	mv	a0,s2
    80003528:	00001097          	auipc	ra,0x1
    8000352c:	b40080e7          	jalr	-1216(ra) # 80004068 <initlog>
}
    80003530:	70a2                	ld	ra,40(sp)
    80003532:	7402                	ld	s0,32(sp)
    80003534:	64e2                	ld	s1,24(sp)
    80003536:	6942                	ld	s2,16(sp)
    80003538:	69a2                	ld	s3,8(sp)
    8000353a:	6145                	addi	sp,sp,48
    8000353c:	8082                	ret
    panic("invalid file system");
    8000353e:	00005517          	auipc	a0,0x5
    80003542:	0b250513          	addi	a0,a0,178 # 800085f0 <syscalls+0x148>
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	ffe080e7          	jalr	-2(ra) # 80000544 <panic>

000000008000354e <iinit>:
{
    8000354e:	7179                	addi	sp,sp,-48
    80003550:	f406                	sd	ra,40(sp)
    80003552:	f022                	sd	s0,32(sp)
    80003554:	ec26                	sd	s1,24(sp)
    80003556:	e84a                	sd	s2,16(sp)
    80003558:	e44e                	sd	s3,8(sp)
    8000355a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000355c:	00005597          	auipc	a1,0x5
    80003560:	0ac58593          	addi	a1,a1,172 # 80008608 <syscalls+0x160>
    80003564:	0001c517          	auipc	a0,0x1c
    80003568:	b7450513          	addi	a0,a0,-1164 # 8001f0d8 <itable>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	5ee080e7          	jalr	1518(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003574:	0001c497          	auipc	s1,0x1c
    80003578:	b8c48493          	addi	s1,s1,-1140 # 8001f100 <itable+0x28>
    8000357c:	0001d997          	auipc	s3,0x1d
    80003580:	61498993          	addi	s3,s3,1556 # 80020b90 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003584:	00005917          	auipc	s2,0x5
    80003588:	08c90913          	addi	s2,s2,140 # 80008610 <syscalls+0x168>
    8000358c:	85ca                	mv	a1,s2
    8000358e:	8526                	mv	a0,s1
    80003590:	00001097          	auipc	ra,0x1
    80003594:	e3a080e7          	jalr	-454(ra) # 800043ca <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003598:	08848493          	addi	s1,s1,136
    8000359c:	ff3498e3          	bne	s1,s3,8000358c <iinit+0x3e>
}
    800035a0:	70a2                	ld	ra,40(sp)
    800035a2:	7402                	ld	s0,32(sp)
    800035a4:	64e2                	ld	s1,24(sp)
    800035a6:	6942                	ld	s2,16(sp)
    800035a8:	69a2                	ld	s3,8(sp)
    800035aa:	6145                	addi	sp,sp,48
    800035ac:	8082                	ret

00000000800035ae <ialloc>:
{
    800035ae:	715d                	addi	sp,sp,-80
    800035b0:	e486                	sd	ra,72(sp)
    800035b2:	e0a2                	sd	s0,64(sp)
    800035b4:	fc26                	sd	s1,56(sp)
    800035b6:	f84a                	sd	s2,48(sp)
    800035b8:	f44e                	sd	s3,40(sp)
    800035ba:	f052                	sd	s4,32(sp)
    800035bc:	ec56                	sd	s5,24(sp)
    800035be:	e85a                	sd	s6,16(sp)
    800035c0:	e45e                	sd	s7,8(sp)
    800035c2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035c4:	0001c717          	auipc	a4,0x1c
    800035c8:	b0072703          	lw	a4,-1280(a4) # 8001f0c4 <sb+0xc>
    800035cc:	4785                	li	a5,1
    800035ce:	04e7fa63          	bgeu	a5,a4,80003622 <ialloc+0x74>
    800035d2:	8aaa                	mv	s5,a0
    800035d4:	8bae                	mv	s7,a1
    800035d6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035d8:	0001ca17          	auipc	s4,0x1c
    800035dc:	ae0a0a13          	addi	s4,s4,-1312 # 8001f0b8 <sb>
    800035e0:	00048b1b          	sext.w	s6,s1
    800035e4:	0044d593          	srli	a1,s1,0x4
    800035e8:	018a2783          	lw	a5,24(s4)
    800035ec:	9dbd                	addw	a1,a1,a5
    800035ee:	8556                	mv	a0,s5
    800035f0:	00000097          	auipc	ra,0x0
    800035f4:	940080e7          	jalr	-1728(ra) # 80002f30 <bread>
    800035f8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035fa:	05850993          	addi	s3,a0,88
    800035fe:	00f4f793          	andi	a5,s1,15
    80003602:	079a                	slli	a5,a5,0x6
    80003604:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003606:	00099783          	lh	a5,0(s3)
    8000360a:	c3a1                	beqz	a5,8000364a <ialloc+0x9c>
    brelse(bp);
    8000360c:	00000097          	auipc	ra,0x0
    80003610:	a54080e7          	jalr	-1452(ra) # 80003060 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003614:	0485                	addi	s1,s1,1
    80003616:	00ca2703          	lw	a4,12(s4)
    8000361a:	0004879b          	sext.w	a5,s1
    8000361e:	fce7e1e3          	bltu	a5,a4,800035e0 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003622:	00005517          	auipc	a0,0x5
    80003626:	ff650513          	addi	a0,a0,-10 # 80008618 <syscalls+0x170>
    8000362a:	ffffd097          	auipc	ra,0xffffd
    8000362e:	f64080e7          	jalr	-156(ra) # 8000058e <printf>
  return 0;
    80003632:	4501                	li	a0,0
}
    80003634:	60a6                	ld	ra,72(sp)
    80003636:	6406                	ld	s0,64(sp)
    80003638:	74e2                	ld	s1,56(sp)
    8000363a:	7942                	ld	s2,48(sp)
    8000363c:	79a2                	ld	s3,40(sp)
    8000363e:	7a02                	ld	s4,32(sp)
    80003640:	6ae2                	ld	s5,24(sp)
    80003642:	6b42                	ld	s6,16(sp)
    80003644:	6ba2                	ld	s7,8(sp)
    80003646:	6161                	addi	sp,sp,80
    80003648:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000364a:	04000613          	li	a2,64
    8000364e:	4581                	li	a1,0
    80003650:	854e                	mv	a0,s3
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	694080e7          	jalr	1684(ra) # 80000ce6 <memset>
      dip->type = type;
    8000365a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000365e:	854a                	mv	a0,s2
    80003660:	00001097          	auipc	ra,0x1
    80003664:	c84080e7          	jalr	-892(ra) # 800042e4 <log_write>
      brelse(bp);
    80003668:	854a                	mv	a0,s2
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	9f6080e7          	jalr	-1546(ra) # 80003060 <brelse>
      return iget(dev, inum);
    80003672:	85da                	mv	a1,s6
    80003674:	8556                	mv	a0,s5
    80003676:	00000097          	auipc	ra,0x0
    8000367a:	d9c080e7          	jalr	-612(ra) # 80003412 <iget>
    8000367e:	bf5d                	j	80003634 <ialloc+0x86>

0000000080003680 <iupdate>:
{
    80003680:	1101                	addi	sp,sp,-32
    80003682:	ec06                	sd	ra,24(sp)
    80003684:	e822                	sd	s0,16(sp)
    80003686:	e426                	sd	s1,8(sp)
    80003688:	e04a                	sd	s2,0(sp)
    8000368a:	1000                	addi	s0,sp,32
    8000368c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000368e:	415c                	lw	a5,4(a0)
    80003690:	0047d79b          	srliw	a5,a5,0x4
    80003694:	0001c597          	auipc	a1,0x1c
    80003698:	a3c5a583          	lw	a1,-1476(a1) # 8001f0d0 <sb+0x18>
    8000369c:	9dbd                	addw	a1,a1,a5
    8000369e:	4108                	lw	a0,0(a0)
    800036a0:	00000097          	auipc	ra,0x0
    800036a4:	890080e7          	jalr	-1904(ra) # 80002f30 <bread>
    800036a8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036aa:	05850793          	addi	a5,a0,88
    800036ae:	40c8                	lw	a0,4(s1)
    800036b0:	893d                	andi	a0,a0,15
    800036b2:	051a                	slli	a0,a0,0x6
    800036b4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036b6:	04449703          	lh	a4,68(s1)
    800036ba:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036be:	04649703          	lh	a4,70(s1)
    800036c2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036c6:	04849703          	lh	a4,72(s1)
    800036ca:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036ce:	04a49703          	lh	a4,74(s1)
    800036d2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036d6:	44f8                	lw	a4,76(s1)
    800036d8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036da:	03400613          	li	a2,52
    800036de:	05048593          	addi	a1,s1,80
    800036e2:	0531                	addi	a0,a0,12
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	662080e7          	jalr	1634(ra) # 80000d46 <memmove>
  log_write(bp);
    800036ec:	854a                	mv	a0,s2
    800036ee:	00001097          	auipc	ra,0x1
    800036f2:	bf6080e7          	jalr	-1034(ra) # 800042e4 <log_write>
  brelse(bp);
    800036f6:	854a                	mv	a0,s2
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	968080e7          	jalr	-1688(ra) # 80003060 <brelse>
}
    80003700:	60e2                	ld	ra,24(sp)
    80003702:	6442                	ld	s0,16(sp)
    80003704:	64a2                	ld	s1,8(sp)
    80003706:	6902                	ld	s2,0(sp)
    80003708:	6105                	addi	sp,sp,32
    8000370a:	8082                	ret

000000008000370c <idup>:
{
    8000370c:	1101                	addi	sp,sp,-32
    8000370e:	ec06                	sd	ra,24(sp)
    80003710:	e822                	sd	s0,16(sp)
    80003712:	e426                	sd	s1,8(sp)
    80003714:	1000                	addi	s0,sp,32
    80003716:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003718:	0001c517          	auipc	a0,0x1c
    8000371c:	9c050513          	addi	a0,a0,-1600 # 8001f0d8 <itable>
    80003720:	ffffd097          	auipc	ra,0xffffd
    80003724:	4ca080e7          	jalr	1226(ra) # 80000bea <acquire>
  ip->ref++;
    80003728:	449c                	lw	a5,8(s1)
    8000372a:	2785                	addiw	a5,a5,1
    8000372c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000372e:	0001c517          	auipc	a0,0x1c
    80003732:	9aa50513          	addi	a0,a0,-1622 # 8001f0d8 <itable>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	568080e7          	jalr	1384(ra) # 80000c9e <release>
}
    8000373e:	8526                	mv	a0,s1
    80003740:	60e2                	ld	ra,24(sp)
    80003742:	6442                	ld	s0,16(sp)
    80003744:	64a2                	ld	s1,8(sp)
    80003746:	6105                	addi	sp,sp,32
    80003748:	8082                	ret

000000008000374a <ilock>:
{
    8000374a:	1101                	addi	sp,sp,-32
    8000374c:	ec06                	sd	ra,24(sp)
    8000374e:	e822                	sd	s0,16(sp)
    80003750:	e426                	sd	s1,8(sp)
    80003752:	e04a                	sd	s2,0(sp)
    80003754:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003756:	c115                	beqz	a0,8000377a <ilock+0x30>
    80003758:	84aa                	mv	s1,a0
    8000375a:	451c                	lw	a5,8(a0)
    8000375c:	00f05f63          	blez	a5,8000377a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003760:	0541                	addi	a0,a0,16
    80003762:	00001097          	auipc	ra,0x1
    80003766:	ca2080e7          	jalr	-862(ra) # 80004404 <acquiresleep>
  if(ip->valid == 0){
    8000376a:	40bc                	lw	a5,64(s1)
    8000376c:	cf99                	beqz	a5,8000378a <ilock+0x40>
}
    8000376e:	60e2                	ld	ra,24(sp)
    80003770:	6442                	ld	s0,16(sp)
    80003772:	64a2                	ld	s1,8(sp)
    80003774:	6902                	ld	s2,0(sp)
    80003776:	6105                	addi	sp,sp,32
    80003778:	8082                	ret
    panic("ilock");
    8000377a:	00005517          	auipc	a0,0x5
    8000377e:	eb650513          	addi	a0,a0,-330 # 80008630 <syscalls+0x188>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	dc2080e7          	jalr	-574(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000378a:	40dc                	lw	a5,4(s1)
    8000378c:	0047d79b          	srliw	a5,a5,0x4
    80003790:	0001c597          	auipc	a1,0x1c
    80003794:	9405a583          	lw	a1,-1728(a1) # 8001f0d0 <sb+0x18>
    80003798:	9dbd                	addw	a1,a1,a5
    8000379a:	4088                	lw	a0,0(s1)
    8000379c:	fffff097          	auipc	ra,0xfffff
    800037a0:	794080e7          	jalr	1940(ra) # 80002f30 <bread>
    800037a4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037a6:	05850593          	addi	a1,a0,88
    800037aa:	40dc                	lw	a5,4(s1)
    800037ac:	8bbd                	andi	a5,a5,15
    800037ae:	079a                	slli	a5,a5,0x6
    800037b0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037b2:	00059783          	lh	a5,0(a1)
    800037b6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037ba:	00259783          	lh	a5,2(a1)
    800037be:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037c2:	00459783          	lh	a5,4(a1)
    800037c6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037ca:	00659783          	lh	a5,6(a1)
    800037ce:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037d2:	459c                	lw	a5,8(a1)
    800037d4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037d6:	03400613          	li	a2,52
    800037da:	05b1                	addi	a1,a1,12
    800037dc:	05048513          	addi	a0,s1,80
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	566080e7          	jalr	1382(ra) # 80000d46 <memmove>
    brelse(bp);
    800037e8:	854a                	mv	a0,s2
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	876080e7          	jalr	-1930(ra) # 80003060 <brelse>
    ip->valid = 1;
    800037f2:	4785                	li	a5,1
    800037f4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037f6:	04449783          	lh	a5,68(s1)
    800037fa:	fbb5                	bnez	a5,8000376e <ilock+0x24>
      panic("ilock: no type");
    800037fc:	00005517          	auipc	a0,0x5
    80003800:	e3c50513          	addi	a0,a0,-452 # 80008638 <syscalls+0x190>
    80003804:	ffffd097          	auipc	ra,0xffffd
    80003808:	d40080e7          	jalr	-704(ra) # 80000544 <panic>

000000008000380c <iunlock>:
{
    8000380c:	1101                	addi	sp,sp,-32
    8000380e:	ec06                	sd	ra,24(sp)
    80003810:	e822                	sd	s0,16(sp)
    80003812:	e426                	sd	s1,8(sp)
    80003814:	e04a                	sd	s2,0(sp)
    80003816:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003818:	c905                	beqz	a0,80003848 <iunlock+0x3c>
    8000381a:	84aa                	mv	s1,a0
    8000381c:	01050913          	addi	s2,a0,16
    80003820:	854a                	mv	a0,s2
    80003822:	00001097          	auipc	ra,0x1
    80003826:	c7c080e7          	jalr	-900(ra) # 8000449e <holdingsleep>
    8000382a:	cd19                	beqz	a0,80003848 <iunlock+0x3c>
    8000382c:	449c                	lw	a5,8(s1)
    8000382e:	00f05d63          	blez	a5,80003848 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003832:	854a                	mv	a0,s2
    80003834:	00001097          	auipc	ra,0x1
    80003838:	c26080e7          	jalr	-986(ra) # 8000445a <releasesleep>
}
    8000383c:	60e2                	ld	ra,24(sp)
    8000383e:	6442                	ld	s0,16(sp)
    80003840:	64a2                	ld	s1,8(sp)
    80003842:	6902                	ld	s2,0(sp)
    80003844:	6105                	addi	sp,sp,32
    80003846:	8082                	ret
    panic("iunlock");
    80003848:	00005517          	auipc	a0,0x5
    8000384c:	e0050513          	addi	a0,a0,-512 # 80008648 <syscalls+0x1a0>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	cf4080e7          	jalr	-780(ra) # 80000544 <panic>

0000000080003858 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003858:	7179                	addi	sp,sp,-48
    8000385a:	f406                	sd	ra,40(sp)
    8000385c:	f022                	sd	s0,32(sp)
    8000385e:	ec26                	sd	s1,24(sp)
    80003860:	e84a                	sd	s2,16(sp)
    80003862:	e44e                	sd	s3,8(sp)
    80003864:	e052                	sd	s4,0(sp)
    80003866:	1800                	addi	s0,sp,48
    80003868:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000386a:	05050493          	addi	s1,a0,80
    8000386e:	08050913          	addi	s2,a0,128
    80003872:	a021                	j	8000387a <itrunc+0x22>
    80003874:	0491                	addi	s1,s1,4
    80003876:	01248d63          	beq	s1,s2,80003890 <itrunc+0x38>
    if(ip->addrs[i]){
    8000387a:	408c                	lw	a1,0(s1)
    8000387c:	dde5                	beqz	a1,80003874 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000387e:	0009a503          	lw	a0,0(s3)
    80003882:	00000097          	auipc	ra,0x0
    80003886:	8f4080e7          	jalr	-1804(ra) # 80003176 <bfree>
      ip->addrs[i] = 0;
    8000388a:	0004a023          	sw	zero,0(s1)
    8000388e:	b7dd                	j	80003874 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003890:	0809a583          	lw	a1,128(s3)
    80003894:	e185                	bnez	a1,800038b4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003896:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000389a:	854e                	mv	a0,s3
    8000389c:	00000097          	auipc	ra,0x0
    800038a0:	de4080e7          	jalr	-540(ra) # 80003680 <iupdate>
}
    800038a4:	70a2                	ld	ra,40(sp)
    800038a6:	7402                	ld	s0,32(sp)
    800038a8:	64e2                	ld	s1,24(sp)
    800038aa:	6942                	ld	s2,16(sp)
    800038ac:	69a2                	ld	s3,8(sp)
    800038ae:	6a02                	ld	s4,0(sp)
    800038b0:	6145                	addi	sp,sp,48
    800038b2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038b4:	0009a503          	lw	a0,0(s3)
    800038b8:	fffff097          	auipc	ra,0xfffff
    800038bc:	678080e7          	jalr	1656(ra) # 80002f30 <bread>
    800038c0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038c2:	05850493          	addi	s1,a0,88
    800038c6:	45850913          	addi	s2,a0,1112
    800038ca:	a811                	j	800038de <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038cc:	0009a503          	lw	a0,0(s3)
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	8a6080e7          	jalr	-1882(ra) # 80003176 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038d8:	0491                	addi	s1,s1,4
    800038da:	01248563          	beq	s1,s2,800038e4 <itrunc+0x8c>
      if(a[j])
    800038de:	408c                	lw	a1,0(s1)
    800038e0:	dde5                	beqz	a1,800038d8 <itrunc+0x80>
    800038e2:	b7ed                	j	800038cc <itrunc+0x74>
    brelse(bp);
    800038e4:	8552                	mv	a0,s4
    800038e6:	fffff097          	auipc	ra,0xfffff
    800038ea:	77a080e7          	jalr	1914(ra) # 80003060 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038ee:	0809a583          	lw	a1,128(s3)
    800038f2:	0009a503          	lw	a0,0(s3)
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	880080e7          	jalr	-1920(ra) # 80003176 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038fe:	0809a023          	sw	zero,128(s3)
    80003902:	bf51                	j	80003896 <itrunc+0x3e>

0000000080003904 <iput>:
{
    80003904:	1101                	addi	sp,sp,-32
    80003906:	ec06                	sd	ra,24(sp)
    80003908:	e822                	sd	s0,16(sp)
    8000390a:	e426                	sd	s1,8(sp)
    8000390c:	e04a                	sd	s2,0(sp)
    8000390e:	1000                	addi	s0,sp,32
    80003910:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003912:	0001b517          	auipc	a0,0x1b
    80003916:	7c650513          	addi	a0,a0,1990 # 8001f0d8 <itable>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	2d0080e7          	jalr	720(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003922:	4498                	lw	a4,8(s1)
    80003924:	4785                	li	a5,1
    80003926:	02f70363          	beq	a4,a5,8000394c <iput+0x48>
  ip->ref--;
    8000392a:	449c                	lw	a5,8(s1)
    8000392c:	37fd                	addiw	a5,a5,-1
    8000392e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003930:	0001b517          	auipc	a0,0x1b
    80003934:	7a850513          	addi	a0,a0,1960 # 8001f0d8 <itable>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	366080e7          	jalr	870(ra) # 80000c9e <release>
}
    80003940:	60e2                	ld	ra,24(sp)
    80003942:	6442                	ld	s0,16(sp)
    80003944:	64a2                	ld	s1,8(sp)
    80003946:	6902                	ld	s2,0(sp)
    80003948:	6105                	addi	sp,sp,32
    8000394a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000394c:	40bc                	lw	a5,64(s1)
    8000394e:	dff1                	beqz	a5,8000392a <iput+0x26>
    80003950:	04a49783          	lh	a5,74(s1)
    80003954:	fbf9                	bnez	a5,8000392a <iput+0x26>
    acquiresleep(&ip->lock);
    80003956:	01048913          	addi	s2,s1,16
    8000395a:	854a                	mv	a0,s2
    8000395c:	00001097          	auipc	ra,0x1
    80003960:	aa8080e7          	jalr	-1368(ra) # 80004404 <acquiresleep>
    release(&itable.lock);
    80003964:	0001b517          	auipc	a0,0x1b
    80003968:	77450513          	addi	a0,a0,1908 # 8001f0d8 <itable>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	332080e7          	jalr	818(ra) # 80000c9e <release>
    itrunc(ip);
    80003974:	8526                	mv	a0,s1
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	ee2080e7          	jalr	-286(ra) # 80003858 <itrunc>
    ip->type = 0;
    8000397e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003982:	8526                	mv	a0,s1
    80003984:	00000097          	auipc	ra,0x0
    80003988:	cfc080e7          	jalr	-772(ra) # 80003680 <iupdate>
    ip->valid = 0;
    8000398c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003990:	854a                	mv	a0,s2
    80003992:	00001097          	auipc	ra,0x1
    80003996:	ac8080e7          	jalr	-1336(ra) # 8000445a <releasesleep>
    acquire(&itable.lock);
    8000399a:	0001b517          	auipc	a0,0x1b
    8000399e:	73e50513          	addi	a0,a0,1854 # 8001f0d8 <itable>
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	248080e7          	jalr	584(ra) # 80000bea <acquire>
    800039aa:	b741                	j	8000392a <iput+0x26>

00000000800039ac <iunlockput>:
{
    800039ac:	1101                	addi	sp,sp,-32
    800039ae:	ec06                	sd	ra,24(sp)
    800039b0:	e822                	sd	s0,16(sp)
    800039b2:	e426                	sd	s1,8(sp)
    800039b4:	1000                	addi	s0,sp,32
    800039b6:	84aa                	mv	s1,a0
  iunlock(ip);
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	e54080e7          	jalr	-428(ra) # 8000380c <iunlock>
  iput(ip);
    800039c0:	8526                	mv	a0,s1
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	f42080e7          	jalr	-190(ra) # 80003904 <iput>
}
    800039ca:	60e2                	ld	ra,24(sp)
    800039cc:	6442                	ld	s0,16(sp)
    800039ce:	64a2                	ld	s1,8(sp)
    800039d0:	6105                	addi	sp,sp,32
    800039d2:	8082                	ret

00000000800039d4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039d4:	1141                	addi	sp,sp,-16
    800039d6:	e422                	sd	s0,8(sp)
    800039d8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039da:	411c                	lw	a5,0(a0)
    800039dc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039de:	415c                	lw	a5,4(a0)
    800039e0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039e2:	04451783          	lh	a5,68(a0)
    800039e6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039ea:	04a51783          	lh	a5,74(a0)
    800039ee:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039f2:	04c56783          	lwu	a5,76(a0)
    800039f6:	e99c                	sd	a5,16(a1)
}
    800039f8:	6422                	ld	s0,8(sp)
    800039fa:	0141                	addi	sp,sp,16
    800039fc:	8082                	ret

00000000800039fe <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039fe:	457c                	lw	a5,76(a0)
    80003a00:	0ed7e963          	bltu	a5,a3,80003af2 <readi+0xf4>
{
    80003a04:	7159                	addi	sp,sp,-112
    80003a06:	f486                	sd	ra,104(sp)
    80003a08:	f0a2                	sd	s0,96(sp)
    80003a0a:	eca6                	sd	s1,88(sp)
    80003a0c:	e8ca                	sd	s2,80(sp)
    80003a0e:	e4ce                	sd	s3,72(sp)
    80003a10:	e0d2                	sd	s4,64(sp)
    80003a12:	fc56                	sd	s5,56(sp)
    80003a14:	f85a                	sd	s6,48(sp)
    80003a16:	f45e                	sd	s7,40(sp)
    80003a18:	f062                	sd	s8,32(sp)
    80003a1a:	ec66                	sd	s9,24(sp)
    80003a1c:	e86a                	sd	s10,16(sp)
    80003a1e:	e46e                	sd	s11,8(sp)
    80003a20:	1880                	addi	s0,sp,112
    80003a22:	8b2a                	mv	s6,a0
    80003a24:	8bae                	mv	s7,a1
    80003a26:	8a32                	mv	s4,a2
    80003a28:	84b6                	mv	s1,a3
    80003a2a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a2c:	9f35                	addw	a4,a4,a3
    return 0;
    80003a2e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a30:	0ad76063          	bltu	a4,a3,80003ad0 <readi+0xd2>
  if(off + n > ip->size)
    80003a34:	00e7f463          	bgeu	a5,a4,80003a3c <readi+0x3e>
    n = ip->size - off;
    80003a38:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a3c:	0a0a8963          	beqz	s5,80003aee <readi+0xf0>
    80003a40:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a42:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a46:	5c7d                	li	s8,-1
    80003a48:	a82d                	j	80003a82 <readi+0x84>
    80003a4a:	020d1d93          	slli	s11,s10,0x20
    80003a4e:	020ddd93          	srli	s11,s11,0x20
    80003a52:	05890613          	addi	a2,s2,88
    80003a56:	86ee                	mv	a3,s11
    80003a58:	963a                	add	a2,a2,a4
    80003a5a:	85d2                	mv	a1,s4
    80003a5c:	855e                	mv	a0,s7
    80003a5e:	fffff097          	auipc	ra,0xfffff
    80003a62:	a14080e7          	jalr	-1516(ra) # 80002472 <either_copyout>
    80003a66:	05850d63          	beq	a0,s8,80003ac0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a6a:	854a                	mv	a0,s2
    80003a6c:	fffff097          	auipc	ra,0xfffff
    80003a70:	5f4080e7          	jalr	1524(ra) # 80003060 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a74:	013d09bb          	addw	s3,s10,s3
    80003a78:	009d04bb          	addw	s1,s10,s1
    80003a7c:	9a6e                	add	s4,s4,s11
    80003a7e:	0559f763          	bgeu	s3,s5,80003acc <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a82:	00a4d59b          	srliw	a1,s1,0xa
    80003a86:	855a                	mv	a0,s6
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	8a2080e7          	jalr	-1886(ra) # 8000332a <bmap>
    80003a90:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a94:	cd85                	beqz	a1,80003acc <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a96:	000b2503          	lw	a0,0(s6)
    80003a9a:	fffff097          	auipc	ra,0xfffff
    80003a9e:	496080e7          	jalr	1174(ra) # 80002f30 <bread>
    80003aa2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa4:	3ff4f713          	andi	a4,s1,1023
    80003aa8:	40ec87bb          	subw	a5,s9,a4
    80003aac:	413a86bb          	subw	a3,s5,s3
    80003ab0:	8d3e                	mv	s10,a5
    80003ab2:	2781                	sext.w	a5,a5
    80003ab4:	0006861b          	sext.w	a2,a3
    80003ab8:	f8f679e3          	bgeu	a2,a5,80003a4a <readi+0x4c>
    80003abc:	8d36                	mv	s10,a3
    80003abe:	b771                	j	80003a4a <readi+0x4c>
      brelse(bp);
    80003ac0:	854a                	mv	a0,s2
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	59e080e7          	jalr	1438(ra) # 80003060 <brelse>
      tot = -1;
    80003aca:	59fd                	li	s3,-1
  }
  return tot;
    80003acc:	0009851b          	sext.w	a0,s3
}
    80003ad0:	70a6                	ld	ra,104(sp)
    80003ad2:	7406                	ld	s0,96(sp)
    80003ad4:	64e6                	ld	s1,88(sp)
    80003ad6:	6946                	ld	s2,80(sp)
    80003ad8:	69a6                	ld	s3,72(sp)
    80003ada:	6a06                	ld	s4,64(sp)
    80003adc:	7ae2                	ld	s5,56(sp)
    80003ade:	7b42                	ld	s6,48(sp)
    80003ae0:	7ba2                	ld	s7,40(sp)
    80003ae2:	7c02                	ld	s8,32(sp)
    80003ae4:	6ce2                	ld	s9,24(sp)
    80003ae6:	6d42                	ld	s10,16(sp)
    80003ae8:	6da2                	ld	s11,8(sp)
    80003aea:	6165                	addi	sp,sp,112
    80003aec:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aee:	89d6                	mv	s3,s5
    80003af0:	bff1                	j	80003acc <readi+0xce>
    return 0;
    80003af2:	4501                	li	a0,0
}
    80003af4:	8082                	ret

0000000080003af6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003af6:	457c                	lw	a5,76(a0)
    80003af8:	10d7e863          	bltu	a5,a3,80003c08 <writei+0x112>
{
    80003afc:	7159                	addi	sp,sp,-112
    80003afe:	f486                	sd	ra,104(sp)
    80003b00:	f0a2                	sd	s0,96(sp)
    80003b02:	eca6                	sd	s1,88(sp)
    80003b04:	e8ca                	sd	s2,80(sp)
    80003b06:	e4ce                	sd	s3,72(sp)
    80003b08:	e0d2                	sd	s4,64(sp)
    80003b0a:	fc56                	sd	s5,56(sp)
    80003b0c:	f85a                	sd	s6,48(sp)
    80003b0e:	f45e                	sd	s7,40(sp)
    80003b10:	f062                	sd	s8,32(sp)
    80003b12:	ec66                	sd	s9,24(sp)
    80003b14:	e86a                	sd	s10,16(sp)
    80003b16:	e46e                	sd	s11,8(sp)
    80003b18:	1880                	addi	s0,sp,112
    80003b1a:	8aaa                	mv	s5,a0
    80003b1c:	8bae                	mv	s7,a1
    80003b1e:	8a32                	mv	s4,a2
    80003b20:	8936                	mv	s2,a3
    80003b22:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b24:	00e687bb          	addw	a5,a3,a4
    80003b28:	0ed7e263          	bltu	a5,a3,80003c0c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b2c:	00043737          	lui	a4,0x43
    80003b30:	0ef76063          	bltu	a4,a5,80003c10 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b34:	0c0b0863          	beqz	s6,80003c04 <writei+0x10e>
    80003b38:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b3a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b3e:	5c7d                	li	s8,-1
    80003b40:	a091                	j	80003b84 <writei+0x8e>
    80003b42:	020d1d93          	slli	s11,s10,0x20
    80003b46:	020ddd93          	srli	s11,s11,0x20
    80003b4a:	05848513          	addi	a0,s1,88
    80003b4e:	86ee                	mv	a3,s11
    80003b50:	8652                	mv	a2,s4
    80003b52:	85de                	mv	a1,s7
    80003b54:	953a                	add	a0,a0,a4
    80003b56:	fffff097          	auipc	ra,0xfffff
    80003b5a:	972080e7          	jalr	-1678(ra) # 800024c8 <either_copyin>
    80003b5e:	07850263          	beq	a0,s8,80003bc2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b62:	8526                	mv	a0,s1
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	780080e7          	jalr	1920(ra) # 800042e4 <log_write>
    brelse(bp);
    80003b6c:	8526                	mv	a0,s1
    80003b6e:	fffff097          	auipc	ra,0xfffff
    80003b72:	4f2080e7          	jalr	1266(ra) # 80003060 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b76:	013d09bb          	addw	s3,s10,s3
    80003b7a:	012d093b          	addw	s2,s10,s2
    80003b7e:	9a6e                	add	s4,s4,s11
    80003b80:	0569f663          	bgeu	s3,s6,80003bcc <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b84:	00a9559b          	srliw	a1,s2,0xa
    80003b88:	8556                	mv	a0,s5
    80003b8a:	fffff097          	auipc	ra,0xfffff
    80003b8e:	7a0080e7          	jalr	1952(ra) # 8000332a <bmap>
    80003b92:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b96:	c99d                	beqz	a1,80003bcc <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b98:	000aa503          	lw	a0,0(s5)
    80003b9c:	fffff097          	auipc	ra,0xfffff
    80003ba0:	394080e7          	jalr	916(ra) # 80002f30 <bread>
    80003ba4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba6:	3ff97713          	andi	a4,s2,1023
    80003baa:	40ec87bb          	subw	a5,s9,a4
    80003bae:	413b06bb          	subw	a3,s6,s3
    80003bb2:	8d3e                	mv	s10,a5
    80003bb4:	2781                	sext.w	a5,a5
    80003bb6:	0006861b          	sext.w	a2,a3
    80003bba:	f8f674e3          	bgeu	a2,a5,80003b42 <writei+0x4c>
    80003bbe:	8d36                	mv	s10,a3
    80003bc0:	b749                	j	80003b42 <writei+0x4c>
      brelse(bp);
    80003bc2:	8526                	mv	a0,s1
    80003bc4:	fffff097          	auipc	ra,0xfffff
    80003bc8:	49c080e7          	jalr	1180(ra) # 80003060 <brelse>
  }

  if(off > ip->size)
    80003bcc:	04caa783          	lw	a5,76(s5)
    80003bd0:	0127f463          	bgeu	a5,s2,80003bd8 <writei+0xe2>
    ip->size = off;
    80003bd4:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bd8:	8556                	mv	a0,s5
    80003bda:	00000097          	auipc	ra,0x0
    80003bde:	aa6080e7          	jalr	-1370(ra) # 80003680 <iupdate>

  return tot;
    80003be2:	0009851b          	sext.w	a0,s3
}
    80003be6:	70a6                	ld	ra,104(sp)
    80003be8:	7406                	ld	s0,96(sp)
    80003bea:	64e6                	ld	s1,88(sp)
    80003bec:	6946                	ld	s2,80(sp)
    80003bee:	69a6                	ld	s3,72(sp)
    80003bf0:	6a06                	ld	s4,64(sp)
    80003bf2:	7ae2                	ld	s5,56(sp)
    80003bf4:	7b42                	ld	s6,48(sp)
    80003bf6:	7ba2                	ld	s7,40(sp)
    80003bf8:	7c02                	ld	s8,32(sp)
    80003bfa:	6ce2                	ld	s9,24(sp)
    80003bfc:	6d42                	ld	s10,16(sp)
    80003bfe:	6da2                	ld	s11,8(sp)
    80003c00:	6165                	addi	sp,sp,112
    80003c02:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c04:	89da                	mv	s3,s6
    80003c06:	bfc9                	j	80003bd8 <writei+0xe2>
    return -1;
    80003c08:	557d                	li	a0,-1
}
    80003c0a:	8082                	ret
    return -1;
    80003c0c:	557d                	li	a0,-1
    80003c0e:	bfe1                	j	80003be6 <writei+0xf0>
    return -1;
    80003c10:	557d                	li	a0,-1
    80003c12:	bfd1                	j	80003be6 <writei+0xf0>

0000000080003c14 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c14:	1141                	addi	sp,sp,-16
    80003c16:	e406                	sd	ra,8(sp)
    80003c18:	e022                	sd	s0,0(sp)
    80003c1a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c1c:	4639                	li	a2,14
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	1a0080e7          	jalr	416(ra) # 80000dbe <strncmp>
}
    80003c26:	60a2                	ld	ra,8(sp)
    80003c28:	6402                	ld	s0,0(sp)
    80003c2a:	0141                	addi	sp,sp,16
    80003c2c:	8082                	ret

0000000080003c2e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c2e:	7139                	addi	sp,sp,-64
    80003c30:	fc06                	sd	ra,56(sp)
    80003c32:	f822                	sd	s0,48(sp)
    80003c34:	f426                	sd	s1,40(sp)
    80003c36:	f04a                	sd	s2,32(sp)
    80003c38:	ec4e                	sd	s3,24(sp)
    80003c3a:	e852                	sd	s4,16(sp)
    80003c3c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c3e:	04451703          	lh	a4,68(a0)
    80003c42:	4785                	li	a5,1
    80003c44:	00f71a63          	bne	a4,a5,80003c58 <dirlookup+0x2a>
    80003c48:	892a                	mv	s2,a0
    80003c4a:	89ae                	mv	s3,a1
    80003c4c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c4e:	457c                	lw	a5,76(a0)
    80003c50:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c52:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c54:	e79d                	bnez	a5,80003c82 <dirlookup+0x54>
    80003c56:	a8a5                	j	80003cce <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c58:	00005517          	auipc	a0,0x5
    80003c5c:	9f850513          	addi	a0,a0,-1544 # 80008650 <syscalls+0x1a8>
    80003c60:	ffffd097          	auipc	ra,0xffffd
    80003c64:	8e4080e7          	jalr	-1820(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003c68:	00005517          	auipc	a0,0x5
    80003c6c:	a0050513          	addi	a0,a0,-1536 # 80008668 <syscalls+0x1c0>
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	8d4080e7          	jalr	-1836(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c78:	24c1                	addiw	s1,s1,16
    80003c7a:	04c92783          	lw	a5,76(s2)
    80003c7e:	04f4f763          	bgeu	s1,a5,80003ccc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c82:	4741                	li	a4,16
    80003c84:	86a6                	mv	a3,s1
    80003c86:	fc040613          	addi	a2,s0,-64
    80003c8a:	4581                	li	a1,0
    80003c8c:	854a                	mv	a0,s2
    80003c8e:	00000097          	auipc	ra,0x0
    80003c92:	d70080e7          	jalr	-656(ra) # 800039fe <readi>
    80003c96:	47c1                	li	a5,16
    80003c98:	fcf518e3          	bne	a0,a5,80003c68 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c9c:	fc045783          	lhu	a5,-64(s0)
    80003ca0:	dfe1                	beqz	a5,80003c78 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ca2:	fc240593          	addi	a1,s0,-62
    80003ca6:	854e                	mv	a0,s3
    80003ca8:	00000097          	auipc	ra,0x0
    80003cac:	f6c080e7          	jalr	-148(ra) # 80003c14 <namecmp>
    80003cb0:	f561                	bnez	a0,80003c78 <dirlookup+0x4a>
      if(poff)
    80003cb2:	000a0463          	beqz	s4,80003cba <dirlookup+0x8c>
        *poff = off;
    80003cb6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cba:	fc045583          	lhu	a1,-64(s0)
    80003cbe:	00092503          	lw	a0,0(s2)
    80003cc2:	fffff097          	auipc	ra,0xfffff
    80003cc6:	750080e7          	jalr	1872(ra) # 80003412 <iget>
    80003cca:	a011                	j	80003cce <dirlookup+0xa0>
  return 0;
    80003ccc:	4501                	li	a0,0
}
    80003cce:	70e2                	ld	ra,56(sp)
    80003cd0:	7442                	ld	s0,48(sp)
    80003cd2:	74a2                	ld	s1,40(sp)
    80003cd4:	7902                	ld	s2,32(sp)
    80003cd6:	69e2                	ld	s3,24(sp)
    80003cd8:	6a42                	ld	s4,16(sp)
    80003cda:	6121                	addi	sp,sp,64
    80003cdc:	8082                	ret

0000000080003cde <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cde:	711d                	addi	sp,sp,-96
    80003ce0:	ec86                	sd	ra,88(sp)
    80003ce2:	e8a2                	sd	s0,80(sp)
    80003ce4:	e4a6                	sd	s1,72(sp)
    80003ce6:	e0ca                	sd	s2,64(sp)
    80003ce8:	fc4e                	sd	s3,56(sp)
    80003cea:	f852                	sd	s4,48(sp)
    80003cec:	f456                	sd	s5,40(sp)
    80003cee:	f05a                	sd	s6,32(sp)
    80003cf0:	ec5e                	sd	s7,24(sp)
    80003cf2:	e862                	sd	s8,16(sp)
    80003cf4:	e466                	sd	s9,8(sp)
    80003cf6:	1080                	addi	s0,sp,96
    80003cf8:	84aa                	mv	s1,a0
    80003cfa:	8b2e                	mv	s6,a1
    80003cfc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cfe:	00054703          	lbu	a4,0(a0)
    80003d02:	02f00793          	li	a5,47
    80003d06:	02f70363          	beq	a4,a5,80003d2c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d0a:	ffffe097          	auipc	ra,0xffffe
    80003d0e:	cbc080e7          	jalr	-836(ra) # 800019c6 <myproc>
    80003d12:	15053503          	ld	a0,336(a0)
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	9f6080e7          	jalr	-1546(ra) # 8000370c <idup>
    80003d1e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d20:	02f00913          	li	s2,47
  len = path - s;
    80003d24:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d26:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d28:	4c05                	li	s8,1
    80003d2a:	a865                	j	80003de2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d2c:	4585                	li	a1,1
    80003d2e:	4505                	li	a0,1
    80003d30:	fffff097          	auipc	ra,0xfffff
    80003d34:	6e2080e7          	jalr	1762(ra) # 80003412 <iget>
    80003d38:	89aa                	mv	s3,a0
    80003d3a:	b7dd                	j	80003d20 <namex+0x42>
      iunlockput(ip);
    80003d3c:	854e                	mv	a0,s3
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	c6e080e7          	jalr	-914(ra) # 800039ac <iunlockput>
      return 0;
    80003d46:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d48:	854e                	mv	a0,s3
    80003d4a:	60e6                	ld	ra,88(sp)
    80003d4c:	6446                	ld	s0,80(sp)
    80003d4e:	64a6                	ld	s1,72(sp)
    80003d50:	6906                	ld	s2,64(sp)
    80003d52:	79e2                	ld	s3,56(sp)
    80003d54:	7a42                	ld	s4,48(sp)
    80003d56:	7aa2                	ld	s5,40(sp)
    80003d58:	7b02                	ld	s6,32(sp)
    80003d5a:	6be2                	ld	s7,24(sp)
    80003d5c:	6c42                	ld	s8,16(sp)
    80003d5e:	6ca2                	ld	s9,8(sp)
    80003d60:	6125                	addi	sp,sp,96
    80003d62:	8082                	ret
      iunlock(ip);
    80003d64:	854e                	mv	a0,s3
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	aa6080e7          	jalr	-1370(ra) # 8000380c <iunlock>
      return ip;
    80003d6e:	bfe9                	j	80003d48 <namex+0x6a>
      iunlockput(ip);
    80003d70:	854e                	mv	a0,s3
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	c3a080e7          	jalr	-966(ra) # 800039ac <iunlockput>
      return 0;
    80003d7a:	89d2                	mv	s3,s4
    80003d7c:	b7f1                	j	80003d48 <namex+0x6a>
  len = path - s;
    80003d7e:	40b48633          	sub	a2,s1,a1
    80003d82:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d86:	094cd463          	bge	s9,s4,80003e0e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d8a:	4639                	li	a2,14
    80003d8c:	8556                	mv	a0,s5
    80003d8e:	ffffd097          	auipc	ra,0xffffd
    80003d92:	fb8080e7          	jalr	-72(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003d96:	0004c783          	lbu	a5,0(s1)
    80003d9a:	01279763          	bne	a5,s2,80003da8 <namex+0xca>
    path++;
    80003d9e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003da0:	0004c783          	lbu	a5,0(s1)
    80003da4:	ff278de3          	beq	a5,s2,80003d9e <namex+0xc0>
    ilock(ip);
    80003da8:	854e                	mv	a0,s3
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	9a0080e7          	jalr	-1632(ra) # 8000374a <ilock>
    if(ip->type != T_DIR){
    80003db2:	04499783          	lh	a5,68(s3)
    80003db6:	f98793e3          	bne	a5,s8,80003d3c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dba:	000b0563          	beqz	s6,80003dc4 <namex+0xe6>
    80003dbe:	0004c783          	lbu	a5,0(s1)
    80003dc2:	d3cd                	beqz	a5,80003d64 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dc4:	865e                	mv	a2,s7
    80003dc6:	85d6                	mv	a1,s5
    80003dc8:	854e                	mv	a0,s3
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	e64080e7          	jalr	-412(ra) # 80003c2e <dirlookup>
    80003dd2:	8a2a                	mv	s4,a0
    80003dd4:	dd51                	beqz	a0,80003d70 <namex+0x92>
    iunlockput(ip);
    80003dd6:	854e                	mv	a0,s3
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	bd4080e7          	jalr	-1068(ra) # 800039ac <iunlockput>
    ip = next;
    80003de0:	89d2                	mv	s3,s4
  while(*path == '/')
    80003de2:	0004c783          	lbu	a5,0(s1)
    80003de6:	05279763          	bne	a5,s2,80003e34 <namex+0x156>
    path++;
    80003dea:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dec:	0004c783          	lbu	a5,0(s1)
    80003df0:	ff278de3          	beq	a5,s2,80003dea <namex+0x10c>
  if(*path == 0)
    80003df4:	c79d                	beqz	a5,80003e22 <namex+0x144>
    path++;
    80003df6:	85a6                	mv	a1,s1
  len = path - s;
    80003df8:	8a5e                	mv	s4,s7
    80003dfa:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dfc:	01278963          	beq	a5,s2,80003e0e <namex+0x130>
    80003e00:	dfbd                	beqz	a5,80003d7e <namex+0xa0>
    path++;
    80003e02:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e04:	0004c783          	lbu	a5,0(s1)
    80003e08:	ff279ce3          	bne	a5,s2,80003e00 <namex+0x122>
    80003e0c:	bf8d                	j	80003d7e <namex+0xa0>
    memmove(name, s, len);
    80003e0e:	2601                	sext.w	a2,a2
    80003e10:	8556                	mv	a0,s5
    80003e12:	ffffd097          	auipc	ra,0xffffd
    80003e16:	f34080e7          	jalr	-204(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003e1a:	9a56                	add	s4,s4,s5
    80003e1c:	000a0023          	sb	zero,0(s4)
    80003e20:	bf9d                	j	80003d96 <namex+0xb8>
  if(nameiparent){
    80003e22:	f20b03e3          	beqz	s6,80003d48 <namex+0x6a>
    iput(ip);
    80003e26:	854e                	mv	a0,s3
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	adc080e7          	jalr	-1316(ra) # 80003904 <iput>
    return 0;
    80003e30:	4981                	li	s3,0
    80003e32:	bf19                	j	80003d48 <namex+0x6a>
  if(*path == 0)
    80003e34:	d7fd                	beqz	a5,80003e22 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e36:	0004c783          	lbu	a5,0(s1)
    80003e3a:	85a6                	mv	a1,s1
    80003e3c:	b7d1                	j	80003e00 <namex+0x122>

0000000080003e3e <dirlink>:
{
    80003e3e:	7139                	addi	sp,sp,-64
    80003e40:	fc06                	sd	ra,56(sp)
    80003e42:	f822                	sd	s0,48(sp)
    80003e44:	f426                	sd	s1,40(sp)
    80003e46:	f04a                	sd	s2,32(sp)
    80003e48:	ec4e                	sd	s3,24(sp)
    80003e4a:	e852                	sd	s4,16(sp)
    80003e4c:	0080                	addi	s0,sp,64
    80003e4e:	892a                	mv	s2,a0
    80003e50:	8a2e                	mv	s4,a1
    80003e52:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e54:	4601                	li	a2,0
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	dd8080e7          	jalr	-552(ra) # 80003c2e <dirlookup>
    80003e5e:	e93d                	bnez	a0,80003ed4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e60:	04c92483          	lw	s1,76(s2)
    80003e64:	c49d                	beqz	s1,80003e92 <dirlink+0x54>
    80003e66:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e68:	4741                	li	a4,16
    80003e6a:	86a6                	mv	a3,s1
    80003e6c:	fc040613          	addi	a2,s0,-64
    80003e70:	4581                	li	a1,0
    80003e72:	854a                	mv	a0,s2
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	b8a080e7          	jalr	-1142(ra) # 800039fe <readi>
    80003e7c:	47c1                	li	a5,16
    80003e7e:	06f51163          	bne	a0,a5,80003ee0 <dirlink+0xa2>
    if(de.inum == 0)
    80003e82:	fc045783          	lhu	a5,-64(s0)
    80003e86:	c791                	beqz	a5,80003e92 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e88:	24c1                	addiw	s1,s1,16
    80003e8a:	04c92783          	lw	a5,76(s2)
    80003e8e:	fcf4ede3          	bltu	s1,a5,80003e68 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e92:	4639                	li	a2,14
    80003e94:	85d2                	mv	a1,s4
    80003e96:	fc240513          	addi	a0,s0,-62
    80003e9a:	ffffd097          	auipc	ra,0xffffd
    80003e9e:	f60080e7          	jalr	-160(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003ea2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea6:	4741                	li	a4,16
    80003ea8:	86a6                	mv	a3,s1
    80003eaa:	fc040613          	addi	a2,s0,-64
    80003eae:	4581                	li	a1,0
    80003eb0:	854a                	mv	a0,s2
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	c44080e7          	jalr	-956(ra) # 80003af6 <writei>
    80003eba:	1541                	addi	a0,a0,-16
    80003ebc:	00a03533          	snez	a0,a0
    80003ec0:	40a00533          	neg	a0,a0
}
    80003ec4:	70e2                	ld	ra,56(sp)
    80003ec6:	7442                	ld	s0,48(sp)
    80003ec8:	74a2                	ld	s1,40(sp)
    80003eca:	7902                	ld	s2,32(sp)
    80003ecc:	69e2                	ld	s3,24(sp)
    80003ece:	6a42                	ld	s4,16(sp)
    80003ed0:	6121                	addi	sp,sp,64
    80003ed2:	8082                	ret
    iput(ip);
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	a30080e7          	jalr	-1488(ra) # 80003904 <iput>
    return -1;
    80003edc:	557d                	li	a0,-1
    80003ede:	b7dd                	j	80003ec4 <dirlink+0x86>
      panic("dirlink read");
    80003ee0:	00004517          	auipc	a0,0x4
    80003ee4:	79850513          	addi	a0,a0,1944 # 80008678 <syscalls+0x1d0>
    80003ee8:	ffffc097          	auipc	ra,0xffffc
    80003eec:	65c080e7          	jalr	1628(ra) # 80000544 <panic>

0000000080003ef0 <namei>:

struct inode*
namei(char *path)
{
    80003ef0:	1101                	addi	sp,sp,-32
    80003ef2:	ec06                	sd	ra,24(sp)
    80003ef4:	e822                	sd	s0,16(sp)
    80003ef6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ef8:	fe040613          	addi	a2,s0,-32
    80003efc:	4581                	li	a1,0
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	de0080e7          	jalr	-544(ra) # 80003cde <namex>
}
    80003f06:	60e2                	ld	ra,24(sp)
    80003f08:	6442                	ld	s0,16(sp)
    80003f0a:	6105                	addi	sp,sp,32
    80003f0c:	8082                	ret

0000000080003f0e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f0e:	1141                	addi	sp,sp,-16
    80003f10:	e406                	sd	ra,8(sp)
    80003f12:	e022                	sd	s0,0(sp)
    80003f14:	0800                	addi	s0,sp,16
    80003f16:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f18:	4585                	li	a1,1
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	dc4080e7          	jalr	-572(ra) # 80003cde <namex>
}
    80003f22:	60a2                	ld	ra,8(sp)
    80003f24:	6402                	ld	s0,0(sp)
    80003f26:	0141                	addi	sp,sp,16
    80003f28:	8082                	ret

0000000080003f2a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f2a:	1101                	addi	sp,sp,-32
    80003f2c:	ec06                	sd	ra,24(sp)
    80003f2e:	e822                	sd	s0,16(sp)
    80003f30:	e426                	sd	s1,8(sp)
    80003f32:	e04a                	sd	s2,0(sp)
    80003f34:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f36:	0001d917          	auipc	s2,0x1d
    80003f3a:	c4a90913          	addi	s2,s2,-950 # 80020b80 <log>
    80003f3e:	01892583          	lw	a1,24(s2)
    80003f42:	02892503          	lw	a0,40(s2)
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	fea080e7          	jalr	-22(ra) # 80002f30 <bread>
    80003f4e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f50:	02c92683          	lw	a3,44(s2)
    80003f54:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f56:	02d05763          	blez	a3,80003f84 <write_head+0x5a>
    80003f5a:	0001d797          	auipc	a5,0x1d
    80003f5e:	c5678793          	addi	a5,a5,-938 # 80020bb0 <log+0x30>
    80003f62:	05c50713          	addi	a4,a0,92
    80003f66:	36fd                	addiw	a3,a3,-1
    80003f68:	1682                	slli	a3,a3,0x20
    80003f6a:	9281                	srli	a3,a3,0x20
    80003f6c:	068a                	slli	a3,a3,0x2
    80003f6e:	0001d617          	auipc	a2,0x1d
    80003f72:	c4660613          	addi	a2,a2,-954 # 80020bb4 <log+0x34>
    80003f76:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f78:	4390                	lw	a2,0(a5)
    80003f7a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f7c:	0791                	addi	a5,a5,4
    80003f7e:	0711                	addi	a4,a4,4
    80003f80:	fed79ce3          	bne	a5,a3,80003f78 <write_head+0x4e>
  }
  bwrite(buf);
    80003f84:	8526                	mv	a0,s1
    80003f86:	fffff097          	auipc	ra,0xfffff
    80003f8a:	09c080e7          	jalr	156(ra) # 80003022 <bwrite>
  brelse(buf);
    80003f8e:	8526                	mv	a0,s1
    80003f90:	fffff097          	auipc	ra,0xfffff
    80003f94:	0d0080e7          	jalr	208(ra) # 80003060 <brelse>
}
    80003f98:	60e2                	ld	ra,24(sp)
    80003f9a:	6442                	ld	s0,16(sp)
    80003f9c:	64a2                	ld	s1,8(sp)
    80003f9e:	6902                	ld	s2,0(sp)
    80003fa0:	6105                	addi	sp,sp,32
    80003fa2:	8082                	ret

0000000080003fa4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fa4:	0001d797          	auipc	a5,0x1d
    80003fa8:	c087a783          	lw	a5,-1016(a5) # 80020bac <log+0x2c>
    80003fac:	0af05d63          	blez	a5,80004066 <install_trans+0xc2>
{
    80003fb0:	7139                	addi	sp,sp,-64
    80003fb2:	fc06                	sd	ra,56(sp)
    80003fb4:	f822                	sd	s0,48(sp)
    80003fb6:	f426                	sd	s1,40(sp)
    80003fb8:	f04a                	sd	s2,32(sp)
    80003fba:	ec4e                	sd	s3,24(sp)
    80003fbc:	e852                	sd	s4,16(sp)
    80003fbe:	e456                	sd	s5,8(sp)
    80003fc0:	e05a                	sd	s6,0(sp)
    80003fc2:	0080                	addi	s0,sp,64
    80003fc4:	8b2a                	mv	s6,a0
    80003fc6:	0001da97          	auipc	s5,0x1d
    80003fca:	beaa8a93          	addi	s5,s5,-1046 # 80020bb0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fce:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fd0:	0001d997          	auipc	s3,0x1d
    80003fd4:	bb098993          	addi	s3,s3,-1104 # 80020b80 <log>
    80003fd8:	a035                	j	80004004 <install_trans+0x60>
      bunpin(dbuf);
    80003fda:	8526                	mv	a0,s1
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	15e080e7          	jalr	350(ra) # 8000313a <bunpin>
    brelse(lbuf);
    80003fe4:	854a                	mv	a0,s2
    80003fe6:	fffff097          	auipc	ra,0xfffff
    80003fea:	07a080e7          	jalr	122(ra) # 80003060 <brelse>
    brelse(dbuf);
    80003fee:	8526                	mv	a0,s1
    80003ff0:	fffff097          	auipc	ra,0xfffff
    80003ff4:	070080e7          	jalr	112(ra) # 80003060 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff8:	2a05                	addiw	s4,s4,1
    80003ffa:	0a91                	addi	s5,s5,4
    80003ffc:	02c9a783          	lw	a5,44(s3)
    80004000:	04fa5963          	bge	s4,a5,80004052 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004004:	0189a583          	lw	a1,24(s3)
    80004008:	014585bb          	addw	a1,a1,s4
    8000400c:	2585                	addiw	a1,a1,1
    8000400e:	0289a503          	lw	a0,40(s3)
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	f1e080e7          	jalr	-226(ra) # 80002f30 <bread>
    8000401a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000401c:	000aa583          	lw	a1,0(s5)
    80004020:	0289a503          	lw	a0,40(s3)
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	f0c080e7          	jalr	-244(ra) # 80002f30 <bread>
    8000402c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000402e:	40000613          	li	a2,1024
    80004032:	05890593          	addi	a1,s2,88
    80004036:	05850513          	addi	a0,a0,88
    8000403a:	ffffd097          	auipc	ra,0xffffd
    8000403e:	d0c080e7          	jalr	-756(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004042:	8526                	mv	a0,s1
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	fde080e7          	jalr	-34(ra) # 80003022 <bwrite>
    if(recovering == 0)
    8000404c:	f80b1ce3          	bnez	s6,80003fe4 <install_trans+0x40>
    80004050:	b769                	j	80003fda <install_trans+0x36>
}
    80004052:	70e2                	ld	ra,56(sp)
    80004054:	7442                	ld	s0,48(sp)
    80004056:	74a2                	ld	s1,40(sp)
    80004058:	7902                	ld	s2,32(sp)
    8000405a:	69e2                	ld	s3,24(sp)
    8000405c:	6a42                	ld	s4,16(sp)
    8000405e:	6aa2                	ld	s5,8(sp)
    80004060:	6b02                	ld	s6,0(sp)
    80004062:	6121                	addi	sp,sp,64
    80004064:	8082                	ret
    80004066:	8082                	ret

0000000080004068 <initlog>:
{
    80004068:	7179                	addi	sp,sp,-48
    8000406a:	f406                	sd	ra,40(sp)
    8000406c:	f022                	sd	s0,32(sp)
    8000406e:	ec26                	sd	s1,24(sp)
    80004070:	e84a                	sd	s2,16(sp)
    80004072:	e44e                	sd	s3,8(sp)
    80004074:	1800                	addi	s0,sp,48
    80004076:	892a                	mv	s2,a0
    80004078:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000407a:	0001d497          	auipc	s1,0x1d
    8000407e:	b0648493          	addi	s1,s1,-1274 # 80020b80 <log>
    80004082:	00004597          	auipc	a1,0x4
    80004086:	60658593          	addi	a1,a1,1542 # 80008688 <syscalls+0x1e0>
    8000408a:	8526                	mv	a0,s1
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	ace080e7          	jalr	-1330(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004094:	0149a583          	lw	a1,20(s3)
    80004098:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000409a:	0109a783          	lw	a5,16(s3)
    8000409e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040a0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040a4:	854a                	mv	a0,s2
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	e8a080e7          	jalr	-374(ra) # 80002f30 <bread>
  log.lh.n = lh->n;
    800040ae:	4d3c                	lw	a5,88(a0)
    800040b0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040b2:	02f05563          	blez	a5,800040dc <initlog+0x74>
    800040b6:	05c50713          	addi	a4,a0,92
    800040ba:	0001d697          	auipc	a3,0x1d
    800040be:	af668693          	addi	a3,a3,-1290 # 80020bb0 <log+0x30>
    800040c2:	37fd                	addiw	a5,a5,-1
    800040c4:	1782                	slli	a5,a5,0x20
    800040c6:	9381                	srli	a5,a5,0x20
    800040c8:	078a                	slli	a5,a5,0x2
    800040ca:	06050613          	addi	a2,a0,96
    800040ce:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040d0:	4310                	lw	a2,0(a4)
    800040d2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040d4:	0711                	addi	a4,a4,4
    800040d6:	0691                	addi	a3,a3,4
    800040d8:	fef71ce3          	bne	a4,a5,800040d0 <initlog+0x68>
  brelse(buf);
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	f84080e7          	jalr	-124(ra) # 80003060 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040e4:	4505                	li	a0,1
    800040e6:	00000097          	auipc	ra,0x0
    800040ea:	ebe080e7          	jalr	-322(ra) # 80003fa4 <install_trans>
  log.lh.n = 0;
    800040ee:	0001d797          	auipc	a5,0x1d
    800040f2:	aa07af23          	sw	zero,-1346(a5) # 80020bac <log+0x2c>
  write_head(); // clear the log
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	e34080e7          	jalr	-460(ra) # 80003f2a <write_head>
}
    800040fe:	70a2                	ld	ra,40(sp)
    80004100:	7402                	ld	s0,32(sp)
    80004102:	64e2                	ld	s1,24(sp)
    80004104:	6942                	ld	s2,16(sp)
    80004106:	69a2                	ld	s3,8(sp)
    80004108:	6145                	addi	sp,sp,48
    8000410a:	8082                	ret

000000008000410c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000410c:	1101                	addi	sp,sp,-32
    8000410e:	ec06                	sd	ra,24(sp)
    80004110:	e822                	sd	s0,16(sp)
    80004112:	e426                	sd	s1,8(sp)
    80004114:	e04a                	sd	s2,0(sp)
    80004116:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004118:	0001d517          	auipc	a0,0x1d
    8000411c:	a6850513          	addi	a0,a0,-1432 # 80020b80 <log>
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	aca080e7          	jalr	-1334(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004128:	0001d497          	auipc	s1,0x1d
    8000412c:	a5848493          	addi	s1,s1,-1448 # 80020b80 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004130:	4979                	li	s2,30
    80004132:	a039                	j	80004140 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004134:	85a6                	mv	a1,s1
    80004136:	8526                	mv	a0,s1
    80004138:	ffffe097          	auipc	ra,0xffffe
    8000413c:	f32080e7          	jalr	-206(ra) # 8000206a <sleep>
    if(log.committing){
    80004140:	50dc                	lw	a5,36(s1)
    80004142:	fbed                	bnez	a5,80004134 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004144:	509c                	lw	a5,32(s1)
    80004146:	0017871b          	addiw	a4,a5,1
    8000414a:	0007069b          	sext.w	a3,a4
    8000414e:	0027179b          	slliw	a5,a4,0x2
    80004152:	9fb9                	addw	a5,a5,a4
    80004154:	0017979b          	slliw	a5,a5,0x1
    80004158:	54d8                	lw	a4,44(s1)
    8000415a:	9fb9                	addw	a5,a5,a4
    8000415c:	00f95963          	bge	s2,a5,8000416e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004160:	85a6                	mv	a1,s1
    80004162:	8526                	mv	a0,s1
    80004164:	ffffe097          	auipc	ra,0xffffe
    80004168:	f06080e7          	jalr	-250(ra) # 8000206a <sleep>
    8000416c:	bfd1                	j	80004140 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000416e:	0001d517          	auipc	a0,0x1d
    80004172:	a1250513          	addi	a0,a0,-1518 # 80020b80 <log>
    80004176:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004178:	ffffd097          	auipc	ra,0xffffd
    8000417c:	b26080e7          	jalr	-1242(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004180:	60e2                	ld	ra,24(sp)
    80004182:	6442                	ld	s0,16(sp)
    80004184:	64a2                	ld	s1,8(sp)
    80004186:	6902                	ld	s2,0(sp)
    80004188:	6105                	addi	sp,sp,32
    8000418a:	8082                	ret

000000008000418c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000418c:	7139                	addi	sp,sp,-64
    8000418e:	fc06                	sd	ra,56(sp)
    80004190:	f822                	sd	s0,48(sp)
    80004192:	f426                	sd	s1,40(sp)
    80004194:	f04a                	sd	s2,32(sp)
    80004196:	ec4e                	sd	s3,24(sp)
    80004198:	e852                	sd	s4,16(sp)
    8000419a:	e456                	sd	s5,8(sp)
    8000419c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000419e:	0001d497          	auipc	s1,0x1d
    800041a2:	9e248493          	addi	s1,s1,-1566 # 80020b80 <log>
    800041a6:	8526                	mv	a0,s1
    800041a8:	ffffd097          	auipc	ra,0xffffd
    800041ac:	a42080e7          	jalr	-1470(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    800041b0:	509c                	lw	a5,32(s1)
    800041b2:	37fd                	addiw	a5,a5,-1
    800041b4:	0007891b          	sext.w	s2,a5
    800041b8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041ba:	50dc                	lw	a5,36(s1)
    800041bc:	efb9                	bnez	a5,8000421a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041be:	06091663          	bnez	s2,8000422a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041c2:	0001d497          	auipc	s1,0x1d
    800041c6:	9be48493          	addi	s1,s1,-1602 # 80020b80 <log>
    800041ca:	4785                	li	a5,1
    800041cc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	ace080e7          	jalr	-1330(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041d8:	54dc                	lw	a5,44(s1)
    800041da:	06f04763          	bgtz	a5,80004248 <end_op+0xbc>
    acquire(&log.lock);
    800041de:	0001d497          	auipc	s1,0x1d
    800041e2:	9a248493          	addi	s1,s1,-1630 # 80020b80 <log>
    800041e6:	8526                	mv	a0,s1
    800041e8:	ffffd097          	auipc	ra,0xffffd
    800041ec:	a02080e7          	jalr	-1534(ra) # 80000bea <acquire>
    log.committing = 0;
    800041f0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041f4:	8526                	mv	a0,s1
    800041f6:	ffffe097          	auipc	ra,0xffffe
    800041fa:	ed8080e7          	jalr	-296(ra) # 800020ce <wakeup>
    release(&log.lock);
    800041fe:	8526                	mv	a0,s1
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	a9e080e7          	jalr	-1378(ra) # 80000c9e <release>
}
    80004208:	70e2                	ld	ra,56(sp)
    8000420a:	7442                	ld	s0,48(sp)
    8000420c:	74a2                	ld	s1,40(sp)
    8000420e:	7902                	ld	s2,32(sp)
    80004210:	69e2                	ld	s3,24(sp)
    80004212:	6a42                	ld	s4,16(sp)
    80004214:	6aa2                	ld	s5,8(sp)
    80004216:	6121                	addi	sp,sp,64
    80004218:	8082                	ret
    panic("log.committing");
    8000421a:	00004517          	auipc	a0,0x4
    8000421e:	47650513          	addi	a0,a0,1142 # 80008690 <syscalls+0x1e8>
    80004222:	ffffc097          	auipc	ra,0xffffc
    80004226:	322080e7          	jalr	802(ra) # 80000544 <panic>
    wakeup(&log);
    8000422a:	0001d497          	auipc	s1,0x1d
    8000422e:	95648493          	addi	s1,s1,-1706 # 80020b80 <log>
    80004232:	8526                	mv	a0,s1
    80004234:	ffffe097          	auipc	ra,0xffffe
    80004238:	e9a080e7          	jalr	-358(ra) # 800020ce <wakeup>
  release(&log.lock);
    8000423c:	8526                	mv	a0,s1
    8000423e:	ffffd097          	auipc	ra,0xffffd
    80004242:	a60080e7          	jalr	-1440(ra) # 80000c9e <release>
  if(do_commit){
    80004246:	b7c9                	j	80004208 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004248:	0001da97          	auipc	s5,0x1d
    8000424c:	968a8a93          	addi	s5,s5,-1688 # 80020bb0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004250:	0001da17          	auipc	s4,0x1d
    80004254:	930a0a13          	addi	s4,s4,-1744 # 80020b80 <log>
    80004258:	018a2583          	lw	a1,24(s4)
    8000425c:	012585bb          	addw	a1,a1,s2
    80004260:	2585                	addiw	a1,a1,1
    80004262:	028a2503          	lw	a0,40(s4)
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	cca080e7          	jalr	-822(ra) # 80002f30 <bread>
    8000426e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004270:	000aa583          	lw	a1,0(s5)
    80004274:	028a2503          	lw	a0,40(s4)
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	cb8080e7          	jalr	-840(ra) # 80002f30 <bread>
    80004280:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004282:	40000613          	li	a2,1024
    80004286:	05850593          	addi	a1,a0,88
    8000428a:	05848513          	addi	a0,s1,88
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	ab8080e7          	jalr	-1352(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004296:	8526                	mv	a0,s1
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	d8a080e7          	jalr	-630(ra) # 80003022 <bwrite>
    brelse(from);
    800042a0:	854e                	mv	a0,s3
    800042a2:	fffff097          	auipc	ra,0xfffff
    800042a6:	dbe080e7          	jalr	-578(ra) # 80003060 <brelse>
    brelse(to);
    800042aa:	8526                	mv	a0,s1
    800042ac:	fffff097          	auipc	ra,0xfffff
    800042b0:	db4080e7          	jalr	-588(ra) # 80003060 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b4:	2905                	addiw	s2,s2,1
    800042b6:	0a91                	addi	s5,s5,4
    800042b8:	02ca2783          	lw	a5,44(s4)
    800042bc:	f8f94ee3          	blt	s2,a5,80004258 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	c6a080e7          	jalr	-918(ra) # 80003f2a <write_head>
    install_trans(0); // Now install writes to home locations
    800042c8:	4501                	li	a0,0
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	cda080e7          	jalr	-806(ra) # 80003fa4 <install_trans>
    log.lh.n = 0;
    800042d2:	0001d797          	auipc	a5,0x1d
    800042d6:	8c07ad23          	sw	zero,-1830(a5) # 80020bac <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042da:	00000097          	auipc	ra,0x0
    800042de:	c50080e7          	jalr	-944(ra) # 80003f2a <write_head>
    800042e2:	bdf5                	j	800041de <end_op+0x52>

00000000800042e4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042e4:	1101                	addi	sp,sp,-32
    800042e6:	ec06                	sd	ra,24(sp)
    800042e8:	e822                	sd	s0,16(sp)
    800042ea:	e426                	sd	s1,8(sp)
    800042ec:	e04a                	sd	s2,0(sp)
    800042ee:	1000                	addi	s0,sp,32
    800042f0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042f2:	0001d917          	auipc	s2,0x1d
    800042f6:	88e90913          	addi	s2,s2,-1906 # 80020b80 <log>
    800042fa:	854a                	mv	a0,s2
    800042fc:	ffffd097          	auipc	ra,0xffffd
    80004300:	8ee080e7          	jalr	-1810(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004304:	02c92603          	lw	a2,44(s2)
    80004308:	47f5                	li	a5,29
    8000430a:	06c7c563          	blt	a5,a2,80004374 <log_write+0x90>
    8000430e:	0001d797          	auipc	a5,0x1d
    80004312:	88e7a783          	lw	a5,-1906(a5) # 80020b9c <log+0x1c>
    80004316:	37fd                	addiw	a5,a5,-1
    80004318:	04f65e63          	bge	a2,a5,80004374 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000431c:	0001d797          	auipc	a5,0x1d
    80004320:	8847a783          	lw	a5,-1916(a5) # 80020ba0 <log+0x20>
    80004324:	06f05063          	blez	a5,80004384 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004328:	4781                	li	a5,0
    8000432a:	06c05563          	blez	a2,80004394 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000432e:	44cc                	lw	a1,12(s1)
    80004330:	0001d717          	auipc	a4,0x1d
    80004334:	88070713          	addi	a4,a4,-1920 # 80020bb0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004338:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000433a:	4314                	lw	a3,0(a4)
    8000433c:	04b68c63          	beq	a3,a1,80004394 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004340:	2785                	addiw	a5,a5,1
    80004342:	0711                	addi	a4,a4,4
    80004344:	fef61be3          	bne	a2,a5,8000433a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004348:	0621                	addi	a2,a2,8
    8000434a:	060a                	slli	a2,a2,0x2
    8000434c:	0001d797          	auipc	a5,0x1d
    80004350:	83478793          	addi	a5,a5,-1996 # 80020b80 <log>
    80004354:	963e                	add	a2,a2,a5
    80004356:	44dc                	lw	a5,12(s1)
    80004358:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000435a:	8526                	mv	a0,s1
    8000435c:	fffff097          	auipc	ra,0xfffff
    80004360:	da2080e7          	jalr	-606(ra) # 800030fe <bpin>
    log.lh.n++;
    80004364:	0001d717          	auipc	a4,0x1d
    80004368:	81c70713          	addi	a4,a4,-2020 # 80020b80 <log>
    8000436c:	575c                	lw	a5,44(a4)
    8000436e:	2785                	addiw	a5,a5,1
    80004370:	d75c                	sw	a5,44(a4)
    80004372:	a835                	j	800043ae <log_write+0xca>
    panic("too big a transaction");
    80004374:	00004517          	auipc	a0,0x4
    80004378:	32c50513          	addi	a0,a0,812 # 800086a0 <syscalls+0x1f8>
    8000437c:	ffffc097          	auipc	ra,0xffffc
    80004380:	1c8080e7          	jalr	456(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004384:	00004517          	auipc	a0,0x4
    80004388:	33450513          	addi	a0,a0,820 # 800086b8 <syscalls+0x210>
    8000438c:	ffffc097          	auipc	ra,0xffffc
    80004390:	1b8080e7          	jalr	440(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004394:	00878713          	addi	a4,a5,8
    80004398:	00271693          	slli	a3,a4,0x2
    8000439c:	0001c717          	auipc	a4,0x1c
    800043a0:	7e470713          	addi	a4,a4,2020 # 80020b80 <log>
    800043a4:	9736                	add	a4,a4,a3
    800043a6:	44d4                	lw	a3,12(s1)
    800043a8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043aa:	faf608e3          	beq	a2,a5,8000435a <log_write+0x76>
  }
  release(&log.lock);
    800043ae:	0001c517          	auipc	a0,0x1c
    800043b2:	7d250513          	addi	a0,a0,2002 # 80020b80 <log>
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	8e8080e7          	jalr	-1816(ra) # 80000c9e <release>
}
    800043be:	60e2                	ld	ra,24(sp)
    800043c0:	6442                	ld	s0,16(sp)
    800043c2:	64a2                	ld	s1,8(sp)
    800043c4:	6902                	ld	s2,0(sp)
    800043c6:	6105                	addi	sp,sp,32
    800043c8:	8082                	ret

00000000800043ca <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043ca:	1101                	addi	sp,sp,-32
    800043cc:	ec06                	sd	ra,24(sp)
    800043ce:	e822                	sd	s0,16(sp)
    800043d0:	e426                	sd	s1,8(sp)
    800043d2:	e04a                	sd	s2,0(sp)
    800043d4:	1000                	addi	s0,sp,32
    800043d6:	84aa                	mv	s1,a0
    800043d8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043da:	00004597          	auipc	a1,0x4
    800043de:	2fe58593          	addi	a1,a1,766 # 800086d8 <syscalls+0x230>
    800043e2:	0521                	addi	a0,a0,8
    800043e4:	ffffc097          	auipc	ra,0xffffc
    800043e8:	776080e7          	jalr	1910(ra) # 80000b5a <initlock>
  lk->name = name;
    800043ec:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043f0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043f4:	0204a423          	sw	zero,40(s1)
}
    800043f8:	60e2                	ld	ra,24(sp)
    800043fa:	6442                	ld	s0,16(sp)
    800043fc:	64a2                	ld	s1,8(sp)
    800043fe:	6902                	ld	s2,0(sp)
    80004400:	6105                	addi	sp,sp,32
    80004402:	8082                	ret

0000000080004404 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004404:	1101                	addi	sp,sp,-32
    80004406:	ec06                	sd	ra,24(sp)
    80004408:	e822                	sd	s0,16(sp)
    8000440a:	e426                	sd	s1,8(sp)
    8000440c:	e04a                	sd	s2,0(sp)
    8000440e:	1000                	addi	s0,sp,32
    80004410:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004412:	00850913          	addi	s2,a0,8
    80004416:	854a                	mv	a0,s2
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	7d2080e7          	jalr	2002(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004420:	409c                	lw	a5,0(s1)
    80004422:	cb89                	beqz	a5,80004434 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004424:	85ca                	mv	a1,s2
    80004426:	8526                	mv	a0,s1
    80004428:	ffffe097          	auipc	ra,0xffffe
    8000442c:	c42080e7          	jalr	-958(ra) # 8000206a <sleep>
  while (lk->locked) {
    80004430:	409c                	lw	a5,0(s1)
    80004432:	fbed                	bnez	a5,80004424 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004434:	4785                	li	a5,1
    80004436:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004438:	ffffd097          	auipc	ra,0xffffd
    8000443c:	58e080e7          	jalr	1422(ra) # 800019c6 <myproc>
    80004440:	591c                	lw	a5,48(a0)
    80004442:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004444:	854a                	mv	a0,s2
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	858080e7          	jalr	-1960(ra) # 80000c9e <release>
}
    8000444e:	60e2                	ld	ra,24(sp)
    80004450:	6442                	ld	s0,16(sp)
    80004452:	64a2                	ld	s1,8(sp)
    80004454:	6902                	ld	s2,0(sp)
    80004456:	6105                	addi	sp,sp,32
    80004458:	8082                	ret

000000008000445a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000445a:	1101                	addi	sp,sp,-32
    8000445c:	ec06                	sd	ra,24(sp)
    8000445e:	e822                	sd	s0,16(sp)
    80004460:	e426                	sd	s1,8(sp)
    80004462:	e04a                	sd	s2,0(sp)
    80004464:	1000                	addi	s0,sp,32
    80004466:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004468:	00850913          	addi	s2,a0,8
    8000446c:	854a                	mv	a0,s2
    8000446e:	ffffc097          	auipc	ra,0xffffc
    80004472:	77c080e7          	jalr	1916(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004476:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000447a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000447e:	8526                	mv	a0,s1
    80004480:	ffffe097          	auipc	ra,0xffffe
    80004484:	c4e080e7          	jalr	-946(ra) # 800020ce <wakeup>
  release(&lk->lk);
    80004488:	854a                	mv	a0,s2
    8000448a:	ffffd097          	auipc	ra,0xffffd
    8000448e:	814080e7          	jalr	-2028(ra) # 80000c9e <release>
}
    80004492:	60e2                	ld	ra,24(sp)
    80004494:	6442                	ld	s0,16(sp)
    80004496:	64a2                	ld	s1,8(sp)
    80004498:	6902                	ld	s2,0(sp)
    8000449a:	6105                	addi	sp,sp,32
    8000449c:	8082                	ret

000000008000449e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000449e:	7179                	addi	sp,sp,-48
    800044a0:	f406                	sd	ra,40(sp)
    800044a2:	f022                	sd	s0,32(sp)
    800044a4:	ec26                	sd	s1,24(sp)
    800044a6:	e84a                	sd	s2,16(sp)
    800044a8:	e44e                	sd	s3,8(sp)
    800044aa:	1800                	addi	s0,sp,48
    800044ac:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044ae:	00850913          	addi	s2,a0,8
    800044b2:	854a                	mv	a0,s2
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	736080e7          	jalr	1846(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044bc:	409c                	lw	a5,0(s1)
    800044be:	ef99                	bnez	a5,800044dc <holdingsleep+0x3e>
    800044c0:	4481                	li	s1,0
  release(&lk->lk);
    800044c2:	854a                	mv	a0,s2
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	7da080e7          	jalr	2010(ra) # 80000c9e <release>
  return r;
}
    800044cc:	8526                	mv	a0,s1
    800044ce:	70a2                	ld	ra,40(sp)
    800044d0:	7402                	ld	s0,32(sp)
    800044d2:	64e2                	ld	s1,24(sp)
    800044d4:	6942                	ld	s2,16(sp)
    800044d6:	69a2                	ld	s3,8(sp)
    800044d8:	6145                	addi	sp,sp,48
    800044da:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044dc:	0284a983          	lw	s3,40(s1)
    800044e0:	ffffd097          	auipc	ra,0xffffd
    800044e4:	4e6080e7          	jalr	1254(ra) # 800019c6 <myproc>
    800044e8:	5904                	lw	s1,48(a0)
    800044ea:	413484b3          	sub	s1,s1,s3
    800044ee:	0014b493          	seqz	s1,s1
    800044f2:	bfc1                	j	800044c2 <holdingsleep+0x24>

00000000800044f4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044f4:	1141                	addi	sp,sp,-16
    800044f6:	e406                	sd	ra,8(sp)
    800044f8:	e022                	sd	s0,0(sp)
    800044fa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044fc:	00004597          	auipc	a1,0x4
    80004500:	1ec58593          	addi	a1,a1,492 # 800086e8 <syscalls+0x240>
    80004504:	0001c517          	auipc	a0,0x1c
    80004508:	7c450513          	addi	a0,a0,1988 # 80020cc8 <ftable>
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	64e080e7          	jalr	1614(ra) # 80000b5a <initlock>
}
    80004514:	60a2                	ld	ra,8(sp)
    80004516:	6402                	ld	s0,0(sp)
    80004518:	0141                	addi	sp,sp,16
    8000451a:	8082                	ret

000000008000451c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000451c:	1101                	addi	sp,sp,-32
    8000451e:	ec06                	sd	ra,24(sp)
    80004520:	e822                	sd	s0,16(sp)
    80004522:	e426                	sd	s1,8(sp)
    80004524:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004526:	0001c517          	auipc	a0,0x1c
    8000452a:	7a250513          	addi	a0,a0,1954 # 80020cc8 <ftable>
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	6bc080e7          	jalr	1724(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004536:	0001c497          	auipc	s1,0x1c
    8000453a:	7aa48493          	addi	s1,s1,1962 # 80020ce0 <ftable+0x18>
    8000453e:	0001d717          	auipc	a4,0x1d
    80004542:	74270713          	addi	a4,a4,1858 # 80021c80 <disk>
    if(f->ref == 0){
    80004546:	40dc                	lw	a5,4(s1)
    80004548:	cf99                	beqz	a5,80004566 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000454a:	02848493          	addi	s1,s1,40
    8000454e:	fee49ce3          	bne	s1,a4,80004546 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004552:	0001c517          	auipc	a0,0x1c
    80004556:	77650513          	addi	a0,a0,1910 # 80020cc8 <ftable>
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	744080e7          	jalr	1860(ra) # 80000c9e <release>
  return 0;
    80004562:	4481                	li	s1,0
    80004564:	a819                	j	8000457a <filealloc+0x5e>
      f->ref = 1;
    80004566:	4785                	li	a5,1
    80004568:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000456a:	0001c517          	auipc	a0,0x1c
    8000456e:	75e50513          	addi	a0,a0,1886 # 80020cc8 <ftable>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	72c080e7          	jalr	1836(ra) # 80000c9e <release>
}
    8000457a:	8526                	mv	a0,s1
    8000457c:	60e2                	ld	ra,24(sp)
    8000457e:	6442                	ld	s0,16(sp)
    80004580:	64a2                	ld	s1,8(sp)
    80004582:	6105                	addi	sp,sp,32
    80004584:	8082                	ret

0000000080004586 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004586:	1101                	addi	sp,sp,-32
    80004588:	ec06                	sd	ra,24(sp)
    8000458a:	e822                	sd	s0,16(sp)
    8000458c:	e426                	sd	s1,8(sp)
    8000458e:	1000                	addi	s0,sp,32
    80004590:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004592:	0001c517          	auipc	a0,0x1c
    80004596:	73650513          	addi	a0,a0,1846 # 80020cc8 <ftable>
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	650080e7          	jalr	1616(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800045a2:	40dc                	lw	a5,4(s1)
    800045a4:	02f05263          	blez	a5,800045c8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045a8:	2785                	addiw	a5,a5,1
    800045aa:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045ac:	0001c517          	auipc	a0,0x1c
    800045b0:	71c50513          	addi	a0,a0,1820 # 80020cc8 <ftable>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	6ea080e7          	jalr	1770(ra) # 80000c9e <release>
  return f;
}
    800045bc:	8526                	mv	a0,s1
    800045be:	60e2                	ld	ra,24(sp)
    800045c0:	6442                	ld	s0,16(sp)
    800045c2:	64a2                	ld	s1,8(sp)
    800045c4:	6105                	addi	sp,sp,32
    800045c6:	8082                	ret
    panic("filedup");
    800045c8:	00004517          	auipc	a0,0x4
    800045cc:	12850513          	addi	a0,a0,296 # 800086f0 <syscalls+0x248>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	f74080e7          	jalr	-140(ra) # 80000544 <panic>

00000000800045d8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045d8:	7139                	addi	sp,sp,-64
    800045da:	fc06                	sd	ra,56(sp)
    800045dc:	f822                	sd	s0,48(sp)
    800045de:	f426                	sd	s1,40(sp)
    800045e0:	f04a                	sd	s2,32(sp)
    800045e2:	ec4e                	sd	s3,24(sp)
    800045e4:	e852                	sd	s4,16(sp)
    800045e6:	e456                	sd	s5,8(sp)
    800045e8:	0080                	addi	s0,sp,64
    800045ea:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045ec:	0001c517          	auipc	a0,0x1c
    800045f0:	6dc50513          	addi	a0,a0,1756 # 80020cc8 <ftable>
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	5f6080e7          	jalr	1526(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800045fc:	40dc                	lw	a5,4(s1)
    800045fe:	06f05163          	blez	a5,80004660 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004602:	37fd                	addiw	a5,a5,-1
    80004604:	0007871b          	sext.w	a4,a5
    80004608:	c0dc                	sw	a5,4(s1)
    8000460a:	06e04363          	bgtz	a4,80004670 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000460e:	0004a903          	lw	s2,0(s1)
    80004612:	0094ca83          	lbu	s5,9(s1)
    80004616:	0104ba03          	ld	s4,16(s1)
    8000461a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000461e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004622:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004626:	0001c517          	auipc	a0,0x1c
    8000462a:	6a250513          	addi	a0,a0,1698 # 80020cc8 <ftable>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	670080e7          	jalr	1648(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004636:	4785                	li	a5,1
    80004638:	04f90d63          	beq	s2,a5,80004692 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000463c:	3979                	addiw	s2,s2,-2
    8000463e:	4785                	li	a5,1
    80004640:	0527e063          	bltu	a5,s2,80004680 <fileclose+0xa8>
    begin_op();
    80004644:	00000097          	auipc	ra,0x0
    80004648:	ac8080e7          	jalr	-1336(ra) # 8000410c <begin_op>
    iput(ff.ip);
    8000464c:	854e                	mv	a0,s3
    8000464e:	fffff097          	auipc	ra,0xfffff
    80004652:	2b6080e7          	jalr	694(ra) # 80003904 <iput>
    end_op();
    80004656:	00000097          	auipc	ra,0x0
    8000465a:	b36080e7          	jalr	-1226(ra) # 8000418c <end_op>
    8000465e:	a00d                	j	80004680 <fileclose+0xa8>
    panic("fileclose");
    80004660:	00004517          	auipc	a0,0x4
    80004664:	09850513          	addi	a0,a0,152 # 800086f8 <syscalls+0x250>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	edc080e7          	jalr	-292(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004670:	0001c517          	auipc	a0,0x1c
    80004674:	65850513          	addi	a0,a0,1624 # 80020cc8 <ftable>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	626080e7          	jalr	1574(ra) # 80000c9e <release>
  }
}
    80004680:	70e2                	ld	ra,56(sp)
    80004682:	7442                	ld	s0,48(sp)
    80004684:	74a2                	ld	s1,40(sp)
    80004686:	7902                	ld	s2,32(sp)
    80004688:	69e2                	ld	s3,24(sp)
    8000468a:	6a42                	ld	s4,16(sp)
    8000468c:	6aa2                	ld	s5,8(sp)
    8000468e:	6121                	addi	sp,sp,64
    80004690:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004692:	85d6                	mv	a1,s5
    80004694:	8552                	mv	a0,s4
    80004696:	00000097          	auipc	ra,0x0
    8000469a:	34c080e7          	jalr	844(ra) # 800049e2 <pipeclose>
    8000469e:	b7cd                	j	80004680 <fileclose+0xa8>

00000000800046a0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046a0:	715d                	addi	sp,sp,-80
    800046a2:	e486                	sd	ra,72(sp)
    800046a4:	e0a2                	sd	s0,64(sp)
    800046a6:	fc26                	sd	s1,56(sp)
    800046a8:	f84a                	sd	s2,48(sp)
    800046aa:	f44e                	sd	s3,40(sp)
    800046ac:	0880                	addi	s0,sp,80
    800046ae:	84aa                	mv	s1,a0
    800046b0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046b2:	ffffd097          	auipc	ra,0xffffd
    800046b6:	314080e7          	jalr	788(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046ba:	409c                	lw	a5,0(s1)
    800046bc:	37f9                	addiw	a5,a5,-2
    800046be:	4705                	li	a4,1
    800046c0:	04f76763          	bltu	a4,a5,8000470e <filestat+0x6e>
    800046c4:	892a                	mv	s2,a0
    ilock(f->ip);
    800046c6:	6c88                	ld	a0,24(s1)
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	082080e7          	jalr	130(ra) # 8000374a <ilock>
    stati(f->ip, &st);
    800046d0:	fb840593          	addi	a1,s0,-72
    800046d4:	6c88                	ld	a0,24(s1)
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	2fe080e7          	jalr	766(ra) # 800039d4 <stati>
    iunlock(f->ip);
    800046de:	6c88                	ld	a0,24(s1)
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	12c080e7          	jalr	300(ra) # 8000380c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046e8:	46e1                	li	a3,24
    800046ea:	fb840613          	addi	a2,s0,-72
    800046ee:	85ce                	mv	a1,s3
    800046f0:	05093503          	ld	a0,80(s2)
    800046f4:	ffffd097          	auipc	ra,0xffffd
    800046f8:	f90080e7          	jalr	-112(ra) # 80001684 <copyout>
    800046fc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004700:	60a6                	ld	ra,72(sp)
    80004702:	6406                	ld	s0,64(sp)
    80004704:	74e2                	ld	s1,56(sp)
    80004706:	7942                	ld	s2,48(sp)
    80004708:	79a2                	ld	s3,40(sp)
    8000470a:	6161                	addi	sp,sp,80
    8000470c:	8082                	ret
  return -1;
    8000470e:	557d                	li	a0,-1
    80004710:	bfc5                	j	80004700 <filestat+0x60>

0000000080004712 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004712:	7179                	addi	sp,sp,-48
    80004714:	f406                	sd	ra,40(sp)
    80004716:	f022                	sd	s0,32(sp)
    80004718:	ec26                	sd	s1,24(sp)
    8000471a:	e84a                	sd	s2,16(sp)
    8000471c:	e44e                	sd	s3,8(sp)
    8000471e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004720:	00854783          	lbu	a5,8(a0)
    80004724:	c3d5                	beqz	a5,800047c8 <fileread+0xb6>
    80004726:	84aa                	mv	s1,a0
    80004728:	89ae                	mv	s3,a1
    8000472a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000472c:	411c                	lw	a5,0(a0)
    8000472e:	4705                	li	a4,1
    80004730:	04e78963          	beq	a5,a4,80004782 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004734:	470d                	li	a4,3
    80004736:	04e78d63          	beq	a5,a4,80004790 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000473a:	4709                	li	a4,2
    8000473c:	06e79e63          	bne	a5,a4,800047b8 <fileread+0xa6>
    ilock(f->ip);
    80004740:	6d08                	ld	a0,24(a0)
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	008080e7          	jalr	8(ra) # 8000374a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000474a:	874a                	mv	a4,s2
    8000474c:	5094                	lw	a3,32(s1)
    8000474e:	864e                	mv	a2,s3
    80004750:	4585                	li	a1,1
    80004752:	6c88                	ld	a0,24(s1)
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	2aa080e7          	jalr	682(ra) # 800039fe <readi>
    8000475c:	892a                	mv	s2,a0
    8000475e:	00a05563          	blez	a0,80004768 <fileread+0x56>
      f->off += r;
    80004762:	509c                	lw	a5,32(s1)
    80004764:	9fa9                	addw	a5,a5,a0
    80004766:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004768:	6c88                	ld	a0,24(s1)
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	0a2080e7          	jalr	162(ra) # 8000380c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004772:	854a                	mv	a0,s2
    80004774:	70a2                	ld	ra,40(sp)
    80004776:	7402                	ld	s0,32(sp)
    80004778:	64e2                	ld	s1,24(sp)
    8000477a:	6942                	ld	s2,16(sp)
    8000477c:	69a2                	ld	s3,8(sp)
    8000477e:	6145                	addi	sp,sp,48
    80004780:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004782:	6908                	ld	a0,16(a0)
    80004784:	00000097          	auipc	ra,0x0
    80004788:	3ce080e7          	jalr	974(ra) # 80004b52 <piperead>
    8000478c:	892a                	mv	s2,a0
    8000478e:	b7d5                	j	80004772 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004790:	02451783          	lh	a5,36(a0)
    80004794:	03079693          	slli	a3,a5,0x30
    80004798:	92c1                	srli	a3,a3,0x30
    8000479a:	4725                	li	a4,9
    8000479c:	02d76863          	bltu	a4,a3,800047cc <fileread+0xba>
    800047a0:	0792                	slli	a5,a5,0x4
    800047a2:	0001c717          	auipc	a4,0x1c
    800047a6:	48670713          	addi	a4,a4,1158 # 80020c28 <devsw>
    800047aa:	97ba                	add	a5,a5,a4
    800047ac:	639c                	ld	a5,0(a5)
    800047ae:	c38d                	beqz	a5,800047d0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047b0:	4505                	li	a0,1
    800047b2:	9782                	jalr	a5
    800047b4:	892a                	mv	s2,a0
    800047b6:	bf75                	j	80004772 <fileread+0x60>
    panic("fileread");
    800047b8:	00004517          	auipc	a0,0x4
    800047bc:	f5050513          	addi	a0,a0,-176 # 80008708 <syscalls+0x260>
    800047c0:	ffffc097          	auipc	ra,0xffffc
    800047c4:	d84080e7          	jalr	-636(ra) # 80000544 <panic>
    return -1;
    800047c8:	597d                	li	s2,-1
    800047ca:	b765                	j	80004772 <fileread+0x60>
      return -1;
    800047cc:	597d                	li	s2,-1
    800047ce:	b755                	j	80004772 <fileread+0x60>
    800047d0:	597d                	li	s2,-1
    800047d2:	b745                	j	80004772 <fileread+0x60>

00000000800047d4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047d4:	715d                	addi	sp,sp,-80
    800047d6:	e486                	sd	ra,72(sp)
    800047d8:	e0a2                	sd	s0,64(sp)
    800047da:	fc26                	sd	s1,56(sp)
    800047dc:	f84a                	sd	s2,48(sp)
    800047de:	f44e                	sd	s3,40(sp)
    800047e0:	f052                	sd	s4,32(sp)
    800047e2:	ec56                	sd	s5,24(sp)
    800047e4:	e85a                	sd	s6,16(sp)
    800047e6:	e45e                	sd	s7,8(sp)
    800047e8:	e062                	sd	s8,0(sp)
    800047ea:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047ec:	00954783          	lbu	a5,9(a0)
    800047f0:	10078663          	beqz	a5,800048fc <filewrite+0x128>
    800047f4:	892a                	mv	s2,a0
    800047f6:	8aae                	mv	s5,a1
    800047f8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047fa:	411c                	lw	a5,0(a0)
    800047fc:	4705                	li	a4,1
    800047fe:	02e78263          	beq	a5,a4,80004822 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004802:	470d                	li	a4,3
    80004804:	02e78663          	beq	a5,a4,80004830 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004808:	4709                	li	a4,2
    8000480a:	0ee79163          	bne	a5,a4,800048ec <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000480e:	0ac05d63          	blez	a2,800048c8 <filewrite+0xf4>
    int i = 0;
    80004812:	4981                	li	s3,0
    80004814:	6b05                	lui	s6,0x1
    80004816:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000481a:	6b85                	lui	s7,0x1
    8000481c:	c00b8b9b          	addiw	s7,s7,-1024
    80004820:	a861                	j	800048b8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004822:	6908                	ld	a0,16(a0)
    80004824:	00000097          	auipc	ra,0x0
    80004828:	22e080e7          	jalr	558(ra) # 80004a52 <pipewrite>
    8000482c:	8a2a                	mv	s4,a0
    8000482e:	a045                	j	800048ce <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004830:	02451783          	lh	a5,36(a0)
    80004834:	03079693          	slli	a3,a5,0x30
    80004838:	92c1                	srli	a3,a3,0x30
    8000483a:	4725                	li	a4,9
    8000483c:	0cd76263          	bltu	a4,a3,80004900 <filewrite+0x12c>
    80004840:	0792                	slli	a5,a5,0x4
    80004842:	0001c717          	auipc	a4,0x1c
    80004846:	3e670713          	addi	a4,a4,998 # 80020c28 <devsw>
    8000484a:	97ba                	add	a5,a5,a4
    8000484c:	679c                	ld	a5,8(a5)
    8000484e:	cbdd                	beqz	a5,80004904 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004850:	4505                	li	a0,1
    80004852:	9782                	jalr	a5
    80004854:	8a2a                	mv	s4,a0
    80004856:	a8a5                	j	800048ce <filewrite+0xfa>
    80004858:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000485c:	00000097          	auipc	ra,0x0
    80004860:	8b0080e7          	jalr	-1872(ra) # 8000410c <begin_op>
      ilock(f->ip);
    80004864:	01893503          	ld	a0,24(s2)
    80004868:	fffff097          	auipc	ra,0xfffff
    8000486c:	ee2080e7          	jalr	-286(ra) # 8000374a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004870:	8762                	mv	a4,s8
    80004872:	02092683          	lw	a3,32(s2)
    80004876:	01598633          	add	a2,s3,s5
    8000487a:	4585                	li	a1,1
    8000487c:	01893503          	ld	a0,24(s2)
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	276080e7          	jalr	630(ra) # 80003af6 <writei>
    80004888:	84aa                	mv	s1,a0
    8000488a:	00a05763          	blez	a0,80004898 <filewrite+0xc4>
        f->off += r;
    8000488e:	02092783          	lw	a5,32(s2)
    80004892:	9fa9                	addw	a5,a5,a0
    80004894:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004898:	01893503          	ld	a0,24(s2)
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	f70080e7          	jalr	-144(ra) # 8000380c <iunlock>
      end_op();
    800048a4:	00000097          	auipc	ra,0x0
    800048a8:	8e8080e7          	jalr	-1816(ra) # 8000418c <end_op>

      if(r != n1){
    800048ac:	009c1f63          	bne	s8,s1,800048ca <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048b0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048b4:	0149db63          	bge	s3,s4,800048ca <filewrite+0xf6>
      int n1 = n - i;
    800048b8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048bc:	84be                	mv	s1,a5
    800048be:	2781                	sext.w	a5,a5
    800048c0:	f8fb5ce3          	bge	s6,a5,80004858 <filewrite+0x84>
    800048c4:	84de                	mv	s1,s7
    800048c6:	bf49                	j	80004858 <filewrite+0x84>
    int i = 0;
    800048c8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048ca:	013a1f63          	bne	s4,s3,800048e8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048ce:	8552                	mv	a0,s4
    800048d0:	60a6                	ld	ra,72(sp)
    800048d2:	6406                	ld	s0,64(sp)
    800048d4:	74e2                	ld	s1,56(sp)
    800048d6:	7942                	ld	s2,48(sp)
    800048d8:	79a2                	ld	s3,40(sp)
    800048da:	7a02                	ld	s4,32(sp)
    800048dc:	6ae2                	ld	s5,24(sp)
    800048de:	6b42                	ld	s6,16(sp)
    800048e0:	6ba2                	ld	s7,8(sp)
    800048e2:	6c02                	ld	s8,0(sp)
    800048e4:	6161                	addi	sp,sp,80
    800048e6:	8082                	ret
    ret = (i == n ? n : -1);
    800048e8:	5a7d                	li	s4,-1
    800048ea:	b7d5                	j	800048ce <filewrite+0xfa>
    panic("filewrite");
    800048ec:	00004517          	auipc	a0,0x4
    800048f0:	e2c50513          	addi	a0,a0,-468 # 80008718 <syscalls+0x270>
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	c50080e7          	jalr	-944(ra) # 80000544 <panic>
    return -1;
    800048fc:	5a7d                	li	s4,-1
    800048fe:	bfc1                	j	800048ce <filewrite+0xfa>
      return -1;
    80004900:	5a7d                	li	s4,-1
    80004902:	b7f1                	j	800048ce <filewrite+0xfa>
    80004904:	5a7d                	li	s4,-1
    80004906:	b7e1                	j	800048ce <filewrite+0xfa>

0000000080004908 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004908:	7179                	addi	sp,sp,-48
    8000490a:	f406                	sd	ra,40(sp)
    8000490c:	f022                	sd	s0,32(sp)
    8000490e:	ec26                	sd	s1,24(sp)
    80004910:	e84a                	sd	s2,16(sp)
    80004912:	e44e                	sd	s3,8(sp)
    80004914:	e052                	sd	s4,0(sp)
    80004916:	1800                	addi	s0,sp,48
    80004918:	84aa                	mv	s1,a0
    8000491a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000491c:	0005b023          	sd	zero,0(a1)
    80004920:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004924:	00000097          	auipc	ra,0x0
    80004928:	bf8080e7          	jalr	-1032(ra) # 8000451c <filealloc>
    8000492c:	e088                	sd	a0,0(s1)
    8000492e:	c551                	beqz	a0,800049ba <pipealloc+0xb2>
    80004930:	00000097          	auipc	ra,0x0
    80004934:	bec080e7          	jalr	-1044(ra) # 8000451c <filealloc>
    80004938:	00aa3023          	sd	a0,0(s4)
    8000493c:	c92d                	beqz	a0,800049ae <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	1bc080e7          	jalr	444(ra) # 80000afa <kalloc>
    80004946:	892a                	mv	s2,a0
    80004948:	c125                	beqz	a0,800049a8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000494a:	4985                	li	s3,1
    8000494c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004950:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004954:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004958:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000495c:	00004597          	auipc	a1,0x4
    80004960:	dcc58593          	addi	a1,a1,-564 # 80008728 <syscalls+0x280>
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	1f6080e7          	jalr	502(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    8000496c:	609c                	ld	a5,0(s1)
    8000496e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004972:	609c                	ld	a5,0(s1)
    80004974:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004978:	609c                	ld	a5,0(s1)
    8000497a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000497e:	609c                	ld	a5,0(s1)
    80004980:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004984:	000a3783          	ld	a5,0(s4)
    80004988:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000498c:	000a3783          	ld	a5,0(s4)
    80004990:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004994:	000a3783          	ld	a5,0(s4)
    80004998:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000499c:	000a3783          	ld	a5,0(s4)
    800049a0:	0127b823          	sd	s2,16(a5)
  return 0;
    800049a4:	4501                	li	a0,0
    800049a6:	a025                	j	800049ce <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049a8:	6088                	ld	a0,0(s1)
    800049aa:	e501                	bnez	a0,800049b2 <pipealloc+0xaa>
    800049ac:	a039                	j	800049ba <pipealloc+0xb2>
    800049ae:	6088                	ld	a0,0(s1)
    800049b0:	c51d                	beqz	a0,800049de <pipealloc+0xd6>
    fileclose(*f0);
    800049b2:	00000097          	auipc	ra,0x0
    800049b6:	c26080e7          	jalr	-986(ra) # 800045d8 <fileclose>
  if(*f1)
    800049ba:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049be:	557d                	li	a0,-1
  if(*f1)
    800049c0:	c799                	beqz	a5,800049ce <pipealloc+0xc6>
    fileclose(*f1);
    800049c2:	853e                	mv	a0,a5
    800049c4:	00000097          	auipc	ra,0x0
    800049c8:	c14080e7          	jalr	-1004(ra) # 800045d8 <fileclose>
  return -1;
    800049cc:	557d                	li	a0,-1
}
    800049ce:	70a2                	ld	ra,40(sp)
    800049d0:	7402                	ld	s0,32(sp)
    800049d2:	64e2                	ld	s1,24(sp)
    800049d4:	6942                	ld	s2,16(sp)
    800049d6:	69a2                	ld	s3,8(sp)
    800049d8:	6a02                	ld	s4,0(sp)
    800049da:	6145                	addi	sp,sp,48
    800049dc:	8082                	ret
  return -1;
    800049de:	557d                	li	a0,-1
    800049e0:	b7fd                	j	800049ce <pipealloc+0xc6>

00000000800049e2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049e2:	1101                	addi	sp,sp,-32
    800049e4:	ec06                	sd	ra,24(sp)
    800049e6:	e822                	sd	s0,16(sp)
    800049e8:	e426                	sd	s1,8(sp)
    800049ea:	e04a                	sd	s2,0(sp)
    800049ec:	1000                	addi	s0,sp,32
    800049ee:	84aa                	mv	s1,a0
    800049f0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	1f8080e7          	jalr	504(ra) # 80000bea <acquire>
  if(writable){
    800049fa:	02090d63          	beqz	s2,80004a34 <pipeclose+0x52>
    pi->writeopen = 0;
    800049fe:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a02:	21848513          	addi	a0,s1,536
    80004a06:	ffffd097          	auipc	ra,0xffffd
    80004a0a:	6c8080e7          	jalr	1736(ra) # 800020ce <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a0e:	2204b783          	ld	a5,544(s1)
    80004a12:	eb95                	bnez	a5,80004a46 <pipeclose+0x64>
    release(&pi->lock);
    80004a14:	8526                	mv	a0,s1
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	288080e7          	jalr	648(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004a1e:	8526                	mv	a0,s1
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	fde080e7          	jalr	-34(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004a28:	60e2                	ld	ra,24(sp)
    80004a2a:	6442                	ld	s0,16(sp)
    80004a2c:	64a2                	ld	s1,8(sp)
    80004a2e:	6902                	ld	s2,0(sp)
    80004a30:	6105                	addi	sp,sp,32
    80004a32:	8082                	ret
    pi->readopen = 0;
    80004a34:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a38:	21c48513          	addi	a0,s1,540
    80004a3c:	ffffd097          	auipc	ra,0xffffd
    80004a40:	692080e7          	jalr	1682(ra) # 800020ce <wakeup>
    80004a44:	b7e9                	j	80004a0e <pipeclose+0x2c>
    release(&pi->lock);
    80004a46:	8526                	mv	a0,s1
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	256080e7          	jalr	598(ra) # 80000c9e <release>
}
    80004a50:	bfe1                	j	80004a28 <pipeclose+0x46>

0000000080004a52 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a52:	7159                	addi	sp,sp,-112
    80004a54:	f486                	sd	ra,104(sp)
    80004a56:	f0a2                	sd	s0,96(sp)
    80004a58:	eca6                	sd	s1,88(sp)
    80004a5a:	e8ca                	sd	s2,80(sp)
    80004a5c:	e4ce                	sd	s3,72(sp)
    80004a5e:	e0d2                	sd	s4,64(sp)
    80004a60:	fc56                	sd	s5,56(sp)
    80004a62:	f85a                	sd	s6,48(sp)
    80004a64:	f45e                	sd	s7,40(sp)
    80004a66:	f062                	sd	s8,32(sp)
    80004a68:	ec66                	sd	s9,24(sp)
    80004a6a:	1880                	addi	s0,sp,112
    80004a6c:	84aa                	mv	s1,a0
    80004a6e:	8aae                	mv	s5,a1
    80004a70:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a72:	ffffd097          	auipc	ra,0xffffd
    80004a76:	f54080e7          	jalr	-172(ra) # 800019c6 <myproc>
    80004a7a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a7c:	8526                	mv	a0,s1
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	16c080e7          	jalr	364(ra) # 80000bea <acquire>
  while(i < n){
    80004a86:	0d405463          	blez	s4,80004b4e <pipewrite+0xfc>
    80004a8a:	8ba6                	mv	s7,s1
  int i = 0;
    80004a8c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a8e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a90:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a94:	21c48c13          	addi	s8,s1,540
    80004a98:	a08d                	j	80004afa <pipewrite+0xa8>
      release(&pi->lock);
    80004a9a:	8526                	mv	a0,s1
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	202080e7          	jalr	514(ra) # 80000c9e <release>
      return -1;
    80004aa4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004aa6:	854a                	mv	a0,s2
    80004aa8:	70a6                	ld	ra,104(sp)
    80004aaa:	7406                	ld	s0,96(sp)
    80004aac:	64e6                	ld	s1,88(sp)
    80004aae:	6946                	ld	s2,80(sp)
    80004ab0:	69a6                	ld	s3,72(sp)
    80004ab2:	6a06                	ld	s4,64(sp)
    80004ab4:	7ae2                	ld	s5,56(sp)
    80004ab6:	7b42                	ld	s6,48(sp)
    80004ab8:	7ba2                	ld	s7,40(sp)
    80004aba:	7c02                	ld	s8,32(sp)
    80004abc:	6ce2                	ld	s9,24(sp)
    80004abe:	6165                	addi	sp,sp,112
    80004ac0:	8082                	ret
      wakeup(&pi->nread);
    80004ac2:	8566                	mv	a0,s9
    80004ac4:	ffffd097          	auipc	ra,0xffffd
    80004ac8:	60a080e7          	jalr	1546(ra) # 800020ce <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004acc:	85de                	mv	a1,s7
    80004ace:	8562                	mv	a0,s8
    80004ad0:	ffffd097          	auipc	ra,0xffffd
    80004ad4:	59a080e7          	jalr	1434(ra) # 8000206a <sleep>
    80004ad8:	a839                	j	80004af6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ada:	21c4a783          	lw	a5,540(s1)
    80004ade:	0017871b          	addiw	a4,a5,1
    80004ae2:	20e4ae23          	sw	a4,540(s1)
    80004ae6:	1ff7f793          	andi	a5,a5,511
    80004aea:	97a6                	add	a5,a5,s1
    80004aec:	f9f44703          	lbu	a4,-97(s0)
    80004af0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004af4:	2905                	addiw	s2,s2,1
  while(i < n){
    80004af6:	05495063          	bge	s2,s4,80004b36 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004afa:	2204a783          	lw	a5,544(s1)
    80004afe:	dfd1                	beqz	a5,80004a9a <pipewrite+0x48>
    80004b00:	854e                	mv	a0,s3
    80004b02:	ffffe097          	auipc	ra,0xffffe
    80004b06:	810080e7          	jalr	-2032(ra) # 80002312 <killed>
    80004b0a:	f941                	bnez	a0,80004a9a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b0c:	2184a783          	lw	a5,536(s1)
    80004b10:	21c4a703          	lw	a4,540(s1)
    80004b14:	2007879b          	addiw	a5,a5,512
    80004b18:	faf705e3          	beq	a4,a5,80004ac2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b1c:	4685                	li	a3,1
    80004b1e:	01590633          	add	a2,s2,s5
    80004b22:	f9f40593          	addi	a1,s0,-97
    80004b26:	0509b503          	ld	a0,80(s3)
    80004b2a:	ffffd097          	auipc	ra,0xffffd
    80004b2e:	be6080e7          	jalr	-1050(ra) # 80001710 <copyin>
    80004b32:	fb6514e3          	bne	a0,s6,80004ada <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b36:	21848513          	addi	a0,s1,536
    80004b3a:	ffffd097          	auipc	ra,0xffffd
    80004b3e:	594080e7          	jalr	1428(ra) # 800020ce <wakeup>
  release(&pi->lock);
    80004b42:	8526                	mv	a0,s1
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	15a080e7          	jalr	346(ra) # 80000c9e <release>
  return i;
    80004b4c:	bfa9                	j	80004aa6 <pipewrite+0x54>
  int i = 0;
    80004b4e:	4901                	li	s2,0
    80004b50:	b7dd                	j	80004b36 <pipewrite+0xe4>

0000000080004b52 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b52:	715d                	addi	sp,sp,-80
    80004b54:	e486                	sd	ra,72(sp)
    80004b56:	e0a2                	sd	s0,64(sp)
    80004b58:	fc26                	sd	s1,56(sp)
    80004b5a:	f84a                	sd	s2,48(sp)
    80004b5c:	f44e                	sd	s3,40(sp)
    80004b5e:	f052                	sd	s4,32(sp)
    80004b60:	ec56                	sd	s5,24(sp)
    80004b62:	e85a                	sd	s6,16(sp)
    80004b64:	0880                	addi	s0,sp,80
    80004b66:	84aa                	mv	s1,a0
    80004b68:	892e                	mv	s2,a1
    80004b6a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b6c:	ffffd097          	auipc	ra,0xffffd
    80004b70:	e5a080e7          	jalr	-422(ra) # 800019c6 <myproc>
    80004b74:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b76:	8b26                	mv	s6,s1
    80004b78:	8526                	mv	a0,s1
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	070080e7          	jalr	112(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b82:	2184a703          	lw	a4,536(s1)
    80004b86:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b8a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b8e:	02f71763          	bne	a4,a5,80004bbc <piperead+0x6a>
    80004b92:	2244a783          	lw	a5,548(s1)
    80004b96:	c39d                	beqz	a5,80004bbc <piperead+0x6a>
    if(killed(pr)){
    80004b98:	8552                	mv	a0,s4
    80004b9a:	ffffd097          	auipc	ra,0xffffd
    80004b9e:	778080e7          	jalr	1912(ra) # 80002312 <killed>
    80004ba2:	e941                	bnez	a0,80004c32 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ba4:	85da                	mv	a1,s6
    80004ba6:	854e                	mv	a0,s3
    80004ba8:	ffffd097          	auipc	ra,0xffffd
    80004bac:	4c2080e7          	jalr	1218(ra) # 8000206a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bb0:	2184a703          	lw	a4,536(s1)
    80004bb4:	21c4a783          	lw	a5,540(s1)
    80004bb8:	fcf70de3          	beq	a4,a5,80004b92 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bbc:	09505263          	blez	s5,80004c40 <piperead+0xee>
    80004bc0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bc2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004bc4:	2184a783          	lw	a5,536(s1)
    80004bc8:	21c4a703          	lw	a4,540(s1)
    80004bcc:	02f70d63          	beq	a4,a5,80004c06 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bd0:	0017871b          	addiw	a4,a5,1
    80004bd4:	20e4ac23          	sw	a4,536(s1)
    80004bd8:	1ff7f793          	andi	a5,a5,511
    80004bdc:	97a6                	add	a5,a5,s1
    80004bde:	0187c783          	lbu	a5,24(a5)
    80004be2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004be6:	4685                	li	a3,1
    80004be8:	fbf40613          	addi	a2,s0,-65
    80004bec:	85ca                	mv	a1,s2
    80004bee:	050a3503          	ld	a0,80(s4)
    80004bf2:	ffffd097          	auipc	ra,0xffffd
    80004bf6:	a92080e7          	jalr	-1390(ra) # 80001684 <copyout>
    80004bfa:	01650663          	beq	a0,s6,80004c06 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bfe:	2985                	addiw	s3,s3,1
    80004c00:	0905                	addi	s2,s2,1
    80004c02:	fd3a91e3          	bne	s5,s3,80004bc4 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c06:	21c48513          	addi	a0,s1,540
    80004c0a:	ffffd097          	auipc	ra,0xffffd
    80004c0e:	4c4080e7          	jalr	1220(ra) # 800020ce <wakeup>
  release(&pi->lock);
    80004c12:	8526                	mv	a0,s1
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	08a080e7          	jalr	138(ra) # 80000c9e <release>
  return i;
}
    80004c1c:	854e                	mv	a0,s3
    80004c1e:	60a6                	ld	ra,72(sp)
    80004c20:	6406                	ld	s0,64(sp)
    80004c22:	74e2                	ld	s1,56(sp)
    80004c24:	7942                	ld	s2,48(sp)
    80004c26:	79a2                	ld	s3,40(sp)
    80004c28:	7a02                	ld	s4,32(sp)
    80004c2a:	6ae2                	ld	s5,24(sp)
    80004c2c:	6b42                	ld	s6,16(sp)
    80004c2e:	6161                	addi	sp,sp,80
    80004c30:	8082                	ret
      release(&pi->lock);
    80004c32:	8526                	mv	a0,s1
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	06a080e7          	jalr	106(ra) # 80000c9e <release>
      return -1;
    80004c3c:	59fd                	li	s3,-1
    80004c3e:	bff9                	j	80004c1c <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c40:	4981                	li	s3,0
    80004c42:	b7d1                	j	80004c06 <piperead+0xb4>

0000000080004c44 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c44:	1141                	addi	sp,sp,-16
    80004c46:	e422                	sd	s0,8(sp)
    80004c48:	0800                	addi	s0,sp,16
    80004c4a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c4c:	8905                	andi	a0,a0,1
    80004c4e:	c111                	beqz	a0,80004c52 <flags2perm+0xe>
      perm = PTE_X;
    80004c50:	4521                	li	a0,8
    if(flags & 0x2)
    80004c52:	8b89                	andi	a5,a5,2
    80004c54:	c399                	beqz	a5,80004c5a <flags2perm+0x16>
      perm |= PTE_W;
    80004c56:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c5a:	6422                	ld	s0,8(sp)
    80004c5c:	0141                	addi	sp,sp,16
    80004c5e:	8082                	ret

0000000080004c60 <exec>:

int
exec(char *path, char **argv)
{
    80004c60:	df010113          	addi	sp,sp,-528
    80004c64:	20113423          	sd	ra,520(sp)
    80004c68:	20813023          	sd	s0,512(sp)
    80004c6c:	ffa6                	sd	s1,504(sp)
    80004c6e:	fbca                	sd	s2,496(sp)
    80004c70:	f7ce                	sd	s3,488(sp)
    80004c72:	f3d2                	sd	s4,480(sp)
    80004c74:	efd6                	sd	s5,472(sp)
    80004c76:	ebda                	sd	s6,464(sp)
    80004c78:	e7de                	sd	s7,456(sp)
    80004c7a:	e3e2                	sd	s8,448(sp)
    80004c7c:	ff66                	sd	s9,440(sp)
    80004c7e:	fb6a                	sd	s10,432(sp)
    80004c80:	f76e                	sd	s11,424(sp)
    80004c82:	0c00                	addi	s0,sp,528
    80004c84:	84aa                	mv	s1,a0
    80004c86:	dea43c23          	sd	a0,-520(s0)
    80004c8a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c8e:	ffffd097          	auipc	ra,0xffffd
    80004c92:	d38080e7          	jalr	-712(ra) # 800019c6 <myproc>
    80004c96:	892a                	mv	s2,a0

  begin_op();
    80004c98:	fffff097          	auipc	ra,0xfffff
    80004c9c:	474080e7          	jalr	1140(ra) # 8000410c <begin_op>

  if((ip = namei(path)) == 0){
    80004ca0:	8526                	mv	a0,s1
    80004ca2:	fffff097          	auipc	ra,0xfffff
    80004ca6:	24e080e7          	jalr	590(ra) # 80003ef0 <namei>
    80004caa:	c92d                	beqz	a0,80004d1c <exec+0xbc>
    80004cac:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cae:	fffff097          	auipc	ra,0xfffff
    80004cb2:	a9c080e7          	jalr	-1380(ra) # 8000374a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cb6:	04000713          	li	a4,64
    80004cba:	4681                	li	a3,0
    80004cbc:	e5040613          	addi	a2,s0,-432
    80004cc0:	4581                	li	a1,0
    80004cc2:	8526                	mv	a0,s1
    80004cc4:	fffff097          	auipc	ra,0xfffff
    80004cc8:	d3a080e7          	jalr	-710(ra) # 800039fe <readi>
    80004ccc:	04000793          	li	a5,64
    80004cd0:	00f51a63          	bne	a0,a5,80004ce4 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004cd4:	e5042703          	lw	a4,-432(s0)
    80004cd8:	464c47b7          	lui	a5,0x464c4
    80004cdc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ce0:	04f70463          	beq	a4,a5,80004d28 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ce4:	8526                	mv	a0,s1
    80004ce6:	fffff097          	auipc	ra,0xfffff
    80004cea:	cc6080e7          	jalr	-826(ra) # 800039ac <iunlockput>
    end_op();
    80004cee:	fffff097          	auipc	ra,0xfffff
    80004cf2:	49e080e7          	jalr	1182(ra) # 8000418c <end_op>
  }
  return -1;
    80004cf6:	557d                	li	a0,-1
}
    80004cf8:	20813083          	ld	ra,520(sp)
    80004cfc:	20013403          	ld	s0,512(sp)
    80004d00:	74fe                	ld	s1,504(sp)
    80004d02:	795e                	ld	s2,496(sp)
    80004d04:	79be                	ld	s3,488(sp)
    80004d06:	7a1e                	ld	s4,480(sp)
    80004d08:	6afe                	ld	s5,472(sp)
    80004d0a:	6b5e                	ld	s6,464(sp)
    80004d0c:	6bbe                	ld	s7,456(sp)
    80004d0e:	6c1e                	ld	s8,448(sp)
    80004d10:	7cfa                	ld	s9,440(sp)
    80004d12:	7d5a                	ld	s10,432(sp)
    80004d14:	7dba                	ld	s11,424(sp)
    80004d16:	21010113          	addi	sp,sp,528
    80004d1a:	8082                	ret
    end_op();
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	470080e7          	jalr	1136(ra) # 8000418c <end_op>
    return -1;
    80004d24:	557d                	li	a0,-1
    80004d26:	bfc9                	j	80004cf8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d28:	854a                	mv	a0,s2
    80004d2a:	ffffd097          	auipc	ra,0xffffd
    80004d2e:	d60080e7          	jalr	-672(ra) # 80001a8a <proc_pagetable>
    80004d32:	8baa                	mv	s7,a0
    80004d34:	d945                	beqz	a0,80004ce4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d36:	e7042983          	lw	s3,-400(s0)
    80004d3a:	e8845783          	lhu	a5,-376(s0)
    80004d3e:	c7ad                	beqz	a5,80004da8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d40:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d42:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d44:	6c85                	lui	s9,0x1
    80004d46:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d4a:	def43823          	sd	a5,-528(s0)
    80004d4e:	ac0d                	j	80004f80 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d50:	00004517          	auipc	a0,0x4
    80004d54:	9e050513          	addi	a0,a0,-1568 # 80008730 <syscalls+0x288>
    80004d58:	ffffb097          	auipc	ra,0xffffb
    80004d5c:	7ec080e7          	jalr	2028(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d60:	8756                	mv	a4,s5
    80004d62:	012d86bb          	addw	a3,s11,s2
    80004d66:	4581                	li	a1,0
    80004d68:	8526                	mv	a0,s1
    80004d6a:	fffff097          	auipc	ra,0xfffff
    80004d6e:	c94080e7          	jalr	-876(ra) # 800039fe <readi>
    80004d72:	2501                	sext.w	a0,a0
    80004d74:	1aaa9a63          	bne	s5,a0,80004f28 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004d78:	6785                	lui	a5,0x1
    80004d7a:	0127893b          	addw	s2,a5,s2
    80004d7e:	77fd                	lui	a5,0xfffff
    80004d80:	01478a3b          	addw	s4,a5,s4
    80004d84:	1f897563          	bgeu	s2,s8,80004f6e <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004d88:	02091593          	slli	a1,s2,0x20
    80004d8c:	9181                	srli	a1,a1,0x20
    80004d8e:	95ea                	add	a1,a1,s10
    80004d90:	855e                	mv	a0,s7
    80004d92:	ffffc097          	auipc	ra,0xffffc
    80004d96:	2e6080e7          	jalr	742(ra) # 80001078 <walkaddr>
    80004d9a:	862a                	mv	a2,a0
    if(pa == 0)
    80004d9c:	d955                	beqz	a0,80004d50 <exec+0xf0>
      n = PGSIZE;
    80004d9e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004da0:	fd9a70e3          	bgeu	s4,s9,80004d60 <exec+0x100>
      n = sz - i;
    80004da4:	8ad2                	mv	s5,s4
    80004da6:	bf6d                	j	80004d60 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004da8:	4a01                	li	s4,0
  iunlockput(ip);
    80004daa:	8526                	mv	a0,s1
    80004dac:	fffff097          	auipc	ra,0xfffff
    80004db0:	c00080e7          	jalr	-1024(ra) # 800039ac <iunlockput>
  end_op();
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	3d8080e7          	jalr	984(ra) # 8000418c <end_op>
  p = myproc();
    80004dbc:	ffffd097          	auipc	ra,0xffffd
    80004dc0:	c0a080e7          	jalr	-1014(ra) # 800019c6 <myproc>
    80004dc4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004dc6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004dca:	6785                	lui	a5,0x1
    80004dcc:	17fd                	addi	a5,a5,-1
    80004dce:	9a3e                	add	s4,s4,a5
    80004dd0:	757d                	lui	a0,0xfffff
    80004dd2:	00aa77b3          	and	a5,s4,a0
    80004dd6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004dda:	4691                	li	a3,4
    80004ddc:	6609                	lui	a2,0x2
    80004dde:	963e                	add	a2,a2,a5
    80004de0:	85be                	mv	a1,a5
    80004de2:	855e                	mv	a0,s7
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	648080e7          	jalr	1608(ra) # 8000142c <uvmalloc>
    80004dec:	8b2a                	mv	s6,a0
  ip = 0;
    80004dee:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004df0:	12050c63          	beqz	a0,80004f28 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004df4:	75f9                	lui	a1,0xffffe
    80004df6:	95aa                	add	a1,a1,a0
    80004df8:	855e                	mv	a0,s7
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	858080e7          	jalr	-1960(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e02:	7c7d                	lui	s8,0xfffff
    80004e04:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e06:	e0043783          	ld	a5,-512(s0)
    80004e0a:	6388                	ld	a0,0(a5)
    80004e0c:	c535                	beqz	a0,80004e78 <exec+0x218>
    80004e0e:	e9040993          	addi	s3,s0,-368
    80004e12:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e16:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e18:	ffffc097          	auipc	ra,0xffffc
    80004e1c:	052080e7          	jalr	82(ra) # 80000e6a <strlen>
    80004e20:	2505                	addiw	a0,a0,1
    80004e22:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e26:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e2a:	13896663          	bltu	s2,s8,80004f56 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e2e:	e0043d83          	ld	s11,-512(s0)
    80004e32:	000dba03          	ld	s4,0(s11)
    80004e36:	8552                	mv	a0,s4
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	032080e7          	jalr	50(ra) # 80000e6a <strlen>
    80004e40:	0015069b          	addiw	a3,a0,1
    80004e44:	8652                	mv	a2,s4
    80004e46:	85ca                	mv	a1,s2
    80004e48:	855e                	mv	a0,s7
    80004e4a:	ffffd097          	auipc	ra,0xffffd
    80004e4e:	83a080e7          	jalr	-1990(ra) # 80001684 <copyout>
    80004e52:	10054663          	bltz	a0,80004f5e <exec+0x2fe>
    ustack[argc] = sp;
    80004e56:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e5a:	0485                	addi	s1,s1,1
    80004e5c:	008d8793          	addi	a5,s11,8
    80004e60:	e0f43023          	sd	a5,-512(s0)
    80004e64:	008db503          	ld	a0,8(s11)
    80004e68:	c911                	beqz	a0,80004e7c <exec+0x21c>
    if(argc >= MAXARG)
    80004e6a:	09a1                	addi	s3,s3,8
    80004e6c:	fb3c96e3          	bne	s9,s3,80004e18 <exec+0x1b8>
  sz = sz1;
    80004e70:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e74:	4481                	li	s1,0
    80004e76:	a84d                	j	80004f28 <exec+0x2c8>
  sp = sz;
    80004e78:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e7a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e7c:	00349793          	slli	a5,s1,0x3
    80004e80:	f9040713          	addi	a4,s0,-112
    80004e84:	97ba                	add	a5,a5,a4
    80004e86:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004e8a:	00148693          	addi	a3,s1,1
    80004e8e:	068e                	slli	a3,a3,0x3
    80004e90:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e94:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e98:	01897663          	bgeu	s2,s8,80004ea4 <exec+0x244>
  sz = sz1;
    80004e9c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ea0:	4481                	li	s1,0
    80004ea2:	a059                	j	80004f28 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ea4:	e9040613          	addi	a2,s0,-368
    80004ea8:	85ca                	mv	a1,s2
    80004eaa:	855e                	mv	a0,s7
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	7d8080e7          	jalr	2008(ra) # 80001684 <copyout>
    80004eb4:	0a054963          	bltz	a0,80004f66 <exec+0x306>
  p->trapframe->a1 = sp;
    80004eb8:	058ab783          	ld	a5,88(s5)
    80004ebc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ec0:	df843783          	ld	a5,-520(s0)
    80004ec4:	0007c703          	lbu	a4,0(a5)
    80004ec8:	cf11                	beqz	a4,80004ee4 <exec+0x284>
    80004eca:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ecc:	02f00693          	li	a3,47
    80004ed0:	a039                	j	80004ede <exec+0x27e>
      last = s+1;
    80004ed2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004ed6:	0785                	addi	a5,a5,1
    80004ed8:	fff7c703          	lbu	a4,-1(a5)
    80004edc:	c701                	beqz	a4,80004ee4 <exec+0x284>
    if(*s == '/')
    80004ede:	fed71ce3          	bne	a4,a3,80004ed6 <exec+0x276>
    80004ee2:	bfc5                	j	80004ed2 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ee4:	4641                	li	a2,16
    80004ee6:	df843583          	ld	a1,-520(s0)
    80004eea:	158a8513          	addi	a0,s5,344
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	f4a080e7          	jalr	-182(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ef6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004efa:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004efe:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f02:	058ab783          	ld	a5,88(s5)
    80004f06:	e6843703          	ld	a4,-408(s0)
    80004f0a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f0c:	058ab783          	ld	a5,88(s5)
    80004f10:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f14:	85ea                	mv	a1,s10
    80004f16:	ffffd097          	auipc	ra,0xffffd
    80004f1a:	c10080e7          	jalr	-1008(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f1e:	0004851b          	sext.w	a0,s1
    80004f22:	bbd9                	j	80004cf8 <exec+0x98>
    80004f24:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f28:	e0843583          	ld	a1,-504(s0)
    80004f2c:	855e                	mv	a0,s7
    80004f2e:	ffffd097          	auipc	ra,0xffffd
    80004f32:	bf8080e7          	jalr	-1032(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80004f36:	da0497e3          	bnez	s1,80004ce4 <exec+0x84>
  return -1;
    80004f3a:	557d                	li	a0,-1
    80004f3c:	bb75                	j	80004cf8 <exec+0x98>
    80004f3e:	e1443423          	sd	s4,-504(s0)
    80004f42:	b7dd                	j	80004f28 <exec+0x2c8>
    80004f44:	e1443423          	sd	s4,-504(s0)
    80004f48:	b7c5                	j	80004f28 <exec+0x2c8>
    80004f4a:	e1443423          	sd	s4,-504(s0)
    80004f4e:	bfe9                	j	80004f28 <exec+0x2c8>
    80004f50:	e1443423          	sd	s4,-504(s0)
    80004f54:	bfd1                	j	80004f28 <exec+0x2c8>
  sz = sz1;
    80004f56:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f5a:	4481                	li	s1,0
    80004f5c:	b7f1                	j	80004f28 <exec+0x2c8>
  sz = sz1;
    80004f5e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f62:	4481                	li	s1,0
    80004f64:	b7d1                	j	80004f28 <exec+0x2c8>
  sz = sz1;
    80004f66:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f6a:	4481                	li	s1,0
    80004f6c:	bf75                	j	80004f28 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f6e:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f72:	2b05                	addiw	s6,s6,1
    80004f74:	0389899b          	addiw	s3,s3,56
    80004f78:	e8845783          	lhu	a5,-376(s0)
    80004f7c:	e2fb57e3          	bge	s6,a5,80004daa <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f80:	2981                	sext.w	s3,s3
    80004f82:	03800713          	li	a4,56
    80004f86:	86ce                	mv	a3,s3
    80004f88:	e1840613          	addi	a2,s0,-488
    80004f8c:	4581                	li	a1,0
    80004f8e:	8526                	mv	a0,s1
    80004f90:	fffff097          	auipc	ra,0xfffff
    80004f94:	a6e080e7          	jalr	-1426(ra) # 800039fe <readi>
    80004f98:	03800793          	li	a5,56
    80004f9c:	f8f514e3          	bne	a0,a5,80004f24 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80004fa0:	e1842783          	lw	a5,-488(s0)
    80004fa4:	4705                	li	a4,1
    80004fa6:	fce796e3          	bne	a5,a4,80004f72 <exec+0x312>
    if(ph.memsz < ph.filesz)
    80004faa:	e4043903          	ld	s2,-448(s0)
    80004fae:	e3843783          	ld	a5,-456(s0)
    80004fb2:	f8f966e3          	bltu	s2,a5,80004f3e <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fb6:	e2843783          	ld	a5,-472(s0)
    80004fba:	993e                	add	s2,s2,a5
    80004fbc:	f8f964e3          	bltu	s2,a5,80004f44 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80004fc0:	df043703          	ld	a4,-528(s0)
    80004fc4:	8ff9                	and	a5,a5,a4
    80004fc6:	f3d1                	bnez	a5,80004f4a <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fc8:	e1c42503          	lw	a0,-484(s0)
    80004fcc:	00000097          	auipc	ra,0x0
    80004fd0:	c78080e7          	jalr	-904(ra) # 80004c44 <flags2perm>
    80004fd4:	86aa                	mv	a3,a0
    80004fd6:	864a                	mv	a2,s2
    80004fd8:	85d2                	mv	a1,s4
    80004fda:	855e                	mv	a0,s7
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	450080e7          	jalr	1104(ra) # 8000142c <uvmalloc>
    80004fe4:	e0a43423          	sd	a0,-504(s0)
    80004fe8:	d525                	beqz	a0,80004f50 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fea:	e2843d03          	ld	s10,-472(s0)
    80004fee:	e2042d83          	lw	s11,-480(s0)
    80004ff2:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ff6:	f60c0ce3          	beqz	s8,80004f6e <exec+0x30e>
    80004ffa:	8a62                	mv	s4,s8
    80004ffc:	4901                	li	s2,0
    80004ffe:	b369                	j	80004d88 <exec+0x128>

0000000080005000 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005000:	7179                	addi	sp,sp,-48
    80005002:	f406                	sd	ra,40(sp)
    80005004:	f022                	sd	s0,32(sp)
    80005006:	ec26                	sd	s1,24(sp)
    80005008:	e84a                	sd	s2,16(sp)
    8000500a:	1800                	addi	s0,sp,48
    8000500c:	892e                	mv	s2,a1
    8000500e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005010:	fdc40593          	addi	a1,s0,-36
    80005014:	ffffe097          	auipc	ra,0xffffe
    80005018:	bb0080e7          	jalr	-1104(ra) # 80002bc4 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000501c:	fdc42703          	lw	a4,-36(s0)
    80005020:	47bd                	li	a5,15
    80005022:	02e7eb63          	bltu	a5,a4,80005058 <argfd+0x58>
    80005026:	ffffd097          	auipc	ra,0xffffd
    8000502a:	9a0080e7          	jalr	-1632(ra) # 800019c6 <myproc>
    8000502e:	fdc42703          	lw	a4,-36(s0)
    80005032:	01a70793          	addi	a5,a4,26
    80005036:	078e                	slli	a5,a5,0x3
    80005038:	953e                	add	a0,a0,a5
    8000503a:	611c                	ld	a5,0(a0)
    8000503c:	c385                	beqz	a5,8000505c <argfd+0x5c>
    return -1;
  if(pfd)
    8000503e:	00090463          	beqz	s2,80005046 <argfd+0x46>
    *pfd = fd;
    80005042:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005046:	4501                	li	a0,0
  if(pf)
    80005048:	c091                	beqz	s1,8000504c <argfd+0x4c>
    *pf = f;
    8000504a:	e09c                	sd	a5,0(s1)
}
    8000504c:	70a2                	ld	ra,40(sp)
    8000504e:	7402                	ld	s0,32(sp)
    80005050:	64e2                	ld	s1,24(sp)
    80005052:	6942                	ld	s2,16(sp)
    80005054:	6145                	addi	sp,sp,48
    80005056:	8082                	ret
    return -1;
    80005058:	557d                	li	a0,-1
    8000505a:	bfcd                	j	8000504c <argfd+0x4c>
    8000505c:	557d                	li	a0,-1
    8000505e:	b7fd                	j	8000504c <argfd+0x4c>

0000000080005060 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005060:	1101                	addi	sp,sp,-32
    80005062:	ec06                	sd	ra,24(sp)
    80005064:	e822                	sd	s0,16(sp)
    80005066:	e426                	sd	s1,8(sp)
    80005068:	1000                	addi	s0,sp,32
    8000506a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000506c:	ffffd097          	auipc	ra,0xffffd
    80005070:	95a080e7          	jalr	-1702(ra) # 800019c6 <myproc>
    80005074:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005076:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdd310>
    8000507a:	4501                	li	a0,0
    8000507c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000507e:	6398                	ld	a4,0(a5)
    80005080:	cb19                	beqz	a4,80005096 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005082:	2505                	addiw	a0,a0,1
    80005084:	07a1                	addi	a5,a5,8
    80005086:	fed51ce3          	bne	a0,a3,8000507e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000508a:	557d                	li	a0,-1
}
    8000508c:	60e2                	ld	ra,24(sp)
    8000508e:	6442                	ld	s0,16(sp)
    80005090:	64a2                	ld	s1,8(sp)
    80005092:	6105                	addi	sp,sp,32
    80005094:	8082                	ret
      p->ofile[fd] = f;
    80005096:	01a50793          	addi	a5,a0,26
    8000509a:	078e                	slli	a5,a5,0x3
    8000509c:	963e                	add	a2,a2,a5
    8000509e:	e204                	sd	s1,0(a2)
      return fd;
    800050a0:	b7f5                	j	8000508c <fdalloc+0x2c>

00000000800050a2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050a2:	715d                	addi	sp,sp,-80
    800050a4:	e486                	sd	ra,72(sp)
    800050a6:	e0a2                	sd	s0,64(sp)
    800050a8:	fc26                	sd	s1,56(sp)
    800050aa:	f84a                	sd	s2,48(sp)
    800050ac:	f44e                	sd	s3,40(sp)
    800050ae:	f052                	sd	s4,32(sp)
    800050b0:	ec56                	sd	s5,24(sp)
    800050b2:	e85a                	sd	s6,16(sp)
    800050b4:	0880                	addi	s0,sp,80
    800050b6:	8b2e                	mv	s6,a1
    800050b8:	89b2                	mv	s3,a2
    800050ba:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050bc:	fb040593          	addi	a1,s0,-80
    800050c0:	fffff097          	auipc	ra,0xfffff
    800050c4:	e4e080e7          	jalr	-434(ra) # 80003f0e <nameiparent>
    800050c8:	84aa                	mv	s1,a0
    800050ca:	16050063          	beqz	a0,8000522a <create+0x188>
    return 0;

  ilock(dp);
    800050ce:	ffffe097          	auipc	ra,0xffffe
    800050d2:	67c080e7          	jalr	1660(ra) # 8000374a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050d6:	4601                	li	a2,0
    800050d8:	fb040593          	addi	a1,s0,-80
    800050dc:	8526                	mv	a0,s1
    800050de:	fffff097          	auipc	ra,0xfffff
    800050e2:	b50080e7          	jalr	-1200(ra) # 80003c2e <dirlookup>
    800050e6:	8aaa                	mv	s5,a0
    800050e8:	c931                	beqz	a0,8000513c <create+0x9a>
    iunlockput(dp);
    800050ea:	8526                	mv	a0,s1
    800050ec:	fffff097          	auipc	ra,0xfffff
    800050f0:	8c0080e7          	jalr	-1856(ra) # 800039ac <iunlockput>
    ilock(ip);
    800050f4:	8556                	mv	a0,s5
    800050f6:	ffffe097          	auipc	ra,0xffffe
    800050fa:	654080e7          	jalr	1620(ra) # 8000374a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050fe:	000b059b          	sext.w	a1,s6
    80005102:	4789                	li	a5,2
    80005104:	02f59563          	bne	a1,a5,8000512e <create+0x8c>
    80005108:	044ad783          	lhu	a5,68(s5)
    8000510c:	37f9                	addiw	a5,a5,-2
    8000510e:	17c2                	slli	a5,a5,0x30
    80005110:	93c1                	srli	a5,a5,0x30
    80005112:	4705                	li	a4,1
    80005114:	00f76d63          	bltu	a4,a5,8000512e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005118:	8556                	mv	a0,s5
    8000511a:	60a6                	ld	ra,72(sp)
    8000511c:	6406                	ld	s0,64(sp)
    8000511e:	74e2                	ld	s1,56(sp)
    80005120:	7942                	ld	s2,48(sp)
    80005122:	79a2                	ld	s3,40(sp)
    80005124:	7a02                	ld	s4,32(sp)
    80005126:	6ae2                	ld	s5,24(sp)
    80005128:	6b42                	ld	s6,16(sp)
    8000512a:	6161                	addi	sp,sp,80
    8000512c:	8082                	ret
    iunlockput(ip);
    8000512e:	8556                	mv	a0,s5
    80005130:	fffff097          	auipc	ra,0xfffff
    80005134:	87c080e7          	jalr	-1924(ra) # 800039ac <iunlockput>
    return 0;
    80005138:	4a81                	li	s5,0
    8000513a:	bff9                	j	80005118 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000513c:	85da                	mv	a1,s6
    8000513e:	4088                	lw	a0,0(s1)
    80005140:	ffffe097          	auipc	ra,0xffffe
    80005144:	46e080e7          	jalr	1134(ra) # 800035ae <ialloc>
    80005148:	8a2a                	mv	s4,a0
    8000514a:	c921                	beqz	a0,8000519a <create+0xf8>
  ilock(ip);
    8000514c:	ffffe097          	auipc	ra,0xffffe
    80005150:	5fe080e7          	jalr	1534(ra) # 8000374a <ilock>
  ip->major = major;
    80005154:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005158:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000515c:	4785                	li	a5,1
    8000515e:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005162:	8552                	mv	a0,s4
    80005164:	ffffe097          	auipc	ra,0xffffe
    80005168:	51c080e7          	jalr	1308(ra) # 80003680 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000516c:	000b059b          	sext.w	a1,s6
    80005170:	4785                	li	a5,1
    80005172:	02f58b63          	beq	a1,a5,800051a8 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005176:	004a2603          	lw	a2,4(s4)
    8000517a:	fb040593          	addi	a1,s0,-80
    8000517e:	8526                	mv	a0,s1
    80005180:	fffff097          	auipc	ra,0xfffff
    80005184:	cbe080e7          	jalr	-834(ra) # 80003e3e <dirlink>
    80005188:	06054f63          	bltz	a0,80005206 <create+0x164>
  iunlockput(dp);
    8000518c:	8526                	mv	a0,s1
    8000518e:	fffff097          	auipc	ra,0xfffff
    80005192:	81e080e7          	jalr	-2018(ra) # 800039ac <iunlockput>
  return ip;
    80005196:	8ad2                	mv	s5,s4
    80005198:	b741                	j	80005118 <create+0x76>
    iunlockput(dp);
    8000519a:	8526                	mv	a0,s1
    8000519c:	fffff097          	auipc	ra,0xfffff
    800051a0:	810080e7          	jalr	-2032(ra) # 800039ac <iunlockput>
    return 0;
    800051a4:	8ad2                	mv	s5,s4
    800051a6:	bf8d                	j	80005118 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051a8:	004a2603          	lw	a2,4(s4)
    800051ac:	00003597          	auipc	a1,0x3
    800051b0:	5a458593          	addi	a1,a1,1444 # 80008750 <syscalls+0x2a8>
    800051b4:	8552                	mv	a0,s4
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	c88080e7          	jalr	-888(ra) # 80003e3e <dirlink>
    800051be:	04054463          	bltz	a0,80005206 <create+0x164>
    800051c2:	40d0                	lw	a2,4(s1)
    800051c4:	00003597          	auipc	a1,0x3
    800051c8:	59458593          	addi	a1,a1,1428 # 80008758 <syscalls+0x2b0>
    800051cc:	8552                	mv	a0,s4
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	c70080e7          	jalr	-912(ra) # 80003e3e <dirlink>
    800051d6:	02054863          	bltz	a0,80005206 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800051da:	004a2603          	lw	a2,4(s4)
    800051de:	fb040593          	addi	a1,s0,-80
    800051e2:	8526                	mv	a0,s1
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	c5a080e7          	jalr	-934(ra) # 80003e3e <dirlink>
    800051ec:	00054d63          	bltz	a0,80005206 <create+0x164>
    dp->nlink++;  // for ".."
    800051f0:	04a4d783          	lhu	a5,74(s1)
    800051f4:	2785                	addiw	a5,a5,1
    800051f6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800051fa:	8526                	mv	a0,s1
    800051fc:	ffffe097          	auipc	ra,0xffffe
    80005200:	484080e7          	jalr	1156(ra) # 80003680 <iupdate>
    80005204:	b761                	j	8000518c <create+0xea>
  ip->nlink = 0;
    80005206:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000520a:	8552                	mv	a0,s4
    8000520c:	ffffe097          	auipc	ra,0xffffe
    80005210:	474080e7          	jalr	1140(ra) # 80003680 <iupdate>
  iunlockput(ip);
    80005214:	8552                	mv	a0,s4
    80005216:	ffffe097          	auipc	ra,0xffffe
    8000521a:	796080e7          	jalr	1942(ra) # 800039ac <iunlockput>
  iunlockput(dp);
    8000521e:	8526                	mv	a0,s1
    80005220:	ffffe097          	auipc	ra,0xffffe
    80005224:	78c080e7          	jalr	1932(ra) # 800039ac <iunlockput>
  return 0;
    80005228:	bdc5                	j	80005118 <create+0x76>
    return 0;
    8000522a:	8aaa                	mv	s5,a0
    8000522c:	b5f5                	j	80005118 <create+0x76>

000000008000522e <sys_dup>:
{
    8000522e:	7179                	addi	sp,sp,-48
    80005230:	f406                	sd	ra,40(sp)
    80005232:	f022                	sd	s0,32(sp)
    80005234:	ec26                	sd	s1,24(sp)
    80005236:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005238:	fd840613          	addi	a2,s0,-40
    8000523c:	4581                	li	a1,0
    8000523e:	4501                	li	a0,0
    80005240:	00000097          	auipc	ra,0x0
    80005244:	dc0080e7          	jalr	-576(ra) # 80005000 <argfd>
    return -1;
    80005248:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000524a:	02054363          	bltz	a0,80005270 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000524e:	fd843503          	ld	a0,-40(s0)
    80005252:	00000097          	auipc	ra,0x0
    80005256:	e0e080e7          	jalr	-498(ra) # 80005060 <fdalloc>
    8000525a:	84aa                	mv	s1,a0
    return -1;
    8000525c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000525e:	00054963          	bltz	a0,80005270 <sys_dup+0x42>
  filedup(f);
    80005262:	fd843503          	ld	a0,-40(s0)
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	320080e7          	jalr	800(ra) # 80004586 <filedup>
  return fd;
    8000526e:	87a6                	mv	a5,s1
}
    80005270:	853e                	mv	a0,a5
    80005272:	70a2                	ld	ra,40(sp)
    80005274:	7402                	ld	s0,32(sp)
    80005276:	64e2                	ld	s1,24(sp)
    80005278:	6145                	addi	sp,sp,48
    8000527a:	8082                	ret

000000008000527c <sys_read>:
{
    8000527c:	7179                	addi	sp,sp,-48
    8000527e:	f406                	sd	ra,40(sp)
    80005280:	f022                	sd	s0,32(sp)
    80005282:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005284:	fd840593          	addi	a1,s0,-40
    80005288:	4505                	li	a0,1
    8000528a:	ffffe097          	auipc	ra,0xffffe
    8000528e:	95a080e7          	jalr	-1702(ra) # 80002be4 <argaddr>
  argint(2, &n);
    80005292:	fe440593          	addi	a1,s0,-28
    80005296:	4509                	li	a0,2
    80005298:	ffffe097          	auipc	ra,0xffffe
    8000529c:	92c080e7          	jalr	-1748(ra) # 80002bc4 <argint>
  if(argfd(0, 0, &f) < 0)
    800052a0:	fe840613          	addi	a2,s0,-24
    800052a4:	4581                	li	a1,0
    800052a6:	4501                	li	a0,0
    800052a8:	00000097          	auipc	ra,0x0
    800052ac:	d58080e7          	jalr	-680(ra) # 80005000 <argfd>
    800052b0:	87aa                	mv	a5,a0
    return -1;
    800052b2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052b4:	0007cc63          	bltz	a5,800052cc <sys_read+0x50>
  return fileread(f, p, n);
    800052b8:	fe442603          	lw	a2,-28(s0)
    800052bc:	fd843583          	ld	a1,-40(s0)
    800052c0:	fe843503          	ld	a0,-24(s0)
    800052c4:	fffff097          	auipc	ra,0xfffff
    800052c8:	44e080e7          	jalr	1102(ra) # 80004712 <fileread>
}
    800052cc:	70a2                	ld	ra,40(sp)
    800052ce:	7402                	ld	s0,32(sp)
    800052d0:	6145                	addi	sp,sp,48
    800052d2:	8082                	ret

00000000800052d4 <sys_write>:
{
    800052d4:	7179                	addi	sp,sp,-48
    800052d6:	f406                	sd	ra,40(sp)
    800052d8:	f022                	sd	s0,32(sp)
    800052da:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052dc:	fd840593          	addi	a1,s0,-40
    800052e0:	4505                	li	a0,1
    800052e2:	ffffe097          	auipc	ra,0xffffe
    800052e6:	902080e7          	jalr	-1790(ra) # 80002be4 <argaddr>
  argint(2, &n);
    800052ea:	fe440593          	addi	a1,s0,-28
    800052ee:	4509                	li	a0,2
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	8d4080e7          	jalr	-1836(ra) # 80002bc4 <argint>
  if(argfd(0, 0, &f) < 0)
    800052f8:	fe840613          	addi	a2,s0,-24
    800052fc:	4581                	li	a1,0
    800052fe:	4501                	li	a0,0
    80005300:	00000097          	auipc	ra,0x0
    80005304:	d00080e7          	jalr	-768(ra) # 80005000 <argfd>
    80005308:	87aa                	mv	a5,a0
    return -1;
    8000530a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000530c:	0007cc63          	bltz	a5,80005324 <sys_write+0x50>
  return filewrite(f, p, n);
    80005310:	fe442603          	lw	a2,-28(s0)
    80005314:	fd843583          	ld	a1,-40(s0)
    80005318:	fe843503          	ld	a0,-24(s0)
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	4b8080e7          	jalr	1208(ra) # 800047d4 <filewrite>
}
    80005324:	70a2                	ld	ra,40(sp)
    80005326:	7402                	ld	s0,32(sp)
    80005328:	6145                	addi	sp,sp,48
    8000532a:	8082                	ret

000000008000532c <sys_close>:
{
    8000532c:	1101                	addi	sp,sp,-32
    8000532e:	ec06                	sd	ra,24(sp)
    80005330:	e822                	sd	s0,16(sp)
    80005332:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005334:	fe040613          	addi	a2,s0,-32
    80005338:	fec40593          	addi	a1,s0,-20
    8000533c:	4501                	li	a0,0
    8000533e:	00000097          	auipc	ra,0x0
    80005342:	cc2080e7          	jalr	-830(ra) # 80005000 <argfd>
    return -1;
    80005346:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005348:	02054463          	bltz	a0,80005370 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	67a080e7          	jalr	1658(ra) # 800019c6 <myproc>
    80005354:	fec42783          	lw	a5,-20(s0)
    80005358:	07e9                	addi	a5,a5,26
    8000535a:	078e                	slli	a5,a5,0x3
    8000535c:	97aa                	add	a5,a5,a0
    8000535e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005362:	fe043503          	ld	a0,-32(s0)
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	272080e7          	jalr	626(ra) # 800045d8 <fileclose>
  return 0;
    8000536e:	4781                	li	a5,0
}
    80005370:	853e                	mv	a0,a5
    80005372:	60e2                	ld	ra,24(sp)
    80005374:	6442                	ld	s0,16(sp)
    80005376:	6105                	addi	sp,sp,32
    80005378:	8082                	ret

000000008000537a <sys_fstat>:
{
    8000537a:	1101                	addi	sp,sp,-32
    8000537c:	ec06                	sd	ra,24(sp)
    8000537e:	e822                	sd	s0,16(sp)
    80005380:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005382:	fe040593          	addi	a1,s0,-32
    80005386:	4505                	li	a0,1
    80005388:	ffffe097          	auipc	ra,0xffffe
    8000538c:	85c080e7          	jalr	-1956(ra) # 80002be4 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005390:	fe840613          	addi	a2,s0,-24
    80005394:	4581                	li	a1,0
    80005396:	4501                	li	a0,0
    80005398:	00000097          	auipc	ra,0x0
    8000539c:	c68080e7          	jalr	-920(ra) # 80005000 <argfd>
    800053a0:	87aa                	mv	a5,a0
    return -1;
    800053a2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053a4:	0007ca63          	bltz	a5,800053b8 <sys_fstat+0x3e>
  return filestat(f, st);
    800053a8:	fe043583          	ld	a1,-32(s0)
    800053ac:	fe843503          	ld	a0,-24(s0)
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	2f0080e7          	jalr	752(ra) # 800046a0 <filestat>
}
    800053b8:	60e2                	ld	ra,24(sp)
    800053ba:	6442                	ld	s0,16(sp)
    800053bc:	6105                	addi	sp,sp,32
    800053be:	8082                	ret

00000000800053c0 <sys_link>:
{
    800053c0:	7169                	addi	sp,sp,-304
    800053c2:	f606                	sd	ra,296(sp)
    800053c4:	f222                	sd	s0,288(sp)
    800053c6:	ee26                	sd	s1,280(sp)
    800053c8:	ea4a                	sd	s2,272(sp)
    800053ca:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053cc:	08000613          	li	a2,128
    800053d0:	ed040593          	addi	a1,s0,-304
    800053d4:	4501                	li	a0,0
    800053d6:	ffffe097          	auipc	ra,0xffffe
    800053da:	82e080e7          	jalr	-2002(ra) # 80002c04 <argstr>
    return -1;
    800053de:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053e0:	10054e63          	bltz	a0,800054fc <sys_link+0x13c>
    800053e4:	08000613          	li	a2,128
    800053e8:	f5040593          	addi	a1,s0,-176
    800053ec:	4505                	li	a0,1
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	816080e7          	jalr	-2026(ra) # 80002c04 <argstr>
    return -1;
    800053f6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053f8:	10054263          	bltz	a0,800054fc <sys_link+0x13c>
  begin_op();
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	d10080e7          	jalr	-752(ra) # 8000410c <begin_op>
  if((ip = namei(old)) == 0){
    80005404:	ed040513          	addi	a0,s0,-304
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	ae8080e7          	jalr	-1304(ra) # 80003ef0 <namei>
    80005410:	84aa                	mv	s1,a0
    80005412:	c551                	beqz	a0,8000549e <sys_link+0xde>
  ilock(ip);
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	336080e7          	jalr	822(ra) # 8000374a <ilock>
  if(ip->type == T_DIR){
    8000541c:	04449703          	lh	a4,68(s1)
    80005420:	4785                	li	a5,1
    80005422:	08f70463          	beq	a4,a5,800054aa <sys_link+0xea>
  ip->nlink++;
    80005426:	04a4d783          	lhu	a5,74(s1)
    8000542a:	2785                	addiw	a5,a5,1
    8000542c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005430:	8526                	mv	a0,s1
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	24e080e7          	jalr	590(ra) # 80003680 <iupdate>
  iunlock(ip);
    8000543a:	8526                	mv	a0,s1
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	3d0080e7          	jalr	976(ra) # 8000380c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005444:	fd040593          	addi	a1,s0,-48
    80005448:	f5040513          	addi	a0,s0,-176
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	ac2080e7          	jalr	-1342(ra) # 80003f0e <nameiparent>
    80005454:	892a                	mv	s2,a0
    80005456:	c935                	beqz	a0,800054ca <sys_link+0x10a>
  ilock(dp);
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	2f2080e7          	jalr	754(ra) # 8000374a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005460:	00092703          	lw	a4,0(s2)
    80005464:	409c                	lw	a5,0(s1)
    80005466:	04f71d63          	bne	a4,a5,800054c0 <sys_link+0x100>
    8000546a:	40d0                	lw	a2,4(s1)
    8000546c:	fd040593          	addi	a1,s0,-48
    80005470:	854a                	mv	a0,s2
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	9cc080e7          	jalr	-1588(ra) # 80003e3e <dirlink>
    8000547a:	04054363          	bltz	a0,800054c0 <sys_link+0x100>
  iunlockput(dp);
    8000547e:	854a                	mv	a0,s2
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	52c080e7          	jalr	1324(ra) # 800039ac <iunlockput>
  iput(ip);
    80005488:	8526                	mv	a0,s1
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	47a080e7          	jalr	1146(ra) # 80003904 <iput>
  end_op();
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	cfa080e7          	jalr	-774(ra) # 8000418c <end_op>
  return 0;
    8000549a:	4781                	li	a5,0
    8000549c:	a085                	j	800054fc <sys_link+0x13c>
    end_op();
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	cee080e7          	jalr	-786(ra) # 8000418c <end_op>
    return -1;
    800054a6:	57fd                	li	a5,-1
    800054a8:	a891                	j	800054fc <sys_link+0x13c>
    iunlockput(ip);
    800054aa:	8526                	mv	a0,s1
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	500080e7          	jalr	1280(ra) # 800039ac <iunlockput>
    end_op();
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	cd8080e7          	jalr	-808(ra) # 8000418c <end_op>
    return -1;
    800054bc:	57fd                	li	a5,-1
    800054be:	a83d                	j	800054fc <sys_link+0x13c>
    iunlockput(dp);
    800054c0:	854a                	mv	a0,s2
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	4ea080e7          	jalr	1258(ra) # 800039ac <iunlockput>
  ilock(ip);
    800054ca:	8526                	mv	a0,s1
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	27e080e7          	jalr	638(ra) # 8000374a <ilock>
  ip->nlink--;
    800054d4:	04a4d783          	lhu	a5,74(s1)
    800054d8:	37fd                	addiw	a5,a5,-1
    800054da:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054de:	8526                	mv	a0,s1
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	1a0080e7          	jalr	416(ra) # 80003680 <iupdate>
  iunlockput(ip);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	4c2080e7          	jalr	1218(ra) # 800039ac <iunlockput>
  end_op();
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	c9a080e7          	jalr	-870(ra) # 8000418c <end_op>
  return -1;
    800054fa:	57fd                	li	a5,-1
}
    800054fc:	853e                	mv	a0,a5
    800054fe:	70b2                	ld	ra,296(sp)
    80005500:	7412                	ld	s0,288(sp)
    80005502:	64f2                	ld	s1,280(sp)
    80005504:	6952                	ld	s2,272(sp)
    80005506:	6155                	addi	sp,sp,304
    80005508:	8082                	ret

000000008000550a <sys_unlink>:
{
    8000550a:	7151                	addi	sp,sp,-240
    8000550c:	f586                	sd	ra,232(sp)
    8000550e:	f1a2                	sd	s0,224(sp)
    80005510:	eda6                	sd	s1,216(sp)
    80005512:	e9ca                	sd	s2,208(sp)
    80005514:	e5ce                	sd	s3,200(sp)
    80005516:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005518:	08000613          	li	a2,128
    8000551c:	f3040593          	addi	a1,s0,-208
    80005520:	4501                	li	a0,0
    80005522:	ffffd097          	auipc	ra,0xffffd
    80005526:	6e2080e7          	jalr	1762(ra) # 80002c04 <argstr>
    8000552a:	18054163          	bltz	a0,800056ac <sys_unlink+0x1a2>
  begin_op();
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	bde080e7          	jalr	-1058(ra) # 8000410c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005536:	fb040593          	addi	a1,s0,-80
    8000553a:	f3040513          	addi	a0,s0,-208
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	9d0080e7          	jalr	-1584(ra) # 80003f0e <nameiparent>
    80005546:	84aa                	mv	s1,a0
    80005548:	c979                	beqz	a0,8000561e <sys_unlink+0x114>
  ilock(dp);
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	200080e7          	jalr	512(ra) # 8000374a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005552:	00003597          	auipc	a1,0x3
    80005556:	1fe58593          	addi	a1,a1,510 # 80008750 <syscalls+0x2a8>
    8000555a:	fb040513          	addi	a0,s0,-80
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	6b6080e7          	jalr	1718(ra) # 80003c14 <namecmp>
    80005566:	14050a63          	beqz	a0,800056ba <sys_unlink+0x1b0>
    8000556a:	00003597          	auipc	a1,0x3
    8000556e:	1ee58593          	addi	a1,a1,494 # 80008758 <syscalls+0x2b0>
    80005572:	fb040513          	addi	a0,s0,-80
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	69e080e7          	jalr	1694(ra) # 80003c14 <namecmp>
    8000557e:	12050e63          	beqz	a0,800056ba <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005582:	f2c40613          	addi	a2,s0,-212
    80005586:	fb040593          	addi	a1,s0,-80
    8000558a:	8526                	mv	a0,s1
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	6a2080e7          	jalr	1698(ra) # 80003c2e <dirlookup>
    80005594:	892a                	mv	s2,a0
    80005596:	12050263          	beqz	a0,800056ba <sys_unlink+0x1b0>
  ilock(ip);
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	1b0080e7          	jalr	432(ra) # 8000374a <ilock>
  if(ip->nlink < 1)
    800055a2:	04a91783          	lh	a5,74(s2)
    800055a6:	08f05263          	blez	a5,8000562a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055aa:	04491703          	lh	a4,68(s2)
    800055ae:	4785                	li	a5,1
    800055b0:	08f70563          	beq	a4,a5,8000563a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055b4:	4641                	li	a2,16
    800055b6:	4581                	li	a1,0
    800055b8:	fc040513          	addi	a0,s0,-64
    800055bc:	ffffb097          	auipc	ra,0xffffb
    800055c0:	72a080e7          	jalr	1834(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055c4:	4741                	li	a4,16
    800055c6:	f2c42683          	lw	a3,-212(s0)
    800055ca:	fc040613          	addi	a2,s0,-64
    800055ce:	4581                	li	a1,0
    800055d0:	8526                	mv	a0,s1
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	524080e7          	jalr	1316(ra) # 80003af6 <writei>
    800055da:	47c1                	li	a5,16
    800055dc:	0af51563          	bne	a0,a5,80005686 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055e0:	04491703          	lh	a4,68(s2)
    800055e4:	4785                	li	a5,1
    800055e6:	0af70863          	beq	a4,a5,80005696 <sys_unlink+0x18c>
  iunlockput(dp);
    800055ea:	8526                	mv	a0,s1
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	3c0080e7          	jalr	960(ra) # 800039ac <iunlockput>
  ip->nlink--;
    800055f4:	04a95783          	lhu	a5,74(s2)
    800055f8:	37fd                	addiw	a5,a5,-1
    800055fa:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055fe:	854a                	mv	a0,s2
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	080080e7          	jalr	128(ra) # 80003680 <iupdate>
  iunlockput(ip);
    80005608:	854a                	mv	a0,s2
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	3a2080e7          	jalr	930(ra) # 800039ac <iunlockput>
  end_op();
    80005612:	fffff097          	auipc	ra,0xfffff
    80005616:	b7a080e7          	jalr	-1158(ra) # 8000418c <end_op>
  return 0;
    8000561a:	4501                	li	a0,0
    8000561c:	a84d                	j	800056ce <sys_unlink+0x1c4>
    end_op();
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	b6e080e7          	jalr	-1170(ra) # 8000418c <end_op>
    return -1;
    80005626:	557d                	li	a0,-1
    80005628:	a05d                	j	800056ce <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000562a:	00003517          	auipc	a0,0x3
    8000562e:	13650513          	addi	a0,a0,310 # 80008760 <syscalls+0x2b8>
    80005632:	ffffb097          	auipc	ra,0xffffb
    80005636:	f12080e7          	jalr	-238(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000563a:	04c92703          	lw	a4,76(s2)
    8000563e:	02000793          	li	a5,32
    80005642:	f6e7f9e3          	bgeu	a5,a4,800055b4 <sys_unlink+0xaa>
    80005646:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000564a:	4741                	li	a4,16
    8000564c:	86ce                	mv	a3,s3
    8000564e:	f1840613          	addi	a2,s0,-232
    80005652:	4581                	li	a1,0
    80005654:	854a                	mv	a0,s2
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	3a8080e7          	jalr	936(ra) # 800039fe <readi>
    8000565e:	47c1                	li	a5,16
    80005660:	00f51b63          	bne	a0,a5,80005676 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005664:	f1845783          	lhu	a5,-232(s0)
    80005668:	e7a1                	bnez	a5,800056b0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000566a:	29c1                	addiw	s3,s3,16
    8000566c:	04c92783          	lw	a5,76(s2)
    80005670:	fcf9ede3          	bltu	s3,a5,8000564a <sys_unlink+0x140>
    80005674:	b781                	j	800055b4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005676:	00003517          	auipc	a0,0x3
    8000567a:	10250513          	addi	a0,a0,258 # 80008778 <syscalls+0x2d0>
    8000567e:	ffffb097          	auipc	ra,0xffffb
    80005682:	ec6080e7          	jalr	-314(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005686:	00003517          	auipc	a0,0x3
    8000568a:	10a50513          	addi	a0,a0,266 # 80008790 <syscalls+0x2e8>
    8000568e:	ffffb097          	auipc	ra,0xffffb
    80005692:	eb6080e7          	jalr	-330(ra) # 80000544 <panic>
    dp->nlink--;
    80005696:	04a4d783          	lhu	a5,74(s1)
    8000569a:	37fd                	addiw	a5,a5,-1
    8000569c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056a0:	8526                	mv	a0,s1
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	fde080e7          	jalr	-34(ra) # 80003680 <iupdate>
    800056aa:	b781                	j	800055ea <sys_unlink+0xe0>
    return -1;
    800056ac:	557d                	li	a0,-1
    800056ae:	a005                	j	800056ce <sys_unlink+0x1c4>
    iunlockput(ip);
    800056b0:	854a                	mv	a0,s2
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	2fa080e7          	jalr	762(ra) # 800039ac <iunlockput>
  iunlockput(dp);
    800056ba:	8526                	mv	a0,s1
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	2f0080e7          	jalr	752(ra) # 800039ac <iunlockput>
  end_op();
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	ac8080e7          	jalr	-1336(ra) # 8000418c <end_op>
  return -1;
    800056cc:	557d                	li	a0,-1
}
    800056ce:	70ae                	ld	ra,232(sp)
    800056d0:	740e                	ld	s0,224(sp)
    800056d2:	64ee                	ld	s1,216(sp)
    800056d4:	694e                	ld	s2,208(sp)
    800056d6:	69ae                	ld	s3,200(sp)
    800056d8:	616d                	addi	sp,sp,240
    800056da:	8082                	ret

00000000800056dc <sys_open>:

uint64
sys_open(void)
{
    800056dc:	7131                	addi	sp,sp,-192
    800056de:	fd06                	sd	ra,184(sp)
    800056e0:	f922                	sd	s0,176(sp)
    800056e2:	f526                	sd	s1,168(sp)
    800056e4:	f14a                	sd	s2,160(sp)
    800056e6:	ed4e                	sd	s3,152(sp)
    800056e8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800056ea:	f4c40593          	addi	a1,s0,-180
    800056ee:	4505                	li	a0,1
    800056f0:	ffffd097          	auipc	ra,0xffffd
    800056f4:	4d4080e7          	jalr	1236(ra) # 80002bc4 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800056f8:	08000613          	li	a2,128
    800056fc:	f5040593          	addi	a1,s0,-176
    80005700:	4501                	li	a0,0
    80005702:	ffffd097          	auipc	ra,0xffffd
    80005706:	502080e7          	jalr	1282(ra) # 80002c04 <argstr>
    8000570a:	87aa                	mv	a5,a0
    return -1;
    8000570c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000570e:	0a07c963          	bltz	a5,800057c0 <sys_open+0xe4>

  begin_op();
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	9fa080e7          	jalr	-1542(ra) # 8000410c <begin_op>

  if(omode & O_CREATE){
    8000571a:	f4c42783          	lw	a5,-180(s0)
    8000571e:	2007f793          	andi	a5,a5,512
    80005722:	cfc5                	beqz	a5,800057da <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005724:	4681                	li	a3,0
    80005726:	4601                	li	a2,0
    80005728:	4589                	li	a1,2
    8000572a:	f5040513          	addi	a0,s0,-176
    8000572e:	00000097          	auipc	ra,0x0
    80005732:	974080e7          	jalr	-1676(ra) # 800050a2 <create>
    80005736:	84aa                	mv	s1,a0
    if(ip == 0){
    80005738:	c959                	beqz	a0,800057ce <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000573a:	04449703          	lh	a4,68(s1)
    8000573e:	478d                	li	a5,3
    80005740:	00f71763          	bne	a4,a5,8000574e <sys_open+0x72>
    80005744:	0464d703          	lhu	a4,70(s1)
    80005748:	47a5                	li	a5,9
    8000574a:	0ce7ed63          	bltu	a5,a4,80005824 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	dce080e7          	jalr	-562(ra) # 8000451c <filealloc>
    80005756:	89aa                	mv	s3,a0
    80005758:	10050363          	beqz	a0,8000585e <sys_open+0x182>
    8000575c:	00000097          	auipc	ra,0x0
    80005760:	904080e7          	jalr	-1788(ra) # 80005060 <fdalloc>
    80005764:	892a                	mv	s2,a0
    80005766:	0e054763          	bltz	a0,80005854 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000576a:	04449703          	lh	a4,68(s1)
    8000576e:	478d                	li	a5,3
    80005770:	0cf70563          	beq	a4,a5,8000583a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005774:	4789                	li	a5,2
    80005776:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000577a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000577e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005782:	f4c42783          	lw	a5,-180(s0)
    80005786:	0017c713          	xori	a4,a5,1
    8000578a:	8b05                	andi	a4,a4,1
    8000578c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005790:	0037f713          	andi	a4,a5,3
    80005794:	00e03733          	snez	a4,a4
    80005798:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000579c:	4007f793          	andi	a5,a5,1024
    800057a0:	c791                	beqz	a5,800057ac <sys_open+0xd0>
    800057a2:	04449703          	lh	a4,68(s1)
    800057a6:	4789                	li	a5,2
    800057a8:	0af70063          	beq	a4,a5,80005848 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057ac:	8526                	mv	a0,s1
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	05e080e7          	jalr	94(ra) # 8000380c <iunlock>
  end_op();
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	9d6080e7          	jalr	-1578(ra) # 8000418c <end_op>

  return fd;
    800057be:	854a                	mv	a0,s2
}
    800057c0:	70ea                	ld	ra,184(sp)
    800057c2:	744a                	ld	s0,176(sp)
    800057c4:	74aa                	ld	s1,168(sp)
    800057c6:	790a                	ld	s2,160(sp)
    800057c8:	69ea                	ld	s3,152(sp)
    800057ca:	6129                	addi	sp,sp,192
    800057cc:	8082                	ret
      end_op();
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	9be080e7          	jalr	-1602(ra) # 8000418c <end_op>
      return -1;
    800057d6:	557d                	li	a0,-1
    800057d8:	b7e5                	j	800057c0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057da:	f5040513          	addi	a0,s0,-176
    800057de:	ffffe097          	auipc	ra,0xffffe
    800057e2:	712080e7          	jalr	1810(ra) # 80003ef0 <namei>
    800057e6:	84aa                	mv	s1,a0
    800057e8:	c905                	beqz	a0,80005818 <sys_open+0x13c>
    ilock(ip);
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	f60080e7          	jalr	-160(ra) # 8000374a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057f2:	04449703          	lh	a4,68(s1)
    800057f6:	4785                	li	a5,1
    800057f8:	f4f711e3          	bne	a4,a5,8000573a <sys_open+0x5e>
    800057fc:	f4c42783          	lw	a5,-180(s0)
    80005800:	d7b9                	beqz	a5,8000574e <sys_open+0x72>
      iunlockput(ip);
    80005802:	8526                	mv	a0,s1
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	1a8080e7          	jalr	424(ra) # 800039ac <iunlockput>
      end_op();
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	980080e7          	jalr	-1664(ra) # 8000418c <end_op>
      return -1;
    80005814:	557d                	li	a0,-1
    80005816:	b76d                	j	800057c0 <sys_open+0xe4>
      end_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	974080e7          	jalr	-1676(ra) # 8000418c <end_op>
      return -1;
    80005820:	557d                	li	a0,-1
    80005822:	bf79                	j	800057c0 <sys_open+0xe4>
    iunlockput(ip);
    80005824:	8526                	mv	a0,s1
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	186080e7          	jalr	390(ra) # 800039ac <iunlockput>
    end_op();
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	95e080e7          	jalr	-1698(ra) # 8000418c <end_op>
    return -1;
    80005836:	557d                	li	a0,-1
    80005838:	b761                	j	800057c0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000583a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000583e:	04649783          	lh	a5,70(s1)
    80005842:	02f99223          	sh	a5,36(s3)
    80005846:	bf25                	j	8000577e <sys_open+0xa2>
    itrunc(ip);
    80005848:	8526                	mv	a0,s1
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	00e080e7          	jalr	14(ra) # 80003858 <itrunc>
    80005852:	bfa9                	j	800057ac <sys_open+0xd0>
      fileclose(f);
    80005854:	854e                	mv	a0,s3
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	d82080e7          	jalr	-638(ra) # 800045d8 <fileclose>
    iunlockput(ip);
    8000585e:	8526                	mv	a0,s1
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	14c080e7          	jalr	332(ra) # 800039ac <iunlockput>
    end_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	924080e7          	jalr	-1756(ra) # 8000418c <end_op>
    return -1;
    80005870:	557d                	li	a0,-1
    80005872:	b7b9                	j	800057c0 <sys_open+0xe4>

0000000080005874 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005874:	7175                	addi	sp,sp,-144
    80005876:	e506                	sd	ra,136(sp)
    80005878:	e122                	sd	s0,128(sp)
    8000587a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	890080e7          	jalr	-1904(ra) # 8000410c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005884:	08000613          	li	a2,128
    80005888:	f7040593          	addi	a1,s0,-144
    8000588c:	4501                	li	a0,0
    8000588e:	ffffd097          	auipc	ra,0xffffd
    80005892:	376080e7          	jalr	886(ra) # 80002c04 <argstr>
    80005896:	02054963          	bltz	a0,800058c8 <sys_mkdir+0x54>
    8000589a:	4681                	li	a3,0
    8000589c:	4601                	li	a2,0
    8000589e:	4585                	li	a1,1
    800058a0:	f7040513          	addi	a0,s0,-144
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	7fe080e7          	jalr	2046(ra) # 800050a2 <create>
    800058ac:	cd11                	beqz	a0,800058c8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	0fe080e7          	jalr	254(ra) # 800039ac <iunlockput>
  end_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	8d6080e7          	jalr	-1834(ra) # 8000418c <end_op>
  return 0;
    800058be:	4501                	li	a0,0
}
    800058c0:	60aa                	ld	ra,136(sp)
    800058c2:	640a                	ld	s0,128(sp)
    800058c4:	6149                	addi	sp,sp,144
    800058c6:	8082                	ret
    end_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	8c4080e7          	jalr	-1852(ra) # 8000418c <end_op>
    return -1;
    800058d0:	557d                	li	a0,-1
    800058d2:	b7fd                	j	800058c0 <sys_mkdir+0x4c>

00000000800058d4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058d4:	7135                	addi	sp,sp,-160
    800058d6:	ed06                	sd	ra,152(sp)
    800058d8:	e922                	sd	s0,144(sp)
    800058da:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	830080e7          	jalr	-2000(ra) # 8000410c <begin_op>
  argint(1, &major);
    800058e4:	f6c40593          	addi	a1,s0,-148
    800058e8:	4505                	li	a0,1
    800058ea:	ffffd097          	auipc	ra,0xffffd
    800058ee:	2da080e7          	jalr	730(ra) # 80002bc4 <argint>
  argint(2, &minor);
    800058f2:	f6840593          	addi	a1,s0,-152
    800058f6:	4509                	li	a0,2
    800058f8:	ffffd097          	auipc	ra,0xffffd
    800058fc:	2cc080e7          	jalr	716(ra) # 80002bc4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005900:	08000613          	li	a2,128
    80005904:	f7040593          	addi	a1,s0,-144
    80005908:	4501                	li	a0,0
    8000590a:	ffffd097          	auipc	ra,0xffffd
    8000590e:	2fa080e7          	jalr	762(ra) # 80002c04 <argstr>
    80005912:	02054b63          	bltz	a0,80005948 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005916:	f6841683          	lh	a3,-152(s0)
    8000591a:	f6c41603          	lh	a2,-148(s0)
    8000591e:	458d                	li	a1,3
    80005920:	f7040513          	addi	a0,s0,-144
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	77e080e7          	jalr	1918(ra) # 800050a2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000592c:	cd11                	beqz	a0,80005948 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	07e080e7          	jalr	126(ra) # 800039ac <iunlockput>
  end_op();
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	856080e7          	jalr	-1962(ra) # 8000418c <end_op>
  return 0;
    8000593e:	4501                	li	a0,0
}
    80005940:	60ea                	ld	ra,152(sp)
    80005942:	644a                	ld	s0,144(sp)
    80005944:	610d                	addi	sp,sp,160
    80005946:	8082                	ret
    end_op();
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	844080e7          	jalr	-1980(ra) # 8000418c <end_op>
    return -1;
    80005950:	557d                	li	a0,-1
    80005952:	b7fd                	j	80005940 <sys_mknod+0x6c>

0000000080005954 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005954:	7135                	addi	sp,sp,-160
    80005956:	ed06                	sd	ra,152(sp)
    80005958:	e922                	sd	s0,144(sp)
    8000595a:	e526                	sd	s1,136(sp)
    8000595c:	e14a                	sd	s2,128(sp)
    8000595e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005960:	ffffc097          	auipc	ra,0xffffc
    80005964:	066080e7          	jalr	102(ra) # 800019c6 <myproc>
    80005968:	892a                	mv	s2,a0
  
  begin_op();
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	7a2080e7          	jalr	1954(ra) # 8000410c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005972:	08000613          	li	a2,128
    80005976:	f6040593          	addi	a1,s0,-160
    8000597a:	4501                	li	a0,0
    8000597c:	ffffd097          	auipc	ra,0xffffd
    80005980:	288080e7          	jalr	648(ra) # 80002c04 <argstr>
    80005984:	04054b63          	bltz	a0,800059da <sys_chdir+0x86>
    80005988:	f6040513          	addi	a0,s0,-160
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	564080e7          	jalr	1380(ra) # 80003ef0 <namei>
    80005994:	84aa                	mv	s1,a0
    80005996:	c131                	beqz	a0,800059da <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	db2080e7          	jalr	-590(ra) # 8000374a <ilock>
  if(ip->type != T_DIR){
    800059a0:	04449703          	lh	a4,68(s1)
    800059a4:	4785                	li	a5,1
    800059a6:	04f71063          	bne	a4,a5,800059e6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059aa:	8526                	mv	a0,s1
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	e60080e7          	jalr	-416(ra) # 8000380c <iunlock>
  iput(p->cwd);
    800059b4:	15093503          	ld	a0,336(s2)
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	f4c080e7          	jalr	-180(ra) # 80003904 <iput>
  end_op();
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	7cc080e7          	jalr	1996(ra) # 8000418c <end_op>
  p->cwd = ip;
    800059c8:	14993823          	sd	s1,336(s2)
  return 0;
    800059cc:	4501                	li	a0,0
}
    800059ce:	60ea                	ld	ra,152(sp)
    800059d0:	644a                	ld	s0,144(sp)
    800059d2:	64aa                	ld	s1,136(sp)
    800059d4:	690a                	ld	s2,128(sp)
    800059d6:	610d                	addi	sp,sp,160
    800059d8:	8082                	ret
    end_op();
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	7b2080e7          	jalr	1970(ra) # 8000418c <end_op>
    return -1;
    800059e2:	557d                	li	a0,-1
    800059e4:	b7ed                	j	800059ce <sys_chdir+0x7a>
    iunlockput(ip);
    800059e6:	8526                	mv	a0,s1
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	fc4080e7          	jalr	-60(ra) # 800039ac <iunlockput>
    end_op();
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	79c080e7          	jalr	1948(ra) # 8000418c <end_op>
    return -1;
    800059f8:	557d                	li	a0,-1
    800059fa:	bfd1                	j	800059ce <sys_chdir+0x7a>

00000000800059fc <sys_exec>:

uint64
sys_exec(void)
{
    800059fc:	7145                	addi	sp,sp,-464
    800059fe:	e786                	sd	ra,456(sp)
    80005a00:	e3a2                	sd	s0,448(sp)
    80005a02:	ff26                	sd	s1,440(sp)
    80005a04:	fb4a                	sd	s2,432(sp)
    80005a06:	f74e                	sd	s3,424(sp)
    80005a08:	f352                	sd	s4,416(sp)
    80005a0a:	ef56                	sd	s5,408(sp)
    80005a0c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a0e:	e3840593          	addi	a1,s0,-456
    80005a12:	4505                	li	a0,1
    80005a14:	ffffd097          	auipc	ra,0xffffd
    80005a18:	1d0080e7          	jalr	464(ra) # 80002be4 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a1c:	08000613          	li	a2,128
    80005a20:	f4040593          	addi	a1,s0,-192
    80005a24:	4501                	li	a0,0
    80005a26:	ffffd097          	auipc	ra,0xffffd
    80005a2a:	1de080e7          	jalr	478(ra) # 80002c04 <argstr>
    80005a2e:	87aa                	mv	a5,a0
    return -1;
    80005a30:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a32:	0c07c263          	bltz	a5,80005af6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a36:	10000613          	li	a2,256
    80005a3a:	4581                	li	a1,0
    80005a3c:	e4040513          	addi	a0,s0,-448
    80005a40:	ffffb097          	auipc	ra,0xffffb
    80005a44:	2a6080e7          	jalr	678(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a48:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a4c:	89a6                	mv	s3,s1
    80005a4e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a50:	02000a13          	li	s4,32
    80005a54:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a58:	00391513          	slli	a0,s2,0x3
    80005a5c:	e3040593          	addi	a1,s0,-464
    80005a60:	e3843783          	ld	a5,-456(s0)
    80005a64:	953e                	add	a0,a0,a5
    80005a66:	ffffd097          	auipc	ra,0xffffd
    80005a6a:	0c0080e7          	jalr	192(ra) # 80002b26 <fetchaddr>
    80005a6e:	02054a63          	bltz	a0,80005aa2 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005a72:	e3043783          	ld	a5,-464(s0)
    80005a76:	c3b9                	beqz	a5,80005abc <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a78:	ffffb097          	auipc	ra,0xffffb
    80005a7c:	082080e7          	jalr	130(ra) # 80000afa <kalloc>
    80005a80:	85aa                	mv	a1,a0
    80005a82:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a86:	cd11                	beqz	a0,80005aa2 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a88:	6605                	lui	a2,0x1
    80005a8a:	e3043503          	ld	a0,-464(s0)
    80005a8e:	ffffd097          	auipc	ra,0xffffd
    80005a92:	0ea080e7          	jalr	234(ra) # 80002b78 <fetchstr>
    80005a96:	00054663          	bltz	a0,80005aa2 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005a9a:	0905                	addi	s2,s2,1
    80005a9c:	09a1                	addi	s3,s3,8
    80005a9e:	fb491be3          	bne	s2,s4,80005a54 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa2:	10048913          	addi	s2,s1,256
    80005aa6:	6088                	ld	a0,0(s1)
    80005aa8:	c531                	beqz	a0,80005af4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005aaa:	ffffb097          	auipc	ra,0xffffb
    80005aae:	f54080e7          	jalr	-172(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab2:	04a1                	addi	s1,s1,8
    80005ab4:	ff2499e3          	bne	s1,s2,80005aa6 <sys_exec+0xaa>
  return -1;
    80005ab8:	557d                	li	a0,-1
    80005aba:	a835                	j	80005af6 <sys_exec+0xfa>
      argv[i] = 0;
    80005abc:	0a8e                	slli	s5,s5,0x3
    80005abe:	fc040793          	addi	a5,s0,-64
    80005ac2:	9abe                	add	s5,s5,a5
    80005ac4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ac8:	e4040593          	addi	a1,s0,-448
    80005acc:	f4040513          	addi	a0,s0,-192
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	190080e7          	jalr	400(ra) # 80004c60 <exec>
    80005ad8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ada:	10048993          	addi	s3,s1,256
    80005ade:	6088                	ld	a0,0(s1)
    80005ae0:	c901                	beqz	a0,80005af0 <sys_exec+0xf4>
    kfree(argv[i]);
    80005ae2:	ffffb097          	auipc	ra,0xffffb
    80005ae6:	f1c080e7          	jalr	-228(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aea:	04a1                	addi	s1,s1,8
    80005aec:	ff3499e3          	bne	s1,s3,80005ade <sys_exec+0xe2>
  return ret;
    80005af0:	854a                	mv	a0,s2
    80005af2:	a011                	j	80005af6 <sys_exec+0xfa>
  return -1;
    80005af4:	557d                	li	a0,-1
}
    80005af6:	60be                	ld	ra,456(sp)
    80005af8:	641e                	ld	s0,448(sp)
    80005afa:	74fa                	ld	s1,440(sp)
    80005afc:	795a                	ld	s2,432(sp)
    80005afe:	79ba                	ld	s3,424(sp)
    80005b00:	7a1a                	ld	s4,416(sp)
    80005b02:	6afa                	ld	s5,408(sp)
    80005b04:	6179                	addi	sp,sp,464
    80005b06:	8082                	ret

0000000080005b08 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b08:	7139                	addi	sp,sp,-64
    80005b0a:	fc06                	sd	ra,56(sp)
    80005b0c:	f822                	sd	s0,48(sp)
    80005b0e:	f426                	sd	s1,40(sp)
    80005b10:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b12:	ffffc097          	auipc	ra,0xffffc
    80005b16:	eb4080e7          	jalr	-332(ra) # 800019c6 <myproc>
    80005b1a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b1c:	fd840593          	addi	a1,s0,-40
    80005b20:	4501                	li	a0,0
    80005b22:	ffffd097          	auipc	ra,0xffffd
    80005b26:	0c2080e7          	jalr	194(ra) # 80002be4 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b2a:	fc840593          	addi	a1,s0,-56
    80005b2e:	fd040513          	addi	a0,s0,-48
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	dd6080e7          	jalr	-554(ra) # 80004908 <pipealloc>
    return -1;
    80005b3a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b3c:	0c054463          	bltz	a0,80005c04 <sys_pipe+0xfc>
  fd0 = -1;
    80005b40:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b44:	fd043503          	ld	a0,-48(s0)
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	518080e7          	jalr	1304(ra) # 80005060 <fdalloc>
    80005b50:	fca42223          	sw	a0,-60(s0)
    80005b54:	08054b63          	bltz	a0,80005bea <sys_pipe+0xe2>
    80005b58:	fc843503          	ld	a0,-56(s0)
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	504080e7          	jalr	1284(ra) # 80005060 <fdalloc>
    80005b64:	fca42023          	sw	a0,-64(s0)
    80005b68:	06054863          	bltz	a0,80005bd8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b6c:	4691                	li	a3,4
    80005b6e:	fc440613          	addi	a2,s0,-60
    80005b72:	fd843583          	ld	a1,-40(s0)
    80005b76:	68a8                	ld	a0,80(s1)
    80005b78:	ffffc097          	auipc	ra,0xffffc
    80005b7c:	b0c080e7          	jalr	-1268(ra) # 80001684 <copyout>
    80005b80:	02054063          	bltz	a0,80005ba0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b84:	4691                	li	a3,4
    80005b86:	fc040613          	addi	a2,s0,-64
    80005b8a:	fd843583          	ld	a1,-40(s0)
    80005b8e:	0591                	addi	a1,a1,4
    80005b90:	68a8                	ld	a0,80(s1)
    80005b92:	ffffc097          	auipc	ra,0xffffc
    80005b96:	af2080e7          	jalr	-1294(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b9a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b9c:	06055463          	bgez	a0,80005c04 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005ba0:	fc442783          	lw	a5,-60(s0)
    80005ba4:	07e9                	addi	a5,a5,26
    80005ba6:	078e                	slli	a5,a5,0x3
    80005ba8:	97a6                	add	a5,a5,s1
    80005baa:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bae:	fc042503          	lw	a0,-64(s0)
    80005bb2:	0569                	addi	a0,a0,26
    80005bb4:	050e                	slli	a0,a0,0x3
    80005bb6:	94aa                	add	s1,s1,a0
    80005bb8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bbc:	fd043503          	ld	a0,-48(s0)
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	a18080e7          	jalr	-1512(ra) # 800045d8 <fileclose>
    fileclose(wf);
    80005bc8:	fc843503          	ld	a0,-56(s0)
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	a0c080e7          	jalr	-1524(ra) # 800045d8 <fileclose>
    return -1;
    80005bd4:	57fd                	li	a5,-1
    80005bd6:	a03d                	j	80005c04 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005bd8:	fc442783          	lw	a5,-60(s0)
    80005bdc:	0007c763          	bltz	a5,80005bea <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005be0:	07e9                	addi	a5,a5,26
    80005be2:	078e                	slli	a5,a5,0x3
    80005be4:	94be                	add	s1,s1,a5
    80005be6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bea:	fd043503          	ld	a0,-48(s0)
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	9ea080e7          	jalr	-1558(ra) # 800045d8 <fileclose>
    fileclose(wf);
    80005bf6:	fc843503          	ld	a0,-56(s0)
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	9de080e7          	jalr	-1570(ra) # 800045d8 <fileclose>
    return -1;
    80005c02:	57fd                	li	a5,-1
}
    80005c04:	853e                	mv	a0,a5
    80005c06:	70e2                	ld	ra,56(sp)
    80005c08:	7442                	ld	s0,48(sp)
    80005c0a:	74a2                	ld	s1,40(sp)
    80005c0c:	6121                	addi	sp,sp,64
    80005c0e:	8082                	ret

0000000080005c10 <kernelvec>:
    80005c10:	7111                	addi	sp,sp,-256
    80005c12:	e006                	sd	ra,0(sp)
    80005c14:	e40a                	sd	sp,8(sp)
    80005c16:	e80e                	sd	gp,16(sp)
    80005c18:	ec12                	sd	tp,24(sp)
    80005c1a:	f016                	sd	t0,32(sp)
    80005c1c:	f41a                	sd	t1,40(sp)
    80005c1e:	f81e                	sd	t2,48(sp)
    80005c20:	fc22                	sd	s0,56(sp)
    80005c22:	e0a6                	sd	s1,64(sp)
    80005c24:	e4aa                	sd	a0,72(sp)
    80005c26:	e8ae                	sd	a1,80(sp)
    80005c28:	ecb2                	sd	a2,88(sp)
    80005c2a:	f0b6                	sd	a3,96(sp)
    80005c2c:	f4ba                	sd	a4,104(sp)
    80005c2e:	f8be                	sd	a5,112(sp)
    80005c30:	fcc2                	sd	a6,120(sp)
    80005c32:	e146                	sd	a7,128(sp)
    80005c34:	e54a                	sd	s2,136(sp)
    80005c36:	e94e                	sd	s3,144(sp)
    80005c38:	ed52                	sd	s4,152(sp)
    80005c3a:	f156                	sd	s5,160(sp)
    80005c3c:	f55a                	sd	s6,168(sp)
    80005c3e:	f95e                	sd	s7,176(sp)
    80005c40:	fd62                	sd	s8,184(sp)
    80005c42:	e1e6                	sd	s9,192(sp)
    80005c44:	e5ea                	sd	s10,200(sp)
    80005c46:	e9ee                	sd	s11,208(sp)
    80005c48:	edf2                	sd	t3,216(sp)
    80005c4a:	f1f6                	sd	t4,224(sp)
    80005c4c:	f5fa                	sd	t5,232(sp)
    80005c4e:	f9fe                	sd	t6,240(sp)
    80005c50:	da3fc0ef          	jal	ra,800029f2 <kerneltrap>
    80005c54:	6082                	ld	ra,0(sp)
    80005c56:	6122                	ld	sp,8(sp)
    80005c58:	61c2                	ld	gp,16(sp)
    80005c5a:	7282                	ld	t0,32(sp)
    80005c5c:	7322                	ld	t1,40(sp)
    80005c5e:	73c2                	ld	t2,48(sp)
    80005c60:	7462                	ld	s0,56(sp)
    80005c62:	6486                	ld	s1,64(sp)
    80005c64:	6526                	ld	a0,72(sp)
    80005c66:	65c6                	ld	a1,80(sp)
    80005c68:	6666                	ld	a2,88(sp)
    80005c6a:	7686                	ld	a3,96(sp)
    80005c6c:	7726                	ld	a4,104(sp)
    80005c6e:	77c6                	ld	a5,112(sp)
    80005c70:	7866                	ld	a6,120(sp)
    80005c72:	688a                	ld	a7,128(sp)
    80005c74:	692a                	ld	s2,136(sp)
    80005c76:	69ca                	ld	s3,144(sp)
    80005c78:	6a6a                	ld	s4,152(sp)
    80005c7a:	7a8a                	ld	s5,160(sp)
    80005c7c:	7b2a                	ld	s6,168(sp)
    80005c7e:	7bca                	ld	s7,176(sp)
    80005c80:	7c6a                	ld	s8,184(sp)
    80005c82:	6c8e                	ld	s9,192(sp)
    80005c84:	6d2e                	ld	s10,200(sp)
    80005c86:	6dce                	ld	s11,208(sp)
    80005c88:	6e6e                	ld	t3,216(sp)
    80005c8a:	7e8e                	ld	t4,224(sp)
    80005c8c:	7f2e                	ld	t5,232(sp)
    80005c8e:	7fce                	ld	t6,240(sp)
    80005c90:	6111                	addi	sp,sp,256
    80005c92:	10200073          	sret
    80005c96:	00000013          	nop
    80005c9a:	00000013          	nop
    80005c9e:	0001                	nop

0000000080005ca0 <timervec>:
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	e10c                	sd	a1,0(a0)
    80005ca6:	e510                	sd	a2,8(a0)
    80005ca8:	e914                	sd	a3,16(a0)
    80005caa:	6d0c                	ld	a1,24(a0)
    80005cac:	7110                	ld	a2,32(a0)
    80005cae:	6194                	ld	a3,0(a1)
    80005cb0:	96b2                	add	a3,a3,a2
    80005cb2:	e194                	sd	a3,0(a1)
    80005cb4:	4589                	li	a1,2
    80005cb6:	14459073          	csrw	sip,a1
    80005cba:	6914                	ld	a3,16(a0)
    80005cbc:	6510                	ld	a2,8(a0)
    80005cbe:	610c                	ld	a1,0(a0)
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	30200073          	mret
	...

0000000080005cca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cca:	1141                	addi	sp,sp,-16
    80005ccc:	e422                	sd	s0,8(sp)
    80005cce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cd0:	0c0007b7          	lui	a5,0xc000
    80005cd4:	4705                	li	a4,1
    80005cd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cd8:	c3d8                	sw	a4,4(a5)
}
    80005cda:	6422                	ld	s0,8(sp)
    80005cdc:	0141                	addi	sp,sp,16
    80005cde:	8082                	ret

0000000080005ce0 <plicinithart>:

void
plicinithart(void)
{
    80005ce0:	1141                	addi	sp,sp,-16
    80005ce2:	e406                	sd	ra,8(sp)
    80005ce4:	e022                	sd	s0,0(sp)
    80005ce6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	cb2080e7          	jalr	-846(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cf0:	0085171b          	slliw	a4,a0,0x8
    80005cf4:	0c0027b7          	lui	a5,0xc002
    80005cf8:	97ba                	add	a5,a5,a4
    80005cfa:	40200713          	li	a4,1026
    80005cfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d02:	00d5151b          	slliw	a0,a0,0xd
    80005d06:	0c2017b7          	lui	a5,0xc201
    80005d0a:	953e                	add	a0,a0,a5
    80005d0c:	00052023          	sw	zero,0(a0)
}
    80005d10:	60a2                	ld	ra,8(sp)
    80005d12:	6402                	ld	s0,0(sp)
    80005d14:	0141                	addi	sp,sp,16
    80005d16:	8082                	ret

0000000080005d18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d18:	1141                	addi	sp,sp,-16
    80005d1a:	e406                	sd	ra,8(sp)
    80005d1c:	e022                	sd	s0,0(sp)
    80005d1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d20:	ffffc097          	auipc	ra,0xffffc
    80005d24:	c7a080e7          	jalr	-902(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d28:	00d5179b          	slliw	a5,a0,0xd
    80005d2c:	0c201537          	lui	a0,0xc201
    80005d30:	953e                	add	a0,a0,a5
  return irq;
}
    80005d32:	4148                	lw	a0,4(a0)
    80005d34:	60a2                	ld	ra,8(sp)
    80005d36:	6402                	ld	s0,0(sp)
    80005d38:	0141                	addi	sp,sp,16
    80005d3a:	8082                	ret

0000000080005d3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d3c:	1101                	addi	sp,sp,-32
    80005d3e:	ec06                	sd	ra,24(sp)
    80005d40:	e822                	sd	s0,16(sp)
    80005d42:	e426                	sd	s1,8(sp)
    80005d44:	1000                	addi	s0,sp,32
    80005d46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	c52080e7          	jalr	-942(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d50:	00d5151b          	slliw	a0,a0,0xd
    80005d54:	0c2017b7          	lui	a5,0xc201
    80005d58:	97aa                	add	a5,a5,a0
    80005d5a:	c3c4                	sw	s1,4(a5)
}
    80005d5c:	60e2                	ld	ra,24(sp)
    80005d5e:	6442                	ld	s0,16(sp)
    80005d60:	64a2                	ld	s1,8(sp)
    80005d62:	6105                	addi	sp,sp,32
    80005d64:	8082                	ret

0000000080005d66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d66:	1141                	addi	sp,sp,-16
    80005d68:	e406                	sd	ra,8(sp)
    80005d6a:	e022                	sd	s0,0(sp)
    80005d6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d6e:	479d                	li	a5,7
    80005d70:	04a7cc63          	blt	a5,a0,80005dc8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d74:	0001c797          	auipc	a5,0x1c
    80005d78:	f0c78793          	addi	a5,a5,-244 # 80021c80 <disk>
    80005d7c:	97aa                	add	a5,a5,a0
    80005d7e:	0187c783          	lbu	a5,24(a5)
    80005d82:	ebb9                	bnez	a5,80005dd8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d84:	00451613          	slli	a2,a0,0x4
    80005d88:	0001c797          	auipc	a5,0x1c
    80005d8c:	ef878793          	addi	a5,a5,-264 # 80021c80 <disk>
    80005d90:	6394                	ld	a3,0(a5)
    80005d92:	96b2                	add	a3,a3,a2
    80005d94:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d98:	6398                	ld	a4,0(a5)
    80005d9a:	9732                	add	a4,a4,a2
    80005d9c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005da0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005da4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005da8:	953e                	add	a0,a0,a5
    80005daa:	4785                	li	a5,1
    80005dac:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005db0:	0001c517          	auipc	a0,0x1c
    80005db4:	ee850513          	addi	a0,a0,-280 # 80021c98 <disk+0x18>
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	316080e7          	jalr	790(ra) # 800020ce <wakeup>
}
    80005dc0:	60a2                	ld	ra,8(sp)
    80005dc2:	6402                	ld	s0,0(sp)
    80005dc4:	0141                	addi	sp,sp,16
    80005dc6:	8082                	ret
    panic("free_desc 1");
    80005dc8:	00003517          	auipc	a0,0x3
    80005dcc:	9d850513          	addi	a0,a0,-1576 # 800087a0 <syscalls+0x2f8>
    80005dd0:	ffffa097          	auipc	ra,0xffffa
    80005dd4:	774080e7          	jalr	1908(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005dd8:	00003517          	auipc	a0,0x3
    80005ddc:	9d850513          	addi	a0,a0,-1576 # 800087b0 <syscalls+0x308>
    80005de0:	ffffa097          	auipc	ra,0xffffa
    80005de4:	764080e7          	jalr	1892(ra) # 80000544 <panic>

0000000080005de8 <virtio_disk_init>:
{
    80005de8:	1101                	addi	sp,sp,-32
    80005dea:	ec06                	sd	ra,24(sp)
    80005dec:	e822                	sd	s0,16(sp)
    80005dee:	e426                	sd	s1,8(sp)
    80005df0:	e04a                	sd	s2,0(sp)
    80005df2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005df4:	00003597          	auipc	a1,0x3
    80005df8:	9cc58593          	addi	a1,a1,-1588 # 800087c0 <syscalls+0x318>
    80005dfc:	0001c517          	auipc	a0,0x1c
    80005e00:	fac50513          	addi	a0,a0,-84 # 80021da8 <disk+0x128>
    80005e04:	ffffb097          	auipc	ra,0xffffb
    80005e08:	d56080e7          	jalr	-682(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e0c:	100017b7          	lui	a5,0x10001
    80005e10:	4398                	lw	a4,0(a5)
    80005e12:	2701                	sext.w	a4,a4
    80005e14:	747277b7          	lui	a5,0x74727
    80005e18:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e1c:	14f71e63          	bne	a4,a5,80005f78 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e20:	100017b7          	lui	a5,0x10001
    80005e24:	43dc                	lw	a5,4(a5)
    80005e26:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e28:	4709                	li	a4,2
    80005e2a:	14e79763          	bne	a5,a4,80005f78 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e2e:	100017b7          	lui	a5,0x10001
    80005e32:	479c                	lw	a5,8(a5)
    80005e34:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e36:	14e79163          	bne	a5,a4,80005f78 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e3a:	100017b7          	lui	a5,0x10001
    80005e3e:	47d8                	lw	a4,12(a5)
    80005e40:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e42:	554d47b7          	lui	a5,0x554d4
    80005e46:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e4a:	12f71763          	bne	a4,a5,80005f78 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e4e:	100017b7          	lui	a5,0x10001
    80005e52:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e56:	4705                	li	a4,1
    80005e58:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e5a:	470d                	li	a4,3
    80005e5c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e5e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e60:	c7ffe737          	lui	a4,0xc7ffe
    80005e64:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc99f>
    80005e68:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e6a:	2701                	sext.w	a4,a4
    80005e6c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6e:	472d                	li	a4,11
    80005e70:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e72:	0707a903          	lw	s2,112(a5)
    80005e76:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e78:	00897793          	andi	a5,s2,8
    80005e7c:	10078663          	beqz	a5,80005f88 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e80:	100017b7          	lui	a5,0x10001
    80005e84:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005e88:	43fc                	lw	a5,68(a5)
    80005e8a:	2781                	sext.w	a5,a5
    80005e8c:	10079663          	bnez	a5,80005f98 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e90:	100017b7          	lui	a5,0x10001
    80005e94:	5bdc                	lw	a5,52(a5)
    80005e96:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e98:	10078863          	beqz	a5,80005fa8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005e9c:	471d                	li	a4,7
    80005e9e:	10f77d63          	bgeu	a4,a5,80005fb8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005ea2:	ffffb097          	auipc	ra,0xffffb
    80005ea6:	c58080e7          	jalr	-936(ra) # 80000afa <kalloc>
    80005eaa:	0001c497          	auipc	s1,0x1c
    80005eae:	dd648493          	addi	s1,s1,-554 # 80021c80 <disk>
    80005eb2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005eb4:	ffffb097          	auipc	ra,0xffffb
    80005eb8:	c46080e7          	jalr	-954(ra) # 80000afa <kalloc>
    80005ebc:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005ebe:	ffffb097          	auipc	ra,0xffffb
    80005ec2:	c3c080e7          	jalr	-964(ra) # 80000afa <kalloc>
    80005ec6:	87aa                	mv	a5,a0
    80005ec8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005eca:	6088                	ld	a0,0(s1)
    80005ecc:	cd75                	beqz	a0,80005fc8 <virtio_disk_init+0x1e0>
    80005ece:	0001c717          	auipc	a4,0x1c
    80005ed2:	dba73703          	ld	a4,-582(a4) # 80021c88 <disk+0x8>
    80005ed6:	cb6d                	beqz	a4,80005fc8 <virtio_disk_init+0x1e0>
    80005ed8:	cbe5                	beqz	a5,80005fc8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005eda:	6605                	lui	a2,0x1
    80005edc:	4581                	li	a1,0
    80005ede:	ffffb097          	auipc	ra,0xffffb
    80005ee2:	e08080e7          	jalr	-504(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005ee6:	0001c497          	auipc	s1,0x1c
    80005eea:	d9a48493          	addi	s1,s1,-614 # 80021c80 <disk>
    80005eee:	6605                	lui	a2,0x1
    80005ef0:	4581                	li	a1,0
    80005ef2:	6488                	ld	a0,8(s1)
    80005ef4:	ffffb097          	auipc	ra,0xffffb
    80005ef8:	df2080e7          	jalr	-526(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005efc:	6605                	lui	a2,0x1
    80005efe:	4581                	li	a1,0
    80005f00:	6888                	ld	a0,16(s1)
    80005f02:	ffffb097          	auipc	ra,0xffffb
    80005f06:	de4080e7          	jalr	-540(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f0a:	100017b7          	lui	a5,0x10001
    80005f0e:	4721                	li	a4,8
    80005f10:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f12:	4098                	lw	a4,0(s1)
    80005f14:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f18:	40d8                	lw	a4,4(s1)
    80005f1a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f1e:	6498                	ld	a4,8(s1)
    80005f20:	0007069b          	sext.w	a3,a4
    80005f24:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f28:	9701                	srai	a4,a4,0x20
    80005f2a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f2e:	6898                	ld	a4,16(s1)
    80005f30:	0007069b          	sext.w	a3,a4
    80005f34:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f38:	9701                	srai	a4,a4,0x20
    80005f3a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f3e:	4685                	li	a3,1
    80005f40:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80005f42:	4705                	li	a4,1
    80005f44:	00d48c23          	sb	a3,24(s1)
    80005f48:	00e48ca3          	sb	a4,25(s1)
    80005f4c:	00e48d23          	sb	a4,26(s1)
    80005f50:	00e48da3          	sb	a4,27(s1)
    80005f54:	00e48e23          	sb	a4,28(s1)
    80005f58:	00e48ea3          	sb	a4,29(s1)
    80005f5c:	00e48f23          	sb	a4,30(s1)
    80005f60:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f64:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f68:	0727a823          	sw	s2,112(a5)
}
    80005f6c:	60e2                	ld	ra,24(sp)
    80005f6e:	6442                	ld	s0,16(sp)
    80005f70:	64a2                	ld	s1,8(sp)
    80005f72:	6902                	ld	s2,0(sp)
    80005f74:	6105                	addi	sp,sp,32
    80005f76:	8082                	ret
    panic("could not find virtio disk");
    80005f78:	00003517          	auipc	a0,0x3
    80005f7c:	85850513          	addi	a0,a0,-1960 # 800087d0 <syscalls+0x328>
    80005f80:	ffffa097          	auipc	ra,0xffffa
    80005f84:	5c4080e7          	jalr	1476(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005f88:	00003517          	auipc	a0,0x3
    80005f8c:	86850513          	addi	a0,a0,-1944 # 800087f0 <syscalls+0x348>
    80005f90:	ffffa097          	auipc	ra,0xffffa
    80005f94:	5b4080e7          	jalr	1460(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80005f98:	00003517          	auipc	a0,0x3
    80005f9c:	87850513          	addi	a0,a0,-1928 # 80008810 <syscalls+0x368>
    80005fa0:	ffffa097          	auipc	ra,0xffffa
    80005fa4:	5a4080e7          	jalr	1444(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80005fa8:	00003517          	auipc	a0,0x3
    80005fac:	88850513          	addi	a0,a0,-1912 # 80008830 <syscalls+0x388>
    80005fb0:	ffffa097          	auipc	ra,0xffffa
    80005fb4:	594080e7          	jalr	1428(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80005fb8:	00003517          	auipc	a0,0x3
    80005fbc:	89850513          	addi	a0,a0,-1896 # 80008850 <syscalls+0x3a8>
    80005fc0:	ffffa097          	auipc	ra,0xffffa
    80005fc4:	584080e7          	jalr	1412(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80005fc8:	00003517          	auipc	a0,0x3
    80005fcc:	8a850513          	addi	a0,a0,-1880 # 80008870 <syscalls+0x3c8>
    80005fd0:	ffffa097          	auipc	ra,0xffffa
    80005fd4:	574080e7          	jalr	1396(ra) # 80000544 <panic>

0000000080005fd8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fd8:	7159                	addi	sp,sp,-112
    80005fda:	f486                	sd	ra,104(sp)
    80005fdc:	f0a2                	sd	s0,96(sp)
    80005fde:	eca6                	sd	s1,88(sp)
    80005fe0:	e8ca                	sd	s2,80(sp)
    80005fe2:	e4ce                	sd	s3,72(sp)
    80005fe4:	e0d2                	sd	s4,64(sp)
    80005fe6:	fc56                	sd	s5,56(sp)
    80005fe8:	f85a                	sd	s6,48(sp)
    80005fea:	f45e                	sd	s7,40(sp)
    80005fec:	f062                	sd	s8,32(sp)
    80005fee:	ec66                	sd	s9,24(sp)
    80005ff0:	e86a                	sd	s10,16(sp)
    80005ff2:	1880                	addi	s0,sp,112
    80005ff4:	892a                	mv	s2,a0
    80005ff6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ff8:	00c52c83          	lw	s9,12(a0)
    80005ffc:	001c9c9b          	slliw	s9,s9,0x1
    80006000:	1c82                	slli	s9,s9,0x20
    80006002:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006006:	0001c517          	auipc	a0,0x1c
    8000600a:	da250513          	addi	a0,a0,-606 # 80021da8 <disk+0x128>
    8000600e:	ffffb097          	auipc	ra,0xffffb
    80006012:	bdc080e7          	jalr	-1060(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006016:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006018:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000601a:	0001cb17          	auipc	s6,0x1c
    8000601e:	c66b0b13          	addi	s6,s6,-922 # 80021c80 <disk>
  for(int i = 0; i < 3; i++){
    80006022:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006024:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006026:	0001cc17          	auipc	s8,0x1c
    8000602a:	d82c0c13          	addi	s8,s8,-638 # 80021da8 <disk+0x128>
    8000602e:	a8b5                	j	800060aa <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006030:	00fb06b3          	add	a3,s6,a5
    80006034:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006038:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000603a:	0207c563          	bltz	a5,80006064 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000603e:	2485                	addiw	s1,s1,1
    80006040:	0711                	addi	a4,a4,4
    80006042:	1f548a63          	beq	s1,s5,80006236 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006046:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006048:	0001c697          	auipc	a3,0x1c
    8000604c:	c3868693          	addi	a3,a3,-968 # 80021c80 <disk>
    80006050:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006052:	0186c583          	lbu	a1,24(a3)
    80006056:	fde9                	bnez	a1,80006030 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006058:	2785                	addiw	a5,a5,1
    8000605a:	0685                	addi	a3,a3,1
    8000605c:	ff779be3          	bne	a5,s7,80006052 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006060:	57fd                	li	a5,-1
    80006062:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006064:	02905a63          	blez	s1,80006098 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006068:	f9042503          	lw	a0,-112(s0)
    8000606c:	00000097          	auipc	ra,0x0
    80006070:	cfa080e7          	jalr	-774(ra) # 80005d66 <free_desc>
      for(int j = 0; j < i; j++)
    80006074:	4785                	li	a5,1
    80006076:	0297d163          	bge	a5,s1,80006098 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000607a:	f9442503          	lw	a0,-108(s0)
    8000607e:	00000097          	auipc	ra,0x0
    80006082:	ce8080e7          	jalr	-792(ra) # 80005d66 <free_desc>
      for(int j = 0; j < i; j++)
    80006086:	4789                	li	a5,2
    80006088:	0097d863          	bge	a5,s1,80006098 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000608c:	f9842503          	lw	a0,-104(s0)
    80006090:	00000097          	auipc	ra,0x0
    80006094:	cd6080e7          	jalr	-810(ra) # 80005d66 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006098:	85e2                	mv	a1,s8
    8000609a:	0001c517          	auipc	a0,0x1c
    8000609e:	bfe50513          	addi	a0,a0,-1026 # 80021c98 <disk+0x18>
    800060a2:	ffffc097          	auipc	ra,0xffffc
    800060a6:	fc8080e7          	jalr	-56(ra) # 8000206a <sleep>
  for(int i = 0; i < 3; i++){
    800060aa:	f9040713          	addi	a4,s0,-112
    800060ae:	84ce                	mv	s1,s3
    800060b0:	bf59                	j	80006046 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800060b2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800060b6:	00479693          	slli	a3,a5,0x4
    800060ba:	0001c797          	auipc	a5,0x1c
    800060be:	bc678793          	addi	a5,a5,-1082 # 80021c80 <disk>
    800060c2:	97b6                	add	a5,a5,a3
    800060c4:	4685                	li	a3,1
    800060c6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800060c8:	0001c597          	auipc	a1,0x1c
    800060cc:	bb858593          	addi	a1,a1,-1096 # 80021c80 <disk>
    800060d0:	00a60793          	addi	a5,a2,10
    800060d4:	0792                	slli	a5,a5,0x4
    800060d6:	97ae                	add	a5,a5,a1
    800060d8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800060dc:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060e0:	f6070693          	addi	a3,a4,-160
    800060e4:	619c                	ld	a5,0(a1)
    800060e6:	97b6                	add	a5,a5,a3
    800060e8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060ea:	6188                	ld	a0,0(a1)
    800060ec:	96aa                	add	a3,a3,a0
    800060ee:	47c1                	li	a5,16
    800060f0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060f2:	4785                	li	a5,1
    800060f4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800060f8:	f9442783          	lw	a5,-108(s0)
    800060fc:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006100:	0792                	slli	a5,a5,0x4
    80006102:	953e                	add	a0,a0,a5
    80006104:	05890693          	addi	a3,s2,88
    80006108:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000610a:	6188                	ld	a0,0(a1)
    8000610c:	97aa                	add	a5,a5,a0
    8000610e:	40000693          	li	a3,1024
    80006112:	c794                	sw	a3,8(a5)
  if(write)
    80006114:	100d0d63          	beqz	s10,8000622e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006118:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000611c:	00c7d683          	lhu	a3,12(a5)
    80006120:	0016e693          	ori	a3,a3,1
    80006124:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006128:	f9842583          	lw	a1,-104(s0)
    8000612c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006130:	0001c697          	auipc	a3,0x1c
    80006134:	b5068693          	addi	a3,a3,-1200 # 80021c80 <disk>
    80006138:	00260793          	addi	a5,a2,2
    8000613c:	0792                	slli	a5,a5,0x4
    8000613e:	97b6                	add	a5,a5,a3
    80006140:	587d                	li	a6,-1
    80006142:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006146:	0592                	slli	a1,a1,0x4
    80006148:	952e                	add	a0,a0,a1
    8000614a:	f9070713          	addi	a4,a4,-112
    8000614e:	9736                	add	a4,a4,a3
    80006150:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006152:	6298                	ld	a4,0(a3)
    80006154:	972e                	add	a4,a4,a1
    80006156:	4585                	li	a1,1
    80006158:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000615a:	4509                	li	a0,2
    8000615c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006160:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006164:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006168:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000616c:	6698                	ld	a4,8(a3)
    8000616e:	00275783          	lhu	a5,2(a4)
    80006172:	8b9d                	andi	a5,a5,7
    80006174:	0786                	slli	a5,a5,0x1
    80006176:	97ba                	add	a5,a5,a4
    80006178:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000617c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006180:	6698                	ld	a4,8(a3)
    80006182:	00275783          	lhu	a5,2(a4)
    80006186:	2785                	addiw	a5,a5,1
    80006188:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000618c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006190:	100017b7          	lui	a5,0x10001
    80006194:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006198:	00492703          	lw	a4,4(s2)
    8000619c:	4785                	li	a5,1
    8000619e:	02f71163          	bne	a4,a5,800061c0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800061a2:	0001c997          	auipc	s3,0x1c
    800061a6:	c0698993          	addi	s3,s3,-1018 # 80021da8 <disk+0x128>
  while(b->disk == 1) {
    800061aa:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061ac:	85ce                	mv	a1,s3
    800061ae:	854a                	mv	a0,s2
    800061b0:	ffffc097          	auipc	ra,0xffffc
    800061b4:	eba080e7          	jalr	-326(ra) # 8000206a <sleep>
  while(b->disk == 1) {
    800061b8:	00492783          	lw	a5,4(s2)
    800061bc:	fe9788e3          	beq	a5,s1,800061ac <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800061c0:	f9042903          	lw	s2,-112(s0)
    800061c4:	00290793          	addi	a5,s2,2
    800061c8:	00479713          	slli	a4,a5,0x4
    800061cc:	0001c797          	auipc	a5,0x1c
    800061d0:	ab478793          	addi	a5,a5,-1356 # 80021c80 <disk>
    800061d4:	97ba                	add	a5,a5,a4
    800061d6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800061da:	0001c997          	auipc	s3,0x1c
    800061de:	aa698993          	addi	s3,s3,-1370 # 80021c80 <disk>
    800061e2:	00491713          	slli	a4,s2,0x4
    800061e6:	0009b783          	ld	a5,0(s3)
    800061ea:	97ba                	add	a5,a5,a4
    800061ec:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061f0:	854a                	mv	a0,s2
    800061f2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061f6:	00000097          	auipc	ra,0x0
    800061fa:	b70080e7          	jalr	-1168(ra) # 80005d66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061fe:	8885                	andi	s1,s1,1
    80006200:	f0ed                	bnez	s1,800061e2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006202:	0001c517          	auipc	a0,0x1c
    80006206:	ba650513          	addi	a0,a0,-1114 # 80021da8 <disk+0x128>
    8000620a:	ffffb097          	auipc	ra,0xffffb
    8000620e:	a94080e7          	jalr	-1388(ra) # 80000c9e <release>
}
    80006212:	70a6                	ld	ra,104(sp)
    80006214:	7406                	ld	s0,96(sp)
    80006216:	64e6                	ld	s1,88(sp)
    80006218:	6946                	ld	s2,80(sp)
    8000621a:	69a6                	ld	s3,72(sp)
    8000621c:	6a06                	ld	s4,64(sp)
    8000621e:	7ae2                	ld	s5,56(sp)
    80006220:	7b42                	ld	s6,48(sp)
    80006222:	7ba2                	ld	s7,40(sp)
    80006224:	7c02                	ld	s8,32(sp)
    80006226:	6ce2                	ld	s9,24(sp)
    80006228:	6d42                	ld	s10,16(sp)
    8000622a:	6165                	addi	sp,sp,112
    8000622c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000622e:	4689                	li	a3,2
    80006230:	00d79623          	sh	a3,12(a5)
    80006234:	b5e5                	j	8000611c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006236:	f9042603          	lw	a2,-112(s0)
    8000623a:	00a60713          	addi	a4,a2,10
    8000623e:	0712                	slli	a4,a4,0x4
    80006240:	0001c517          	auipc	a0,0x1c
    80006244:	a4850513          	addi	a0,a0,-1464 # 80021c88 <disk+0x8>
    80006248:	953a                	add	a0,a0,a4
  if(write)
    8000624a:	e60d14e3          	bnez	s10,800060b2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000624e:	00a60793          	addi	a5,a2,10
    80006252:	00479693          	slli	a3,a5,0x4
    80006256:	0001c797          	auipc	a5,0x1c
    8000625a:	a2a78793          	addi	a5,a5,-1494 # 80021c80 <disk>
    8000625e:	97b6                	add	a5,a5,a3
    80006260:	0007a423          	sw	zero,8(a5)
    80006264:	b595                	j	800060c8 <virtio_disk_rw+0xf0>

0000000080006266 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006266:	1101                	addi	sp,sp,-32
    80006268:	ec06                	sd	ra,24(sp)
    8000626a:	e822                	sd	s0,16(sp)
    8000626c:	e426                	sd	s1,8(sp)
    8000626e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006270:	0001c497          	auipc	s1,0x1c
    80006274:	a1048493          	addi	s1,s1,-1520 # 80021c80 <disk>
    80006278:	0001c517          	auipc	a0,0x1c
    8000627c:	b3050513          	addi	a0,a0,-1232 # 80021da8 <disk+0x128>
    80006280:	ffffb097          	auipc	ra,0xffffb
    80006284:	96a080e7          	jalr	-1686(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006288:	10001737          	lui	a4,0x10001
    8000628c:	533c                	lw	a5,96(a4)
    8000628e:	8b8d                	andi	a5,a5,3
    80006290:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006292:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006296:	689c                	ld	a5,16(s1)
    80006298:	0204d703          	lhu	a4,32(s1)
    8000629c:	0027d783          	lhu	a5,2(a5)
    800062a0:	04f70863          	beq	a4,a5,800062f0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062a4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062a8:	6898                	ld	a4,16(s1)
    800062aa:	0204d783          	lhu	a5,32(s1)
    800062ae:	8b9d                	andi	a5,a5,7
    800062b0:	078e                	slli	a5,a5,0x3
    800062b2:	97ba                	add	a5,a5,a4
    800062b4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062b6:	00278713          	addi	a4,a5,2
    800062ba:	0712                	slli	a4,a4,0x4
    800062bc:	9726                	add	a4,a4,s1
    800062be:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800062c2:	e721                	bnez	a4,8000630a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062c4:	0789                	addi	a5,a5,2
    800062c6:	0792                	slli	a5,a5,0x4
    800062c8:	97a6                	add	a5,a5,s1
    800062ca:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800062cc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062d0:	ffffc097          	auipc	ra,0xffffc
    800062d4:	dfe080e7          	jalr	-514(ra) # 800020ce <wakeup>

    disk.used_idx += 1;
    800062d8:	0204d783          	lhu	a5,32(s1)
    800062dc:	2785                	addiw	a5,a5,1
    800062de:	17c2                	slli	a5,a5,0x30
    800062e0:	93c1                	srli	a5,a5,0x30
    800062e2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062e6:	6898                	ld	a4,16(s1)
    800062e8:	00275703          	lhu	a4,2(a4)
    800062ec:	faf71ce3          	bne	a4,a5,800062a4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800062f0:	0001c517          	auipc	a0,0x1c
    800062f4:	ab850513          	addi	a0,a0,-1352 # 80021da8 <disk+0x128>
    800062f8:	ffffb097          	auipc	ra,0xffffb
    800062fc:	9a6080e7          	jalr	-1626(ra) # 80000c9e <release>
}
    80006300:	60e2                	ld	ra,24(sp)
    80006302:	6442                	ld	s0,16(sp)
    80006304:	64a2                	ld	s1,8(sp)
    80006306:	6105                	addi	sp,sp,32
    80006308:	8082                	ret
      panic("virtio_disk_intr status");
    8000630a:	00002517          	auipc	a0,0x2
    8000630e:	57e50513          	addi	a0,a0,1406 # 80008888 <syscalls+0x3e0>
    80006312:	ffffa097          	auipc	ra,0xffffa
    80006316:	232080e7          	jalr	562(ra) # 80000544 <panic>
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

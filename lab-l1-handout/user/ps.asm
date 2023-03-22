
user/_ps:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	1000                	addi	s0,sp,32
    if(argc < 2)
   a:	4785                	li	a5,1
   c:	02a7d963          	bge	a5,a0,3e <main+0x3e>
  10:	84ae                	mv	s1,a1
        scps();
        exit(0);
    }
    else
    {
        printf("no arguments allowed\n");
  12:	00000517          	auipc	a0,0x0
  16:	7fe50513          	addi	a0,a0,2046 # 810 <malloc+0xf2>
  1a:	00000097          	auipc	ra,0x0
  1e:	646080e7          	jalr	1606(ra) # 660 <printf>
        printf("Usage: %s", argv[0]);
  22:	608c                	ld	a1,0(s1)
  24:	00001517          	auipc	a0,0x1
  28:	80450513          	addi	a0,a0,-2044 # 828 <malloc+0x10a>
  2c:	00000097          	auipc	ra,0x0
  30:	634080e7          	jalr	1588(ra) # 660 <printf>
        exit(1);
  34:	4505                	li	a0,1
  36:	00000097          	auipc	ra,0x0
  3a:	2aa080e7          	jalr	682(ra) # 2e0 <exit>
        scps();
  3e:	00000097          	auipc	ra,0x0
  42:	342080e7          	jalr	834(ra) # 380 <scps>
        exit(0);
  46:	4501                	li	a0,0
  48:	00000097          	auipc	ra,0x0
  4c:	298080e7          	jalr	664(ra) # 2e0 <exit>

0000000000000050 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  50:	1141                	addi	sp,sp,-16
  52:	e406                	sd	ra,8(sp)
  54:	e022                	sd	s0,0(sp)
  56:	0800                	addi	s0,sp,16
  extern int main();
  main();
  58:	00000097          	auipc	ra,0x0
  5c:	fa8080e7          	jalr	-88(ra) # 0 <main>
  exit(0);
  60:	4501                	li	a0,0
  62:	00000097          	auipc	ra,0x0
  66:	27e080e7          	jalr	638(ra) # 2e0 <exit>

000000000000006a <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  6a:	1141                	addi	sp,sp,-16
  6c:	e422                	sd	s0,8(sp)
  6e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  70:	87aa                	mv	a5,a0
  72:	0585                	addi	a1,a1,1
  74:	0785                	addi	a5,a5,1
  76:	fff5c703          	lbu	a4,-1(a1)
  7a:	fee78fa3          	sb	a4,-1(a5)
  7e:	fb75                	bnez	a4,72 <strcpy+0x8>
    ;
  return os;
}
  80:	6422                	ld	s0,8(sp)
  82:	0141                	addi	sp,sp,16
  84:	8082                	ret

0000000000000086 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  86:	1141                	addi	sp,sp,-16
  88:	e422                	sd	s0,8(sp)
  8a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  8c:	00054783          	lbu	a5,0(a0)
  90:	cb91                	beqz	a5,a4 <strcmp+0x1e>
  92:	0005c703          	lbu	a4,0(a1)
  96:	00f71763          	bne	a4,a5,a4 <strcmp+0x1e>
    p++, q++;
  9a:	0505                	addi	a0,a0,1
  9c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  9e:	00054783          	lbu	a5,0(a0)
  a2:	fbe5                	bnez	a5,92 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  a4:	0005c503          	lbu	a0,0(a1)
}
  a8:	40a7853b          	subw	a0,a5,a0
  ac:	6422                	ld	s0,8(sp)
  ae:	0141                	addi	sp,sp,16
  b0:	8082                	ret

00000000000000b2 <strlen>:

uint
strlen(const char *s)
{
  b2:	1141                	addi	sp,sp,-16
  b4:	e422                	sd	s0,8(sp)
  b6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  b8:	00054783          	lbu	a5,0(a0)
  bc:	cf91                	beqz	a5,d8 <strlen+0x26>
  be:	0505                	addi	a0,a0,1
  c0:	87aa                	mv	a5,a0
  c2:	4685                	li	a3,1
  c4:	9e89                	subw	a3,a3,a0
  c6:	00f6853b          	addw	a0,a3,a5
  ca:	0785                	addi	a5,a5,1
  cc:	fff7c703          	lbu	a4,-1(a5)
  d0:	fb7d                	bnez	a4,c6 <strlen+0x14>
    ;
  return n;
}
  d2:	6422                	ld	s0,8(sp)
  d4:	0141                	addi	sp,sp,16
  d6:	8082                	ret
  for(n = 0; s[n]; n++)
  d8:	4501                	li	a0,0
  da:	bfe5                	j	d2 <strlen+0x20>

00000000000000dc <memset>:

void*
memset(void *dst, int c, uint n)
{
  dc:	1141                	addi	sp,sp,-16
  de:	e422                	sd	s0,8(sp)
  e0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  e2:	ce09                	beqz	a2,fc <memset+0x20>
  e4:	87aa                	mv	a5,a0
  e6:	fff6071b          	addiw	a4,a2,-1
  ea:	1702                	slli	a4,a4,0x20
  ec:	9301                	srli	a4,a4,0x20
  ee:	0705                	addi	a4,a4,1
  f0:	972a                	add	a4,a4,a0
    cdst[i] = c;
  f2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  f6:	0785                	addi	a5,a5,1
  f8:	fee79de3          	bne	a5,a4,f2 <memset+0x16>
  }
  return dst;
}
  fc:	6422                	ld	s0,8(sp)
  fe:	0141                	addi	sp,sp,16
 100:	8082                	ret

0000000000000102 <strchr>:

char*
strchr(const char *s, char c)
{
 102:	1141                	addi	sp,sp,-16
 104:	e422                	sd	s0,8(sp)
 106:	0800                	addi	s0,sp,16
  for(; *s; s++)
 108:	00054783          	lbu	a5,0(a0)
 10c:	cb99                	beqz	a5,122 <strchr+0x20>
    if(*s == c)
 10e:	00f58763          	beq	a1,a5,11c <strchr+0x1a>
  for(; *s; s++)
 112:	0505                	addi	a0,a0,1
 114:	00054783          	lbu	a5,0(a0)
 118:	fbfd                	bnez	a5,10e <strchr+0xc>
      return (char*)s;
  return 0;
 11a:	4501                	li	a0,0
}
 11c:	6422                	ld	s0,8(sp)
 11e:	0141                	addi	sp,sp,16
 120:	8082                	ret
  return 0;
 122:	4501                	li	a0,0
 124:	bfe5                	j	11c <strchr+0x1a>

0000000000000126 <gets>:

char*
gets(char *buf, int max)
{
 126:	711d                	addi	sp,sp,-96
 128:	ec86                	sd	ra,88(sp)
 12a:	e8a2                	sd	s0,80(sp)
 12c:	e4a6                	sd	s1,72(sp)
 12e:	e0ca                	sd	s2,64(sp)
 130:	fc4e                	sd	s3,56(sp)
 132:	f852                	sd	s4,48(sp)
 134:	f456                	sd	s5,40(sp)
 136:	f05a                	sd	s6,32(sp)
 138:	ec5e                	sd	s7,24(sp)
 13a:	1080                	addi	s0,sp,96
 13c:	8baa                	mv	s7,a0
 13e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 140:	892a                	mv	s2,a0
 142:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 144:	4aa9                	li	s5,10
 146:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 148:	89a6                	mv	s3,s1
 14a:	2485                	addiw	s1,s1,1
 14c:	0344d863          	bge	s1,s4,17c <gets+0x56>
    cc = read(0, &c, 1);
 150:	4605                	li	a2,1
 152:	faf40593          	addi	a1,s0,-81
 156:	4501                	li	a0,0
 158:	00000097          	auipc	ra,0x0
 15c:	1a0080e7          	jalr	416(ra) # 2f8 <read>
    if(cc < 1)
 160:	00a05e63          	blez	a0,17c <gets+0x56>
    buf[i++] = c;
 164:	faf44783          	lbu	a5,-81(s0)
 168:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 16c:	01578763          	beq	a5,s5,17a <gets+0x54>
 170:	0905                	addi	s2,s2,1
 172:	fd679be3          	bne	a5,s6,148 <gets+0x22>
  for(i=0; i+1 < max; ){
 176:	89a6                	mv	s3,s1
 178:	a011                	j	17c <gets+0x56>
 17a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 17c:	99de                	add	s3,s3,s7
 17e:	00098023          	sb	zero,0(s3)
  return buf;
}
 182:	855e                	mv	a0,s7
 184:	60e6                	ld	ra,88(sp)
 186:	6446                	ld	s0,80(sp)
 188:	64a6                	ld	s1,72(sp)
 18a:	6906                	ld	s2,64(sp)
 18c:	79e2                	ld	s3,56(sp)
 18e:	7a42                	ld	s4,48(sp)
 190:	7aa2                	ld	s5,40(sp)
 192:	7b02                	ld	s6,32(sp)
 194:	6be2                	ld	s7,24(sp)
 196:	6125                	addi	sp,sp,96
 198:	8082                	ret

000000000000019a <stat>:

int
stat(const char *n, struct stat *st)
{
 19a:	1101                	addi	sp,sp,-32
 19c:	ec06                	sd	ra,24(sp)
 19e:	e822                	sd	s0,16(sp)
 1a0:	e426                	sd	s1,8(sp)
 1a2:	e04a                	sd	s2,0(sp)
 1a4:	1000                	addi	s0,sp,32
 1a6:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1a8:	4581                	li	a1,0
 1aa:	00000097          	auipc	ra,0x0
 1ae:	176080e7          	jalr	374(ra) # 320 <open>
  if(fd < 0)
 1b2:	02054563          	bltz	a0,1dc <stat+0x42>
 1b6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1b8:	85ca                	mv	a1,s2
 1ba:	00000097          	auipc	ra,0x0
 1be:	17e080e7          	jalr	382(ra) # 338 <fstat>
 1c2:	892a                	mv	s2,a0
  close(fd);
 1c4:	8526                	mv	a0,s1
 1c6:	00000097          	auipc	ra,0x0
 1ca:	142080e7          	jalr	322(ra) # 308 <close>
  return r;
}
 1ce:	854a                	mv	a0,s2
 1d0:	60e2                	ld	ra,24(sp)
 1d2:	6442                	ld	s0,16(sp)
 1d4:	64a2                	ld	s1,8(sp)
 1d6:	6902                	ld	s2,0(sp)
 1d8:	6105                	addi	sp,sp,32
 1da:	8082                	ret
    return -1;
 1dc:	597d                	li	s2,-1
 1de:	bfc5                	j	1ce <stat+0x34>

00000000000001e0 <atoi>:

int
atoi(const char *s)
{
 1e0:	1141                	addi	sp,sp,-16
 1e2:	e422                	sd	s0,8(sp)
 1e4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1e6:	00054603          	lbu	a2,0(a0)
 1ea:	fd06079b          	addiw	a5,a2,-48
 1ee:	0ff7f793          	andi	a5,a5,255
 1f2:	4725                	li	a4,9
 1f4:	02f76963          	bltu	a4,a5,226 <atoi+0x46>
 1f8:	86aa                	mv	a3,a0
  n = 0;
 1fa:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1fc:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 1fe:	0685                	addi	a3,a3,1
 200:	0025179b          	slliw	a5,a0,0x2
 204:	9fa9                	addw	a5,a5,a0
 206:	0017979b          	slliw	a5,a5,0x1
 20a:	9fb1                	addw	a5,a5,a2
 20c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 210:	0006c603          	lbu	a2,0(a3)
 214:	fd06071b          	addiw	a4,a2,-48
 218:	0ff77713          	andi	a4,a4,255
 21c:	fee5f1e3          	bgeu	a1,a4,1fe <atoi+0x1e>
  return n;
}
 220:	6422                	ld	s0,8(sp)
 222:	0141                	addi	sp,sp,16
 224:	8082                	ret
  n = 0;
 226:	4501                	li	a0,0
 228:	bfe5                	j	220 <atoi+0x40>

000000000000022a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 22a:	1141                	addi	sp,sp,-16
 22c:	e422                	sd	s0,8(sp)
 22e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 230:	02b57663          	bgeu	a0,a1,25c <memmove+0x32>
    while(n-- > 0)
 234:	02c05163          	blez	a2,256 <memmove+0x2c>
 238:	fff6079b          	addiw	a5,a2,-1
 23c:	1782                	slli	a5,a5,0x20
 23e:	9381                	srli	a5,a5,0x20
 240:	0785                	addi	a5,a5,1
 242:	97aa                	add	a5,a5,a0
  dst = vdst;
 244:	872a                	mv	a4,a0
      *dst++ = *src++;
 246:	0585                	addi	a1,a1,1
 248:	0705                	addi	a4,a4,1
 24a:	fff5c683          	lbu	a3,-1(a1)
 24e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 252:	fee79ae3          	bne	a5,a4,246 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 256:	6422                	ld	s0,8(sp)
 258:	0141                	addi	sp,sp,16
 25a:	8082                	ret
    dst += n;
 25c:	00c50733          	add	a4,a0,a2
    src += n;
 260:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 262:	fec05ae3          	blez	a2,256 <memmove+0x2c>
 266:	fff6079b          	addiw	a5,a2,-1
 26a:	1782                	slli	a5,a5,0x20
 26c:	9381                	srli	a5,a5,0x20
 26e:	fff7c793          	not	a5,a5
 272:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 274:	15fd                	addi	a1,a1,-1
 276:	177d                	addi	a4,a4,-1
 278:	0005c683          	lbu	a3,0(a1)
 27c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 280:	fee79ae3          	bne	a5,a4,274 <memmove+0x4a>
 284:	bfc9                	j	256 <memmove+0x2c>

0000000000000286 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 286:	1141                	addi	sp,sp,-16
 288:	e422                	sd	s0,8(sp)
 28a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 28c:	ca05                	beqz	a2,2bc <memcmp+0x36>
 28e:	fff6069b          	addiw	a3,a2,-1
 292:	1682                	slli	a3,a3,0x20
 294:	9281                	srli	a3,a3,0x20
 296:	0685                	addi	a3,a3,1
 298:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 29a:	00054783          	lbu	a5,0(a0)
 29e:	0005c703          	lbu	a4,0(a1)
 2a2:	00e79863          	bne	a5,a4,2b2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2a6:	0505                	addi	a0,a0,1
    p2++;
 2a8:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2aa:	fed518e3          	bne	a0,a3,29a <memcmp+0x14>
  }
  return 0;
 2ae:	4501                	li	a0,0
 2b0:	a019                	j	2b6 <memcmp+0x30>
      return *p1 - *p2;
 2b2:	40e7853b          	subw	a0,a5,a4
}
 2b6:	6422                	ld	s0,8(sp)
 2b8:	0141                	addi	sp,sp,16
 2ba:	8082                	ret
  return 0;
 2bc:	4501                	li	a0,0
 2be:	bfe5                	j	2b6 <memcmp+0x30>

00000000000002c0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2c0:	1141                	addi	sp,sp,-16
 2c2:	e406                	sd	ra,8(sp)
 2c4:	e022                	sd	s0,0(sp)
 2c6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2c8:	00000097          	auipc	ra,0x0
 2cc:	f62080e7          	jalr	-158(ra) # 22a <memmove>
}
 2d0:	60a2                	ld	ra,8(sp)
 2d2:	6402                	ld	s0,0(sp)
 2d4:	0141                	addi	sp,sp,16
 2d6:	8082                	ret

00000000000002d8 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2d8:	4885                	li	a7,1
 ecall
 2da:	00000073          	ecall
 ret
 2de:	8082                	ret

00000000000002e0 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2e0:	4889                	li	a7,2
 ecall
 2e2:	00000073          	ecall
 ret
 2e6:	8082                	ret

00000000000002e8 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2e8:	488d                	li	a7,3
 ecall
 2ea:	00000073          	ecall
 ret
 2ee:	8082                	ret

00000000000002f0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2f0:	4891                	li	a7,4
 ecall
 2f2:	00000073          	ecall
 ret
 2f6:	8082                	ret

00000000000002f8 <read>:
.global read
read:
 li a7, SYS_read
 2f8:	4895                	li	a7,5
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <write>:
.global write
write:
 li a7, SYS_write
 300:	48c1                	li	a7,16
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <close>:
.global close
close:
 li a7, SYS_close
 308:	48d5                	li	a7,21
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <kill>:
.global kill
kill:
 li a7, SYS_kill
 310:	4899                	li	a7,6
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <exec>:
.global exec
exec:
 li a7, SYS_exec
 318:	489d                	li	a7,7
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <open>:
.global open
open:
 li a7, SYS_open
 320:	48bd                	li	a7,15
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 328:	48c5                	li	a7,17
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 330:	48c9                	li	a7,18
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 338:	48a1                	li	a7,8
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <link>:
.global link
link:
 li a7, SYS_link
 340:	48cd                	li	a7,19
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 348:	48d1                	li	a7,20
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 350:	48a5                	li	a7,9
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <dup>:
.global dup
dup:
 li a7, SYS_dup
 358:	48a9                	li	a7,10
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 360:	48ad                	li	a7,11
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 368:	48b1                	li	a7,12
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 370:	48b5                	li	a7,13
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 378:	48b9                	li	a7,14
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <scps>:
.global scps
scps:
 li a7, SYS_scps
 380:	48d9                	li	a7,22
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 388:	1101                	addi	sp,sp,-32
 38a:	ec06                	sd	ra,24(sp)
 38c:	e822                	sd	s0,16(sp)
 38e:	1000                	addi	s0,sp,32
 390:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 394:	4605                	li	a2,1
 396:	fef40593          	addi	a1,s0,-17
 39a:	00000097          	auipc	ra,0x0
 39e:	f66080e7          	jalr	-154(ra) # 300 <write>
}
 3a2:	60e2                	ld	ra,24(sp)
 3a4:	6442                	ld	s0,16(sp)
 3a6:	6105                	addi	sp,sp,32
 3a8:	8082                	ret

00000000000003aa <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3aa:	7139                	addi	sp,sp,-64
 3ac:	fc06                	sd	ra,56(sp)
 3ae:	f822                	sd	s0,48(sp)
 3b0:	f426                	sd	s1,40(sp)
 3b2:	f04a                	sd	s2,32(sp)
 3b4:	ec4e                	sd	s3,24(sp)
 3b6:	0080                	addi	s0,sp,64
 3b8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3ba:	c299                	beqz	a3,3c0 <printint+0x16>
 3bc:	0805c863          	bltz	a1,44c <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3c0:	2581                	sext.w	a1,a1
  neg = 0;
 3c2:	4881                	li	a7,0
 3c4:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3c8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3ca:	2601                	sext.w	a2,a2
 3cc:	00000517          	auipc	a0,0x0
 3d0:	47450513          	addi	a0,a0,1140 # 840 <digits>
 3d4:	883a                	mv	a6,a4
 3d6:	2705                	addiw	a4,a4,1
 3d8:	02c5f7bb          	remuw	a5,a1,a2
 3dc:	1782                	slli	a5,a5,0x20
 3de:	9381                	srli	a5,a5,0x20
 3e0:	97aa                	add	a5,a5,a0
 3e2:	0007c783          	lbu	a5,0(a5)
 3e6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3ea:	0005879b          	sext.w	a5,a1
 3ee:	02c5d5bb          	divuw	a1,a1,a2
 3f2:	0685                	addi	a3,a3,1
 3f4:	fec7f0e3          	bgeu	a5,a2,3d4 <printint+0x2a>
  if(neg)
 3f8:	00088b63          	beqz	a7,40e <printint+0x64>
    buf[i++] = '-';
 3fc:	fd040793          	addi	a5,s0,-48
 400:	973e                	add	a4,a4,a5
 402:	02d00793          	li	a5,45
 406:	fef70823          	sb	a5,-16(a4)
 40a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 40e:	02e05863          	blez	a4,43e <printint+0x94>
 412:	fc040793          	addi	a5,s0,-64
 416:	00e78933          	add	s2,a5,a4
 41a:	fff78993          	addi	s3,a5,-1
 41e:	99ba                	add	s3,s3,a4
 420:	377d                	addiw	a4,a4,-1
 422:	1702                	slli	a4,a4,0x20
 424:	9301                	srli	a4,a4,0x20
 426:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 42a:	fff94583          	lbu	a1,-1(s2)
 42e:	8526                	mv	a0,s1
 430:	00000097          	auipc	ra,0x0
 434:	f58080e7          	jalr	-168(ra) # 388 <putc>
  while(--i >= 0)
 438:	197d                	addi	s2,s2,-1
 43a:	ff3918e3          	bne	s2,s3,42a <printint+0x80>
}
 43e:	70e2                	ld	ra,56(sp)
 440:	7442                	ld	s0,48(sp)
 442:	74a2                	ld	s1,40(sp)
 444:	7902                	ld	s2,32(sp)
 446:	69e2                	ld	s3,24(sp)
 448:	6121                	addi	sp,sp,64
 44a:	8082                	ret
    x = -xx;
 44c:	40b005bb          	negw	a1,a1
    neg = 1;
 450:	4885                	li	a7,1
    x = -xx;
 452:	bf8d                	j	3c4 <printint+0x1a>

0000000000000454 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 454:	7119                	addi	sp,sp,-128
 456:	fc86                	sd	ra,120(sp)
 458:	f8a2                	sd	s0,112(sp)
 45a:	f4a6                	sd	s1,104(sp)
 45c:	f0ca                	sd	s2,96(sp)
 45e:	ecce                	sd	s3,88(sp)
 460:	e8d2                	sd	s4,80(sp)
 462:	e4d6                	sd	s5,72(sp)
 464:	e0da                	sd	s6,64(sp)
 466:	fc5e                	sd	s7,56(sp)
 468:	f862                	sd	s8,48(sp)
 46a:	f466                	sd	s9,40(sp)
 46c:	f06a                	sd	s10,32(sp)
 46e:	ec6e                	sd	s11,24(sp)
 470:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 472:	0005c903          	lbu	s2,0(a1)
 476:	18090f63          	beqz	s2,614 <vprintf+0x1c0>
 47a:	8aaa                	mv	s5,a0
 47c:	8b32                	mv	s6,a2
 47e:	00158493          	addi	s1,a1,1
  state = 0;
 482:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 484:	02500a13          	li	s4,37
      if(c == 'd'){
 488:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 48c:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 490:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 494:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 498:	00000b97          	auipc	s7,0x0
 49c:	3a8b8b93          	addi	s7,s7,936 # 840 <digits>
 4a0:	a839                	j	4be <vprintf+0x6a>
        putc(fd, c);
 4a2:	85ca                	mv	a1,s2
 4a4:	8556                	mv	a0,s5
 4a6:	00000097          	auipc	ra,0x0
 4aa:	ee2080e7          	jalr	-286(ra) # 388 <putc>
 4ae:	a019                	j	4b4 <vprintf+0x60>
    } else if(state == '%'){
 4b0:	01498f63          	beq	s3,s4,4ce <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4b4:	0485                	addi	s1,s1,1
 4b6:	fff4c903          	lbu	s2,-1(s1)
 4ba:	14090d63          	beqz	s2,614 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 4be:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4c2:	fe0997e3          	bnez	s3,4b0 <vprintf+0x5c>
      if(c == '%'){
 4c6:	fd479ee3          	bne	a5,s4,4a2 <vprintf+0x4e>
        state = '%';
 4ca:	89be                	mv	s3,a5
 4cc:	b7e5                	j	4b4 <vprintf+0x60>
      if(c == 'd'){
 4ce:	05878063          	beq	a5,s8,50e <vprintf+0xba>
      } else if(c == 'l') {
 4d2:	05978c63          	beq	a5,s9,52a <vprintf+0xd6>
      } else if(c == 'x') {
 4d6:	07a78863          	beq	a5,s10,546 <vprintf+0xf2>
      } else if(c == 'p') {
 4da:	09b78463          	beq	a5,s11,562 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 4de:	07300713          	li	a4,115
 4e2:	0ce78663          	beq	a5,a4,5ae <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 4e6:	06300713          	li	a4,99
 4ea:	0ee78e63          	beq	a5,a4,5e6 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 4ee:	11478863          	beq	a5,s4,5fe <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4f2:	85d2                	mv	a1,s4
 4f4:	8556                	mv	a0,s5
 4f6:	00000097          	auipc	ra,0x0
 4fa:	e92080e7          	jalr	-366(ra) # 388 <putc>
        putc(fd, c);
 4fe:	85ca                	mv	a1,s2
 500:	8556                	mv	a0,s5
 502:	00000097          	auipc	ra,0x0
 506:	e86080e7          	jalr	-378(ra) # 388 <putc>
      }
      state = 0;
 50a:	4981                	li	s3,0
 50c:	b765                	j	4b4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 50e:	008b0913          	addi	s2,s6,8
 512:	4685                	li	a3,1
 514:	4629                	li	a2,10
 516:	000b2583          	lw	a1,0(s6)
 51a:	8556                	mv	a0,s5
 51c:	00000097          	auipc	ra,0x0
 520:	e8e080e7          	jalr	-370(ra) # 3aa <printint>
 524:	8b4a                	mv	s6,s2
      state = 0;
 526:	4981                	li	s3,0
 528:	b771                	j	4b4 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 52a:	008b0913          	addi	s2,s6,8
 52e:	4681                	li	a3,0
 530:	4629                	li	a2,10
 532:	000b2583          	lw	a1,0(s6)
 536:	8556                	mv	a0,s5
 538:	00000097          	auipc	ra,0x0
 53c:	e72080e7          	jalr	-398(ra) # 3aa <printint>
 540:	8b4a                	mv	s6,s2
      state = 0;
 542:	4981                	li	s3,0
 544:	bf85                	j	4b4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 546:	008b0913          	addi	s2,s6,8
 54a:	4681                	li	a3,0
 54c:	4641                	li	a2,16
 54e:	000b2583          	lw	a1,0(s6)
 552:	8556                	mv	a0,s5
 554:	00000097          	auipc	ra,0x0
 558:	e56080e7          	jalr	-426(ra) # 3aa <printint>
 55c:	8b4a                	mv	s6,s2
      state = 0;
 55e:	4981                	li	s3,0
 560:	bf91                	j	4b4 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 562:	008b0793          	addi	a5,s6,8
 566:	f8f43423          	sd	a5,-120(s0)
 56a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 56e:	03000593          	li	a1,48
 572:	8556                	mv	a0,s5
 574:	00000097          	auipc	ra,0x0
 578:	e14080e7          	jalr	-492(ra) # 388 <putc>
  putc(fd, 'x');
 57c:	85ea                	mv	a1,s10
 57e:	8556                	mv	a0,s5
 580:	00000097          	auipc	ra,0x0
 584:	e08080e7          	jalr	-504(ra) # 388 <putc>
 588:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 58a:	03c9d793          	srli	a5,s3,0x3c
 58e:	97de                	add	a5,a5,s7
 590:	0007c583          	lbu	a1,0(a5)
 594:	8556                	mv	a0,s5
 596:	00000097          	auipc	ra,0x0
 59a:	df2080e7          	jalr	-526(ra) # 388 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 59e:	0992                	slli	s3,s3,0x4
 5a0:	397d                	addiw	s2,s2,-1
 5a2:	fe0914e3          	bnez	s2,58a <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5a6:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5aa:	4981                	li	s3,0
 5ac:	b721                	j	4b4 <vprintf+0x60>
        s = va_arg(ap, char*);
 5ae:	008b0993          	addi	s3,s6,8
 5b2:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 5b6:	02090163          	beqz	s2,5d8 <vprintf+0x184>
        while(*s != 0){
 5ba:	00094583          	lbu	a1,0(s2)
 5be:	c9a1                	beqz	a1,60e <vprintf+0x1ba>
          putc(fd, *s);
 5c0:	8556                	mv	a0,s5
 5c2:	00000097          	auipc	ra,0x0
 5c6:	dc6080e7          	jalr	-570(ra) # 388 <putc>
          s++;
 5ca:	0905                	addi	s2,s2,1
        while(*s != 0){
 5cc:	00094583          	lbu	a1,0(s2)
 5d0:	f9e5                	bnez	a1,5c0 <vprintf+0x16c>
        s = va_arg(ap, char*);
 5d2:	8b4e                	mv	s6,s3
      state = 0;
 5d4:	4981                	li	s3,0
 5d6:	bdf9                	j	4b4 <vprintf+0x60>
          s = "(null)";
 5d8:	00000917          	auipc	s2,0x0
 5dc:	26090913          	addi	s2,s2,608 # 838 <malloc+0x11a>
        while(*s != 0){
 5e0:	02800593          	li	a1,40
 5e4:	bff1                	j	5c0 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 5e6:	008b0913          	addi	s2,s6,8
 5ea:	000b4583          	lbu	a1,0(s6)
 5ee:	8556                	mv	a0,s5
 5f0:	00000097          	auipc	ra,0x0
 5f4:	d98080e7          	jalr	-616(ra) # 388 <putc>
 5f8:	8b4a                	mv	s6,s2
      state = 0;
 5fa:	4981                	li	s3,0
 5fc:	bd65                	j	4b4 <vprintf+0x60>
        putc(fd, c);
 5fe:	85d2                	mv	a1,s4
 600:	8556                	mv	a0,s5
 602:	00000097          	auipc	ra,0x0
 606:	d86080e7          	jalr	-634(ra) # 388 <putc>
      state = 0;
 60a:	4981                	li	s3,0
 60c:	b565                	j	4b4 <vprintf+0x60>
        s = va_arg(ap, char*);
 60e:	8b4e                	mv	s6,s3
      state = 0;
 610:	4981                	li	s3,0
 612:	b54d                	j	4b4 <vprintf+0x60>
    }
  }
}
 614:	70e6                	ld	ra,120(sp)
 616:	7446                	ld	s0,112(sp)
 618:	74a6                	ld	s1,104(sp)
 61a:	7906                	ld	s2,96(sp)
 61c:	69e6                	ld	s3,88(sp)
 61e:	6a46                	ld	s4,80(sp)
 620:	6aa6                	ld	s5,72(sp)
 622:	6b06                	ld	s6,64(sp)
 624:	7be2                	ld	s7,56(sp)
 626:	7c42                	ld	s8,48(sp)
 628:	7ca2                	ld	s9,40(sp)
 62a:	7d02                	ld	s10,32(sp)
 62c:	6de2                	ld	s11,24(sp)
 62e:	6109                	addi	sp,sp,128
 630:	8082                	ret

0000000000000632 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 632:	715d                	addi	sp,sp,-80
 634:	ec06                	sd	ra,24(sp)
 636:	e822                	sd	s0,16(sp)
 638:	1000                	addi	s0,sp,32
 63a:	e010                	sd	a2,0(s0)
 63c:	e414                	sd	a3,8(s0)
 63e:	e818                	sd	a4,16(s0)
 640:	ec1c                	sd	a5,24(s0)
 642:	03043023          	sd	a6,32(s0)
 646:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 64a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 64e:	8622                	mv	a2,s0
 650:	00000097          	auipc	ra,0x0
 654:	e04080e7          	jalr	-508(ra) # 454 <vprintf>
}
 658:	60e2                	ld	ra,24(sp)
 65a:	6442                	ld	s0,16(sp)
 65c:	6161                	addi	sp,sp,80
 65e:	8082                	ret

0000000000000660 <printf>:

void
printf(const char *fmt, ...)
{
 660:	711d                	addi	sp,sp,-96
 662:	ec06                	sd	ra,24(sp)
 664:	e822                	sd	s0,16(sp)
 666:	1000                	addi	s0,sp,32
 668:	e40c                	sd	a1,8(s0)
 66a:	e810                	sd	a2,16(s0)
 66c:	ec14                	sd	a3,24(s0)
 66e:	f018                	sd	a4,32(s0)
 670:	f41c                	sd	a5,40(s0)
 672:	03043823          	sd	a6,48(s0)
 676:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 67a:	00840613          	addi	a2,s0,8
 67e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 682:	85aa                	mv	a1,a0
 684:	4505                	li	a0,1
 686:	00000097          	auipc	ra,0x0
 68a:	dce080e7          	jalr	-562(ra) # 454 <vprintf>
}
 68e:	60e2                	ld	ra,24(sp)
 690:	6442                	ld	s0,16(sp)
 692:	6125                	addi	sp,sp,96
 694:	8082                	ret

0000000000000696 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 696:	1141                	addi	sp,sp,-16
 698:	e422                	sd	s0,8(sp)
 69a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 69c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6a0:	00001797          	auipc	a5,0x1
 6a4:	9607b783          	ld	a5,-1696(a5) # 1000 <freep>
 6a8:	a805                	j	6d8 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6aa:	4618                	lw	a4,8(a2)
 6ac:	9db9                	addw	a1,a1,a4
 6ae:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6b2:	6398                	ld	a4,0(a5)
 6b4:	6318                	ld	a4,0(a4)
 6b6:	fee53823          	sd	a4,-16(a0)
 6ba:	a091                	j	6fe <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6bc:	ff852703          	lw	a4,-8(a0)
 6c0:	9e39                	addw	a2,a2,a4
 6c2:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 6c4:	ff053703          	ld	a4,-16(a0)
 6c8:	e398                	sd	a4,0(a5)
 6ca:	a099                	j	710 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6cc:	6398                	ld	a4,0(a5)
 6ce:	00e7e463          	bltu	a5,a4,6d6 <free+0x40>
 6d2:	00e6ea63          	bltu	a3,a4,6e6 <free+0x50>
{
 6d6:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6d8:	fed7fae3          	bgeu	a5,a3,6cc <free+0x36>
 6dc:	6398                	ld	a4,0(a5)
 6de:	00e6e463          	bltu	a3,a4,6e6 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6e2:	fee7eae3          	bltu	a5,a4,6d6 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 6e6:	ff852583          	lw	a1,-8(a0)
 6ea:	6390                	ld	a2,0(a5)
 6ec:	02059713          	slli	a4,a1,0x20
 6f0:	9301                	srli	a4,a4,0x20
 6f2:	0712                	slli	a4,a4,0x4
 6f4:	9736                	add	a4,a4,a3
 6f6:	fae60ae3          	beq	a2,a4,6aa <free+0x14>
    bp->s.ptr = p->s.ptr;
 6fa:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6fe:	4790                	lw	a2,8(a5)
 700:	02061713          	slli	a4,a2,0x20
 704:	9301                	srli	a4,a4,0x20
 706:	0712                	slli	a4,a4,0x4
 708:	973e                	add	a4,a4,a5
 70a:	fae689e3          	beq	a3,a4,6bc <free+0x26>
  } else
    p->s.ptr = bp;
 70e:	e394                	sd	a3,0(a5)
  freep = p;
 710:	00001717          	auipc	a4,0x1
 714:	8ef73823          	sd	a5,-1808(a4) # 1000 <freep>
}
 718:	6422                	ld	s0,8(sp)
 71a:	0141                	addi	sp,sp,16
 71c:	8082                	ret

000000000000071e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 71e:	7139                	addi	sp,sp,-64
 720:	fc06                	sd	ra,56(sp)
 722:	f822                	sd	s0,48(sp)
 724:	f426                	sd	s1,40(sp)
 726:	f04a                	sd	s2,32(sp)
 728:	ec4e                	sd	s3,24(sp)
 72a:	e852                	sd	s4,16(sp)
 72c:	e456                	sd	s5,8(sp)
 72e:	e05a                	sd	s6,0(sp)
 730:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 732:	02051493          	slli	s1,a0,0x20
 736:	9081                	srli	s1,s1,0x20
 738:	04bd                	addi	s1,s1,15
 73a:	8091                	srli	s1,s1,0x4
 73c:	0014899b          	addiw	s3,s1,1
 740:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 742:	00001517          	auipc	a0,0x1
 746:	8be53503          	ld	a0,-1858(a0) # 1000 <freep>
 74a:	c515                	beqz	a0,776 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 74c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 74e:	4798                	lw	a4,8(a5)
 750:	02977f63          	bgeu	a4,s1,78e <malloc+0x70>
 754:	8a4e                	mv	s4,s3
 756:	0009871b          	sext.w	a4,s3
 75a:	6685                	lui	a3,0x1
 75c:	00d77363          	bgeu	a4,a3,762 <malloc+0x44>
 760:	6a05                	lui	s4,0x1
 762:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 766:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 76a:	00001917          	auipc	s2,0x1
 76e:	89690913          	addi	s2,s2,-1898 # 1000 <freep>
  if(p == (char*)-1)
 772:	5afd                	li	s5,-1
 774:	a88d                	j	7e6 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 776:	00001797          	auipc	a5,0x1
 77a:	89a78793          	addi	a5,a5,-1894 # 1010 <base>
 77e:	00001717          	auipc	a4,0x1
 782:	88f73123          	sd	a5,-1918(a4) # 1000 <freep>
 786:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 788:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 78c:	b7e1                	j	754 <malloc+0x36>
      if(p->s.size == nunits)
 78e:	02e48b63          	beq	s1,a4,7c4 <malloc+0xa6>
        p->s.size -= nunits;
 792:	4137073b          	subw	a4,a4,s3
 796:	c798                	sw	a4,8(a5)
        p += p->s.size;
 798:	1702                	slli	a4,a4,0x20
 79a:	9301                	srli	a4,a4,0x20
 79c:	0712                	slli	a4,a4,0x4
 79e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7a0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7a4:	00001717          	auipc	a4,0x1
 7a8:	84a73e23          	sd	a0,-1956(a4) # 1000 <freep>
      return (void*)(p + 1);
 7ac:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7b0:	70e2                	ld	ra,56(sp)
 7b2:	7442                	ld	s0,48(sp)
 7b4:	74a2                	ld	s1,40(sp)
 7b6:	7902                	ld	s2,32(sp)
 7b8:	69e2                	ld	s3,24(sp)
 7ba:	6a42                	ld	s4,16(sp)
 7bc:	6aa2                	ld	s5,8(sp)
 7be:	6b02                	ld	s6,0(sp)
 7c0:	6121                	addi	sp,sp,64
 7c2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7c4:	6398                	ld	a4,0(a5)
 7c6:	e118                	sd	a4,0(a0)
 7c8:	bff1                	j	7a4 <malloc+0x86>
  hp->s.size = nu;
 7ca:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7ce:	0541                	addi	a0,a0,16
 7d0:	00000097          	auipc	ra,0x0
 7d4:	ec6080e7          	jalr	-314(ra) # 696 <free>
  return freep;
 7d8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7dc:	d971                	beqz	a0,7b0 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7de:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7e0:	4798                	lw	a4,8(a5)
 7e2:	fa9776e3          	bgeu	a4,s1,78e <malloc+0x70>
    if(p == freep)
 7e6:	00093703          	ld	a4,0(s2)
 7ea:	853e                	mv	a0,a5
 7ec:	fef719e3          	bne	a4,a5,7de <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 7f0:	8552                	mv	a0,s4
 7f2:	00000097          	auipc	ra,0x0
 7f6:	b76080e7          	jalr	-1162(ra) # 368 <sbrk>
  if(p == (char*)-1)
 7fa:	fd5518e3          	bne	a0,s5,7ca <malloc+0xac>
        return 0;
 7fe:	4501                	li	a0,0
 800:	bf45                	j	7b0 <malloc+0x92>

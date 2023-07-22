from timeit import default_timer as timer
import struct
import binascii
import base64
import random
import traceback
import enum
import time

USER_PROGRAM = binascii.unhexlify( # in Little-Endian
    # ###### User Program Assembly ######
    # __start:
    '0C048002' # addi.w      $t0,$zero,0x1   # t0 = 1
    '0D048002' # addi.w      $t1,$zero,0x1   # t1 = 1
    '04800015' # lu12i.w     $a0,-0x7fc00    # a0 = 0x80400000
    '85808002' # addi.w      $a1,$a0,0x20    # a1 = 0x80400020

    # loop:
    '8E351000' # add.w       $t2,$t0,$t1     # t2 = t0+t1
    'AC018002' # addi.w      $t0,$t1,0x0     # t0 = t1
    'CD018002' # addi.w      $t1,$t2,0x0     # t1 = t2
    '8E008029' # st.w        $t2,$a0,0x0
    '84108002' # addi.w      $a0,$a0,0x4     # a0 += 4
    '85ECFF5F' # bne         $a0,$a1,loop
    '2000004C' # jirl        $zero,$ra,0x0
)
REG_VERIFICATION = [(4, 0x80400020), (5, 0x80400020), (12, 0x22), (13, 0x37), (14, 0x37)]
MEM_VERIFICATION = binascii.unhexlify(
    '020000000300000005000000080000000d000000150000002200000037000000')



class State(enum.Enum):
    WaitBoot = enum.auto()
    RunA = enum.auto()
    RunD = enum.auto()
    RunG = enum.auto()
    WaitG = enum.auto()
    RunR = enum.auto()
    RunD2 = enum.auto()
    Done = enum.auto()

bootMessage = b'MONITOR for Loongarch32 - initialized.'
recvBuf = b''

@staticmethod
def int2bytes(val):
    return struct.pack('<I', val)

@staticmethod
def bytes2int(val):
    return struct.unpack('<I', val)[0]

def endTest(state):
    if state == State.WaitBoot:
        score = 0
    elif state == State.RunD:
        score = 0.3
    elif state in [State.RunG, State.WaitG]:
        score = 0.5
    elif state == State.RunR:
        score = 0.7
    elif state == State.RunD2:
        score = 0.8
    elif state == State.Done:
        score = 1

    return score

def stateChange(state, received):
    addr = 0x80100000
    if state == State.WaitBoot:
        bootMsgLen = len(bootMessage)
        if received != bootMessage:
            print('ERROR: incorrect message')
            return state, True
        elif len(recvBuf) > bootMsgLen:
            print('WARNING: extra bytes received')
        recvBuf = b''

        state = State.RunA
        for i in range(0, len(USER_PROGRAM), 4):
            print('A')
            print(int2bytes(addr + i))
            print(int2bytes(4))
            print(USER_PROGRAM[i:i + 4])
        print("User program written")

        state = State.RunD
        expectedLen = len(USER_PROGRAM)
        print('D')
        print(int2bytes(addr))
        print(int2bytes(len(USER_PROGRAM)))

    # ... (rest of the state change logic)

def main():
    addr = 0x80100000
    for i in range(0, len(USER_PROGRAM), 4):
        print('A')
        print(int2bytes(addr + i))
        print(int2bytes(4))
        print(USER_PROGRAM[i:i + 4])

if __name__ == "__main__":
    main()

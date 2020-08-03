import sys

translator = [
    { # Load Byte
        "name": "LDB",
        "opcode": "0111",
        "flags": "10",
        "type": 1,
        "subtype": 0
    },
    { # Load Byte Unsigned
        "name": "LDBU",
        "opcode": "0110",
        "flags": "10",
        "type": 1,
        "subtype": 0
    },
    { # Load Halfword
        "name": "LDH",
        "opcode": "0111",
        "flags": "01",
        "type": 1,
        "subtype": 0
    },
    { # Load Halfword Unsigned
        "name": "LDHU",
        "opcode": "0110",
        "flags": "01",
        "type": 1,
        "subtype": 0
    },
    { # Load Word
        "name": "LD",
        "opcode": "0111",
        "flags": "00",
        "type": 1,
        "subtype": 0
    },
    { # Load Float
        "name": "LDF",
        "opcode": "0111",
        "flags": "11",
        "type": 1,
        "subtype": 0
    },
    { # Store Byte
        "name": "STB",
        "opcode": "1000",
        "flags": "10",
        "type": 1,
        "subtype": 0
    },
    { # Store Halfword
        "name": "STH",
        "opcode": "1000",
        "flags": "01",
        "type": 1,
        "subtype": 0
    },
    { # Store Word
        "name": "ST",
        "opcode": "1000",
        "flags": "00",
        "type": 1,
        "subtype": 0
    },
    { # Store Float
        "name": "STF",
        "opcode": "1000",
        "flags": "11",
        "type": 1,
        "subtype": 0
    },
    { # Move Integer 2 FP
        "name": "MI2F",
        "opcode": "0100",
        "flags": "01",
        "type": 1,
        "subtype": 1
    },
    { # Move FP 2 Integer
        "name": "MF2I",
        "opcode": "0100",
        "flags": "00",
        "type": 1,
        "subtype": 1
    },
    { # Addition
        "name": "ADD",
        "opcode": "0000",
        "flags": "00",
        "flags2": "00000000000",
        "type": 0,
        "subtype": 0
    },
    { # Add immediate
        "name": "ADDI",
        "opcode": "0000",
        "flags": "01",
        "type": 1,
        "subtype": 2
    },
    { # Substraction
        "name": "SUB",
        "opcode": "0000",
        "flags": "00",
        "flags2": "00000000001",
        "type": 0,
        "subtype": 0
    },
    { # Multiplication
        "name": "MULT",
        "opcode": "0000",
        "flags": "00",
        "flags2": "00000000010",
        "type": 0,
        "subtype": 0
    },
    { # Division
        "name": "DIV",
        "opcode": "0000",
        "flags": "00",
        "flags2": "00000000011",
        "type": 0,
        "subtype": 0
    },
    { # And
        "name": "AND",
        "opcode": "0001",
        "flags": "00",
        "flags2": "00000000000",
        "type": 0,
        "subtype": 0
    },
    { # Or
        "name": "OR",
        "opcode": "0001",
        "flags": "00",
        "flags2": "00000000001",
        "type": 0,
        "subtype": 0
    },
    { # Xor
        "name": "XOR",
        "opcode": "0001",
        "flags": "00",
        "flags2": "00000000010",
        "type": 0,
        "subtype": 0
    },
    { # Negate
        "name": "NEG",
        "opcode": "0001",
        "flags": "00",
        "flags2": "00000000011",
        "type": 0,
        "subtype": 1
    },
    { # Not
        "name": "NOT",
        "opcode": "0001",
        "flags": "00",
        "flags2": "00000000100",
        "type": 0,
        "subtype": 1
    },
    { # Integer to 7seg
        "name": "I2SS",
        "opcode": "1111",
        "flags": "00",
        "flags2": "00000000000",
        "type": 0,
        "subtype": 1
    },
    { # Load High part register
        "name": "LHI",
        "opcode": "0010",
        "flags": "00",
        "type": 1,
        "subtype": 3
    },
    { # Load Low part register
        "name": "LLO",
        "opcode": "0010",
        "flags": "01",
        "type": 1,
        "subtype": 3
    },
    { # Shift Left
        "name": "SL",
        "opcode": "0011",
        "flags": "00",
        "flags2": "00000000000",
        "type": 0,
        "subtype": 0
    },
    { # Shift Right (Logical)
        "name": "SR",
        "opcode": "0011",
        "flags": "01",
        "flags2": "00000000000",
        "type": 0,
        "subtype": 0
    },
    { # Shift Right (Arithmetical)
        "name": "SRA",
        "opcode": "0011",
        "flags": "01",
        "flags2": "00000000001",
        "type": 0,
        "subtype": 0
    },
    { # Compare equality
        "name": "EQU",
        "opcode": "0101",
        "flags": "00",
        "flags2": "00000000000",
        "type": 0,
        "subtype": 0
    },
    { # Compare greateness
        "name": "CMP",
        "opcode": "0101",
        "flags": "00",
        "flags2": "00000000001",
        "type": 0,
        "subtype": 0
    },
    { # Compare lowerness
        "name": "LOT",
        "opcode": "0101",
        "flags": "00",
        "flags2": "00000000010",
        "type": 0,
        "subtype": 0
    },
    { # Float addition
        "name": "FADD",
        "opcode": "0000",
        "flags": "10",
        "flags2": "00000000000",
        "type": 0,
        "subtype": 0
    },
    { # Float substraction
        "name": "FSUB",
        "opcode": "0000",
        "flags": "10",
        "flags2": "00000000001",
        "type": 0,
        "subtype": 0
    },
    { # Float multiplication
        "name": "FMULT",
        "opcode": "0000",
        "flags": "10",
        "flags2": "00000000010",
        "type": 0,
        "subtype": 0
    },
    { # Float division
        "name": "FDIV",
        "opcode": "0000",
        "flags": "10",
        "flags2": "00000000011",
        "type": 0,
        "subtype": 0
    },
    { # Float “greater than” comp.
        "name": "FGRT",
        "opcode": "0101",
        "flags": "10",
        "flags2": "00000000001",
        "type": 0,
        "subtype": 0
    },
    { # Branch if equal
        "name": "BEQ",
        "opcode": "1101",
        "flags": "00",
        "type": 1,
        "subtype": 0
    },
    { # Branch if float equal
        "name": "BFEQ",
        "opcode": "1101",
        "flags": "10",
        "type": 1,
        "subtype": 0
    },
    { # Jump
        "name": "JMP",
        "opcode": "1100",
        "flags": "00",
        "type": 2
    },
    { # Call
        "name": "CALL",
        "opcode": "1100",
        "flags": "01",
        "type": 2
    },
    { # Return
        "name": "RETURN",
        "opcode": "1100",
        "flags": "10",
        "type": 2
    }
]

def loadData(OriginFilename):

    file = open(OriginFilename, "r")
    textFull = file.read()
    file.close()

    inst = textFull.split('\n')

    return inst

def showResult(b, DestinationFilename):
    data = "signal Memory: STORAGE := (\n"
    i = 0

    for binary in b:
        if(i < 10): data = data + str(i) + "  => "
        else: data = data + str(i) + " => "
        data = data + '"' + "".join(binary) + '"' + ",\n"
        i += 1

    if (len(instructionList) < 64):
        data = data + "others => (others => '0'));"

    if(DestinationFilename == None):
        print("\n" + data)
    else:
        file = open(DestinationFilename, "w")
        textFull = file.write(data)
        file.close()
    print("\nAll OK")

def getBinary(value, nBits):
    isneg = value < 0
    binary = list("0" * nBits)
    if (isneg): value *= -1

    for i in range(nBits):
        pot = 2**(nBits-1 - i)

        if (value >= pot):
            binary[i] = '1'
            value -= pot

    if isneg:
        for i in range(nBits):
            if (binary[i] == '1'): binary[i] = '0'
            else: binary[i] = '1'

        if (binary[nBits-1] == '0'): binary[nBits-1] = '1'
        else:
            binary[nBits-1] = '0'

            i = nBits-2
            while (i > 0 and binary[i] == '1'):
                binary[i] = '0'
                i -= 1

            if (i != nBits): binary[i] = '1'

    return binary

def getInstruction(name):
    aux = {"type": -1}
    for i in translator:
        if i.get("name") == name:
            aux = i
    return aux

def convertInstruction(instruction):
    code = list("0" * 32)
    components = instruction.split(' ')

    print("-"*50)
    print("Original instruction: " + str(instruction))

    instruction = getInstruction(components[0])

    print("Instruction detected: " + str(instruction))
    print("Components  detected: " + str(components))

    if (instruction.get("type") == 0):
        rd = getBinary(int(components[1]), 5)
        rs = getBinary(int(components[2]), 5)
        if (instruction.get("subtype") == 0):
            rt = getBinary(int(components[3]), 5)
        else:
            rt = getBinary(0, 5)

        for i in range(4): code[i] = instruction.get("opcode")[i]
        for i in range(2): code[i + 4] = instruction.get("flags")[i]
        for i in range(5): code[i + 6] = rd[i]
        for i in range(5): code[i + 11] = rs[i]
        for i in range(5): code[i + 16] = rt[i]
        for i in range(11): code[i + 21] = instruction.get("flags2")[i]

    elif (instruction.get("type") == 1):
        rd = []
        rs = []
        imm = []
        if (instruction.get("subtype") == 0):
            rd = getBinary(int(components[2]), 5)
            rs = getBinary(int(components[1]), 5)
            imm = getBinary(int(components[3]), 16)
        elif (instruction.get("subtype") == 1):
            rd = getBinary(int(components[2]), 5)
            rs = getBinary(int(components[1]), 5)
            imm = getBinary(0, 16)
        elif (instruction.get("subtype") == 2):
            rd = getBinary(int(components[1]), 5)
            rs = getBinary(int(components[2]), 5)
            imm = getBinary(int(components[3]), 16)
        else:
            rd = getBinary(int(components[1]), 5)
            rs = getBinary(0, 5)
            imm = getBinary(int(components[2]), 16)

        for i in range(4): code[i] = instruction.get("opcode")[i]
        for i in range(2): code[i + 4] = instruction.get("flags")[i]
        for i in range(5): code[i + 6] = rd[i]
        for i in range(5): code[i + 11] = rs[i]
        for i in range(16): code[i + 16] = imm[i]

    elif (instruction.get("type") == 2):
        imm = []
        if (len(components) > 1): imm = getBinary(int(components[1]), 26)
        else: imm = getBinary(0, 26)

        for i in range(4): code[i] = instruction.get("opcode")[i]
        for i in range(2): code[i + 4] = instruction.get("flags")[i]
        for i in range(26): code[i + 6] = imm[i]

    return code

###################################### 02200000  0000 00 10001 00000 0000000000000000

binaries = []

if (len(sys.argv) < 2):
	print("Number of arguments given wrong!\nUse python assembler_v2.py <code path> <result path> to obtain the result on the given path\nUse python assembler_v2.py <code path> to obtain the result on screen.")
else:
    #Instructions loaded from the given path
    instructionList = loadData( sys.argv[1] )

    #Each instruction is converted to the binary format for the final result
    for instruction in instructionList:
        converted = convertInstruction(instruction)
        print("".join(converted))

        binaries.append(converted[24:32])
        binaries.append(converted[16:24])
        binaries.append(converted[8:16])
        binaries.append(converted[0:8])

    if(len(sys.argv) == 3):
        showResult(binaries, sys.argv[2])
    else:
        showResult(binaries, None)

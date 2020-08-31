--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity execution_module is
    generic (
        -- System
        SA: integer:= 32;
        SD: integer:= 32;
        SX: integer:= 17;

        -- Instruction
        IO: integer:= 4;
        IX: integer:= 2;
        IY: integer:= 11;

        -- Floating Point
        FD: integer:= 32;
        FM: integer:= 23;
        FE: integer:= 8
    );
    port (
        clk: in std_logic;
        reset: in std_logic;
        EXE_Stall: in std_logic;

        -- Connexions amb el IDM
        A: in std_logic_vector(SD-1 downto 0);
        B: in std_logic_vector(SD-1 downto 0);
        Af: in std_logic_vector(SD-1 downto 0);
        Bf: in std_logic_vector(SD-1 downto 0);

        InstructionToExecute: in std_logic_vector(SX-1 downto 0);

        -- Conexions amb el MEM
        InstructionExecuted: out std_logic_vector(SX-1 downto 0);
        ALUOut: out std_logic_vector(SD-1 downto 0);
        SMDR: out std_logic_vector(SD-1 downto 0);
        cond: out std_logic;

        -- Altres connexions
        ALUNotReady: out std_logic;
        ret: out std_logic;
        LIFOout: in std_logic_vector(SD-1 downto 0);
        
        freshValue: in std_logic
	);
end execution_module;

architecture a of execution_module is

    component fpu is
        generic (
            -- System
            SX: integer:= 17;

            -- Instruction
            IO: integer:= 4;
            IX: integer:= 2;
            IY: integer:= 11;

            -- Floating Point
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8
        );
        port (
            clk: in std_logic;
            reset: in std_logic;
            exe_stall: in std_logic;

            InstructionToExecute: in std_logic_vector(SX-1 downto 0);

            A: in std_logic_vector(SD-1 downto 0);
            B: in std_logic_vector(SD-1 downto 0);

            C: out std_logic_vector(SD-1 downto 0);

            FPUNotReady: out std_logic;
            freshValue: in std_logic
    	);
    end component;

    component int2sevseg is
        port (
            input: in std_logic_vector(SD-1 downto 0);
            output: out std_logic_vector(SD-1 downto 0)
        );
    end component;

    constant all_ones: std_logic_vector(SD-1 downto 0) := (others => '1');
    constant all_zero: std_logic_vector(SD-1 downto 0) := (others => '0');

    signal C: std_logic_vector(SD-1 downto 0) := (others => '0');

    signal Ai: integer := 0;
    signal Bi: integer := 0;
    signal Ci: integer := 0;

    signal opcode: std_logic_vector(IO-1 downto 0) := (others => '0');
    signal flags: std_logic_vector(IX-1 downto 0) := (others => '0');
    signal flags2: std_logic_vector(IY-1 downto 0) := (others => '0');

    signal shiftAux: std_logic_vector(SD-1 downto 0) := (others => '0');
    signal sevsegAux: std_logic_vector(SD-1 downto 0) := (others => '0');
    signal FPUOut: std_logic_vector(FD-1 downto 0) := (others => '0');

    --signal freshValue: std_logic;

begin

    FPUU: fpu
    generic map (
        SX => SX,

        IO => IO,
        IX => IX,
        IY => IY,

        FD => FD,
        FM => FM,
        FE => FE
    ) port map (
        clk => clk,
        reset => reset,
        exe_stall => EXE_Stall,
        InstructionToExecute => InstructionToExecute,
        A => A,
        B => B,
        C => FPUOut,
        FPUNotReady => ALUNotReady,
        freshValue => freshValue
    );

    I2SS: int2sevseg
    port map (
        input => A,
        output => sevsegAux
    );

    opcode <= InstructionToExecute(IO-1 downto 0);
    flags <= InstructionToExecute((IO+IX)-1 downto IO);
    flags2 <= InstructionToExecute((IO+IX+IY)-1 downto (IO+IX));

    Ai <= to_integer(unsigned(A));
    Bi <= to_integer(unsigned(B));

    Ci <=
        Ai + Bi when opcode = "0000" and flags = "00" and flags2 = "00000000000" else
        Ai + Bi when opcode = "0000" and flags = "01" else
        Ai - Bi when opcode = "0000" and flags = "00" and flags2 = "00000000001" else
        Ai * Bi when opcode = "0000" and flags = "00" and flags2 = "00000000010" else
        Ai / Bi when opcode = "0000" and flags = "00" and flags2 = "00000000011" else
        to_integer(unsigned(A AND B)) when opcode = "0001" and flags = "00" and flags2 = "00000000000" else
        to_integer(unsigned(A OR B))  when opcode = "0001" and flags = "00" and flags2 = "00000000001" else
        to_integer(unsigned(A XOR B)) when opcode = "0001" and flags = "00" and flags2 = "00000000010" else
        to_integer(unsigned(NOT A)) +1 when opcode = "0001" and flags = "00" and flags2 = "00000000011" else
        to_integer(unsigned(NOT A))    when opcode = "0001" and flags = "00" and flags2 = "00000000100" else
        to_integer(unsigned(sevsegAux)) when opcode = "1111" else
        to_integer(unsigned(B(15 downto 0) & A(15 downto 0))) when opcode = "0010" and flags = "00" else
        to_integer(unsigned(A(31 downto 16) & B(15 downto 0))) when opcode = "0010" and flags = "01" else
        to_integer(unsigned(shiftAux)) when opcode = "0011" else
        to_integer(unsigned(all_ones)) when Ai = Bi and opcode = "0101" and flags = "00" and flags2 = "00000000000" else
        to_integer(unsigned(all_zero)) when (not (Ai = Bi)) and opcode = "0101" and flags = "00" and flags2 = "00000000000" else
        to_integer(unsigned(all_ones)) when Ai > Bi and opcode = "0101" and flags = "00" and flags2 = "00000000001" else
        to_integer(unsigned(all_zero)) when (not (Ai > Bi)) and opcode = "0101" and flags = "00" and flags2 = "00000000001" else
        to_integer(unsigned(all_ones)) when Ai < Bi and opcode = "0101" and flags = "00" and flags2 = "00000000010" else
        to_integer(unsigned(all_zero)) when (not (Ai < Bi)) and opcode = "0101" and flags = "00" and flags2 = "00000000010" else
        Ai + Bi when opcode = "1101" else
        Ai + Bi when opcode = "1100" and flags = "00" else
        Ai + Bi when opcode = "1100" and flags = "01" else
        to_integer(unsigned(LIFOout)) +4 when opcode = "1100" and flags = "10" else
        Ai + Bi when opcode = "0111" or opcode = "1000" or opcode = "0110" else
        to_integer(unsigned(FPUOut)) when (((opcode = "0000") and (flags = "10")) or ((opcode = "0101") and (flags = "10"))) or (opcode = "0100") else
        to_integer(unsigned(all_zero));

    C <= std_logic_vector(to_signed(Ci, SD));

    ret <= '1' when InstructionToExecute(IO-1 downto 0) = "1100" and InstructionToExecute((IO+IX)-1 downto IO) = "10" else '0';

    updateOutputs: process(clk)
    begin
        if (clk = '1' and EXE_Stall = '0') then
            if (opcode = "1100" and flags = "01") then SMDR <= B;
            else SMDR <= Bf; end if;

            InstructionExecuted <= InstructionToExecute;
            ALUOut <= C;

            if (Af = Bf) then cond <= '1';
            else cond <= '0'; end if;
        end if;
    end process;

    performShiftOperation: process(Ai, Bi, opcode, flags, flags2)
    begin
        if (opcode = "0011") then
            if (Bi >= 32) then
                shiftAux <= (others => '0'); -- 0
            elsif (Bi < 0) then
                shiftAux <= (others => '1'); -- error
            else
                if (flags = "00") then
                    shiftAux(SD-1 downto Bi) <= A((SD-1) - Bi downto 0);
                    shiftAux(Bi-1 downto 0) <= (others => '0');
                elsif (flags = "01") then
                    shiftAux(SD - Bi -1 downto 0) <= A((SD-1) downto Bi);
                    if (flags2 = "00000000000") then
                        shiftAux((SD-1) downto SD - Bi) <= (others => '0');
                    elsif (flags2 = "00000000001") then
                        shiftAux((SD-1) downto SD - Bi) <= (others => A((SD-1)));
                    end if;
                end if;
            end if;
        end if;
    end process;

end a;

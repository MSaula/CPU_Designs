--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity fpu is
    generic (
        -- System
        SX: integer:= 17;
        SB: integer:= 5;

        -- Instruction
        IO: integer:= 4;
        IX: integer:= 2;
        IY: integer:= 11;

        -- Floating Point
        FD: integer:= 32;
        FM: integer:= 23;
        FE: integer:= 8;

        BC: integer:= 8
    );
    port (
        clk: in std_logic;
        reset: in std_logic;
        EXE_Stall: in std_logic;

        InstructionToExecute: in std_logic_vector(SX-1 downto 0);

        A: in std_logic_vector(FD-1 downto 0);
        B: in std_logic_vector(FD-1 downto 0);

        C: out std_logic_vector(FD-1 downto 0);

        FPUNotReady: out std_logic;

        RDin: in std_logic_vector(SB-1 downto 0);
        IsFP: in std_logic;

        ACK0: in std_logic;
        Q0: out std_logic_vector(FD-1 downto 0);
        RD0: out std_logic_vector(SB-1 downto 0);
        END0: out std_logic;
        IFP0: out std_logic;

        ACK1: in std_logic;
        Q1: out std_logic_vector(FD-1 downto 0);
        RD1: out std_logic_vector(SB-1 downto 0);
        END1: out std_logic;
        IFP1: out std_logic;

        ACK2: in std_logic;
        Q2: out std_logic_vector(FD-1 downto 0);
        RD2: out std_logic_vector(SB-1 downto 0);
        END2: out std_logic;
        IFP2: out std_logic;

        ACK3: in std_logic;
        Q3: out std_logic_vector(FD-1 downto 0);
        RD3: out std_logic_vector(SB-1 downto 0);
        END3: out std_logic;
        IFP3: out std_logic;

        ACK4: in std_logic;
        Q4: out std_logic_vector(FD-1 downto 0);
        RD4: out std_logic_vector(SB-1 downto 0);
        END4: out std_logic;
        IFP4: out std_logic;

        ACK5: in std_logic;
        Q5: out std_logic_vector(FD-1 downto 0);
        RD5: out std_logic_vector(SB-1 downto 0);
        END5: out std_logic;
        IFP5: out std_logic;

        ACK6: in std_logic;
        Q6: out std_logic_vector(FD-1 downto 0);
        RD6: out std_logic_vector(SB-1 downto 0);
        END6: out std_logic;
        IFP6: out std_logic;

        ACK7: in std_logic;
        Q7: out std_logic_vector(FD-1 downto 0);
        RD7: out std_logic_vector(SB-1 downto 0);
        END7: out std_logic;
        IFP7: out std_logic
	);
end fpu;

architecture a of fpu is

    component fp_multiplier is
        generic (
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8
        );
        port (
            A: in std_logic_vector(FD-1 downto 0);
            B: in std_logic_vector(FD-1 downto 0);

            C: out std_logic_vector(FD-1 downto 0)
    	);
    end component;

    component fp_adder is
        generic (
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8
        );
        port (
            A: in std_logic_vector(FD-1 downto 0);
            B: in std_logic_vector(FD-1 downto 0);

            C: out std_logic_vector(FD-1 downto 0)
    	);
    end component;

    component parallel_division_module is
        generic (
            -- System
            SX: integer:= 17;
            SB: integer:= 5;

            -- Instruction
            IO: integer:= 4;
            IX: integer:= 2;
            IY: integer:= 11;

            -- Floating Point
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8;

            BC: integer:= 8
        );
        port (
            clk: in std_logic;
            reset: in std_logic;

            start: in std_logic;
            RDin: in std_logic_vector(SB-1 downto 0);
            IsFP: in std_logic;

            N: in std_logic_vector(FD-1 downto 0);
            D: in std_logic_vector(FD-1 downto 0);

            C: out std_logic_vector(FD-1 downto 0);

            FPUfull: out std_logic;

            -- OoOE Bus
            ACK0: in std_logic;
            Q0: out std_logic_vector(FD-1 downto 0);
            RD0: out std_logic_vector(SB-1 downto 0);
            END0: out std_logic;
            IFP0: out std_logic;

            ACK1: in std_logic;
            Q1: out std_logic_vector(FD-1 downto 0);
            RD1: out std_logic_vector(SB-1 downto 0);
            END1: out std_logic;
            IFP1: out std_logic;

            ACK2: in std_logic;
            Q2: out std_logic_vector(FD-1 downto 0);
            RD2: out std_logic_vector(SB-1 downto 0);
            END2: out std_logic;
            IFP2: out std_logic;

            ACK3: in std_logic;
            Q3: out std_logic_vector(FD-1 downto 0);
            RD3: out std_logic_vector(SB-1 downto 0);
            END3: out std_logic;
            IFP3: out std_logic;

            ACK4: in std_logic;
            Q4: out std_logic_vector(FD-1 downto 0);
            RD4: out std_logic_vector(SB-1 downto 0);
            END4: out std_logic;
            IFP4: out std_logic;

            ACK5: in std_logic;
            Q5: out std_logic_vector(FD-1 downto 0);
            RD5: out std_logic_vector(SB-1 downto 0);
            END5: out std_logic;
            IFP5: out std_logic;

            ACK6: in std_logic;
            Q6: out std_logic_vector(FD-1 downto 0);
            RD6: out std_logic_vector(SB-1 downto 0);
            END6: out std_logic;
            IFP6: out std_logic;

            ACK7: in std_logic;
            Q7: out std_logic_vector(FD-1 downto 0);
            RD7: out std_logic_vector(SB-1 downto 0);
            END7: out std_logic;
            IFP7: out std_logic
        );
    end component;

    component int2fp is
        generic (
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8
        );
        port (
            input: in std_logic_vector(FD-1 downto 0);
            output: out std_logic_vector(FD-1 downto 0)
    	);
    end component;

    component fp2int is
        generic (
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8
        );
        port (
            input: in std_logic_vector(FD-1 downto 0);
            output: out std_logic_vector(FD-1 downto 0)
    	);
    end component;

    signal mult: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal add: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal sub: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal div: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal fp2int_out: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal int2fp_out: std_logic_vector(FD-1 downto 0) := (others => '0');

    signal B_neg: std_logic_vector(FD-1 downto 0) := (others => '0');

    signal AgtB: std_logic := '0';

    signal divisionEnded: std_logic := '0';
    signal startShot: std_logic := '0';

    signal isAdd: boolean;
    signal isSub: boolean;
    signal isMul: boolean;
    signal isDiv: boolean;
    signal isCmp: boolean;
    signal isF2I: boolean;
    signal isI2F: boolean;

begin

    B_neg(FD-1) <= not B(FD-1);
    B_neg(FD-2 downto 0) <= B(FD-2 downto 0);

    AgtB <= '1' when ((A(FD-1) = '0') and (B(FD-1) = '1')) or
        ((A(FD-1) = B(FD-1)) and (A(FD-2 downto 0) > B(FD-2 downto 0)))
        else '0';

    isAdd <= InstructionToExecute(IO-1 downto 0) = "0000" and InstructionToExecute((IO+IX-1) downto IO) = "10" and InstructionToExecute((IO+IX+IY-1) downto (IO+IX)) = "00000000000";
    isSub <= InstructionToExecute(IO-1 downto 0) = "0000" and InstructionToExecute((IO+IX-1) downto IO) = "10" and InstructionToExecute((IO+IX+IY-1) downto (IO+IX)) = "00000000001";
    isMul <= InstructionToExecute(IO-1 downto 0) = "0000" and InstructionToExecute((IO+IX-1) downto IO) = "10" and InstructionToExecute((IO+IX+IY-1) downto (IO+IX)) = "00000000010";
    isDiv <= InstructionToExecute(IO-1 downto 0) = "0000" and InstructionToExecute((IO+IX-1) downto IO) = "10" and InstructionToExecute((IO+IX+IY-1) downto (IO+IX)) = "00000000011";
    isCmp <= InstructionToExecute(IO-1 downto 0) = "0101" and InstructionToExecute((IO+IX-1) downto IO) = "10" and InstructionToExecute((IO+IX+IY-1) downto (IO+IX)) = "00000000001";
    isI2F <= InstructionToExecute(IO-1 downto 0) = "0100" and InstructionToExecute((IO+IX-1) downto IO) = "01";
    isF2I <= InstructionToExecute(IO-1 downto 0) = "0100" and InstructionToExecute((IO+IX-1) downto IO) = "00";

    C <= (others => AgtB) when isCmp else
        add  when isAdd else
        sub  when isSub else
        mult when isMul else
        div  when isDiv else
        fp2int_out when isF2I else
        int2fp_out when isI2F else
        (others => '0');

    multiplier: fp_multiplier
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        A => A,
        B => B,

        C => mult
    );

    adder: fp_adder
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        A => A,
        B => B,

        C => add
    );

    substractor: fp_adder
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        A => A,
        B => B_neg,

        C => sub
    );

    divider: parallel_division_module
    generic map (
        SX => SX,
        SB => SB,
        IO => IO,
        IX => IX,
        IY => IY,
        FD => FD,
        FM => FM,
        FE => FE,
        BC => BC
    )
    port map (
        N => A,
        D => B,
        start => startShot,
        clk => clk,
        reset => reset,
        RDin => RDin,
        IsFP => IsFP,
        C => div,
        FPUfull => FPUNotReady,
        ACK0 => ACK0,
        Q0 => Q0,
        RD0 => RD0,
        END0 => END0,
        IFP0 => IFP0,
        ACK1 => ACK1,
        Q1 => Q1,
        RD1 => RD1,
        END1 => END1,
        IFP1 => IFP1,
        ACK2 => ACK2,
        Q2 => Q2,
        RD2 => RD2,
        END2 => END2,
        IFP2 => IFP2,
        ACK3 => ACK3,
        Q3 => Q3,
        RD3 => RD3,
        END3 => END3,
        IFP3 => IFP3,
        ACK4 => ACK4,
        Q4 => Q4,
        RD4 => RD4,
        END4 => END4,
        IFP4 => IFP4,
        ACK5 => ACK5,
        Q5 => Q5,
        RD5 => RD5,
        END5 => END5,
        IFP5 => IFP5,
        ACK6 => ACK6,
        Q6 => Q6,
        RD6 => RD6,
        END6 => END6,
        IFP6 => IFP6,
        ACK7 => ACK7,
        Q7 => Q7,
        RD7 => RD7,
        END7 => END7,
        IFP7 => IFP7
    );

    FP2I: fp2int
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        input => A,
        output => fp2int_out
    );

    I2FP: int2fp
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        input => A,
        output => int2fp_out
    );

    startShot <= '1' when isDiv and EXE_Stall = '0' else '0';
end a;

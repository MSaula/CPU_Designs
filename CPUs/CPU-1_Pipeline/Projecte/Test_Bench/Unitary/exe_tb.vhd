
library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity exe_tb is
end exe_tb;

architecture TB of exe_tb is

    component execution_module is
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
            ret: out std_logic
    	);
    end component;

    constant SA: integer:= 32;
    constant SD: integer:= 32;
    constant SX: integer:= 17;
    constant IO: integer:= 4;
    constant IX: integer:= 2;
    constant IY: integer:= 11;
    constant FD: integer:= 32;
    constant FM: integer:= 23;
    constant FE: integer:= 8;

    constant PERIOD: time := 10 ps;
    signal clk: std_logic := '0';

    signal reset: std_logic;
    signal EXE_Stall: std_logic;
    signal A: std_logic_vector(SD-1 downto 0);
    signal B: std_logic_vector(SD-1 downto 0);
    signal Af: std_logic_vector(SD-1 downto 0);
    signal Bf: std_logic_vector(SD-1 downto 0);
    signal InstructionToExecute: std_logic_vector(SX-1 downto 0);
    signal InstructionExecuted: std_logic_vector(SX-1 downto 0);
    signal ALUOut: std_logic_vector(SD-1 downto 0);
    signal SMDR: std_logic_vector(SD-1 downto 0);
    signal cond: std_logic;
    signal ALUNotReady: std_logic;
    signal ret: std_logic;

begin

    clk <= not clk after PERIOD/2;

    EXEM: execution_module
    generic map (
        SA => SA,
        SD => SD,
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
        EXE_Stall => EXE_Stall,
        A => A,
        B => B,
        Af => Af,
        Bf => Bf,
        InstructionToExecute => InstructionToExecute,
        InstructionExecuted => InstructionExecuted,
        ALUOut => ALUOut,
        SMDR => SMDR,
        cond => cond,
        ALUNotReady => ALUNotReady,
        ret => ret
    );

	process
	begin

        reset <= '0';
        EXE_Stall <= '0';
        A <= x"00000000";
        B <= x"00000000";
        Af <= x"00000000";
        Bf <= x"00000000";
        InstructionToExecute <= x"00000";

        wait for PERIOD/2;
        reset <= '1';
        wait for PERIOD/2;
        reset <= '0';
        wait for PERIOD/2;

        

        wait;
    end process;
end TB;

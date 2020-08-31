-- Last version 24/07/2020 (12:48)

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity fpu_tb is
end fpu_tb;

architecture TB of fpu_tb is

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

            InstructionToExecute: in std_logic_vector(SX-1 downto 0);

            A: in std_logic_vector(FD-1 downto 0);
            B: in std_logic_vector(FD-1 downto 0);

            C: out std_logic_vector(FD-1 downto 0);

            FPUNotReady: out std_logic
    	);
    end component;

    constant SX: integer := 17;
    constant IO: integer := 4;
    constant IX: integer := 2;
    constant IY: integer := 11;
    constant FD: integer := 32;
    constant FM: integer := 23;
    constant FE: integer := 8;

    constant OP_ADD: std_logic_vector(SX-1 downto 0) := "00000000000100000";
    constant OP_SUB: std_logic_vector(SX-1 downto 0) := "00000000001100000";
    constant OP_MUL: std_logic_vector(SX-1 downto 0) := "00000000010100000";
    constant OP_DIV: std_logic_vector(SX-1 downto 0) := "00000000011100000";
    constant OP_CMP: std_logic_vector(SX-1 downto 0) := "00000000001100101";

    constant PERIOD: time := 10 ps;
    signal reset: std_logic;
    signal clk: std_logic := '0';

    signal InstructionToExecute: std_logic_vector(SX-1 downto 0);
    signal A: std_logic_vector(FD-1 downto 0);
    signal B: std_logic_vector(FD-1 downto 0);
    signal C: std_logic_vector(FD-1 downto 0);
    signal FPUNotReady: std_logic;

begin

    clk <= not clk after PERIOD/2;

    FPUM: fpu
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
        InstructionToExecute => InstructionToExecute,
        A => A,
        B => B,
        C => C,
        FPUNotReady => FPUNotReady
    );

	process
	begin

        reset <= '0';
        wait for PERIOD/2;

        reset <= '1';
        wait for PERIOD;

        reset <= '0';

        InstructionToExecute <= OP_ADD;
        A <= x"40A00000";
        B <= x"40C00000";
        wait for PERIOD;

        InstructionToExecute <= OP_SUB;
        A <= x"40A00000";
        B <= x"40C00000";
        wait for PERIOD;

        InstructionToExecute <= OP_MUL;
        A <= x"40A00000";
        B <= x"40C00000";
        wait for PERIOD;

        InstructionToExecute <= OP_DIV;
        A <= x"40A00000";
        B <= x"40C00000";
        wait for PERIOD;
        while FPUNotReady = '1' loop wait for PERIOD; end loop;

        InstructionToExecute <= OP_CMP;
        A <= x"40A00000";
        B <= x"40C00000";
        wait for PERIOD;

        A <= x"40A00000";
        B <= x"40C00000";
        wait for PERIOD;

        wait;
    end process;
end TB;

configuration FPUConfig of fpu_tb is
  for TB
    for FPUM : fpu
        use entity work.fpu(a);
    end for;
  end for;
end FPUConfig;

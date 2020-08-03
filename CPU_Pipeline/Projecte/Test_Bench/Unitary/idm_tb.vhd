-- Last version 24/07/2020 (13:03)

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity idm_tb is
end idm_tb;

architecture TB of idm_tb is

    component instruction_decode_module is
        generic (
            -- System
            SA: integer:= 32;
            SB: integer:= 5;
            SD: integer:= 32;
            SI: integer:= 32;
            SX: integer:= 17;

            -- Instruction
            IB: integer:= 5;
            IO: integer:= 4;
            IX: integer:= 2;
            IY: integer:= 11;
            IJ: integer:= 26
        );
        port (
            clk: in std_logic;
            ID_Stall: in std_logic;

            -- Connexions amb IFM
            IR: in std_logic_vector(SI-1 downto 0);
            PC: in std_logic_vector(SA-1 downto 0);

            -- Connexions amb el WBM
            R1: in std_logic_vector(SD-1 downto 0);
            R2: in std_logic_vector(SD-1 downto 0);

            rs: out std_logic_vector(SB-1 downto 0);
            rt: out std_logic_vector(SB-1 downto 0);
            rd: out std_logic_vector(SB-1 downto 0);

            op: out std_logic_vector(SX-1 downto 0);

            -- Connexions amb el ExeM
            A: out std_logic_vector(SD-1 downto 0);
            B: out std_logic_vector(SD-1 downto 0);
            Af: out std_logic_vector(SD-1 downto 0);
            Bf: out std_logic_vector(SD-1 downto 0);
            InstructionToExecute: out std_logic_vector(SX-1 downto 0)
    	);
    end component;

    constant SA: integer:= 32;
    constant SB: integer:= 5;
    constant SD: integer:= 32;
    constant SI: integer:= 32;
    constant SX: integer:= 17;
    constant IB: integer:= 5;
    constant IO: integer:= 4;
    constant IX: integer:= 2;
    constant IY: integer:= 11;
    constant IJ: integer:= 26;

    constant PERIOD: time := 10 ps;
    signal clk: std_logic := '0';
    signal reset: std_logic := '0';

    signal ID_Stall: std_logic;
    signal IR: std_logic_vector(SI-1 downto 0);
    signal PC: std_logic_vector(SA-1 downto 0);
    signal R1: std_logic_vector(SD-1 downto 0);
    signal R2: std_logic_vector(SD-1 downto 0);
    signal rs: std_logic_vector(SB-1 downto 0);
    signal rt: std_logic_vector(SB-1 downto 0);
    signal rd: std_logic_vector(SB-1 downto 0);
    signal op: std_logic_vector(SX-1 downto 0);
    signal A: std_logic_vector(SD-1 downto 0);
    signal B: std_logic_vector(SD-1 downto 0);
    signal Af: std_logic_vector(SD-1 downto 0);
    signal Bf: std_logic_vector(SD-1 downto 0);
    signal InstructionToExecute: std_logic_vector(SX-1 downto 0);

begin

    clk <= not clk after PERIOD/2;

    IDM: instruction_decode_module
    generic map (
        SA => SA,
        SB => SB,
        SD => SD,
        SI => SI,
        SX => SX,
        IB => IB,
        IO => IO,
        IX => IX,
        IY => IY,
        IJ => IJ
    ) port map (
        clk => clk,
        ID_Stall => ID_Stall,
        IR => IR,
        PC => PC,
        R1 => R1,
        R2 => R2,
        rs => rs,
        rt => rt,
        rd => rd,
        op => op,
        A => A,
        B => B,
        Af => Af,
        Bf => Bf,
        InstructionToExecute => InstructionToExecute
    );

	process
	begin

        ID_Stall <= '0';
        IR <= x"00000000";
        PC <= x"00000000";
        R1 <= x"00000000";
        R2 <= x"00000000";

        wait for PERIOD/2;

        IR <= x"DBDBDBDB";
        PC <= x"00000100";

        R1 <= x"54545454";
        R2 <= x"32323232";

        wait for PERIOD;

        IR <= x"BDBDBDBD";
        PC <= PC +4;

        R1 <= x"65656565";
        R2 <= x"32323232";

        wait for PERIOD;

        wait;
    end process;
end TB;

configuration IDMConfig of idm_tb is
  for TB
    for IDM : instruction_decode_module
        use entity work.instruction_decode_module(a);
    end for;
  end for;
end IDMConfig;

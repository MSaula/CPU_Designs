
library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity idm_ftb is
end idm_ftb;

architecture TB of idm_ftb is

    component instruction_fetch_module is
        generic (
            -- Bus
            BA: integer:= 32;
            BD: integer:= 32;
            BE: integer:= 2;

            -- System
            SA: integer:= 32;
            SD: integer:= 32;
            SI: integer:= 32
        );
        port (
            clk: in std_logic;
            reset: in std_logic;

            jump: in std_logic;
            ALUOut: in std_logic_vector(SD-1 downto 0);
            IF_Stall: in std_logic;

            RDATA: in std_logic_vector(BD-1 downto 0);
            RDATAV: in std_logic;
            RRESP: in std_logic_vector(BE-1 downto 0);


            PC: out std_logic_vector(SA-1 downto 0);
            IR: out std_logic_vector(SI-1 downto 0);
            ICDOK: out std_logic;

            RADDR: out std_logic_vector(BA-1 downto 0);
            RAVALID: out std_logic
    	);
    end component;

    component instruction_cache_memory is
        generic (
            CA: integer:= 0;
            CS: integer:= 1024;
            BA: integer:= 32;
            BD: integer:= 32;
            BE: integer:= 2
        );
        port (
            clk: in std_logic;

            RADDR: in std_logic_vector(BA-1 downto 0);
            RAVALID: in std_logic;
            RDATA: out std_logic_vector(BD-1 downto 0);
            RDATAV: out std_logic;
            RRESP: out std_logic_vector(BE-1 downto 0)
        );
    end component;

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

    constant CA: integer:= 0;
    constant CS: integer:= 1024;
    constant BA: integer:= 32;
    constant BD: integer:= 32;
    constant BE: integer:= 2;
    constant SA: integer:= 32;
    constant SD: integer:= 32;
    constant SI: integer:= 32;
    constant SB: integer:= 5;
    constant SX: integer:= 17;
    constant IB: integer:= 5;
    constant IO: integer:= 4;
    constant IX: integer:= 2;
    constant IY: integer:= 11;
    constant IJ: integer:= 26;

    constant PERIOD: time := 10 ps;
    signal clk: std_logic := '0';
    signal reset: std_logic := '0';

    signal jump: std_logic;
    signal ALUOut: std_logic_vector(SD-1 downto 0);
    signal IF_Stall: std_logic;
    signal RDATA: std_logic_vector(BD-1 downto 0);
    signal RDATAV: std_logic;
    signal RRESP: std_logic_vector(BE-1 downto 0);
    signal PC: std_logic_vector(SA-1 downto 0);
    signal IR: std_logic_vector(SI-1 downto 0);
    signal ICDOK: std_logic;
    signal RADDR: std_logic_vector(BA-1 downto 0);
    signal RAVALID: std_logic;

    signal ID_Stall: std_logic;
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

    IFM: instruction_fetch_module
    generic map (
        BA => BA,
        BD => BD,
        BE => BE,
        SA => SA,
        SD => SD,
        SI => SI
    ) port map (
        clk => clk,
        reset => reset,
        jump => jump,
        ALUOut => ALUOut,
        IF_Stall => IF_Stall,
        RDATA => RDATA,
        RDATAV => RDATAV,
        RRESP => RRESP,
        PC => PC,
        IR => IR,
        ICDOK => ICDOK,
        RADDR => RADDR,
        RAVALID => RAVALID
    );

    ICM: instruction_cache_memory
    generic map (
        CA => CA,
        CS => CS,
        BA => BA,
        BD => BD,
        BE => BE
    ) port map (
        clk => clk,
        RADDR => RADDR,
        RAVALID => RAVALID,
        RDATA => RDATA,
        RDATAV => RDATAV,
        RRESP => RRESP
    );

	process
	begin

        IF_Stall <= '0';
        ID_Stall <= '1';

        jump <= '0';
        ALUOut <= x"00000000";
        reset <= '0';

        IR <= x"00000000";
        PC <= x"00000000";
        R1 <= x"00000000";
        R2 <= x"00000000";

        wait for PERIOD/2;
        reset <= '1';

        wait for PERIOD/2;
        reset <= '0';

        wait for PERIOD*(3/2);

        ID_Stall <= '0';
        R1 <= x"65656565";
        R2 <= x"32323232";

        for i in 1 to 5 loop
            wait for PERIOD;
        end loop;

        ALUOut <= x"00000014";
        jump <= '1';
        wait for PERIOD;

        R2 <= x"65656565";
        R1 <= x"32323232";
        jump <= '0';

        for i in 1 to 5 loop
            wait for PERIOD;
        end loop;

        IF_Stall <= '1';

        for i in 1 to 5 loop
            wait for PERIOD;
        end loop;

        IF_Stall <= '0';

        wait;
    end process;
end TB;

-- configuration IFMFConfig of ifm_ftb is
--   for TB
--     for IFM : instruction_fetch_module
--         use entity work.instruction_fetch_module(a);
--     end for;
--   end for;
-- end IFMFConfig;

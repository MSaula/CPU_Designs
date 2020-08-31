-- Last version 24/07/2020 (13:02)

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity ifm_ftb is
end ifm_ftb;

architecture TB of ifm_ftb is

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

    constant CA: integer:= 0;
    constant CS: integer:= 1024;
    constant BA: integer:= 32;
    constant BD: integer:= 32;
    constant BE: integer:= 2;
    constant SA: integer:= 32;
    constant SD: integer:= 32;
    constant SI: integer:= 32;

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

begin

    clk <= not clk after PERIOD/2;

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

        jump <= '0';
        ALUOut <= x"00000000";
        IF_Stall <= '0';
        reset <= '0';

        wait for PERIOD/2;
        reset <= '1';

        wait for PERIOD/2;
        reset <= '0';

        wait for PERIOD/2;

        for i in 1 to 5 loop
            wait for PERIOD;
        end loop;

        ALUOut <= x"00000008";
        jump <= '1';
        wait for PERIOD;

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

configuration IFMFConfig of ifm_ftb is
  for TB
    for IFM : instruction_fetch_module
        use entity work.instruction_fetch_module(a);
    end for;
  end for;
end IFMFConfig;

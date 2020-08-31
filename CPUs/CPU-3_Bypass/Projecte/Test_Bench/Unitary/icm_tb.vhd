-- Last version 24/07/2020 (12:50)

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity icm_tb is
end icm_tb;

architecture TB of icm_tb is

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

    constant PERIOD: time := 10 ps;
    signal clk: std_logic := '0';

    signal RADDR: std_logic_vector(BA-1 downto 0);
    signal RAVALID: std_logic;
    signal RDATA: std_logic_vector(BD-1 downto 0);
    signal RDATAV: std_logic;
    signal RRESP: std_logic_vector(BE-1 downto 0);

begin

    clk <= not clk after PERIOD/2;

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

        wait for PERIOD/2;

        RADDR <= x"00000000";
        RAVALID <= '1';
        wait for PERIOD;

        for i in 0 to 10 loop
            RADDR <= RADDR +4;
            RAVALID <= '1';
            wait for PERIOD;
        end loop;

        RADDR <= x"00000020";
        RAVALID <= '0';

        wait for PERIOD*3;

        RAVALID <= '1';
        wait for PERIOD;

        for i in 0 to 5 loop
            RADDR <= RADDR +4;
            RAVALID <= '1';
            wait for PERIOD;
        end loop;

        RADDR <= x"00300000";
        RAVALID <= '0';

        wait for PERIOD*3;

        RAVALID <= '1';
        wait for PERIOD;

        for i in 0 to 5 loop
            RADDR <= RADDR +4;
            RAVALID <= '1';
            wait for PERIOD;
        end loop;

        wait;
    end process;
end TB;

configuration ICMConfig of icm_tb is
  for TB
    for ICM : instruction_cache_memory
        use entity work.instruction_cache_memory(a);
    end for;
  end for;
end ICMConfig;

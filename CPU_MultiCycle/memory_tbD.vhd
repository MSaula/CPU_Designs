
library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity memory_tb is
end memory_tb;

architecture TB of memory_tb is

    component memory is
        generic (
            lenght: integer := 64;
            addr_size : integer := 6;
            size : integer := 32
        );
        port (
            --INPUTS
            RADDR: in std_logic_vector(addr_size-1 downto 0);
            RAVALID: in std_logic;
            WADDR: in std_logic_vector(addr_size-1 downto 0);
            WAVALID: in std_logic;
            WDATA: in std_logic_vector(size-1 downto 0);
            WDATAV: in std_logic;
            clk: in std_logic;
            reset: in std_logic;

            --OUTPUTS
            RDATA: out std_logic_vector(size-1 downto 0);
            RDATAV: out std_logic;
            RRESP: out std_logic_vector(1 downto 0);
            WRESP: out std_logic_vector(1 downto 0);
            WRESPV: out std_logic
    	);
    end component;

    component memory_driver is
        generic (
            size : integer := 6;
            word_size : integer := 32
        );
        port (
            --INPUTS
            clk: in std_logic;
            reset: in std_logic;

            --Inputs from ALU
            FALU: in std_logic;
            RnWalu: in std_logic;
            AddrALU: in std_logic_vector(size-1 downto 0);
            DataAlu: in std_logic_vector(word_size-1 downto 0);

            --Inputs from UC
            FCU: in std_logic;
            RnWCU: in std_logic;
            AddrCU: in std_logic_vector(size-1 downto 0);
            DataCU: in std_logic_vector(word_size-1 downto 0);

            --Inputs from Memory
            RDATA: in std_logic_vector(word_size-1 downto 0);
            RDATAV: in std_logic;
            RRESP: in std_logic_vector(1 downto 0);
            WRESP: in std_logic_vector(1 downto 0);
            WRESPV: in std_logic;

    --------------------------------------------------------------------------------
            --OUTPUTS

            --Main outputs
            busy: out std_logic;
            readOut: out std_logic_vector(word_size-1 downto 0);
            resp: out std_logic_vector(1 downto 0);

            --To memory outputs
            WADDR: out std_logic_vector(size-1 downto 0);
            WAVALID: out std_logic;
            WDATA: out std_logic_vector(word_size-1 downto 0);
            WDATAV: out std_logic;
            RADDR: out std_logic_vector(size-1 downto 0);
            RAVALID: out std_logic
    	);
    end component;

constant size: integer := 6;
constant word_size: integer := 32;

signal RADDRR: std_logic_vector(size-1 downto 0);
signal RAVALIDD: std_logic;
signal WADDRR: std_logic_vector(size-1 downto 0);
signal WAVALIDD: std_logic;
signal WDATAA: std_logic_vector(word_size-1 downto 0);
signal WDATAVV: std_logic;
signal clkk: std_logic := '0';
signal resett: std_logic;

signal RDATAA: std_logic_vector(word_size-1 downto 0);
signal RDATAVV: std_logic;
signal RRESPP: std_logic_vector(1 downto 0);
signal WRESPP: std_logic_vector(1 downto 0);
signal WRESPVV: std_logic;

signal FALUU: std_logic;
signal RnWaluu: std_logic;
signal AddrALUU: std_logic_vector(size-1 downto 0);
signal DataAluu: std_logic_vector(word_size-1 downto 0);

signal FCUU: std_logic;
signal RnWCUU: std_logic;
signal AddrCUU: std_logic_vector(size-1 downto 0);
signal DataCUU: std_logic_vector(word_size-1 downto 0);

signal busyy: std_logic;
signal readOutt: std_logic_vector(word_size-1 downto 0);
signal respp: std_logic_vector(1 downto 0);

constant PERIOD: time := 10 ps;

begin

	clkk <= not clkk after PERIOD /2;

	M: memory
    generic map(
        lenght => 16,
        addr_size => 6,
        size => 32
    )
    port map(
        RADDR => RADDRR,
        RAVALID => RAVALIDD,
        WADDR => WADDRR,
        WAVALID => WAVALIDD,
        WDATA => WDATAA,
        WDATAV => WDATAVV,
        clk => clkk,
        reset => resett,

        RDATA => RDATAA,
        RDATAV => RDATAVV,
        RRESP => RRESPP,
        WRESP => WRESPP,
        WRESPV => WRESPVV
	);

    MD: memory_driver
    generic map(
        size => 6,
        word_size => 32
    )
    port map(

        clk => clkk,
        reset => resett,

        FALU => FALUU,
        RnWalu => RnWaluu,
        AddrALU => AddrALUU,
        DataAlu => DataAluu,

        FCU => FCUU,
        RnWCU => RnWCUU,
        AddrCU => AddrCUU,
        DataCU => DataCUU,

        RDATA => RDATAA,
        RDATAV => RDATAVV,
        RRESP => RRESPP,
        WRESP => WRESPP,
        WRESPV => WRESPVV,

        busy => busyy,
        readOut => readOutt,
        resp => respp,

        WADDR => WADDRR,
        WAVALID => WAVALIDD,
        WDATA => WDATAA,
        WDATAV => WDATAVV,
        RADDR => RADDRR,
        RAVALID => RAVALIDD
    );

	process
	begin

		resett <= '0';

        FALUU <= '0';
        RnWaluu <= '0';
        AddrALUU <= (others => '0');
        DataAluu <= (others => '0');

        FCUU <= '0';
        RnWCUU <= '0';
        AddrCUU <= (others => '0');
        DataCUU <= (others => '0');


   	wait for PERIOD;
		resett <= '1';

   	wait for PERIOD;
		resett <= '0';

    wait for PERIOD * 5;


    for i in 0 to 4 loop
            AddrALUU <= AddrALUU +1;
            DataAluu <= not DataAluu;

       	wait for PERIOD;
    		FALUU <= '1';

      	wait for PERIOD;
    		FALUU <= '0';

        while busyy = '1' loop
            wait for PERIOD;
        end loop;
    end loop;

    RnWaluu <= '1';
    AddrALUU <= (others => '0');
    wait for PERIOD;

    for i in 0 to 5 loop
            AddrALUU <= AddrALUU +1;

       	wait for PERIOD;
    		FALUU <= '1';

      	wait for PERIOD;
    		FALUU <= '0';

        while busyy = '1' loop
            wait for PERIOD;
        end loop;
    end loop;

    wait;
  end process;
end TB;

configuration memTBConfig of memory_tb is
  for TB
    for M : memory
        use entity work.memory(bhv);
    end for;
    for MD : memory_driver
        use entity work.memory_driver(bhv);
    end for;
  end for;
end memTBConfig;
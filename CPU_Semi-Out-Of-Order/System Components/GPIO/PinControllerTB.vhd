
library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;
use work.types_definitions.all;

entity pc_tb is
end pc_tb;

architecture TB of pc_tb is

	component PinController
		generic (
	        pinsPerBlock: integer := 8;
	        addrSize : integer := 32;
	        dataSize : integer := 32;
	        respSize : integer := 2;

	        baseAddress: integer := 0;
	        addressValue: integer := 0;
	        totalSingleSize: integer := 32;

	        isOW: std_logic := '0';
	        isOR: std_logic := '0'
	    );
	    port (
	        pin: inout std_logic_vector(pinsPerBlock-1 downto 0);

	        WADDR: in std_logic_vector(addrSize-1 downto 0);
	        WAVALID: in std_logic;
	        WDATA: in std_logic_vector(dataSize-1 downto 0);
	        WDATAV: in std_logic;
	        WCOMPLETE: out std_logic;

	        RADDR: in std_logic_vector(addrSize-1 downto 0);
	        RAVALID: in std_logic;
	        RDATA: out std_logic_vector(dataSize-1 downto 0);
	        RDATAV: out std_logic;

	        clk: in std_logic;
	        reset: in std_logic
	    );
	end component PinController;

constant PERIOD: time := 10 ps;
signal reset: std_logic;
signal clk: std_logic := '0';

signal pin: std_logic_vector(7 downto 0);

signal WADDR : std_logic_vector(31 downto 0);
signal WAVALID : std_logic;
signal WDATA : std_logic_vector(31 downto 0);
signal WDATAV : std_logic;
signal WCOMPLETE : std_logic;

signal RADDR : std_logic_vector(31 downto 0);
signal RAVALID : std_logic;
signal RDATA : std_logic_vector(31 downto 0);
signal RDATAV : std_logic;

begin
	clk <= not clk after PERIOD/2;

	PC: PinController
	generic map (
		pinsPerBlock => 8,
		addrSize => 32,
		dataSize => 32,
		respSize => 2,

		baseAddress => 0,
		addressValue => 0,
		totalSingleSize => 32,

		isOW => '0',
		isOR => '0'
	)
	port map (
		pin => pin,

		WADDR => WADDR,
		WAVALID => WAVALID,
		WDATA => WDATA,
		WDATAV => WDATAV,
		WCOMPLETE => WCOMPLETE,

		RADDR => RADDR,
		RAVALID => RAVALID,
		RDATA => RDATA,
		RDATAV => RDATAV,

		clk => clk,
		reset => reset
	);

	process
	begin

		pin <= (others => 'Z');
		WADDR <= x"00000000";
		WAVALID <= '0';
		WDATA <= x"000000F8";
		WDATAV <= '0';

		RADDR <= x"00000001";
		RAVALID <= '0';

		reset <= '0';
		wait for PERIOD;
		reset <= '1';
		wait for PERIOD;
		reset <= '0';
		wait for PERIOD;

		-- Write Test
		WAVALID <= '1';
		WDATAV <= '1';
		while WCOMPLETE = '0' loop
			wait for PERIOD;
		end loop;

		WAVALID <= '0';
		WDATAV <= '0';
		wait for PERIOD;

		WADDR <= x"00000020";
		WDATA <= x"000000FF";
		wait for PERIOD;

		WAVALID <= '1';
		WDATAV <= '1';
		while WCOMPLETE = '0' loop
			wait for PERIOD;
		end loop;

		WAVALID <= '0';
		WDATAV <= '0';
		wait for PERIOD*3;

		WDATA <= x"00000000";
		wait for PERIOD;

		WAVALID <= '1';
		WDATAV <= '1';
		while WCOMPLETE = '0' loop
			wait for PERIOD;
		end loop;

		WAVALID <= '0';
		WDATAV <= '0';
		wait for PERIOD*3;

		-- Read Test from LAT
		pin <= x"8F";
		RADDR <= x"00000000";
		wait for PERIOD;

		RAVALID <= '1';
		while RDATAV = '0' loop
			wait for PERIOD;
		end loop;

		RAVALID <= '0';
		wait for PERIOD;

		-- Read Test from PORT
		RADDR <= x"00000040";
		wait for PERIOD;

		RAVALID <= '1';
		while RDATAV = '0' loop
			wait for PERIOD;
		end loop;

		RAVALID <= '0';
		wait for PERIOD;

		wait;
  end process;
end TB;

configuration PCConfig of pc_tb is
  for TB
    for PC : PinController
        use entity work.PinController(a);
    end for;
  end for;
end PCConfig;

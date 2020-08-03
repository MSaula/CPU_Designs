library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;
use work.gpio_configuration.all;

entity gpio_tb is
end gpio_tb;

architecture TB of gpio_tb is

	component gpio
	generic (
        -- Dimensionat de busos
        pinsPerBlock: integer := PinsPerBloc;
        busAddrSize : integer := addrSize;
        busDataSize : integer := dataSize;
        respSize : integer := 2;

        -- Estructura de la GPIO
        baseAddress: integer := 0;
        totalSingleSize: integer := 32;
        totalComponents: integer := 22;

        -- Defineix la quantitat de components de nomÃ©s lectura o nomÃ©s escriptura.
        -- La organitzaciÃ³ serÃ  de que les OR anirÃ n al primer rang d'addr, les OW
        -- al segon i les bidireccionals al
        ORComponents: integer := 2;
        OWComponents: integer := 8
    );
	port (
		-- Pinout del sistema
		pin: inout std_logic_vector((PinsPerBloc * totalComponents)-1 downto 0);

		-- Bus d'escriptura del sistema
		WADDR: in std_logic_vector(addrSize-1 downto 0);
		WAVALID: in std_logic;
		WDATA: in std_logic_vector(dataSize-1 downto 0);
		WDATAV: in std_logic;
		WRESP: out std_logic_vector(respSize-1 downto 0);
		WRESPV: out std_logic;

		-- Bus de lectura del sistema
		RADDR: in std_logic_vector(addrSize-1 downto 0);
		RAVALID: in std_logic;
		RDATA: out std_logic_vector(dataSize-1 downto 0);
		RDATAV: out std_logic;
		RRESP: out std_logic_vector(respSize-1 downto 0);

		clk: in std_logic;
		reset: in std_logic
	);
end component gpio;

constant PERIOD: time := 10 ps;
signal reset: std_logic;
signal clk: std_logic := '0';

signal pins: std_logic_vector((PinsPerBloc * totalComponents)-1 downto 0);

signal WADDR : std_logic_vector(31 downto 0);
signal WAVALID : std_logic;
signal WDATA : std_logic_vector(31 downto 0);
signal WDATAV : std_logic;
signal WRESP : std_logic_vector(1 downto 0);
signal WRESPV : std_logic;

signal RADDR : std_logic_vector(31 downto 0);
signal RAVALID : std_logic;
signal RDATA : std_logic_vector(31 downto 0);
signal RDATAV : std_logic;
signal RRESP : std_logic_vector(1 downto 0);

begin
	clk <= not clk after PERIOD/2;

	GPIOModule: gpio
	generic map (
    pinsPerBlock => PinsPerBloc,
    busAddrSize => addrSize,
    busDataSize => dataSize,
    respSize => 2,

    baseAddress => 0,
    totalSingleSize => 32,
    totalComponents => 22,

    ORComponents => 2,
    OWComponents => 8
  )
	port map (
		pin => pins,

		WADDR => WADDR,
		WAVALID => WAVALID,
		WDATA => WDATA,
		WDATAV => WDATAV,
		WRESP => WRESP,
		WRESPV => WRESPV,

		RADDR => RADDR,
		RAVALID => RAVALID,
		RDATA => RDATA,
		RDATAV => RDATAV,
		RRESP => RRESP,

		clk => clk,
		reset => reset
	);

	process
	begin

		pins <= (others => 'Z');

		pins(7 downto 0) <= x"AB";

		WADDR <= x"00000002";
		WAVALID <= '0';
		WDATA <= x"000000BA";
		WDATAV <= '0';

		--RADDR <= x"00000040";
    RADDR <= x"00000000";
		RAVALID <= '0';

		reset <= '0';
		wait for PERIOD;
		reset <= '1';
		wait for PERIOD;
		reset <= '0';
		wait for PERIOD;

		-- *                         * --
		---------------------------------
		-----   < READ TEST LAT >   -----
		---------------------------------
		-- *                         * --

    RADDR <= x"00000000";
    wait for PERIOD;

		RAVALID <= '1';
		while RDATAV /= '1' loop
		  wait for PERIOD;
		end loop;
		RAVALID <= '0';

		wait for PERIOD;

		-- *                          * --
		----------------------------------
		-----   < READ TEST TRIS >   -----
		----------------------------------
		-- *                          * --

    RADDR <= x"00000020";
    wait for PERIOD;

		RAVALID <= '1';
		while RDATAV /= '1' loop
		  wait for PERIOD;
		end loop;
		RAVALID <= '0';

		wait for PERIOD;

		-- *                          * --
		----------------------------------
		-----   < READ TEST PORT >   -----
		----------------------------------
		-- *                          * --

    RADDR <= x"00000040";
    wait for PERIOD;

		RAVALID <= '1';
		while RDATAV /= '1' loop
		  wait for PERIOD;
		end loop;
		RAVALID <= '0';

		wait for PERIOD;

		-- *                          * --
		----------------------------------
		-----   < WRITE TEST LAT >   -----
		----------------------------------
		-- *                          * --

    WADDR <= x"00000002";
    wait for PERIOD;

		WAVALID <= '1';
		WDATAV <= '1';
		while WRESPV = '0' loop
			wait for PERIOD;
		end loop;
		WAVALID <= '0';
		WDATAV <= '0';

		-- *                           * --
		-----------------------------------
		-----   < WRITE TEST TRIS >   -----
		-----------------------------------
		-- *                           * --

    WADDR <= x"00000030";
    wait for PERIOD;

		WAVALID <= '1';
		WDATAV <= '1';
		while WRESPV = '0' loop
			wait for PERIOD;
		end loop;
		WAVALID <= '0';
		WDATAV <= '0';

		-- *                           * --
		-----------------------------------
		-----   < WRITE TEST PORT >   -----
		-----------------------------------
		-- *          (ERROR)          * --

    WADDR <= x"00000042";
    wait for PERIOD;

		WAVALID <= '1';
		WDATAV <= '1';
		while WRESPV = '0' loop
			wait for PERIOD;
		end loop;
		WAVALID <= '0';
		WDATAV <= '0';

		-- *                         * --
		---------------------------------
		-----   < READ TEST LAT >   -----
		---------------------------------
		-- *                         * --

    WADDR <= x"FFFFFFFF";
    RADDR <= x"00000002";
    wait for PERIOD;

		RAVALID <= '1';
		while RDATAV /= '1' loop
		  wait for PERIOD;
		end loop;
		RAVALID <= '0';

		wait for PERIOD;

		-- *                          * --
		----------------------------------
		-----   < READ TEST TRIS >   -----
		----------------------------------
		-- *                          * --

    RADDR <= x"00000030";
    wait for PERIOD;

		RAVALID <= '1';
		while RDATAV /= '1' loop
		  wait for PERIOD;
		end loop;
		RAVALID <= '0';

		wait for PERIOD;

		wait;
  end process;
end TB;

configuration GPIOConfig of gpio_tb is
  for TB
    for GPIOModule : gpio
        use entity work.gpio(a);
    end for;
  end for;
end GPIOConfig;

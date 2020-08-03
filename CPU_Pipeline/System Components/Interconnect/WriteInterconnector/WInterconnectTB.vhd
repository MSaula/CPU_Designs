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

entity wi_tb is
end wi_tb;

architecture TB of wi_tb is

	component wiaux is
		port (
			reset: in std_logic;
			clk: in std_logic;

			M1_WADDR: in std_logic_vector(31 downto 0);
			M1_WAVALID: in std_logic;
			M1_WDATA: in std_logic_vector(31 downto 0);
			M1_WDATAV: in std_logic;
			M1_WRESP: out std_logic_vector(1 downto 0);
			M1_WRESPV: out std_logic;

			S1_WADDR: out std_logic_vector(31 downto 0);
			S1_WAVALID: out std_logic;
			S1_WDATA: out std_logic_vector(31 downto 0);
			S1_WDATAV: out std_logic;
			S1_WRESP: in std_logic_vector(1 downto 0);
			S1_WRESPV: in std_logic;

			M2_WADDR: in std_logic_vector(31 downto 0);
			M2_WAVALID: in std_logic;
			M2_WDATA: in std_logic_vector(31 downto 0);
			M2_WDATAV: in std_logic;
			M2_WRESP: out std_logic_vector(1 downto 0);
			M2_WRESPV: out std_logic;

			S2_WADDR: out std_logic_vector(31 downto 0);
			S2_WAVALID: out std_logic;
			S2_WDATA: out std_logic_vector(31 downto 0);
			S2_WDATAV: out std_logic;
			S2_WRESP: in std_logic_vector(1 downto 0);
			S2_WRESPV: in std_logic
	      );
	end component wiaux;

constant PERIOD: time := 10 ps;
signal reset: std_logic;
signal clk: std_logic := '0';

signal M1_WADDR: std_logic_vector(31 downto 0);
signal M1_WAVALID: std_logic;
signal M1_WDATA: std_logic_vector(31 downto 0);
signal M1_WDATAV: std_logic;
signal M1_WRESP: std_logic_vector(1 downto 0);
signal M1_WRESPV: std_logic;

signal S1_WADDR: std_logic_vector(31 downto 0);
signal S1_WAVALID: std_logic;
signal S1_WDATA: std_logic_vector(31 downto 0);
signal S1_WDATAV: std_logic;
signal S1_WRESP: std_logic_vector(1 downto 0);
signal S1_WRESPV: std_logic;

signal M2_WADDR: std_logic_vector(31 downto 0);
signal M2_WAVALID: std_logic;
signal M2_WDATA: std_logic_vector(31 downto 0);
signal M2_WDATAV: std_logic;
signal M2_WRESP: std_logic_vector(1 downto 0);
signal M2_WRESPV: std_logic;

signal S2_WADDR: std_logic_vector(31 downto 0);
signal S2_WAVALID: std_logic;
signal S2_WDATA: std_logic_vector(31 downto 0);
signal S2_WDATAV: std_logic;
signal S2_WRESP: std_logic_vector(1 downto 0);
signal S2_WRESPV: std_logic;


begin

  clk <= not clk after PERIOD/2;

	WI: wiaux
	port map(
		reset => reset,
		clk => clk,

		M1_WADDR => M1_WADDR,
		M1_WAVALID => M1_WAVALID,
		M1_WDATA => M1_WDATA,
		M1_WDATAV => M1_WDATAV,
		M1_WRESP => M1_WRESP,
		M1_WRESPV => M1_WRESPV,

		S1_WADDR => S1_WADDR,
		S1_WAVALID => S1_WAVALID,
		S1_WDATA => S1_WDATA,
		S1_WDATAV => S1_WDATAV,
		S1_WRESP => S1_WRESP,
		S1_WRESPV => S1_WRESPV,

		M2_WADDR => M2_WADDR,
		M2_WAVALID => M2_WAVALID,
		M2_WDATA => M2_WDATA,
		M2_WDATAV => M2_WDATAV,
		M2_WRESP => M2_WRESP,
		M2_WRESPV => M2_WRESPV,

		S2_WADDR => S2_WADDR,
		S2_WAVALID => S2_WAVALID,
		S2_WDATA => S2_WDATA,
		S2_WDATAV => S2_WDATAV,
		S2_WRESP => S2_WRESP,
		S2_WRESPV => S2_WRESPV
	);

	process
	begin

	  --wait for PERIOD/4;

		M1_WAVALID <= '0';
		M2_WAVALID <= '0';
		M1_WDATAV <= '0';
		M2_WDATAV <= '0';

		S1_WRESP <= "00";
    S2_WRESP <= "01";
    S1_WRESPV <= '0';
    S2_WRESPV <= '0';

		reset <= '0';
		wait for PERIOD;
		reset <= '1';
		wait for PERIOD;
		reset <= '0';
		wait for PERIOD;


    -- *                  * --
    --------------------------
    ---  < SINGLE WRITE >  ---
    --------------------------
    -- *                  * --

    M1_WADDR <= x"00000020";
    M1_WDATA <= x"FAFAFABC";
    wait for PERIOD;

    M1_WAVALID <= '1';
    M1_WDATAV <= '1';
    wait for PERIOD;

    S1_WRESP <= "00";
    wait for PERIOD;

    S1_WRESPV <= '1';
    wait for PERIOD;

    S1_WRESPV <= '0';
    M1_WAVALID <= '0';
    M1_WDATAV <= '0';


    -- *                    * --
    ----------------------------
    ---  < PARALLEL WRITE >  ---
    ----------------------------
    -- *                    * --

    M1_WADDR <= x"00000404";
    M2_WADDR <= x"00000020";
    M1_WDATA <= x"FAFAFABC";
    M2_WDATA <= x"25252567";
    wait for PERIOD;

    M1_WAVALID <= '1';
    M1_WDATAV <= '1';
    M2_WDATAV <= '1';
    M2_WAVALID <= '1';
    wait for PERIOD;

    S1_WRESP <= "00";
    S2_WRESP <= "01";
    wait for PERIOD;

    S1_WRESPV <= '1';
    S2_WRESPV <= '1';
    wait for PERIOD;

    S1_WRESPV <= '0';
    S2_WRESPV <= '0';
    M1_WAVALID <= '0';
    M1_WDATAV <= '0';
    M2_WAVALID <= '0';
    M2_WDATAV <= '0';


    -- *                                * --
    ----------------------------------------
    ---  < COLLISION & PARALLEL WRITE >  ---
    ----------------------------------------
    -- *                                * --

    M1_WADDR <= x"00000002";
    M2_WADDR <= x"00000020";
    M1_WDATA <= x"FAFAFABC";
    M2_WDATA <= x"25252567";
    wait for PERIOD;

    M1_WAVALID <= '1';
    M1_WDATAV <= '1';
    wait for PERIOD;

    M2_WDATAV <= '1';
    M2_WAVALID <= '1';
    wait for PERIOD;

    S1_WRESP <= "00";
    wait for PERIOD;

    S1_WRESPV <= '1';
    wait for PERIOD;

    S1_WRESPV <= '0';
    M1_WAVALID <= '0';
    M1_WDATAV <= '0';
    wait for PERIOD;

    M1_WADDR <= x"00000404";
    wait for PERIOD;

    M1_WAVALID <= '1';
    M1_WDATAV <= '1';
    wait for PERIOD;

    S1_WRESP <= "00";
    S2_WRESP <= "01";
    wait for PERIOD;

    S1_WRESPV <= '1';
    S2_WRESPV <= '1';
    wait for PERIOD;

    S1_WRESPV <= '0';
    S2_WRESPV <= '0';
    M1_WAVALID <= '0';
    M1_WDATAV <= '0';
    M2_WAVALID <= '0';
    M2_WDATAV <= '0';

		-- *                    * --
    ----------------------------
    ---  < PARALLEL WRITE >  ---
    ----------------------------
    -- *       (Error)      * --

    M1_WADDR <= x"80000404";
    M2_WADDR <= x"80000020";
    M1_WDATA <= x"FAFAFABC";
    M2_WDATA <= x"25252567";
    wait for PERIOD;

    M1_WAVALID <= '1';
    M1_WDATAV <= '1';
    M2_WDATAV <= '1';
    M2_WAVALID <= '1';
    wait for PERIOD;

    M1_WAVALID <= '0';
    M1_WDATAV <= '0';
    M2_WAVALID <= '0';
    M2_WDATAV <= '0';

		wait;
  end process;
end TB;

configuration WIConfig of wi_tb is
  for TB
    for WI : wiaux
        use entity work.wiaux(a);
    end for;
  end for;
end WIConfig;

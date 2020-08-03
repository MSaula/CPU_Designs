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

entity ri_tb is
end ri_tb;

architecture TB of ri_tb is

	component riaux is
	    port (
	     reset: in std_logic;
	     clk : in std_logic;

			 M1_RADDR: in std_logic_vector(31 downto 0);
	        M1_RAVALID: in std_logic;
	        M1_RDATA: out std_logic_vector(31 downto 0);
	        M1_RDATAV: out std_logic;
	        M1_RRESP: out std_logic_vector(1 downto 0);

	        S1_RADDR: out std_logic_vector(31 downto 0);
	        S1_RAVALID: out std_logic;
	        S1_RDATA: in std_logic_vector(31 downto 0);
	        S1_RDATAV: in std_logic;
	        S1_RRESP: in std_logic_vector(1 downto 0);

	        M2_RADDR: in std_logic_vector(31 downto 0);
	        M2_RAVALID: in std_logic;
	        M2_RDATA: out std_logic_vector(31 downto 0);
	        M2_RDATAV: out std_logic;
	        M2_RRESP: out std_logic_vector(1 downto 0);

	        S2_RADDR: out std_logic_vector(31 downto 0);
	        S2_RAVALID: out std_logic;
	        S2_RDATA: in std_logic_vector(31 downto 0);
	        S2_RDATAV: in std_logic;
	        S2_RRESP: in std_logic_vector(1 downto 0)
	    );
	end component riaux;

constant PERIOD: time := 10 ps;
signal reset: std_logic;
signal clk: std_logic := '0';

signal M1_RADDR: std_logic_vector(31 downto 0);
signal M1_RAVALID: std_logic;
signal M1_RDATA: std_logic_vector(31 downto 0);
signal M1_RDATAV: std_logic;
signal M1_RRESP: std_logic_vector(1 downto 0);

signal S1_RADDR: std_logic_vector(31 downto 0);
signal S1_RAVALID: std_logic;
signal S1_RDATA: std_logic_vector(31 downto 0);
signal S1_RDATAV: std_logic;
signal S1_RRESP: std_logic_vector(1 downto 0);

signal M2_RADDR: std_logic_vector(31 downto 0);
signal M2_RAVALID: std_logic;
signal M2_RDATA: std_logic_vector(31 downto 0);
signal M2_RDATAV: std_logic;
signal M2_RRESP: std_logic_vector(1 downto 0);

signal S2_RADDR: std_logic_vector(31 downto 0);
signal S2_RAVALID: std_logic;
signal S2_RDATA: std_logic_vector(31 downto 0);
signal S2_RDATAV: std_logic;
signal S2_RRESP: std_logic_vector(1 downto 0);


begin
  
  clk <= not clk after PERIOD/2;

	RI: riaux
	port map(
		reset => reset,
		clk => clk,

		M1_RADDR => M1_RADDR,
		M1_RAVALID => M1_RAVALID,
		M1_RDATA => M1_RDATA,
		M1_RDATAV => M1_RDATAV,
		M1_RRESP => M1_RRESP,

		S1_RADDR => S1_RADDR,
		S1_RAVALID => S1_RAVALID,
		S1_RDATA => S1_RDATA,
		S1_RDATAV => S1_RDATAV,
		S1_RRESP => S1_RRESP,

		M2_RADDR => M2_RADDR,
		M2_RAVALID => M2_RAVALID,
		M2_RDATA => M2_RDATA,
		M2_RDATAV => M2_RDATAV,
		M2_RRESP => M2_RRESP,

		S2_RADDR => S2_RADDR,
		S2_RAVALID => S2_RAVALID,
		S2_RDATA => S2_RDATA,
		S2_RDATAV => S2_RDATAV,
		S2_RRESP => S2_RRESP
	);

	process
	begin
	  
	  --wait for PERIOD/4;
	  
		M1_RAVALID <= '0';
		M2_RAVALID <= '0';
		
		S1_RDATA <= (others => '0');
    S2_RDATA <= (others => '0');
    S1_RRESP <= "00";
    S2_RRESP <= "01";
    S1_RDATAV <= '0';
    S2_RDATAV <= '0';

		reset <= '0';
		wait for PERIOD;
		reset <= '1';
		wait for PERIOD;
		reset <= '0';
		wait for PERIOD;

		M2_RADDR <= x"000004F0";
		M1_RADDR <= x"00000080";

		wait for PERIOD;
		M2_RAVALID <= '1';
		wait for PERIOD;
		M1_RAVALID <= '1';
		wait for PERIOD * 2;
		
		S1_RDATA <= x"AAAAAAAA";
    S2_RDATA <= x"55555555";
    
    wait for PERIOD;
    
    S1_RDATAV <= '1';
    S2_RDATAV <= '1';
    
    wait for PERIOD;
    
    S1_RDATAV <= '0';
    S2_RDATAV <= '0';
    
    wait for PERIOD;
    
    M1_RAVALID <= '0';
		M2_RAVALID <= '0';
	
	  wait for PERIOD;
  
    M2_RADDR <= x"000000F0";
		M1_RADDR <= x"000000E0";

    wait for PERIOD;
    
    M2_RAVALID <= '1';
    
    wait for PERIOD;
    
    M1_RAVALID <= '1';
    
    wait for PERIOD;
    
    S1_RDATAV <= '1';
    wait for PERIOD;
    S1_RDATAV <= '0';
    wait for PERIOD;
    S1_RDATAV <= '1';
    wait for PERIOD;
    S1_RDATAV <= '0';
    wait for PERIOD;
    

		wait;
  end process;
end TB;

configuration RIConfig of ri_tb is
  for TB
    for RI : riaux
        use entity work.riaux(a);
    end for;
  end for;
end RIConfig;

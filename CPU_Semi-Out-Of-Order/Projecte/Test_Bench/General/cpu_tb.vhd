library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity cpu_tb is
end cpu_tb;

architecture TB of cpu_tb is

	component cpu is
	    generic (
	        -- Bus
	        BA: integer:= 32;
	        BD: integer:= 32;
	        BE: integer:= 2;

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
	        IJ: integer:= 26;

	        -- Floating Point
	        FD: integer:= 32;
	        FM: integer:= 23;
	        FE: integer:= 8;

	        -- Instruction Cache Memory
	        CA: integer:= 0;
	        CS: integer:= 1024;

	        -- LIFO
	        LS: integer := 32;
	        
	        BC: integer := 8
	    );
	    port (
	        clk: in std_logic;
	        reset: in std_logic;

	        RDATA: in std_logic_vector(BD-1 downto 0);
	        RDATAV: in std_logic;
	        RADDR: out std_logic_vector(BA-1 downto 0);
	        RAVALID: out std_logic;
	        RRESP: in std_logic_vector(BE-1 downto 0);

	        WDATA: out std_logic_vector(BD-1 downto 0);
	        WDATAV: out std_logic;
	        WADDR: out std_logic_vector(BA-1 downto 0);
	        WAVALID: out std_logic;
	        WRESP: in std_logic_vector(BE-1 downto 0);
	        WRESPV: in std_logic
	   );
	end component;

	constant PERIOD: time := 10 ps;

	constant BA: integer:= 32;
	constant BD: integer:= 32;
	constant BE: integer:= 2;
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
	constant FD: integer:= 32;
	constant FM: integer:= 23;
	constant FE: integer:= 8;
	constant CA: integer:= 0;
	constant CS: integer:= 1024;
	constant BC: integer:= 8;

	signal clk: std_logic := '0';
	signal reset: std_logic;
	signal RDATA: std_logic_vector(BD-1 downto 0);
	signal RDATAV: std_logic;
	signal RADDR: std_logic_vector(BA-1 downto 0);
	signal RAVALID: std_logic;
	signal RRESP: std_logic_vector(BE-1 downto 0);
	signal WDATA: std_logic_vector(BD-1 downto 0);
	signal WDATAV: std_logic;
	signal WADDR: std_logic_vector(BA-1 downto 0);
	signal WAVALID: std_logic;
	signal WRESP: std_logic_vector(BE-1 downto 0);
	signal WRESPV: std_logic;

	signal aux: integer;

begin

	clk <= not clk after PERIOD/2;

	CPUU: cpu
	generic map (
		BA => BA,
		BD => BD,
		BE => BE,
		SA => SA,
		SB => SB,
		SD => SD,
		SI => SI,
		SX => SX,
		IB => IB,
		IO => IO,
		IX => IX,
		IY => IY,
		IJ => IJ,
		FD => FD,
		FM => FM,
		FE => FE,
		CA => CA,
		CS => CS,
		BC => BC
	)
	port map (
		clk => clk,
		reset => reset,
		RDATA => RDATA,
		RDATAV => RDATAV,
		RADDR => RADDR,
		RAVALID => RAVALID,
		RRESP => RRESP,
		WDATA => WDATA,
		WDATAV => WDATAV,
		WADDR => WADDR,
		WAVALID => WAVALID,
		WRESP => WRESP,
		WRESPV => WRESPV
	);

	process
	begin

	reset <= '1';
	RADDR <= x"00000000";
	RAVALID <= '0';
	WDATA <= x"00000000";
	WDATAV <= '0';
	WADDR <= x"00000000";
	WAVALID <= '0';
	aux <= 0;

    wait for PERIOD/2;
    reset <= '1';
    wait for PERIOD/2;
    reset <= '0';
    wait for PERIOD/2;

	while true loop
		if (RAVALID = '1' or (WAVALID = '1' and WDATAV = '1')) then
			wait for PERIOD*3;
			RDATA <= std_logic_vector(to_unsigned(aux, SD));
			RDATAV <= '1';
			WRESPV <= '1';
			wait for PERIOD;
			RDATAV <= '0';
			WRESPV <= '0';
			aux <= aux+1;
		end if;
		wait for PERIOD;
	end loop;

    wait;
  end process;
end TB;

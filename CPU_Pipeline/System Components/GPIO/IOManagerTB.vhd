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

entity iom_tb is
end iom_tb;

architecture TB of iom_tb is

	component IOManager is
		generic (
	        size: integer := 8;

	        isOR: std_logic := '0';
	        isOW: std_logic := '0'
	    );
	    port (
	        pin: inout std_logic_vector(size-1 downto 0); -- Array de 8 pins de I/O
	        data: inout std_logic_vector(size-1 downto 0); -- Bus de dades de lectura o escriptura

	        WRLAT:  in std_logic; -- Pin per modificar el valor enregistrat
	        RDLAT:  in std_logic; -- Pin per llegir el valor enregistrat
	        WRTRIS: in std_logic; -- Pin per indicar la direcciÃ³ de cada pin
	        RDTRIS: in std_logic; -- Pin per llegir l'estat de la direcciÃ³ de cada pin
	        RDPORT: in std_logic; -- Pin per llegir l'estat directament del pin de sortida

	        reset: in std_logic
	    );
	end component IOManager;

constant PERIOD: time := 10 ps;
constant size: integer := 8;
signal reset: std_logic;

signal pin : std_logic_vector(size-1 downto 0);
signal data : std_logic_vector(size-1 downto 0);

signal WRLAT : std_logic;
signal RDLAT : std_logic;
signal WRTRIS : std_logic;
signal RDTRIS : std_logic;
signal RDPORT : std_logic;


begin
	IOM: IOManager
	generic map (
		size => 8,

		isOR => '0',
		isOW => '0'
	)
	port map (
		pin => pin,
		data => data,

		WRLAT => WRLAT,
		RDLAT => RDLAT,
		WRTRIS => WRTRIS,
		RDTRIS => RDTRIS,
		RDPORT => RDPORT,

		reset => reset
	);

	process
	begin

		data <= (others => 'Z');
		pin <= (others => 'Z');
		WRLAT <= '0';
		RDLAT <= '0';
		RDTRIS <= '0';
		WRTRIS <= '0';
		RDPORT <= '0';

		reset <= '0';
		wait for PERIOD;
		reset <= '1';
		wait for PERIOD;
		reset <= '0';
		wait for PERIOD;

		-- Read Test
		pin <= x"AB";
		data <= x"00";
		wait for PERIOD;

		WRTRIS <= '1';
		wait for PERIOD;

		WRTRIS <= '0';
		data <= (others => 'Z');
		wait for PERIOD;

		RDPORT <= '1';
		wait for PERIOD*2;
		RDPORT <= '0';
    RDLAT <= '1';
		wait for PERIOD*2;
		RDLAT <= '0';
		RDTRIS <= '1';
		wait for PERIOD*2;
		RDTRIS <= '0';

		-- Write Test
		pin <= (others => 'Z');
		data <= x"FF";
		wait for PERIOD;

		WRTRIS <= '1';
		wait for PERIOD;

		WRTRIS <= '0';
		data <= x"BA";
		wait for PERIOD;

		WRLAT <= '1';
		wait for PERIOD*2;

		wait;
  end process;
end TB;

configuration IOMConfig of iom_tb is
  for TB
    for IOM : IOManager
        use entity work.IOManager(a);
    end for;
  end for;
end IOMConfig;

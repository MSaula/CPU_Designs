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
            base_addr: integer := 0;
            lenght: integer := 1024;
            addr_size: integer := 32;
            data_size: integer := 32;
            size : integer := 8
        );
        port (
            reset: in std_logic;

            RADDR: in std_logic_vector(addr_size-1 downto 0);
            RAVALID: in std_logic;
            RDATA: out std_logic_vector(data_size-1 downto 0);
            RDATAV: out std_logic;
            RRESP: out std_logic_vector(1 downto 0);

            WADDR: in std_logic_vector(addr_size-1 downto 0);
            WAVALID: in std_logic;
            WDATA: in std_logic_vector(data_size-1 downto 0);
            WDATAV: in std_logic;
            WRESP: out std_logic_vector(1 downto 0);
            WRESPV: out std_logic
    	);
    end component;

    constant PERIOD: time := 10 ps;
    signal reset: std_logic;

    signal RADDR: std_logic_vector(31 downto 0);
    signal RAVALID: std_logic;
    signal RDATA: std_logic_vector(31 downto 0);
    signal RDATAV: std_logic;
    signal RRESP: std_logic_vector(1 downto 0);

    signal WADDR: std_logic_vector(31 downto 0);
    signal WAVALID: std_logic;
    signal WDATA: std_logic_vector(31 downto 0);
    signal WDATAV: std_logic;
    signal WRESP: std_logic_vector(1 downto 0);
    signal WRESPV: std_logic;

begin

	MEM: Memory
    generic map (
        base_addr => 0,
        lenght => 1024,
        addr_size => 32,
        data_size => 32,
        size => 8
    )
    port map (
        reset => reset,

        RADDR => RADDR,
        RAVALID => RAVALID,
        RDATA => RDATA,
        RDATAV => RDATAV,
        RRESP => RRESP,

        WADDR => WADDR,
        WAVALID => WAVALID,
        WDATA => WDATA,
        WDATAV => WDATAV,
        WRESP => WRESP,
        WRESPV => WRESPV
    );

	process
	begin

        WAVALID <= '0';
        RAVALID <= '0';
        WDATAV <= '0';

		reset <= '0';
		wait for PERIOD;
		reset <= '1';
		wait for PERIOD;
		reset <= '0';
		wait for PERIOD;

        -- Provant Escriptura multiple

        for i in 0 to 5 loop
            WADDR <= x"00000000" + i * 4;
            WDATA <= x"00000000" + i;
            wait for PERIOD;
            WDATAV <= '1';
            WAVALID <= '1';
            wait for PERIOD;
            WDATAV <= '0';
            WAVALID <= '0';
            wait for PERIOD;
        end loop;

        -- Provant Lectura multiple

        for i in 0 to 5 loop
            RADDR <= x"00000000" + i * 4;
            wait for PERIOD;
            RAVALID <= '1';
            wait for PERIOD;
            RAVALID <= '0';
            wait for PERIOD;
        end loop;

        -- Provant Escriptura i Lectura simultànies multiples

        for i in 20 to 30 loop
            WADDR <= x"00000000" + i * 4;
            WDATA <= x"00000000" + i;
            RADDR <= x"00000000" + i * 4;
            wait for PERIOD;
            WDATAV <= '1';
            WAVALID <= '1';
            RAVALID <= '1';
            wait for PERIOD;
            WDATAV <= '0';
            WAVALID <= '0';
            RAVALID <= '0';
            wait for PERIOD;
        end loop;

        -- Provant Escriptura i Lectura simultànies multiples en adreces inexistents

        for i in 2000 to 2010 loop
            WADDR <= x"00000000" + i * 4;
            WDATA <= x"00000000" + i;
            RADDR <= x"00000000" + i * 4;
            wait for PERIOD;
            WDATAV <= '1';
            WAVALID <= '1';
            RAVALID <= '1';
            wait for PERIOD;
            WDATAV <= '0';
            WAVALID <= '0';
            RAVALID <= '0';
            wait for PERIOD;
        end loop;

		wait;
  end process;
end TB;

configuration MEMConfig of memory_tb is
  for TB
    for MEM : Memory
        use entity work.memory(a);
    end for;
  end for;
end MEMConfig;

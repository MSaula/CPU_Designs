-- Last version 24/07/2020 (12:39)

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity lifo_tb is
end lifo_tb;

architecture TB of lifo_tb is

    component lifo is
        generic (
            SA: integer:= 32;
            LS: integer := 32
        );
        port (
            clk: in std_logic;
            reset: in std_logic;

            input: in std_logic_vector(SA-1 downto 0);
            output: out std_logic_vector(SA-1 downto 0);

            add: in std_logic;
            pop: in std_logic;
            error: out std_logic
    	);
    end component;

    constant SA: integer:= 32;
    constant LS: integer := 32;

    constant PERIOD: time := 10 ps;
    signal clk: std_logic := '0';
    signal reset: std_logic;

    signal input: std_logic_vector(SA-1 downto 0);
    signal output: std_logic_vector(SA-1 downto 0);
    signal add: std_logic;
    signal pop: std_logic;
    signal error: std_logic;

begin

    clk <= not clk after PERIOD/2;

    LIFOO: lifo
    generic map (
        SA => SA,
        LS => LS
    ) port map (
        clk => clk,
        reset => reset,
        input => input,
        output => output,
        add => add,
        pop => pop,
        error => error
    );

	process
	begin

        reset <= '0';
        input <= x"00000000";
        add <= '0';
        pop <= '0';

        wait for PERIOD/2;
        reset <= '1';
        wait for PERIOD/2;
        reset <= '0';
        wait for PERIOD/2;

        add <= '1';
        input <= x"12121212";
        wait for PERIOD;

        add <= '0';
        wait for PERIOD;

        pop <= '1';
        wait for PERIOD;

        pop <= '0';
        wait for PERIOD;

        add <= '1';
        for i in 3 to 13 loop
            input <= std_logic_vector(to_unsigned((i + 2048), 32));
            wait for PERIOD;
        end loop;

        add <= '0';
        wait for PERIOD;

        pop <= '1';
        for i in 0 to 10 loop
            wait for PERIOD;
        end loop;

        wait;
    end process;
end TB;

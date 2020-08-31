-- Last version 28/07/2020 (17:41)

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity fp2int_tb is
end fp2int_tb;

architecture TB of fp2int_tb is

    component fp2int is
        generic (
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8
        );
        port (
            input: in std_logic_vector(FD-1 downto 0);
            output: out std_logic_vector(FD-1 downto 0)
    	);
    end component;

    constant FD: integer:= 32;
    constant FM: integer:= 23;
    constant FE: integer:= 8;

    constant PERIOD: time := 10 ps;
    signal clk: std_logic := '0';

    signal input: std_logic_vector(FD-1 downto 0);
    signal output: std_logic_vector(FD-1 downto 0);

begin

    clk <= not clk after PERIOD/2;

    CONVERTER: fp2int
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    ) port map (
        input => input,
        output => output
    );

	process
	begin

        input <= "01000010110010000000000000000000"; -- +100
        wait for PERIOD;

        input <= "11000010110010000000000000000000"; -- -100
        wait for PERIOD;

        input <= "01111111100000000000000000000000"; -- inf
        wait for PERIOD;

        input <= "11111111100000000000000000000000"; -- -inf
        wait for PERIOD;

        input <= "01111111110000000000000000000000"; -- nan
        wait for PERIOD;

        input <= "01001111000000000000000000000001"; -- overflow
        wait for PERIOD;

        input <= "00111011000000110001001001101111"; -- underflow
        wait for PERIOD;

        input <= "01000010010010000000000000000000"; -- 50
        wait for PERIOD;

        input <= "00111110100110011001100110011010"; -- 0.3
        wait for PERIOD;

        input <= "01000000101100000000000000000000"; -- 5.5
        wait for PERIOD;

        input <= "01000000101100110011001100110011"; -- 5.6
        wait for PERIOD;

        input <= "11001001011101000010010000000000"; -- -1000000
        wait for PERIOD;

        wait;
    end process;
end TB;

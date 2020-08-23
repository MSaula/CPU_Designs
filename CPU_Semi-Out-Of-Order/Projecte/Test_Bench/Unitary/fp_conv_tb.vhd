-- Last version 24/07/2020 (12:42)

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity fp_conv_tb is
end fp_conv_tb;

architecture TB of fp_conv_tb is

    component int2fp is
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

    constant PERIOD: time := 10 ps;
    signal reset: std_logic;
    signal clk: std_logic := '0';

    signal input: std_logic_vector(31 downto 0);
    signal output: std_logic_vector(31 downto 0);

begin

    clk <= not clk after PERIOD/2;

    I2FP: int2fp
    generic map (
        FD => 32,
        FM => 23,
        FE => 8
    ) port map (
        input => input,
        output => output
    );

	process
	begin
        input <= x"00000000";

        wait for PERIOD;
        input <= x"FFFFFFFF";

        wait for PERIOD;
        input <= x"0000000A";

        wait for PERIOD;
        input <= x"7FFFFFFF";

        wait for PERIOD;
        input <= x"000F4240";

        wait for PERIOD;
        input <= x"00800000";

        wait for PERIOD;
        input <= x"00800C30";

        wait for PERIOD;
        input <= x"00FFFFFF";

        wait for PERIOD;
        input <= x"007FFFFF";

        wait for PERIOD;
        input <= x"80A00000";

        wait;
    end process;
end TB;

configuration I2FPConfig of fp_conv_tb is
  for TB
    for I2FP : int2fp
        use entity work.int2fp(a);
    end for;
  end for;
end I2FPConfig;

-- Last version 24/07/2020 (12:45)

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity fp_multiplier_tb is
end fp_multiplier_tb;

architecture TB of fp_multiplier_tb is

    component fp_multiplier is
        generic (
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8
        );
        port (
            A: in std_logic_vector(31 downto 0);
            B: in std_logic_vector(31 downto 0);

            C: out std_logic_vector(31 downto 0)
    	);
    end component;

    constant PERIOD: time := 10 ps;
    signal reset: std_logic;
    signal clk: std_logic := '0';

    signal A: std_logic_vector(31 downto 0);
    signal B: std_logic_vector(31 downto 0);
    signal C: std_logic_vector(31 downto 0);

begin

    clk <= not clk after PERIOD/2;

    FPM: fp_multiplier
    generic map (
        FD => 32,
        FM => 23,
        FE => 8
    ) port map (
        A => A,
        B => B,
        C => C
    );

	process
	begin
	      -- Integer sum (expected 0x41300000)
        A <= x"40A00000"; -- 5
        B <= x"40C00000"; -- 6
        wait for PERIOD;

        -- Decimal sum (expected 0x4236A8F6)
        A <= x"4126B852"; -- 10,42
        B <= x"4200FAE1"; -- 30,245
        wait for PERIOD;

        -- Normal decimal sub negative (expected 0xC2C80000)
        A <= x"420A0000"; -- 34,5
        B <= x"C2C80000"; -- -100
        wait for PERIOD;

        -- Decimal sub negative (A and B swapped)
        A <= x"C2C80000"; -- -100
        B <= x"420A0000"; -- 34,5
        wait for PERIOD;

        -- Decimal sub positive (expected 0x41C40000)
        A <= x"420A0000"; -- 34,5
        B <= x"C1200000"; -- -10
        wait for PERIOD;

        -- Decimal sub positive (A and B swapped)
        A <= x"C1200000"; -- -10
        B <= x"420A0000"; -- 34,5
        wait for PERIOD;

        -- Error -> NaN + NaN (expected NaN)
        A <= x"7FFFFFFF"; -- NaN
        B <= x"7FFFFFFF"; -- NaN
        wait for PERIOD;

        -- Sum with A >> B (expected C = A)
        A <= x"86D54000"; -- N << -1
        B <= x"42C10000"; -- 96,5
        wait for PERIOD;

        -- Sub with A similar to B (expected C << A)
        A <= x"40FFFFFF"; -- +7.99999952316
        B <= x"C0FFFFFE"; -- -7.99999904633
        wait for PERIOD;

        -- Error -> A anb B near limit (expected +inf.)
        A <= x"7F7FFFFF"; -- 3.40282346639e+38
        B <= x"7F7FFFFF"; -- 3.40282346639e+38
        wait for PERIOD;

        -- Error -> A and B near limit but negative (expected -inf.)
        A <= x"FF7FFFFF"; -- -3.40282346639e+38
        B <= x"FF7FFFFF"; -- -3.40282346639e+38
        wait for PERIOD;

        -- 0 + 0 (expected 0)
        A <= x"00000000"; -- 0
        B <= x"00000000"; -- 0
        wait for PERIOD;

        -- 0 + N (expected N)
        A <= x"00000000"; -- 0
        B <= x"40A00000"; -- 5
        wait for PERIOD;

        -- N + 0 (expected N)
        A <= x"40A00000"; -- 5
        B <= x"00000000"; -- 0
        wait for PERIOD;

        -- N - N (expected N)
        A <= x"40A00000"; -- 5
        B <= x"C0A00000"; -- -5
        wait for PERIOD;

        -- Error -> inf + inf (expected +inf.)
        A <= x"7F800000"; -- +inf
        B <= x"7F800000"; -- +inf
        wait for PERIOD;

        -- Error -> inf - inf (expected NaN)
        A <= x"7F800000"; -- +inf
        B <= x"FF800000"; -- -inf
        wait for PERIOD;

        -- Error -> -inf - inf (expected -inf.)
        A <= x"FF800000"; -- -inf
        B <= x"FF800000"; -- -inf
        wait for PERIOD;

        A <= x"1A3C97A9";
        B <= x"1A3C97A9";
        wait for PERIOD;

        A <= x"1A000000";
        B <= x"1A000000";
        wait;
    end process;
end TB;

configuration FPMConfig of fp_multiplier_tb is
  for TB
    for FPM : fp_multiplier
        use entity work.fp_multiplier(a);
    end for;
  end for;
end FPMConfig;

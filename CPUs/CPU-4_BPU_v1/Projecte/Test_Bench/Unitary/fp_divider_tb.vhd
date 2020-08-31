-- Last Version 24/07/2020 (12:47)

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity fp_divider_tb is
end fp_divider_tb;

architecture TB of fp_divider_tb is

    component fp_divider is
        generic (
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8
        );
        port (
            Nin: in std_logic_vector(31 downto 0);
            Din: in std_logic_vector(31 downto 0);

            start: in std_logic;
            clk: in std_logic;


            Q: out std_logic_vector(31 downto 0);

            ended: out std_logic
    	);
    end component;

    constant PERIOD: time := 10 ps;
    signal reset: std_logic;
    signal clk: std_logic := '0';

    signal N: std_logic_vector(31 downto 0);
    signal D: std_logic_vector(31 downto 0);
    signal Q: std_logic_vector(31 downto 0);

    signal start: std_logic;
    signal ended: std_logic;

    signal test_id: integer;

begin

    clk <= not clk after PERIOD/2;

    FPD: fp_divider
    generic map (
        FD => 32,
        FM => 23,
        FE => 8
    ) port map (
        Nin => N,
        Din => D,
        start => start,
        clk => clk,
        Q => Q,
        ended => ended
    );

	process
	begin
	      wait for PERIOD/2;
        -------------------------------------------------
        test_id <= 1;

        start <= '0';
        wait for PERIOD;

        N <= x"42800000";
        D <= x"40800000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 2;

        N <= x"40800000";
        D <= x"42800000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 3;

        N <= x"41B80000";
        D <= x"40A00000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 4;

        N <= x"40A00000";
        D <= x"41B80000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 5;

        N <= x"4E6E6B28";
        D <= x"40E00000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 6;

        N <= x"40E00000";
        D <= x"4E6E6B28";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 7;

        N <= x"3089705F";
        D <= x"40E00000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 8;

        N <= x"40E00000";
        D <= x"3089705F";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 9;

        N <= x"C0000000";
        D <= x"40A00000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 10;

        N <= x"40A00000";
        D <= x"C0000000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 11;

        N <= x"40400000";
        D <= x"C0000000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 12;

        N <= x"C0000000";
        D <= x"40400000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 13;

        N <= x"7FFFFFFF";
        D <= x"40A00000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 14;

        N <= x"40A00000";
        D <= x"7FFFFFFF";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 15;

        N <= x"40A00000";
        D <= x"7F800000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 16;

        N <= x"7F800000";
        D <= x"40A00000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 17;

        N <= x"00000000";
        D <= x"00000000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 18;

        N <= x"00000000";
        D <= x"7F800000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 19;

        N <= x"00000000";
        D <= x"40A00000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 20;

        N <= x"7F800000";
        D <= x"00000000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 21;

        N <= x"40A00000";
        D <= x"00000000";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 22;

        N <= x"7149F2CA";
        D <= x"0DA24260";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------
        -------------------------------------------------
        test_id <= 23;

        N <= x"0DA24260";
        D <= x"7149F2CA";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        wait for PERIOD;
        while ended = '0' loop wait for PERIOD; end loop;

        -------------------------------------------------

        wait;
    end process;
end TB;

configuration FPDConfig of fp_divider_tb is
  for TB
    for FPD : fp_divider
        use entity work.fp_divider(a);
    end for;
  end for;
end FPDConfig;

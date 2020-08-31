--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity int2sevseg is
    port (
        input: in std_logic_vector(31 downto 0);
        output: out std_logic_vector(31 downto 0)
	);
end int2sevseg;

architecture a of int2sevseg is

    constant bcd: integer := 4;
    constant seg: integer := 8;
    constant int: integer := 32;

    signal digit_0: std_logic_vector(bcd-1 downto 0) := (others => '0');
    signal digit_1: std_logic_vector(bcd-1 downto 0) := (others => '0');
    signal digit_2: std_logic_vector(bcd-1 downto 0) := (others => '0');
    signal digit_3: std_logic_vector(bcd-1 downto 0) := (others => '0');

begin

    performIntTo7seg: process(input)
      variable s_digit_0 : unsigned(bcd-1 downto 0);
      variable s_digit_1 : unsigned(bcd-1 downto 0);
      variable s_digit_2 : unsigned(bcd-1 downto 0);
      variable s_digit_3 : unsigned(bcd-1 downto 0);
    begin
      s_digit_3 := "0000";
      s_digit_2 := "0000";
      s_digit_1 := "0000";
      s_digit_0 := "0000";

      for i in 9 downto 0 loop
        if (s_digit_3 >= 5) then s_digit_3 := s_digit_3 + 3; end if;
        if (s_digit_2 >= 5) then s_digit_2 := s_digit_2 + 3; end if;
        if (s_digit_1 >= 5) then s_digit_1 := s_digit_1 + 3; end if;
        if (s_digit_0 >= 5) then s_digit_0 := s_digit_0 + 3; end if;
        s_digit_3 := s_digit_3 sll 1; s_digit_3(0) := s_digit_2(3);
        s_digit_2 := s_digit_2 sll 1; s_digit_2(0) := s_digit_1(3);
        s_digit_1 := s_digit_1 sll 1; s_digit_1(0) := s_digit_0(3);
        s_digit_0 := s_digit_0 sll 1; s_digit_0(0) := input(i);
      end loop;

      digit_0 <=  std_logic_vector(s_digit_0);
      digit_1 <=  std_logic_vector(s_digit_1);
      digit_2 <=  std_logic_vector(s_digit_2);
      digit_3 <=  std_logic_vector(s_digit_3);
    end process;

    output((seg*1)-1 downto (seg*0)) <=
        "00000010" when digit_0 = "0000" else
        "10011110" when digit_0 = "0001" else
        "00100100" when digit_0 = "0010" else
        "00001100" when digit_0 = "0011" else
        "10011000" when digit_0 = "0100" else
        "01001000" when digit_0 = "0101" else
        "01000000" when digit_0 = "0110" else
        "00011110" when digit_0 = "0111" else
        "00000000" when digit_0 = "1000" else
        "00001000" when digit_0 = "1001";

    output((seg*2)-1 downto (seg*1)) <=
        "00000010" when digit_1 = "0000" else
        "10011110" when digit_1 = "0001" else
        "00100100" when digit_1 = "0010" else
        "00001100" when digit_1 = "0011" else
        "10011000" when digit_1 = "0100" else
        "01001000" when digit_1 = "0101" else
        "01000000" when digit_1 = "0110" else
        "00011110" when digit_1 = "0111" else
        "00000000" when digit_1 = "1000" else
        "00001000" when digit_1 = "1001";

    output((seg*3)-1 downto (seg*2)) <=
        "00000010" when digit_2 = "0000" else
        "10011110" when digit_2 = "0001" else
        "00100100" when digit_2 = "0010" else
        "00001100" when digit_2 = "0011" else
        "10011000" when digit_2 = "0100" else
        "01001000" when digit_2 = "0101" else
        "01000000" when digit_2 = "0110" else
        "00011110" when digit_2 = "0111" else
        "00000000" when digit_2 = "1000" else
        "00001000" when digit_2 = "1001";

    output((seg*4)-1 downto (seg*3)) <=
        "00000010" when digit_3 = "0000" else
        "10011110" when digit_3 = "0001" else
        "00100100" when digit_3 = "0010" else
        "00001100" when digit_3 = "0011" else
        "10011000" when digit_3 = "0100" else
        "01001000" when digit_3 = "0101" else
        "01000000" when digit_3 = "0110" else
        "00011110" when digit_3 = "0111" else
        "00000000" when digit_3 = "1000" else
        "00001000" when digit_3 = "1001";
end a;

--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity int2fp is
    generic (
        FD: integer:= 32;
        FM: integer:= 23;
        FE: integer:= 8
    );
    port (
        input: in std_logic_vector(FD-1 downto 0);
        output: out std_logic_vector(FD-1 downto 0)
	);
end int2fp;

architecture a of int2fp is

    signal sgn: std_logic;
    signal expn: std_logic_vector(FE-1 downto 0);
    signal man: std_logic_vector(FM-1 downto 0);

    signal first_one: integer;
    signal in_abs: std_logic_vector(FD-1 downto 0);

    signal iszero: boolean;

begin

    sgn <= input(FD-1);
    in_abs <= NOT input + 1 when sgn = '1' else input;

    iszero <= input = "00000000000000000000000000000000" or
              input = "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" or
              input = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";

    calculateFirstOne: process(in_abs)
        variable aux: integer := FD;
    begin
        if iszero then
            first_one <= FD;
        else
            for i in 0 to FD-1 loop
                if in_abs(i) = '1' then aux := i; end if;
            end loop;
            first_one <= aux;
        end if;
    end process;

    expn <= std_logic_vector(to_unsigned(first_one + 127, FE)) when not iszero else (others => '0');

    updateFraction: process(first_one, in_abs)
    begin
        if (first_one >= FD or first_one < 0) then
            man <= (others => '0');
        else
            if (first_one > FM-1) then
                man <= in_abs(first_one-1 downto first_one - FM);
            else
                man(FM-1 downto FM - first_one) <= in_abs(first_one - 1 downto 0);
                man(FM - first_one -1 downto 0) <= (others => '0');
            end if;
        end if;
    end process;

    output(FE+FM) <= sgn;
    output(FE+FM-1 downto FM) <= expn;
    output(FM-1 downto 0) <= man;

end a;

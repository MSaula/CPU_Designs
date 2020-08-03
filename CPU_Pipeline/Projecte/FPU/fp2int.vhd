--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity fp2int is
    generic (
        FD: integer:= 32;
        FM: integer:= 23;
        FE: integer:= 8
    );
    port (
        input: in std_logic_vector(FD-1 downto 0);
        output: out std_logic_vector(FD-1 downto 0)
	);
end fp2int;

architecture a of fp2int is

    signal sgn: std_logic := '0';
    signal expn: std_logic_vector(FE-1 downto 0) := (others => '0');
    signal man: std_logic_vector(FM-1 downto 0) := (others => '0');

    signal iszero: boolean;
    signal isnan: boolean;
    signal isinf: boolean;

begin

    sgn <= input(FD-1);
    expn <= input(FD-2 downto FM);
    man <= input(FM-1 downto 0);

    iszero <= input = "00000000000000000000000000000000" or
              input = "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" or
              input = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";

    isnan <= (expn = x"FF") and not (man = x"000000");
    isinf <= (expn = x"FF") and (man = x"000000");

    CALCULATE_OUT: process (sgn, expn, man, iszero, isnan, isinf)
        variable oabs: std_logic_vector(FD-1 downto 0);
        variable e: integer;
        variable aux1: integer;
        variable aux2: integer;
    begin
        -- TODO: revisar que el resultat sigui absolut
        e := to_integer(unsigned(expn)) - 127;

        if ((iszero or isnan) or (e < 0)) then
            output <= (others => '0');
        elsif (isinf or (e > 30)) then
            output(FD-1) <= sgn;
            output(FD-2 downto 0) <= (others => (NOT sgn));
        else

            if ((e - 23) < 0) then aux1 := 0;
            else aux1 := e-23; end if;

            if ((23 - e) < 0) then aux2 := 0;
            else aux2 := 23-e; end if;

            oabs(FD-1 downto 0) := (others => '0');
            oabs(e downto aux1) := "1" & man(22 downto aux2);

            if (sgn = '0') then output <= oabs;
            else output <= (NOT oabs) +1; end if;

        end if;
    end process;

end a;

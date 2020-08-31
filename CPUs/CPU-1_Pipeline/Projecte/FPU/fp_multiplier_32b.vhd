--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

-- For this version of the multiplier, if the result is lower than 1.1755E-38
-- then it is rounded to 0 because of underflow
-- An upgrade should be to let the multiplier work with the Cexp = 0 and no "hidden" '1'
-- for lower values than the mentioned.

entity fp_multiplier is
    generic (
        FD: integer:= 32;
        FM: integer:= 23;
        FE: integer:= 8
    );
    port (
        A: in std_logic_vector(FD-1 downto 0);
        B: in std_logic_vector(FD-1 downto 0);

        C: out std_logic_vector(FD-1 downto 0)
	);
end fp_multiplier;

architecture a of fp_multiplier is

    signal Asgn: std_logic := '0';
    signal Aexp: std_logic_vector(FE-1 downto 0) := (others => '0');
    signal Aman: std_logic_vector(FM-1 downto 0) := (others => '0');

    signal Bsgn: std_logic := '0';
    signal Bexp: std_logic_vector(FE-1 downto 0) := (others => '0');
    signal Bman: std_logic_vector(FM-1 downto 0) := (others => '0');

    signal Csgn: std_logic := '0';
    signal Cexp: std_logic_vector(FE-1 downto 0) := (others => '0');
    signal Cman: std_logic_vector(FM-1 downto 0) := (others => '0');

    signal Cmanaux: std_logic_vector(((FM+1)*2)-1 downto 0) := (others => '0');

    signal infinite: boolean;
    signal zero: boolean;
    signal nan: boolean;

begin

    Asgn <= A(FD-1);
    Bsgn <= B(FD-1);

    Aexp <= A((FM+FE-1) downto FM);
    Bexp <= B((FM+FE-1) downto FM);

    Aman <= A(FM-1 downto 0);
    Bman <= B(FM-1 downto 0);

    Cmanaux <= ("1" & Aman) * ("1" & Bman);

    zero <= ((Aexp = x"00") and (Aman = x"000000")) or
            ((Bexp = x"00") and (Bman = x"000000")) or
            ((to_integer(unsigned(Aexp)) + to_integer(unsigned(Bexp))) < 127);

    infinite <= (to_integer(unsigned(Aexp)) + to_integer(unsigned(Bexp)) - 127 + to_integer(unsigned'('0' & Cmanaux(((FM+1)*2)-1)))) >= 255;
    nan <= ((Aexp = x"FF") and (Aman /= x"000000")) or ((Bexp = x"FF") and (Bman /= x"000000"));

    Cexp <= (others => '0') when zero
        else std_logic_vector(to_unsigned(to_integer(unsigned(Aexp)) + to_integer(unsigned(Bexp)) -127 +1, FE)) when Cmanaux(((FM+1)*2)-1) = '1' and not infinite and not nan
        else std_logic_vector(to_unsigned(to_integer(unsigned(Aexp)) + to_integer(unsigned(Bexp)) -127, FE)) when not infinite and not nan
        else (others => '1');

    Cman <= (others => '0') when zero
        else Cmanaux(((FM+1)*2)-2 downto (FM+1)) when Cmanaux(((FM+1)*2)-1) = '1' and not infinite and not nan
        else Cmanaux(((FM+1)*2)-3 downto FM) when not infinite and not nan
        else (others => '0') when infinite
        else (others => '1') when nan
        else (others => '1');

    Csgn <= Asgn xor Bsgn;

    C(FM+FE) <= Csgn;
    C(FM+FE-1 downto FM) <= Cexp;
    C(FM-1 downto 0) <= Cman;

end a;

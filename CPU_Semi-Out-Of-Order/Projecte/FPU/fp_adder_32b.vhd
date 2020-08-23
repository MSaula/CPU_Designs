--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity fp_adder is
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
end fp_adder;

architecture a of fp_adder is

    signal order: std_logic; -- Indicates if B > A to switch the order of the operands

    signal Asgn: std_logic := '0';
    signal Aexp: std_logic_vector(FE-1 downto 0) := (others => '0');
    signal Aman: std_logic_vector(FM-1 downto 0) := (others => '0');

    signal Bsgn: std_logic := '0';
    signal Bexp: std_logic_vector(FE-1 downto 0) := (others => '0');
    signal Bman: std_logic_vector(FM-1 downto 0) := (others => '0');

    signal Csgn: std_logic := '0';
    signal Cexp: std_logic_vector(FE-1 downto 0) := (others => '0');
    signal Cman: std_logic_vector(FM-1 downto 0) := (others => '0');

    signal Aop: std_logic_vector((FM+3)-1 downto 0) := (others => '0'); --Added 3 bits corresponding to: CA2 sign - Overflow margin - Hidden '1' from IEEE-754
    signal Bop: std_logic_vector((FM+3)-1 downto 0) := (others => '0');
    signal Cop: std_logic_vector((FM+3)-1 downto 0) := (others => '0');
    signal Cop_abs: std_logic_vector((FM+3)-1 downto 0) := (others => '0');

    signal Bmanaux: std_logic_vector((FM+1)-1 downto 0) := (others => '0');
    signal first_one: integer := 0;

    signal nan: boolean;
    signal Ainf: boolean;
    signal Binf: boolean;
    signal infinite: boolean;

    signal Azero: boolean;
    signal Bzero: boolean;

begin

    order <= '1' when B((FM+FE-1) downto FM) > A((FM+FE-1) downto FM) else
        '1' when B((FM+FE-1) downto FM) = A((FM+FE-1) downto FM) and B(FM-1 downto 0) > A(FM-1 downto 0)
        else '0';

    Asgn <= A(FD-1) when order = '0' else B(FD-1);
    Bsgn <= B(FD-1) when order = '0' else A(FD-1);

    Aexp <= A((FM+FE-1) downto FM) when order = '0' else B((FM+FE-1) downto FM);
    Bexp <= B((FM+FE-1) downto FM) when order = '0' else A((FM+FE-1) downto FM);

    Aman <= A(FM-1 downto 0) when order = '0' else B(FM-1 downto 0);
    Bman <= B(FM-1 downto 0) when order = '0' else A(FM-1 downto 0);

    Azero <= (Aexp = x"00" and Aman = x"000000");
    Bzero <= (Bexp = x"00" and Bman = x"000000");

    Aop <= (others => '0') when Azero else ("001" & Aman) when Asgn = '0' else (("11" & (NOT ("1" & Aman))) +1);

    Ainf <= ((Aexp = x"FF") and (Aman = "0000000000000000000000"));
    Binf <= ((Bexp = x"FF") and (Bman = "0000000000000000000000"));

    nan <= ((Aexp = x"FF") and (not (Aman = "0000000000000000000000"))) or ((Bexp = x"FF") and (not (Bman = "0000000000000000000000")))
            or ((Ainf and Binf) and (Asgn /= Bsgn)) ;

    noizeB: process(Aexp, Bexp, Bman)
        variable aexpi: integer;
        variable bexpi: integer;
    begin
        aexpi := to_integer(unsigned(Aexp));
        bexpi := to_integer(unsigned(Bexp));

        if ((aexpi - bexpi) >= FM or (bexpi > aexpi)) then
            Bmanaux <= (others => '0');
        elsif (aexpi = bexpi) then
            Bmanaux(FM) <= '1';
            Bmanaux((FM-1) downto 0) <= Bman(FM-1 downto 0);
        else
            Bmanaux(FM downto FM - (aexpi - bexpi) + 1) <= (others => '0');
            Bmanaux(FM - (aexpi - bexpi)) <= '1';
            Bmanaux((FM-1) - (aexpi - bexpi) downto 0) <= Bman(FM-1 downto (aexpi - bexpi));
        end if;
    end process;

    Bop <= (others => '0') when Azero else ("00" & Bmanaux) when Bsgn = '0' else ("11" & (NOT Bmanaux))+1;

    Cop <= std_logic_vector(unsigned(Aop) + unsigned(Bop));

    Csgn <= Cop((FM+3)-1);

    Cop_abs <= Cop when Cop((FM+3)-1) = '0' else ((NOT Cop) +1);

    calculateFirstOne: process(Cop_abs)
        variable aux: integer;
    begin
        aux := FD;
        for i in 0 to (FM+3)-1 loop
            if Cop_abs(i) = '1' then aux := i; end if;
        end loop;
        first_one <= aux;
    end process;

    Cexp <= std_logic_vector(unsigned(Aexp) + first_one - FM) when (not (first_one = FD)) else (others => '0');

    updateFraction: process(Cexp, Cop_abs)
    begin
        if (first_one = FD or first_one < 0) then
            Cman <= (others => '0');
        else
            if (first_one > FM-1) then
                Cman <= Cop_abs(first_one-1 downto first_one - FM);
            else
                Cman(FM-1 downto FM - first_one) <= Cop_abs(first_one - 1 downto 0);
                Cman(FM - first_one -1 downto 0) <= (others => '0');
            end if;
        end if;
    end process;

    infinite <= (((to_integer(unsigned(Aexp)) + to_integer(unsigned'('0' & Cop_abs((FM+3)-2)))) >= 255) or
                  (Ainf xor Binf) or ((Ainf and Binf) and (Asgn = Bsgn))) and not nan;

    C(FM+FE) <= Asgn when Ainf and not Binf else
                Bsgn when Binf and not Ainf else
                Asgn when Ainf and Binf and Ainf = Binf else
                Csgn;
    C(FM+FE-1 downto FM) <= Cexp when not infinite and not nan else (others => '1');
    C(FM-1 downto 0) <= (others => '0') when infinite else (others => '1') when nan else Cman;

end a;

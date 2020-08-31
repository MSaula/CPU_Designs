--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;
--
entity fp_divider is
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
end fp_divider;

architecture a of fp_divider is

    component fp_multiplier is
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
    end component;

    component fp_adder is
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
    end component;

    constant fp_one: std_logic_vector(FD-1 downto 0) := "00111111100000000000000000000000";
    constant fp_two: std_logic_vector(FD-1 downto 0) := "01000000000000000000000000000000";

    signal Fin: std_logic_vector(FD-1 downto 0);

    signal N: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal D: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal F: std_logic_vector(FD-1 downto 0) := (others => '0');

    signal Na: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal Da: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal Fa: std_logic_vector(FD-1 downto 0) := (others => '0');

    signal Da_neg: std_logic_vector(FD-1 downto 0) := (others => '0');

    signal ended_aux: std_logic := '0';

    signal nan: boolean := false;
    signal inf: boolean := false;
    signal zero: boolean := false;
    signal ninf: boolean := false;
    signal dinf: boolean := false;
    signal nzero: boolean := false;
    signal dzero: boolean := false;

begin

    nzero <= ((Nin(FD-2 downto FM) = x"00") and (Nin(FM-1 downto 0) = x"000000"));
    dzero <= ((Din(FD-2 downto FM) = x"00") and (Din(FM-1 downto 0) = x"000000"));

    nan <= ((Nin(FD-2 downto FM) = x"FF") and (Nin(FM-1 downto 0) /= x"000000")) or
           ((Din(FD-2 downto FM) = x"FF") and (Din(FM-1 downto 0) /= x"000000")) or
           dzero or (ninf and dinf);

    ninf <= Nin(FD-2 downto 0) = x"7F800000";
    dinf <= Din(FD-2 downto 0) = x"7F800000";

    zero <= (nzero and not dzero) or (dinf and not ninf);

    Da_neg(FD-1) <= not Da(FD-1);
    Da_neg(FD-2 downto 0) <= Da(FD-2 downto 0);

    ended_aux <= '1' when Fa = fp_one else '0';
    ended <= '1' when ended_aux = '1' or nan or inf or zero else '0';

    Fin(FD-1) <= Din(FD-1);
    Fin(FD-2 downto FM) <= std_logic_vector(to_unsigned(252 - to_integer(unsigned(Din(FD-2 downto FM))), FE)) when Din(FM-1 downto 0) /= x"000000"
                          else std_logic_vector(to_unsigned(254 - to_integer(unsigned(Din(FD-2 downto FM))), FE));
    Fin(FM-1 downto 0) <= Din(FM-1 downto 0);

    Q <= Na when not nan and not inf and not zero
         else x"7FFFFFFF" when nan -- not inf and not zero
         else x"00000000" when zero -- not inf
         else x"7F800000" when Nin(FD-1) = Din(FD-1)
         else x"FF800000";

    inf <= ((Na(FD-2 downto FM) = x"FF") and (Na(FM-1 downto 0) = x"000000")) or
            (ninf and not dinf);

    updateRegisters: process(clk)
    begin
        if (clk = '1') then
            if (start = '1') then
                N <= Nin;
                D <= Din;
                F <= Fin;
            elsif (ended_aux = '0') then
                N <= Na;
                D <= Da;
                F <= Fa;
            end if;
        end if;
    end process;

    newNcalculator: fp_multiplier
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        A => N,
        B => F,

        C => Na
    );

    newDcalculator: fp_multiplier
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        A => D,
        B => F,

        C => Da
    );

    newFcalculator: fp_adder
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        A => fp_two,
        B => Da_neg,

        C => Fa
    );
end a;

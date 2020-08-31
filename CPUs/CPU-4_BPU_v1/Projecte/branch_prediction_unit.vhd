--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

-- UNFINISHED

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;
--
entity branch_prediction_unit is
    generic (
        SA: integer:= 32;
        SD: integer:= 32;
        SI: integer:= 32
    );
    port (
        clk: in std_logic;
        reset: in std_logic;

        taken: in std_logic;
        not_taken: in std_logic;

        PC: in std_logic_vector(SA-1 downto 0);
        Ins: in std_logic_vector(SI-1 downto 0);

        newPC: out std_logic_vector(SA-1 downto 0);
        newI: out std_logic_vector(SI-1 downto 0);
        BPUJump: out std_logic
	);
end branch_prediction_unit;

architecture a of branch_prediction_unit is

    constant saturation_bits: integer := 2;
    constant max_value: integer := 2**saturation_bits-1;
    constant threshold: integer := 2**(saturation_bits-1);

    signal state: integer := 1;

    signal insaux: std_logic_vector(SI-1 downto 0);

    signal isJump: boolean;
    signal isBranch: boolean;

begin

    isJump <= Ins(SI-1 downto SI-4) = "1100" and Ins(SI-5 downto SI-6) = "00";
    isBranch <= Ins(SI-1 downto SI-4) = "1101";

    insaux(SI-1 downto SI-4)  <= Ins(SI-1 downto SI-4);
    insaux(SI-5 downto SI-6)  <= (Ins(SI-5) & '0') when state < threshold else (Ins(SI-5) & '1');
    insaux(SI-7 downto SI-16) <= Ins(SI-7 downto SI-16);
    insaux(SI-17 downto 0) <= Ins(SI-17 downto 0) when state < threshold else (others => '0');--Ins(SI-17 downto 0) when state < threshold else PC(15 downto 0) +4;

    newI <= (others => '0') when isJump else
            insaux when isBranch else
            Ins;

    newPC <= std_logic_vector(to_unsigned(to_integer(unsigned(PC)) + 4*to_integer(signed(Ins(SI-17 downto 0))), SI)) when isJump or (state >= threshold) else
                PC + x"00000004";

    BPUJump <= '1' when isJump or (isBranch and state >= threshold) else '0';

    saturation_counter_update: process(clk, reset)
    begin
        if (reset = '1') then
            state <= threshold;
        elsif (clk'event and clk = '1') then
            if (taken = '1' and state < max_value) then
                state <= state +1;
            elsif (not_taken = '1' and state > 0) then
                state <= state -1;
            end if;
        end if;
    end process;

end a;

--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity lifo is
    generic (
        -- System
        SA: integer:= 32;

        -- LIFO
        LS: integer := 32
    );
    port (
        clk: in std_logic;
        reset: in std_logic;

        input: in std_logic_vector(SA-1 downto 0);
        output: out std_logic_vector(SA-1 downto 0);

        add: in std_logic;
        pop: in std_logic;
        error: out std_logic
	);
end lifo;

architecture a of lifo is

    type STORAGE is array (LS-1 downto 0) of std_logic_vector(SA - 1 downto 0);

    signal memory: STORAGE;
    signal pointer: integer;

begin

    error <= '1' when ((pointer = 0) and (pop = '1')) or ((pointer = LS) and (add = '1'));
    output <= (others => '0') when pointer <= 0 or pointer >= LS else
              memory(pointer -1);

    update: process(clk, reset)
    begin
        if (reset = '1') then
            pointer <= 0;
        elsif (clk'event and clk = '1') then
            if (add = '1' and pop = '0') then
                pointer <= pointer +1;
                memory(pointer) <= input;
            elsif (add = '0' and pop = '1') then
                if (pointer > 0) then
                    pointer <= pointer -1;
                    --output <= memory(pointer -1);
                end if;
            elsif (add = '1' and pop = '1') then
                if (pointer > 0) then
                    --output <= memory(pointer -1);
                    memory(pointer -1) <= input;
                else
                    memory(pointer) <= input;
                    pointer <= pointer +1;
                end if;
            end if;
        end if;
    end process;

end a;

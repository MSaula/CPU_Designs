--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity cpi_tool is
    port (
        clk: in std_logic;
        wb_stall: in std_logic
   );
end cpi_tool;

architecture a of cpi_tool is

    signal instructions: integer := 0;
    signal total_clocks: integer := 0;

begin

    counter: process(clk)
    begin
        if (clk = '1') then
            if (wb_stall = '0') then instructions <= instructions + 1; end if;
            total_clocks <= total_clocks +1;
        end if;
    end process;

end a;

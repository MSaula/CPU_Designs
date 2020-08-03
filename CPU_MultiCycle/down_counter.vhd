Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

entity down_counter is
    generic (
        size: integer := 16
     );
    port (
        -- Senyals d'entrada principals
        D: in std_logic_vector(size-1 downto 0);
        Load: in std_logic;
        Clk: in std_logic;

        Zero: out std_logic
    );
end down_counter;

architecture Behaviour of down_counter is
    signal counted: std_logic_vector(size-1 downto 0);
begin

    Zero <= '1' when counted = 0 else '0';

    updateValue: process (Load, Clk)
    begin
        if Clk'event and Clk = '1' and not (counted = 0) then
            counted <= counted -1;
        elsif Load'event and Load = '1' then
            counted <= D;
        end if;
    end process;

end Behaviour;
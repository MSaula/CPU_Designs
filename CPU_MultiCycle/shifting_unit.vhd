Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

entity shifting_unit is
    generic (
        size: integer := 6
    );
    port (
        Data: in std_logic_vector(size-1 downto 0);
        load: in std_logic;
        shift: in std_logic;
        shiftDir: in std_logic;

        ShiftOut: out std_logic_vector(size-1 downto 0)
    );
end shifting_unit;

architecture Behaviour of shifting_unit is
    signal value: std_logic_vector(size-1 downto 0);
begin

    ShiftOut <= value;

    updateValue: process (load, shift)
    begin
        if (load = '1' and load'event) then
            value <= Data;
        elsif (shift = '1' and shift'event) then
            if (shiftDir = '1') then
                value(0) <= '0';
                for i in 1 to size-1 loop
                    value(i) <= value(i-1);
                end loop;
            else
                value(size-1) <= '0';
                for i in 0 to size-2 loop
                    value(i) <= value(i+1);
                end loop;
            end if;
        end if;

    end process;

end Behaviour;

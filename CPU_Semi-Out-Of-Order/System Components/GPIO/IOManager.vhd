library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IOManager is
    generic (
        size: integer := 8;

        isOR: std_logic := '0';
        isOW: std_logic := '0'
    );
    port (
        pin: inout std_logic_vector(size-1 downto 0); -- Array de 8 pins de I/O

        data: inout std_logic_vector(size-1 downto 0); -- Bus de dades de lectura o escriptura

        WRLAT:  in std_logic; -- Pin per modificar el valor enregistrat
        RDLAT:  in std_logic; -- Pin per llegir el valor enregistrat
        WRTRIS: in std_logic; -- Pin per indicar la direcciÃ³ de cada pin
        RDTRIS: in std_logic; -- Pin per llegir l'estat de la direcciÃ³ de cada pin
        RDPORT: in std_logic; -- Pin per llegir l'estat directament del pin de sortida

        reset: in std_logic
    );
end entity IOManager;

architecture a of IOManager is
    signal dataStored: std_logic_vector(size-1 downto 0) := (others => '0');
    signal trisConfig: std_logic_vector(size-1 downto 0) := (others => isOW);
begin

    storeLatValue: process (WRLAT, reset)
    begin
        if (reset = '1') then
            dataStored <= (others => '0');
        else
            if (WRLAT = '1' and WRLAT'EVENT) then
                dataStored <= data;
            end if;
        end if;
    end process;

    storeTrisValue: process (WRTRIS, reset)
    begin
        if (reset = '1') then
            trisConfig <= (others => isOW);
        else
            if (WRTRIS = '1' and WRTRIS'EVENT and isOW = '0' and isOR = '0') then
                trisConfig <= data;
            end if;
        end if;
    end process;

    updatePinsValue: process (trisConfig, dataStored)
    begin
        for i in size-1 downto 0 loop
            if trisConfig(i) = '1' then
                pin(i) <= dataStored(i);
            else
                pin(i) <= 'Z';
            end if;
        end loop;
    end process;

    updateDataValue: process (RDLAT, RDTRIS, RDPORT)
    begin
        if (RDLAT = '0' and RDTRIS = '0' and RDPORT = '0') then
            for i in size-1 downto 0 loop
                data(i) <= 'Z';
            end loop;
        elsif (RDLAT'EVENT and RDLAT = '1') then
            data <= dataStored;
        elsif (RDTRIS'EVENT and RDTRIS = '1') then
            data <= trisConfig;
        elsif (RDPORT'EVENT and RDPORT = '1') then
            data <= pin;
        end if;
    end process;

end architecture a;

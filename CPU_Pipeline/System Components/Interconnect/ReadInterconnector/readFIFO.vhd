library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types_definitions.all;

entity rfifo is
    generic (
        capacity: integer := 5;
        size: integer := (numOfMasters + addrSize + 1)
    );
    port (
        reset: in std_logic;
        pop: in std_logic;

        Data: in RFIFOA(capacity-1 downto 0);
        load: in BitArray(capacity-1 downto 0);

        Q: out std_logic_vector(size-1 downto 0)
    );
end entity rfifo;

architecture a of rfifo is
    signal stored: RFIFOA(capacity-1 downto 0);
    signal loadAux: BitArray(capacity-1 downto 0);
    signal index: integer := 0;
begin

    Q <= stored(0);

    newValue: process (load)
      variable aux: BitArray(capacity-1 downto 0);
    begin
      for i in capacity-1 downto 0 loop
        aux(i) := '0';
      end loop;
      for i in capacity-1 downto 0 loop
        if ((load(i) = '1') and (loadAux(i) = '0')) then
          aux(i) := '1';
        end if;
      end loop;
      loadAux <= aux;
    end process;

    addPopValue: process (loadAux, reset, pop)
        variable indexAux: integer;
    begin
        indexAux := index;
        if (reset = '1') then
            for i in capacity-1 downto 0 loop
                stored(i) <= (others => '0');
            end loop;
        elsif (loadAux'event) then
            for i in capacity-1 downto 0 loop
                if (loadAux(i) = '1') then
                    stored(indexAux) <= Data(i);
                    if not (indexAux = capacity-1) then
                      indexAux := indexAux+1;
                    end if;
                end if;
            end loop;
        elsif (pop'event and pop = '1') then
            for i in 0 to capacity-2 loop
                stored(i) <= stored(i+1);
            end loop;
            stored(capacity-1) <= (others => '0');
            if indexAux > 0 then
              indexAux := indexAux-1;
            end if;
        end if;
        index <= indexAux;
    end process;

end architecture a;

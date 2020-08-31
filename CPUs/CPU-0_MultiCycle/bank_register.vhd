Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
USE ieee.numeric_std.all;

entity bank_register is
    generic (
        lenght :   integer := 16;
        size:      integer := 16;
        addr_size: integer := 6
    );
    port (
        -- Senyals d'entrada principals
        Addr1: in std_logic_vector(addr_size-1 downto 0);
        Addr2: in std_logic_vector(addr_size-1 downto 0);
        AddrI: in std_logic_vector(addr_size-1 downto 0);
        Input: in std_logic_vector(size-1 downto 0);
        UBR:   in std_logic;
        OE1:    in std_logic;
        OE2:    in std_logic;
        ualui:  in std_logic;
        
        Out1: out std_logic_vector(size-1 downto 0);
        Out2: out std_logic_vector(size-1 downto 0);
        OutAux: out std_logic_vector(size-1 downto 0)
    );
end bank_register;

architecture Behaviour of bank_register is
    type BANK is array (lenght-1 downto 0) of std_logic_vector(size-1 downto 0);
    signal bankRegister: BANK := (others => (others => '0'));
begin

    Out1 <= bankRegister(to_integer(signed(Addr1))) when OE1 = '1' else (others => '0');
    Out2 <= bankRegister(to_integer(signed(Addr2))) when OE1 = '1' else (others => '0');
    
    updateOutAux: process (ualui)
    begin
      if (ualui = '1' and OE2 = '1') then
        OutAux <= bankRegister(to_integer(signed(AddrI)));
      end if;
    end process;

    updateBank: process (UBR)
    begin
        if (UBR = '1') then
            bankRegister(to_integer(signed(AddrI))) <= Input;
        end if;
    end process;

end Behaviour;
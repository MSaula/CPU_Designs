library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types_definitions is
  constant numOfMasters: integer := 2; -- Quantitat de Masters connectats al sistema d'interconnexi��
  constant numOfSlaves: integer := 3;  -- Quantitat de Slaves connectats al sistema d'interconnexi�
  constant addrSize: integer := 32; -- Mida del bus d'adreçes
  constant dataSize: integer := 32; -- Mida del bus de dades
  constant respSize: integer := 2;  -- Mida del bus de resposta
  constant respErrorValue: std_logic_vector(1 downto 0) := "01";
  constant slotSize: integer := 1024; -- Quantitat d'adreces de memoria virtual assignades a cada slave
  constant wordSize: integer := 32;

  type WordArray is array (integer range <>) of std_logic_vector(31 downto 0);
  type BitArray is array (integer range <>) of std_logic;
  type ErrorArray is array (integer range <>) of std_logic_vector(1 downto 0);
  type RFIFOA is array (integer range <>) of std_logic_vector((numOfMasters + wordSize + 1)-1 downto 0);
  type WFIFOA is array (integer range <>) of std_logic_vector((numOfMasters + wordSize*2 + 2)-1 downto 0);
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package gpio_configuration is
  constant addrSize: integer := 32; -- Mida del bus d'adreçes
  constant dataSize: integer := 32; -- Mida del bus de dades
  constant respSize: integer := 2;  -- Mida del bus de resposta
  constant respErrorValue: std_logic_vector(1 downto 0) := "01";
  constant slotSize: integer := 1024; -- Quantitat d'adreces de memoria virtual assignades a cada slave
  constant wordSize: integer := 32;

  constant PinsPerBloc: integer := 8;
  constant totalComponents: integer := 22;

  type Pinout is array (integer range <>) of std_logic_vector(pinsPerBloc-1 downto 0);
end package;

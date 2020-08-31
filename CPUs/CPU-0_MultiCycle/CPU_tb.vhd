library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity cpu_tb is
end cpu_tb;

architecture TB of cpu_tb is

	component cpu is
    port (
        clk: in std_logic;
        reset: in std_logic
    );
	end component;


signal clkk: std_logic := '0';
signal resett: std_logic;

constant PERIOD: time := 10 ps;

begin

	clkk <= not clkk after PERIOD /2;

  CPUU: cpu
    port map(clk => clkk, reset => resett);

	process
	begin
    
    resett <= '0';
    
    wait for PERIOD;
    resett <= '1';
    
    wait for PERIOD;
    resett <= '0';
    
    wait for PERIOD;
    
    wait;
  end process;
end TB;

configuration CPUConfig of CPU_tb is
  for TB
    for CPUU : cpu
        use entity work.cpu(bhv);
    end for;
  end for;
end CPUConfig;
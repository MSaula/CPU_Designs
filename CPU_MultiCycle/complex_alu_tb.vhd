library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity complex_alu_tb is
end complex_alu_tb;

architecture TB of complex_alu_tb is

    component complex_alu is
        generic (
            a_size : integer := 6;
            op_size : integer := 4;
            m_word : integer := 32;
            b_word : integer := 16
        );
        port (
            -- Senyals d'entrada principals
            Ain:      in std_logic_vector(b_word-1 downto 0); --Senyal A d'entrada (no processada)
            Bin:      in std_logic_vector(b_word-1 downto 0); --Senyal B d'entrada (no processada)
            OPin:     in std_logic_vector(op_size-1 downto 0); --Opcode de l'operació (no processada)
            rdin:     in std_logic_vector(a_size-1 downto 0); --Senyal B d'entrada (no processada)
            rsin:     in std_logic_vector(a_size-1 downto 0); --Senyal B d'entrada (no processada)

            -- Senyals d'entrada auxiliars
            ualui:    in std_logic; --Update ALU Inputs
            clk:      in std_logic;
            reset:    in std_logic;

            -- Senyals d'entrada provinents de la memòria
            mem_busy: in std_logic;
            readOut:  in std_logic_vector(m_word-1 downto 0);

    ----------------------------------------------------------------------------------------------
            -- Sortides
            AluOut:   out std_logic_vector(b_word-1 downto 0); --Resultat de l'operació aplicada
            busy:     out std_logic;

            -- Sortides cap a la memòria
            mem_data: out std_logic_vector(b_word-1 downto 0);
            RnW:      out std_logic;
            FALU:     out std_logic;
            AddrIn:   out std_logic_vector(a_size-1 downto 0)
    	);
    end component;

    component memory is
        generic (
            lenght: integer := 64;
            addr_size : integer := 6;
            size : integer := 32
        );
        port (
            --INPUTS
            RADDR: in std_logic_vector(addr_size-1 downto 0);
            RAVALID: in std_logic;
            WADDR: in std_logic_vector(addr_size-1 downto 0);
            WAVALID: in std_logic;
            WDATA: in std_logic_vector(size-1 downto 0);
            WDATAV: in std_logic;
            clk: in std_logic;
            reset: in std_logic;

            --OUTPUTS
            RDATA: out std_logic_vector(size-1 downto 0);
            RDATAV: out std_logic;
            RRESP: out std_logic_vector(1 downto 0);
            WRESP: out std_logic_vector(1 downto 0);
            WRESPV: out std_logic
    	);
    end component;

    component memory_driver is
        generic (
            size : integer := 6;
            word_size: integer := 32
        );
        port (
            --INPUTS
            clk: in std_logic;
            reset: in std_logic;

            --Inputs from ALU
            FALU: in std_logic;
            RnWalu: in std_logic;
            AddrALU: in std_logic_vector(size-1 downto 0);
            DataAlu: in std_logic_vector(word_size-1 downto 0);

            --Inputs from UC
            FCU: in std_logic;
            RnWCU: in std_logic;
            AddrCU: in std_logic_vector(size-1 downto 0);
            DataCU: in std_logic_vector(word_size-1 downto 0);

            --Inputs from Memory
            RDATA: in std_logic_vector(size downto 0);
            RDATAV: in std_logic;
            RRESP: in std_logic_vector(1 downto 0);
            WRESP: in std_logic_vector(1 downto 0);
            WRESPV: in std_logic;

    --------------------------------------------------------------------------------
            --OUTPUTS

            --Main outputs
            busy: out std_logic;
            readOut: out std_logic_vector(size downto 0);
            resp: out std_logic_vector(1 downto 0);

            --To memory outputs
            WADDR: out std_logic_vector(size downto 0);
            WAVALID: out std_logic;
            WDATA: out std_logic_vector(size downto 0);
            WDATAV: out std_logic;
            RADDR: out std_logic_vector(size downto 0);
            RAVALID: out std_logic
    	);
    end component;

constant a_size: integer := 6;
constant op_size: integer := 4;
constant m_word: integer := 32;
constant b_word: integer := 16;

------------------------------------------------------------------------------------------------
signal clkk: std_logic := '0';
signal resett: std_logic;

signal Ainn:     std_logic_vector(b_word-1 downto 0); --Senyal A d'entrada (no processada)
signal Binn:     std_logic_vector(b_word-1 downto 0); --Senyal B d'entrada (no processada)
signal OPinn:    std_logic_vector(op_size-1 downto 0); --Opcode de l'operació (no processada)
signal rdinn:    std_logic_vector(a_size-1 downto 0); --Senyal B d'entrada (no processada)
signal rsinn:    std_logic_vector(a_size-1 downto 0); --Senyal B d'entrada (no processada)

signal ualuii:   std_logic; --Update ALU Inputs

signal mem_busyy: std_logic;
signal readOutt: std_logic_vector(m_word-1 downto 0);

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  

signal AluOutt:   std_logic_vector(b_word-1 downto 0); --Resultat de l'operació aplicada
signal busyy: std_logic;

signal RnWaluu: std_logic;
signal DataAluu: std_logic_vector(m_word-1 downto 0);
signal AddrALUU: std_logic_vector(a_size-1 downto 0);
signal FALUU: std_logic;

-----------------------------------------------------------------------------------------------

signal RADDRR: std_logic_vector(a_size-1 downto 0);
signal RAVALIDD: std_logic;
signal WADDRR: std_logic_vector(a_size-1 downto 0);
signal WAVALIDD: std_logic;
signal WDATAA: std_logic_vector(m_word-1 downto 0);
signal WDATAVV: std_logic;

signal RDATAA: std_logic_vector(m_word-1 downto 0);
signal RDATAVV: std_logic;
signal RRESPP: std_logic_vector(1 downto 0);
signal WRESPP: std_logic_vector(1 downto 0);
signal WRESPVV: std_logic;

signal FCUU: std_logic;
signal RnWCUU: std_logic;
signal AddrCUU: std_logic_vector(a_size-1 downto 0);
signal DataCUU: std_logic_vector(m_word-1 downto 0);

signal respp: std_logic_vector(1 downto 0);

constant PERIOD: time := 10 ps;

begin

	clkk <= not clkk after PERIOD /2;

	M: memory
    generic map(
        lenght => 64,
        addr_size => 6,
        size => 32
    )
    port map(
        RADDR => RADDRR,
        RAVALID => RAVALIDD,
        WADDR => WADDRR,
        WAVALID => WAVALIDD,
        WDATA => WDATAA,
        WDATAV => WDATAVV,
        clk => clkk,
        reset => resett,

        RDATA => RDATAA,
        RDATAV => RDATAVV,
        RRESP => RRESPP,
        WRESP => WRESPP,
        WRESPV => WRESPVV
	);

    MD: memory_driver
    generic map(
        size => 6,
        word_size => 32
    )
    port map(
        clk => clkk,
        reset => resett,

        FALU => FALUU,
        RnWalu => RnWaluu,
        AddrALU => AddrALUU,
        DataAlu => DataAluu,

        FCU => FCUU,
        RnWCU => RnWCUU,
        AddrCU => AddrCUU,
        DataCU => DataCUU,

        RDATA => RDATAA,
        RDATAV => RDATAVV,
        RRESP => RRESPP,
        WRESP => WRESPP,
        WRESPV => WRESPVV,

        busy => mem_busyy,
        readOut => readOutt,
        resp => respp,

        WADDR => WADDRR,
        WAVALID => WAVALIDD,
        WDATA => WDATAA,
        WDATAV => WDATAVV,
        RADDR => RADDRR,
        RAVALID => RAVALIDD
    );

    CA: complex_alu
    generic map (
        a_size => 6,
        op_size => 4,
        m_word => 32,
        b_word => 16
    )
    port map(
        Ain => Ainn,
        Bin => Binn,
        OPin => OPinn,
        rdin => rdinn,
        rsin => rsinn,

        ualui => ualuii,
        clk => clkk,
        reset => resett,

        mem_busy => mem_busyy,
        readOut => readOutt,

        AluOut => AluOutt,
        busy => busyy,

        mem_data => DataAluu,
        RnW => RnWaluu,
        FALU => FALUU,
        AddrIn => AddrALUU
    );

	process
	begin

		resett <= '0';

        Ainn <= (others => '0');
        Binn <= (others => '0');
        OPinn <= (others => '0');
        rdinn <= (others => '0');
        ualuii <= '0';

   	wait for PERIOD;
		resett <= '1';
   	wait for PERIOD;
		resett <= '0';

    wait for PERIOD * 1;

        Ainn <= x"0026";
        Binn <= x"0003";
        Opinn <= "1010";

    wait for PERIOD;
        ualuii <= '1';

    wait for PERIOD;
        ualuii <= '0';

    wait for PERIOD * 15;
        Opinn <= "1011";

    wait for PERIOD;
        ualuii <= '1';

    wait for PERIOD;
        ualuii <= '0';

    wait for PERIOD * 15;

        rdinn <= "100110";
        Opinn <= "1000";

    wait for PERIOD;
        ualuii <= '1';

    wait for PERIOD;
        ualuii <= '0';
    
    while busyy = '0' loop 
      wait for PERIOD;
    end loop;
    while busyy = '1' loop 
      wait for PERIOD;
    end loop;
    
    -----wait for PERIOD * 40;
        OPinn <= "0111";

    wait for PERIOD;
        ualuii <= '1';

    wait for PERIOD;
        ualuii <= '0';

    wait for PERIOD * 40;

    wait;
  end process;
end TB;

configuration complexALUConfig of complex_alu_tb is
  for TB
    for M : memory
        use entity work.memory(bhv);
    end for;
    for MD : memory_driver
        use entity work.memory_driver(bhv);
    end for;
    for CA : complex_alu
        use entity work.complex_alu(bhv);
    end for;
  end for;
end complexALUConfig;
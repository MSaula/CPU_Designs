library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity cpu is
  port (
    clk: in std_logic;
    reset: in std_logic
  );
end cpu;

architecture behaviour of cpu is

  component control_unit is
    generic (
        op_size : integer := 4;
        a_size: integer := 6;
        c_size: integer := 8;
        size : integer := 32
    );
    port (
        --INPUTS
        mem_busy: in std_logic;
        mem_read: in std_logic_vector(size-1 downto 0);
        mem_resp: in std_logic;
        alu_busy: in std_logic;
        alu_iseq: in std_logic;
        reset:    in std_logic;
        clk:      in std_logic;

        newPC:    in std_logic_vector(a_size-1 downto 0);

        --OUTPUTS
        RnW: out std_logic;
        Addr: out std_logic_vector(a_size-1 downto 0);
        FCU: out std_logic;
        ualui: out std_logic;
        UBR: out std_logic;
        OE1: out std_logic;
        OE2: out std_logic;
        
        stateAux: out std_logic_vector(3 downto 0);
        futureStateAux: out std_logic_vector(3 downto 0);

        opcode: out std_logic_vector(op_size-1 downto 0);
        rd: out std_logic_vector(a_size-1 downto 0);
        rs: out std_logic_vector(a_size-1 downto 0);
        rt: out std_logic_vector(a_size-1 downto 0);
        ct: out std_logic_vector(c_size-1 downto 0)
	);
	end component;

	component bank_register is
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
        Input: in std_logic_vector(addr_size-1 downto 0);
        UBR:   in std_logic;
        OE1:    in std_logic;
        OE2:    in std_logic;
        ualui: in std_logic;

        Out1: out std_logic_vector(size-1 downto 0);
        Out2: out std_logic_vector(size-1 downto 0);
        OutAux: out std_logic_vector(size-1 downto 0)
    );
	end component;

    component alu is
        generic (
            a_size : integer := 6;
            op_size : integer := 4;
            m_word : integer := 32;
            b_word : integer := 16;
            ct_size : integer := 8
        );
        port (
            -- Senyals d'entrada principals
            Ain:      in std_logic_vector(b_word-1 downto 0); --Senyal A d'entrada (no processada)
            Bin:      in std_logic_vector(b_word-1 downto 0); --Senyal B d'entrada (no processada)
            OPin:     in std_logic_vector(op_size-1 downto 0); --Opcode de l'operaci? (no processada)
            rdin:     in std_logic_vector(a_size-1 downto 0); --Senyal B d'entrada (no processada)
            rsin:     in std_logic_vector(a_size-1 downto 0); --Senyal B d'entrada (no processada)
            ConstIn: in std_logic_vector(ct_size-1 downto 0); --Senyal d'entrada de la constant de l'operaci? (sense processar)

            -- Senyals d'entrada auxiliars
            ualui:    in std_logic; --Update ALU Inputs
            clk:      in std_logic;
            reset:    in std_logic;

            -- Senyals d'entrada provinents de la mem?ria
            mem_busy: in std_logic;
            readOut:  in std_logic_vector(m_word-1 downto 0);

    ----------------------------------------------------------------------------------------------
            -- Sortides
            AluOut:   out std_logic_vector(b_word-1 downto 0); --Resultat de l'operaci? aplicada
            busy:     out std_logic;

            -- Sortides cap a la mem?ria
            mem_data: out std_logic_vector(b_word-1 downto 0);
            RnW:      out std_logic;
            FALU:     out std_logic;
            AddrIn:   out std_logic_vector(a_size-1 downto 0)
    	);
    end component;

    component memory is
        generic (
            base_addr: integer := 0;
            lenght: integer := 1024;
            addr_size: integer := 32;
            data_size: integer := 32;
            size : integer := 8
        );
        port (
            --INPUTS
            RADDR: in std_logic_vector(addr_size-1 downto 0);
            RAVALID: in std_logic;
            WADDR: in std_logic_vector(addr_size-1 downto 0);
            WAVALID: in std_logic;
            WDATA: in std_logic_vector(size-1 downto 0);
            WDATAV: in std_logic;
            
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
            size : integer := 32;
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
constant ct_size: integer := 8;

------------------------------------------------------------------------------------------------
signal clkk: std_logic := '0';
signal resett: std_logic;

signal statee: std_logic_vector(3 downto 0);
signal futuree: std_logic_vector(3 downto 0);

signal Ainn:     std_logic_vector(b_word-1 downto 0); --Senyal A d'entrada (no processada)
signal Binn:     std_logic_vector(b_word-1 downto 0); --Senyal B d'entrada (no processada)
signal OPinn:    std_logic_vector(op_size-1 downto 0); --Opcode de l'operaci? (no processada)
signal rdinn:    std_logic_vector(a_size-1 downto 0); --Senyal B d'entrada (no processada)
signal rsinn:    std_logic_vector(a_size-1 downto 0); --Senyal B d'entrada (no processada)
signal rtinn:    std_logic_vector(a_size-1 downto 0); --Senyal B d'entrada (no processada)
signal ctinn:    std_logic_vector(ct_size-1 downto 0); --Senyal B d'entrada (no processada)

signal ualuii:   std_logic; --Update ALU Inputs

signal mem_busyy: std_logic;
signal readOutt: std_logic_vector(m_word-1 downto 0);

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

signal AluOutt:   std_logic_vector(b_word-1 downto 0); --Resultat de l'operaci? aplicada
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

------------------------------------------------------------------------------------------------
signal UBRR: std_logic;
signal OEE1:  std_logic;
signal OEE2:  std_logic;
signal OutAuxx: std_logic_vector(b_word-1 downto 0);
------------------------------------------------------------------------------------------------

--constant PERIOD: time := 10 ps;

begin
    
    clkk <= clk;
    resett <= reset;
	
    CU: control_unit
      generic map(
          op_size => 4,
          a_size => 6,
          c_size => 8,
          size => 32
      )
      port map(
          --INPUTS
          mem_busy => mem_busyy,
          mem_read => readOutt,
          mem_resp => respp(0),
          alu_busy => busyy,
          alu_iseq => AluOutt(0),
          reset => resett,
          clk => clkk,
          
          newPC => OutAuxx(a_size-1 downto 0),

          --OUTPUTS
          RnW => RnWCUU,
          Addr => AddrCUU,
          FCU => FCUU,
          ualui => ualuii,
          UBR => UBRR,
          OE1 => OEE1,
          OE2 => OEE2,
          
          stateAux => statee,
          futureStateAux => futuree,

          opcode => OPinn,
          rd => rdinn,
          rs => rsinn,
          rt => rtinn,
          ct => ctinn
  	);

  	BR: bank_register
  	 generic map(
          lenght => 16,
          size => 16,
          addr_size => 6
      )
      port map(
          -- Senyals d'entrada principals
          Addr1 => rsinn,
          Addr2 => rtinn,
          AddrI => rdinn,
          Input => AluOutt,
          UBR => UBRR,
          OE1 => OEE1,
          OE2 => OEE2,
          ualui => ualuii,

          Out1 => Ainn,
          Out2 => Binn,
          OutAux => OutAuxx
      );

	M: memory
    generic map(
        base_addr => 0,
        lenght => 1024,
        addr_size => 32,
        data_size => 32,
        size => 8
    )
    port map(
        RADDR => RADDRR,
        RAVALID => RAVALIDD,
        WADDR => WADDRR,
        WAVALID => WAVALIDD,
        WDATA => WDATAA,
        WDATAV => WDATAVV,

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

    ALUUUU: alu
    generic map (
        a_size => 6,
        op_size => 4,
        m_word => 32,
        b_word => 16,
        ct_size => 8
    )
    port map(
        Ain => Ainn,
        Bin => Binn,
        OPin => OPinn,
        rdin => rdinn,
        rsin => rsinn,
        ConstIn => ctinn,

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

	
end Behaviour;
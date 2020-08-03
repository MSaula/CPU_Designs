Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

entity alu is
    generic (
        a_size : integer := 6; --Mida de les adreces
        op_size: integer := 4; --Mida dels opcode
        m_word: integer := 32; --Mida del bus de memoria
        b_word: integer := 16;  --Mida del bus del banc de registres
        ct_size: integer := 8  --Mida del bus del banc de registres
    );
    port (
        -- Senyals d'entrada principals
        Ain:      in std_logic_vector(b_word-1  downto 0); --Senyal A d'entrada (no processada)
        Bin:      in std_logic_vector(b_word-1  downto 0); --Senyal B d'entrada (no processada)
        OPin:     in std_logic_vector(op_size-1 downto 0); --Opcode de l'operaci? (no processada)
        rdin:     in std_logic_vector(a_size-1  downto 0); --Senyal rd d'entrada (no processada)
        rsin:     in std_logic_vector(a_size-1  downto 0); --Senyal rd d'entrada (no processada)
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
        mem_data: out std_logic_vector(m_word-1 downto 0);
        RnW:      out std_logic;
        FALU:     out std_logic;
        AddrIn:   out std_logic_vector(a_size-1 downto 0)
	);
end alu;

architecture behaviour of alu is --Si hi ha problem, posar fsm te bona pinta (al nom de c_alu)

component complex_alu is
    generic (
        a_size : integer := 6; --Mida de les adreces
        op_size: integer := 4; --Mida dels opcode
        m_word: integer := 32; --Mida del bus de memoria
        b_word: integer := 16  --Mida del bus del banc de registres
    );
    port (
        -- Senyals d'entrada principals
        Ain:      in std_logic_vector(b_word-1  downto 0); --Senyal A d'entrada (no processada)
        Bin:      in std_logic_vector(b_word-1  downto 0); --Senyal B d'entrada (no processada)
        OPin:     in std_logic_vector(op_size-1 downto 0); --Opcode de l'operaci? (no processada)
        rdin:     in std_logic_vector(a_size-1  downto 0); --Senyal rd d'entrada (no processada)
        rsin:     in std_logic_vector(a_size-1  downto 0); --Senyal rd d'entrada (no processada)

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
        mem_data: out std_logic_vector(m_word-1 downto 0);
        RnW:      out std_logic;
        FALU:     out std_logic;
        AddrIn:   out std_logic_vector(a_size-1 downto 0)
	);
end component;

component simple_alu is
    generic (
        size : integer := 16;
        ct_size: integer := 8;
        op_size: integer := 4
    );
    port (
        -- Senyals d'entrada principals
        Ain: in std_logic_vector(size-1 downto 0); --Senyal A d'entrada (no processada)
        Bin: in std_logic_vector(size-1 downto 0); --Senyal B d'entrada (no processada)
        OPin:  in std_logic_vector(op_size-1 downto 0); --Opcode de l'operaci? (no processada)

        -- Senyals d'entrada auxiliars
        ualui: in std_logic; --Update ALU Inputs
        ConstIn: in std_logic_vector(ct_size-1 downto 0); --Senyal d'entrada de la constant de l'operaci? (sense processar)

        -- Sortides
        AluOut: out std_logic_vector(size-1 downto 0) --Resultat de l'operaci? aplicada
    );
end component;

signal A:     std_logic_vector(b_word-1  downto 0);
signal B:     std_logic_vector(b_word-1  downto 0);
signal OP:    std_logic_vector(op_size-1 downto 0);
signal rd:    std_logic_vector(a_size-1  downto 0);
signal rs:    std_logic_vector(a_size-1  downto 0);
signal ct:    std_logic_vector(ct_size-1  downto 0);

signal ualuii:   std_logic; --Update ALU Inputs
signal clkk:     std_logic;
signal resett:   std_logic;

signal mem_busyy: std_logic;
signal readOutt: std_logic_vector(m_word-1 downto 0);

signal AluOutS:   std_logic_vector(b_word-1 downto 0); --Resultat de l'operaci? aplicada
signal AluOutC:   std_logic_vector(b_word-1 downto 0); --Resultat de l'operaci? aplicada
signal busyy:     std_logic;

signal mem_dataa: std_logic_vector(m_word-1 downto 0);
signal RnWW:      std_logic;
signal FALUU:     std_logic;
signal AddrInn:   std_logic_vector(a_size-1 downto 0);

signal selector: std_logic := '0';

begin

    A <= Ain;
    B <= Bin;
    OP <= OPin;
    rd <= rdin;
    rs <= rsin;
    ct <= ConstIn;

    ualuii <= ualui;
    clkk <= clk;
    resett <= reset;

    mem_busyy <= mem_busy;
    readOutt <= readOut;

    busy <= busyy;

    mem_data <= mem_dataa;
    RnW <=  RnWW;
    FALU <= FALUU;
    AddrIn <= AddrInn;

    AluOut <= AluOutC when selector = '1' else AluOutS;

SALU: simple_alu
    generic map(
        size => 16,
        ct_size => 8,
        op_size => 4
    )
    port map(
        Ain => A,
        Bin => B,
        OPin => OP,

        ualui => ualuii,
        ConstIn => ct,

        AluOut => AluOutS
    );

CALU: complex_alu
    generic map(
        a_size => 6,
        op_size => 4,
        m_word => 32,
        b_word => 16
    )
    port map(
        Ain => A,
        Bin => B,
        OPin => OP,
        rdin => rd,
        rsin => rs,

        ualui => ualuii,
        clk => clkk,
        reset => resett,

        mem_busy => mem_busyy,
        readOut => readOutt,

        AluOut => AluOutC,
        busy => busyy,

        mem_data => mem_dataa,
        RnW => RnWW,
        FALU => FALUU,
        AddrIn => AddrInn
    );

updateOutput: process (ualui)
begin
    if (ualui = '1') then
        if (OPin = "0111" or OPin = "1000" or OPin = "1010" or OPin = "1011") then
            selector <= '1';
        else
            selector <= '0';
        end if;
    end if;
end process;

end behaviour;

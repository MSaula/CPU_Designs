Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

entity complex_alu is
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
        OPin:     in std_logic_vector(op_size-1 downto 0); --Opcode de l'operació (no processada)
        rdin:     in std_logic_vector(a_size-1  downto 0); --Senyal rd d'entrada (no processada)
        rsin:     in std_logic_vector(a_size-1  downto 0); --Senyal rd d'entrada (no processada)

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
        mem_data: out std_logic_vector(m_word-1 downto 0);
        RnW:      out std_logic;
        FALU:     out std_logic;
        AddrIn:   out std_logic_vector(a_size-1 downto 0)
	);
end complex_alu;

architecture rtl of complex_alu is --Si hi ha problem, posar fsm te bona pinta (al nom de c_alu)

component shifting_unit is
    generic (
        size: integer := b_word
    );
    port (
        Data: in std_logic_vector(size-1 downto 0);
        load: in std_logic;
        shift: in std_logic;
        shiftDir: in std_logic;

        ShiftOut: out std_logic_vector(size-1 downto 0)
    );
end component;

component down_counter is
    generic (
        size: integer := b_word
    );
    port (
        D: in std_logic_vector(size-1 downto 0);
        Load: in std_logic;
        Clk: in std_logic;

        Zero: out std_logic
    );
end component;

type state is (
	  E0,
    E1,
    E2,
    E3
);
signal current_state    : state;
signal next_state       : state;

signal NewOp: std_logic;
signal MemFinish: std_logic;
signal shift: std_logic;
signal shiftt: std_logic;
signal shiftDir: std_logic;
signal final: std_logic;
signal AluOutS: std_logic_vector(b_word-1 downto 0);
signal Rualui: std_logic;
signal RMB: std_logic;
signal FALUU: std_logic;

signal fromMem: std_logic;

signal A: std_logic_vector(b_word-1 downto 0);
signal B: std_logic_vector(b_word-1 downto 0);
signal rd: std_logic_vector(a_size-1 downto 0);
signal rs: std_logic_vector(a_size-1 downto 0);
signal opcode: std_logic_vector(op_size-1 downto 0);

begin

    AluOut <= readOut(b_word-1 downto 0) when fromMem = '1' else AluOutS;
    shift <= shiftt and not clk;
    FALU <= FALUU and not clk;

SU: shifting_unit
generic map(
    size => b_word
)
port map (
    Data => Ain,
    load => ualui,
    shift => shift,
    shiftDir => shiftDir,

    ShiftOut => AluOutS
);

DC: down_counter
generic map(
    size => b_word
)
port map(
    D => Bin,
    Load => ualui,
    Clk => shift,

    Zero => final
);

updateInputs: process (ualui)
begin
    if (ualui = '1') then
        A <= Ain;
        rd <= rdin;
        rs <= rsin;
        opcode <= OPin;
        B <= Bin;
    end if;
end process;

updateNewOperation: process (ualui, Rualui)
begin
    if (ualui = '1' and ualui'event and (OPin = "0111" or OPin = "1000" or OPin = "1010" or OPin = "1011")) then
        NewOp <= '1';
        if (OPin = "0111" or OPin = "1000") then
            fromMem <= '1';
        else
            fromMem <= '0';
        end if;
    elsif (Rualui'event and Rualui = '1') then
        NewOp <= '0';
    end if;
end process;

memFlag: process (mem_busy, RMB)
begin
    if (mem_busy = '0' and mem_busy'event) then
        MemFinish <= '1';
    elsif (RMB'event and RMB = '0') then
        MemFinish <= '0';
    end if;
end process;

shiftDirUpdate: process (ualui)
begin
  if (ualui = '1') then
    if (OPin = "1010") then
      shiftDir <= '1';
    else 
      shiftDir <= '0';
    end if;
  end if;
end process;

p_seq_next_state : process(clk,reset)
begin
  if(reset = '1') then
    current_state <= E0;
  elsif(clk = '1' and clk'event) then
    current_state <= next_state;
  end if;
end process p_seq_next_state;

p_comb_state : process(current_state, NewOp, Opcode, final, MemFinish)
begin
  case current_state is
    when E0 =>
        if (NewOp = '1' and (Opcode = "1010" or Opcode = "1011")) then
            next_state <= E1;
        elsif (NewOp = '1' and (Opcode = "0111" or Opcode = "1000")) then
            next_state <= E2;
        else
            next_state <= E0;
        end if;
	when E1 =>
		if (final = '1') then
            next_state <= E0;
        else
            next_state <= E1;
        end if;
	when E2 =>
			next_state <= E3;
	when E3 =>
		if MemFinish = '0' then
			next_state <= E3;
		else
			next_state <= E0;
		end if;
    when others =>
      next_state <= E0;
  end case;
end process p_comb_state;

p_seq_output: process (current_state, reset)
begin
  if reset'event then
      if reset = '1' then
    	  busy <= '0';
          RMB <= '1';
          Rualui <= '0';
          RnW <= '0';
          mem_data <= (others => '0');
          AddrIn <= (others => '0');
          FALUU <= '0';
          shiftt <= '0';
      end if;
  else
    case current_state is
        when E0 =>
  	  		     busy <= '0';
            RMB <= '1';
            Rualui <= '0';
            RnW <= '0';
            mem_data <= (others => '0');
            AddrIn <= (others => '0');
            FALUU <= '0';
            shiftt <= '0';
        when E1 =>
	  		      busy <= '1';
            RMB <= '0';
            Rualui <= '1';
            RnW <= '0';
            mem_data <= (others => '0');
            AddrIn <= (others => '0');
            FALUU <= '0';
            shiftt <= '1';
		when E2 =>
  	  		     busy <= '1';
            RMB <= '0';
            Rualui <= '1';
            
            if opcode = "0111" then RnW <= '1'; else RnW <= '0'; end if;
            
            for i in 0 to b_word-1 loop
              mem_data(i) <= A(i);
            end loop;
            for i in b_word to m_word-1 loop
              mem_data(i) <= '0';
            end loop;
            
            if (opcode = "0111") then
              AddrIn <= rs;
            elsif (opcode = "1000") then
              AddrIn <= rd;
            else
              AddrIn <= A;
            end if; 
            
            FALUU <= '1';
            shiftt <= '0';
		when E3 =>
  	  		     busy <= '1';
            RMB <= '0';
            Rualui <= '0';
            RnW <= '0';
            mem_data <= (others => '0');
            AddrIn <= (others => '0');
            FALUU <= '0';
            shiftt <= '0';
		when others =>
			      busy <= '0';
            RMB <= '1';
            Rualui <= '0';
            RnW <= '0';
            mem_data <= (others => '0');
            AddrIn <= (others => '0');
            FALUU <= '0';
            shiftt <= '0';
	end case;
  end if;
end process p_seq_output;
end rtl;
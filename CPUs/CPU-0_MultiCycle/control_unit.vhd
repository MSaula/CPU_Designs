Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

entity control_unit is
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
end control_unit;

architecture rtl of control_unit is
type state is (E0, E1, E2, E3, E4, E5, E6, E7, E8, E9, E54);
signal current_state    : state;
signal next_state       : state;

signal IR: std_logic_vector(size-1 downto 0);
signal PC: std_logic_vector(a_size-1 downto 0);

signal MemReady: std_logic := '0';
signal RMB: std_logic;
signal SaveI: std_logic;
signal IRaux: std_logic_vector(size-1 downto 0);
signal opcodee: std_logic_vector(op_size-1 downto 0);

signal FCUU: std_logic;
signal SaveeI: std_logic;
signal UBRR: std_logic;
signal loaddPC: std_logic;

signal loadPC: std_logic;
signal PCCount: std_logic;

signal simpleOper:  std_logic;
signal complexOper: std_logic;
signal jumpOper:    std_logic;


signal rss: std_logic_vector(a_size-1 downto 0);
signal rtt: std_logic_vector(a_size-1 downto 0);
signal rdd: std_logic_vector(a_size-1 downto 0);

signal rsAux: std_logic_vector(a_size-1 downto 0);
signal OEE1: std_logic;
signal OEE2: std_logic;

--Senyals d'errors
signal OK: std_logic;
signal MemError: std_logic;
signal IOBError: std_logic;

begin

    stateAux <= "0000" when current_state = E0 else
                "0001" when current_state = E1 else
                "0010" when current_state = E2 else
                "0011" when current_state = E3 else
                "0100" when current_state = E4 else
                "0101" when current_state = E5 else
                "0110" when current_state = E6 else
                "0111" when current_state = E7 else
                "1000" when current_state = E8 else
                "1111";

    futureStateAux <= "0000" when next_state = E0 else
                "0001" when next_state = E1 else
                "0010" when next_state = E2 else
                "0011" when next_state = E3 else
                "0100" when next_state = E4 else
                "0101" when next_state = E5 else
                "0110" when next_state = E6 else
                "0111" when next_state = E7 else
                "1000" when next_state = E8 else
                "1111";

    opcodee <= IR(31 downto 28);
    opcode <= opcodee when not (opcodee = "1101") else "1111";
    rdd <= IR(23 downto 18);
    --rd <= rdd when not (opcodee = "1000") else IR(11 downto 6);
    rsAux <= IR(17 downto 12) when opcodee = "0001" else IR(11 downto 6);
    rss <= rsAux when ((not ((OEE1 = '1') and (opcodee = "0111")))) else (others => '0');
    rtt <= IR(5 downto 0) when (not (IR(31 downto 28) = "0001")) else (others => '0');
    ct <= IR(7 downto 0);

    rd <= rdd;
    rs <= rss;
    rt <= rtt;

    simpleOper <= '1' when ((opcodee < "0111") or (opcodee = "1001")) else '0';
    complexOper <= '1' when ((opcodee = "0111") or (opcodee = "1000") or (opcodee = "1010") or (opcodee = "1011")) else '0';
    jumpOper <= '1' when ((opcodee = "1100") or (opcodee = "1101")) else '0';

    FCU <= FCUU and not clk;
    SaveI <= SaveeI and not clk;
    UBR <= UBRR and not clk;
    loadPC <= loaddPC and not clk;

    OEE1 <= '0' when opcodee = "0111" else '1';
    OE1 <= OEE1;

    OEE2 <= '1' when opcodee = "1100" or opcodee = "1101" else '0';
    OE2 <= OEE2;

    --OK <= '0' when (MemError = '1' or IOBError = '1') else '1';
    OK <= '1';

    checkMemError: process (reset, mem_busy)
    begin
      if (reset = '1') then
        MemError <= '0';
      elsif (mem_busy'event and mem_busy = '0') then
        MemError <= mem_resp;
      end if;
    end process;

    checkIOBError: process (reset, current_state)
    begin
      if (reset = '1') then
        IOBError <= '0';
      elsif (current_state'event and (current_state = E3 or current_state = E4 or current_state = E7 or current_state = E8)) then
        if ((opcodee < "0111") or (opcodee = "1001") or (opcodee = "1010") or (opcodee = "1011")) then

            if (rdd >= 16 or rss >= 16 or rtt >= 16) then
              IOBError <= '1';
            else
              IOBError <= '0';
            end if;

        elsif (opcodee = "0111") then

            if (rdd >= 64 or rss >= 16) then
              IOBError <= '1';
            else
              IOBError <= '0';
            end if;

        elsif (opcodee = "1000") then

            if (rdd >= 16 or rss >= 64) then
              IOBError <= '1';
            else
              IOBError <= '0';
            end if;

        elsif (opcodee = "1101" or opcodee = "1100") then

            if (rdd >= 64 or rss >= 16 or rtt >= 16) then
              IOBError <= '1';
            else
              IOBError <= '0';
            end if;

        else
            IOBError <= '1';

        end if;
      end if;
    end process;

updateMemBusy: process (mem_busy, RMB, reset)
begin
    if (reset'event and reset = '1') then
      MemReady <= '0';
    else
      if (mem_busy'event and mem_busy = '0') then
          MemReady <= '1';
      elsif RMB = '1' then
          MemReady <= '0';
      end if;
    end if;
end process;

updateIR: process (MemReady, SaveI, reset)
begin
    if (reset'event and reset = '1') then
      IR <= (others => '0');
    else
     if (MemReady'event and MemReady = '1') then
          IRaux <= mem_read;
      end if;
      if (SaveI'event and SaveI = '1') then
          IR <= IRaux;
      end if;
    end if;
end process;

PCCounter: process(loadPC, PCCount, reset)
begin
    if (loadPC'event and loadPC = '1') then
        PC <= newPC * 4;
    elsif (PCCount'event and PCCount = '1') then
        PC <= PC + 4;
    elsif reset = '1' then
        PC <= (others => '0');
    end if;
end process;

p_seq_next_state : process(clk,reset, OK)
begin
  if(reset = '1') then
    current_state <= E54;
  elsif(clk = '1' and clk'event) then
    current_state <= next_state;
  end if;

  if (reset = '0' and OK = '0') then
    current_state <= E9;
  end if;
end process p_seq_next_state;

p_comb_state : process(current_state, MemReady, simpleOper, complexOper, jumpOper, opcodee, alu_busy)
begin
  case current_state is
  when E54 =>
    next_state <= E0;
    when E0 =>
        next_state <= E1;
	when E1 =>
		if MemReady = '1' then
            next_state <= E2;
        else
            next_state <= E1;
        end if;
	when E2 =>
	      if (OK = '1') then
          if ((opcodee < "0111") or (opcodee = "1001")) then--simpleOper = '1' then
              next_state <= E3;
          elsif ((opcodee = "0111") or (opcodee = "1000") or (opcodee = "1010") or (opcodee = "1011")) then--complexOper = '1' then
              next_state <= E4;
          elsif (opcodee = "1101") then--jumpOper = '1' and opcodee = "1101" then
              next_state <= E7;
          else
              next_state <= E8;
          end if;
        else
          next_state <= E9;
        end if;
	  when E3 =>
        next_state <= E0;
    when E4 =>
        next_state <= E5;
    when E5 =>
      if OK = '1' then
        if alu_busy = '1' then
            next_state <= E5;
        elsif not (opcodee = "1000") then
            next_state <= E6;
        else
            next_state <= E0;
        end if;
      else
        next_state <= E9;
      end if;
    when E6 =>
        next_state <= E0;
    when E7 =>
        next_state <= E0;
    when E8 =>
        next_state <= E0;
    when E9 =>
        next_state <= E9;
    when others =>
        next_state <= E0;
  end case;
end process p_comb_state;

p_seq_output: process (current_state, reset, alu_iseq, PC)
begin
  if reset'event then
      if reset = '1' then
          PCCount <= '0';
          RnW <= '1';
          Addr <= PC;
          FCUU <= '1';
          RMB <= '1';
          SaveeI <= '0';
          ualui <= '0';
          UBRR <= '0';
          loaddPC <= '0';
      end if;
  else
    case current_state is
        when E0 =>
            PCCount <= '0';
            RnW <= '1';
            Addr <= PC;
            FCUU <= '1';
            RMB <= '1';
            SaveeI <= '0';
            ualui <= '0';
            UBRR <= '0';
            loaddPC <= '0';
        when E1 =>
  	  		PCCount <= '1';
            RnW <= '0';
            Addr <= (others => '0');
            FCUU <= '0';
            RMB <= '0';
            SaveeI <= '0';
            ualui <= '0';
            UBRR <= '0';
            loaddPC <= '0';
		when E2 =>
  	  		PCCount <= '1';
            RnW <= '0';
            Addr <= (others => '0');
            FCUU <= '0';
            RMB <= '1';
            SaveeI <= '1';
            ualui <= '0';
            UBRR <= '0';
            loaddPC <= '0';
        when E3 =>
            PCCount <= '1';
            RnW <= '0';
            Addr <= (others => '0');
            FCUU <= '0';
            RMB <= '0';
            SaveeI <= '0';
            ualui <= '1';
            UBRR <= '1';
            loaddPC <= '0';
        when E4 =>
            PCCount <= '1';
            RnW <= '0';
            Addr <= (others => '0');
            FCUU <= '0';
            RMB <= '0';
            SaveeI <= '0';
            ualui <= '1';
            UBRR <= '0';
            loaddPC <= '0';
        when E5 =>
            PCCount <= '1';
            RnW <= '0';
            Addr <= (others => '0');
            FCUU <= '0';
            RMB <= '0';
            SaveeI <= '0';
            ualui <= '0';
            UBRR <= '0';
            loaddPC <= '0';
        when E6 =>
            PCCount <= '1';
            RnW <= '0';
            Addr <= (others => '0');
            FCUU <= '0';
            RMB <= '0';
            SaveeI <= '0';
            ualui <= '0';
            UBRR <= '1';
            loaddPC <= '0';
        when E7 =>
            PCCount <= '1';
            RnW <= '0';
            Addr <= (others => '0');
            FCUU <= '0';
            RMB <= '0';
            SaveeI <= '0';
            ualui <= '1';
            UBRR <= '0';
            loaddPC <= alu_iseq;
        when E8 =>
            PCCount <= '1';
            RnW <= '0';
            Addr <= (others => '0');
            FCUU <= '0';
            RMB <= '0';
            SaveeI <= '0';
            ualui <= '1';
            UBRR <= '0';
            loaddPC <= '1';
        when E9 =>
            PCCount <= '0';
            RnW <= '0';
            Addr <= (others => '0');
            FCUU <= '0';
            RMB <= '0';
            SaveeI <= '0';
            ualui <= '0';
            UBRR <= '0';
            loaddPC <= '0';
		when others =>
            PCCount <= '0';
            RnW <= '1';
            Addr <= PC;
            FCUU <= '1';
            RMB <= '0';
            SaveeI <= '0';
            ualui <= '0';
            UBRR <= '0';
            loaddPC <= '0';
	end case;
  end if;
end process p_seq_output;
end rtl;

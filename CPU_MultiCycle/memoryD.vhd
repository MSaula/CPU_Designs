Library ieee;
USE ieee.std_logic_1164.all;
--USE ieee.std_logic_signed.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity memory is
    generic (
        lenght: integer := 64;
        addr_size: integer := 6;
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
end memory;

architecture rtl of memory is --Si hi ha problem, posar fsm te bona pinta (al nom de c_alu)

component down_counter is
    generic (
        size: integer := 4
    );
    port (
        D: in std_logic_vector(size-1 downto 0);
        Load: in std_logic;
        Clk: in std_logic;

        Zero: out std_logic
    );
end component;

type STORAGE is array (lenght-1 downto 0) of std_logic_vector(size-1 downto 0);
type state is (E0, E1, E2, E3, E4, E5, E6);
signal current_state    : state;
signal next_state       : state;

signal Rno: std_logic;
signal count: std_logic;
signal countt: std_logic;
signal ReadAux: std_logic_vector(size-1 downto 0);
signal NewOrder: std_logic := '0';
signal Random: std_logic_vector(3 downto 0) := "0110";
signal Error: std_logic;
signal final: std_logic;
signal Addr: std_logic_vector(addr_size-1 downto 0);
signal readSave: std_logic;
signal readSavee: std_logic;
signal reading: std_logic;
signal writeMem: std_logic;

signal Memory: STORAGE := (
0 => "00010000000001000000000000000001",
1 => "00010000000010000000000000000001",
2 => "00010000000011000000000000000001",
3 => "00010000000100000000000000001111",
4 => "00010000000101000000000000001010",
5 => "00010000000110000000000000000111",
6 => "10100000000010000000000010000100",
7 => "10100000000001000000000001000011",
8 => "11010000000101000000000001000010",
9 => "11000000000110000000000000000000",
10 => "00010000001110000000000000001011",
11 => "10110000000001000000000001000011",
12 => "11010000000110000000000001000011",
13 => "11000000001110000000000000000000",
others => (others => '0'));

begin

    count <= countt and not clk;
    readSave <= readSavee and not clk;

DC: down_counter generic map(size => 4)
port map(
    D => Random,
    Load => NewOrder,
    Clk => count,

    Zero => final
);

--FILL_MEM: process (reset)
--begin
--end process;

updateAddr: process (WAVALID, RAVALID)
begin
    if ((WAVALID'event and WAVALID = '1') or (RAVALID'event and RAVALID = '1')) then
        if RAVALID = '1' then
            Addr <= RADDR;
        else
            Addr <= WADDR;
        end if;
    end if;
end process;

updateNewOrder: process(WAVALID, WDATAV, RAVALID, Rno)
begin
    if Rno = '1' then
        NewOrder <= '0';
    elsif (WAVALID'event or WDATAV'event or RAVALID'event) then
      if (WAVALID = '1' and WDATAV = '1') or RAVALID = '1' then
        NewOrder <= '1';
      end if;
    end if;
end process;

--updateError: process(NewOrder)
--begin
--    if NewOrder = '1' then
--        if (Random > 14) then
--            Error <= '1';
--        else
--            Error <= '0';
--        end if;
--    end if;
--end process;

--randomGen: process(clk)
--begin
--    if (clk = '1') then
--        Random <= Random +1;
--    end if;
--end process;
Random <= "0000";
Error <= '0';

updateRead: process(NewOrder, Rno)
begin
    if (Rno'event and Rno = '1') then
        reading <= '0';
    elsif (NewOrder'event and NewOrder = '1') then
        reading <= RAVALID;
    end if;
end process;

updateReadOut: process(readSave)
begin
    if (readSave = '1') then
        RDATA <= ReadAux;
    end if;
end process;

writeMemory: process(writeMem)
begin
    if (writeMem = '1') then
        --Memory(22) <= WDATA;
        Memory(to_integer(unsigned(Addr))) <= WDATA;
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

p_comb_state : process(current_state, NewOrder, reading, final, RAVALID, WAVALID, WDATAV, Error, Addr, Memory, WDATA)
begin
  case current_state is
    when E0 =>
        if NewOrder = '0' then
            next_state <= E0;
        elsif reading = '1' then
            next_state <= E1;
        elsif reading = '0' then
            next_state <= E4;
        else
            next_state <= E0;
        end if;
	when E1 =>
		next_state <= E2;
	when E2 =>
        if final = '1' then
            next_state <= E3;
        else
            next_state <= E2;
        end if;
	when E3 =>
        if RAVALID = '1' then
            next_state <= E3;
        else
            next_state <= E0;
        end if;
    when E4 =>
        next_state <= E5;
    when E5 =>
        if final = '1' then
            next_state <= E6;
        else
            next_state <= E5;
        end if;
    when E6 =>
        if WAVALID = '1' and WDATAV = '1' then
            next_state <= E6;
        else
            next_state <= E0;
        end if;
    when others =>
        next_state <= E0;
  end case;
end process p_comb_state;

p_seq_output: process (reset, current_state, NewOrder, Memory, Addr, WDATA, Error)
begin
  if reset'event then
      if reset = '1' then
          Rno <= '0';
          ReadAux <= (others => '0');
          writeMem <= '0';
          readSavee <= '0';
          countt <= '0';
          RRESP <= "00";
          RDATAV <= '0';
          WRESP <= "00";
      end if;
  else
    case current_state is
        when E0 =>
            Rno <= '0';
            ReadAux <= (others => '0');
            writeMem <= '0';
            readSavee <= '0';
            countt <= '0';
            RRESP <= "00";
            RDATAV <= '0';
            WRESP <= "00";
            WRESPV <= '0';
        when E1 =>
            Rno <= '1';
            ReadAux <= Memory(to_integer(unsigned(Addr)));
            writeMem <= '0';
            readSavee <= '1';
            countt <= '0';
            RRESP <= "00";
            RDATAV <= '0';
            WRESP <= "00";
            WRESPV <= '0';
		when E2 =>
            Rno <= '0';
            ReadAux <= (others => '0');
            writeMem <= '0';
            readSavee <= '0';
            countt <= '1';
            RRESP <= "00";
            RDATAV <= '0';
            WRESP <= "00";
            WRESPV <= '0';
        when E3 =>
            Rno <= '0';
            ReadAux <= (others => '0');
            writeMem <= '0';
            readSavee <= '0';
            countt <= '0';
            RRESP(1) <= '0';
            RRESP(0) <= Error;
            RDATAV <= '1';
            WRESP <= "00";
            WRESPV <= '0';
        when E4 =>
            Rno <= '1';
            ReadAux <= (others => '0');
            writeMem <= '1';
            readSavee <= '0';
            countt <= '0';
            RRESP <= "00";
            RDATAV <= '0';
            WRESP <= "00";
            WRESPV <= '0';
        when E5 =>
            Rno <= '0';
            ReadAux <= (others => '0');
            writeMem <= '0';
            readSavee <= '0';
            countt <= '1';
            RRESP <= "00";
            RDATAV <= '0';
            WRESP <= "00";
            WRESPV <= '0';
        when E6 =>
            Rno <= '0';
            ReadAux <= (others => '0');
            writeMem <= '0';
            readSavee <= '0';
            countt <= '0';
            RRESP <= "00";
            RDATAV <= '0';
            WRESP(1) <= '0';
            WRESP(0) <= Error;
            WRESPV <= '1';
		when others =>
            Rno <= '0';
            ReadAux <= (others => '0');
            writeMem <= '0';
            readSavee <= '0';
            countt <= '0';
            RRESP <= "00";
            RDATAV <= '0';
            WRESP <= "00";
            WRESPV <= '0';
	end case;
  end if;
end process p_seq_output;
end rtl;

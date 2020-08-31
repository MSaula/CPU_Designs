Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

entity memory_driver is
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

        --Inputs from CU
        FCU: in std_logic;
        RnWCU: in std_logic;
        AddrCU: in std_logic_vector(size-1 downto 0);
        DataCU: in std_logic_vector(word_size-1 downto 0);

--------------------------------------------------------------------------------

        --Main outputs
        busy: out std_logic;
        readOut: out std_logic_vector(word_size-1 downto 0);
        resp: out std_logic_vector(1 downto 0);

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

        RADDR: out std_logic_vector(size-1 downto 0);
        RAVALID: out std_logic;
        RDATA: in std_logic_vector(word_size-1 downto 0);
        RDATAV: in std_logic;
        RRESP: in std_logic_vector(1 downto 0);

        WADDR: out std_logic_vector(size-1 downto 0);
        WAVALID: out std_logic;
        WDATA: out std_logic_vector(word_size-1 downto 0);
        WDATAV: out std_logic;
        WRESP: in std_logic_vector(1 downto 0);
        WRESPV: in std_logic
        
	);
end memory_driver;

architecture rtl of memory_driver is
    
    type state is (E0, E1, E2, E3, E4);

    signal current_state : state;
    signal next_state : state;

    signal NewOp: std_logic;
    signal Rno: std_logic;
    signal RnW: std_logic;
    signal Addr: std_logic_vector(size-1 downto 0);
    signal Data: std_logic_vector(word_size-1 downto 0);
    signal fromALU: std_logic;
    signal reading: std_logic;
    signal writing: std_logic;
    signal D: std_logic_vector(word_size-1 downto 0);
    signal uresp: std_logic;

begin

    updateNewOp: process (FALU, FCU, Rno)
    begin
        if (FALU'event and FALU = '1') then
            NewOp <= '1';
            fromALU <= '1';
        elsif (FCU'event and FCU = '1') then
            NewOp <= '1';
            fromALU <= '0';
        elsif (Rno = '1') then
            NewOp <= '0';
        end if;
    end process;

    updateInputs: process (NewOp)
    begin
        if (NewOp = '1') then
            if (fromALU = '1') then
                reading <= RnWalu;
                writing <= not RnWalu;

                Addr <= AddrALU;
                D <= DataAlu;
            else
                reading <= RnWCU;
                writing <= not RnWCU;

                Addr <= AddrCU;
                D <= DataCU;
            end if;
        end if;
    end process;

    updateOutput: process (uresp, reading)
    begin
        if (uresp = '1' and reading = '1') then
            readOut <= RDATA;
        end if;
        if (uresp = '1' and uresp'event) then
            if reading = '1' then
                resp <= RRESP;
            else
                resp <= WRESP;
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

    p_comb_state : process(current_state, NewOp, reading, writing, WRESPV, RDATAV)
    begin
      case current_state is
        when E0 =>
            if (NewOp = '1' and reading = '1') then
                next_state <= E1;
            elsif (NewOp = '1' and writing = '1') then
                next_state <= E2;
            else
                next_state <= E0;
            end if;
    	when E1 =>
    		if (RDATAV = '1') then
                next_state <= E4;
            else
                next_state <= E1;
            end if;
    	when E2 =>
            if (WRESPV = '1') then
                next_state <= E3;
            else
                next_state <= E2;
            end if;
    	when E3 =>
            next_state <= E0;
        when E4 =>
            next_state <= E0;
        when others =>
            next_state <= E0;
      end case;
    end process p_comb_state;

    p_seq_output: process (current_state, reset)
    begin
      if reset'event then
          if reset = '1' then
        	  busy <= '0';
              WADDR <= (others => '0');
              WAVALID <= '0';
              WDATA <= (others => '0');
              WDATAV <= '0';
              Rno <= '0';
              RADDR <= (others => '0');
              RAVALID <= '0';
              uresp <= '0';
          end if;
      else
        case current_state is
            when E0 =>
                busy <= '0';
                WADDR <= (others => '0');
                WAVALID <= '0';
                WDATA <= (others => '0');
                WDATAV <= '0';
                Rno <= '0';
                RADDR <= (others => '0');
                RAVALID <= '0';
                uresp <= '0';
            when E1 =>
      	  		busy <= '1';
                WADDR <= (others => '0');
                WAVALID <= '0';
                WDATA <= (others => '0');
                WDATAV <= '0';
                Rno <= '1';
                RADDR <= Addr;
                RAVALID <= '1';
                uresp <= '0';
    		when E2 =>
      	  		busy <= '1';
                WADDR <= Addr;
                WAVALID <= '1';
                WDATA <= D;
                WDATAV <= '1';
                Rno <= '1';
                RADDR <= (others => '0');
                RAVALID <= '0';
                uresp <= '0';
            when E3 =>
                busy <= '1';
                WADDR <= Addr;
                WAVALID <= '1';
                WDATA <= D;
                WDATAV <= '1';
                Rno <= '1';
                RADDR <= (others => '0');
                RAVALID <= '0';
                uresp <= '1';
            when E4 =>
                busy <= '1';
                WADDR <= (others => '0');
                WAVALID <= '0';
                WDATA <= (others => '0');
                WDATAV <= '0';
                Rno <= '1';
                RADDR <= Addr;
                RAVALID <= '1';
                uresp <= '1';
    		when others =>
                busy <= '0';
                WADDR <= (others => '0');
                WAVALID <= '0';
                WDATA <= (others => '0');
                WDATAV <= '0';
                Rno <= '0';
                RADDR <= (others => '0');
                RAVALID <= '0';
                uresp <= '0';
    	end case;
      end if;
    end process p_seq_output;
end rtl;
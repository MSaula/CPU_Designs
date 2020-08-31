--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity control_unit is
    port (
        clk: in std_logic;
        reset: in std_logic;
        
        jump: in std_logic;
        id_err: in std_logic;      -- SrcNotReady
        if_err: in std_logic;      -- ICDOK
        exe_err: in std_logic;     -- ALUNotReady
        store: in std_logic;       -- store
        load: in std_logic;        -- load
        WRESPV: in std_logic;      -- WRESPV
        RDATAV: in std_logic;      -- RDATAV

        if_stall:  out std_logic;
        id_stall:  out std_logic;
        exe_stall: out std_logic;
        mem_stall: out std_logic;
        wb_stall:  out std_logic;
        rwbfifo: out std_logic
	);
end control_unit;

architecture a of control_unit is

    type state is (E0, E1, E2, E3, E4, E5, S0, S1, S2, S3, S4, S5, S6, S7, S8);

    signal current_state    : state;
    signal next_state       : state;

    signal ifss: std_logic;
    signal idss: std_logic;
    signal exess: std_logic;
    signal memss: std_logic;
    signal wbss: std_logic;

    signal ifsd: std_logic;
    signal idsd: std_logic;
    signal exesd: std_logic;
    signal memsd: std_logic;
    signal wbsd: std_logic;

    signal global_stall: boolean;

begin

    global_stall <= ((if_err = '1') or (exe_err = '1')) or (((load = '1') and (RDATAV = '0')) or ((store = '1') and (WRESPV = '0')));

    if_stall  <= '1' when (global_stall or ifsd = '1')  or ifss  = '1' else '0';
    id_stall  <= '1' when (global_stall or idsd = '1')  or idss  = '1' else '0';
    exe_stall <= '1' when (global_stall or exesd = '1') or exess = '1' else '0';
    mem_stall <= '1' when (global_stall or memsd = '1') or memss = '1' else '0';
    wb_stall  <= '1' when (global_stall or wbsd = '1')  or wbss  = '1' else '0';

    ifsd <= id_err;
    idsd <= id_err;

    data_dependency_hazard_control: process (clk, reset, jump)
    begin
        if ((clk'event and clk = '1') and not global_stall) then
            if (reset = '0' and jump = '0') then
                exesd <= idsd;
                memsd <= exesd;
                wbsd <= memsd;
              else
                exesd <= '0';
                memsd <= '0';
                wbsd <= '0';
            end if;
        end if;
    end process data_dependency_hazard_control;

    p_seq_next_state : process(clk, reset)
    begin
      if(reset = '1') then
        current_state <= E0;
      elsif ((clk = '1' and clk'event) and not global_stall) then
        current_state <= next_state;
      end if;
    end process p_seq_next_state;

    p_comb_state_start : process(current_state, jump)
    begin
      case current_state is
        when E0 =>
            next_state <= E1;
        when E1 =>
            next_state <= E2;
    	when E2 =>
            next_state <= E3;
        when E3 =>
            next_state <= E4;
        when E4 =>
            next_state <= E5;
        when E5 =>
            if (jump = '1') then
                next_state <= E0;
            end if;
        when others =>
            next_state <= E0;
      end case;
    end process p_comb_state_start;

    p_seq_output_start: process (current_state, reset)
    begin
      if (reset'event and (reset = '1')) then
          ifss <= '1';
          idss <= '1';
          exess <= '1';
          memss <= '1';
          wbss <= '1';
          rwbfifo <= '1';
      else
        case current_state is
            when E0 =>
                ifss <= '0';
                idss <= '1';
                exess <= '1';
                memss <= '1';
                wbss <= '1';
                rwbfifo <= '1';
            when E1 =>
                ifss <= '0';
                idss <= '1';
                exess <= '1';
                memss <= '1';
                wbss <= '1';
                rwbfifo <= '0';
            when E2 =>
                ifss <= '0';
                idss <= '0';
                exess <= '1';
                memss <= '1';
                wbss <= '1';
                rwbfifo <= '0';
            when E3 =>
                ifss <= '0';
                idss <= '0';
                exess <= '0';
                memss <= '1';
                wbss <= '1';
                rwbfifo <= '0';
            when E4 =>
                ifss <= '0';
                idss <= '0';
                exess <= '0';
                memss <= '0';
                wbss <= '1';
                rwbfifo <= '0';
            when E5 =>
                ifss <= '0';
                idss <= '0';
                exess <= '0';
                memss <= '0';
                wbss <= '0';
                rwbfifo <= '0';
            when others =>
                ifss <= '0';
                idss <= '0';
                exess <= '0';
                memss <= '0';
                wbss <= '0';
                rwbfifo <= '0';
    	end case;
      end if;
    end process p_seq_output_start;

end a;

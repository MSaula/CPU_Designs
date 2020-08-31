-- Last version 28/07/2020 (17:35)

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library STD;
use STD.textio.all;

library altera;
use altera.all;
use work.all;

entity wb_fifo_tb is
end wb_fifo_tb;

architecture TB of wb_fifo_tb is

    component wb_fifo is
        generic (
            -- System
            SB: integer:= 5;
            SD: integer:= 32;
            SX: integer:= 17;

            -- Instruction
            IO: integer:= 4;
            IX: integer:= 2;
            IY: integer:= 11
        );
        port (
            clk: in std_logic;
            reset: in std_logic;
            wb_stall: in std_logic;
            id_stall: in std_logic;

            -- Main INPUTS
            rd: in std_logic_vector(SB-1 downto 0);
            op: in std_logic_vector(SX-1 downto 0);

            -- Secondary INPUTS
            rs: in std_logic_vector(SB-1 downto 0);
            rt: in std_logic_vector(SB-1 downto 0);

            -- OUTPUTS
            rd_out: out std_logic_vector(SB-1 downto 0);
            op_out: out std_logic_vector(SX-1 downto 0);

            SrcNotReady: out std_logic

    	);
    end component;

    constant SB: integer := 5;
    constant SD: integer := 32;
    constant SX: integer := 17;
    constant IO: integer := 4;
    constant IX: integer := 2;
    constant IY: integer := 11;

    constant PERIOD: time := 10 ps;
    signal clk: std_logic := '0';

    signal reset: std_logic;
    signal wb_stall: std_logic;
    signal id_stall: std_logic;
    signal rd: std_logic_vector(SB-1 downto 0);
    signal op: std_logic_vector(SX-1 downto 0);
    signal rs: std_logic_vector(SB-1 downto 0);
    signal rt: std_logic_vector(SB-1 downto 0);
    signal rd_out: std_logic_vector(SB-1 downto 0);
    signal op_out: std_logic_vector(SX-1 downto 0);
    signal SrcNotReady: std_logic;

begin

    clk <= not clk after PERIOD/2;

    WBFIFO: wb_fifo
    generic map (
        SB => 5,
        SD => 32,
        SX => 17,
        IO => 4,
        IX => 2,
        IY => 11
    ) port map (
        clk => clk,
        reset => reset,
        wb_stall => wb_stall,
        id_stall => id_stall,
        rd => rd,
        op => op,
        rs => rs,
        rt => rt,
        rd_out => rd_out,
        op_out => op_out,
        SrcNotReady => SrcNotReady
    );

	process
	begin

        reset <= '0';
        wb_stall <= '1';
        id_stall <= '1';
        rd <= "00001";
        op <= (others => '0');
        rs <= "00000";
        rt <= "00000";

        wait for PERIOD/2;
        reset <= '1';
        wait for PERIOD/2;
        reset <= '0';
        wait for PERIOD/2;

        rd <= "00001";
        wait for PERIOD;

        id_stall <= '0';
        for i in 2 to 5 loop
            rd <= "00000" + std_logic_vector(to_unsigned(i, 5));
            wait for PERIOD;
        end loop;

        wb_stall <= '0';
        for i in 6 to 31 loop
            rd <= "00000" + std_logic_vector(to_unsigned(i, 5));
            wait for PERIOD;
        end loop;

        ------------------------------------------------------------

        reset <= '1';
        wait for PERIOD;

        reset <= '0';
        id_stall <= '1';
        wb_stall <= '1';
        rd <= "00000";
        wait for PERIOD;

        rd <= "00001";
        wait for PERIOD;

        id_stall <= '0';
        for i in 2 to 4 loop
            rd <= "00000" + std_logic_vector(to_unsigned(i, 5));
            wait for PERIOD;
        end loop;

        wb_stall <= '0';
        for i in 5 to 31 loop
            rd <= "00000" + std_logic_vector(to_unsigned(i, 5));
            rs <= "11111" - std_logic_vector(to_unsigned(i, 5));
            rt <= "00000" + std_logic_vector(to_unsigned(i, 5));
            wait for PERIOD;
        end loop;

        wait;
    end process;
end TB;

--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity write_back_module is
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
        WB_Stall: in std_logic;
        ID_Stall: in std_logic;
        reset_fifo: in std_logic;

        rs: in std_logic_vector(SB-1 downto 0);
        rt: in std_logic_vector(SB-1 downto 0);
        rd: in std_logic_vector(SB-1 downto 0);

        NewValue: in std_logic_vector(SD-1 downto 0);
        DecodeOpcode: in std_logic_vector(SX-1 downto 0);

        R1: out std_logic_vector(SD-1 downto 0);
        R2: out std_logic_vector(SD-1 downto 0);

        SrcNotReady: out std_logic
	);
end write_back_module;

architecture a of write_back_module is

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

    type STORAGE is array ((2**SB)-1 downto 0) of std_logic_vector(SD-1 downto 0);

    signal GPBR: STORAGE := (others => (others => '0'));
    signal FPBR: STORAGE := (others => (others => '0'));

    signal r1_isFloat: boolean;
    signal r2_isFloat: boolean;
    signal r2_isD: boolean;

    signal wb_isFloat: boolean;
    signal wb_needsWB: boolean;

    signal op: std_logic_vector(IO-1 downto 0) := (others => '0');
    signal flag: std_logic_vector(IX-1 downto 0) := (others => '0');
    signal flag2: std_logic_vector(IY-1 downto 0) := (others => '0');

    signal B: std_logic_vector(SD-1 downto 0) := (others => '0');
    signal D: std_logic_vector(SD-1 downto 0) := (others => '0');

    signal LIFO_error: std_logic;

    signal wb_rd: std_logic_vector(SB-1 downto 0) := (others => '0');
    signal wb_instruction: std_logic_vector(SX-1 downto 0) := (others => '0');

    signal rfifo: std_logic;

begin

    op <= DecodeOpcode(IO-1 downto 0);
    flag <= DecodeOpcode(IX+IO-1 downto IO);
    flag2 <= DecodeOpcode(IY+IX+IO-1 downto IO+IX);

    r1_isFloat <= ((op = "0100") and (flag = "00")) or
        ((op = "0000") and (flag = "10")) or
        ((op = "0101") and (flag = "10") and (flag2 = "00000000001")) or
        ((op = "1101") and (flag = "10"));

    r2_isFloat <= ((op = "0100") and (flag = "00")) or
        ((op = "0000") and (flag = "10")) or
        ((op = "0101") and (flag = "10") and (flag2 = "00000000001")) or
        ((op = "1101") and (flag = "10")) or
        ((op = "1000") and (flag = "11"));

    r2_isD <= (op = "1000") or (op = "0010") or (op = "1101");

    R1 <= FPBR(to_integer(unsigned(rs))) when r1_isFloat else GPBR(to_integer(unsigned(rs)));

    B <= FPBR(to_integer(unsigned(rt))) when r2_isFloat else GPBR(to_integer(unsigned(rt)));
    D <= FPBR(to_integer(unsigned(rd))) when r2_isFloat else GPBR(to_integer(unsigned(rd)));
    R2 <= D when r2_isD else B;

    rfifo <= reset or reset_fifo;

    FIFO: wb_fifo
    generic map (
        SB => SB,
        SD => SD,
        SX => SX,

        IO => IO,
        IX => IX,
        IY => IY
    ) port map (
        clk => clk,
        reset => rfifo,
        wb_stall => WB_Stall,
        id_stall => ID_Stall,
        rd => rd,
        op => DecodeOpcode,
        rs => rs,
        rt => rt,
        rd_out => wb_rd,
        op_out => wb_instruction,
        SrcNotReady => SrcNotReady
    );

    wb_isFloat <=
        ((wb_instruction(IO-1 downto 0) = "0100") and (wb_instruction(5 downto 4) = "01")) or
        ((wb_instruction(IO-1 downto 0) = "0111") and (wb_instruction(5 downto 4) = "11")) or
        ((wb_instruction(IO-1 downto 0) = "0000") and (wb_instruction(5 downto 4) = "10"));-- or
        --((wb_instruction(IO-1 downto 0) = "0101") and (wb_instruction(5 downto 4) = "10") and (wb_instruction(16 downto 6) = "00000000001"));

    wb_needsWB <=
        (wb_instruction(IO-1 downto 0) = "0000") or
        (wb_instruction(IO-1 downto 0) = "0001") or
        (wb_instruction(IO-1 downto 0) = "0010") or
        (wb_instruction(IO-1 downto 0) = "0011") or
        (wb_instruction(IO-1 downto 0) = "0100") or
        (wb_instruction(IO-1 downto 0) = "0101") or
        (wb_instruction(IO-1 downto 0) = "0110") or
        (wb_instruction(IO-1 downto 0) = "0111") or
        (wb_instruction(IO-1 downto 0) = "1111");

    updateBR: process(clk)
    begin
        if (clk = '1' and wb_needsWB and WB_Stall = '0') then
            if (wb_isFloat) then
                FPBR(to_integer(unsigned(wb_rd))) <= NewValue;
            else
                GPBR(to_integer(unsigned(wb_rd))) <= NewValue;
            end if;
        end if;
    end process;

end a;

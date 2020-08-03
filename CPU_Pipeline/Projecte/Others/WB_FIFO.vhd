--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity wb_fifo is
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
end wb_fifo;

architecture a of wb_fifo is

    constant fifo_size: integer := 7;
    type RD_STORAGE is array (fifo_size-1 downto 0) of std_logic_vector(SB-1 downto 0);
    type OP_STORAGE is array (fifo_size-1 downto 0) of std_logic_vector(SX-1 downto 0);

    signal FIFO_rd: RD_STORAGE;
    signal FIFO_op: OP_STORAGE;
    signal in_pointer: integer := 0;
    signal out_pointer: integer := 0;

    signal quantity: integer := 0;

begin

    rd_out <= FIFO_rd(out_pointer);
    op_out <= FIFO_op(out_pointer);

    checkSNR: process(FIFO_op, FIFO_rd, rs, rt, rd, in_pointer, out_pointer)
        variable coincidence: boolean;
        variable index: integer;
    begin
        coincidence := false;

        -- TODO: Revisar la logica del FOR per minimitzar la mida d'aquest
        if (quantity > 0) then
            for i in 0 to quantity-1 loop
                index := i + out_pointer;
                if (index >= fifo_size) then index := index - fifo_size; end if;

                if (not (((FIFO_op(index)(IO-1 downto 0) = "1000") or (FIFO_op(index)(IO-1 downto 0) = "1100")))) then
                    if (not (op(IO-1 downto 0) = "0010" or op(IO-1 downto 0) = "1100")) then
                        if (FIFO_rd(index) = rs) then coincidence := true; end if;
                    end if;

                    if (not (op(IO-1 downto 0) = "0010" or op(IO-1 downto 0) = "1100" or op(IO-1 downto 0) = "1000" or op(IO-1 downto 0) = "0111" or
                            op(IO-1 downto 0) = "0110" or op(IO-1 downto 0) = "0100" or op(IO-1 downto 0) = "0010")) then
                        if (FIFO_rd(index) = rt) then coincidence := true; end if;
                    end if;

                    if (op(IO-1 downto 0) = "1101" or op(IO-1 downto 0) = "1100" or op(IO-1 downto 0) = "0010" or op(IO-1 downto 0) = "1000") then
                        if (FIFO_rd(index) = rd) then coincidence := true; end if;
                    end if;
                end if;
            end loop;
            if coincidence then SrcNotReady <= '1'; else SrcNotReady <= '0'; end if;
        else
            SrcNotReady <= '0';
        end if;

    end process;

    updateFIFO: process(clk, reset)
    begin
        if (reset = '1') then
            in_pointer <= 0;
            out_pointer <= 0;
            FIFO_rd <= (others => (others => '0'));
            FIFO_op <= (others => (others => '0'));
        else
            if (clk'event and clk = '1') then
                if (wb_stall = '0') then
                    if (out_pointer = fifo_size-1) then out_pointer <= 0; else out_pointer <= out_pointer +1; end if;
                end if;
                if (id_stall = '0') then
                    FIFO_rd(in_pointer) <= rd;
                    FIFO_op(in_pointer) <= op;
                    if (in_pointer = fifo_size-1) then in_pointer <= 0; else in_pointer <= in_pointer +1; end if;
                end if;
            end if;
        end if;
    end process;

    updateQuantity: process(clk, reset)
    begin
        if (reset = '1') then
            quantity <= 0;
        else
            if (clk'event and clk = '1') then
                if (wb_stall = '0' and id_stall = '1') then
                    quantity <= quantity -1;
                elsif (id_stall = '0' and wb_stall = '1') then
                    quantity <= quantity +1;
                end if;
            end if;
        end if;
    end process;


end a;

--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity memory_module is
    generic (
        -- Bus
        BA: integer:= 32;
        BD: integer:= 32;
        BE: integer:= 2;

        -- System
        SD: integer:= 32;
        SX: integer:= 17;

        -- Instruction
        IO: integer:= 4;
        IX: integer:= 2
    );
    port (
        clk: in std_logic;
        MEM_Stall: in std_logic;

        -- InterfÃ­cie de bus del sistema
        RADDR: out std_logic_vector(BA-1 downto 0);
        RAVALID: out std_logic;
        RDATA: in std_logic_vector(BD-1 downto 0);
        RDATAV: in std_logic;
        RRESP: in std_logic_vector(BE-1 downto 0);

        WADDR: out std_logic_vector(BA-1 downto 0);
        WAVALID: out std_logic;
        WDATA: out std_logic_vector(BD-1 downto 0);
        WDATAV: out std_logic;
        WRESP: in std_logic_vector(BE-1 downto 0);
        WRESPV: in std_logic;

        -- Connexions al Execution Module
        ALUOut: in std_logic_vector(SD-1 downto 0);
        SMDR: in std_logic_vector(SD-1 downto 0);
        InstructionExecuted: in std_logic_vector(SX-1 downto 0);
        cond: in std_logic;

        -- Altres connexions
        loadI: out std_logic;
        storeI: out std_logic;
        jump: out std_logic;

        NewValue: out std_logic_vector(SD-1 downto 0);
        Hmem: out std_logic
	);
end memory_module;

architecture a of memory_module is

    constant BYTE_SIZE: integer := 8;
    constant HALFWORD_SIZE: integer := 16;

    signal load: std_logic;
    signal store: std_logic;

    signal isbyte: boolean;
    signal ishalfword: boolean;

    signal isunsigned: boolean;

begin

    loadI <= load;
    storeI <= store;

    load <= '1' when
            InstructionExecuted(IO-1 downto 0) = "0111" or
            InstructionExecuted(IO-1 downto 0) = "0110"
        else '0';

    isbyte <= InstructionExecuted(IO+IX-1 downto IO) = "10";
    ishalfword <= InstructionExecuted(IO+IX-1 downto IO) = "01";
    isunsigned <= InstructionExecuted(IO-1 downto 0) = "0110";

    store <= '1' when InstructionExecuted(IO-1 downto 0) = "1000" else '0';

    jump <= '1' when MEM_Stall = '0' and
            ((InstructionExecuted(IO-1 downto 0) = "1100") or
            ((InstructionExecuted(IO-1 downto 0) = "1101") and (cond = '1')))
        else '0';

    RAVALID <= '1' when load = '1' else '0';
    WAVALID <= '1' when store = '1' else '0';
    WDATAV <= '1' when store = '1' else '0';

    RADDR <= ALUOut when load = '1' else (others => '1');
    WADDR <= ALUOut when store = '1' else (others => '1');
    WDATA <= x"000000" & SMDR(BYTE_SIZE-1 downto 0) when store = '1' and isbyte else
             x"0000" & SMDR(HALFWORD_SIZE-1 downto 0) when store = '1' and ishalfword else
             SMDR when store = '1' else
            (others => '1');

    Hmem <= '1' when ((load = '1') and (RDATAV = '0')) or ((store = '1') and (WRESPV = '0')) else '0';

    updateNewValue: process(clk)
    begin
        if (clk = '1' and MEM_Stall = '0') then
            if (load = '1') then
                if (isbyte) then
                    NewValue(BYTE_SIZE-1 downto 0) <= RDATA(BYTE_SIZE-1 downto 0);
                    if (isunsigned) then
                        NewValue(SD-1 downto BYTE_SIZE) <= (others => '0');
                    else
                        NewValue(SD-1 downto BYTE_SIZE) <= (others => RDATA(BYTE_SIZE-1));
                    end if;
                elsif (ishalfword) then
                    NewValue(HALFWORD_SIZE-1 downto 0) <= RDATA(HALFWORD_SIZE-1 downto 0);
                    if (isunsigned) then
                        NewValue(SD-1 downto HALFWORD_SIZE) <= (others => '0');
                    else
                        NewValue(SD-1 downto HALFWORD_SIZE) <= (others => RDATA(HALFWORD_SIZE-1));
                    end if;
                else
                    NewValue <= RDATA;
                end if;
            else
                NewValue <= ALUOut;
            end if;
        end if;
    end process;

end a;

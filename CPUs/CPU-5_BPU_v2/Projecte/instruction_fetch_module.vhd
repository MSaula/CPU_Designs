--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 10/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;
--
entity instruction_fetch_module is
    generic (
        -- Bus
        BA: integer:= 32;
        BD: integer:= 32;
        BE: integer:= 2;

        -- System
        SA: integer:= 32;
        SD: integer:= 32;
        SI: integer:= 32
    );
    port (
        clk: in std_logic;
        reset: in std_logic;

        jump: in std_logic;
        ALUOut: in std_logic_vector(SD-1 downto 0);
        IF_Stall: in std_logic;
        MEM_Stall: in std_logic;

        RDATA: in std_logic_vector(BD-1 downto 0);
        RDATAV: in std_logic;
        RRESP: in std_logic_vector(BE-1 downto 0);


        PC: out std_logic_vector(SA-1 downto 0);
        IR: out std_logic_vector(SI-1 downto 0);
        ICDOK: out std_logic;

        RADDR: out std_logic_vector(BA-1 downto 0);
        RAVALID: out std_logic;


        newPC: in std_logic_vector(SA-1 downto 0);
        newI: in std_logic_vector(SI-1 downto 0);
        BPUJump: in std_logic

	);
end instruction_fetch_module;

architecture a of instruction_fetch_module is

    signal PCvalue: std_logic_vector(SA-1 downto 0) := (others => '0');
    signal IRvalue: std_logic_vector(SI-1 downto 0) := (others => '0');

begin

    PC <= PCvalue;
    IR <= IRvalue;

    RADDR <= PCvalue;
    RAVALID <= not IF_Stall;
    ICDOK <= RDATAV;

    updatePC: process(clk, reset)
    begin
        if (reset = '1') then
            PCvalue <= (others => '0');
        elsif ((clk'event and clk = '1')) then
            if (jump = '1' and MEM_Stall = '0') then
                PCvalue <= ALUOut;
            elsif (IF_Stall = '0') then
                if (BPUJump = '1') then
                    PCvalue <= newPC +4;
                else
                    PCvalue <= PCvalue +4;
                end if;
            end if;
        end if;
    end process;

    updateIR: process(clk)
    begin
        if (clk = '1' and IF_Stall = '0') then
            if (BPUJump = '1') then
                IRvalue <= newI;
            else
                IRvalue <= RDATA;
            end if;
        end if;
    end process;

end a;

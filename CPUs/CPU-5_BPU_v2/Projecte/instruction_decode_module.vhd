--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity instruction_decode_module is
    generic (
        -- System
        SA: integer:= 32;
        SB: integer:= 5;
        SD: integer:= 32;
        SI: integer:= 32;
        SX: integer:= 17;

        -- Instruction
        IB: integer:= 5;
        IO: integer:= 4;
        IX: integer:= 2;
        IY: integer:= 11;
        IJ: integer:= 26
    );
    port (
        clk: in std_logic;
        ID_Stall: in std_logic;

        -- Connexions amb IFM
        IR: in std_logic_vector(SI-1 downto 0);
        PC: in std_logic_vector(SA-1 downto 0);

        -- Connexions amb el WBM
        R1: in std_logic_vector(SD-1 downto 0);
        R2: in std_logic_vector(SD-1 downto 0);

        rs: out std_logic_vector(SB-1 downto 0);
        rt: out std_logic_vector(SB-1 downto 0);
        rd: out std_logic_vector(SB-1 downto 0);

        op: out std_logic_vector(SX-1 downto 0);

        -- Connexions amb el ExeM
        A: out std_logic_vector(SD-1 downto 0);
        B: out std_logic_vector(SD-1 downto 0);
        Af: out std_logic_vector(SD-1 downto 0);
        Bf: out std_logic_vector(SD-1 downto 0);
        InstructionToExecute: out std_logic_vector(SX-1 downto 0);
        RDid: out std_logic_vector(SB-1 downto 0)
	);
end instruction_decode_module;

architecture a of instruction_decode_module is

    -- Values obtained from the ISA definition
    constant ops: integer := 31; -- Opcode start
    constant ope: integer := 28; -- Opcode end
    constant fxs: integer := 27; -- Flags X start
    constant fxe: integer := 26; -- Flags X end
    constant fys: integer := 10; -- Flags Y start
    constant fye: integer :=  0; -- Flags Y end
    constant rds: integer := 25; -- Rd start
    constant rde: integer := 21; -- Rd end
    constant rss: integer := 20; -- Rs start
    constant rse: integer := 16; -- Rs end
    constant rts: integer := 15; -- Rt start
    constant rte: integer := 11; -- Rt end
    constant ims: integer := 15; -- Immediate start
    constant ime: integer :=  0; -- Immediate end
    constant jms: integer := 25; -- Extended jump start
    constant jme: integer :=  0; -- Extended jump end


    signal PCvalue: std_logic_vector(SA-1 downto 0) := (others => '0');
    signal IRvalue: std_logic_vector(SI-1 downto 0) := (others => '0');

    signal opcode: std_logic_vector(IO-1 downto 0) := (others => '0');
    signal func: std_logic_vector((IX+IY)-1 downto 0) := (others => '0');

    signal ct: std_logic_vector(SD-1 downto 0) := (others => '0');
    signal ctaux1: std_logic_vector(SD-1 downto 0) := (others => '0');
    signal ctaux2: std_logic_vector(SD-1 downto 0) := (others => '0');

    signal operandSelector: std_logic_vector(1 downto 0) := (others => '0');

begin

    opcode <= IR(ops downto ope);
    func(IX-1 downto 0) <= IR(fxs downto fxe);
    func(IX+IY-1 downto IX) <= IR(fys downto fye);

    op(IO-1 downto 0) <= opcode;
    op(IO+IX+IY-1 downto IO) <= func;

    rs <= IR(rss downto rse);
    rd <= IR(rds downto rde);
    rt <= IR(rts downto rte);

    ctaux1((ims - ime) downto 0) <= IR(ims downto ime);
    ctaux1(SD-1 downto (ims + ime)+1) <= (others => IR(ims));

    ctaux2((jms - jme) downto 0) <= IR(jms downto jme);
    ctaux2(SD-1 downto (jms + jme)+1) <= (others => IR(jms));

    ct <= ctaux2 when opcode = "1100" else ctaux1;

    operandSelector <= "11"  when
            (opcode = "1101") or
            ((opcode = "1100") and (not (func(1 downto 0) = "10")))
        else "10" when
            ((opcode = "1100") and (func(1 downto 0) = "10")) or
            (opcode = "0010")
        else "01" when
            ((opcode = "0000") and (not (func(1 downto 0) = "01"))) or
            (opcode = "0001") or
            (opcode = "1111") or
            (opcode = "0011") or
            (opcode = "0101")
        else "00";

    updateModule: process (clk)
    begin
        if (clk = '1' and ID_Stall = '0') then
            Af <= R1;
            Bf <= R2;
            InstructionToExecute (IO-1 downto 0) <= opcode;
            InstructionToExecute (IO+IX+IY-1 downto IO) <= func;
            RDid <= IR(rds downto rde);
            
            if (IR(rds downto rde) = "00000" and opcode(IO-1 downto 1) /= "110") then
                A <= (others => '0');
                B <= (others => '0');
            else
                if (operandSelector = "00") then
                    A <= R1;
                    B <= ct;
                elsif (operandSelector = "01") then
                    A <= R1;
                    B <= R2;
                elsif (operandSelector = "10") then
                    A <= R2;
                    B <= ct;
                elsif (operandSelector = "11") then
                    A <= ct(SD-3 downto 0) & "00";
                    B <= PC - x"00000008";
                else
                    A <= (others => '0');
                    B <= (others => '0');
                end if;
            end if;
        end if;
    end process;

end a;

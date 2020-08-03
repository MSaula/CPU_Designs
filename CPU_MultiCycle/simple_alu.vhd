
Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

entity simple_alu is
    generic (
        size : integer := 16;
        ct_size: integer := 8;
        op_size: integer := 4
    );
    port (
        -- Senyals d'entrada principals
        Ain: in std_logic_vector(size-1 downto 0); --Senyal A d'entrada (no processada)
        Bin: in std_logic_vector(size-1 downto 0); --Senyal B d'entrada (no processada)
        OPin:  in std_logic_vector(op_size-1 downto 0); --Opcode de l'operació (no processada)

        -- Senyals d'entrada auxiliars
        ualui: in std_logic; --Update ALU Inputs
        ConstIn: in std_logic_vector(ct_size-1 downto 0); --Senyal d'entrada de la constant de l'operació (sense processar)

        -- Sortides
        AluOut: out std_logic_vector(size-1 downto 0) --Resultat de l'operació aplicada
    );
end simple_alu;

architecture Behaviour of simple_alu is
    signal A: std_logic_vector(size-1 downto 0);
    signal B: std_logic_vector(size-1 downto 0);
    signal opcode: std_logic_vector(op_size-1 downto 0);
    signal oac: std_logic; --Operació Amb Constant
begin

    oac <= '1' when OPin = "0001" else '0';

    AluOut <= (A + B)   when ((opcode = "0000") or (opcode = "0001")) else
              (A - B)   when (opcode = "0010") else
              (A or B)  when (opcode = "0011") else
              (A xor B) when (opcode = "0100") else
              (A and B) when (opcode = "0101") else
              (not A)   when (opcode = "0110") else
              (others => '1') when (opcode = "1001" and A > B) else
              (others => '0') when (opcode = "1001" and (A <= B)) else
              (others => '1') when (opcode = "1111" and A = B) else
              (others => '0') when (opcode = "1111" and not (A = B)) else
              A;

    updateInputs: process (ualui)
    begin
        if (ualui = '1') then
            A <= Ain;
            opcode <= OPin;

            if (oac = '0') then
                B <= Bin;
            else
              B <= (others => '0');
              for i in 0 to ct_size-1 loop
                B(i) <= ConstIn(i);
              end loop;
            end if;
        end if;
    end process;

end Behaviour;
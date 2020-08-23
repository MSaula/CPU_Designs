--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity division_scheduler is
    generic (
        SB: integer:= 5;
        BC: integer:= 8
    );
    port (
        clk: in std_logic;
        reset: in std_logic;
        start: in std_logic;
        RDin: in std_logic_vector(SB+1-1 downto 0);

        ACK: in std_logic_vector(BC-1 downto 0);
        AVA: out std_logic_vector(BC-1 downto 0);

        start_vector: out std_logic_vector(BC-1 downto 0);

        RD0: out std_logic_vector(SB+1-1 downto 0);
        RD1: out std_logic_vector(SB+1-1 downto 0);
        RD2: out std_logic_vector(SB+1-1 downto 0);
        RD3: out std_logic_vector(SB+1-1 downto 0);
        RD4: out std_logic_vector(SB+1-1 downto 0);
        RD5: out std_logic_vector(SB+1-1 downto 0);
        RD6: out std_logic_vector(SB+1-1 downto 0);
        RD7: out std_logic_vector(SB+1-1 downto 0);

        FPUfull: out std_logic
	);
end division_scheduler;

architecture a of division_scheduler is

    type RD_MATRIX is array (BC-1 downto 0) of std_logic_vector(SB+1-1 downto 0);

    signal av: std_logic_vector(BC-1 downto 0);
    signal startv: std_logic_vector(BC-1 downto 0);
    signal zeros: std_logic_vector(BC-1 downto 0) := (others => '0');

    signal rdm: RD_MATRIX;

begin

    FPUfull <= '1' when av = zeros else '0';
    AVA <= av;

    start_vector <= startv;

    RD0 <= rdm(0);
    RD1 <= rdm(1);
    RD2 <= rdm(2);
    RD3 <= rdm(3);
    RD4 <= rdm(4);
    RD5 <= rdm(5);
    RD6 <= rdm(6);
    RD7 <= rdm(7);

    start_vector_logic: process (start, av)
    begin
        startv(0) <= av(0) and start;
        for i in 1 to BC-1 loop
            if ((av(i) = '1') and (av(i-1 downto 0) = zeros(i-1 downto 0))) then
                startv(i) <= start;
            else
                startv(i) <= '0';
            end if;
        end loop;
    end process;

    update_availability: process (clk, reset)
    begin
        if (reset = '1') then
            av <= (others => '1');
            for i in BC-1 downto 0 loop rdm(i) <= (others => '0'); end loop;
        elsif (clk'event and clk = '1') then
            for i in BC-1 downto 0 loop
                if (startv(i) = '1') then
                    av(i) <= '0';
                    rdm(i) <= RDin;
                elsif (ACK(i) = '1') then
                    av(i) <= '1';
                    rdm(i) <= (others => '0');
                end if;
            end loop;
        end if;
    end process;

end a;

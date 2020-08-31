--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 10/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;
--
entity instruction_cache_memory is
    generic (
        SA: integer:= 32;
        SD: integer:= 32;
        SI: integer:= 32;
        CA: integer:= 0;
        CS: integer:= 1024;
        BA: integer:= 32;
        BD: integer:= 32;
        BE: integer:= 2
    );
    port (
        clk: in std_logic;
        reset: in std_logic;

        RADDR: in std_logic_vector(BA-1 downto 0);
        RAVALID: in std_logic;
        RDATA: out std_logic_vector(BD-1 downto 0);
        RDATAV: out std_logic;
        RRESP: out std_logic_vector(BE-1 downto 0);

        taken: in std_logic;
        not_taken: in std_logic;

        newPC: out std_logic_vector(SA-1 downto 0);
        newI: out std_logic_vector(SI-1 downto 0);
        BPUJump: out std_logic
	);
end instruction_cache_memory;

architecture a of instruction_cache_memory is

    component branch_prediction_unit is
        generic (
            SA: integer:= 32;
            SD: integer:= 32;
            SI: integer:= 32
        );
        port (
            clk: in std_logic;
            reset: in std_logic;

            taken: in std_logic;
            not_taken: in std_logic;

            PC: in std_logic_vector(SA-1 downto 0);
            Ins: in std_logic_vector(SI-1 downto 0);

            newPC: out std_logic_vector(SA-1 downto 0);
            newI: out std_logic_vector(SI-1 downto 0);
            BPUJump: out std_logic
    	);
    end component;

    constant byte_size: integer := 8;
    type STORAGE is array (CS-1 downto 0) of std_logic_vector(byte_size-1 downto 0);

    constant bytesPerWord: integer := BD / byte_size;

    signal rerror: std_logic := '0';
    -- signal Memory: STORAGE := (others => (others => '0'));
    signal Memory: STORAGE := (
0  => "00000001",
1  => "00000000",
2  => "00100001",
3  => "00000100",
4  => "00000001",
5  => "00000000",
6  => "01100001",
7  => "00000100",
8  => "00000011",
9  => "00000000",
10 => "01000001",
11 => "00010000",
12 => "00000000",
13 => "00000000",
14 => "00000001",
15 => "01000111",
16 => "00000000",
17 => "00000000",
18 => "01000001",
19 => "01000100",
20 => "00000000",
21 => "00000000",
22 => "00100010",
23 => "01000111",
24 => "00000000",
25 => "00000000",
26 => "01000011",
27 => "01000111",
28 => "00000010",
29 => "11010000",
30 => "01111010",
31 => "00001011",
32 => "00000010",
33 => "11001000",
34 => "01111011",
35 => "00001011",
36 => "00000000",
37 => "11000000",
38 => "00100001",
39 => "00001000",
40 => "00000010",
41 => "11001000",
42 => "01000010",
43 => "00001000",
44 => "00000010",
45 => "11010000",
46 => "01100001",
47 => "00001000",
48 => "00000001",
49 => "11000000",
50 => "01100011",
51 => "00001000",
52 => "00000010",
53 => "11011000",
54 => "10000010",
55 => "00001000",
56 => "00000011",
57 => "00011000",
58 => "00100100",
59 => "00001001",
60 => "00000000",
61 => "01001000",
62 => "01001010",
63 => "00001001",
64 => "11111001",
65 => "11111111",
66 => "11111111",
67 => "11000011",
68 => "00000000",
69 => "00000000",
70 => "00000000",
71 => "00000000",
others => (others => '0'));



    signal current_addr: std_logic_vector (BA-1 downto 0) := (others => '0');
    signal memout: std_logic_vector(SI-1 downto 0);

    signal BPUJumpAux: std_logic;
    signal newPCAux: std_logic_vector(SA-1 downto 0);

begin

    RRESP <= "01" when rerror = '1' else "00";
    RDATAV <= not rerror;

    updateAddrReg: process(clk)
        variable error: boolean;
    begin
        error := (to_integer(unsigned(RADDR)) < (CA)) or (to_integer(unsigned(RADDR)) > (CA + CS));
        if (clk = '1' and RAVALID = '1') then
            if error then
                rerror <= '1';
                current_addr <= (others => '0');
            else
                rerror <= '0';
                if (BPUJumpAux = '0') then
                    current_addr <= RADDR;
                else
                    current_addr <= newPCAux;
                end if;
            end if;
        end if;
    end process;

    memout((byte_size*1)-1 downto (byte_size*0)) <= (others => '0') when rerror = '1' else Memory(to_integer(unsigned(current_addr)) - CA +0);
    memout((byte_size*2)-1 downto (byte_size*1)) <= (others => '0') when rerror = '1' else Memory(to_integer(unsigned(current_addr)) - CA +1);
    memout((byte_size*3)-1 downto (byte_size*2)) <= (others => '0') when rerror = '1' else Memory(to_integer(unsigned(current_addr)) - CA +2);
    memout((byte_size*4)-1 downto (byte_size*3)) <= (others => '0') when rerror = '1' else Memory(to_integer(unsigned(current_addr)) - CA +3);

    RDATA <= memout;

    BPU: branch_prediction_unit
    generic map (
        SA => SA,
        SD => SD,
        SI => SI
    )
    port map (
        clk => clk,
        reset => reset,
        taken => taken,
        not_taken => not_taken,
        PC => current_addr,
        Ins => memout,
        newPC => newPCAux,
        newI => newI,
        BPUJump => BPUJumpAux
    );

    BPUJump <= BPUJumpAux;
    newPC <= newPCAux;

end a;

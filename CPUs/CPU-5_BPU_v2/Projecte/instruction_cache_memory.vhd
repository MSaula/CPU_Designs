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
2  => "00100000",
3  => "00000100",
4  => "00001000",
5  => "00000000",
6  => "00000000",
7  => "11000000",
8  => "00000000",
9  => "00000000",
10 => "10000000",
11 => "00000001",
12 => "00000001",
13 => "00000000",
14 => "01100000",
15 => "00000101",
16 => "00000100",
17 => "00000000",
18 => "01001100",
19 => "11010001",
20 => "00000001",
21 => "00000000",
22 => "10001100",
23 => "00000101",
24 => "00000010",
25 => "01100000",
26 => "01101011",
27 => "00000001",
28 => "11111101",
29 => "11111111",
30 => "11111111",
31 => "11000011",
32 => "00000000",
33 => "00000000",
34 => "00000000",
35 => "11001000",
36 => "00001100",
37 => "00000000",
38 => "01000000",
39 => "00000101",
40 => "11111000",
41 => "11111111",
42 => "11111111",
43 => "11000111",
44 => "00000101",
45 => "00000000",
46 => "01000000",
47 => "00000101",
48 => "11110110",
49 => "11111111",
50 => "11111111",
51 => "11000111",
52 => "00000000",
53 => "00000000",
54 => "01000000",
55 => "00000101",
56 => "11110100",
57 => "11111111",
58 => "11111111",
59 => "11000111",
60 => "00000101",
61 => "00000000",
62 => "00000000",
63 => "11000100",
64 => "00000000",
65 => "00000000",
66 => "00100001",
67 => "01000100",
68 => "00000000",
69 => "00000000",
70 => "01001011",
71 => "01000100",
72 => "00000010",
73 => "00000000",
74 => "01000001",
75 => "11011000",
76 => "11101101",
77 => "11111111",
78 => "01000010",
79 => "11011000",
80 => "00001100",
81 => "00000000",
82 => "01000000",
83 => "00000101",
84 => "00000000",
85 => "00000000",
86 => "10000000",
87 => "00000001",
88 => "00000001",
89 => "00000000",
90 => "01100000",
91 => "00000101",
92 => "00000100",
93 => "00000000",
94 => "01001100",
95 => "11010001",
96 => "00000001",
97 => "00000000",
98 => "10001100",
99 => "00000101",
100 => "00000010",
101 => "01100000",
102 => "01101011",
103 => "00000001",
104 => "11111101",
105 => "11111111",
106 => "11111111",
107 => "11000111",
108 => "00000000",
109 => "00000000",
110 => "00000000",
111 => "11001000",
112 => "00000000",
113 => "00000000",
114 => "00000000",
115 => "00000000",
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

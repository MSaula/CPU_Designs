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
4  => "00001010",
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
32 => "00000011",
33 => "00000000",
34 => "00001010",
35 => "11010000",
36 => "11111111",
37 => "11111111",
38 => "01001010",
39 => "00000101",
40 => "11111000",
41 => "11111111",
42 => "11111111",
43 => "11000011",
44 => "00000101",
45 => "00000000",
46 => "01000000",
47 => "00000101",
48 => "00000001",
49 => "00000000",
50 => "10010100",
51 => "00000110",
52 => "00000010",
53 => "00000000",
54 => "01010100",
55 => "11010001",
56 => "11110100",
57 => "11111111",
58 => "11111111",
59 => "11000011",
60 => "00000000",
61 => "00000000",
62 => "10000000",
63 => "00000010",
64 => "10111010",
65 => "00010111",
66 => "10100000",
67 => "00100010",
68 => "00100011",
69 => "10100010",
70 => "10100000",
71 => "00100110",
72 => "00001001",
73 => "00000000",
74 => "11000000",
75 => "00000110",
76 => "00001010",
77 => "00000000",
78 => "11100000",
79 => "00000110",
80 => "00000000",
81 => "00000000",
82 => "10110101",
83 => "01000110",
84 => "00000000",
85 => "00000000",
86 => "11010110",
87 => "01000110",
88 => "00000000",
89 => "00000000",
90 => "11110111",
91 => "01000110",
92 => "00000011",
93 => "10111000",
94 => "10110101",
95 => "00001010",
96 => "11111111",
97 => "11111111",
98 => "11010110",
99 => "00000110",
100 => "00000010",
101 => "00000000",
102 => "00010110",
103 => "11010000",
104 => "11111101",
105 => "11111111",
106 => "11111111",
107 => "11000011",
108 => "00000010",
109 => "10101000",
110 => "00110101",
111 => "00001011",
112 => "00000011",
113 => "00000000",
114 => "11000000",
115 => "00000110",
116 => "00000010",
117 => "10101000",
118 => "00111001",
119 => "00001011",
120 => "11111111",
121 => "11111111",
122 => "11010110",
123 => "00000110",
124 => "11100011",
125 => "11111111",
126 => "00010110",
127 => "11010000",
128 => "11111101",
129 => "11111111",
130 => "11111111",
131 => "11000011",
132 => "00000000",
133 => "00000000",
134 => "00000000",
135 => "00000000",
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

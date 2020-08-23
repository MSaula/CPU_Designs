library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types_definitions.all;

entity wiaux is
  port (
        reset: in std_logic;
        clk: in std_logic;

        M1_WADDR: in std_logic_vector(31 downto 0);
        M1_WAVALID: in std_logic;
        M1_WDATA: in std_logic_vector(31 downto 0);
        M1_WDATAV: in std_logic;
        M1_WRESP: out std_logic_vector(1 downto 0);
        M1_WRESPV: out std_logic;

        S1_WADDR: out std_logic_vector(31 downto 0);
        S1_WAVALID: out std_logic;
        S1_WDATA: out std_logic_vector(31 downto 0);
        S1_WDATAV: out std_logic;
        S1_WRESP: in std_logic_vector(1 downto 0);
        S1_WRESPV: in std_logic;

        M2_WADDR: in std_logic_vector(31 downto 0);
        M2_WAVALID: in std_logic;
        M2_WDATA: in std_logic_vector(31 downto 0);
        M2_WDATAV: in std_logic;
        M2_WRESP: out std_logic_vector(1 downto 0);
        M2_WRESPV: out std_logic;

        S2_WADDR: out std_logic_vector(31 downto 0);
        S2_WAVALID: out std_logic;
        S2_WDATA: out std_logic_vector(31 downto 0);
        S2_WDATAV: out std_logic;
        S2_WRESP: in std_logic_vector(1 downto 0);
        S2_WRESPV: in std_logic
    );
end entity wiaux;

architecture a of wiaux is

  component writeInterconnector is
      generic (
          numOfMasters: integer := 2; -- Quantitat de Masters connectats al sistema d'interconnexi��
          numOfSlaves: integer := 2;  -- Quantitat de Slaves connectats al sistema d'interconnexi��

          addrSize: integer := 32; -- Mida del bus d'adreçes
          dataSize: integer := 32; -- Mida del bus de dades
          respSize: integer := 2;  -- Mida del bus de resposta
          respErrorValue: std_logic_vector(1 downto 0) := "01";

          slotSize: integer := 1024 -- Quantitat d'adreces de memoria virtual assignades a cada slave
      );
      port (
          reset: in std_logic;
          clk: in std_logic;

          M_WADDR: in WordArray(numOfMasters-1 downto 0);
          M_WAVALID: in BitArray(numOfMasters-1 downto 0);
          M_WDATA: in WordArray(numOfMasters-1 downto 0);
          M_WDATAV: in BitArray(numOfMasters-1 downto 0);
          M_WRESP: out ErrorArray(numOfMasters-1 downto 0);
          M_WRESPV: out BitArray(numOfMasters-1 downto 0);

          S_WADDR: out WordArray(numOfSlaves-1 downto 0);
          S_WAVALID: out BitArray(numOfSlaves-1 downto 0);
          S_WDATA: out WordArray(numOfSlaves-1 downto 0);
          S_WDATAV: out BitArray(numOfSlaves-1 downto 0);
          S_WRESP: in ErrorArray(numOfSlaves-1 downto 0);
          S_WRESPV: in BitArray(numOfSlaves-1 downto 0)
      );
end component writeInterconnector;

  signal M_WADDR: WordArray(1 downto 0);
  signal M_WAVALID: BitArray(1 downto 0);
  signal M_WDATA: WordArray(1 downto 0);
  signal M_WDATAV: BitArray(1 downto 0);
  signal M_WRESP: ErrorArray(1 downto 0);
  signal M_WRESPV: BitArray(1 downto 0);

  signal S_WADDR: WordArray(1 downto 0);
  signal S_WAVALID: BitArray(1 downto 0);
  signal S_WDATA: WordArray(1 downto 0);
  signal S_WDATAV: BitArray(1 downto 0);
  signal S_WRESP: ErrorArray(1 downto 0);
  signal S_WRESPV: BitArray(1 downto 0);

begin

    M_WADDR(0) <= M1_WADDR;
    M_WADDR(1) <= M2_WADDR;
    M_WAVALID(0) <= M1_WAVALID;
    M_WAVALID(1) <= M2_WAVALID;
    M_WDATA(0) <= M1_WDATA;
    M_WDATA(1) <= M2_WDATA;
    M_WDATAV(0) <= M1_WDATAV;
    M_WDATAV(1) <= M2_WDATAV;
    M1_WRESP <= M_WRESP(0);
    M2_WRESP <= M_WRESP(1);
    M1_WRESPV <= M_WRESPV(0);
    M2_WRESPV <= M_WRESPV(1);

    S1_WADDR <= S_WADDR(0);
    S2_WADDR <= S_WADDR(1);
    S1_WAVALID <= S_WAVALID(0);
    S2_WAVALID <= S_WAVALID(1);
    S1_WDATA <= S_WDATA(0);
    S2_WDATA <= S_WDATA(1);
    S1_WDATAV <= S_WDATAV(0);
    S2_WDATAV <= S_WDATAV(1);
    S_WRESP(0) <= S1_WRESP;
    S_WRESP(1) <= S2_WRESP;
    S_WRESPV(0) <= S1_WRESPV;
    S_WRESPV(1) <= S2_WRESPV;

    RI: writeInterconnector
        generic map (
            numOfMasters => 2,
            numOfSlaves => 2,

            addrSize => 32,
            dataSize => 32,
            respSize => 2,
            respErrorValue => "01",

            slotSize => 1024
        )
        port map (
            reset => reset,
            clk => clk,

            M_WADDR => M_WADDR,
            M_WAVALID => M_WAVALID,
            M_WDATA => M_WDATA,
            M_WDATAV => M_WDATAV,
            M_WRESP => M_WRESP,
            M_WRESPV => M_WRESPV,

            S_WADDR => S_WADDR,
            S_WAVALID => S_WAVALID,
            S_WDATA => S_WDATA,
            S_WDATAV => S_WDATAV,
            S_WRESP => S_WRESP,
            S_WRESPV => S_WRESPV
        );

end architecture a;

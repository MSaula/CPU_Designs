library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types_definitions.all;

entity riaux is
  port (
        reset: in std_logic;
        clk: in std_logic;

        M1_RADDR: in std_logic_vector(31 downto 0);
        M1_RAVALID: in std_logic;
        M1_RDATA: out std_logic_vector(31 downto 0);
        M1_RDATAV: out std_logic;
        M1_RRESP: out std_logic_vector(1 downto 0);

        S1_RADDR: out std_logic_vector(31 downto 0);
        S1_RAVALID: out std_logic;
        S1_RDATA: in std_logic_vector(31 downto 0);
        S1_RDATAV: in std_logic;
        S1_RRESP: in std_logic_vector(1 downto 0);

        M2_RADDR: in std_logic_vector(31 downto 0);
        M2_RAVALID: in std_logic;
        M2_RDATA: out std_logic_vector(31 downto 0);
        M2_RDATAV: out std_logic;
        M2_RRESP: out std_logic_vector(1 downto 0);

        S2_RADDR: out std_logic_vector(31 downto 0);
        S2_RAVALID: out std_logic;
        S2_RDATA: in std_logic_vector(31 downto 0);
        S2_RDATAV: in std_logic;
        S2_RRESP: in std_logic_vector(1 downto 0)
    );
end entity riaux;

architecture a of riaux is

  component readInterconnector is
      generic (
          numOfMasters: integer := 2; -- Quantitat de Masters connectats al sistema d'interconnexió³
          numOfSlaves: integer := 2;  -- Quantitat de Slaves connectats al sistema d'interconnexió³

          addrSize: integer := 32; -- Mida del bus d'adreÃ§es
          dataSize: integer := 32; -- Mida del bus de dades
          respSize: integer := 2;  -- Mida del bus de resposta
          respErrorValue: std_logic_vector(1 downto 0) := "01";

         slotSize: integer := 1024 -- Quantitat d'adreces de memoria virtual assignades a cada slave
    );
    port (
        reset: in std_logic;
        clk: in std_logic;

        M_RADDR: in WordArray(numOfMasters-1 downto 0);
        M_RAVALID: in BitArray(numOfMasters-1 downto 0);
        M_RDATA: out WordArray(numOfMasters-1 downto 0);
        M_RDATAV: out BitArray(numOfMasters-1 downto 0);
        M_RRESP: out ErrorArray(numOfMasters-1 downto 0);

        S_RADDR: out WordArray(numOfSlaves-1 downto 0);
        S_RAVALID: out BitArray(numOfSlaves-1 downto 0);
        S_RDATA: in WordArray(numOfSlaves-1 downto 0);
        S_RDATAV: in BitArray(numOfSlaves-1 downto 0);
        S_RRESP: in ErrorArray(numOfSlaves-1 downto 0)
    );
  end component readInterconnector;

  signal M_RADDR: WordArray(1 downto 0);
  signal M_RAVALID: BitArray(1 downto 0);
  signal M_RDATA: WordArray(1 downto 0);
  signal M_RDATAV: BitArray(1 downto 0);
  signal M_RRESP: ErrorArray(1 downto 0);

  signal S_RADDR: WordArray(1 downto 0);
  signal S_RAVALID: BitArray(1 downto 0);
  signal S_RDATA: WordArray(1 downto 0);
  signal S_RDATAV: BitArray(1 downto 0);
  signal S_RRESP: ErrorArray(1 downto 0);


begin

    M_RADDR(0) <= M1_RADDR;
    M_RADDR(1) <= M2_RADDR;
    M_RAVALID(0) <= M1_RAVALID;
    M_RAVALID(1) <= M2_RAVALID;
    M1_RDATA <= M_RDATA(0);
    M2_RDATA <= M_RDATA(1);
    M1_RDATAV <= M_RDATAV(0);
    M2_RDATAV <= M_RDATAV(1);
    M1_RRESP <= M_RRESP(0);
    M2_RRESP <= M_RRESP(1);

    S1_RADDR <= S_RADDR(0);
    S2_RADDR <= S_RADDR(1);
    S1_RAVALID <= S_RAVALID(0);
    S2_RAVALID <= S_RAVALID(1);
    S_RDATA(0) <= S1_RDATA;
    S_RDATA(1) <= S2_RDATA;
    S_RDATAV(0) <= S1_RDATAV;
    S_RDATAV(1) <= S2_RDATAV;
    S_RRESP(0) <= S1_RRESP;
    S_RRESP(1) <= S2_RRESP;


    RI: readInterconnector
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

            M_RADDR => M_RADDR,
            M_RAVALID => M_RAVALID,
            M_RDATA => M_RDATA,
            M_RDATAV => M_RDATAV,
            M_RRESP => M_RRESP,

            S_RADDR => S_RADDR,
            S_RAVALID => S_RAVALID,
            S_RDATA => S_RDATA,
            S_RDATAV => S_RDATAV,
            S_RRESP => S_RRESP
        );

end architecture a;

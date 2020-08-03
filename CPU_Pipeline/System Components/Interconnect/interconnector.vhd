library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types_definitions.all;

entity interconnector is
    port (
        reset: in std_logic;
        clk: in std_logic;


        M_RADDR: in WordArray(numOfMasters-1 downto 0);
        M_RAVALID: in BitArray(numOfMasters-1 downto 0);
        M_RDATA: out WordArray(numOfMasters-1 downto 0);
        M_RDATAV: out BitArray(numOfMasters-1 downto 0);
        M_RRESP: out ErrorArray(numOfMasters-1 downto 0);

        M_WADDR: in WordArray(numOfMasters-1 downto 0);
        M_WAVALID: in BitArray(numOfMasters-1 downto 0);
        M_WDATA: in WordArray(numOfMasters-1 downto 0);
        M_WDATAV: in BitArray(numOfMasters-1 downto 0);
        M_WRESP: out ErrorArray(numOfMasters-1 downto 0);
        M_WRESPV: out BitArray(numOfMasters-1 downto 0);


        S_RADDR: out WordArray(numOfSlaves-1 downto 0);
        S_RAVALID: out BitArray(numOfSlaves-1 downto 0);
        S_RDATA: in WordArray(numOfSlaves-1 downto 0);
        S_RDATAV: in BitArray(numOfSlaves-1 downto 0);
        S_RRESP: in ErrorArray(numOfSlaves-1 downto 0);

        S_WADDR: out WordArray(numOfSlaves-1 downto 0);
        S_WAVALID: out BitArray(numOfSlaves-1 downto 0);
        S_WDATA: out WordArray(numOfSlaves-1 downto 0);
        S_WDATAV: out BitArray(numOfSlaves-1 downto 0);
        S_WRESP: in ErrorArray(numOfSlaves-1 downto 0);
        S_WRESPV: in BitArray(numOfSlaves-1 downto 0)
    );
end entity interconnector;

architecture a of interconnector is
    component writeInterconnector is
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

    component readInterconnector is
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

    signal clk: std_logic;
    signal reset: std_logic;

    signal M_RADDR: WordArray(numOfMasters-1 downto 0);
    signal M_RAVALID: BitArray(numOfMasters-1 downto 0);
    signal M_RDATA: WordArray(numOfMasters-1 downto 0);
    signal M_RDATAV: BitArray(numOfMasters-1 downto 0);
    signal M_RRESP: ErrorArray(numOfMasters-1 downto 0);

    signal M_WADDR: WordArray(numOfMasters-1 downto 0);
    signal M_WAVALID: BitArray(numOfMasters-1 downto 0);
    signal M_WDATA: WordArray(numOfMasters-1 downto 0);
    signal M_WDATAV: BitArray(numOfMasters-1 downto 0);
    signal M_WRESP: ErrorArray(numOfMasters-1 downto 0);
    signal M_WRESPV: BitArray(numOfMasters-1 downto 0);


    signal S_RADDR: WordArray(numOfSlaves-1 downto 0);
    signal S_RAVALID: BitArray(numOfSlaves-1 downto 0);
    signal S_RDATA: WordArray(numOfSlaves-1 downto 0);
    signal S_RDATAV: BitArray(numOfSlaves-1 downto 0);
    signal S_RRESP: ErrorArray(numOfSlaves-1 downto 0);

    signal S_WADDR: WordArray(numOfSlaves-1 downto 0);
    signal S_WAVALID: BitArray(numOfSlaves-1 downto 0);
    signal S_WDATA: WordArray(numOfSlaves-1 downto 0);
    signal S_WDATAV: BitArray(numOfSlaves-1 downto 0);
    signal S_WRESP: ErrorArray(numOfSlaves-1 downto 0);
    signal S_WRESPV: BitArray(numOfSlaves-1 downto 0)

begin

    WRITE_INTERCONNECTOR: writeInterconnector
    port map (
        clk => clk,
        reset => reset,

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

    READ_INTERCONNECTOR: readInterconnector
    port map (
        clk => clk,
        reset => reset,

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

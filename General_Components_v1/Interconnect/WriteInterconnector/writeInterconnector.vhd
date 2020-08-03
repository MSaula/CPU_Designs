library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types_definitions.all;

entity writeInterconnector is
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
end entity writeInterconnector;

architecture a of writeInterconnector is

    constant fifoSize: integer := numOfMasters + addrSize + dataSize + 2;

    component wfifo is
        generic (
            capacity: integer := numOfMasters;
            size: integer := fifoSize
        );
        port (
            reset: in std_logic;
            pop: in std_logic;

            Data: in WFIFOA(capacity-1 downto 0);
            load: in BitArray(capacity-1 downto 0);

            Q: out std_logic_vector(size-1 downto 0)
        );
    end component wfifo;

    type IDContainer is array (numOfSlaves-1 downto 0) of std_logic_vector(numOfMasters-1 downto 0);
    type BitMatrix is array (numOfSlaves-1 downto 0) of BitArray(numOfMasters-1 downto 0);

    signal CSM: BitMatrix;
    signal DataInAux: WFIFOA(numOfMasters-1 downto 0);
    signal DataOutAux: WFIFOA(numOfSlaves-1 downto 0);
    signal IDfromMinS: IDContainer;

begin

    fifoGeneration: for i in numOfSlaves-1 downto 0 generate
        fifoS: wfifo
        generic map (
            capacity => numOfMasters,
            size => fifoSize
        )
        port map (
            reset => reset,
            pop => S_WRESPV(i),
            Data => DataInAux,
            load => CSM(i),
            Q => DataOutAux(i)
        );
    end generate;

    DataInAuxUpdate: process (M_WADDR, M_WAVALID, M_WDATA, M_WDATAV)
        variable IDin: std_logic_vector(numOfMasters-1 downto 0);
    begin
        for i in numOfMasters-1 downto 0 loop
            for j in numOfMasters-1 downto 0 loop
                if (i = j) then
                    IDin(j) := '1';
                else
                    IDin(j) := '0';
                end if;
            end loop;
            DataInAux(i)((numOfMasters + addrSize + dataSize + 2)-1 downto (addrSize + dataSize + 2)) <= IDin;
            DataInAux(i)((addrSize + dataSize + 2)-1 downto (dataSize + 2)) <= M_WADDR(i);
            DataInAux(i)((dataSize + 2)-1 downto 2) <= M_WDATA(i);
            DataInAux(i)(1) <= M_WAVALID(i);
            DataInAux(i)(0) <= M_WDATAV(i);
        end loop;
    end process;

    DataOutAuxUpdate: process (DataOutAux, clk)
    begin
        for i in numOfSlaves-1 downto 0 loop
            IDfromMinS(i) <= DataOutAux(i)((numOfMasters + addrSize + dataSize + 2)-1 downto (addrSize + dataSize + 2));
            S_WADDR(i) <= DataOutAux(i)((addrSize + dataSize + 2)-1 downto (dataSize + 2));
            S_WDATA(i) <= DataOutAux(i)((dataSize + 2)-1 downto 2);

            if (clk'event and DataOutAux(i)(1) = '1') then
              S_WAVALID(i) <= '1';
            elsif (DataOutAux(i)(1) = '0') then
              S_WAVALID(i) <= '0';
            end if;

            if (clk'event and DataOutAux(i)(0) = '1') then
              S_WDATAV(i) <= '1';
            elsif ((DataOutAux(i)(0) = '0')) then
              S_WDATAV(i) <= '0';
            end if;

        end loop;
    end process;

    ADFS_Read: process (M_WAVALID, M_WDATAV, reset)
        variable aux: integer := 0;
    begin
        if (reset = '1') then
            for i in numOfMasters-1 downto 0 loop
                for j in numOfMasters-1 downto 0 loop
                    CSM(j)(i) <= '0';
                end loop;
            end loop;
        else
            for i in numOfMasters-1 downto 0 loop
                if (M_WAVALID(i) = '1' and M_WDATAV(i) = '1') then
                    if (not (to_integer(unsigned(M_WADDR(i))) > (numOfSlaves * slotSize))) then
                        csAssignment: for j in 0 to numOfSlaves-1 loop
                            if (to_integer(unsigned(M_WADDR(i))) < ((j+1)*slotSize) and to_integer(unsigned(M_WADDR(i))) > ((j)*slotSize)) then
                                CSM(j)(i) <= '1';
                            end if;
                        end loop;
                    end if;
                elsif (M_WAVALID(i) = '0' or M_WDATAV(i) = '0') then
                    for j in numOfSlaves-1 downto 0 loop
                        CSM(j)(i) <= '0';
                    end loop;
                end if;
            end loop;
        end if;
    end process;

    ToMasterData: process (S_WRESP, S_WRESPV, M_WADDR, M_WAVALID, M_WDATA, M_WDATAV, reset, clk)
        variable IDin: std_logic_vector(numOfMasters-1 downto 0);
    begin
        for i in numOfMasters-1 downto 0 loop
          if (reset = '1') then
            M_WRESP(i) <= (others => '0');
            M_WRESPV(i) <= '0';
        elsif (abs(to_integer(unsigned(M_WADDR(i)))) >= (numOfSlaves * slotSize)) then
            M_WRESP(i) <= respErrorValue;
            if (M_WAVALID(i) = '1' and M_WDATAV(i) = '1') then
              M_WRESPV(i) <= '1';
            else
              M_WRESPV(i) <= '0';
            end if;
        elsif (M_WAVALID(i) = '0' or M_WDATAV(i) = '0') then
            M_WRESP(i) <= (others => '0');
            M_WRESPV(i) <= '0';
          else
            for j in numOfMasters-1 downto 0 loop
              if (i = j) then
                IDin(j) := '1';
              else
                IDin(j) := '0';
              end if;
            end loop;
            for j in numOfSlaves-1 downto 0 loop
              if (IDin = IDfromMinS(j)) then
                M_WRESPV(i) <= S_WRESPV(j);
                if (clk'event) then
                  M_WRESP(i)  <= S_WRESP(j);
                end if;
              end if;
            end loop;
          end if;
        end loop;
    end process;
end architecture a;

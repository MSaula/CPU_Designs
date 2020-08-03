library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types_definitions.all;

entity readInterconnector is
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
end entity readInterconnector;

architecture a of readInterconnector is

    component rfifo is
        generic (
            capacity: integer := numOfMasters;
            size: integer := (numOfMasters + addrSize + 1)
        );
        port (
            reset: in std_logic;
            pop: in std_logic;

            Data: in RFIFOA(capacity-1 downto 0);
            load: in BitArray(capacity-1 downto 0);

            Q: out std_logic_vector(size-1 downto 0)
        );
    end component rfifo;

    type IDContainer is array (numOfSlaves-1 downto 0) of std_logic_vector(numOfMasters-1 downto 0);
    type BitMatrix is array (numOfSlaves-1 downto 0) of BitArray(numOfMasters-1 downto 0);

    signal CSM: BitMatrix;
    signal DataInAux: RFIFOA(numOfMasters-1 downto 0);
    signal DataOutAux: RFIFOA(numOfSlaves-1 downto 0);
    signal IDfromMinS: IDContainer;

    signal debugg1: integer;
    signal debugg2: integer;

begin

    fifoGeneration: for i in numOfSlaves-1 downto 0 generate
        fifoS: rfifo
        generic map (
            capacity => numOfMasters,
            size => (numOfMasters + addrSize + 1)
        )
        port map (
            reset => reset,
            pop => S_RDATAV(i),
            Data => DataInAux,
            load => CSM(i),
            Q => DataOutAux(i)
        );
    end generate;

    DataInAuxUpdate: process (M_RADDR, M_RAVALID)
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
            DataInAux(i)((numOfMasters + addrSize + 1)-1 downto (addrSize + 1)) <= IDin;
            DataInAux(i)((addrSize + 1)-1 downto 1) <= M_RADDR(i);
            DataInAux(i)(0) <= M_RAVALID(i);
        end loop;
    end process;

    DataOutAuxUpdate: process (DataOutAux, clk)
    begin
        for i in numOfSlaves-1 downto 0 loop
            S_RADDR(i) <= DataOutAux(i)((addrSize + 1)-1 downto 1);
            IDfromMinS(i) <= DataOutAux(i)((numOfMasters + addrSize + 1)-1 downto (addrSize + 1));
            if (clk'event and DataOutAux(i)(0) = '1') then
              S_RAVALID(i) <= '1';
          elsif (DataOutAux(i)(0) = '0') then
              S_RAVALID(i) <= '0';
            end if;
        end loop;
    end process;

    ADFS_Read: process (M_RAVALID, reset)
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
                if (M_RAVALID(i) = '1') then
                    if (not (to_integer(unsigned(M_RADDR(i))) > (numOfSlaves * slotSize))) then
                        csAssignment: for j in 0 to numOfSlaves-1 loop
                            if (to_integer(unsigned(M_RADDR(i))) < ((j+1)*slotSize) and to_integer(unsigned(M_RADDR(i))) > ((j)*slotSize)) then
                                CSM(j)(i) <= '1';
                            end if;
                        end loop;
                    end if;
                elsif (M_RAVALID(i) = '0') then
                    for j in numOfSlaves-1 downto 0 loop
                        CSM(j)(i) <= '0';
                    end loop;
                end if;
            end loop;
        end if;
    end process;

    ToMasterData: process (S_RDATA, S_RDATAV, S_RRESP, M_RADDR, M_RAVALID, reset)
        variable IDin: std_logic_vector(numOfMasters-1 downto 0);
    begin
        debugg1 <= to_integer(unsigned(M_RADDR(1)));
        debugg2 <= to_integer(unsigned(M_RADDR(0)));

        for i in numOfMasters-1 downto 0 loop
          if (reset = '1') then
            M_RRESP(i) <= (others => '0');
            M_RDATA(i) <= (others => '0');
            M_RDATAV(i) <= '0';
          elsif (abs(to_integer(unsigned(M_RADDR(i)))) >= (numOfSlaves * slotSize)) then
            M_RRESP(i) <= respErrorValue;
            M_RDATA(i) <= (others => '0');
            if (M_RAVALID(i) = '1') then
              M_RDATAV(i) <= '1';
            else
              M_RDATAV(i) <= '0';
            end if;
          elsif (M_RAVALID(i) = '0') then
            M_RRESP(i) <= (others => '0');
            M_RDATA(i) <= (others => '0');
            M_RDATAV(i) <= '0';
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
                M_RDATA(i)  <= S_RDATA(j);
                M_RDATAV(i) <= S_RDATAV(j);
                M_RRESP(i)  <= S_RRESP(j);
              end if;
            end loop;
          end if;
        end loop;
    end process;
end architecture a;

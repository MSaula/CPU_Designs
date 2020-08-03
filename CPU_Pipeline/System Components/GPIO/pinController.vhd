library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- TODO: Actualment el sistema petaria si s'intenta llegir i escriure en el bloc
-- a la vegada. De moment de suposa que el programador ho tindrÃ  en compte i farÃ 
-- un bon Ãºs del mÃ²dul. PerÃ² en un futur seria interessant solucionar aquest problema.
entity pinController is
    generic (
        pinsPerBlock: integer := 8;
        addrSize : integer := 32;
        dataSize : integer := 32;
        respSize : integer := 2;

        -- La baseAddress Ã©s l'adreÃ§a en la que inicia el bloc de memoria visrtual
        -- de la GPIO dins el sistema. Llavors les adrÃ§es que accepta el bloc sÃ³n:
        --  - LAT -> baseAddress + addressValue
        --  - TRIS -> baseAddress + totalSingleSize + addressValue
        --  - PORT -> baseAddress + 2 * totalSingleSize + addressValue
        baseAddress: integer := 0;
        addressValue: integer := 0;
        totalSingleSize: integer := 32;

        isOW: std_logic := '0';
        isOR: std_logic := '0'
    );
    port (
        pin: inout std_logic_vector(pinsPerBlock-1 downto 0);

        WADDR: in std_logic_vector(addrSize-1 downto 0);
        WAVALID: in std_logic;
        WDATA: in std_logic_vector(dataSize-1 downto 0);
        WDATAV: in std_logic;
        WCOMPLETE: out std_logic;

        RADDR: in std_logic_vector(addrSize-1 downto 0);
        RAVALID: in std_logic;
        RDATA: out std_logic_vector(dataSize-1 downto 0);
        RDATAV: out std_logic;

        clk: in std_logic;
        reset: in std_logic
    );
end entity pinController;

architecture a of pinController is

    component IOManager is
        generic (
            size: integer := 8;
            isOW: std_logic := '0';
            isOR: std_logic := '0'
        );
        port (
            pin: inout std_logic_vector(size-1 downto 0);

            data: inout std_logic_vector(size-1 downto 0);

            WRLAT:  in std_logic;
            RDLAT:  in std_logic;
            WRTRIS: in std_logic;
            RDTRIS: in std_logic;
            RDPORT: in std_logic;

            reset: in std_logic
        );
    end component IOManager;

    type state is (E0, E1);
    signal current_state    : state;
    signal next_state       : state;

    signal data: std_logic_vector(pinsPerBlock-1 downto 0);
    signal WRLAT:  std_logic;
    signal RDLAT:  std_logic;
    signal WRTRIS: std_logic;
    signal RDTRIS: std_logic;
    signal RDPORT: std_logic;

    signal RDATAVAux: std_logic;

    signal wantsToWriteLAT: boolean;
    signal wantsToWriteTRIS: boolean;
    signal wantsToWrite: boolean;

    signal wantsToReadLAT: boolean;
    signal wantsToReadTRIS: boolean;
    signal wantsToReadPORT: boolean;
    signal wantsToRead: boolean;

begin

    PinC: IOManager
    generic map (
        size => pinsPerBlock,
        isOW => isOW,
        isOR => isOR
    )
    port map (
        pin => pin,
        data => data,
        WRLAT => WRLAT,
        RDLAT => RDLAT,
        WRTRIS => WRTRIS,
        RDTRIS => RDTRIS,
        RDPORT => RDPORT,
        reset => reset
    );

    wantsToWriteLAT <= (to_integer(unsigned(WADDR)) = (baseAddress + addressValue));
    wantsToWriteTRIS <= (to_integer(unsigned(WADDR)) = (baseAddress + totalSingleSize + addressValue));
    wantsToWrite <= wantsToWriteLAT or wantsToWriteTRIS;

    wantsToReadLAT <= (to_integer(unsigned(RADDR)) = (baseAddress + addressValue));
    wantsToReadTRIS <= (to_integer(unsigned(RADDR)) = (baseAddress + totalSingleSize + addressValue));
    wantsToReadPORT <= (to_integer(unsigned(RADDR)) = (baseAddress + totalSingleSize + 2 * addressValue));
    wantsToRead <= (wantsToReadLAT or wantsToReadTRIS or wantsToReadTRIS);

    RDATA(dataSize-1 downto pinsPerBlock) <= (others => '0') when wantsToRead else (others => 'Z');
    RDATA(pinsPerBlock-1 downto 0) <= data when (wantsToRead) else (others => 'Z');

    RDATAV <= RDATAVAux when (to_integer(unsigned(RADDR)) = (baseAddress + addressValue)) else
        RDATAVAux when (to_integer(unsigned(RADDR)) = (baseAddress + totalSingleSize + addressValue)) else
        RDATAVAux when (to_integer(unsigned(RADDR)) = (baseAddress + 2 * totalSingleSize + addressValue)) else
        'Z';

    data <= WDATA(pinsPerBlock-1 downto 0) when wantsToWrite and not wantsToRead else (others => 'Z');

    p_seq_next_state : process(clk, reset)
    begin
        if(reset = '1') then
            current_state <= E0;
        elsif(clk = '1' and clk'event) then
            current_state <= next_state;
        end if;
    end process p_seq_next_state;

    p_comb_state : process(WAVALID, WDATAV, RAVALID, clk)
    begin
        case current_state is
            when E0 =>
                if ((WAVALID = '1' and WDATAV = '1') or RAVALID = '1') then
                    next_state <= E1;
                else
                    next_state <= E0;
                end if;
            when E1 =>
                if ((WAVALID = '0' and WDATAV = '0') and RAVALID = '0') then
                  next_state <= E0;
                end if;
            when others =>
                next_state <= E0;
        end case;
    end process p_comb_state;

    p_seq_output: process (current_state, reset, clk, WADDR)
    begin
        if reset'event and reset = '1' then
            WRLAT <= '0';
            RDLAT <= '0';
            WRTRIS <= '0';
            RDTRIS <= '0';
            RDPORT <= '0';
        else
            case current_state is
                when E0 =>
                    WRLAT <= '0';
                    RDLAT <= '0';
                    WRTRIS <= '0';
                    RDTRIS <= '0';
                    RDPORT <= '0';
                when E1 =>
                    if (wantsToWriteLAT) and (WAVALID = '1' and WDATAV = '1') then
                        WRLAT <= '1';
                    elsif (wantsToReadLAT) and RAVALID = '1' then
                      	RDLAT <= '1';
				  	         elsif (wantsToWriteTRIS) and (WAVALID = '1' and WDATAV = '1') then
					  	          WRTRIS <= '1';
				            elsif (wantsToReadTRIS) and RAVALID = '1' then
                        RDTRIS <= '1';
					          elsif (wantsToReadPORT) and RAVALID = '1' then
                        RDPORT <= '1';
                    else
                        WRLAT <= '0';
						            RDLAT <= '0';
						            WRTRIS <= '0';
						            RDTRIS <= '0';
						            RDPORT <= '0';
                    end if;
            end case;
        end if;
    end process;

    WCOMPLETEUpdate: process (WAVALID, WDATAV, WRTRIS, WRLAT, clk)
    begin
      if (WAVALID = '1' and WDATAV = '1' and (WRTRIS = '1' or WRLAT = '1')) then
        if (clk'event and clk = '0') then
          WCOMPLETE <= '1';
        end if;
      else
        WCOMPLETE <= '0';
      end if;
    end process;

    READCOMPLETEUpdate: process (RAVALID, RDTRIS, RDLAT, RDPORT, clk)
    begin
      if (RAVALID = '1' and (RDTRIS = '1' or RDLAT = '1' or RDPORT = '1')) then
        if (clk'event and clk = '0') then
          RDATAVAux <= '1';
        end if;
      else
        RDATAVAux <= '0';
      end if;
    end process;

end architecture a;

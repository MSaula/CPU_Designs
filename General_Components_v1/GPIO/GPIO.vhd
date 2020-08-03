library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.gpio_configuration.all;

entity gpio is
    generic (
        -- Dimensionat de busos
        pinsPerBlock: integer := PinsPerBloc;
        busAddrSize : integer := addrSize;
        busDataSize : integer := dataSize;
        respSize : integer := 2;

        -- Estructura de la GPIO
        baseAddress: integer := 0;
        totalSingleSize: integer := 32;
        totalComponents: integer := 22;

        -- Defineix la quantitat de components de nomÃ©s lectura o nomÃ©s escriptura.
        -- La organitzaciÃ³ serÃ  de que les OR anirÃ n al primer rang d'addr, les OW
        -- al segon i les bidireccionals al
        ORComponents: integer := 2;
        OWComponents: integer := 8
    );
    port (
        -- Pinout del sistema
        pin: inout std_logic_vector((totalComponents*PinsPerBloc)-1 downto 0);--Pinout(totalComponents-1 downto 0);

        -- Bus d'escriptura del sistema
        WADDR: in std_logic_vector(addrSize-1 downto 0);
        WAVALID: in std_logic;
        WDATA: in std_logic_vector(dataSize-1 downto 0);
        WDATAV: in std_logic;
        WRESP: out std_logic_vector(respSize-1 downto 0);
        WRESPV: out std_logic;

        -- Bus de lectura del sistema
        RADDR: in std_logic_vector(addrSize-1 downto 0);
        RAVALID: in std_logic;
        RDATA: out std_logic_vector(dataSize-1 downto 0);
        RDATAV: out std_logic;
        RRESP: out std_logic_vector(respSize-1 downto 0);

        clk: in std_logic;
        reset: in std_logic
    );
end entity gpio;

architecture a of gpio is

    component pinController is
        generic (
            pinsPerBlock: integer := 8;
            addrSize : integer := 32;
            dataSize : integer := 32;
            respSize : integer := 2;

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
    end component pinController;

    type ControlSignals is array (totalComponents-1 downto 0) of std_logic;

    signal WOK: ControlSignals;
    signal RNoValid: Boolean;
    signal WNoValid: Boolean;

    signal RDATAV1: std_logic;
    signal RDATAV2: std_logic;

begin

    RDATAV <= RDATAV1 or RDATAV2;

    outBlocks: for i in 0 to totalComponents-1 generate
      ORBlocs: if (i < ORComponents) generate
        pbcor: pinController
        generic map (
          pinsPerBlock => pinsPerBlock,
          addrSize => addrSize,
          dataSize => dataSize,
          respSize => respSize,

          baseAddress => baseAddress,
          addressValue => i,
          totalSingleSize => totalSingleSize,

          isOW => '0',
          isOR => '1'
        )
        port map (
          pin => pin((PinsPerBloc*(i+1))-1 downto (PinsPerBloc*i)),

          WADDR => WADDR,
          WAVALID => WAVALID,
          WDATA => WDATA,
          WDATAV => WDATAV,
          WCOMPLETE => WOK(i),

          RADDR => RADDR,
          RAVALID => RAVALID,
          RDATA => RDATA,
          RDATAV => RDATAV1,

                clk => clk,
                reset => reset
            );
        end generate ORBlocs;
        OWBlocs: if (i < (OWComponents + ORComponents) and i >= ORComponents) generate
            pbcow: pinController
            generic map (
                pinsPerBlock => pinsPerBlock,
                addrSize => addrSize,
                dataSize => dataSize,
                respSize => respSize,

                baseAddress => baseAddress,
                addressValue => i,
                totalSingleSize => totalSingleSize,

                isOW => '1',
                isOR => '0'
            )
            port map (
                pin => pin((PinsPerBloc*(i+1))-1 downto (PinsPerBloc*i)),

                WADDR => WADDR,
                WAVALID => WAVALID,
                WDATA => WDATA,
                WDATAV => WDATAV,
                WCOMPLETE => WOK(i),

                RADDR => RADDR,
                RAVALID => RAVALID,
                RDATA => RDATA,
                RDATAV => RDATAV1,

                clk => clk,
                reset => reset
            );
        end generate OWBlocs;
        BIBlocs: if (i >= (ORComponents + OWComponents)) generate
            pbcbi: pinController
            generic map (
                pinsPerBlock => pinsPerBlock,
                addrSize => addrSize,
                dataSize => dataSize,
                respSize => respSize,

                baseAddress => baseAddress,
                addressValue => i,
                totalSingleSize => totalSingleSize,

                isOW => '0',
                isOR => '0'
            )
            port map (
                pin => pin((PinsPerBloc*(i+1))-1 downto (PinsPerBloc*i)),

                WADDR => WADDR,
                WAVALID => WAVALID,
                WDATA => WDATA,
                WDATAV => WDATAV,
                WCOMPLETE => WOK(i),

                RADDR => RADDR,
                RAVALID => RAVALID,
                RDATA => RDATA,
                RDATAV => RDATAV1,

                clk => clk,
                reset => reset
            );
        end generate BIBlocs;
    end generate;

    RNoValid <=
      (to_integer(unsigned(RADDR)) < baseAddress) or
		      ((to_integer(unsigned(RADDR)) < (baseAddress + totalSingleSize)) and
		      	  (to_integer(unsigned(RADDR)) > (baseAddress + totalComponents))) or
		      ((to_integer(unsigned(RADDR)) < (baseAddress + 2 * totalSingleSize)) and
		          (to_integer(unsigned(RADDR)) > (baseAddress + totalSingleSize + totalComponents))) or
		      (to_integer(unsigned(RADDR)) > (baseAddress + 2 * totalSingleSize + totalComponents));
    WNoValid <=
      (to_integer(unsigned(WADDR)) < baseAddress) or
      ((to_integer(unsigned(WADDR)) < (baseAddress + totalSingleSize)) and
          (to_integer(unsigned(WADDR)) > (baseAddress + totalComponents))) or
      ((to_integer(unsigned(WADDR)) > (baseAddress + totalSingleSize + totalComponents)));

    RRESP <= "01" when RNoValid else "00";
    WRESP <= "01" when WNoValid else "00";

     WOKA: process (WOK, clk)
        variable aux: std_logic;
     begin
         aux := '0';
         for i in totalComponents-1 downto 0 loop
             if (WOK(i) = '1') then
                 aux := '1';
             end if;
         end loop;
         if (WNoValid and clk'event and WAVALID = '1' and WDATAV = '1') then
              aux := '1';
         end if;
         WRESPV <= aux;
     end process;

    RRESPERROR: process (clk)
    begin
      if (RNoValid and RAVALID = '1') then
        RDATAV2 <= '1';
      else
        RDATAV2 <= '0';
      end if;
    end process;

end architecture a;

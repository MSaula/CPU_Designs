Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity memory is
    generic (
        base_addr: integer := 0;
        lenght: integer := 1024;
        addr_size: integer := 32;
        data_size: integer := 32;
        size : integer := 8
    );
    port (
        reset: in std_logic;

        RADDR: in std_logic_vector(addr_size-1 downto 0);
        RAVALID: in std_logic;
        RDATA: out std_logic_vector(data_size-1 downto 0);
        RDATAV: out std_logic;
        RRESP: out std_logic_vector(1 downto 0);

        WADDR: in std_logic_vector(addr_size-1 downto 0);
        WAVALID: in std_logic;
        WDATA: in std_logic_vector(data_size-1 downto 0);
        WDATAV: in std_logic;
        WRESP: out std_logic_vector(1 downto 0);
        WRESPV: out std_logic
	);
end memory;

architecture a of memory is

    type STORAGE is array (lenght-1 downto 0) of std_logic_vector(size-1 downto 0);

    constant bytesPerWord: integer := data_size / size;

    signal rerror: std_logic;
    signal werror: std_logic;

    signal Memory: STORAGE := (others => (others => '0'));

begin

    rerror <= '1' when to_integer(unsigned(RADDR)) < (base_addr) or to_integer(unsigned(RADDR)) > (base_addr + lenght) else '0';
    werror <= '1' when to_integer(unsigned(WADDR)) < (base_addr) or to_integer(unsigned(WADDR)) > (base_addr + lenght) else '0';

    RRESP <= "01" when rerror = '1' else "00";
    WRESP <= "01" when werror = '1' else "00";

    RDATAV <= RAVALID;

    writeMemory: process(WAVALID, WDATAV)
    begin
        if ((WAVALID'event or WDATAV'event) and WAVALID = '1' and WDATAV = '1') then
            if (werror = '0') then
                for i in bytesPerWord-1 downto 0 loop
                    Memory(to_integer(unsigned(WADDR + i - base_addr))) <= WDATA(size*(i+1)-1 downto (size*i));
                end loop;
            end if;
            WRESPV <= '1';
        elsif (WAVALID = '0' or WDATAV = '0') then
            WRESPV <= '0';
        end if;
    end process;

    updateRDATA: process(RADDR)
    begin
        if (to_integer(unsigned(RADDR)) < (base_addr) or to_integer(unsigned(RADDR)) > (base_addr + lenght)) then
            RDATA <= (others => '0');
        else
            for i in bytesPerWord-1 downto 0 loop
                RDATA((i+1)*size-1 downto i*size) <= Memory(to_integer(unsigned(RADDR)) + i - base_addr);
            end loop;
        end if;
    end process;

end a;

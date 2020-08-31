--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity fpu is
    generic (
        -- System
        SX: integer:= 17;

        -- Instruction
        IO: integer:= 4;
        IX: integer:= 2;
        IY: integer:= 11;

        -- Floating Point
        FD: integer:= 32;
        FM: integer:= 23;
        FE: integer:= 8
    );
    port (
        clk: in std_logic;
        reset: in std_logic;
        exe_stall: in std_logic;

        InstructionToExecute: in std_logic_vector(SX-1 downto 0);

        A: in std_logic_vector(FD-1 downto 0);
        B: in std_logic_vector(FD-1 downto 0);

        C: out std_logic_vector(FD-1 downto 0);

        FPUNotReady: out std_logic;
        freshValue: in std_logic
	);
end fpu;

architecture a of fpu is

    component fp_multiplier is
        generic (
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8
        );
        port (
            A: in std_logic_vector(FD-1 downto 0);
            B: in std_logic_vector(FD-1 downto 0);

            C: out std_logic_vector(FD-1 downto 0)
    	);
    end component;

    component fp_adder is
        generic (
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8
        );
        port (
            A: in std_logic_vector(FD-1 downto 0);
            B: in std_logic_vector(FD-1 downto 0);

            C: out std_logic_vector(FD-1 downto 0)
    	);
    end component;

    component fp_divider is
        generic (
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8
        );
        port (
            Nin: in std_logic_vector(FD-1 downto 0);
            Din: in std_logic_vector(FD-1 downto 0);

            start: in std_logic;
            clk: in std_logic;


            Q: out std_logic_vector(FD-1 downto 0);

            ended: out std_logic
    	);
    end component;

    component int2fp is
        generic (
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8
        );
        port (
            input: in std_logic_vector(FD-1 downto 0);
            output: out std_logic_vector(FD-1 downto 0)
    	);
    end component;

    component fp2int is
        generic (
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8
        );
        port (
            input: in std_logic_vector(FD-1 downto 0);
            output: out std_logic_vector(FD-1 downto 0)
    	);
    end component;

    type state is (E0, E1);
    signal current_state    : state;
    signal next_state       : state;

    signal mult: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal add: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal sub: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal div: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal fp2int_out: std_logic_vector(FD-1 downto 0) := (others => '0');
    signal int2fp_out: std_logic_vector(FD-1 downto 0) := (others => '0');

    signal B_neg: std_logic_vector(FD-1 downto 0) := (others => '0');

    signal AgtB: std_logic := '0';

    signal divisionEnded: std_logic := '0';
    signal startShot: std_logic := '0';

    signal isAdd: boolean;
    signal isSub: boolean;
    signal isMul: boolean;
    signal isDiv: boolean;
    signal isCmp: boolean;
    signal isF2I: boolean;
    signal isI2F: boolean;
    
    signal full: boolean;

begin

    --startShot <= startShotAux;

    B_neg(FD-1) <= not B(FD-1);
    B_neg(FD-2 downto 0) <= B(FD-2 downto 0);

    AgtB <= '1' when ((A(FD-1) = '0') and (B(FD-1) = '1')) or
        ((A(FD-1) = B(FD-1)) and (A(FD-2 downto 0) > B(FD-2 downto 0)))
        else '0';

    isAdd <= InstructionToExecute(IO-1 downto 0) = "0000" and InstructionToExecute((IO+IX-1) downto IO) = "10" and InstructionToExecute((IO+IX+IY-1) downto (IO+IX)) = "00000000000";
    isSub <= InstructionToExecute(IO-1 downto 0) = "0000" and InstructionToExecute((IO+IX-1) downto IO) = "10" and InstructionToExecute((IO+IX+IY-1) downto (IO+IX)) = "00000000001";
    isMul <= InstructionToExecute(IO-1 downto 0) = "0000" and InstructionToExecute((IO+IX-1) downto IO) = "10" and InstructionToExecute((IO+IX+IY-1) downto (IO+IX)) = "00000000010";
    isDiv <= InstructionToExecute(IO-1 downto 0) = "0000" and InstructionToExecute((IO+IX-1) downto IO) = "10" and InstructionToExecute((IO+IX+IY-1) downto (IO+IX)) = "00000000011";
    isCmp <= InstructionToExecute(IO-1 downto 0) = "0101" and InstructionToExecute((IO+IX-1) downto IO) = "10" and InstructionToExecute((IO+IX+IY-1) downto (IO+IX)) = "00000000001";
    isI2F <= InstructionToExecute(IO-1 downto 0) = "0100" and InstructionToExecute((IO+IX-1) downto IO) = "01";
    isF2I <= InstructionToExecute(IO-1 downto 0) = "0100" and InstructionToExecute((IO+IX-1) downto IO) = "00";

    C <= (others => AgtB) when isCmp else
        add  when isAdd else
        sub  when isSub else
        mult when isMul else
        div  when isDiv else
        fp2int_out when isF2I else
        int2fp_out when isI2F else
        (others => '0');

    multiplier: fp_multiplier
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        A => A,
        B => B,

        C => mult
    );

    adder: fp_adder
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        A => A,
        B => B,

        C => add
    );

    substractor: fp_adder
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        A => A,
        B => B_neg,

        C => sub
    );

    divider: fp_divider
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        Nin => A,
        Din => B,
        start => startShot,
        clk => clk,
        Q => div,
        ended => divisionEnded
    );

    FP2I: fp2int
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        input => A,
        output => fp2int_out
    );

    I2FP: int2fp
    generic map (
        FD => FD,
        FM => FM,
        FE => FE
    )
    port map (
        input => A,
        output => int2fp_out
    );

    p_seq_next_state : process(clk, reset)
    begin
      if(reset = '1') then
        current_state <= E0;
      elsif(clk = '1' and clk'event) then
        current_state <= next_state;
      end if;
    end process p_seq_next_state;

    p_comb_state : process(current_state, isDiv, divisionEnded)
    begin
      case current_state is
        when E0 =>
            if (isDiv and freshValue = '1') then next_state <= E1; end if;
       	when E1 =>
    		      if divisionEnded = '1' then
                next_state <= E0;
            end if;
        when others =>
            next_state <= E0;
      end case;
    end process p_comb_state;

    p_seq_output: process (current_state, freshValue, reset, isDiv, divisionEnded)
    begin
      if reset = '1' then
          startShot <= '0';
          FPUNotReady <= '0';
      else
        case current_state is
            when E0 =>
                if isDiv and freshValue = '1' then
                    startShot <= '1';
                    FPUNotReady <= '1';
                else
                    startShot <= '0';
                    FPUNotReady <= '0';
                end if;
    		  when others =>
          startShot <= '0';
          FPUNotReady <= not DivisionEnded;
    	   end case;
      end if;
    end process p_seq_output;
    
end a;

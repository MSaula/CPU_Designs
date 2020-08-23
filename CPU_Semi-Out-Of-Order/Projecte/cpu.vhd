--------------------------------------------
-- Author:            Miquel Saula
-- Last modification: 3/08/2020
--------------------------------------------

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

entity cpu is
    generic (
        -- Bus
        BA: integer:= 32;
        BD: integer:= 32;
        BE: integer:= 2;

        -- System
        SA: integer:= 32;
        SB: integer:= 5;
        SD: integer:= 32;
        SI: integer:= 32;
        SX: integer:= 17;

        -- Instruction
        IB: integer:= 5;
        IO: integer:= 4;
        IX: integer:= 2;
        IY: integer:= 11;
        IJ: integer:= 26;

        -- Floating Point
        FD: integer:= 32;
        FM: integer:= 23;
        FE: integer:= 8;

        -- Instruction Cache Memory
        CA: integer:= 0;
        CS: integer:= 1024;

        -- LIFO
        LS: integer := 32;

        -- OOE Bus
        BC: integer := 8
    );
    port (
        clk: in std_logic;
        reset: in std_logic;

        RDATA: in std_logic_vector(BD-1 downto 0);
        RDATAV: in std_logic;
        RADDR: out std_logic_vector(BA-1 downto 0);
        RAVALID: out std_logic;
        RRESP: in std_logic_vector(BE-1 downto 0);

        WDATA: out std_logic_vector(BD-1 downto 0);
        WDATAV: out std_logic;
        WADDR: out std_logic_vector(BA-1 downto 0);
        WAVALID: out std_logic;
        WRESP: in std_logic_vector(BE-1 downto 0);
        WRESPV: in std_logic
   );
end cpu;

architecture a of cpu is

    ------------------------------------------------------------------------
    -------------------------- COMPONENTS ----------------------------------
    ------------------------------------------------------------------------

    component instruction_fetch_module is
        generic (
            -- Bus
            BA: integer:= 32;
            BD: integer:= 32;
            BE: integer:= 2;

            -- System
            SA: integer:= 32;
            SD: integer:= 32;
            SI: integer:= 32
        );
        port (
            clk: in std_logic;
            reset: in std_logic;

            jump: in std_logic;
            ALUOut: in std_logic_vector(SD-1 downto 0);
            IF_Stall: in std_logic;
            MEM_Stall: in std_logic;

            RDATA: in std_logic_vector(BD-1 downto 0);
            RDATAV: in std_logic;
            RRESP: in std_logic_vector(BE-1 downto 0);


            PC: out std_logic_vector(SA-1 downto 0);
            IR: out std_logic_vector(SI-1 downto 0);
            ICDOK: out std_logic;

            RADDR: out std_logic_vector(BA-1 downto 0);
            RAVALID: out std_logic;

            newPC: in std_logic_vector(SA-1 downto 0);
            newI: in std_logic_vector(SI-1 downto 0);
            BPUJump: in std_logic
    	);
    end component;

    component instruction_cache_memory is
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
    end component;

    component instruction_decode_module is
        generic (
            -- System
            SA: integer:= 32;
            SB: integer:= 5;
            SD: integer:= 32;
            SI: integer:= 32;
            SX: integer:= 17;

            -- Instruction
            IB: integer:= 5;
            IO: integer:= 4;
            IX: integer:= 2;
            IY: integer:= 11;
            IJ: integer:= 26
        );
        port (
            clk: in std_logic;
            ID_Stall: in std_logic;

            -- Connexions amb IFM
            IR: in std_logic_vector(SI-1 downto 0);
            PC: in std_logic_vector(SA-1 downto 0);

            -- Connexions amb el WBM
            R1: in std_logic_vector(SD-1 downto 0);
            R2: in std_logic_vector(SD-1 downto 0);

            rs: out std_logic_vector(SB-1 downto 0);
            rt: out std_logic_vector(SB-1 downto 0);
            rd: out std_logic_vector(SB-1 downto 0);

            op: out std_logic_vector(SX-1 downto 0);

            -- Connexions amb el ExeM
            A: out std_logic_vector(SD-1 downto 0);
            B: out std_logic_vector(SD-1 downto 0);
            Af: out std_logic_vector(SD-1 downto 0);
            Bf: out std_logic_vector(SD-1 downto 0);
            InstructionToExecute: out std_logic_vector(SX-1 downto 0);
            RDid: out std_logic_vector(SB-1 downto 0)
    	);
    end component;

    component execution_module is
        generic (
            -- System
            SA: integer:= 32;
            SD: integer:= 32;
            SX: integer:= 17;
            SB: integer:= 5;

            -- Instruction
            IO: integer:= 4;
            IX: integer:= 2;
            IY: integer:= 11;

            -- Floating Point
            FD: integer:= 32;
            FM: integer:= 23;
            FE: integer:= 8;

            BC: integer:= 8
        );
        port (
            clk: in std_logic;
            reset: in std_logic;
            EXE_Stall: in std_logic;

            -- Connexions amb el IDM
            A: in std_logic_vector(SD-1 downto 0);
            B: in std_logic_vector(SD-1 downto 0);
            Af: in std_logic_vector(SD-1 downto 0);
            Bf: in std_logic_vector(SD-1 downto 0);

            InstructionToExecute: in std_logic_vector(SX-1 downto 0);
            RD: in std_logic_vector(SB-1 downto 0);

            BPIDQ: out std_logic_vector(SD-1 downto 0);
            BPIDIFP: out std_logic;
            BPIDNFI: out std_logic;

            BPEXERD: out std_logic_vector(SB-1 downto 0);
            BPEXEIFP: out std_logic;
            BPEXENFI: out std_logic;

            -- Conexions amb el MEM
            InstructionExecuted: out std_logic_vector(SX-1 downto 0);
            ALUOut: out std_logic_vector(SD-1 downto 0);
            SMDR: out std_logic_vector(SD-1 downto 0);
            cond: out std_logic;

            -- Altres connexions
            ALUNotReady: out std_logic;
            ret: out std_logic;
            LIFOout: in std_logic_vector(SD-1 downto 0);

            -- OoOE Bus
            ACK0: in std_logic;
            Q0: out std_logic_vector(FD-1 downto 0);
            RD0: out std_logic_vector(SB-1 downto 0);
            END0: out std_logic;
            IFP0: out std_logic;

            ACK1: in std_logic;
            Q1: out std_logic_vector(FD-1 downto 0);
            RD1: out std_logic_vector(SB-1 downto 0);
            END1: out std_logic;
            IFP1: out std_logic;

            ACK2: in std_logic;
            Q2: out std_logic_vector(FD-1 downto 0);
            RD2: out std_logic_vector(SB-1 downto 0);
            END2: out std_logic;
            IFP2: out std_logic;

            ACK3: in std_logic;
            Q3: out std_logic_vector(FD-1 downto 0);
            RD3: out std_logic_vector(SB-1 downto 0);
            END3: out std_logic;
            IFP3: out std_logic;

            ACK4: in std_logic;
            Q4: out std_logic_vector(FD-1 downto 0);
            RD4: out std_logic_vector(SB-1 downto 0);
            END4: out std_logic;
            IFP4: out std_logic;

            ACK5: in std_logic;
            Q5: out std_logic_vector(FD-1 downto 0);
            RD5: out std_logic_vector(SB-1 downto 0);
            END5: out std_logic;
            IFP5: out std_logic;

            ACK6: in std_logic;
            Q6: out std_logic_vector(FD-1 downto 0);
            RD6: out std_logic_vector(SB-1 downto 0);
            END6: out std_logic;
            IFP6: out std_logic;

            ACK7: in std_logic;
            Q7: out std_logic_vector(FD-1 downto 0);
            RD7: out std_logic_vector(SB-1 downto 0);
            END7: out std_logic;
            IFP7: out std_logic
    	);
    end component;

    component memory_module is
        generic (
            -- Bus
            BA: integer:= 32;
            BD: integer:= 32;
            BE: integer:= 2;

            -- System
            SD: integer:= 32;
            SX: integer:= 17;

            -- Instruction
            IO: integer:= 4;
            IX: integer:= 2
        );
        port (
            clk: in std_logic;
            MEM_Stall: in std_logic;

            -- Interfície de bus del sistema
            RADDR: out std_logic_vector(BA-1 downto 0);
            RAVALID: out std_logic;
            RDATA: in std_logic_vector(BD-1 downto 0);
            RDATAV: in std_logic;
            RRESP: in std_logic_vector(BE-1 downto 0);

            WADDR: out std_logic_vector(BA-1 downto 0);
            WAVALID: out std_logic;
            WDATA: out std_logic_vector(BD-1 downto 0);
            WDATAV: out std_logic;
            WRESP: in std_logic_vector(BE-1 downto 0);
            WRESPV: in std_logic;

            -- Connexions al Execution Module
            ALUOut: in std_logic_vector(SD-1 downto 0);
            SMDR: in std_logic_vector(SD-1 downto 0);
            InstructionExecuted: in std_logic_vector(SX-1 downto 0);
            cond: in std_logic;

            -- Altres connexions
            loadI: out std_logic;
            storeI: out std_logic;
            jump: out std_logic;

  	        NewValue: out std_logic_vector(SD-1 downto 0);
            Hmem: out std_logic;

            taken: out std_logic;
            not_taken: out std_logic
    	);
    end component;

    component write_back_module is
        generic (
            -- System
            SB: integer:= 5;
            SD: integer:= 32;
            SX: integer:= 17;

            -- Instruction
            IO: integer:= 4;
            IX: integer:= 2;
            IY: integer:= 11
        );
        port (
            clk: in std_logic;
            reset: in std_logic;
            WB_Stall: in std_logic;
            ID_Stall: in std_logic;
            reset_fifo: in std_logic;

            rs: in std_logic_vector(SB-1 downto 0);
            rt: in std_logic_vector(SB-1 downto 0);
            rd: in std_logic_vector(SB-1 downto 0);

            NewValue: in std_logic_vector(SD-1 downto 0);
            DecodeOpcode: in std_logic_vector(SX-1 downto 0);

            R1: out std_logic_vector(SD-1 downto 0);
            R2: out std_logic_vector(SD-1 downto 0);

            SrcNotReady: out std_logic;
            InOOEM: out std_logic;

            BPIDQ: in std_logic_vector(SD-1 downto 0);
            BPIDRD: in std_logic_vector(SB-1 downto 0);
            BPIDIFP: in std_logic;
            BPIDNFI: in std_logic;

            BPEXEQ: in std_logic_vector(SD-1 downto 0);
            BPEXERD: in std_logic_vector(SB-1 downto 0);
            BPEXEIFP: in std_logic;
            BPEXENFI: in std_logic;

            -- OUT OF ORDER EXECUTION BUS
            ACK0: out std_logic;
            Q0: in std_logic_vector(FD-1 downto 0);
            RD0: in std_logic_vector(SB-1 downto 0);
            END0: in std_logic;
            IFP0: in std_logic;

            ACK1: out std_logic;
            Q1: in std_logic_vector(FD-1 downto 0);
            RD1: in std_logic_vector(SB-1 downto 0);
            END1: in std_logic;
            IFP1: in std_logic;

            ACK2: out std_logic;
            Q2: in std_logic_vector(FD-1 downto 0);
            RD2: in std_logic_vector(SB-1 downto 0);
            END2: in std_logic;
            IFP2: in std_logic;

            ACK3: out std_logic;
            Q3: in std_logic_vector(FD-1 downto 0);
            RD3: in std_logic_vector(SB-1 downto 0);
            END3: in std_logic;
            IFP3: in std_logic;

            ACK4: out std_logic;
            Q4: in std_logic_vector(FD-1 downto 0);
            RD4: in std_logic_vector(SB-1 downto 0);
            END4: in std_logic;
            IFP4: in std_logic;

            ACK5: out std_logic;
            Q5: in std_logic_vector(FD-1 downto 0);
            RD5: in std_logic_vector(SB-1 downto 0);
            END5: in std_logic;
            IFP5: in std_logic;

            ACK6: out std_logic;
            Q6: in std_logic_vector(FD-1 downto 0);
            RD6: in std_logic_vector(SB-1 downto 0);
            END6: in std_logic;
            IFP6: in std_logic;

            ACK7: out std_logic;
            Q7: in std_logic_vector(FD-1 downto 0);
            RD7: in std_logic_vector(SB-1 downto 0);
            END7: in std_logic;
            IFP7: in std_logic
    	);
    end component;

    component control_unit is
        port (
            clk: in std_logic;
            reset: in std_logic;

            jump: in std_logic;
            InOOEM: in std_logic;
            id_err: in std_logic;      -- SrcNotReady
            if_err: in std_logic;      -- ICDOK
            exe_err: in std_logic;     -- ALUNotReady
            store: in std_logic;       -- store
            load: in std_logic;        -- load
            WRESPV: in std_logic;      -- WRESPV
            RDATAV: in std_logic;      -- RDATAV

            if_stall:  out std_logic;
            id_stall:  out std_logic;
            exe_stall: out std_logic;
            mem_stall: out std_logic;
            wb_stall:  out std_logic;
            rwbfifo: out std_logic
    	);
    end component;

    component lifo is
        generic (
            -- System
            SA: integer:= 32;

            -- LIFO
            LS: integer := 32
        );
        port (
            clk: in std_logic;
            reset: in std_logic;

            input: in std_logic_vector(SA-1 downto 0);
            output: out std_logic_vector(SA-1 downto 0);

            add: in std_logic;
            pop: in std_logic;
            error: out std_logic
    	);
    end component;

    component cpi_tool is
        port (
            clk: in std_logic;
            wb_stall: in std_logic;
            reset: in std_logic;
            double_count: in std_logic
        );
    end component;

    ------------------------------------------------------------------------
    ----------------------------  SIGNALS  ---------------------------------
    ------------------------------------------------------------------------

    signal if_stall: std_logic;
    signal id_stall: std_logic;
    signal exe_stall: std_logic;
    signal mem_stall: std_logic;
    signal wb_stall: std_logic;

    signal ic_raddr: std_logic_vector(BA-1 downto 0);
    signal ic_ravalid: std_logic;
    signal ic_rdata: std_logic_vector(BD-1 downto 0) := (others => '0');
    signal ic_rdatav: std_logic;
    signal ic_rresp: std_logic_vector(BE-1 downto 0) := (others => '0');

    signal if_err: std_logic := '0';
    signal jump: std_logic := '0';
    signal ALUOut: std_logic_vector(SD-1 downto 0) := (others => '0');
    signal PC: std_logic_vector(SA-1 downto 0) := (others => '0');
    signal IR: std_logic_vector(SI-1 downto 0) := (others => '0');
    signal ICDOK: std_logic := '0';

    signal R1: std_logic_vector(SD-1 downto 0) := (others => '0');
    signal R2: std_logic_vector(SD-1 downto 0) := (others => '0');
    signal rs: std_logic_vector(SB-1 downto 0) := (others => '0');
    signal rt: std_logic_vector(SB-1 downto 0) := (others => '0');
    signal rd: std_logic_vector(SB-1 downto 0) := (others => '0');
    signal op: std_logic_vector(SX-1 downto 0) := (others => '0');

    signal A: std_logic_vector(SD-1 downto 0) := (others => '0');
    signal B: std_logic_vector(SD-1 downto 0) := (others => '0');
    signal Af: std_logic_vector(SD-1 downto 0) := (others => '0');
    signal Bf: std_logic_vector(SD-1 downto 0) := (others => '0');
    signal InstructionToExecute: std_logic_vector(SX-1 downto 0) := (others => '0');
    signal DecodeOpcode: std_logic_vector(SX-1 downto 0) := (others => '0');

    signal InstructionExecuted: std_logic_vector(SX-1 downto 0) := (others => '0');
    signal SMDR: std_logic_vector(SD-1 downto 0) := (others => '0');
    signal cond: std_logic := '0';

    signal ALUNotReady: std_logic;
    signal ret: std_logic;

    signal call: std_logic;
    signal NewValue: std_logic_vector(SD-1 downto 0);
    signal Hmem: std_logic;

    signal LIFOout: std_logic_vector(SD-1 downto 0);
    signal add: std_logic;
    signal pop: std_logic;

    signal SrcNotReady: std_logic;
    signal rwbfifo: std_logic;

    signal load: std_logic;
    signal store: std_logic;

    signal lifo_error: std_logic;

    signal RDid: std_logic_vector(SB-1 downto 0);

    type DEPENDENCIES_MATRIX is array ((2*(2**SB))-1 downto 0) of std_logic_vector((2*(2**SB))-1 downto 0);
    type RD_MATRIX is array (BC-1 downto 0) of std_logic_vector(SB-1 downto 0);
    type Q_MATRIX is array (BC-1 downto 0) of std_logic_vector(SD-1 downto 0);

    signal ACKV: std_logic_vector((2*(2**SB))-1 downto 0);
    signal ENDV: std_logic_vector((2*(2**SB))-1 downto 0);
    signal QM: Q_MATRIX;
    signal RDM: RD_MATRIX;
    signal IFPV: std_logic_vector((2*(2**SB))-1 downto 0);

    signal InOOEM: std_logic;

    signal BPIDQ: std_logic_vector(SD-1 downto 0);
    signal BPEXERD: std_logic_vector(SB-1 downto 0);

    signal BPIDIFP: std_logic;
    signal BPEXEIFP: std_logic;

    signal BPIDNFI: std_logic;
    signal BPEXENFI: std_logic;

    signal double_count: std_logic;

    signal newPC: std_logic_vector(SA-1 downto 0);
    signal newI: std_logic_vector(SI-1 downto 0);
    signal BPUJump: std_logic;

    signal taken: std_logic;
    signal not_taken: std_logic;

begin

    ICM: instruction_cache_memory
    generic map (
        CA => CA,
        CS => CS,

        BA => BA,
        BD => BD,
        BE => BE
    ) port map (
        clk => clk,
        reset => reset,

        RADDR => ic_raddr,
        RAVALID => ic_ravalid,
        RDATA => ic_rdata,
        RDATAV => ic_rdatav,
        RRESP => ic_rresp,

        taken => taken,
        not_taken => not_taken,

        newPC => newPC,
        newI => newI,
        BPUJump => BPUJump
    );

    IFM: instruction_fetch_module
    generic map (
        BA => BA,
        BD => BD,

        SA => SA,
        SD => SD,
        SI => SI
    ) port map (
        clk => clk,
        reset => reset,

        jump => jump,
        ALUOut => ALUOut,
        IF_Stall => if_stall,
        MEM_Stall => mem_stall,

        RDATA => ic_rdata,
        RDATAV => ic_rdatav,
        RRESP => ic_rresp,

        PC => PC,
        IR => IR,
        ICDOK => ICDOK,

        RADDR => ic_raddr,
        RAVALID => ic_ravalid,

        newPC => newPC,
        newI => newI,
        BPUJump => BPUJump
    );

    IDM: instruction_decode_module
    generic map (
        SA => SA,
        SB => SB,
        SD => SD,
        SI => SI,
        SX => SX,

        IB => IB,
        IO => IO,
        IX => IX,
        IY => IY,
        IJ => IJ
    ) port map (
        clk => clk,
        ID_Stall => id_stall,

        IR => IR,
        PC => PC,

        R1 => R1,
        R2 => R2,

        rs => rs,
        rt => rt,
        rd => rd,

        op => DecodeOpcode,

        A => A,
        B => B,
        Af => Af,
        Bf => Bf,
        InstructionToExecute => InstructionToExecute,
        RDid => RDid
    );

    EXEM: execution_module
    generic map (
        SA => SA,
        SD => SD,
        SX => SX,
        SB => SB,

        IO => IO,
        IX => IX,
        IY => IY,

        FD => FD,
        FM => FM,
        FE => FE,

        BC => BC
    )
    port map (
        clk => clk,
        reset => reset,
        EXE_Stall => exe_stall,

        A => A,
        B => B,
        Af => Af,
        Bf => Bf,

        InstructionToExecute => InstructionToExecute,
        RD => RDid,

        BPIDQ => BPIDQ,
        BPIDIFP => BPIDIFP,
        BPIDNFI => BPIDNFI,

        BPEXERD => BPEXERD,
        BPEXEIFP => BPEXEIFP,
        BPEXENFI => BPEXENFI,

        InstructionExecuted => InstructionExecuted,
        ALUOut => ALUOut,
        SMDR => SMDR,
        cond => cond,

        ALUNotReady => ALUNotReady,
        ret => ret,
        LIFOout => LIFOout,

        ACK0 => ACKV(0),
        Q0 => QM(0),
        RD0 => RDM(0),
        END0 => ENDV(0),
        IFP0 => IFPV(0),
        ACK1 => ACKV(1),
        Q1 => QM(1),
        RD1 => RDM(1),
        END1 => ENDV(1),
        IFP1 => IFPV(1),
        ACK2 => ACKV(2),
        Q2 => QM(2),
        RD2 => RDM(2),
        END2 => ENDV(2),
        IFP2 => IFPV(2),
        ACK3 => ACKV(3),
        Q3 => QM(3),
        RD3 => RDM(3),
        END3 => ENDV(3),
        IFP3 => IFPV(3),
        ACK4 => ACKV(4),
        Q4 => QM(4),
        RD4 => RDM(4),
        END4 => ENDV(4),
        IFP4 => IFPV(4),
        ACK5 => ACKV(5),
        Q5 => QM(5),
        RD5 => RDM(5),
        END5 => ENDV(5),
        IFP5 => IFPV(5),
        ACK6 => ACKV(6),
        Q6 => QM(6),
        RD6 => RDM(6),
        END6 => ENDV(6),
        IFP6 => IFPV(6),
        ACK7 => ACKV(7),
        Q7 => QM(7),
        RD7 => RDM(7),
        END7 => ENDV(7),
        IFP7 => IFPV(7)
    );

    MEM: memory_module
    generic map (
        BA => BA,
        BD => BD,
        BE => BE,

        SD => SD,
        SX => SX,

        IO => IO,
        IX => IX
    ) port map (
        clk => clk,
        MEM_Stall => mem_stall,

        RADDR => RADDR,
        RAVALID => RAVALID,
        RDATA => RDATA,
        RDATAV => RDATAV,
        RRESP => RRESP,

        WADDR => WADDR,
        WAVALID => WAVALID,
        WDATA => WDATA,
        WDATAV => WDATAV,
        WRESP => WRESP,
        WRESPV => WRESPV,

        ALUOut => ALUOut,
        SMDR => SMDR,
        InstructionExecuted => InstructionExecuted,
        cond => cond,

        loadI => load,
        storeI => store,
        jump => jump,

        NewValue => NewValue,
        Hmem => Hmem,
        
        taken => taken,
        not_taken => not_taken
    );

    WBM: write_back_module
    generic map (
        SB => SB,
        SD => SD,
        SX => SX,

        IO => IO,
        IX => IX,
        IY => IY
    ) port map (
        clk => clk,
        reset => reset,
        WB_Stall => WB_Stall,
        ID_Stall => ID_Stall,

        rs => rs,
        rt => rt,
        rd => rd,

        NewValue => NewValue,
        DecodeOpcode => DecodeOpcode,
        reset_fifo => rwbfifo,

        R1 => R1,
        R2 => R2,

        SrcNotReady => SrcNotReady,
        InOOEM => InOOEM,

        BPIDQ => BPIDQ,
        BPIDRD => RDid,
        BPIDIFP => BPIDIFP,
        BPIDNFI => BPIDNFI,

        BPEXEQ => ALUOut,
        BPEXERD => BPEXERD,
        BPEXEIFP => BPEXEIFP,
        BPEXENFI => BPEXENFI,

        ACK0 => ACKV(0),
        Q0 => QM(0),
        RD0 => RDM(0),
        END0 => ENDV(0),
        IFP0 => IFPV(0),
        ACK1 => ACKV(1),
        Q1 => QM(1),
        RD1 => RDM(1),
        END1 => ENDV(1),
        IFP1 => IFPV(1),
        ACK2 => ACKV(2),
        Q2 => QM(2),
        RD2 => RDM(2),
        END2 => ENDV(2),
        IFP2 => IFPV(2),
        ACK3 => ACKV(3),
        Q3 => QM(3),
        RD3 => RDM(3),
        END3 => ENDV(3),
        IFP3 => IFPV(3),
        ACK4 => ACKV(4),
        Q4 => QM(4),
        RD4 => RDM(4),
        END4 => ENDV(4),
        IFP4 => IFPV(4),
        ACK5 => ACKV(5),
        Q5 => QM(5),
        RD5 => RDM(5),
        END5 => ENDV(5),
        IFP5 => IFPV(5),
        ACK6 => ACKV(6),
        Q6 => QM(6),
        RD6 => RDM(6),
        END6 => ENDV(6),
        IFP6 => IFPV(6),
        ACK7 => ACKV(7),
        Q7 => QM(7),
        RD7 => RDM(7),
        END7 => ENDV(7),
        IFP7 => IFPV(7)
    );

    if_err <= not ic_rdatav;

    CU: control_unit
    port map(
        clk => clk,
        reset => reset,

        jump => jump,
        InOOEM => InOOEM,
        id_err => SrcNotReady,
        if_err => if_err,
        exe_err => ALUNotReady,
        store => store,
        load => load,
        WRESPV => WRESPV,
        RDATAV => RDATAV,

        if_stall => if_stall,
        id_stall => id_stall,
        exe_stall => exe_stall,
        mem_stall => mem_stall,
        wb_stall => wb_stall,
        rwbfifo => rwbfifo
    );

    add <= '1' when (InstructionExecuted(IO-1 downto 0) = "1100" and InstructionExecuted(IO+IX-1 downto IO) = "01") and mem_stall = '0' else '0';
    pop <= '1' when (InstructionExecuted(IO-1 downto 0) = "1100" and InstructionExecuted(IO+IX-1 downto IO) = "10") and mem_stall = '0' else '0';

    LIFOMODULE: lifo
    generic map (
        SA => SA,
        LS => LS
    ) port map (
        clk => clk,
        reset => reset,

        input => SMDR,
        output => LIFOout,

        add => add,
        pop => pop,
        error => lifo_error
    );

    double_count <= mem_stall and jump;

    CPI: cpi_tool
    port map (
        clk => clk,
        wb_stall => wb_stall,
        reset => reset,
        double_count => double_count
    );

end a;

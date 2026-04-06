library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.constant_package.all;
use work.pipeline_registers.all;  -- gives IF_ID, ID_EX, EX_MEM record types

entity Top_Level_CPU is
    port(
        clk       : in  std_logic;
        rst       : in  std_logic;
        boot_mode : in  std_logic;                      -- 0=Execute, 1=Load
        in_port   : in  std_logic_vector(15 downto 0);
        out_port  : out std_logic_vector(15 downto 0)
    );
end Top_Level_CPU;

architecture Behavioral of Top_Level_CPU is

    ---------------------------------------------------------------
    -- PIPELINE REGISTER SIGNALS (record types from pipeline_registers package)
    -- Access fields with dot notation: IF_ID_reg.instruction, etc.
    -- Keep pipeline Registers in top level;
    ---------------------------------------------------------------
    signal IF_ID_reg  : IF_ID;   -- .instruction, .pc_plus2
    signal ID_EX_reg  : ID_EX;   -- .rd_data1/2, .imm, .dest_reg, .pc_plus2,
                                  -- .alu_mode, .alu_src, .wr_en_MEM, .reg_write, .wb_src
    signal EX_MEM_reg : EX_MEM;  -- .alu_result, .rd_data2, .dest_reg, .pc_plus2,
                                  -- .wr_en_MEM, .reg_write, .wb_src
    --Robin Changes END.

    signal MEM_WB_reg : MEM_WB;  -- .alu_result, .mem_data, .dest_reg, .pc_plus2, .reg_write, .wb_src, .in_p_EN

    ---------------------------------------------------------------
    -- FETCH STAGE SIGNALS
    ---------------------------------------------------------------
    signal fetch_pc      : std_logic_vector(15 downto 0); -- current PC out of fetch
    signal fetch_instr   : std_logic_vector(15 downto 0); -- instruction out of fetch
    signal pc_mode       : std_logic_vector(1 downto 0);  -- drives fetch mode port
    signal branch_target : std_logic_vector(15 downto 0); -- address to load on branch


      ---------------------------------------------------------------
    -- DECODE STAGE SIGNALS
    ---------------------------------------------------------------
    signal decode_rd_data1  : std_logic_vector(15 downto 0);
    signal decode_rd_data2  : std_logic_vector(15 downto 0);
    signal decode_imm       : std_logic_vector(15 downto 0);
    signal decode_dest_reg  : std_logic_vector(2 downto 0);
    signal decode_pc_plus2  : std_logic_vector(15 downto 0);

    signal decode_alu_mode  : std_logic_vector(2 downto 0);
    signal decode_alu_src   : std_logic;
    signal decode_wr_en_MEM : std_logic;
    signal decode_wr_en_REG : std_logic;
    signal decode_sel_WB    : std_logic_vector(1 downto 0);
    signal decode_in_p_EN   : std_logic;
    signal decode_out_p_EN  : std_logic;

    signal pc_reset         : std_logic;

    -- Robin Changes Start
    -- Explanation of changes:
    -- 1) branch_taken is the controller/decode decision that a branch is actually being taken.
    -- 2) The IF/ID register will use this to flush the wrong-path fetched instruction.
    -- Robin Changes End.
    signal branch_taken     : std_logic;

    -- Robin Changes Start
    -- Explanation of changes:
    -- 1) These signals come from decode so top level can detect RAW hazards.
    -- 2) src*_used tells us whether the current IF/ID instruction actually reads that source.
    -- Robin Changes End.
    signal decode_src1_reg  : std_logic_vector(2 downto 0);
    signal decode_src2_reg  : std_logic_vector(2 downto 0);
    signal decode_src1_used : std_logic;
    signal decode_src2_used : std_logic;

    -- Robin Changes Start
    -- Explanation of changes:
    -- 1) stall_pipe is asserted on a detected RAW hazard.
    -- 2) pc_en freezes fetch/program_counter.
    -- 3) if_id_en freezes the IF/ID register.
    -- 4) id_ex_flush inserts a bubble into ID/EX while older instructions continue draining.
    -- Robin Changes End.
    signal stall_pipe       : std_logic;
    signal pc_en            : std_logic;
    signal if_id_en         : std_logic;
    signal id_ex_flush      : std_logic;

    -- eXecute signals
    signal exec_rd_data2   : std_logic_vector(15 downto 0);
    signal exec_dest_reg   : std_logic_vector(2 downto 0);
    signal exec_pc_plus2   : std_logic_vector(15 downto 0);
    signal exec_wr_en_MEM  : std_logic;
    signal exec_reg_write  : std_logic;
    signal exec_wb_src     : std_logic_vector(1 downto 0);
    signal exec_in_p_EN    : std_logic;
    signal exec_out_p_EN   : std_logic;


    ---------------------------------------------------------------
    -- ALU SIGNALS
    ---------------------------------------------------------------
    signal alu_result : std_logic_vector(15 downto 0);
    signal flag_zero  : std_logic;
    signal flag_neg   : std_logic;
    signal flag_carry : std_logic;
    signal flag_overflow : std_logic;

    ---------------------------------------------------------------
    --MEM SIGNALS

    signal mem_alu_result : std_logic_vector(15 downto 0);
    signal mem_data       : std_logic_vector(15 downto 0);
    signal mem_dest_reg   : std_logic_vector(2 downto 0);
    signal mem_pc_plus2   : std_logic_vector(15 downto 0);
    signal mem_reg_write  : std_logic;
    signal mem_wb_src     : std_logic_vector(1 downto 0);
    signal mem_in_p_EN    : std_logic;
    signal mem_out_p_EN   : std_logic;

    ---------------------------------------------------------------
    -- WRITE BACK SIGNALS
    ---------------------------------------------------------------
    signal w_addr_rf  : std_logic_vector(2 downto 0);
    signal w_data_rf  : std_logic_vector(15 downto 0);
    signal wr_en_rf   : std_logic;

begin

    -- Robin Changes Start
    -- Explanation of changes:
    -- 1) Detect read-after-write hazards between the current IF/ID instruction and older
    --    instructions currently in ID/EX, EX/MEM, and MEM/WB.
    -- 2) Stall while the producer is still in ID/EX or EX/MEM.
    -- 3) Also stall when the producer is in MEM/WB: the register file reads from array_reg
    --    (no write-through), so the WB write and the ID/EX capture happen on the same edge.
    --    Without this check the consumer would capture a stale register value.
    -- Robin Changes End.
    process(ID_EX_reg, EX_MEM_reg, MEM_WB_reg, decode_src1_reg, decode_src2_reg, decode_src1_used, decode_src2_used)
    begin
        stall_pipe <= '0';

        if ID_EX_reg.reg_write = '1' then
            if (decode_src1_used = '1' and decode_src1_reg = ID_EX_reg.dest_reg) or
               (decode_src2_used = '1' and decode_src2_reg = ID_EX_reg.dest_reg) then
                stall_pipe <= '1';
            end if;
        end if;

        if EX_MEM_reg.reg_write = '1' then
            if (decode_src1_used = '1' and decode_src1_reg = EX_MEM_reg.dest_reg) or
               (decode_src2_used = '1' and decode_src2_reg = EX_MEM_reg.dest_reg) then
                stall_pipe <= '1';
            end if;
        end if;

        -- Robin Changes Start
        -- Explanation of changes:
        -- 1) Third stall cycle: producer is in MEM/WB but array_reg hasn't been written yet
        --    when decode combinatorially reads it. Without this stall the consumer reads the
        --    old (pre-writeback) value and that wrong value gets latched into ID/EX.
        -- Robin Changes End.
        if MEM_WB_reg.reg_write = '1' then
            if (decode_src1_used = '1' and decode_src1_reg = MEM_WB_reg.dest_reg) or
               (decode_src2_used = '1' and decode_src2_reg = MEM_WB_reg.dest_reg) then
                stall_pipe <= '1';
            end if;
        end if;
    end process;

-- Robin Changes Start
-- Explanation of changes:
-- 1) Hold the program counter whenever pc_reset is active so the first instruction is not skipped.
-- 2) stall_pipe still freezes the PC for RAW hazards.
-- Robin Changes End.
pc_en       <= (not stall_pipe) and (not pc_reset);
if_id_en    <= not stall_pipe;
id_ex_flush <= stall_pipe;

    ---------------------------------------------------------------
    -- PIPELINE REGISTERS (clocked processes replace missing component files)
    ---------------------------------------------------------------

    -- IF/ID Register: latches fetch output into decode stage
    IF_ID_proc : process(clk, rst)
    begin
        if rst = '1' then
            IF_ID_reg.instruction <= (others => '0');
            IF_ID_reg.pc_plus2    <= (others => '0');
        elsif rising_edge(clk) then

            -- Robin Changes Start
            -- Explanation of changes:
            -- 1) Flush IF/ID on reset-control or on a taken branch — but ONLY when not stalling.
            --    If stall_pipe = '1' a branch instruction in IF/ID may have branch_taken = '1'
            --    (e.g. BR Ra with a RAW hazard on Ra). Without the stall guard the branch would
            --    be flushed from IF/ID while pc_en = '0' prevents the PC from loading the
            --    target, silently losing the branch.
            -- 2) Store real PC+2, not raw fetch_pc.
            -- 3) Hold IF/ID when the hazard unit requests a stall.
            -- Robin Changes End.
            if pc_reset = '1' or (branch_taken = '1' and stall_pipe = '0') then

                -- branch taken: flush the incorrectly-fetched instruction with a NOP
                IF_ID_reg.instruction <= (others => '0');
                IF_ID_reg.pc_plus2    <= (others => '0');
            elsif if_id_en = '1' then
                IF_ID_reg.instruction <= fetch_instr;
                IF_ID_reg.pc_plus2    <= std_logic_vector(unsigned(fetch_pc) + 2);
            else
                IF_ID_reg.instruction <= IF_ID_reg.instruction;
                IF_ID_reg.pc_plus2    <= IF_ID_reg.pc_plus2;
            end if;
        end if;
    end process;

    -- ID/EX Register: latches decode/controller output into execute stage
    ID_EX_proc : process(clk, rst)
    begin
        if rst = '1' then
            ID_EX_reg.rd_data1  <= (others => '0');
            ID_EX_reg.rd_data2  <= (others => '0');
            ID_EX_reg.imm       <= (others => '0');
            ID_EX_reg.dest_reg  <= (others => '0');
            ID_EX_reg.pc_plus2  <= (others => '0');
            ID_EX_reg.alu_mode  <= ALU_NOP;
            ID_EX_reg.alu_src   <= '0';
            ID_EX_reg.wr_en_MEM <= '0';
            ID_EX_reg.reg_write <= '0';
            ID_EX_reg.wb_src    <= WB_ALU;
            ID_EX_reg.in_p_EN   <= '0';
            ID_EX_reg.out_p_EN  <= '0';
            ID_EX_reg.in_data   <= (others => '0');
        elsif rising_edge(clk) then

            -- Robin Changes Start
            -- Explanation of changes:
            -- 1) Insert a bubble into ID/EX whenever the hazard unit requests a stall.
            -- 2) This allows older instructions to keep draining while the consumer remains parked in IF/ID.
            -- Robin Changes End.
            if id_ex_flush = '1' then
                ID_EX_reg.rd_data1  <= (others => '0');
                ID_EX_reg.rd_data2  <= (others => '0');
                ID_EX_reg.imm       <= (others => '0');
                ID_EX_reg.dest_reg  <= (others => '0');
                ID_EX_reg.pc_plus2  <= (others => '0');
                ID_EX_reg.alu_mode  <= ALU_NOP;
                ID_EX_reg.alu_src   <= '0';
                ID_EX_reg.wr_en_MEM <= '0';
                ID_EX_reg.reg_write <= '0';
                ID_EX_reg.wb_src    <= WB_ALU;
                ID_EX_reg.in_p_EN   <= '0';
                ID_EX_reg.out_p_EN  <= '0';
                ID_EX_reg.in_data   <= (others => '0');
            else
                ID_EX_reg.rd_data1  <= decode_rd_data1;
                ID_EX_reg.rd_data2  <= decode_rd_data2;
                ID_EX_reg.imm       <= decode_imm;
                ID_EX_reg.dest_reg  <= decode_dest_reg;
                ID_EX_reg.pc_plus2  <= decode_pc_plus2;
                ID_EX_reg.alu_mode  <= decode_alu_mode;
                ID_EX_reg.alu_src   <= decode_alu_src;
                ID_EX_reg.wr_en_MEM <= decode_wr_en_MEM;
                ID_EX_reg.reg_write <= decode_wr_en_REG;
                ID_EX_reg.wb_src    <= decode_sel_WB;
                ID_EX_reg.in_p_EN   <= decode_in_p_EN;
                ID_EX_reg.out_p_EN  <= decode_out_p_EN;
                -- Robin Changes Start
                -- Explanation of changes:
                -- 1) Reuse the auxiliary ridealong path for both IN data and LOADIMM values.
                -- 2) IN continues to carry external in_port.
                -- 3) LOADIMM carries the synthesized immediate from decode using WB_AUX.
                -- Robin Changes End.
                if decode_sel_WB = WB_AUX then
                    ID_EX_reg.in_data <= decode_imm;
                else
                    ID_EX_reg.in_data <= in_port;
                end if;
            end if;
        end if;
    end process;

    -- EX/MEM Register: latches execute output into memory stage
    EX_MEM_proc : process(clk, rst)
    begin
        if rst = '1' then
            EX_MEM_reg.alu_result <= (others => '0');
            EX_MEM_reg.rd_data2   <= (others => '0');
            EX_MEM_reg.dest_reg   <= (others => '0');
            EX_MEM_reg.pc_plus2   <= (others => '0');
            EX_MEM_reg.wr_en_MEM  <= '0';
            EX_MEM_reg.reg_write  <= '0';
            EX_MEM_reg.wb_src     <= WB_ALU;
            EX_MEM_reg.in_p_EN    <= '0';
            EX_MEM_reg.out_p_EN   <= '0';
            EX_MEM_reg.in_data    <= (others => '0');
        elsif rising_edge(clk) then
            EX_MEM_reg.alu_result <= alu_result;
            EX_MEM_reg.rd_data2   <= exec_rd_data2;
            EX_MEM_reg.dest_reg   <= exec_dest_reg;
            EX_MEM_reg.pc_plus2   <= exec_pc_plus2;
            EX_MEM_reg.wr_en_MEM  <= exec_wr_en_MEM;
            EX_MEM_reg.reg_write  <= exec_reg_write;
            EX_MEM_reg.wb_src     <= exec_wb_src;
            EX_MEM_reg.in_p_EN    <= exec_in_p_EN;
            EX_MEM_reg.out_p_EN   <= exec_out_p_EN;
            EX_MEM_reg.in_data    <= ID_EX_reg.in_data;
        end if;
    end process;

    -- MEM/WB Register: latches memory stage output into write-back stage
    MEM_WB_proc : process(clk, rst)
    begin
        if rst = '1' then
            MEM_WB_reg.alu_result <= (others => '0');
            MEM_WB_reg.mem_data   <= (others => '0');
            MEM_WB_reg.dest_reg   <= (others => '0');
            MEM_WB_reg.pc_plus2   <= (others => '0');
            MEM_WB_reg.reg_write  <= '0';
            MEM_WB_reg.wb_src     <= WB_ALU;
            MEM_WB_reg.in_p_EN    <= '0';
            MEM_WB_reg.out_p_EN   <= '0';
            MEM_WB_reg.in_data    <= (others => '0');
        elsif rising_edge(clk) then
            MEM_WB_reg.alu_result <= mem_alu_result;
            MEM_WB_reg.mem_data   <= mem_data;
            MEM_WB_reg.dest_reg   <= mem_dest_reg;
            MEM_WB_reg.pc_plus2   <= mem_pc_plus2;
            MEM_WB_reg.reg_write  <= mem_reg_write;
            MEM_WB_reg.wb_src     <= mem_wb_src;
            MEM_WB_reg.in_p_EN    <= mem_in_p_EN;
            MEM_WB_reg.out_p_EN   <= mem_out_p_EN;
            MEM_WB_reg.in_data    <= EX_MEM_reg.in_data;
        end if;
    end process;

    ---------------------------------------------------------------
    -- COMPONENT INSTANTIATIONS
    ---------------------------------------------------------------

    -- FETCH (wraps program_counter + ROM internally)
    u_fetch : entity work.fetch
        port map (
            clk         => clk,
            reset       => rst,

            -- Robin Changes Start
            -- Explanation of changes:
            -- 1) pc_en freezes the fetch stage program counter during a hazard stall.
            -- Robin Changes End.
            pc_en       => pc_en,
            rom_ena     => '1',          -- TODO: tie to stall logic if needed

            mode        => pc_mode,
            in_pc       => branch_target,
            pc          => fetch_pc,
            instruction => fetch_instr
        );

        u_decode : entity work.decode
        port map(
            clk           => clk,
            reset         => rst,
            instruction   => IF_ID_reg.instruction,
            pc_plus2_in   => IF_ID_reg.pc_plus2,
            wb_wr_en      => wr_en_rf,
            wb_dest       => w_addr_rf,
            wb_data       => w_data_rf,
            flag_zero     => flag_zero,
            flag_neg      => flag_neg,
            flag_overflow => flag_overflow,
            boot_mode     => boot_mode,
            rd_data1      => decode_rd_data1,
            rd_data2      => decode_rd_data2,
            imm           => decode_imm,
            dest_reg      => decode_dest_reg,
            pc_plus2_out  => decode_pc_plus2,
            alu_mode      => decode_alu_mode,
            alu_src       => decode_alu_src,
            wr_en_MEM     => decode_wr_en_MEM,
            wr_en_REG     => decode_wr_en_REG,
            sel_WB        => decode_sel_WB,
            in_p_EN       => decode_in_p_EN,
            out_p_EN      => decode_out_p_EN,
            shift_amt     => open,
            pc_mode       => pc_mode,
            branch_target => branch_target,
            pc_reset      => pc_reset,

            -- Robin Changes Start
            -- Explanation of changes:
            -- 1) Hook up the new branch_taken output from decode.
            -- Robin Changes End.
            branch_taken  => branch_taken,

            -- Robin Changes Start
            -- Explanation of changes:
            -- 1) Hook up the new hazard detection outputs from decode.
            -- Robin Changes End.
            src1_reg      => decode_src1_reg,
            src2_reg      => decode_src2_reg,
            src1_used     => decode_src1_used,
            src2_used     => decode_src2_used
        );

    --ECECUTE COMPONENT INSTANTIATION
    u_execute : entity work.execute
        port map(
            rd_data1      => ID_EX_reg.rd_data1,
            rd_data2      => ID_EX_reg.rd_data2,
            imm           => ID_EX_reg.imm,
            dest_reg      => ID_EX_reg.dest_reg,
            pc_plus2      => ID_EX_reg.pc_plus2,

            alu_mode      => ID_EX_reg.alu_mode,
            alu_src       => ID_EX_reg.alu_src,
            wr_en_MEM     => ID_EX_reg.wr_en_MEM,
            reg_write     => ID_EX_reg.reg_write,
            wb_src        => ID_EX_reg.wb_src,
            in_p_EN       => ID_EX_reg.in_p_EN,
            out_p_EN      => ID_EX_reg.out_p_EN,

            alu_result        => alu_result,
            rd_data2_out      => exec_rd_data2,
            dest_reg_out      => exec_dest_reg,
            pc_plus2_out      => exec_pc_plus2,

            wr_en_MEM_out     => exec_wr_en_MEM,
            reg_write_out     => exec_reg_write,
            wb_src_out        => exec_wb_src,
            in_p_EN_out       => exec_in_p_EN,
            out_p_EN_out      => exec_out_p_EN,

            flag_zero_out     => flag_zero,
            flag_negative_out => flag_neg,
            flag_carry_out    => flag_carry,
            flag_overflow_out => flag_overflow
        );

        -- MEMORY COMPONENT INSTANTIATION
        u_memory : entity work.memory
            port map
            (
            clk         => clk,
            rst         => rst,

            -- INPUTS from EX/MEM
            alu_result  => EX_MEM_reg.alu_result,
            rd_data2    => EX_MEM_reg.rd_data2,
            dest_reg    => EX_MEM_reg.dest_reg,
            pc_plus2    => EX_MEM_reg.pc_plus2,

            wr_en_MEM   => EX_MEM_reg.wr_en_MEM,
            reg_write   => EX_MEM_reg.reg_write,
            wb_src      => EX_MEM_reg.wb_src,
            in_p_EN     => EX_MEM_reg.in_p_EN,
            out_p_EN    => EX_MEM_reg.out_p_EN,

            -- OUTPUTS to MEM/WB
            alu_result_out  => mem_alu_result,
            mem_data_out    => mem_data,
            dest_reg_out    => mem_dest_reg,
            pc_plus2_out    => mem_pc_plus2,

            reg_write_out   => mem_reg_write,
            wb_src_out      => mem_wb_src,
            in_p_EN_out     => mem_in_p_EN,
            out_p_EN_out    => mem_out_p_EN,

            -- external output port
            out_port        => out_port
            );

            -- WRITEBACK COMPONENT INSTANTIATION
            u_writeback : entity work.writeback
                port map (
                    alu_result   => MEM_WB_reg.alu_result,
                    mem_data     => MEM_WB_reg.mem_data,
                    dest_reg     => MEM_WB_reg.dest_reg,
                    pc_plus2     => MEM_WB_reg.pc_plus2,

                    reg_write    => MEM_WB_reg.reg_write,
                    wb_src       => MEM_WB_reg.wb_src,
                    in_p_EN      => MEM_WB_reg.in_p_EN,
                    out_p_EN     => MEM_WB_reg.out_p_EN,

                    in_data      => MEM_WB_reg.in_data,

                    wb_data      => w_data_rf,
                    wb_dest_reg  => w_addr_rf,
                    wb_reg_write => wr_en_rf,
                    out_port     => open
                );

end Behavioral;

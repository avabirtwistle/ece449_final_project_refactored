library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.constant_package.all;
use work.pipeline_registers.all;

entity Top_Level_CPU is
    port(
        clk       : in  std_logic;
        rst       : in  std_logic;
        boot_mode : in  std_logic;
        in_port   : in  std_logic_vector(15 downto 0);
        out_port  : out std_logic_vector(15 downto 0);
        debug_console : in  std_logic;
        vga_red       : out std_logic_vector(3 downto 0);
        vga_green     : out std_logic_vector(3 downto 0);
        vga_blue      : out std_logic_vector(3 downto 0);
        h_sync_signal : out std_logic;
        v_sync_signal : out std_logic;
        led_segments  : out std_logic_vector(6 downto 0);
        led_digits    : out std_logic_vector(3 downto 0)
    );
end Top_Level_CPU;

architecture Behavioral of Top_Level_CPU is

    signal IF_ID_reg  : IF_ID;
    signal ID_EX_reg  : ID_EX;
    signal EX_MEM_reg : EX_MEM;
    signal MEM_WB_reg : MEM_WB;

    signal fetch_pc      : std_logic_vector(15 downto 0);
    signal fetch_instr   : std_logic_vector(15 downto 0);
    signal pc_mode       : std_logic_vector(1 downto 0);
    signal branch_target : std_logic_vector(15 downto 0);

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
    signal branch_taken     : std_logic;

    signal decode_src1_reg  : std_logic_vector(2 downto 0);
    signal decode_src2_reg  : std_logic_vector(2 downto 0);
    signal decode_src1_used : std_logic;
    signal decode_src2_used : std_logic;

    signal stall_pipe       : std_logic;
    signal pc_en            : std_logic;
    signal if_id_en         : std_logic;
    signal id_ex_flush      : std_logic;

    signal exec_rd_data2   : std_logic_vector(15 downto 0);
    signal exec_dest_reg   : std_logic_vector(2 downto 0);
    signal exec_pc_plus2   : std_logic_vector(15 downto 0);
    signal exec_wr_en_MEM  : std_logic;
    signal exec_reg_write  : std_logic;
    signal exec_wb_src     : std_logic_vector(1 downto 0);
    signal exec_in_p_EN    : std_logic;
    signal exec_out_p_EN   : std_logic;

    signal alu_result      : std_logic_vector(15 downto 0);
    signal flag_zero       : std_logic;
    signal flag_neg        : std_logic;
    signal flag_carry      : std_logic;
    signal flag_overflow   : std_logic;

    signal mem_alu_result : std_logic_vector(15 downto 0);
    signal mem_data       : std_logic_vector(15 downto 0);
    signal mem_dest_reg   : std_logic_vector(2 downto 0);
    signal mem_pc_plus2   : std_logic_vector(15 downto 0);
    signal mem_reg_write  : std_logic;
    signal mem_wb_src     : std_logic_vector(1 downto 0);
    signal mem_in_p_EN    : std_logic;
    signal mem_out_p_EN   : std_logic;

    signal w_addr_rf      : std_logic_vector(2 downto 0);
    signal w_data_rf      : std_logic_vector(15 downto 0);
    signal wr_en_rf       : std_logic;

    -- Robin Changes Start
    -- Explanation of changes:
    -- 1) Minimal live-demo observability only: expose current register file contents to this
    --    top level so the monitor can show them later without altering CPU behavior.
    -- 2) These signals are not used by the testbench path unless you uncomment the monitor block.
    -- Robin Changes End.
    signal dbg_r0         : std_logic_vector(15 downto 0);
    signal dbg_r1         : std_logic_vector(15 downto 0);
    signal dbg_r2         : std_logic_vector(15 downto 0);
    signal dbg_r3         : std_logic_vector(15 downto 0);
    signal dbg_r4         : std_logic_vector(15 downto 0);
    signal dbg_r5         : std_logic_vector(15 downto 0);
    signal dbg_r6         : std_logic_vector(15 downto 0);
    signal dbg_r7         : std_logic_vector(15 downto 0);

begin

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

        if MEM_WB_reg.reg_write = '1' then
            if (decode_src1_used = '1' and decode_src1_reg = MEM_WB_reg.dest_reg) or
               (decode_src2_used = '1' and decode_src2_reg = MEM_WB_reg.dest_reg) then
                stall_pipe <= '1';
            end if;
        end if;
    end process;

    pc_en       <= (not stall_pipe) and (not pc_reset);
    if_id_en    <= not stall_pipe;
    id_ex_flush <= stall_pipe;

    IF_ID_proc : process(clk, rst)
    begin
        if rst = '1' then
            IF_ID_reg.instruction <= (others => '0');
            IF_ID_reg.pc_plus2    <= (others => '0');
        elsif rising_edge(clk) then
            if pc_reset = '1' or (branch_taken = '1' and stall_pipe = '0') then
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
                if decode_sel_WB = WB_AUX then
                    ID_EX_reg.in_data <= decode_imm;
                else
                    ID_EX_reg.in_data <= in_port;
                end if;
            end if;
        end if;
    end process;

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

    u_fetch : entity work.fetch
        port map (
            clk         => clk,
            reset       => rst,
            pc_en       => pc_en,
            rom_ena     => '1',
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
            branch_taken  => branch_taken,
            src1_reg      => decode_src1_reg,
            src2_reg      => decode_src2_reg,
            src1_used     => decode_src1_used,
            src2_used     => decode_src2_used,
            dbg_r0        => dbg_r0,
            dbg_r1        => dbg_r1,
            dbg_r2        => dbg_r2,
            dbg_r3        => dbg_r3,
            dbg_r4        => dbg_r4,
            dbg_r5        => dbg_r5,
            dbg_r6        => dbg_r6,
            dbg_r7        => dbg_r7
        );

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

    u_memory : entity work.memory
        port map(
            clk         => clk,
            rst         => rst,
            alu_result  => EX_MEM_reg.alu_result,
            rd_data2    => EX_MEM_reg.rd_data2,
            dest_reg    => EX_MEM_reg.dest_reg,
            pc_plus2    => EX_MEM_reg.pc_plus2,
            wr_en_MEM   => EX_MEM_reg.wr_en_MEM,
            reg_write   => EX_MEM_reg.reg_write,
            wb_src      => EX_MEM_reg.wb_src,
            in_p_EN     => EX_MEM_reg.in_p_EN,
            out_p_EN    => EX_MEM_reg.out_p_EN,
            alu_result_out  => mem_alu_result,
            mem_data_out    => mem_data,
            dest_reg_out    => mem_dest_reg,
            pc_plus2_out    => mem_pc_plus2,
            reg_write_out   => mem_reg_write,
            wb_src_out      => mem_wb_src,
            in_p_EN_out     => mem_in_p_EN,
            out_p_EN_out    => mem_out_p_EN,
            out_port        => out_port
        );

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

    -- Robin Changes Start
    -- Explanation of changes:
    -- 1) Minimal hardware-demo wiring only: reuse the verified CPU and mirror existing state
    --    into the instructor-provided console and seven-segment display helpers.
    -- 2) No extra core wrapper is introduced; later-stage instruction slots that are not stored
    --    explicitly are tied low instead of restructuring the datapath for observability alone.
    -- 3) The helpers share the existing clk input so the board integration stays small.
    console_display : entity work.console
        port map(
            s1_pc => fetch_pc,
            s1_inst => fetch_instr,
            s2_pc => IF_ID_reg.pc_plus2,
            s2_inst => IF_ID_reg.instruction,
            s2_reg_a => decode_dest_reg,
            s2_reg_b => decode_src1_reg,
            s2_reg_c => decode_src2_reg,
            s2_reg_a_data => x"0000",
            s2_reg_b_data => decode_rd_data1,
            s2_reg_c_data => decode_rd_data2,
            s2_immediate => decode_imm,
            s3_pc => ID_EX_reg.pc_plus2,
            s3_inst => x"0000",
            s3_reg_a => ID_EX_reg.dest_reg,
            s3_reg_b => "000",
            s3_reg_c => "000",
            s3_reg_a_data => ID_EX_reg.rd_data1,
            s3_reg_b_data => ID_EX_reg.rd_data2,
            s3_reg_c_data => x"0000",
            s3_immediate => ID_EX_reg.imm,
            s3_r_wb => ID_EX_reg.reg_write,
            s3_r_wb_data => alu_result,
            s3_br_wb => branch_taken,
            s3_br_wb_address => branch_target,
            s3_mr_wr => EX_MEM_reg.wr_en_MEM,
            s3_mr_wr_address => EX_MEM_reg.alu_result,
            s3_mr_wr_data => EX_MEM_reg.rd_data2,
            s3_mr_rd => '1' when EX_MEM_reg.wb_src = WB_MEM else '0',
            s3_mr_rd_address => EX_MEM_reg.alu_result,
            s4_pc => EX_MEM_reg.pc_plus2,
            s4_inst => x"0000",
            s4_reg_a => EX_MEM_reg.dest_reg,
            s4_r_wb => MEM_WB_reg.reg_write,
            s4_r_wb_data => w_data_rf,
            register_0 => dbg_r0,
            register_1 => dbg_r1,
            register_2 => dbg_r2,
            register_3 => dbg_r3,
            register_4 => dbg_r4,
            register_5 => dbg_r5,
            register_6 => dbg_r6,
            register_7 => dbg_r7,
            register_0_of => '0',
            register_1_of => '0',
            register_2_of => '0',
            register_3_of => '0',
            register_4_of => '0',
            register_5_of => '0',
            register_6_of => '0',
            register_7_of => '0',
            zero_flag => flag_zero,
            negative_flag => flag_neg,
            overflow_flag => flag_overflow,
            debug => debug_console,
            addr_write => EX_MEM_reg.alu_result,
            clk => clk,
            data_in => EX_MEM_reg.rd_data2,
            en_write => EX_MEM_reg.wr_en_MEM,
            board_clock => clk,
            v_sync_signal => v_sync_signal,
            h_sync_signal => h_sync_signal,
            vga_red => vga_red,
            vga_green => vga_green,
            vga_blue => vga_blue
        );

    led_display_memory : entity work.led_display
        port map(
            addr_write => EX_MEM_reg.alu_result,
            clk => clk,
            data_in => EX_MEM_reg.rd_data2,
            en_write => EX_MEM_reg.wr_en_MEM,
            board_clock => clk,
            led_segments => led_segments,
            led_digits => led_digits
        );
    -- Robin Changes End.

end Behavioral;

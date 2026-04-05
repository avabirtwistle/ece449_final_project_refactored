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
    ---------------------------------------------------------------
    signal IF_ID_reg  : IF_ID;   -- .instruction, .pc_plus2
    signal ID_EX_reg  : ID_EX;   -- .rd_data1/2, .imm, .dest_reg, .pc_plus2,
                                  -- .alu_mode, .alu_src, .wr_en_MEM, .reg_write, .wb_src
    signal EX_MEM_reg : EX_MEM;  -- .alu_result, .rd_data2, .dest_reg, .pc_plus2,
                                  -- .wr_en_MEM, .reg_write, .wb_src
    signal MEM_WB_reg : MEM_WB;  -- .alu_result, .mem_data, .dest_reg, .pc_plus2, .reg_write, .wb_src, .in_p_EN

    ---------------------------------------------------------------
    -- FETCH STAGE SIGNALS
    ---------------------------------------------------------------
    signal fetch_pc      : std_logic_vector(15 downto 0); -- current PC out of fetch
    signal fetch_instr   : std_logic_vector(15 downto 0); -- instruction out of fetch
    signal pc_mode       : std_logic_vector(1 downto 0);  -- drives fetch mode port
    signal branch_target : std_logic_vector(15 downto 0); -- address to load on branch

    ---------------------------------------------------------------
    -- CONTROLLER SIGNALS
    ---------------------------------------------------------------
    signal mode_ALU  : std_logic_vector(2 downto 0);
    signal src_ALU   : std_logic;
    signal wr_en_MEM : std_logic;
    signal wr_en_REG : std_logic;
    signal sel_WB    : std_logic_vector(1 downto 0);
    signal in_p_EN   : std_logic;
    signal out_p_EN  : std_logic;
    signal pc_src    : std_logic;
    signal pc_reset  : std_logic_vector(15 downto 0);

    ---------------------------------------------------------------
    -- REGISTER FILE SIGNALS
    ---------------------------------------------------------------
    signal r_addr0_rf : std_logic_vector(2  downto 0);
    signal r_addr1_rf : std_logic_vector(2  downto 0);
    signal r_data0_rf : std_logic_vector(15 downto 0);
    signal r_data1_rf : std_logic_vector(15 downto 0);
    signal w_addr_rf  : std_logic_vector(2  downto 0);
    signal w_data_rf  : std_logic_vector(15 downto 0);
    signal wr_en_rf   : std_logic;

    ---------------------------------------------------------------
    -- ALU SIGNALS
    ---------------------------------------------------------------
    signal alu_op2    : std_logic_vector(15 downto 0); -- mux: register vs immediate
    signal alu_result : std_logic_vector(15 downto 0);
    signal flag_zero  : std_logic;
    signal flag_neg   : std_logic;
    signal flag_carry : std_logic;

    ---------------------------------------------------------------
    -- RAM SIGNALS
    ---------------------------------------------------------------
    signal ram_ena   : std_logic;
    signal ram_wea   : std_logic_vector(0 downto 0);
    signal ram_addra : std_logic_vector(8 downto 0);
    signal ram_dina  : std_logic_vector(15 downto 0);
    signal ram_douta : std_logic_vector(15 downto 0);
    signal ram_enb   : std_logic;
    signal ram_addrb : std_logic_vector(8 downto 0);
    signal ram_doutb : std_logic_vector(15 downto 0);

    ---------------------------------------------------------------
    -- WRITE BACK SIGNALS
    ---------------------------------------------------------------
    signal wb_data      : std_logic_vector(15 downto 0);
    signal imm_extended : std_logic_vector(15 downto 0);

begin

    -- ALU source mux: '0' = register (rd_data2), '1' = immediate
    alu_op2 <= ID_EX_reg.imm when ID_EX_reg.alu_src = '1' else ID_EX_reg.rd_data2;

    -- Write-back mux: WB_ALU = ALU result, WB_MEM = memory data, WB_PC2 = return address
    wb_data <= MEM_WB_reg.mem_data when MEM_WB_reg.wb_src = WB_MEM else
               MEM_WB_reg.pc_plus2 when MEM_WB_reg.wb_src = WB_PC2 else
               MEM_WB_reg.alu_result;

    -- Register file write (from MEM/WB stage)
    w_addr_rf <= MEM_WB_reg.dest_reg;
    wr_en_rf  <= MEM_WB_reg.reg_write;
    -- IN instruction mux: if in_p_EN reached WB stage, write in_port directly to reg file
    w_data_rf <= in_port when MEM_WB_reg.in_p_EN = '1' else wb_data;


    -- TODO: RAM enable/address/write logic (memory map decode)
    -- Suggested memory map:
    --   ROM : 0x0000 - 0x007F
    --   RAM : 0x0400 - 0x07FF
    --   in_port  : 0xFFF0
    --   out_port : 0xFFF2
    ram_ena   <= '0'; -- TODO
    ram_wea   <= "0"; -- TODO
    ram_addra <= (others => '0'); -- TODO: EX_MEM_reg.alu_result(9 downto 1)
    ram_dina  <= (others => '0'); -- TODO: EX_MEM_reg.rd_data2
    ram_enb   <= '0'; -- TODO
    ram_addrb <= (others => '0'); -- TODO

    -- TODO: out_port logic (OUT instruction or memory-mapped store to 0xFFF2)
    out_port <= (others => '0'); -- placeholder

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
            if pc_src = '1' then
                -- branch taken: flush the incorrectly-fetched instruction with a NOP
                IF_ID_reg.instruction <= (others => '0');
                IF_ID_reg.pc_plus2    <= (others => '0');
            else
                IF_ID_reg.instruction <= fetch_instr;
                IF_ID_reg.pc_plus2    <= fetch_pc;
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
        elsif rising_edge(clk) then
            ID_EX_reg.rd_data1  <= r_data0_rf;
            ID_EX_reg.rd_data2  <= r_data1_rf;
            ID_EX_reg.imm       <= imm_extended;
            -- BR_SUB writes return address to R7 (link register), not Ra
            ID_EX_reg.dest_reg  <= LINK_REG when IF_ID_reg.instruction(15 downto 9) = OP_BR_SUB
                                    else IF_ID_reg.instruction(8 downto 6);
            ID_EX_reg.pc_plus2  <= IF_ID_reg.pc_plus2;
            ID_EX_reg.alu_mode  <= mode_ALU;
            ID_EX_reg.alu_src   <= src_ALU;
            ID_EX_reg.wr_en_MEM <= wr_en_MEM;
            ID_EX_reg.reg_write <= wr_en_REG;
            ID_EX_reg.wb_src    <= sel_WB;
            ID_EX_reg.in_p_EN   <= in_p_EN;
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
        elsif rising_edge(clk) then
            EX_MEM_reg.alu_result <= alu_result;
            EX_MEM_reg.rd_data2   <= ID_EX_reg.rd_data2;
            EX_MEM_reg.dest_reg   <= ID_EX_reg.dest_reg;
            EX_MEM_reg.pc_plus2   <= ID_EX_reg.pc_plus2;
            EX_MEM_reg.wr_en_MEM  <= ID_EX_reg.wr_en_MEM;
            EX_MEM_reg.reg_write  <= ID_EX_reg.reg_write;
            EX_MEM_reg.wb_src     <= ID_EX_reg.wb_src;
            EX_MEM_reg.in_p_EN    <= ID_EX_reg.in_p_EN;
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
        elsif rising_edge(clk) then
            MEM_WB_reg.alu_result <= EX_MEM_reg.alu_result;
            MEM_WB_reg.mem_data   <= ram_douta;
            MEM_WB_reg.dest_reg   <= EX_MEM_reg.dest_reg;
            MEM_WB_reg.pc_plus2   <= EX_MEM_reg.pc_plus2;
            MEM_WB_reg.reg_write  <= EX_MEM_reg.reg_write;
            MEM_WB_reg.wb_src     <= EX_MEM_reg.wb_src;
            MEM_WB_reg.in_p_EN    <= EX_MEM_reg.in_p_EN;
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
            pc_mode       => pc_mode,
            pc_reset      => pc_reset,
            branch_target => branch_target,
            branch_taken  => branch_taken
        );

    -- ALU
    u_alu : entity work.Alu
        port map (
            a           => ID_EX_reg.rd_data1,
            b           => alu_op2,
            control_sel => ID_EX_reg.alu_mode,
            result      => alu_result,
            Carry       => flag_carry,
            Zero        => flag_zero,
            Negative    => flag_neg
        );

    -- RAM
    u_ram : entity work.ram
        port map (
            clk   => clk,
            rst   => rst,
            ena   => ram_ena,
            wea   => ram_wea,
            addra => ram_addra,
            dina  => ram_dina,
            douta => ram_douta,
            enb   => ram_enb,
            addrb => ram_addrb,
            doutb => ram_doutb
        );

end Behavioral;
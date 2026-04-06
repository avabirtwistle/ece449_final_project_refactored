----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/28/2026 04:26:59 PM
-- Design Name: 
-- Module Name: top_level - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.constants_package.all;
use work.pipeline_registers.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_level_cpu is
    port(
        clk: in std_logic;
        reset: in std_logic;
        boot_mode: in std_logic;
        in_port: in std_logic_vector(15 downto 0);
        out_port: out std_logic_vector(15 downto 0)
        );
end top_level_cpu;
    
architecture Behavioral of top_level_cpu is
    -- pipeline register internal signals
    signal IF_ID_reg: IF_ID;
    signal ID_EX_reg: ID_EX;

    -- fetch stage outputs
    signal fetch_instruction: std_logic_vector(15 downto 0);
    signal fetch_pc_plus2: std_logic_vector(15 downto 0);

    -- decode stage outputs
    signal decode_rd_data1  : std_logic_vector(15 downto 0);
    signal decode_rd_data2  : std_logic_vector(15 downto 0);
    signal decode_imm       : std_logic_vector(15 downto 0);
    signal decode_dest_reg  : std_logic_vector(2 downto 0);
    signal decode_pc_plus2  : std_logic_vector(15 downto 0);

    signal decode_alu_mode  : std_logic_vector(2 downto 0);
    signal decode_alu_src   : std_logic;
    signal decode_shift_amt : std_logic_vector(3 downto 0);
    signal decode_wr_en_MEM : std_logic;
    signal decode_wr_en_REG : std_logic;
    signal decode_sel_WB    : std_logic_vector(1 downto 0);
    signal decode_in_p_EN   : std_logic;
    signal decode_out_p_EN  : std_logic;
    signal decode_pc_mode   : std_logic_vector(1 downto 0);
    signal decode_pc_reset  : std_logic;
    signal decode_branch_target: std_logic_vector(15 downto 0);
    signal exec_rd_data2   : std_logic_vector(15 downto 0);
    signal exec_dest_reg   : std_logic_vector(2 downto 0);
    signal exec_pc_plus2   : std_logic_vector(15 downto 0);
    signal exec_wr_en_MEM  : std_logic;
    signal exec_reg_write  : std_logic;
    signal exec_wb_src     : std_logic_vector(1 downto 0);
    signal exec_in_p_EN    : std_logic;
    signal exec_out_p_EN   : std_logic;
    signal exec_alu_result : std_logic_vector(15 downto 0);
    signal exec_flag_zero: std_logic;
    signal exec_flag_neg : std_logic;
    signal exec_flag_carry : std_logic;
    -- later-stage inputs back into decode
    signal write_back_wr_en : std_logic;
    signal write_back_dest  : std_logic_vector(2 downto 0);
    signal write_back_data  : std_logic_vector(15 downto 0);


    signal rom_enable: std_logic;
begin
    u_fetch: entity work.fetch
        port map(
            clk         => clk,
            reset       => reset,
            rom_ena     => rom_enable,
            mode        => decode_pc_mode,
            in_pc       => decode_branch_target,
            instruction => fetch_instruction,
            pc => fetch_pc_plus2
        );
        
    -- process for the IF_ID register
    IF_ID_proc: process(clk, reset)
        begin
            if rising_edge(clk) then
                if reset = '1' or decode_pc_mode = PC_LOAD_NEW_VAL then
                    IF_ID_reg.instruction <= (others => '0');
                    IF_ID_reg.pc_plus2 <= (others=>'0');
                    
                else -- normal operation
                    IF_ID_reg.instruction <= fetch_instruction;
                    IF_ID_reg.pc_plus2 <= fetch_pc_plus2;
                end if;
            end if;
    end process;
    
        -- component instantiation
    u_decode: entity work.decode
        port map(
            clk => clk,
            reset => reset,
    
            -- from IF/ID
            instruction  => IF_ID_reg.instruction,
            pc_plus2_in  => IF_ID_reg.pc_plus2,
    
            -- from WB stage
            wb_wr_en  => write_back_wr_en,
            wb_dest   => write_back_dest,
            wb_data   => write_back_data,
    
            -- flags / mode into controller
            flag_zero   => exec_flag_zero,
            flag_neg    => exec_flag_neg,
            boot_mode   => boot_mode,
    
            -- outputs to ID/EX
            rd_data1   => decode_rd_data1,
            rd_data2    => decode_rd_data2,
            imm         => decode_imm,
            dest_reg     => decode_dest_reg,
            pc_plus2_out => decode_pc_plus2,
            shift_amt  => decode_shift_amt,
    
            -- control outputs toward ID/EX
            alu_mode     => decode_alu_mode,
            alu_src       => decode_alu_src,
            wr_en_MEM      => decode_wr_en_MEM,
            wr_en_REG      => decode_wr_en_REG,
            sel_WB         => decode_sel_WB,
            in_p_EN         => decode_in_p_EN,
            out_p_EN       => decode_out_p_EN, -- todo determine what to do with this
    
            -- controls toward fetch
            pc_mode        => decode_pc_mode,
            branch_target   => decode_branch_target,
            pc_reset => decode_pc_reset,
            rom_enable => rom_enable
        );


    -- pipeline refister for the 
    -- ID/EX Register: latches decode/controller output into execute stage
    ID_EX_proc : process(clk, reset)
        begin
            if rising_edge(clk) then
                if reset = '1' then  
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
                    ID_EX_reg.out_p_EN <= '0';
                    ID_EX_reg.shift_amt <= (others => '0');  
                    ID_EX_reg.in_data  <= (others => '0');          
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
                    ID_EX_reg.out_p_EN <= decode_out_p_EN;
                    ID_EX_reg.shift_amt <= decode_shift_amt;  
                    ID_EX_reg.in_data  <= in_port;  
                end if;
            end if;
    end process;
    
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
        shift_amount      => ID_EX_reg.shift_amt,
--------------OUTPUTS to ex/mem---------------------------------

        alu_result        => exec_alu_result,
        rd_data2_out      => exec_rd_data2,
        dest_reg_out      => exec_dest_reg,
        pc_plus2_out      => exec_pc_plus2,

        wr_en_MEM_out     => exec_wr_en_MEM,
        reg_write_out     => exec_reg_write,
        wb_src_out        => exec_wb_src,
        in_p_EN_out       => exec_in_p_EN,
        out_p_EN_out      => exec_out_p_EN,
        flag_zero_out     => exec_flag_zero,
        flag_negative_out => exec_flag_neg,
        flag_carry_out    => exec_flag_carry
    );
end Behavioral;

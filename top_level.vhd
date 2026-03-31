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
    signal IF_ID_reg: IF_ID; -- pipeline register between the fetch stage and the decode stage
    signal ID_EX_reg: ID_EX; -- pipeline register between the decode and execute stage
    
    signal fetch_instruction: std_logic_vector(15 downto 0);
    signal fetch_pc_plus2: std_logic_vector(15 downto 0);
    
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
    signal decode_pc_mode  : std_logic_vector(1 downto 0);
    signal decode_pc_reset  : std_logic;
    signal decode_branch_target: std_logic_vector(15 downto 0);
    signal write_back_wr_en: std_logic;
    signal write_back_dest: std_logic_vector(2 downto 0);
    signal write_back_data: std_logic_vector(15 downto 0);
    signal execute_flag_zero: std_logic;
    signal execute_flag_neg: std_logic;

    
    
begin
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
            instruction => fetch_instruction, -- insrr
            pc_plus2_in  => fetch_pc_plus2,
    
            -- from WB stage
            wb_wr_en  => write_back_wr_en,
            wb_dest   => write_back_dest,
            wb_data   => write_back_data,
    
            -- flags / mode into controller
            flag_zero   => execute_flag_zero,
            flag_neg    => execute_flag_neg,
            boot_mode   => boot_mode,
    
            -- outputs to ID/EX
            rd_data1   => decode_rd_data1,
            rd_data2    => decode_rd_data2,
            imm         => decode_imm,
            dest_reg     => decode_dest_reg,
            pc_plus2_out   => fetch_pc_plus2,
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
            pc_reset => decode_pc_reset
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
                    ID_EX_reg.shift_amt <= (others => '0');           
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
                    ID_EX_reg.shift_amt <= decode_shift_amt;  
                end if;
            end if;
    end process;
    
end Behavioral;


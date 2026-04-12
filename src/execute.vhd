----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/28/2026 11:49:37 AM
-- Design Name: 
-- Module Name: execute - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

use work.constants_package.all;
use work.pipeline_registers.all;  

entity execute is
 port(

       -- from WB stage -- ride alongs?  we should have this in the top level
    --   wb_wr_en      : in  std_logic;
   --    wb_dest       : in  std_logic_vector(2 downto 0);
   --    wb_data       : in  std_logic_vector(15 downto 0);

         -- from ID/EX pipeline register
        rd_data1   : in std_logic_vector(15 downto 0);
        rd_data2   : in std_logic_vector(15 downto 0);
        imm        : in std_logic_vector(15 downto 0);
        dest_reg   : in std_logic_vector(2 downto 0);
        pc_plus2   : in std_logic_vector(15 downto 0);
        
        alu_mode   : in std_logic_vector(2 downto 0);
        alu_src    : in std_logic;
        wr_en_MEM  : in std_logic;
        reg_write  : in std_logic;
        wb_src     : in std_logic_vector(1 downto 0);
        in_p_EN    : in std_logic; -- think should be ride along
        out_p_EN   : in std_logic; -- think should be ride along
        shift_amount: in  std_logic_vector(3 downto 0) ;                                

        -- outputs to EX/MEM pipeline register
        alu_result : out std_logic_vector(15 downto 0);
        rd_data2_out : out std_logic_vector(15 downto 0);
        dest_reg_out : out std_logic_vector(2 downto 0);
        pc_plus2_out : out std_logic_vector(15 downto 0);
        
        wr_en_MEM_out : out std_logic;
        reg_write_out : out std_logic;
        wb_src_out    : out std_logic_vector(1 downto 0);
        in_p_EN_out   : out std_logic; -- shouldnt these just be ridealongs? do i need thsee?
        out_p_EN_out  : out std_logic; -- shouldnt these just be ridealongs? 
        flag_zero_out     : out std_logic; 
        flag_negative_out : out std_logic; 
        flag_carry_out    : out std_logic;
        flag_overflow_out : out std_logic 
    );                                  
end execute;

architecture Behavioral of execute is
    -- Internal input signals to the ALU 
    signal source_1_data_internal : std_logic_vector(15 downto 0); 
    signal source_2_data_internal : std_logic_vector(15 downto 0);

    -- internal output signals from the ALU
    signal result_internal        : std_logic_vector(15 downto 0);
    signal flag_zero_internal     : std_logic;
    signal flag_negative_internal : std_logic;
    signal flag_carry_internal    : std_logic;
    signal flag_overflow_internal : std_logic;
    signal shift_amount_internal  : std_logic_vector(3 downto 0);
begin
    source_1_data_internal <= rd_data1; -- connect input data 1 to the internal signal 
    source_2_data_internal <= rd_data2 when alu_src = '0' else imm;  -- map the input data2 to  register data 2 when alu_src = '0'otherwise use the immediate value

    -- instantiate the ALU
    u_alu : entity work.Alu
        port map(
            shift_amount => shift_amount_internal,
            a           => source_1_data_internal,
            b           => source_2_data_internal,
            result      => result_internal,
            control_sel => alu_mode, -- direct connection
            Carry       => flag_carry_internal,
            Zero        => flag_zero_internal,
            Negative    => flag_negative_internal,
            Overflow    => flag_overflow_internal
        );
    -- output to the EX/MEM pipeline register
    rd_data2_out  <= rd_data2;     -- needed later for STORE instructions
    dest_reg_out  <= dest_reg; 
    pc_plus2_out  <= pc_plus2;
    wr_en_MEM_out <= wr_en_MEM;
    reg_write_out <= reg_write;
    wb_src_out    <= wb_src;
    in_p_EN_out   <= in_p_EN;
    out_p_EN_out  <= out_p_EN;

    -- map the internal signals set by the ALU to the outputs accessible in top level
    flag_zero_out     <= flag_zero_internal;
    flag_negative_out <= flag_negative_internal;
    flag_carry_out    <= flag_carry_internal;
    flag_overflow_out <= flag_overflow_internal;
    alu_result    <= result_internal;
end Behavioral;
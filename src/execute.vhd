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
use work.pipeline_registers.all;  -- gives IF_ID, ID_EX, EX_MEM record types

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity execute is
 port(

       -- from WB stage -- ride alongs?  we should have this in the top level
    --   wb_wr_en      : in  std_logic;
   --    wb_dest       : in  std_logic_vector(2 downto 0);
   --    wb_data       : in  std_logic_vector(15 downto 0);

----------INPUTS from id/ex ---------------------------------------
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
        shift_amount: in  std_logic_vector(3 downto 0) ;                                  -- two flags could occur at the same time.

--------------OUTPUTS to ex/mem---------------------------------

        alu_result : out std_logic_vector(15 downto 0);
        rd_data2_out : out std_logic_vector(15 downto 0);
        dest_reg_out : out std_logic_vector(2 downto 0);
        pc_plus2_out : out std_logic_vector(15 downto 0);
        
        wr_en_MEM_out : out std_logic;
        reg_write_out : out std_logic;
        wb_src_out    : out std_logic_vector(1 downto 0);
        in_p_EN_out   : out std_logic; -- shouldnt these just be ridealongs? do i need thsee?
        out_p_EN_out  : out std_logic; -- shouldnt these just be ridealongs? 
        flag_zero_out     : out std_logic; -- I feel like the flags should be just a 2 bit number to tell which flag is selected
        flag_negative_out : out std_logic; -- 00 = no flags, 01 = zero out, 10 = negative out 11 = carry out, but i guess we can 
        flag_carry_out    : out std_logic -- the only thing stopping me from doing this is if there is a case when 

   );
end execute;

architecture Behavioral of execute is

    -- Internal ALU signals
    signal source_1_data_internal : std_logic_vector(15 downto 0);
    signal source_2_data_internal : std_logic_vector(15 downto 0);
    signal result_internal        : std_logic_vector(15 downto 0);
    signal control_sel_internal   : std_logic_vector(2 downto 0);

    signal flag_zero_internal     : std_logic;
    signal flag_negative_internal : std_logic;
    signal flag_carry_internal    : std_logic;
    signal shift_amount_internal    : std_logic_vector(3 downto 0);
begin

    ------------------------------------------------------------------------
    -- Combinational input selection for ALU
    ------------------------------------------------------------------------
    source_1_data_internal <= rd_data1;

    -- alu_src = '0' -> use register operand
    -- alu_src = '1' -> use immediate
    source_2_data_internal <= rd_data2 when alu_src = '0' else imm;

    control_sel_internal <= alu_mode;

    ------------------------------------------------------------------------
    -- ALU instance
    ------------------------------------------------------------------------
    u_alu : entity work.Alu
        port map(
            shift_amount => shift_amount_internal,
            a           => source_1_data_internal,
            b           => source_2_data_internal,
            result      => result_internal,
            control_sel => control_sel_internal,
            Carry       => flag_carry_internal,
            Zero        => flag_zero_internal,
            Negative    => flag_negative_internal
        );

    ------------------------------------------------------------------------
    -- Outputs to EX/MEM
    ------------------------------------------------------------------------
    alu_result    <= result_internal;
    rd_data2_out  <= rd_data2;     -- needed later for STORE instructions
    dest_reg_out  <= dest_reg;
    pc_plus2_out  <= pc_plus2;

    wr_en_MEM_out <= wr_en_MEM;
    reg_write_out <= reg_write;
    wb_src_out    <= wb_src;
    in_p_EN_out   <= in_p_EN;
    out_p_EN_out  <= out_p_EN;

    ------------------------------------------------------------------------
    -- Flag outputs
    ------------------------------------------------------------------------
    flag_zero_out     <= flag_zero_internal;
    flag_negative_out <= flag_negative_internal;
    flag_carry_out    <= flag_carry_internal;

end Behavioral;
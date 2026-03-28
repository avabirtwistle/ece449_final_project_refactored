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

use work.constant_package.all;
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
       clk           : in  std_logic;
       reset         : in  std_logic;

       -- from IF/ID
       instruction   : in  std_logic_vector(15 downto 0);
       pc_plus2_in   : in  std_logic_vector(15 downto 0); -- dont think i need this. 

       -- from WB stage -- ride alongs? 
       wb_wr_en      : in  std_logic;
       wb_dest       : in  std_logic_vector(2 downto 0);
       wb_data       : in  std_logic_vector(15 downto 0);

       -- flags / mode into controller
       flag_zero     : in  std_logic;
       flag_neg      : in  std_logic;
       boot_mode     : in  std_logic;

       -- inputs to ID/EX
       rd_data1      : in std_logic_vector(15 downto 0);
       rd_data2      : in std_logic_vector(15 downto 0);
       imm           : in std_logic_vector(15 downto 0);
       dest_reg      : in std_logic_vector(2 downto 0);
       pc_plus2_out  : in std_logic_vector(15 downto 0);
       shift_amt     : in std_logic_vector(3 downto 0); 

       -- control outputs toward EX/MEM -- MAYBE REMOVE THIS
       alu_mode      : in std_logic_vector(2 downto 0);
       alu_src       : in std_logic;
       wr_en_MEM     : in std_logic;
       wr_en_REG     : in std_logic;
       sel_WB        : in std_logic_vector(1 downto 0);
       in_p_EN       : in std_logic;
       out_p_EN      : in std_logic;

       -- controls toward fetch
       pc_mode       : out std_logic_vector(1 downto 0);
       branch_target : out std_logic_vector(15 downto 0);
       branch_taken  : out std_logic;
       pc_reset: out std_logic
   );
end execute;

architecture Behavioral of execute is
  --- USE OF THE "_internal" mean is its execute stage signals 
    signal rst                          : std_logic;

    --PIPLINE REGISTERS: 
    signal EX_MEM_reg : EX_MEM;-- .alu_result, .rd_data2, .dest_reg, .pc_plus2,
                                      -- .wr_en_MEM, .reg_write, .wb_src
 
    signal dest_reg_internal            : std_logic_vector(2 downto 0); -- Maps to EX_MEM_reg.dest_reg 
    signal pc_plus2_out_internal        : std_logic_vector(15 downto 0); -- Maps to EX_MEM_reg.pc_plus2
    signal wr_en_MEM_internal           : std_logic; 
    signal wr_en_REG_internal           : std_logic;
    signal sel_WB_internal              : std_logic_vector(1 downto 0); -- We might need to change this to 2 downto 0 i forget why
    signal in_p_EN_internal             : std_logic;
    signal out_p_EN_internal            : std_logic;
    
    -- ALU SIGNALS
    signal source_1_data_internal       : std_logic_vector(15 downto 0); -- Maps to a of the ALU
    signal source_2_data_internal       : std_logic_vector(15 downto 0); -- Maps to b of the ALU  
    signal result_internal              : std_logic_vector(15 downto 0); -- Maps to result of the ALU
    signal control_sel_internal         : std_logic_vector(2 downto 0); -- Maps to control_sel of the ALU
    signal flag_zero_internal           : std_logic; -- Maps to Zero of ALU
    signal flag_negative_internal       : std_logic; -- Maps to Negative of ALU
    signal flag_carry_internal          : std_logic; -- Maps to carry of ALU 
    
begin
    reset => rst

    u_alu: entity work.Alu
        port map(
        
            a           =>  source_1_data_internal, 
            b           =>  source_2_data_internal,  
            result      =>  result_internal,  
            control_sel =>  control_sel_internal, 
            Carry       =>  flag_carry_internal, 
            Zero        =>  flag_zero_internal,
            Negative    =>  flag_negative_internal

        );
     alu_proc : process(source_1_data_internal,
                        source_2_data_internal,
                        control_sel_internal)
           begin
                if rst = '1' then
                
              
        
     EX_MEM_proc : process(clk, rst)
           begin
               if rst = '1' then
                   EX_MEM_reg.alu_result <= (others => '0');
                   EX_MEM_reg.rd_data2   <= (others => '0');
                   EX_MEM_reg.dest_reg   <= (others => '0');
                   EX_MEM_reg.pc_plus2   <= (others => '0');
                   EX_MEM_reg.wr_en_MEM  <= '0';
                   EX_MEM_reg.reg_write  <= '0';
                   EX_MEM_reg.wb_src     <= WB_ALU; -- Maybe change this.
                   EX_MEM_reg.in_p_EN    <= '0';
               elsif rising_edge(clk) then
                   EX_MEM_reg.alu_result <= result_internal;
                  -- EX_MEM_reg.rd_data2   <= ID_EX_reg.rd_data2; -- Not sure what to pass this yet. Maybe IMM?
                   EX_MEM_reg.dest_reg   <= dest_reg_internal;
                   EX_MEM_reg.pc_plus2   <= pc_plus2_out_internal;
                   EX_MEM_reg.wr_en_MEM  <= wr_en_MEM_internal ;
                   EX_MEM_reg.reg_write  <= wr_en_REG_internal;
                   EX_MEM_reg.wb_src     <= sel_WB_internal;
                   EX_MEM_reg.in_p_EN    <= in_p_EN_internal;
                   EX_MEM_reg.out_p_EN   <= out_p_EN_internal                
               end if;
           end process;

end Behavioral;

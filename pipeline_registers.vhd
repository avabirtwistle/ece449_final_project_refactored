library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pipeline_registers is

    type IF_ID is record
        instruction : std_logic_vector(15 downto 0); -- the binary code instrcution which was fetched from instruction memory
        pc_plus2       : std_logic_vector(15 downto 0);
    end record;


    type ID_EX is record
        rd_data1  : std_logic_vector(15 downto 0); -- obtained from rd_index1
        rd_data2  : std_logic_vector(15 downto 0); -- obtained from rd_index2
        imm       : std_logic_vector(15 downto 0); -- immediate value
        dest_reg  : std_logic_vector(2 downto 0); --destination register index
        pc_plus2  : std_logic_vector(15 downto 0);

        alu_mode  : std_logic_vector(2 downto 0); -- selects mode of ALU
        alu_src   : std_logic; -- decides saving to RAM or pass along // Are we sure? I think it should select whether its IMM or Rd_data2

        -- Memory control signals (riding along to MEM)
        wr_en_MEM : std_logic;

        -- Write-back control signals (riding along to WB)
        reg_write : std_logic;
        wb_src    : std_logic_vector(1 downto 0);
        in_p_EN   : std_logic;
        out_p_EN  : std_logic; 
        shift_amt : std_logic_vector(3 downto 0); 
    end record;

    type EX_MEM is record
        alu_result : std_logic_vector(15 downto 0); -- ALU computed result
        rd_data2   : std_logic_vector(15 downto 0); -- store data (STORE @addr, rd_data2)
        dest_reg   : std_logic_vector(2  downto 0); -- destination register index (rd)
        pc_plus2   : std_logic_vector(15 downto 0); -- PC+2 (for BRL return address)

        --  Memory control signals (consumed in MEM) 
        wr_en_MEM  : std_logic;

        -- Write-back control signals (riding along to WB)
        reg_write  : std_logic;                     -- '1' = write to reg file
        wb_src     : std_logic_vector(1 downto 0); -- select write-back source
        in_p_EN    : std_logic;
        out_p_EN   : std_logic;
        
    end record;

    type MEM_WB is record
        alu_result : std_logic_vector(15 downto 0); -- ALU computed result from EX/MEM
        mem_data   : std_logic_vector(15 downto 0); -- data returned from RAM
        dest_reg   : std_logic_vector(2 downto 0);  -- destination register index
        pc_plus2   : std_logic_vector(15 downto 0); -- PC+2 (for BRL return address)

        -- Write-back control signals (consumed in WB) 
        reg_write  : std_logic;                     -- '1' = write to reg file
        wb_src     : std_logic_vector(1 downto 0); -- select write-back source
        in_p_EN    : std_logic;
        out_p_EN   : std_logic;
    end record;

end package pipeline_registers;

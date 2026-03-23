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
        alu_src   : std_logic; -- decides saving to RAM or pass along

        -- ── Memory control signals (riding along to MEM) ───
        wr_en_MEM : std_logic;

        -- ── Write-back control signals (riding along to WB) ─
        reg_write : std_logic;
        wb_src    : std_logic;
    end record;

    type EX_MEM is record
        alu_result : std_logic_vector(15 downto 0); -- ALU computed result
        rd_data2   : std_logic_vector(15 downto 0); -- store data (STORE @addr, rd_data2)
        dest_reg   : std_logic_vector(2  downto 0); -- destination register index (ra)
        pc_plus2   : std_logic_vector(15 downto 0); -- PC+2 (for BRL return address)

        -- ── Memory control signals (consumed in MEM - used for write to RAM) ───────
        wr_en_MEM  : std_logic;

        -- ── Write-back control signals (riding along to WB) ─
        reg_write  : std_logic;                     -- '1' = write to reg file
        wb_src     : std_logic;                     -- '0'=ALU result, '1'=mem data

    end record;
    
    type MEM_WB is record 
    
        alu_result : std_logic_vector(15 downto 0);
        rd_data2   : std_logic_vector(15 downto 0;
        dest_reg   : std_logic_vector(15 downto 0);
        pc_plus2   : std_logic_vector(15 downto 0);
        
        reg_write  : std_logic; --Consumed at this stage; 
        wb_src     : std_logic; --Consumed at this stage;
        
    end record; 


end package pipeline_registers;
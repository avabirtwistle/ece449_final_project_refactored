library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constant_package.all;

entity decode is
    port(
        clk           : in  std_logic;
        reset         : in  std_logic;

        -- from IF/ID
        instruction    : in  std_logic_vector(15 downto 0);
        pc   : in  std_logic_vector(15 downto 0);

        -- from WB stage back into reg file (ignore for now)
        -- wb_wr_en      : in  std_logic;
        -- wb_dest       : in  std_logic_vector(2 downto 0);
       -- wb_data       : in  std_logic_vector(15 downto 0);

        -- optional flags into controller for branches (ignored for now)
        -- flag_zero     : in  std_logic;
        -- flag_neg      : in  std_logic;
        -- boot_mode     : in  std_logic;

        -- outputs to ID/EX
        rd_data1  : out std_logic_vector(15 downto 0); -- the operand register 1
        rd_data2  : out std_logic_vector(15 downto 0); -- the operand register 2
        imm       : out std_logic_vector(15 downto 0); -- the immediate value (after sign extension)
        dest_reg  : out std_logic_vector(2 downto 0); -- the index of the destination register
        pc  : out std_logic_vector(15 downto 0); -- the program counter value (for branch target calculation and BRL return address)

        -- control outputs toward ID/EX
        alu_mode  : out std_logic_vector(2 downto 0);
        alu_src   : out std_logic;

        -- controls the program counter in the fetch stage ?
        pc_mode    : out std_logic; -- set by controller ?
        pc_reset  : out std_logic_vector(15 downto 0)
   
        -- wr_en_MEM : out std_logic;
        -- wr_en_REG : out std_logic;
        --  sel_WB    : out std_logic;
        --  in_p_EN   : out std_logic;
        -- out_p_EN  : out std_logic;
        );
end decode;

architecture Behavioral of decode is

begin

        u_decoder : entity work.decoder
            port map(
                instruction => instruction, -- input
                opcode      => opcode, -- opcode needed for controller
                destination_reg => destination_reg, -- index for register a
                source_1 => source_1, -- index for register b
                source_2 => source_2, -- index for register c
                shift_amount => shift_amount, -- the amount to shift
                disp_long   => disp_long, -- the long displacement for branch instructions
                disp_short  => disp_short -- the short displacement for branch instructions
            );

        u_regfile : entity work.register_file
            port map(
                clk     => clk,
                reset   => reset,
                wr_en   => wb_wr_en,
                w_addr  => destination_reg,
                w_data  => wb_data,
                r_addr0 => source_1, -- the address for register b
                r_addr1 => source_2, -- address for register c (for R-type instructions) or the destination register (for I-type instructions)
                r_data0 => source_1_data,
                r_data1 => source_2_data
            );

        out_rd_data1 <= source_1_data;
        out_rd_data2 <= source_2_data;
        out_imm      <= imm_ext;
        out_dest_reg <= destination_reg;
        out_pc_plus2 <= pc;
    end Behavioral;

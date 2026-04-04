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
        in_instr      : in  std_logic_vector(15 downto 0);
        in_pc_plus2   : in  std_logic_vector(15 downto 0);

        -- from WB stage back into reg file
        wb_wr_en      : in  std_logic;
        wb_dest       : in  std_logic_vector(2 downto 0);
        wb_data       : in  std_logic_vector(15 downto 0);

        -- optional flags into controller for branches
        flag_zero     : in  std_logic;
        flag_neg      : in  std_logic;
        boot_mode     : in  std_logic;

        -- outputs to ID/EX
        out_rd_data1  : out std_logic_vector(15 downto 0);
        out_rd_data2  : out std_logic_vector(15 downto 0);
        out_imm       : out std_logic_vector(15 downto 0);
        out_dest_reg  : out std_logic_vector(2 downto 0);
        out_pc_plus2  : out std_logic_vector(15 downto 0);

        -- control outputs toward ID/EX
        out_alu_mode  : out std_logic_vector(2 downto 0);
        out_alu_src   : out std_logic;
        out_wr_en_MEM : out std_logic;
        out_wr_en_REG : out std_logic;
        out_sel_WB    : out std_logic;
        out_in_p_EN   : out std_logic;
        out_out_p_EN  : out std_logic;
        out_pc_src    : out std_logic;
        out_pc_reset  : out std_logic_vector(15 downto 0)
    );
end decode;

architecture Behavioral of decode is
    signal opcode      : std_logic_vector(6 downto 0);
    signal ra          : std_logic_vector(2 downto 0);
    signal rb          : std_logic_vector(2 downto 0);
    signal rc          : std_logic_vector(2 downto 0);

    signal r_data0_rf  : std_logic_vector(15 downto 0);
    signal r_data1_rf  : std_logic_vector(15 downto 0);

    signal imm_ext     : std_logic_vector(15 downto 0);
begin
    opcode <= in_instr(15 downto 9);
    ra     <= in_instr(8 downto 6);
    rb     <= in_instr(5 downto 3);
    rc     <= in_instr(2 downto 0);

    imm_ext <= std_logic_vector(resize(signed(in_instr(5 downto 0)), 16));

    u_regfile : entity work.register_file
        port map(
            clk     => clk,
            reset   => reset,
            wr_en   => wb_wr_en,
            w_addr  => wb_dest,
            w_data  => wb_data,
            r_addr0 => rb,
            r_addr1 => rc,
            r_data0 => r_data0_rf,
            r_data1 => r_data1_rf
        );

    out_rd_data1 <= r_data0_rf;
    out_rd_data2 <= r_data1_rf;
    out_imm      <= imm_ext;
    out_dest_reg <= ra;
    out_pc_plus2 <= pc;
end Behavioral;

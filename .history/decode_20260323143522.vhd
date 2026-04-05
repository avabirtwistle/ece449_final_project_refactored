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
        instruction   : in  std_logic_vector(15 downto 0);
        pc_plus2_in   : in  std_logic_vector(15 downto 0);

        -- from WB stage
        wb_wr_en      : in  std_logic;
        wb_dest       : in  std_logic_vector(2 downto 0);
        wb_data       : in  std_logic_vector(15 downto 0);

        -- flags / mode into controller
        flag_zero     : in  std_logic;
        flag_neg      : in  std_logic;
        boot_mode     : in  std_logic;

        -- outputs to ID/EX
        rd_data1      : out std_logic_vector(15 downto 0);
        rd_data2      : out std_logic_vector(15 downto 0);
        imm           : out std_logic_vector(15 downto 0);
        dest_reg      : out std_logic_vector(2 downto 0);
        pc_plus2_out  : out std_logic_vector(15 downto 0);

        -- control outputs toward ID/EX
        alu_mode      : out std_logic_vector(2 downto 0);
        alu_src       : out std_logic;
        wr_en_MEM     : out std_logic;
        wr_en_REG     : out std_logic;
        sel_WB        : out std_logic_vector(1 downto 0);
        in_p_EN       : out std_logic;
        out_p_EN      : out std_logic;

        -- controls toward fetch
        pc_mode       : out std_logic_vector(1 downto 0);
        pc_reset      : out std_logic_vector(15 downto 0);
        branch_target : out std_logic_vector(15 downto 0)
    );
end decode;


architecture Behavioral of decode is
    signal opcode_internal          : std_logic_vector(6 downto 0);
    signal source_1_internal        : std_logic_vector(2 downto 0);
    signal source_2_internal        : std_logic_vector(2 downto 0);
    signal destination_reg_internal : std_logic_vector(2 downto 0);
    signal shift_amount_internal    : std_logic_vector(3 downto 0);
    signal disp_long_internal       : std_logic_vector(8 downto 0);
    signal disp_short_internal      : std_logic_vector(5 downto 0);

    signal source_1_data            : std_logic_vector(15 downto 0);
    signal source_2_data            : std_logic_vector(15 downto 0);

    signal r_addr0_sel              : std_logic_vector(2 downto 0);
    signal r_addr1_sel              : std_logic_vector(2 downto 0);

    signal pc_src_internal          : std_logic;
begin

        u_decoder : entity work.decoder
            port map(
                instruction => instruction, -- input
                opcode      => opcode_internal, -- opcode needed for controller
                destination_reg => destination_reg_internal, -- index for register a
                source_1 => source_1_internal, -- index for register b
                source_2 => source_2_internal, -- index for register c
                shift_amount => shift_amount_internal, -- the amount to shift
                disp_long   => disp_long_internal, -- the long displacement for branch instructions
                disp_short  => disp_short_internal -- the short displacement for branch instructions
            );

         -- RETURN reads the link register instead of the normal Ra field.
        r_addr0_sel <= LINK_REGISTER when opcode_internal = OP_RETURN else source_1_internal;
        r_addr1_sel <= source_2_internal;

        u_regfile : entity work.register_file
            port map(
                clk     => clk,
                reset   => reset,
                wr_en   => wb_wr_en,
                w_addr  => wb_dest,
                w_data  => wb_data,
                r_addr0 => r_addr0_sel,
                r_addr1 => r_addr1_sel,
                r_data0 => source_1_data,
                r_data1 => source_2_data
            );

        u_controller : entity work.controller
            port map(
                clk       => clk,
                reset     => reset,
                opcode    => opcode_internal,
                flag_zero => flag_zero,
                flag_neg  => flag_neg,
                boot_mode => boot_mode,
                mode_ALU  => alu_mode,
                src_ALU   => alu_src,
                wr_en_MEM => wr_en_MEM,
                wr_en_REG => wr_en_REG,
                sel_WB    => sel_WB,
                in_p_EN   => in_p_EN,
                out_p_EN  => out_p_EN,
                pc_src    => pc_src_internal,
                pc_reset  => pc_reset
            );

    process(
            opcode_internal,
            destination_reg_internal,
            shift_amount_internal,
            disp_long_internal,
            disp_short_internal,
            source_1_data,
            source_2_data,
            pc_plus2_in,
            pc_src_internal
        )    
    begin
            rd_data1      <= source_1_data;
            rd_data2      <= source_2_data;
            imm           <= (others => '0');
            dest_reg      <= destination_reg_internal;
            pc_plus2_out  <= pc_plus2_in;
            branch_target <= source_1_data;
            pc_mode       <= PC_INCREMENT;

        case opcode_i is
            when OP_NOP =>
                null;

            when OP_ADD | OP_SUB | OP_MUL | OP_NAND =>
                alu_src <= '0';

            when OP_SHL | OP_SHR =>
                alu_src <= '1';
                imm <= std_logic_vector(resize(unsigned(shift_amount_i), 16));

            when OP_TEST | OP_OUT | OP_IN =>
                null;

            when OP_BRR | OP_BRR_N | OP_BRR_Z =>
                imm <= std_logic_vector(resize(signed(disp_long_i), 16));

            when OP_BR | OP_BR_N | OP_BR_Z | OP_BR_SUB =>
                imm <= std_logic_vector(resize(signed(disp_short_i), 16));

            when OP_RETURN =>
                null;

            when others =>
                null;
        end case;
    end process;

    end Behavioral;

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
        wb_wr_en      : in  std_logic;
        wb_dest       : in  std_logic_vector(2 downto 0);
        wb_data       : in  std_logic_vector(15 downto 0);

        --  flags into controller for branches (ignored for now)
        flag_zero     : in  std_logic;
        flag_neg      : in  std_logic;
        boot_mode     : in  std_logic;

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
    signal opcode_internal : std_logic_vector(6 downto 0);
    signal source_1_internal : std_logic_vector(2 downto 0);
    signal source_2_internal : std_logic_vector(2 downto 0);
    signal destination_reg_internal : std_logic_vector(2 downto 0);
    signal shift_amount_internal : std_logic_vector(3 downto 0);
    signal disp_long_internal : std_logic_vector(8 downto 0);
    signal disp_short_internal : std_logic_vector(5 downto 0);

    signal source_1_data     : std_logic_vector(15 downto 0);
    signal source_2_data     : std_logic_vector(15 downto 0);
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

        u_regfile : entity work.register_file
        port map(
            clk     => clk,
            reset   => reset,
            wr_en   => wb_wr_en,
            w_addr  => wb_dest,
            w_data  => wb_data,
            r_addr0 => source_1_i,
            r_addr1 => source_2_i,
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
            mode_ALU  => mode_ALU_internal,
            src_ALU   => src_ALU_internal,
            wr_en_MEM => wr_en_MEM_internal,
            wr_en_REG => wr_en_REG_internal,
            sel_WB    => sel_WB_internal,
            in_p_EN   => in_p_EN_internal,
            out_p_EN  => out_p_EN_internal,
            pc_src    => pc_src_internal,
            pc_reset  => pc_reset_internal
        );

    process(opcode_i, destination_reg_i, shift_amount_i, disp_long_i, disp_short_i, source_1_data, source_2_data, in_pc)
    begin
        -- defaults
        rd_data1 <= source_1_data;
        rd_data2 <= source_2_data;
        imm      <= (others => '0');
        dest_reg <= destination_reg_i;
        out_pc   <= in_pc;

        alu_mode <= (others => '0');
        alu_src  <= '0';
        pc_mode  <= PC_INCREMENT;
        pc_reset <= (others => '0');

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

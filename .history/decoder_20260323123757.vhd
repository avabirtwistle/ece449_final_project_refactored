library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constant_package.all;

entity decoder is
    port(
        clk           : in  std_logic;
        reset         : in  std_logic;

        -- from IF/ID
        instruction    : in  std_logic_vector(15 downto 0);
        pc   : in  std_logic_vector(15 downto 0);

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
        );
end decoder;

architecture Behavioral of decoder is
    signal opcode      : std_logic_vector(6 downto 0);
    signal ra          : std_logic_vector(2 downto 0);
    signal rb          : std_logic_vector(2 downto 0);
    signal rc          : std_logic_vector(2 downto 0);

    signal r_data0_rf  : std_logic_vector(15 downto 0);
    signal r_data1_rf  : std_logic_vector(15 downto 0);

    signal imm_ext     : std_logic_vector(15 downto 0);
begin
    opcode <= instruction(15 downto 9); -- the opcode is always the top 7 bits of the instruction, but we will only use the top 4 bits for our instruction set (see constant_package.vhd)
    process(instruction) -- only needs to run when the INSTUCTION changes, but it doesn't matter if it runs more often than that
        begin
            case opcode is 
                when OP_NOP -- format A0
                    pc_mode <= PC_INCREMENT; -- TODO: should controler just deal with it ?
                
                when OP_ADD | OP_SUB | OP_MUL | OP_NAND -- A1 Format
                    ra<= instruction(8 downto 6); -- index for ra
                    rb<= instruction(5 downto 3); -- index for rb
                    rc<= instruction(2 downto 0); -- index for rc

                when OP_SHL | OP_SHR -- A2 Format
                    ra <= instruction(8 downto 6);
                    shift_amount <= instruction(3 downto 0);

                when OP_TEST | OP_OUT | OP_IN -- A3 Format
                    ra<= instruction(8 downto 6);

            -- TODO: how to deal with the PC mode ? signal needs to be sent to fetch stage
                when OP_BRR | OP_BRR_N | OP_BRR_Z -- B1 format
                    disp_long <= instruction(8 downto 0);
                when OP_BR | OP_BR_N | OP_BR_Z | OP_BR_SUB | OP_RETURN -- format b2
                    ra<= instruction(8 downto 6);
                    disp_short <= instruction(5 downto 0);
            end case;
    end process;
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

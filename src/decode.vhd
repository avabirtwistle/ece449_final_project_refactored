library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants_package.all;

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
        flag_carry    : in  std_logic;
        boot_mode     : in  std_logic; -- this is fed through the top level

        --*********** ID/EX  ***********
        -- data outputs
        rd_data1      : out std_logic_vector(15 downto 0); -- value read from RF for source 1
        rd_data2      : out std_logic_vector(15 downto 0); -- value read from RF for source 2
        imm           : out std_logic_vector(15 downto 0); -- immediate value
        dest_reg      : out std_logic_vector(2 downto 0); -- the index of the register to write
        pc_plus2_out  : out std_logic_vector(15 downto 0); 
        shift_amt     : out std_logic_vector(3 downto 0); -- sent to ALU
        -- control outputs
        alu_mode      : out std_logic_vector(2 downto 0);
        alu_src       : out std_logic;
        wr_en_MEM     : out std_logic;
        wr_en_REG     : out std_logic;
        sel_WB        : out std_logic_vector(1 downto 0);
        in_p_EN       : out std_logic;
        out_p_EN      : out std_logic;

        -- controls toward fetch
        pc_mode       : out std_logic_vector(1 downto 0);
        branch_target : out std_logic_vector(15 downto 0);
        pc_reset: out std_logic;
        rom_enable: out std_logic;

        -- outputs for hazard detection
        src1_reg      : out std_logic_vector(2 downto 0);
        src2_reg      : out std_logic_vector(2 downto 0);
        src1_used     : out std_logic; -- denotes if source 1 reg is used
        src2_used     : out std_logic -- denotes if source 2 reg is used
    );
end decode;


architecture Behavioral of decode is
    signal opcode_internal          : std_logic_vector(6 downto 0);
    signal source_1_internal        : std_logic_vector(2 downto 0); -- index mapped between the decoder component and the register file
    signal source_2_internal        : std_logic_vector(2 downto 0); -- index mapped between the decoder component and the register file
    signal rd_data1_internal            : std_logic_vector(15 downto 0); -- needed for output and branch calculation
    signal rd_data2_internal            : std_logic_vector(15 downto 0); -- needed for output and branch calculation
    signal pc_mode_internal          : std_logic_vector(1 downto 0); -- we need to read this in a process and also output the mode to fetch
    signal disp: signed(15 downto 0);
    signal pc_plus2_internal         : std_logic_vector(15 downto 0);
begin

        u_decoder : entity work.decoder
            port map(
                instruction => instruction, -- input
                opcode      => opcode_internal, -- opcode needed for controller
                destination_reg => dest_reg, -- index for register a, sent to the register file
                source_1 => source_1_internal, -- index for register b, sent to the register file
                source_2 => source_2_internal, -- index for register c, sent to the register file
                shift_amt => shift_amt, -- the amount to shift
                disp => disp
            );

        u_regfile : entity work.register_file
            port map(
                clk     => clk,
                reset   => reset,
                wr_en   => wb_wr_en,
                w_addr  => wb_dest,
                w_data  => wb_data,
                r_addr0 => source_1_internal,
                r_addr1 => source_2_internal,
                r_data0 => rd_data1_internal, -- internal signal so we can output this to the decode output port and so it can be used for branch calc
                r_data1 => rd_data2_internal
            );

        u_controller : entity work.controller
            port map(
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
                pc_mode => pc_mode_internal,
                pc_reset => pc_reset,
                rom_enable => rom_enable
            );
    -- send the internal signals to the output ports
    rd_data1 <= rd_data1_internal;
    rd_data2 <= rd_data2_internal;
    pc_mode <= pc_mode_internal; 
    pc_plus2_out <= pc_plus2_in;
    pc_plus2_internal <= pc_plus2_in;
    shift_amt     <= shift_amt_internal;

    -- allow top level to monitor which source registers are being used for hazard detection
    src1_reg      <= source_1_internal;
    src2_reg      <= source_2_internal;
 
    -- process to determine source registers are used for hazard detection
    process(opcode_internal)
    begin
        src1_used <= '0';
        src2_used <= '0';

        case opcode_internal is
            when OP_ADD | OP_SUB | OP_MUL | OP_NAND =>
                src1_used <= '1';
                src2_used <= '1';

            when OP_LOAD | OP_MOV | OP_LOADIMM =>
                src1_used <= '1';

            when OP_STORE =>
                src1_used <= '1';
                src2_used <= '1';

            when OP_SHL | OP_SHR | OP_TEST =>
                src1_used <= '1';

            when OP_OUT =>
                src2_used <= '1';

            when OP_BR | OP_BR_N | OP_BR_Z | OP_BR_SUB | OP_RETURN =>
                src1_used <= '1';

            when others =>
                null;
        end case;
    end process;

    process(opcode_internal, disp, pc_plus2_internal, pc_mode_internal)    
    begin
            imm           <= (others => '0'); -- TODO figure out what this is supposed to do... does it require reg read ?
            branch_target <= (others => '0'); 

        -- only bother updating when we actually take the branch, other wise the branch target should be 0 for clarity since the pc ignore this
        if pc_mode_internal = PC_LOAD_NEW_VAL then
            case opcode_internal is
                when OP_BRR | OP_BRR_N | OP_BRR_Z =>
                    branch_target <= std_logic_vector(signed(pc_plus2_internal) + disp);
    
                when OP_BR | OP_BR_N | OP_BR_Z | OP_BR_SUB =>
                    branch_target <= std_logic_vector(signed(rd_data1_internal) + disp);
    
                when OP_RETURN =>
                    branch_target <= rd_data1_internal; -- whatever was inside the link register is the branch target
    
                when others =>
                    null;
            end case;
        end if;
    end process;

end Behavioral;

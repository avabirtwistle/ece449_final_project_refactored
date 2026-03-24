library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.constant_package.all; 

entity controller is
    port(
        clk         : in  std_logic;
        reset       : in  std_logic;

        -- Input from IF/ID pipeline register (Instruction bits 15 downto 9)
        opcode      : in  std_logic_vector(6 downto 0);

        -- Status flags from ALU
        flag_zero   : in  std_logic;
        flag_neg    : in  std_logic;

        -- Boot mode
        -- '0' = Reset & Execute (PC -> 0x0000)
        -- '1' = Reset & Load    (PC -> 0x0002)
        boot_mode   : in  std_logic;

        -- ALU Control Signals
        mode_ALU    : out std_logic_vector(2 downto 0);
        src_ALU     : out std_logic;

        -- Memory Control Signals
        wr_en_MEM   : out std_logic;

        -- Write Back Control Signals
        wr_en_REG   : out std_logic;
        sel_WB      : out std_logic_vector(1 downto 0);

        -- I/O Port Control Signals
        in_p_EN     : out std_logic;
        out_p_EN    : out std_logic;

        -- Branch / PC Control
        pc_src      : out std_logic;
        pc_mode       : out std_logic_vector(1 downto 0);
        pc_reset : out std_logic
    );
end controller;

architecture behavioral of controller is

    -- FSM State Encoding
    type state_type is (RESET_STATE, DECODE_STATE);
    signal current_state : state_type := RESET_STATE;
begin

    -- Sequential FSM.. FRaliing edge clock for data path to correctly latch data
    fsm_seq : process(clk, reset)
    begin
        if reset = '1' then
            current_state <= RESET_STATE;
        elsif rising_edge(clk) then
            case current_state is
                when RESET_STATE  => current_state <= DECODE_STATE;
                when DECODE_STATE => current_state <= DECODE_STATE;
                when others       => current_state <= RESET_STATE;
            end case;
        end if;
    end process;

    -- Combinational output logic
    fsm_out : process(current_state, opcode, flag_zero, flag_neg, boot_mode)
    begin
        -- Safe defaults
        mode_ALU  <= ALU_NOP;
        src_ALU   <= '0';
        wr_en_MEM <= '0';
        wr_en_REG <= '0';
        sel_WB    <= WB_ALU;
        in_p_EN   <= '0';
        out_p_EN  <= '0';
        pc_src    <= '0'; -- denotes if we will take a branch or not
        pc_mode <= PC_INCREMENT; -- the signal for selecting the program counter mode in the fetch module
        pc_reset <= '0'; -- for reseting the program counter in the fetch module
        case current_state is

            -- RESET
            when RESET_STATE =>
                if boot_mode = '0' then
                    pc_mode <= PC_BOOT;
                else
                    pc_mode <= PC_INCREMENT;
                end if;
                pc_reset<='1';
            -- DECODE
            when DECODE_STATE =>
                case opcode is

                    when OP_NOP =>
                        mode_ALU  <= ALU_NOP;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';
                        pc_mode <= PC_INCREMENT;

                    when OP_ADD =>
                        mode_ALU  <= ALU_ADD;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';
                        pc_mode <= PC_INCREMENT;
                        
                    when OP_SUB =>
                        mode_ALU  <= ALU_SUB;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';
                        pc_mode <= PC_INCREMENT;
                        
                    when OP_MUL =>
                        mode_ALU  <= ALU_MUL;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';
                        pc_mode <= PC_INCREMENT;
                        
                    when OP_NAND =>
                        mode_ALU  <= ALU_NAND;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';
                        pc_mode <= PC_INCREMENT;
                        
                    when OP_SHL =>
                        mode_ALU  <= ALU_SHL;
                        src_ALU   <= '1';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';
                        pc_mode <= PC_INCREMENT;
                        
                    when OP_SHR =>
                        mode_ALU  <= ALU_SHR;
                        src_ALU   <= '1';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';
                        pc_mode <= PC_INCREMENT;
                        
                    when OP_TEST =>
                        mode_ALU  <= ALU_TEST;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';  -- TEST sets flags only
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';
                        pc_mode <= PC_INCREMENT;
                        
                    when OP_OUT =>
                        mode_ALU  <= ALU_NOP;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '1';
                        pc_src    <= '0';
                        pc_mode <= PC_INCREMENT;
                        
                    when OP_IN =>
                        mode_ALU  <= ALU_NOP;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '1';
                        out_p_EN  <= '0';
                        pc_src    <= '0';
                        pc_mode <= PC_INCREMENT;
                        
                    when OP_BRR =>                        -- Branch relative, unconditional: PC = PC + imm
                        mode_ALU  <= ALU_NOP;             -- target computed in decode (pc_plus2 + imm), ALU not needed
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '1';                 -- always take branch
                        pc_mode <= PC_LOAD_LINK;
                        
                    when OP_BRR_N =>                      -- Branch relative if negative: PC = PC + imm if flag_neg
                        mode_ALU  <= ALU_NOP;             -- target computed in decode (pc_plus2 + imm), ALU not needed
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= flag_neg;            -- take branch only if negative flag set
                        if flag_neg = '1' then 
                            pc_mode <= PC_LOAD_LINK;
                        else
                            pc_mode <= PC_INCREMENT;
                        end if;
                        
                    when OP_BRR_Z =>                      -- Branch relative if zero: PC = PC + imm if flag_zero
                        mode_ALU  <= ALU_NOP;             -- target computed in decode (pc_plus2 + imm), ALU not needed
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= flag_zero;           -- take branch only if zero flag set
                        if flag_zero = '1' then 
                            pc_mode <= PC_LOAD_LINK;
                        else
                            pc_mode <= PC_INCREMENT;
                        end if;

                    when OP_BR =>                         -- Branch to register, unconditional: PC = Ra
                        mode_ALU  <= ALU_NOP;             -- no ALU computation; target is register value
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '1';                 -- always take branch
                        pc_mode <= PC_LOAD_LINK; 
                    when OP_BR_N =>                       -- Branch to register if negative: PC = Ra if flag_neg
                        mode_ALU  <= ALU_NOP;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= flag_neg;
                        if flag_neg = '1' then 
                            pc_mode <= PC_LOAD_LINK;
                        else
                            pc_mode <= PC_INCREMENT;
                        end if;
                        
                    when OP_BR_Z =>                       -- Branch to register if zero: PC = Ra if flag_zero
                        mode_ALU  <= ALU_NOP;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= flag_zero;
                        if flag_zero = '1' then 
                            pc_mode <= PC_LOAD_LINK;
                        else
                            pc_mode <= PC_INCREMENT;
                        end if;
                        
                    when OP_BR_SUB =>                     -- Branch to subroutine: PC = Ra, save PC+2 to link reg
                        mode_ALU  <= ALU_NOP;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';                 -- write return address (PC+2) to link register
                        sel_WB    <= WB_PC2;              -- select PC+2 as write-back value
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '1';                 -- always take branch
                        pc_mode <= PC_LOAD_LINK;

                    when OP_RETURN =>                     -- Return from subroutine: PC = Ra (we need r7?) (link register) 
                        mode_ALU  <= ALU_NOP;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '1';                 -- load PC from link register
                        pc_mode <= PC_LOAD_LINK;
                    when others =>
                        mode_ALU  <= ALU_NOP;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';
                        sel_WB    <= WB_ALU;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';
                        pc_mode <= PC_INCREMENT;
                end case;

            when others =>
                null;

        end case;
    end process;

end behavioral;

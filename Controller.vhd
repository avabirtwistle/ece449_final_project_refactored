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
        sel_WB      : out std_logic;

        -- I/O Port Control Signals
        in_p_EN     : out std_logic;
        out_p_EN    : out std_logic;

        -- Branch / PC Control
        pc_src      : out std_logic;
        pc_reset    : out std_logic_vector(15 downto 0)
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
        sel_WB    <= '0';
        in_p_EN   <= '0';
        out_p_EN  <= '0';
        pc_src    <= '0';
        pc_reset  <= (others => '0');

        case current_state is

            -- RESET
            when RESET_STATE =>
                if boot_mode = '0' then
                    pc_reset <= x"0000";
                else
                    pc_reset <= x"0002";
                end if;

            -- DECODE
            when DECODE_STATE =>
                case opcode is

                    when OP_NOP =>
                        mode_ALU  <= ALU_NOP;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';
                        sel_WB    <= '0';
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';

                    when OP_ADD =>
                        mode_ALU  <= ALU_ADD;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= '0';
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';

                    when OP_SUB =>
                        mode_ALU  <= ALU_SUB;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= '0';
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';

                    when OP_MUL =>
                        mode_ALU  <= ALU_MUL;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= '0';
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';

                    when OP_NAND =>
                        mode_ALU  <= ALU_NAND;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= '0';
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';

                    when OP_SHL =>
                        mode_ALU  <= ALU_SHL;
                        src_ALU   <= '1';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= '0';
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';

                    when OP_SHR =>
                        mode_ALU  <= ALU_SHR;
                        src_ALU   <= '1';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= '0';
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';

                    when OP_TEST =>
                        mode_ALU  <= ALU_TEST;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';  -- TEST sets flags only
                        sel_WB    <= '0';
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';

                    when OP_OUT_PORT =>
                        mode_ALU  <= ALU_NOP;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';
                        sel_WB    <= '0';
                        in_p_EN   <= '0';
                        out_p_EN  <= '1';
                        pc_src    <= '0';

                    when OP_IN_PORT =>
                        mode_ALU  <= ALU_NOP;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= '0';
                        in_p_EN   <= '1';
                        out_p_EN  <= '0';
                        pc_src    <= '0';
                        
                    when OP_BRR => 
                        mode_ALU  <= 
                        src_ALU   <= 
                        wr_en_MEM <=
                        wr_en_REG <= 
                        sel_WB    <= 
                        in_p_EN   <= 
                        out_p_EN  <= 
                        pc_src    <= 
                      
                      when OP_BRR_N => 
                        mode_ALU  <= 
                        src_ALU   <= 
                        wr_en_MEM <=
                        wr_en_REG <= 
                        sel_WB    <= 
                        in_p_EN   <= 
                        out_p_EN  <= 
                        pc_src    <= 
                     
                       when OP_BRR_Z => 
                        mode_ALU  <= 
                        src_ALU   <= 
                        wr_en_MEM <=
                        wr_en_REG <= 
                        sel_WB    <= 
                        in_p_EN   <= 
                        out_p_EN  <= 
                        pc_src    <= 
                     
                       when OP_BR => 
                        mode_ALU  <= 
                        src_ALU   <= 
                        wr_en_MEM <=
                        wr_en_REG <= 
                        sel_WB    <= 
                        in_p_EN   <= 
                        out_p_EN  <= 
                        pc_src    <= 
                    
                      when OP_BR_N => 
                        mode_ALU  <= 
                        src_ALU   <= 
                        wr_en_MEM <=
                        wr_en_REG <= 
                        sel_WB    <= 
                        in_p_EN   <= 
                        out_p_EN  <= 
                        pc_src    <= 
                   
                     when OP_BR_Z => 
                        mode_ALU  <= 
                        src_ALU   <= 
                        wr_en_MEM <=
                        wr_en_REG <= 
                        sel_WB    <= 
                        in_p_EN   <= 
                        out_p_EN  <= 
                        pc_src    <= 
                     
                       when OP_BR_SUB =>                  
                        mode_ALU  <= 
                        src_ALU   <= 
                        wr_en_MEM <=
                        wr_en_REG <= 
                        sel_WB    <= 
                        in_p_EN   <= 
                        out_p_EN  <= 
                        pc_src    <= 
                       
                    when OP_RETURN => 
                        mode_ALU  <= 
                        src_ALU   <= 
                        wr_en_MEM <=
                        wr_en_REG <= 
                        sel_WB    <= 
                        in_p_EN   <= 
                        out_p_EN  <= 
                        pc_src    <= 
                        
                    when others =>
                        mode_ALU  <= ALU_NOP;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '0';
                        sel_WB    <= '0';
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_src    <= '0';

                end case;

            when others =>
                null;

        end case;
    end process;

end behavioral;
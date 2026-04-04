


-- instantiate each of the stages here and connect the ports appropriately
------------------------------------------------------
-- Instruction fetch stage (fetch.vhd) - responsible for fetching the instruction from ROM based on the current value of the program counter

-- IF/ID pipeline register - responsible for holding the instruction and program counter value from the fetch stage and passing them to the decode stage on the next clock cycle

-- Instruction decode stage (decode.vhd) - responsible for decoding the instruction and generating the appropriate control signals for the rest of the pipeline
    u_decode : entity work.decode
        port map(

        );
-- ID/EX pipeline register - responsible for holding the decoded instruction information and control signals from the decode stage and passing them to the execute stage on the next clock cycle

-- Execute stage (execute.vhd) - responsible for performing the ALU operations and calculating memory addresses as needed based on the decoded instruction information and control signals

-- EX/MEM pipeline register - responsible for holding the results from the execute stage and passing them to the memory stage on the next clock cycle

-- Memory stage (memory.vhd) - responsible for performing memory read/write operations as needed based on the decoded instruction information and control signals

-- MEM/WB pipeline register - responsible for holding the results from the memory stage and passing them to the write-back stage on the next clock cycle

-- used by write back stage to write results back to the register file as needed based on the decoded instruction information and control signals
-- used by decode stage to read the source register values from the register file based on the decoded instruction information
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


-- instantiate each of the pipeline registers here and connect the ports appropriately
-- instantiate the controller and connect the output commands of the decode stage to the controller
-- connect the control signals from the controller to the appropriate stages and pipeline registers
-- may also wish to instatiate the RAM here and connect it to the memory stage and EX/MEM pipeline register as needed but this could instead be inside the memory stage itself depending on how you choose to implement the memory stage

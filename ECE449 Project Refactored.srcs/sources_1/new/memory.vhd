----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/29/2026 11:17:36 AM
-- Design Name: 
-- Module Name: memory - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity memory is
  --Port ( );
end memory;

architecture Behavioral of memory is

    signal ram_ena   : std_logic;
    signal ram_wea   : std_logic_vector(0 downto 0);
    signal ram_addra : std_logic_vector(8 downto 0);
    signal ram_dina  : std_logic_vector(15 downto 0);
    signal ram_douta : std_logic_vector(15 downto 0);
    signal ram_enb   : std_logic;
    signal ram_addrb : std_logic_vector(8 downto 0);
    signal ram_doutb : std_logic_vector(15 downto 0);


begin


   -- RAM
    u_ram : entity work.ram
        port map (
            clk   => clk,
            rst   => rst,
            ena   => ram_ena,
            wea   => ram_wea,
            addra => ram_addra,
            dina  => ram_dina,
            douta => ram_douta,
            enb   => ram_enb,
            addrb => ram_addrb,
            doutb => ram_doutb
        );
        
          -- TODO: RAM enable/address/write logic (memory map decode)
    -- Suggested memory map:
    --   ROM : 0x0000 - 0x007F
    --   RAM : 0x0400 - 0x07FF
    --   in_port  : 0xFFF0
    --   out_port : 0xFFF2
    ram_ena   <= '0'; -- TODO
    ram_wea   <= "0"; -- TODO
    ram_addra <= (others => '0'); -- TODO: EX_MEM_reg.alu_result(9 downto 1)
    ram_dina  <= (others => '0'); -- TODO: EX_MEM_reg.rd_data2
    ram_enb   <= '0'; -- TODO
    ram_addrb <= (others => '0'); -- TODO

    -- TODO: out_port logic (OUT instruction or memory-mapped store to 0xFFF2)
    out_port <= (others => '0'); -- placeholder

        
        
end Behavioral;

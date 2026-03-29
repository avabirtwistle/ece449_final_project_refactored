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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


library work;
use work.constant_package.all;

entity memory is
    port(
        clk           : in  std_logic;
        rst           : in  std_logic;

        -- INPUTS from EX/MEM
        alu_result    : in  std_logic_vector(15 downto 0);
        rd_data2      : in  std_logic_vector(15 downto 0);
        dest_reg      : in  std_logic_vector(2 downto 0);
        pc_plus2      : in  std_logic_vector(15 downto 0);

        wr_en_MEM     : in  std_logic;
        reg_write     : in  std_logic;
        wb_src        : in  std_logic_vector(1 downto 0);
        in_p_EN       : in  std_logic;
        out_p_EN      : in  std_logic;

        -- OUTPUTS to MEM/WB
        alu_result_out : out std_logic_vector(15 downto 0);
        mem_data_out   : out std_logic_vector(15 downto 0);
        dest_reg_out   : out std_logic_vector(2 downto 0);
        pc_plus2_out   : out std_logic_vector(15 downto 0);

        reg_write_out  : out std_logic;
        wb_src_out     : out std_logic_vector(1 downto 0);
        in_p_EN_out    : out std_logic;
        out_p_EN_out   : out std_logic;

        -- external output port
        out_port       : out std_logic_vector(15 downto 0)
    );
end memory;

architecture Behavioral of memory is

    signal ram_ena    : std_logic;
    signal ram_wea    : std_logic_vector(0 downto 0);
    signal ram_addra  : std_logic_vector(8 downto 0);
    signal ram_dina   : std_logic_vector(15 downto 0);
    signal ram_douta  : std_logic_vector(15 downto 0);
    signal ram_enb    : std_logic;
    signal ram_addrb  : std_logic_vector(8 downto 0);
    signal ram_doutb  : std_logic_vector(15 downto 0);

    signal ram_addr_hit  : std_logic;
    signal out_addr_hit  : std_logic;
    signal ram_read_en   : std_logic;
    signal ram_write_en  : std_logic;

    signal out_port_reg  : std_logic_vector(15 downto 0);

begin

    --------------------------------------------------------------------
    -- Address decode
    -- RAM : 0x0400 - 0x07FF
    -- OUT : 0xFFF2
    --------------------------------------------------------------------
    ram_addr_hit <= '1' when alu_result(15 downto 10) = "000001" else '0';
    out_addr_hit <= '1' when alu_result = x"FFF2" else '0';

    -- Read memory when WB source is memory and the address is in RAM
    ram_read_en  <= '1' when (wb_src = WB_MEM and ram_addr_hit = '1') else '0';

    -- Write memory when store is enabled and the address is in RAM
    ram_write_en <= '1' when (wr_en_MEM = '1' and ram_addr_hit = '1') else '0';

    --------------------------------------------------------------------
    -- RAM interface
    --------------------------------------------------------------------
    u_ram : entity work.ram
        port map(
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

    ram_ena   <= ram_read_en or ram_write_en;
    ram_wea   <= "1" when ram_write_en = '1' else "0";
    ram_addra <= alu_result(9 downto 1);   -- word-aligned RAM address
    ram_dina  <= rd_data2;

    ram_enb   <= '0';
    ram_addrb <= (others => '0');

    --------------------------------------------------------------------
    -- OUT port logic
    -- update external output on OUT instruction or mapped write to 0xFFF2
    --------------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            out_port_reg <= (others => '0');
        elsif rising_edge(clk) then
            if (out_p_EN = '1') or (wr_en_MEM = '1' and out_addr_hit = '1') then
                out_port_reg <= rd_data2;
            end if;
        end if;
    end process;

    out_port <= out_port_reg;

    --------------------------------------------------------------------
    -- Outputs to MEM/WB
    --------------------------------------------------------------------
    alu_result_out <= alu_result;
    mem_data_out   <= ram_douta when ram_read_en = '1' else (others => '0');
    dest_reg_out   <= dest_reg;
    pc_plus2_out   <= pc_plus2;

    reg_write_out  <= reg_write;
    wb_src_out     <= wb_src;
    in_p_EN_out    <= in_p_EN;
    out_p_EN_out   <= out_p_EN;

end Behavioral;
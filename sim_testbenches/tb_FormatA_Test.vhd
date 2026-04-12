library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
--use work.constant_package.all;
use work.tb_mem_helpers_pkg.all;

entity tb_FormatA_Test is
end entity;

architecture sim of tb_FormatA_Test is
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal boot_mode : std_logic := '0';
    signal in_port   : std_logic_vector(15 downto 0) := (others => '0');
    signal out_port  : std_logic_vector(15 downto 0);
    signal debug_console : std_logic := '0';
    signal vga_red       : std_logic_vector(3 downto 0);
    signal vga_green     : std_logic_vector(3 downto 0);
    signal vga_blue      : std_logic_vector(3 downto 0);
    signal h_sync_signal : std_logic;
    signal v_sync_signal : std_logic;
    signal led_segments  : std_logic_vector(6 downto 0);
    signal led_digits    : std_logic_vector(3 downto 0);

    constant INPUTS : slv16_array_t(0 to 1) := (
        x"0003", -- IN r1
        x"0005"  -- IN r2
    );
begin
    uut : entity work.Top_Level_CPU
        port map (
            clk       => clk,
            rst       => rst,
            boot_mode => boot_mode,
            in_port   => in_port,
            out_port  => out_port,
            debug_console => debug_console,
            vga_red       => vga_red,
            vga_green     => vga_green,
            vga_blue      => vga_blue,
            h_sync_signal => h_sync_signal,
            v_sync_signal => v_sync_signal,
            led_segments  => led_segments,
            led_digits    => led_digits
        );

    clk <= not clk after 5 ns;

    stim_proc : process
    begin
        -- This program is assembled at 0x0210, so this bench assumes your
        -- "boot" reset vector targets that region.
        rst <= '1';
        wait_n_rising_edges(clk, 2);
        rst <= '0';

        -- Robin Changes Start
        -- Explanation of changes:
        -- 1) IN data is latched early in this pipeline path, not all the way at WB.
        -- 2) Holding the first input for 4 cycles causes both back-to-back IN instructions
        --    to sample the first value, which makes FormatA compute 72 instead of 96.
        -- 3) Using 3 fill cycles lines the second IN up with the second stimulus value.
        -- Robin Changes End.
        drive_in_sequence_after_pipeline_fill(clk, in_port, INPUTS, 3);

        wait_n_rising_edges(clk, 30);

        assert out_port = x"0060"
            report "FormatA_Test failed: expected out_port = 96 (0x0060)."
            severity failure;

        assert false report "FormatA_Test passed." severity note;
        wait;
    end process;
end architecture;

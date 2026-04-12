library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tb_mem_helpers_pkg.all;

entity tb_FinalTest1 is
end entity;

architecture sim of tb_FinalTest1 is
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal boot_mode : std_logic := '1';
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

    constant INPUTS : slv16_array_t(0 to 0) := (
        0 => x"0005"
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
        -- Depends on LOADIMM / MOV support in decode + controller.
        rst <= '1';
        wait_n_rising_edges(clk, 2);
        rst <= '0';

        drive_in_sequence_after_pipeline_fill(clk, in_port, INPUTS, 4);

        -- Robin Changes Start
        -- Explanation of changes:
        -- 1) FinalTest1 contains a longer counted loop than the earlier Format B tests.
        -- 2) Waiting only 80 cycles checked out_port before the final branch exit and OUT retired.
        -- 3) Extend the observation window so the architectural result reaches the external port.
        -- Robin Changes End.
        wait_n_rising_edges(clk, 120);

        assert out_port = x"00BF"
            report "FinalTest1 failed: expected out_port = 191 (0x00BF)."
            severity failure;

        assert false report "FinalTest1 passed." severity note;
        wait;
    end process;
end architecture;

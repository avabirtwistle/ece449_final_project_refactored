library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tb_mem_helpers_pkg.all;

entity tb_FactorialTest is
end entity;

architecture sim of tb_FactorialTest is
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
        -- Depends on LOADIMM / MOV support and a boot vector that targets 0x0210.
        rst <= '1';
        wait_n_rising_edges(clk, 2);
        rst <= '0';

        drive_in_sequence_after_pipeline_fill(clk, in_port, INPUTS, 4);

        wait_n_rising_edges(clk, 120);

        assert out_port = x"0078"
            report "FactorialTest failed: expected out_port = 120 (0x0078) for input 5."
            severity failure;

        assert false report "FactorialTest passed." severity note;
        wait;
    end process;
end architecture;

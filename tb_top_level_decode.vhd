library ieee;
use ieee.std_logic_1164.all;

entity tb_top_level_cpu is
end tb_top_level_cpu;

architecture sim of tb_top_level_cpu is
    constant CLK_PERIOD : time := 10 ns;

    signal clk       : std_logic := '0';
    signal reset     : std_logic := '0';
    signal boot_mode : std_logic := '0';
    signal in_port   : std_logic_vector(15 downto 0) := (others => '0');
    signal out_port  : std_logic_vector(15 downto 0);
begin

    -- Instantiate the DUT
    uut : entity work.top_level_cpu
        port map(
            clk       => clk,
            reset     => reset,
            boot_mode => boot_mode,
            in_port   => in_port,
            out_port  => out_port
        );

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Stimulus
    stim_proc : process
    begin
        -- Initial reset
        reset <= '1';
        boot_mode <= '0';
        in_port <= x"0000";
        wait for 3 * CLK_PERIOD;

        -- Release reset
        reset <= '0';
        wait for 5 * CLK_PERIOD;

        -- Try a different input value
        in_port <= x"00A5";
        wait for 5 * CLK_PERIOD;

        -- Switch boot mode
        boot_mode <= '1';
        reset <= '1';
        wait for 2 * CLK_PERIOD;
        reset <= '0';
        wait for 5 * CLK_PERIOD;

        wait;
    end process;

end sim;

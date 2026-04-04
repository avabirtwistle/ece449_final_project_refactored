library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_decode is
end tb_decode;

architecture sim of tb_decode is
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';

    signal in_instr     : std_logic_vector(15 downto 0) := (others => '0');
    signal in_pc_plus2  : std_logic_vector(15 downto 0) := (others => '0');

    signal wb_wr_en     : std_logic := '0';
    signal wb_dest      : std_logic_vector(2 downto 0) := (others => '0');
    signal wb_data      : std_logic_vector(15 downto 0) := (others => '0');

    signal out_rd_data1 : std_logic_vector(15 downto 0);
    signal out_rd_data2 : std_logic_vector(15 downto 0);
    signal out_imm      : std_logic_vector(15 downto 0);
    signal out_dest_reg : std_logic_vector(2 downto 0);
    signal out_pc_plus2 : std_logic_vector(15 downto 0);
begin

    uut : entity work.decode
        port map(
            clk          => clk,
            reset        => reset,
            in_instr     => in_instr,
            in_pc_plus2  => in_pc_plus2,
            wb_wr_en     => wb_wr_en,
            wb_dest      => wb_dest,
            wb_data      => wb_data,
            out_rd_data1 => out_rd_data1,
            out_rd_data2 => out_rd_data2,
            out_imm      => out_imm,
            out_dest_reg => out_dest_reg,
            out_pc_plus2 => out_pc_plus2
        );

    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    stim_proc : process
    begin
        -- reset
        reset <= '1';
        wait for 20 ns;
        reset <= '0';

        -- write 0x0005 into r2
        wb_wr_en <= '1';
        wb_dest  <= "010";
        wb_data  <= x"0005";
        wait for 10 ns;

        -- write 0x0003 into r1
        wb_dest  <= "001";
        wb_data  <= x"0003";
        wait for 10 ns;

        wb_wr_en <= '0';

        -- ADD r3, r2, r1
        -- opcode=0000001, ra=011, rb=010, rc=001
        in_instr    <= "0000001" & "011" & "010" & "001";
        in_pc_plus2 <= x"0002";

        wait for 40 ns;

        wait;
    end process;

end sim;

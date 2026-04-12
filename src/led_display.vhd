----------------------------------------------------------------------------------
--
-- ECE 449
--
-- Console display for ECE 449 FPGA CPU project
--
-- Version 1.00
--
-- (c)2024 B. Sirna         Dept. of ECE
--                          University of Victoria
--
----------------------------------------------------------------------------------

--+
--
-- component declaration insert this code block into your CPU's code top module. To remove the extra comments select the text and press control /
--
--+

-- Cut from here

--component led_display is
--    Port (

--        addr_write : in  STD_LOGIC_VECTOR (15 downto 0);
--        clk : in  STD_LOGIC;
--        data_in : in  STD_LOGIC_VECTOR (15 downto 0);
--        en_write : in  STD_LOGIC;

--        board_clock : in STD_LOGIC;
--        led_segments : out STD_LOGIC_VECTOR( 6 downto 0 );
--        led_digits : out STD_LOGIC_VECTOR( 3 downto 0 )
--    );
--end component;

-- to here

--+
--
-- Creation of led_display. Add the following code to add the component to your system. You will need to map the signal that you wish to display
--
--+

-- Cut from here

--led_display_memory : led_display
--port map (

--        addr_write => s2_memory_write_address,
--        clk => cpu_clock,
--        data_in => s2_memory_write_data,
--        en_write => s2_memory_write_enable,

--        board_clock => board_clock,
--        led_segments => led_segments,
--        led_digits => led_digits
--    );

-- to here


--+
--
-- Top module entity signal declaration. You will need to add the following signals to your entity.
--
--+

-- cut from here

--        led_segments : out STD_LOGIC_VECTOR( 6 downto 0 );
--        led_digits : out STD_LOGIC_VECTOR( 3 downto 0 );

-- to here

--+
--
-- Extra constriants. Add or replace the following constraints in your project constriants file
--
--+

-- cut from here

--##7 segment display
--set_property PACKAGE_PIN W7 [get_ports {led_segments[0]}]
--	set_property IOSTANDARD LVCMOS33 [get_ports {led_segments[0]}]
--set_property PACKAGE_PIN W6 [get_ports {led_segments[1]}]					
--	set_property IOSTANDARD LVCMOS33 [get_ports {led_segments[1]}]
--set_property PACKAGE_PIN U8 [get_ports {led_segments[2]}]					
--	set_property IOSTANDARD LVCMOS33 [get_ports {led_segments[2]}]
--set_property PACKAGE_PIN V8 [get_ports {led_segments[3]}]					
--	set_property IOSTANDARD LVCMOS33 [get_ports {led_segments[3]}]
--set_property PACKAGE_PIN U5 [get_ports {led_segments[4]}]					
--	set_property IOSTANDARD LVCMOS33 [get_ports {led_segments[4]}]
--set_property PACKAGE_PIN V5 [get_ports {led_segments[5]}]					
--	set_property IOSTANDARD LVCMOS33 [get_ports {led_segments[5]}]
--set_property PACKAGE_PIN U7 [get_ports {led_segments[6]}]					
--	set_property IOSTANDARD LVCMOS33 [get_ports {led_segments[6]}]

--#set_property PACKAGE_PIN V7 [get_ports dp]							
--	#set_property IOSTANDARD LVCMOS33 [get_ports dp]

--set_property PACKAGE_PIN U2 [get_ports {led_digits[0]}]					
--	set_property IOSTANDARD LVCMOS33 [get_ports {led_digits[0]}]
--set_property PACKAGE_PIN U4 [get_ports {led_digits[1]}]					
--	set_property IOSTANDARD LVCMOS33 [get_ports {led_digits[1]}]
--set_property PACKAGE_PIN V4 [get_ports {led_digits[2]}]					
--	set_property IOSTANDARD LVCMOS33 [get_ports {led_digits[2]}]
--set_property PACKAGE_PIN W4 [get_ports {led_digits[3]}]					
--	set_property IOSTANDARD LVCMOS33 [get_ports {led_digits[3]}]

-- to here


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity led_display is
    Port (

        addr_write : in  STD_LOGIC_VECTOR (15 downto 0);
        clk : in  STD_LOGIC;
        data_in : in  STD_LOGIC_VECTOR (15 downto 0);
        en_write : in  STD_LOGIC;

        board_clock : in STD_LOGIC;
        led_segments : out STD_LOGIC_VECTOR( 6 downto 0 );
        led_digits : out STD_LOGIC_VECTOR( 3 downto 0 )
    );
end led_display;

architecture Behavioral of led_display is

component hex_to_led is
    port (
        hex : in STD_LOGIC_VECTOR( 3 downto 0 );
        segments : out STD_LOGIC_VECTOR( 6 downto 0 )
    );
end component;

signal led_data : STD_LOGIC_VECTOR( 15 downto 0 ) := x"1234";
signal nibble : STD_LOGIC_VECTOR( 3 downto 0 ) := "0000";
signal digit_select : UNSIGNED( 1 downto 0 ) := "00";

begin

clock_divider : process
( 
    board_clock
)


variable divider : integer range 0 to 100000 := 0;

begin

    if ( rising_edge( board_clock )) then
        divider := divider + 1;
        if ( divider = 100000 ) then
            divider := 0;

            digit_select <= digit_select + 1;
        end if;
    end if;
end process;


with digit_select select
    led_digits <= 
        "1110" when "00",
        "1101" when "01",
        "1011" when "10",
        "0111" when others;

with digit_select select
    nibble <=
        led_data( 3 downto 0 ) when "00",
        led_data( 7 downto 4 ) when "01",
        led_data( 11 downto 8 ) when "10",
        led_data( 15 downto 12 ) when others;


--
--   HEX:   in    STD_LOGIC_VECTOR (3 downto 0);
--   LED:   out   STD_LOGIC_VECTOR (6 downto 0);
-- 
-- segment encoding
--      0
--     ---  
--  5 |   | 1
--     ---   <- 6
--  4 |   | 2
--     ---
--      3

with nibble select
    led_segments <= 
        "1111001" when "0001",   --1
        "0100100" when "0010",   --2
        "0110000" when "0011",   --3
        "0011001" when "0100",   --4
        "0010010" when "0101",   --5
        "0000010" when "0110",   --6
        "1111000" when "0111",   --7
        "0000000" when "1000",   --8
        "0010000" when "1001",   --9
        "0001000" when "1010",   --A
        "0000011" when "1011",   --b
        "1000110" when "1100",   --C
        "0100001" when "1101",   --d
        "0000110" when "1110",   --E
        "0001110" when "1111",   --F
        "1000000" when others;   --0


--segments_decode : hex_to_led
--port map (
--    hex => nibble,
--    segments => led_segments 
--);



--
-- Write data to the main display buffer
--

write_led : process
(
    clk,
    addr_write,
    data_in,
    en_write 
)
begin
    if ( rising_edge( clk )) then
        if (( addr_write = x"FFF2" ) and ( en_write = '1' )) then
            led_data <= data_in;
        end if;
    end if;
end process;





end Behavioral;

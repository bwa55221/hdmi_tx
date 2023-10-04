library ieee;
use ieee.std_logic_1164.all;
use work.all;
use std.env.all;

entity adv7513_driver_tb is
end adv7513_driver_tb;

architecture rtl of adv7513_driver_tb is 
    component adv7513_driver is
        port (
            SYS_CLK         : in std_logic;
            SYS_RST         : in std_logic;
            HDMI_I2C_SCL    : inout std_logic;
            HDMI_I2C_SDA    : inout std_logic
        );
    end component;

signal test_clk : std_logic := '0';
signal test_scl, test_sda : std_logic := '0';
signal test_rst  : std_logic := '1';


begin

    dut0 : component adv7513_driver
        port map (
            SYS_CLK         => test_clk,
            SYS_RST         => test_rst,
            HDMI_I2C_SCL    => test_scl,
            HDMI_I2C_SDA    => test_sda
        );

    test_clk <= not test_clk after 500 ps;
    test_rst <= '0' after 500 ps;

    stimulus : process
        -- place alias here since dut0 needs to be elaborated prior to external name reference
        -- NOTE: QUARTUS HAS LIMITED SUPPORT FOR VHDL-2008, EXTERNAL SIGNAL NOT SUPPORTED.
        -- alias FSM_STATE is << signal dut0.ADV7513_STATE : state_type_adv7513 >>;
    begin
        for i in 0 to 50 loop
            wait until rising_edge(test_clk);
        end loop;
        stop;

    end process;


end rtl;
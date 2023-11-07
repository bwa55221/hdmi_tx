library ieee;
use ieee.std_logic_1164.all;


entity sdram_control is

    port(
        -- WAIT_REQ        : out std_logic;
        -- READ_DATA       : out std_logic_vector(63 downto 0);
        -- READ_DATA_VALID : out std_logic;

        CLK             : in std_logic;
        -- WRITE_DATA      : in std_logic_vector(63 downto 0);
        -- ADDRESS         : in std_logic_vector(9 downto 0);
        WRITE_CMD       : in std_logic;
        -- READ_CMD        : in std_logic;
        -- BYTE_ENABLE     : in std_logic_vector(7 downto 0);
        -- DEBUG_ACCESS    : in std_logic

        DO_SDRAM_READ   : out std_logic
    );
    end sdram_control;

architecture rtl of sdram_control is
begin
    DO_SDRAM_READ   <= WRITE_CMD;
end rtl;

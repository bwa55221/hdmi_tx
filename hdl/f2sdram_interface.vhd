library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity f2sdram_interface is 
    port (


        sdram_if_address            : in    std_logic_vector(28 downto 0) := (others => '0'); -- hps_0_f2h_sdram0_data.address
        sdram_if_burstcount         : in    std_logic_vector(7 downto 0)  := (others => '0'); --                      .burstcount
        sdram_if_waitrequest        : out   std_logic;                                        --                      .waitrequest
        sdram_if_readdata           : out   std_logic_vector(63 downto 0);                    --                      .readdata
        sdram_if_rdv                : out   std_logic;                                        --                      .readdatavalid
        sdram_if_read               : in    std_logic                     := '0';             --                      .read
        sdram_if_writedata          : in    std_logic_vector(63 downto 0) := (others => '0'); --                      .writedata
        sdram_if_data_byteenable    : in    std_logic_vector(7 downto 0)  := (others => '0'); --                      .byteenable
        sdram_if_data_write         : in    std_logic                     := '0';             --                      .write


    );

end entity f2sdram_interface;

architecture rtl of f2sdram_interface is

begin

end rtl;
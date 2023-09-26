library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_lut is
    port (

        count           : in std_logic_vector(7 downto 0);
        address         : out std_logic_vector(7 downto 0);
        data            : out std_logic_vector(7 downto 0)
    );
    end reg_lut;

architecture rtl of reg_lut is
begin

    process(count)
    begin

        case count is
            when X"00"  =>  address <= X"41"; data <= X"10";    -- enable power up
            when X"01"  =>  address <= X"98"; data <= X"03";    -- set for proper operation
            when X"02"  =>  address <= X"9A"; data <= X"E0";    --
            when X"03"  =>  address <= X"9C"; data <= X"30";    --
            when X"04"  =>  address <= X"9D"; data <= X"61";    -- set clock divide
            when X"05"  =>  address <= X"A2"; data <= X"A4";     
            when X"06"  =>  address <= X"A3"; data <= X"A4";    
            when X"07"  =>  address <= X"E0"; data <= X"D0";     
            when X"08"  =>  address <= X"F9"; data <= X"00";  
            
            -- set video input mode registers
            when X"09"  =>  address <= X"15"; data <= X"20";     -- input 444 (RGB or YcrCb) with separate syncs, 48 kHz fs
            when X"0A"  =>  address <= X"16"; data <= X"30";     -- output format 444, 24 bit input RGB; VS/HS high polarity

            -- set video output mode registers
            when X"0B"  => address <= X"18"; data <= X"46";     -- disable CSC
            when X"0C"  => address <= X"AF"; data <= X"06";     -- select HDMI mode and disable HDCP 





            -- X"AF" register can disable HDCP encryption

            -- catch all for compile during test
            when others =>  address <= X"FF"; data <= X"FF";
            
        end case;
    end process;
end rtl;
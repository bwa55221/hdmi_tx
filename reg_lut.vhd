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

            -- X"AF" register can disable HDCP encryption

            -- catch all for compile during test
            when others =>  address <= X"FF"; data <= X"FF";
            
        end case;
    end process;
end rtl;
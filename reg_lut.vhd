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
            when X"01"  =>  address <= X"98"; data <= X"03";    -- must be set for proper operation
            when X"02"  =>  address <= X"9A"; data <= X"E0";    -- must be set for proper operation
            when X"03"  =>  address <= X"9C"; data <= X"30";    -- must be set for proper operation
            when X"04"  =>  address <= X"9D"; data <= X"61";    -- set clock divide
            when X"05"  =>  address <= X"A2"; data <= X"A4";    -- must be set for proper operation
            when X"06"  =>  address <= X"A3"; data <= X"A4";    -- must be set for proper operation
            when X"07"  =>  address <= X"E0"; data <= X"D0";    -- must be set for proper operation 
            when X"08"  =>  address <= X"F9"; data <= X"00";    -- must be set for proper operation
            
            -- set video input mode registers
            when X"09"  =>  address <= X"15"; data <= X"20";     -- input 444 (RGB or YcrCb) with separate syncs, 48 kHz fs
            when X"0A"  =>  address <= X"16"; data <= X"30";     -- output format 444, 8 bit input color depth, 

            -- set video output mode registers
            when X"0B"  =>  address <= X"18"; data <= X"46";     -- disable CSC
            when X"0C"  =>  address <= X"AF"; data <= X"06";     -- select HDMI mode and disable HDCP 

            when X"0D"  =>  address <= X"55"; data <= X"10";     -- enable AVI info frame, communicate RGB 4:4:4
            when X"0E"  =>  address <= X"56"; data <= X"08";     -- set AVI format same as aspect ratio

            when X"0F"  =>  address <= X"96"; data <= X"F6";     -- set interrupts (? still unsure about this ?)
            
            -- ######## CONFIGURATION FROM DE10 NANO HDMI TX EXAMPLE ###############
            -- when X"00"  =>  address <= X"98"; data <= X"03";    
            -- when X"01"  =>  address <= X"01"; data <= X"00";    
            -- when X"02"  =>  address <= X"02"; data <= X"18";    
            -- when X"03"  =>  address <= X"03"; data <= X"00";    
            -- when X"04"  =>  address <= X"14"; data <= X"70";    
            -- when X"05"  =>  address <= X"15"; data <= X"20";    
            -- when X"06"  =>  address <= X"16"; data <= X"30";    
            -- when X"07"  =>  address <= X"18"; data <= X"46";    
            -- when X"08"  =>  address <= X"40"; data <= X"80";    
            -- when X"09"  =>  address <= X"41"; data <= X"10";    
            -- when X"0A"  =>  address <= X"49"; data <= X"A8";    
            -- when X"0B"  =>  address <= X"55"; data <= X"10";    
            -- when X"0C"  =>  address <= X"56"; data <= X"08";  
            -- when X"0D"  =>  address <= X"96"; data <= X"F6";    
            -- when X"0E"  =>  address <= X"73"; data <= X"07";    
            -- when X"0F"  =>  address <= X"76"; data <= X"1F";    
            -- when X"10"  =>  address <= X"98"; data <= X"03";    
            -- when X"11"  =>  address <= X"99"; data <= X"02";    
            -- when X"12"  =>  address <= X"9A"; data <= X"E0";    
            -- when X"13"  =>  address <= X"9C"; data <= X"30";    
            -- when X"14"  =>  address <= X"9D"; data <= X"61";    
            -- when X"15"  =>  address <= X"A2"; data <= X"A4";    
            -- when X"16"  =>  address <= X"A3"; data <= X"A4";    
            -- when X"17"  =>  address <= X"A5"; data <= X"04"; 

            -- when X"18"  =>  address <= X"AB"; data <= X"40";
            -- when X"19"  =>  address <= X"AF"; data <= X"06"; -- change from 16 to 06, disable HDCP and FRAME ENCRYPTION
            -- when X"1A"  =>  address <= X"BA"; data <= X"60";
            -- when X"1B"  =>  address <= X"D1"; data <= X"FF";
            -- when X"1C"  =>  address <= X"DE"; data <= X"10";
            -- when X"1D"  =>  address <= X"E4"; data <= X"60";
            -- when X"1E"  =>  address <= X"FA"; data <= X"7D";
            -- ######## END CONFIGURATION FROM DE10 NANO HDMI TX EXAMPLE ###############

            when others =>  address <= X"98"; data <= X"03";
            
        end case;
    end process;
end rtl;
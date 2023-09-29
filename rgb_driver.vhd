library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- use std.env.all;

-- https://github.com/mfro0/deca_mem/blob/master/vga_generator.vhd

entity rgb_driver is 
    port (
        rgb_clk_i               : in std_logic;
        rgb_rst_n_i             : in std_logic;
        transceiver_ready       : in std_logic;
        rgb_pixel_data_o        : out std_logic_vector(23 downto 0);
        rgb_vsync_o             : out std_logic;
        rgb_hsync_o             : out std_logic;
        rgb_data_enable_o       : out std_logic
    );
end rgb_driver;

architecture rtl of rgb_driver is 

subtype v_int is integer range 0 to 4095;
subtype byte is integer range 0 to 255;
type video_timing_type is record
    h_total,
    h_sync,
    h_start,
    h_end,
    v_total,
    v_sync,
    v_start,
    v_end           : v_int;
end record video_timing_type;

type video_timings_array_type is array(natural range <>) of video_timing_type;

--###############################################################################
-- VIDEO TIMING INFORMATION -- see table 25 in ADV7153 programming guide for rough estimates
constant video_timings  : video_timings_array_type :=
(
    (
        -- 640x480@60 25.175 MHZ
        h_total => 799, h_sync => 95, h_start => 141, h_end => 781, -- (h_end - h_start = 640)
        v_total => 524, v_sync => 1, v_start => 54, v_end => 741
    ),
    (
        -- 720x480@60 27MHZ (VIC=3, 480P)
        h_total => 857, h_sync => 61, h_start => 119, h_end => 839,
        v_total => 524, v_sync => 5, v_start => 35, v_end => 515
    ),
    (
        -- 1024x768@60 65MHZ (XGA)
        h_total => 1343, h_sync => 135, h_start => 293, h_end => 1317,
        v_total => 805, v_sync => 5, v_start => 34, v_end => 802
    ),
    (
        -- 1280x1024@60   108MHZ (SXGA)
        h_total => 1687, h_sync => 111, h_start => 357, h_end => 1637,
        v_total => 1065, v_sync => 2, v_start => 40, v_end => 1064
    ),
    (
        -- 1920x1080p60 148.5MHZ
        h_total => 2199, h_sync => 43, h_start => 189, h_end => 2109,
        v_total => 1124, v_sync => 4, v_start => 40, v_end => 1120
    ),
    (
        -- 1920x1080p60 148.5MHZ
        h_total => 2199, h_sync => 88, h_start => 191, h_end => 2109,
        v_total => 1124, v_sync => 4, v_start => 45, v_end => 1120
    ),
    (
        -- 1600x1200p60 162MHZ (VESA)
        h_total => 2159, h_sync => 191, h_start => 493, h_end => 2093,
        v_total => 1249, v_sync => 2, v_start => 48, v_end => 1248
    )
);
--###############################################################################

constant current_timing     : video_timing_type := video_timings(5); -- 1920 x 1080 selected as current timing information

signal RED          : natural range 0 to 255 := 0;
signal GREEN        : natural range 0 to 255 := 0;
signal BLUE         : natural range 0 to 255 := 0;

signal  v_count,
        h_count : v_int;

signal pixel_x  : byte;

-- signals to indicate if in active display region
signal  h_act,
        h_act_d,
        v_act,
        v_act_d         : std_logic;

-- signals to indicate bounds of frame
signal  h_max,
        hs_end,
        hr_start,
        hr_end,
        v_max,
        vs_end,
        vr_start,
        vr_end          : std_logic;

signal  h_total,
        h_sync,
        h_start,
        h_end,
        v_total,
        v_sync,
        v_start,
        v_end           : v_int;

signal rgb_data_en_pre  : std_logic;


begin

    h_total     <= current_timing.h_total;
    h_sync      <= current_timing.h_sync;
    h_start     <= current_timing.h_start;
    h_end       <= current_timing.h_end;

    v_total     <= current_timing.v_total;
    v_sync      <= current_timing.v_sync;
    v_start     <= current_timing.v_start;
    v_end       <= current_timing.v_end;

    h_max <= '1' when h_count = h_total else '0';       -- indicate h_count hit max value for selected timing
    hs_end <= '1' when h_count >= h_sync else '0';      -- indicate h_sync has ended its duration
    hr_start <= '1' when h_count = h_start else '0';    -- indicate horziontal row is active
    hr_end <= '1' when h_count = h_end else '0';        -- inidcate horizontal row is now inactive

    v_max <= '1' when v_count = v_total else '0';
    vs_end <= '1' when v_count >= v_sync else '0';
    vr_start <= '1' when v_count = v_start else '0';
    vr_end <= '1' when v_count = v_end else '0';

rgb_pixel_data_o <= std_logic_vector(to_unsigned(RED, 8)) &
                    std_logic_vector(to_unsigned(GREEN, 8)) & 
                    std_logic_vector(to_unsigned(BLUE, 8));

p_horizontal    : process(all)
begin
    if (not rgb_rst_n_i) or (not transceiver_ready) then
        h_act           <= '0';
        h_act_d         <= '0';
        h_count         <= 0;
        rgb_hsync_o     <= '0'; -- flipped

    elsif rising_edge(rgb_clk_i) then

        h_act_d     <= h_act;
        
        -- manage counter
        if h_max then
            h_count <= 0;
        else
            h_count <= h_count + 1;
        end if;

        -- increment pixel value
        if h_act_d = '1' then
            if pixel_x < byte'high then
                pixel_x <= (pixel_x + 1); -- simple mod 255
            else
                pixel_x <= 0;
            end if;
        else
            pixel_x <= 0;
        end if;

        if hs_end and not h_max then
            rgb_hsync_o <= '0'; -- flipped
        else
            rgb_hsync_o <= '1'; -- flipped
        end if;

        if hr_start then
            h_act <= '1';
        elsif hr_end then
            h_act <= '0';
        end if;

    end if;
end process p_horizontal;

p_vertical : process(all)
begin
    if (not rgb_rst_n_i) or (not transceiver_ready) then

        v_act_d         <= '0';
        v_count         <= 0;
        rgb_vsync_o     <= '0'; -- change to 0 from 1 (basically flipping polarity on vsync)
        v_act           <= '0';

    elsif rising_edge(rgb_clk_i) then
        if h_max then
            v_act_d <= v_act;

            if v_max then
                v_count <= 0;
                -- ONE_FRAME_DONE  <= '1';
            else
                v_count <= v_count + 1;
            end if;

            if vs_end and not v_max then
                rgb_vsync_o <= '0'; -- change to 0 from 1
            else
                rgb_vsync_o <= '1'; -- change to 1 from 0 
            end if;

            if vr_start then
                v_act <= '1';
            elsif vr_end then
                v_act <= '0';
            end if;
        end if;

    end if;
end process p_vertical;


p_pattern   : process(all)
    -- variable p_x    : std_ulogic_vector(7 downto 0);
begin
    if (not rgb_rst_n_i) or (not transceiver_ready) then
        rgb_data_enable_o   <= '0';
        rgb_data_en_pre     <= '0';         --- add this signal

    elsif rising_edge(rgb_clk_i) then
        
        rgb_data_enable_o   <= rgb_data_en_pre;
        rgb_data_en_pre     <= (v_act and h_act); -- only enable data enable pin when both H and V are active

        -- p_x := std_ulogic_vector(to_unsigned(pixel_x, 8));

        RED     <= pixel_x;
        GREEN   <= 0;
        BLUE    <= 0;
    end if;
end process p_pattern;

end rtl;
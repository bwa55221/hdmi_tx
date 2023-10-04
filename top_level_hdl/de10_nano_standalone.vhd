LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.numeric_std.all;

-- name of top level entity must match top level vhdl file name otherwise
-- compiler returns error "top level entity undefined"

entity de10_nano_standalone is
    port(
        FPGA_CLK1_50            : in std_logic;
        RST_N                   : in std_logic;

        HPS_DDR3_ADDR           : out std_logic_vector(14 downto 0);
        HPS_DDR3_BA             : out std_logic_vector(2 downto 0);
        HPS_DDR3_CAS_N          : out std_logic;
        HPS_DDR3_CK_N           : out std_logic;
        HPS_DDR3_CK_P           : out std_logic;
        HPS_DDR3_CKE            : out std_logic;
        HPS_DDR3_CS_N           : out std_logic;
        HPS_DDR3_DM             : out std_logic_vector(3 downto 0);
        HPS_DDR3_DQ             : inout std_logic_vector(31 downto 0);
        HPS_DDR3_DQS_N          : inout std_logic_vector(3 downto 0);
        HPS_DDR3_DQS_P          : inout std_logic_vector(3 downto 0);
        HPS_DDR3_ODT            : out std_logic;
        HPS_DDR3_RAS_N          : out std_logic;
        HPS_DDR3_RESET_N        : out std_logic;
        HPS_DDR3_RZQ            : in std_logic;
        HPS_DDR3_WE_N           : out std_logic;

        HDMI_I2C_SCL            : inout std_logic;
        HDMI_I2C_SDA            : inout std_logic;
        HDMI_TX_D               : out std_logic_vector(23 downto 0);
        HDMI_TX_CLK             : out std_logic;
        HDMI_TX_DE              : out std_logic;
        HDMI_TX_HS              : out std_logic;
        HDMI_TX_VS              : out std_logic
    );
end entity de10_nano_standalone;


architecture rtl of de10_nano_standalone is

-- COMPONENT DECLARATIONS --

    component soc_system is
        -- these lines below are copied from the soc_system.vhd that is generated from the Platform Designer
        -- ideally just update these lines any time the platform designer is updated

        port (
            clk_clk                  : in    std_logic                     := '0';             --             clk.clk
            hps_0_h2f_reset_reset_n  : out   std_logic;                                        -- hps_0_h2f_reset.reset_n
            hps_bridge_waitrequest   : in    std_logic                     := '0';             --      hps_bridge.waitrequest
            hps_bridge_readdata      : in    std_logic_vector(63 downto 0) := (others => '0'); --                .readdata
            hps_bridge_readdatavalid : in    std_logic                     := '0';             --                .readdatavalid
            hps_bridge_burstcount    : out   std_logic_vector(0 downto 0);                     --                .burstcount
            hps_bridge_writedata     : out   std_logic_vector(63 downto 0);                    --                .writedata
            hps_bridge_address       : out   std_logic_vector(9 downto 0);                     --                .address
            hps_bridge_write         : out   std_logic;                                        --                .write
            hps_bridge_read          : out   std_logic;                                        --                .read
            hps_bridge_byteenable    : out   std_logic_vector(7 downto 0);                     --                .byteenable
            hps_bridge_debugaccess   : out   std_logic;                                        --                .debugaccess
            memory_mem_a             : out   std_logic_vector(14 downto 0);                    --          memory.mem_a
            memory_mem_ba            : out   std_logic_vector(2 downto 0);                     --                .mem_ba
            memory_mem_ck            : out   std_logic;                                        --                .mem_ck
            memory_mem_ck_n          : out   std_logic;                                        --                .mem_ck_n
            memory_mem_cke           : out   std_logic;                                        --                .mem_cke
            memory_mem_cs_n          : out   std_logic;                                        --                .mem_cs_n
            memory_mem_ras_n         : out   std_logic;                                        --                .mem_ras_n
            memory_mem_cas_n         : out   std_logic;                                        --                .mem_cas_n
            memory_mem_we_n          : out   std_logic;                                        --                .mem_we_n
            memory_mem_reset_n       : out   std_logic;                                        --                .mem_reset_n
            memory_mem_dq            : inout std_logic_vector(31 downto 0) := (others => '0'); --                .mem_dq
            memory_mem_dqs           : inout std_logic_vector(3 downto 0)  := (others => '0'); --                .mem_dqs
            memory_mem_dqs_n         : inout std_logic_vector(3 downto 0)  := (others => '0'); --                .mem_dqs_n
            memory_mem_odt           : out   std_logic;                                        --                .mem_odt
            memory_mem_dm            : out   std_logic_vector(3 downto 0);                     --                .mem_dm
            memory_oct_rzqin         : in    std_logic                     := '0';             --                .oct_rzqin
            reset_reset_n            : in    std_logic                     := '0';             --           reset.reset_n
            vid_clk_165mhz_clk       : out   std_logic                                         --           vid_clk_165mhz.clk
        );
    end component;
	 
	component avmm_slave is
	     port(
			  WAIT_REQ        : out std_logic;
			  READ_DATA       : out std_logic_vector(63 downto 0);
			  READ_DATA_VALID : out std_logic;

			  CLK			  : in std_logic;
			  WRITE_DATA      : in std_logic_vector(63 downto 0);
			  ADDRESS         : in std_logic_vector(9 downto 0);
			  WRITE_CMD       : in std_logic;
			  READ_CMD        : in std_logic;
			  BYTE_ENABLE     : in std_logic_vector(7 downto 0);
			  DEBUG_ACCESS    : in std_logic
		 );
        end component;

    component adv7513_driver is 
        port (
            SYS_CLK         : in std_logic;
            SYS_RST_n       : in std_logic;
            ADV_I2C_SCL     : inout std_logic;
            ADV_I2C_SDA     : inout std_logic;
            CONFIG_STATUS   : out std_logic
        );
    end component;

    component reset_counter is 
        port (
            clk_i           : in std_logic;
            reset_n_o       : out std_logic
        );
    end component;

    component rgb_driver is 
        port (
            rgb_clk_i               : in std_logic;
            rgb_rst_n_i             : in std_logic;
            transceiver_ready       : in std_logic;
            rgb_pixel_data_o        : out std_logic_vector(23 downto 0);
            rgb_vsync_o             : out std_logic;
            rgb_hsync_o             : out std_logic;
            rgb_data_enable_o       : out std_logic
        );
    end component;
--******************* GLUE LOGIC BEGIN **********************--

-- define signals to connect the avmm custom slave to the hps
signal h2s_wait_req, h2s_read_dv, h2s_write_cmd, h2s_read_cmd, h2s_debug_access : std_logic := '0';
signal h2s_read_data, h2s_write_data                                            : std_logic_vector(63 downto 0) := (others => '0');
signal h2s_address                                                              : std_logic_vector(9 downto 0) := (others => '0');
signal h2s_byte_enable                                                          : std_logic_vector(7 downto 0) := (others => '0');

signal pixel_clock_interconnect         : std_logic;    -- define signals to connect hps, rgb_driver, and adv7513 configuration module
signal transceiver_ready_interconnect   : std_logic;

-- signal RST_N        : std_logic;     -- toggle for use with reset counter vs RST_N button

begin

    HDMI_TX_CLK     <= pixel_clock_interconnect;    -- connect pll output to physical clock input on ADV7513 also

-- instantiate any ip/component blocks and map their I/O to top level I/O for pin assignments
soc0 : component soc_system
    port map (
        -- global generic
        clk_clk             => FPGA_CLK1_50,
        reset_reset_n       => RST_N,

        -- DDR3
        memory_mem_a        => HPS_DDR3_ADDR,
        memory_mem_ba       => HPS_DDR3_BA,
        memory_mem_cas_n    => HPS_DDR3_CAS_N,
        memory_mem_ck_n     => HPS_DDR3_CK_N,
        memory_mem_ck       => HPS_DDR3_CK_P,
        memory_mem_cke      => HPS_DDR3_CKE,
        memory_mem_cs_n     => HPS_DDR3_CS_N,
        memory_mem_dm       => HPS_DDR3_DM,
        memory_mem_dq       => HPS_DDR3_DQ,
        memory_mem_dqs_n    => HPS_DDR3_DQS_N,
        memory_mem_dqs      => HPS_DDR3_DQS_P,
        memory_mem_odt      => HPS_DDR3_ODT,
        memory_mem_ras_n    => HPS_DDR3_RAS_N,
        memory_mem_reset_n  => HPS_DDR3_RESET_N,
        memory_oct_rzqin    => HPS_DDR3_RZQ,
        memory_mem_we_n     => HPS_DDR3_WE_N,

        -- linking to avalon mm custom slave
        hps_bridge_waitrequest      => h2s_wait_req,
        hps_bridge_readdata         => h2s_read_data,
        hps_bridge_readdatavalid    => h2s_read_dv,
        hps_bridge_writedata        => h2s_write_data,
        hps_bridge_address          => h2s_address,
        hps_bridge_write            => h2s_write_cmd,
        hps_bridge_read             => h2s_read_cmd,
        hps_bridge_byteenable       => h2s_byte_enable,
        hps_bridge_debugaccess      => h2s_debug_access,

        -- linking pll output to rgb_driver
        vid_clk_165mhz_clk          => pixel_clock_interconnect
    );
	 
slave0	: component avmm_slave
			port map (
			  WAIT_REQ          => h2s_wait_req,
			  READ_DATA         => h2s_read_data,
			  READ_DATA_VALID   => h2s_read_dv,

			  CLK			    => FPGA_CLK1_50,
			  WRITE_DATA        => h2s_write_data,
			  ADDRESS           => h2s_address,
			  WRITE_CMD         => h2s_write_cmd,
			  READ_CMD          => h2s_read_cmd,
			  BYTE_ENABLE       => h2s_byte_enable,
			  DEBUG_ACCESS      => h2s_debug_access
            );
	
adv0    : component adv7513_driver
            port map( 
                SYS_CLK         => pixel_clock_interconnect, -- connect logic to pixel clock since this is the clock feeding the hardware.
                SYS_RST_n       => RST_N,
                ADV_I2C_SCL     => HDMI_I2C_SCL,
                ADV_I2C_SDA     => HDMI_I2C_SDA,
                CONFIG_STATUS   => transceiver_ready_interconnect
            );

-- reset0  : component reset_counter
--             port map (
--                 clk_i           =>  FPGA_CLK1_50,
--                 reset_n_o       =>  RST_N
--             );

rgb0    : component rgb_driver
            port map (
                rgb_clk_i               => pixel_clock_interconnect,    -- this needs to run at pixel clock rate (165 MHz)
                rgb_rst_n_i             => RST_N,
                rgb_pixel_data_o        => HDMI_TX_D,
                rgb_vsync_o             => HDMI_TX_VS,
                rgb_hsync_o             => HDMI_TX_HS,
                rgb_data_enable_o       => HDMI_TX_DE,
                transceiver_ready       => transceiver_ready_interconnect
            );

end architecture rtl;
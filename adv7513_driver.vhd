library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- use for all other maths and "to_integer()"
use IEEE.std_logic_unsigned.all; -- get the "+" operator for std_logic_vector
use work.all;
use work.custom_pkg.all;

entity adv7513_driver is 
    port (
        SYS_CLK         : in std_logic;
        SYS_RST_n       : in std_logic;
        ADV_I2C_SCL     : inout std_logic;
        ADV_I2C_SDA     : inout std_logic;
        CONFIG_STATUS   : out std_logic
    );
    end adv7513_driver;

architecture rtl of adv7513_driver is

    component i2c_controller is
        port (
            IIC_RST_N       : in std_logic;
            IIC_CLK         : in std_logic;
            IIC_SDA         : inout std_logic;
            IIC_SCL         : inout std_logic;
    
            WRITE_REQ       : in std_logic;
            WRITE_DONE      : out std_logic;
    
            READ_REQ        : in std_logic;
            READ_DONE       : out std_logic;

            IIC_ADDR        : in std_logic_vector(6 downto 0);
            IIC_DATA        : inout iic_data_array;
            IIC_CTRL_READY  : out std_logic
        );
        end component;

    component reg_lut is
        port(
            count           : in std_logic_vector(7 downto 0);
            address         : out std_logic_vector(7 downto 0);
            data            : out std_logic_vector(7 downto 0)
        );
        end component;


-- LUT wires
signal lut_count, lut_address, lut_data : std_logic_vector(7 downto 0);
signal lut_count_w, lut_address_w, lut_data_w : std_logic_vector(7 downto 0);

-- iic controller wires
signal  WRITE_REQ_w,
        WRITE_DONE_w,
        READ_REQ_w,
        READ_DONE_w,
        IIC_CTRL_READY_w     : std_logic;

signal IIC_ADDR_w   : std_logic_vector(6 downto 0);
signal IIC_DATA_w   : iic_data_array;


-- CONSTANTS
constant ADV7513_I2C_ADDR : std_logic_vector(6 downto 0) := "0111001"; -- 0x72
constant LUT_REG_COUNT_MAX  : natural := 14;

-- state machines
type state_type_adv7513 is (IDLE,
                            CONFIGURE,
                            MONITOR);
signal ADV7513_STATE : state_type_adv7513;

type configuration_state_type is (
                                    IDLE,
                                    WRITE_OUT_LUT,
                                    WAIT_FOR_WRITE_DONE,
                                    READBACK_REGISTER,
                                    WAIT_FOR_READ_DONE,
                                    LOAD_NEXT,
                                    DONE,
                                    ERROR);
signal CONFIGURATION_STATE : configuration_state_type;                                    


-- simulation signals
-- signal SYS_CLK      : std_logic := '0';
-- signal SYS_RST_n    : std_logic := '0';
-- signal ADV_I2C_SCL, ADV_I2C_SDA : std_logic := 'Z';

begin

    -- ******
    -- simulation drivers
    -- SYS_CLK <= not SYS_CLK after 500 ps;
    -- SYS_RST_n   <= '1' after 500 ps;
    -- ******

    -- connect wires to process signals
    lut_count_w         <= lut_count;
    lut_address         <= lut_address_w;
    lut_data            <= lut_data_w;

    i2c_controller0 : component i2c_controller
        port map (
            IIC_RST_N       => SYS_RST_n,
            IIC_CLK         => SYS_CLK,
            IIC_SDA         => ADV_I2C_SDA,
            IIC_SCL         => ADV_I2C_SCL,
            WRITE_REQ       => WRITE_REQ_w,
            WRITE_DONE      => WRITE_DONE_w,
            READ_REQ        => READ_REQ_w,
            READ_DONE       => READ_DONE_w,
            IIC_ADDR        => IIC_ADDR_w,
            IIC_DATA        => IIC_DATA_w,
            IIC_CTRL_READY  => IIC_CTRL_READY_w
        );

    reg_lut_0 : component reg_lut
    port map (
        count       => lut_count_w,
        address     => lut_address_w,
        data        => lut_data_w
    );

    process(SYS_CLK)
    begin
        if SYS_CLK'event and SYS_CLK = '1' then
            if SYS_RST_n = '0' then

                lut_count               <= X"00";
                WRITE_REQ_w             <= '0';
                READ_REQ_w              <= '0';
                
                ADV7513_STATE           <= CONFIGURE;
                CONFIGURATION_STATE     <= IDLE;

                CONFIG_STATUS           <= '0';

            else

                case ADV7513_STATE is 
                    
                    when IDLE =>
                        null;

                    when CONFIGURE  =>

                        case CONFIGURATION_STATE is 
                            when IDLE   =>
                                lut_count   <= X"00";
                                
                                if IIC_CTRL_READY_w then
                                    CONFIGURATION_STATE <= WRITE_OUT_LUT;
                                end if;

                            when WRITE_OUT_LUT          =>
                                IIC_ADDR_w              <= ADV7513_I2C_ADDR;
                                IIC_DATA_w(0)           <= lut_address_w;
                                IIC_DATA_w(1)           <= lut_data_w;
                                WRITE_REQ_w             <= '1';
                                CONFIGURATION_STATE     <= WAIT_FOR_WRITE_DONE;

                            when WAIT_FOR_WRITE_DONE    =>
                                WRITE_REQ_w             <= '0';

                                if WRITE_DONE_w then
                                    CONFIGURATION_STATE <= READBACK_REGISTER;
                                end if;
                            
                            when READBACK_REGISTER      =>
                                READ_REQ_w              <= '1';
                                CONFIGURATION_STATE     <= WAIT_FOR_READ_DONE;

                            when WAIT_FOR_READ_DONE     =>
                                READ_REQ_w              <= '0';

                                if READ_DONE_w then
                                    if IIC_DATA_w(1) = lut_data_w then

                                        if to_integer(unsigned(lut_count)) = LUT_REG_COUNT_MAX then
                                            CONFIGURATION_STATE <= DONE;
                                        else
                                            CONFIGURATION_STATE <= LOAD_NEXT;
                                        end if;
                                    else
                                        CONFIGURATION_STATE <= ERROR;
                                    end if;
                                end if;
                            
                            when LOAD_NEXT              =>
                                lut_count               <= lut_count + X"01";
                                CONFIGURATION_STATE     <= WRITE_OUT_LUT;

                            when DONE                   =>
                                ADV7513_STATE           <= IDLE;
                                CONFIG_STATUS           <= '1';

                            when ERROR                  =>
                                null;   
                        end case;                            

                    when MONITOR    =>
                        null;
                end case;
            end if;
        end if;
    end process;

end rtl;

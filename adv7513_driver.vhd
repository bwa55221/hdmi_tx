library ieee;
use ieee.std_logic_1164.all;
use work.all;

entity adv7513_driver is 
    port (
        
        -- HDMI_TX_D       : out std_logic_vector(23 downto 0);
        -- HDMI_TX_VS      : out std_logic;
        -- HDMI_TX_HS      : out std_logic;
        -- HDMI_TX_INT     : out std_logic;
        -- HDMI_TX_DE      : out std_logic;
        -- HDMI_TX_CLK     : out std_logic;
        -- HDMI_SCLK       : out std_logic;
        -- HDMI_MCLK       : out std_logic;
        -- HDMI_LRCLK      : out std_logic;
        -- HDMI_I2S        : out std_logic;
        HDMI_I2C_SCL    : inout std_logic;
        HDMI_I2C_SDA    : inout std_logic;

        SYS_CLK         : in std_logic;
        SYS_RST         : in std_logic
    );
    end adv7513_driver;

architecture rtl of adv7513_driver is

    component i2c_master is
        generic(
            input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
            bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz

        port(
            clk       : IN     STD_LOGIC;                    --system clock
            reset_n   : IN     STD_LOGIC;                    --active low reset
            ena       : IN     STD_LOGIC;                    --latch in command
            addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
            rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
            data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
            busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
            data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
            ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
            sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
            scl       : INOUT  STD_LOGIC                     --serial clock output of i2c bus
        );
    end component;

    component reg_lut is
        port(
            count           : in std_logic_vector(7 downto 0);
            address         : out std_logic_vector(7 downto 0);
            data            : out std_logic_vector(7 downto 0)
        );
        end component;

-- i2c master wires
signal i2c_reset_n, i2c_ena, i2c_rw : std_logic := '1';
signal i2c_busy, i2c_ack_error : std_logic;
signal i2c_addr : std_logic_vector(6 downto 0);
signal i2c_data_wr, i2c_data_rd : std_logic_vector(7 downto 0);

-- LUT wires
signal lut_count, lut_address, lut_data : std_logic_vector(7 downto 0);

-- CONSTANTS
constant ADV7513_I2C_ADDR : std_logic_vector(6 downto 0) := "0111001"; -- 0x72

-- state machines
type state_type_adv7513 is (IDLE, START, WRITE_REG_ADDR);
signal ADV7513_STATE : state_type_adv7513 := IDLE;


begin

   i2c_master_0 : component i2c_master
    port map (
        clk         => SYS_CLK,
        reset_n     => i2c_reset_n,
        ena         => i2c_ena,
        addr        => i2c_addr,
        rw          => i2c_rw,
        data_wr     => i2c_data_wr,
        busy        => i2c_busy,
        data_rd     => i2c_data_rd,
        ack_error   => i2c_ack_error,
        sda         => HDMI_I2C_SDA, -- connect these directly to top level outputs
        scl         => HDMI_I2C_SCL  -- connect these directly to top level outputs
    );

    reg_lut_0 : component reg_lut
        port map (
            count       => lut_count,
            address     => lut_address,
            data        => lut_data
        );

    process(SYS_CLK)
    begin
        if SYS_CLK'event and SYS_CLK = '1' then
            if SYS_RST = '1' then
                null;
            else

                case ADV7513_STATE is 
                    when IDLE =>

                        -- if (some start condition) then
                            -- go to next state
                        -- else  ADV7513_STATE <= IDLE;
                        
                        ADV7513_STATE <= START;

                    when START =>
                            null;
                            -- increment counter to a ROM
                            ADV7513_STATE <= WRITE_REG_ADDR;

                    when WRITE_REG_ADDR =>
                            i2c_ena     <= '1';
                            i2c_rw      <= '0';
                            i2c_addr    <= ADV7513_I2C_ADDR;
                            -- i2c_data_wr <= 

                end case;
            end if;
        end if;
    end process;

end rtl;

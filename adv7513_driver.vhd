library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- use for all other maths and "to_integer()"
-- use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all; -- get the "+" operator for std_logic_vector
use work.all;
-- use std.env.all;

entity adv7513_driver is 
    port (
        SYS_CLK         : in std_logic;
        SYS_RST_n       : in std_logic;
        ADV_I2C_SCL     : inout std_logic;
        ADV_I2C_SDA     : inout std_logic
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
signal lut_count_w, lut_address_w, lut_data_w : std_logic_vector(7 downto 0);

-- CONSTANTS
constant ADV7513_I2C_ADDR : std_logic_vector(6 downto 0) := "0111001"; -- 0x72
constant LUT_REG_COUNT_MAX  : natural := 13;

-- STATUS SIGNALS   
signal i2c_readback_error   : std_logic;
signal i2c_readback_request : std_logic;
signal i2c_busy_prev        : std_logic;
signal delay                : natural;

-- state machines
type state_type_adv7513 is (IDLE,
    START, ISSUE_WRITE_CMD, WAIT_FOR_BUSY_ASSERT, 
    WRITE_REG_ADDR, WRITE_REG_DATA,
    REQUEST_READBACK, REGISTER_READBACK,
    LOAD_NEXT_LUT_REG, ERROR_STATE, FINISHED);
signal ADV7513_STATE : state_type_adv7513;


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
        sda         => ADV_I2C_SDA, -- connect these directly to top level outputs
        scl         => ADV_I2C_SCL  -- connect these directly to top level outputs
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

                lut_count               <= X"FF";

                i2c_reset_n             <= '0';
                i2c_ena                 <= '0';
                i2c_rw                  <= '1';

                i2c_readback_request    <= '0';
                i2c_readback_error      <= '0';

                delay                   <= 0;
                ADV7513_STATE           <= IDLE;

            else
                
                i2c_busy_prev   <= i2c_busy; -- update this on every rising clock edge

                case ADV7513_STATE is 

                    when IDLE =>
                        i2c_reset_n     <= '1';

                        -- add some delay to make sure i2c master is stabilized out of reset
                        if delay = 250 then
                            ADV7513_STATE   <= START;
                        else
                            delay <= delay + 1;
                        end if;

                    when START =>
                        lut_count       <= X"00";                  -- reset counter for register lut
                        i2c_rw          <= '0';
                        ADV7513_STATE   <= ISSUE_WRITE_CMD;    -- send command to write first register

                    when ISSUE_WRITE_CMD =>
                        i2c_ena         <= '1';             -- issue command
                        i2c_addr        <= ADV7513_I2C_ADDR;
                        i2c_data_wr     <= lut_address;

                        if i2c_rw = '1' then
                            ADV7513_STATE   <= REGISTER_READBACK;
                        else
                            ADV7513_STATE   <= WAIT_FOR_BUSY_ASSERT;
                        end if;
                    
                    when WAIT_FOR_BUSY_ASSERT =>
                        
                        -- rising edge state transition
                        if (i2c_busy = '1' and i2c_busy_prev = '0') then
                            ADV7513_STATE   <= WRITE_REG_ADDR;
                        end if;

                    WHEN WRITE_REG_ADDR =>
                        if i2c_readback_request = '1' then
                            i2c_rw          <= '1';
                        else
                            i2c_data_wr     <= lut_data;             -- latch new data in for writing in next state
                        end if;
                        
                        -- falling edge state transition
                        if (i2c_busy = '0' and i2c_busy_prev = '1') then
                            if i2c_readback_request = '1' then
                                ADV7513_STATE   <= ISSUE_WRITE_CMD;
                            else
                                ADV7513_STATE   <= WRITE_REG_DATA;
                            end if;
                        end if;

                    when WRITE_REG_DATA =>
                        i2c_ena                 <= '0';         -- forces stop condition after writing data
                        i2c_readback_request    <= '1';
                        i2c_rw                  <= '0'; 

                        if (i2c_busy = '0' and i2c_busy_prev = '1' and i2c_readback_request = '1') then
                            ADV7513_STATE       <= ISSUE_WRITE_CMD;
                        end if;
                    
                    when REQUEST_READBACK =>
                        if (i2c_busy = '1' and i2c_busy_prev = '0') then
                            ADV7513_STATE   <= REGISTER_READBACK;
                        end if;

                    when REGISTER_READBACK =>
                        i2c_ena <= '0';

                        if (i2c_busy = '0' and i2c_busy_prev = '1') then
                            if i2c_data_rd /= lut_data then
                                i2c_readback_error <= '1';
                                ADV7513_STATE <= ERROR_STATE;
                            else
                                ADV7513_STATE <= LOAD_NEXT_LUT_REG;
                            end if;
                        end if;

                    when LOAD_NEXT_LUT_REG =>
                        i2c_rw                  <= '0';
                        i2c_readback_request    <= '0';

                        if to_integer(unsigned(lut_count)) < LUT_REG_COUNT_MAX then
                            lut_count <= lut_count + X"01";
                            ADV7513_STATE   <= ISSUE_WRITE_CMD;
                        else
                            ADV7513_STATE   <= FINISHED;
                        end if;

                    when FINISHED =>
                        null;
                        -- stop;

                    when ERROR_STATE =>
                        null;
                        -- stop;

                end case;

            end if;
        end if;
    end process;

end rtl;

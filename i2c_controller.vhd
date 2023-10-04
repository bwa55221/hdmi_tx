library ieee;
use ieee.std_logic_1164.all;
use work.custom_pkg.all;

entity i2c_controller is
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
    end i2c_controller;

architecture rtl of i2c_controller is

    component i2c_master is
        generic(
            input_clk : INTEGER := 148_500_000; --input clock speed from user logic in Hz
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

type i2c_state_type is (ENABLE_I2C_MASTER, IDLE, WRITE_BUS, READ_BUS);
signal CONTROL_STATE    : i2c_state_type;

type i2c_write_state_type is (IDLE, START, WAIT_FOR_BUSY_ASSERT, WRITE_FIRST_BYTE,
                            WRITE_SECOND_BYTE, DONE, CLEANUP);
signal WRITE_STATE      : i2c_write_state_type;

type i2c_read_state_type is (IDLE, START, WAIT_FOR_BUSY_ASSERT, WRITE_REG_ADDR,
                            REPEATED_START, READBACK, DONE, CLEANUP);
signal READ_STATE       : i2c_read_state_type;

signal i2c_reset_n, i2c_ena, i2c_rw : std_logic;
signal i2c_busy, i2c_ack_error      : std_logic;
signal i2c_addr                     : std_logic_vector(6 downto 0);
signal i2c_data_wr, i2c_data_rd     : std_logic_vector(7 downto 0);
signal i2c_busy_prev                : std_logic;

signal TARGET_ADDRESS           : std_logic_vector(6 downto 0);
signal FIRST_BYTE, SECOND_BYTE  : std_logic_vector(7 downto 0);

constant STARTUP_DELAY          : natural := 1000;        -- clocks to delay for i2c master to stabilize after reset
signal delay                    : natural;

begin

    i2c_master_0 : component i2c_master
        port map (
            clk         => IIC_CLK,
            reset_n     => i2c_reset_n,
            ena         => i2c_ena,
            addr        => i2c_addr,
            rw          => i2c_rw,
            data_wr     => i2c_data_wr,
            busy        => i2c_busy,
            data_rd     => i2c_data_rd,
            ack_error   => i2c_ack_error,
            sda         => IIC_SDA, -- connect these directly to top level outputs
            scl         => IIC_SCL  -- connect these directly to top level outputs
        );

TARGET_ADDRESS  <= IIC_ADDR;
FIRST_BYTE      <= IIC_DATA(0);
-- SECOND_BYTE     <= IIC_DATA(1); -- cannot leave this here because we also update this in the READ FSM

iic_control_p   : process(all)
begin

    if not IIC_RST_N then
        i2c_reset_n     <= '0';
        i2c_ena         <= '0';
        i2c_rw          <= '1';

        WRITE_DONE      <= '0';
        READ_DONE       <= '0';

        CONTROL_STATE   <= ENABLE_I2C_MASTER;
        WRITE_STATE     <= IDLE;
        READ_STATE      <= IDLE;
        IIC_CTRL_READY  <= '0';

        delay           <= 0;
    
    elsif rising_edge(IIC_CLK) then
        i2c_busy_prev   <= i2c_busy;
        IIC_CTRL_READY  <= '0';

        case CONTROL_STATE is 
            when ENABLE_I2C_MASTER   =>
                i2c_reset_n     <= '1';

                if delay = STARTUP_DELAY then
                    CONTROL_STATE   <= IDLE;
                else
                    delay <= delay + 1;
                end if;

            when IDLE   =>
                
                IIC_CTRL_READY      <= '1';

                if WRITE_REQ then
                    CONTROL_STATE   <= WRITE_BUS;
                end if;
                
                if READ_REQ then
                    CONTROL_STATE   <= READ_BUS;
                end if;

            when WRITE_BUS  =>

                case WRITE_STATE is 
                    when IDLE   =>
                        WRITE_DONE      <= '0';
                        WRITE_STATE     <= START;
                        SECOND_BYTE     <= IIC_DATA(1);

                    when START  =>
                        i2c_rw      <= '0';
                        i2c_ena     <= '1';
                        i2c_addr    <= TARGET_ADDRESS;
                        i2c_data_wr <= FIRST_BYTE;
                        WRITE_STATE <= WAIT_FOR_BUSY_ASSERT;

                    when WAIT_FOR_BUSY_ASSERT =>
                        if (i2c_busy = '1' and i2c_busy_prev = '0') then
                            WRITE_STATE <= WRITE_FIRST_BYTE;
                        end if;
                    
                    when WRITE_FIRST_BYTE =>
                        i2c_data_wr     <= SECOND_BYTE;

                        if (i2c_busy = '0' and i2c_busy_prev = '1') then
                            WRITE_STATE <= WRITE_SECOND_BYTE;
                        end if;

                    when WRITE_SECOND_BYTE =>
                        i2c_ena     <= '0';
                        -- i2c_rw      <= '0';
                        
                        if i2c_busy = '0' and i2c_busy_prev = '1' then
                            WRITE_STATE <= DONE;
                        end if;

                    when DONE =>
                        WRITE_STATE     <= CLEANUP;

                        if i2c_ack_error = '0' then
                            WRITE_DONE  <= '1';
                        end if;
                    
                    when CLEANUP =>
                        WRITE_DONE      <= '0';
                        WRITE_STATE     <= IDLE;
                        CONTROL_STATE   <= IDLE;

                end case;
            
            when READ_BUS   =>

                case READ_STATE is
                    when IDLE       =>
                        -- READ_DONE   <= '0';
                        READ_STATE  <= START;

                    when START      =>
                        i2c_rw      <= '0';
                        i2c_ena     <= '1';
                        i2c_addr    <= TARGET_ADDRESS;
                        i2c_data_wr <= FIRST_BYTE; -- send register address to be read
                        READ_STATE  <= WAIT_FOR_BUSY_ASSERT;

                    when WAIT_FOR_BUSY_ASSERT   =>
                        if (i2c_busy = '1' and i2c_busy_prev = '0') then
                            READ_STATE  <= WRITE_REG_ADDR;
                        end if;
                    
                    when WRITE_REG_ADDR     =>
                        i2c_rw      <= '1';
                        if (i2c_busy = '0' and i2c_busy_prev = '1') then
                            READ_STATE  <= REPEATED_START;
                        end if;
                                            
                    when REPEATED_START      =>
                        i2c_ena     <= '1';
                        READ_STATE  <= READBACK;

                    when READBACK    =>
                        i2c_ena     <= '0';

                        if i2c_busy = '0' and i2c_busy_prev = '1' then
                            if not i2c_ack_error then
                                SECOND_BYTE     <= i2c_data_rd;
                                READ_STATE      <= DONE;
                            end if;
                        end if;

                    when DONE   =>
                        READ_STATE      <= CLEANUP;

                        if not i2c_ack_error then
                            READ_DONE   <= '1';
                        end if;

                    when CLEANUP    =>
                        READ_DONE       <= '0';
                        READ_STATE      <= IDLE;
                        CONTROL_STATE   <= IDLE;

                end case;
        end case;
    end if;
end process iic_control_p;

end rtl;

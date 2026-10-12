library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.distance_meter_pack.all;

entity sensor_driver_tb is
end entity;

architecture tb of sensor_driver_tb is

  component sensor_driver is
    generic (G_RESET_ACTIVE_VALUE : std_logic := '0');
    port (
      CLK            : in  std_logic;
      RST            : in  std_logic;
      TRIG_IN        : in  std_logic;
      ECHO           : in  std_logic;
      TRIG_OUT       : out std_logic;
      DURATION       : out std_logic_vector(11 downto 0);
      DURATION_VALID : out std_logic
    );
  end component;
  
  component ultrasonic_sensor_sim is
	port (
	TRIG        : in    std_logic;
	ECHO        : out   std_logic
	);
	end component;


  constant s_G_RESET_ACTIVE_VALUE : std_logic := '0';
    signal run             : std_logic := '1';
    signal s_RST           : std_logic := '0';
    signal s_CLK           : std_logic := '0';
    signal s_TRIG_IN       : std_logic := '0';
    signal s_TRIG_OUT      : std_logic;
    signal s_DURATION_VALID : std_logic;
    signal s_ECHO          : std_logic := '0';
    signal s_DURATION      : std_logic_vector(11 downto 0);

begin

  dut:sensor_driver
    generic map (G_RESET_ACTIVE_VALUE => '0')
    port map (
      CLK            => s_CLK,
      RST            => s_RST,
      TRIG_IN        => s_TRIG_IN,
      ECHO           => s_ECHO,
      TRIG_OUT       => s_TRIG_OUT,
      DURATION       => s_DURATION,
      DURATION_VALID => s_DURATION_VALID
    );

	usim:ultrasonic_sensor_sim
	port map(
		TRIG => s_TRIG_OUT,
		ECHO => s_ECHO
	);

    
    run <= '1', '0' after 125 ms; 
    process begin
        while run = '1' loop
            s_CLK <= '1'; wait for 10 ns;
            s_CLK <= '0'; wait for 10 ns;
        end loop;
        wait;
    end process;

s_RST <= '1','0' after 1 ms ,'1' after 2 ms; 
         
s_TRIG_IN <= '0', 
			 '1' after 2 ms,   '0' after 2 ms + 20 ns,    
			 '1' after 30 ms,  '0' after 30 ms + 20 ns,   
			 '1' after 63 ms, '0' after 63 ms+ 20 ns;  
end architecture;

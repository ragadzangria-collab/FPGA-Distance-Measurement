library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.distance_meter_pack.all;

entity measure_distance_tb is
end entity;

architecture tb of measure_distance_tb is

  component measure_distance is
    generic (
      G_RESET_ACTIVE_VALUE : std_logic := '0'
    );
    port (
      CLK            : in  std_logic;
      RST            : in  std_logic;
      MEASURE_REQ    : in  std_logic;
      ECHO           : in  std_logic;
      TRIG_OUT       : out std_logic;
      DISTANCE       : out std_logic_vector(9 downto 0);
      DISTANCE_VALID : out std_logic
    );
  end component;

  component ultrasonic_sensor_sim is
    port (
      TRIG : in  std_logic;
      ECHO : out std_logic
    );
  end component;

  signal s_CLK            : std_logic := '0';
  signal s_RST            : std_logic := '0';
  signal s_MEASURE_REQ    : std_logic := '0';
  signal s_TRIG_OUT       : std_logic;
  signal s_ECHO           : std_logic;
  signal s_DISTANCE       : std_logic_vector(9 downto 0);
  signal s_DISTANCE_VALID : std_logic;
  signal run             : std_logic := '1';
  constant s_G_RESET_ACTIVE_VALUE : std_logic := '0';

begin

  -- DUT
  dut : measure_distance
    generic map (G_RESET_ACTIVE_VALUE => '0')
    port map (
      CLK            => s_CLK,
      RST            => s_RST,
      MEASURE_REQ    => s_MEASURE_REQ,
      ECHO           => s_ECHO,
      TRIG_OUT       => s_TRIG_OUT,
      DISTANCE       => s_DISTANCE,
      DISTANCE_VALID => s_DISTANCE_VALID
    );

  -- Ultrasonic sensor model
  usim : ultrasonic_sensor_sim
    port map (
      TRIG => s_TRIG_OUT,
      ECHO => s_ECHO
    );

  run <= '1', '0' after 700 ms;  

  clk_proc : process
  begin
    while run = '1' loop
      s_CLK <= '1'; wait for 10 ns;
      s_CLK <= '0'; wait for 10 ns;
    end loop;
    wait;
  end process;

  s_RST <= '0','1' after 2 ms;


  s_MEASURE_REQ <= '0',
    '1' after 6 ms,     '0' after 6 ms+ 20 ns,
	'1' after 120 ms,'0' after 120 ms+20 ns,
	'1' after 300 ms,'0' after 300 ms+ 20 ns;

end architecture;


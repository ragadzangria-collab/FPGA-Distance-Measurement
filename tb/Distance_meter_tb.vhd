
library ieee;
use ieee.std_logic_1164.all;

entity Distance_meter_tb is
end entity;

architecture struct of Distance_meter_tb is
component Distance_meter is
generic (
    G_RESET_ACTIVE_VALUE   : std_logic := '0'
);
port (
    CLK             : in    std_logic;  
    RST             : in    std_logic;  
    ECHO            : in    std_logic;  
    START_MEASURE   : in    std_logic;  
    MODE            : in    std_logic ; 
	NUM_ONES        : out   std_logic_vector(6 downto 0) ;
	NUM_TENS        : out   std_logic_vector(6 downto 0) ;
	NUM_HUNDS       : out   std_logic_vector(6 downto 0) ;
	NUM_THOUS       : out   std_logic_vector(6 downto 0) ;
	MODE_LED        : out    std_logic ;
	SER_TX          : out    std_logic ;
    TRIG_OUT        : out    std_logic 	
);
end component;
  
  component ultrasonic_sensor_sim is
    port (
      TRIG : in  std_logic;
      ECHO : out std_logic
    );
  end component;


    
    constant s_G_RESET_ACTIVE_VALUE : std_logic := '0';
    signal run             : std_logic := '1';
    signal s_RST           : std_logic := '0';
    signal s_CLK           : std_logic := '0';
	signal s_ECHO          : std_logic := '0';
	signal s_START_MEASURE       : std_logic := '0';
    signal s_MODE       : std_logic := '0';
	signal	s_NUM_ONES        :    std_logic_vector(6 downto 0):=(others=>'0') ;
	signal s_NUM_TENS        :   std_logic_vector(6 downto 0):=(others=>'0')  ;
	signal s_NUM_HUNDS       :    std_logic_vector(6 downto 0):=(others=>'0')  ;
	signal s_NUM_THOUS       :    std_logic_vector(6 downto 0):=(others=>'0')  ;
	signal s_MODE_LED        :    std_logic:= '0' ;
	signal s_SER_TX          :    std_logic:= '0' ;
    signal s_TRIG_OUT      : std_logic:= '0';

    
begin

    dut: Distance_meter
    generic map( G_RESET_ACTIVE_VALUE => s_G_RESET_ACTIVE_VALUE)
    port map (s_CLK,s_RST,s_ECHO,s_START_MEASURE,s_MODE,s_NUM_ONES,s_NUM_TENS,s_NUM_HUNDS,s_NUM_THOUS,s_MODE_LED,s_SER_TX,s_TRIG_OUT);
    
	
	 usim : ultrasonic_sensor_sim
    port map (
      TRIG => s_TRIG_OUT,
      ECHO => s_ECHO );


    run <= '1', '0' after 3000 ms;
    process begin
        while run = '1' loop
            s_CLK <= '1'; wait for 10 ns;
            s_CLK <= '0'; wait for 10 ns;
        end loop;
        wait;
    end process;

    -------------------------------------------------------
    -- הקפצות לבדיקת הלוגיקה וה-60us (זמנים ב-מיקרו)
    -------------------------------------------------------

    -- 1. איפוס (Reset)
    s_RST <= s_G_RESET_ACTIVE_VALUE, not s_G_RESET_ACTIVE_VALUE after 100 ns;

	--s_TRIG_OUT<= '0', '1' after 5 us, '0' after 7 us  ;
    s_START_MEASURE <= '0' , '1' after 1 us ,'0' after 2 us ,'1' after 300 ms ,'0' after 301 ms ; 
    s_MODE <= '0','1' after 200 ms,'0' after 301 ms  ;
end architecture;


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.distance_meter_pack.all;


entity Distance_meter is
generic (
    G_RESET_ACTIVE_VALUE   : std_logic := '0'
);
port (
    CLK             : in    std_logic;  
    RST             : in    std_logic;  
    ECHO            : in    std_logic;  
    START_MEASURE   : in    std_logic;  
    MODE            : in    std_logic; 
	NUM_ONES        : out   std_logic_vector(6 downto 0) ;
	NUM_TENS        : out   std_logic_vector(6 downto 0) ;
	NUM_HUNDS       : out   std_logic_vector(6 downto 0) ;
	NUM_THOUS       : out   std_logic_vector(6 downto 0) ;
	MODE_LED        : out    std_logic ;
	SER_TX          : out    std_logic ;
    TRIG_OUT        : out    std_logic 
);
end entity;

architecture behave of Distance_meter is 

component measure_distance 
generic (
    G_RESET_ACTIVE_VALUE   : std_logic := '0'
);
port (
    CLK             : in    std_logic;  
    RST             : in    std_logic;  
    MEASURE_REQ     : in    std_logic;  
    ECHO            : in    std_logic;  
    TRIG_OUT        : out   std_logic ; 
	DISTANCE        : out   std_logic_vector(9 downto 0) ;
	DISTANCE_VALID  : out   std_logic 
);
end component;

component controller 
generic (
    G_RESET_ACTIVE_VALUE   : std_logic := '0'
);
port (
    CLK             : in    std_logic;  
    RST             : in    std_logic;  
    DISTANCE        : in    std_logic_vector(9 downto 0);  
    DISTANCE_VALID  : in    std_logic;  
    START_MEASURE   : IN    std_logic; 
	MODE            : IN    std_logic;
	MEASURE_REQ     : out   std_logic;
	SEND            : out   std_logic;
	ONES            : out   std_logic_vector(3 downto 0);
	TENS            : out   std_logic_vector(3 downto 0);
	HUNDS           : out   std_logic_vector(3 downto 0);
	THOUS           : out   std_logic_vector(3 downto 0);
	ERROR           : out   std_logic;
	MODE_LED        : out   std_logic
);
end component;
component hex_to_7seg 
port(
    BCD_IN                      : in    std_logic_vector(3 downto 0);
    SHUTDOWNn                   : in    std_logic;
    D_OUT                       : out   std_logic_vector(6 downto 0));
end component;
       
component send_string is
port (
    CLK             : in    std_logic;
    RST             : in    std_logic;
    SEND            : in    std_logic;
    ONES            : in    std_logic_vector(3 downto 0);
    TENS            : in    std_logic_vector(3 downto 0);
    HUNDS           : in    std_logic_vector(3 downto 0);
    THOUS           : in    std_logic_vector(3 downto 0);
    ERROR           : in    std_logic;
    SER_TX          : out   std_logic
);
end component;
	
	constant s_G_RESET_ACTIVE_VALUE: std_logic:='0';
	signal s_DISTANCE: std_logic_vector(9 downto 0):= (others=>'0');
	signal s_DISTANCE_VALID,s_MESURE_REQ,s_SEND,s_ERROR,s_MODE: std_logic:='0';
	signal s_ONES,s_TENS,s_HUNDS,s_THOUS: std_logic_vector(3 downto 0) := (others=>'0');
	signal s_SHUTDOWNn: std_logic:='1';

 
	
begin

the_controller: controller
generic map( G_RESET_ACTIVE_VALUE => s_G_RESET_ACTIVE_VALUE)
port map(CLK,RST,s_DISTANCE,s_DISTANCE_VALID,START_MEASURE,MODE,s_MESURE_REQ,s_SEND,s_ONES,s_TENS,s_HUNDS,s_THOUS,s_ERROR,MODE_LED);

the_measure: measure_distance
generic map( G_RESET_ACTIVE_VALUE => s_G_RESET_ACTIVE_VALUE)
port map(CLK,RST,s_MESURE_REQ,ECHO,TRIG_OUT,s_DISTANCE,s_DISTANCE_VALID);	

the_ONES: hex_to_7seg 
port map(s_ONES,s_SHUTDOWNn,NUM_ONES);	
the_TENS: hex_to_7seg 
port map(s_TENS,s_SHUTDOWNn,NUM_TENS);	
the_HUNDS: hex_to_7seg 
port map(s_HUNDS,s_SHUTDOWNn,NUM_HUNDS);	
the_THOUS: hex_to_7seg 
port map(s_THOUS,s_ERROR,NUM_THOUS);	

the_send_string: send_string
port map(
    CLK    => CLK,
    RST    => RST,
    SEND   => s_SEND,
    ONES   => s_ONES,
    TENS   => s_TENS,
    HUNDS  => s_HUNDS,
    THOUS  => s_THOUS,
    ERROR  => s_ERROR,
    SER_TX => SER_TX
);		
end architecture;

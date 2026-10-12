library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.distance_meter_pack.all;
entity uart_tx_tb is

end entity;

architecture behave of uart_tx_tb is


component uart_tx 
 generic (
        CLOCKS_PER_BIT  : integer := 5208
    );

port (
    CLK             : in    std_logic;  
    RST             : in    std_logic;  
    START		    : in    std_logic;  
    PAR_DATA        : in    std_logic_vector(7 downto 0);  
    SER_TX          : out   std_logic ; 
	TX_DONE         : out   std_logic 
);
end component;	
  
	constant CLOCKS_PERBIT:integer:=C_CLK_FREQ/CLOCKS_PER_BIT;
	signal run : std_logic:='1';
	signal s_RST:std_logic:='0';
	signal s_CLK:std_logic:='0';
	signal s_START:std_logic:='0';
	signal s_PAR_DATA:std_logic_vector(7 downto 0) :=(others=>'0');
	signal s_SER_TX:std_logic:='0';
	signal s_TX_DONE:std_logic:='0';
begin
dut: uart_tx
	generic map (CLOCKS_PER_BIT =>CLOCKS_PERBIT)

    port map (
        RST            => s_RST,
        CLK            => s_CLK,
        START       => s_START,
        PAR_DATA => s_PAR_DATA,
        SER_TX           => s_SER_TX,
        TX_DONE        => s_TX_DONE
    );
	
s_RST <= '1', '0' after 2800 us;
s_START<='0','1' after 100 us , '0' after 100 us+20 ns,'1' after 1500 us ,'0' after 1500 us+20 ns;
s_PAR_DATA<= "00000000","10001001" after 100 us,"10011101" after 500 us ;

run <= '1', '0' after 3 ms; 
    process begin
        while run = '1' loop
            s_CLK <= '1'; wait for 10 ns;
            s_CLK <= '0'; wait for 10 ns;
        end loop;
        wait;
    end process;
end architecture;

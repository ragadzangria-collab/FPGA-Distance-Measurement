library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity synchronizer is
generic (
    SIG_IN_INIT_VALUE     : std_logic := '0'
);
port (
    CLK             : in    std_logic;
    RST             : in    std_logic;
    SIG_IN          : in    std_logic;
    SIG_OUT         : out   std_logic
);
end entity;

architecture behave of synchronizer is

    signal sig_in_d    : std_logic := SIG_IN_INIT_VALUE;

begin

    process(CLK, RST)
    begin
        if RST = '0' then
            sig_in_d <= SIG_IN_INIT_VALUE;
            SIG_OUT <= SIG_IN_INIT_VALUE;
        elsif rising_edge(CLK) then
            sig_in_d <= SIG_IN;
            SIG_OUT <= sig_in_d;
        end if;
    end process;

end architecture;
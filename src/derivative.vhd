library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- SIG INזה בעצם הדגימה הקודמת של 
--והוא בדיוק מה שמאפשר זיהוי קצה.
entity derivative is
generic (
    DERIVATE_RISING_EDGE  : boolean := false;
    SIG_IN_INIT_VALUE     : std_logic := '0'
);
port (
    CLK             : in    std_logic;
    RST             : in    std_logic;
    SIG_IN          : in    std_logic;
    SIG_OUT         : out   std_logic
);
end entity;

architecture behave of derivative is

    signal sig_in_d     : std_logic := SIG_IN_INIT_VALUE;


begin

    process(CLK, RST)
    begin
        if RST = '0' then
            sig_in_d <= SIG_IN_INIT_VALUE;
            SIG_OUT <= '0';
        elsif rising_edge(CLK) then
            sig_in_d <= SIG_IN;
            
            if DERIVATE_RISING_EDGE then
                SIG_OUT <= SIG_IN and not sig_in_d;
            else
                SIG_OUT <= not SIG_IN and sig_in_d;
            end if;
        end if;
    end process;

end architecture;
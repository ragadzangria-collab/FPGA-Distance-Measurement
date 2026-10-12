library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;

entity hex_to_7seg is
port(
    BCD_IN                      : in    std_logic_vector(3 downto 0);
    SHUTDOWNn                   : in    std_logic;
    D_OUT                       : out   std_logic_vector(6 downto 0));
end entity;
       
architecture behave of hex_to_7seg is
   
begin 
   
    process(BCD_IN, SHUTDOWNn)
    begin
        if SHUTDOWNn = '0' then
            D_OUT <= (others=>'1');
        else
            case BCD_IN is
                when "0000" =>
                    D_OUT <= "1000000";
                when "0001" =>                  
                    D_OUT <= "1111001";
                when "0010" =>
                    D_OUT <= "0100100";
                when "0011" =>
                    D_OUT <= "0110000";
                when "0100" =>
                    D_OUT <= "0011001";
                when "0101" =>
                    D_OUT <= "0010010";
                when "0110" =>
                    D_OUT <= "0000010";
                when "0111" =>
                    D_OUT <= "1111000";
                when "1000" =>
                    D_OUT <= "0000000";
                when "1001" =>
                    D_OUT <= "0010000";
                when "1010" =>
                    D_OUT <= "0001000";
                when "1011" =>
                    D_OUT <= "0000011";
                when "1100" =>
                    D_OUT <= "0100011";
                when "1101" =>
                    D_OUT <= "0100001";
                when "1110" =>
                    D_OUT <= "0000110";
                when "1111" =>
                    D_OUT <= "0001110";
                when others =>
                    D_OUT <= "1111111";

            end case;
        end if;
    end process;
   
end architecture;


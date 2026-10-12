
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package distance_meter_pack is

    type slv8_array is array(natural range <>) of std_logic_vector(7 downto 0);

    constant C_CLK_FREQ                     : integer := 50e6;  -- Hz
    constant TRIG_PULSE_WIDTH_us            : integer := 10;    
    constant C_SPEED_OF_SOUND               : integer := 346;   -- m/s  343@20C, 346@25C, 349@30C
    constant C_AVERAGING_NUM                : integer := 4;
    constant C_DELAY_BETWEEN_MEASUREMENTS   : integer := 25e6;
    constant C_TRIG_TO_TRIG_DELAY_ms        : integer := 60;
    constant C_MAX_DISTANCE_IN_cm           : integer := 300;
    constant CLOCKS_PER_BIT                    : integer := 9600;
    
-- *************** Add your consatnts here ***************

-- *******************************************************  

    function log2 (x : in integer) return integer;

    function to_slv(s: string) return slv8_array;

end package;

package body distance_meter_pack is

    function log2 (x : in integer) return integer is
        variable x_int  : integer;
        variable i      : integer := 0;
    begin
        x_int := x;
        i := 0;
        while x_int > 1 loop
            x_int := x_int/2;
            i := i + 1;
        end loop;
        return i;
    end function;
    
    function to_slv(s: string) return slv8_array is 
        variable answer : slv8_array(1 to s'length);--(7 downto 0); -- std_logic_vector(1 to 8 * s'length); 
        variable c      : integer; 
    begin 
        for i in s'range loop
            c := character'pos(s(i));
            answer(i) := std_logic_vector(to_unsigned(c,8)); 
        end loop; 
        return answer; 
    end function; 
    
    
end package body;

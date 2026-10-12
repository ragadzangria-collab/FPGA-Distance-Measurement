library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.distance_meter_pack.all;
entity uart_tx is
 generic (
        CLOCKS_PER_BIT  : integer := 5208  -- מספר מחזורי שעון לכל ביט משודר  (9600 baud)
    );
port (
    CLK             : in    std_logic;  
    RST             : in    std_logic;  
    START           : in    std_logic;  
    PAR_DATA        : in    std_logic_vector(7 downto 0);  
    SER_TX          : out   std_logic; 
    TX_DONE         : out   std_logic 
);
end entity;
-- מודול זה מממש משדר UART (שידור בלבד)
-- המודול מקבל:
-- START     – בקשה לשדר תו
-- PAR_DATA – וקטור של ביטים בגודל 8 ביטים(לצורך שידור תווי ASCII)
-- ומוציא:
-- SER_TX   – קו השידור הסדרתי
-- TX_DONE  – סימון שסיום השידור הושלם

architecture behave of uart_tx is

-- FSM – מכונת מצבים
-- st_idle         : מצב מנוחה, הקו התקשורת נמצא בגבוה וממתינים ל־START
-- st_transmition  : שידור הביטים אחד־אחד
-- st_done         : סיום שידור והפקת TX_DONE

type states IS (st_idle, st_transmition, st_done);
signal mystate : states := st_idle;
-- ערך האיפוס הפעיל
constant G_RESET_ACTIVE_VALUE : std_logic := '0';
-- מונה אינדקס לביטים המשודרים (0–9)
-- 0  : Start Bit
-- 1–8: Data Bits
-- 9  : Stop Bit
signal indx : integer range 0 to 9;
-- מונה מחזורי שעון לכל ביט
signal count_CLOCKS_PER_BIT :integer range 0 to CLOCKS_PER_BIT-1 := 0;
-- רגיסטר פנימי שמכיל את כל מסגרת השידור:
-- [9]   Stop Bit
-- [8:1] Data Bits
-- [0]   Start Bit
signal CURR_DATA : std_logic_vector(9 downto 0) := (others=>'0');
begin

process(CLK, RST)
begin
    if (RST = G_RESET_ACTIVE_VALUE) then
        SER_TX <= '1';-- קו UART במצב מנוחה ('1')
        TX_DONE <= '0';
        count_CLOCKS_PER_BIT <= 0;
        indx <= 0;
        mystate <= st_idle;
    elsif rising_edge(CLK) then
        case mystate is
            -- מצב IDLE – המתנה לבקשת שידור
            when st_idle =>
                SER_TX <= '1';          -- קו UART במנוחה
                TX_DONE <= '0';
                count_CLOCKS_PER_BIT <= 0;
                indx <= 0;
                if START = '1' then
                    -- בניית מסגרת השידור:
                    CURR_DATA(CURR_DATA'right)<= '0'; -- Start Bit
                    CURR_DATA(CURR_DATA'left)<= '1'; -- Stop Bit
                    CURR_DATA(8 downto 1)<= PAR_DATA; -- נתונים
                    mystate <= st_transmition;
                end if;
            when st_transmition =>
                SER_TX <= CURR_DATA(indx);-- שידור הביט הנוכחי
                if count_CLOCKS_PER_BIT = (CLOCKS_PER_BIT - 1) then-- בדיקה אם הסתיים זמן השידור של הביט
                    count_CLOCKS_PER_BIT <= 0;
                    if indx = 9 then
                        indx <= 0;
                        mystate <= st_done;
                    else
                        indx <= indx + 1;-- מעבר לביט הבא
                    end if;
                else 
                    count_CLOCKS_PER_BIT <= count_CLOCKS_PER_BIT + 1;-- המשך ספירת מחזורי השעון של הביט
                end if;
            -- מצב DONE – סיום שידור
            when st_done =>
                SER_TX <= '1';   -- חזרה למצב מנוחה
                TX_DONE <= '1';  -- סימון סיום שידור
                mystate <= st_idle;

        end case;
    end if;
end process;

end architecture;
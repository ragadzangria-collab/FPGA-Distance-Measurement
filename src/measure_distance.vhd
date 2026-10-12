library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.distance_meter_pack.all;

entity measure_distance is
generic (
    G_RESET_ACTIVE_VALUE   : std_logic := '0'  -- ערך האיפוס הפעיל
);
port (
    CLK             : in    std_logic;  -- שעון מערכת
    RST             : in    std_logic;  -- איפוס
    MEASURE_REQ     : in    std_logic;  -- בקשה חיצונית למדידת מרחק
    ECHO            : in    std_logic;  -- אות החזרה מהחיישן
    TRIG_OUT        : out   std_logic;  -- פולס TRIG לחיישן
    DISTANCE        : out   std_logic_vector(9 downto 0); -- מרחק מחושב
    DISTANCE_VALID  : out   std_logic   -- מציין שהתוצאה תקפה
);
end entity;
-- :מודול זה מממש מדידת מרחק בעלת רמת דיוק יותר גבוהה
-- 1. ביצוע מספר מדידות עוקבות
-- 2. צבירת זמני ההחזרה-שהם מסמלים את המרחקים 
-- 3. חישוב ממוצע (Averaging)
-- 4. עיגול תוצאה
-- 5. מהפקת מרחק סופי ו־VALID

architecture behave of measure_distance is
-- Component: sensor_driver
-- רכיב זה מבצע מדידה בודדת 
-- ומחזיר:
-- DURATION        – משך ECHO
-- DURATION_VALID  – סימון לסיום מדידה
component sensor_driver 
generic (
    G_RESET_ACTIVE_VALUE   : std_logic := '0'
);
port (
    CLK             : in    std_logic;  
    RST             : in    std_logic;  
    TRIG_IN         : in    std_logic;  
    ECHO            : in    std_logic;  
    TRIG_OUT        : out   std_logic ; 
    DURATION        : out   std_logic_vector(11 downto 0);
    DURATION_VALID  : out   std_logic
);
end component;

signal s_duration       : std_logic_vector(11 downto 0) := (others => '0');
signal s_duration_valid : std_logic;

--  מספר הביטים הדרוש להוספה ל 12 בכדי לצבר את הסכום של מדידות - כך שכל מדידה שמוספת היא ויקטור בגודל 12 סיביות (log2 של מספר הדגימות) 
constant C_LSB : integer := log2(C_AVERAGING_NUM);
-- סכום כל המדידות 
signal sum_duration :
    std_logic_vector(11 + C_LSB downto 0) := (others => '0');

type meas_states is (
    st_idle,     -- המתנה לבקשת מדידה
    st_measure,  -- ביצוע מדידות וצבירה
    st_finish    -- חישוב תוצאה והוצאת VALID
);

signal meas_state : meas_states := st_idle;
-- אות TRIG פנימי ל־sensor_driver
signal s_trig_in : std_logic := '0';
-- מונה מספר הדגימות שבוצעו
signal samples_cnt : integer range 0 to C_AVERAGING_NUM;
-- אות עזר לעיגול התוצאה לפני הזזת הביטים (לצורך החלוקה )
signal sum_duration_to_round :std_logic_vector(sum_duration'range);

begin
-- חיבור ה־sensor_driver
-- measure_distance שולטים עליו באמצעות s_trig_in
sensordriver : sensor_driver
generic map (
    G_RESET_ACTIVE_VALUE => G_RESET_ACTIVE_VALUE
)
port map (
    CLK        => CLK,
    RST        => RST,
    TRIG_IN    => s_trig_in,
    ECHO       => ECHO,
    TRIG_OUT   => TRIG_OUT,
    DURATION   => s_duration,
    DURATION_VALID => s_duration_valid
);
--תהליך FSM 
-- מנהל את רצף המדידות, הצבירה, והפקת התוצאה הסופית
process(CLK, RST)
begin
    if (RST = G_RESET_ACTIVE_VALUE) then
        -- איפוס מלא של המערכת
        sum_duration    <= (others => '0');
        samples_cnt     <= 0;
        DISTANCE        <= (others => '0');
        DISTANCE_VALID  <= '0';
    elsif rising_edge(CLK) then
        DISTANCE_VALID <= '0';
        case meas_state is
            -- מצב IDLE: המתנה לבקשת מדידה
            when st_idle =>
                sum_duration <= (others => '0');
                samples_cnt  <= 0;
                if MEASURE_REQ = '1' then
                    s_trig_in  <= '1';-- התחלת מדידה ראשונה
                    meas_state <= st_measure;
                end if;
            -- מצב MEASURE: ביצוע מדידות מרובות
            when st_measure =>
                s_trig_in <= '0';
                if s_duration_valid = '1' then-- מיעד על אפשרות ביצוע מדידה חדשה 
                    sum_duration <= std_logic_vector(unsigned(sum_duration) + resize(unsigned(s_duration), sum_duration'length));
                    s_trig_in <= '1';-- בקשה למדידה נוספת
                    if samples_cnt = C_AVERAGING_NUM - 1 then-- האם קיבלנו את התוצאות של ארבעת המדידות ?
                        s_trig_in  <= '0';
                        meas_state <= st_finish;
                    else
                        samples_cnt <= samples_cnt + 1;
                    end if;
                end if;
            -- מצב FINISH: חישוב ממוצע והוצאת תוצאה
            when st_finish =>
			    -- בכדי לקבל את ממוצע המדידות יש צורך לחלק במספר המדידות שביצענו 
                --לאחר מכן אנחנו נקבל הממוצע ביחידות 0.25 ס"מ ובכדי לקבל את התוצאה ביחידות ס"מ יש לחלק ב 4
				-- כלומר במקרה שלנו יש לחלק את ה SUM בסך הכל 16 
				-- שזה בעצם הזזה 4 סיביות ה LSB 
                DISTANCE <= sum_duration_to_round(sum_duration'high downto C_LSB+2);
                DISTANCE_VALID <= '1';
                meas_state <= st_idle;

        end case;
    end if;
end process;
-- עיגול התוצאה לפני חיתוך ביטים
-- הוספת חצי מגורם החלוקה מאפשרת לקבל
-- עיגול לערך הקרוב ביותר במקום עיגול כלפי מטה
sum_duration_to_round <=std_logic_vector(unsigned(sum_duration) + C_AVERAGING_NUM * 4 / 2);

end architecture;
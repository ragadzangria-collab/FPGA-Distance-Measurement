library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.distance_meter_pack.all;

entity sensor_driver is
generic (
    G_RESET_ACTIVE_VALUE   : std_logic := '0'
);
port (
    CLK             : in    std_logic;  -- שעון המערכת
    RST             : in    std_logic;  -- אות איפוס
    TRIG_IN         : in    std_logic;  -- בקשה חיצונית לביצוע מדידה
    ECHO            : in    std_logic;  -- אות ההחזרה מהחיישן
    TRIG_OUT        : out   std_logic;  -- פולס הפעלה לחיישן
    DURATION        : out   std_logic_vector(11 downto 0); -- משך ההחזרה
    DURATION_VALID  : out   std_logic   -- מציין שהמדידה הסתיימה
);
end entity;
-- מודול זה מממש דרייבר לחיישן מרחק אולטרסוני (לדוגמה HC-SR04)
-- הרעיון הכללי:
-- 1. קבלת בקשה למדידה (TRIG_IN)
-- 2. יצירת פולס TRIG לחיישן(שהוא בעצם המוצא של הדריבר TRIG_OUT)
-- 3. מדידת זמן האות ECHO המתקבל מהחיישן 
-- 4. המרת זמן זה ליחידות מרחק (0.25 ס"מ)
-- 5. החזרת תוצאת המדידה + דגל תקפות (שמייעד גם על אפשור קבלת פולס 

architecture behave of sensor_driver is
-- רכיב synchronizer
component synchronizer 
    generic (
        SIG_IN_INIT_VALUE : std_logic := '0'
    );
    port (
        CLK     : in  std_logic;
        RST     : in  std_logic;
        SIG_IN  : in  std_logic;
        SIG_OUT : out std_logic
    );
end component;

-- רכיב derivative
-- רכיב זה מזהה שינוי באות
component derivative 
    generic (
        DERIVATE_RISING_EDGE : boolean := false;
        SIG_IN_INIT_VALUE    : std_logic := '0'
    );
    port (
        CLK     : in  std_logic;
        RST     : in  std_logic;
        SIG_IN  : in  std_logic;
        SIG_OUT : out std_logic
    );
end component;

-- מספר מחזורי שעון הדרושים למעבר של 0.25 ס"מ
-- החישוב מבוסס על:
-- תדר השעון ומהירות הקול באוויר
constant C_CLKS_PER_Q_CM : integer :=(C_CLK_FREQ*2 + (C_SPEED_OF_SOUND*4*100)/2) /(C_SPEED_OF_SOUND*4*100);
-- רוחב פולס TRIG במונחי מחזורי שעון
constant TRIG_WIDTH : integer :=TRIG_PULSE_WIDTH_us * (C_CLK_FREQ / 1e6);-- שווה ל 500 בגלל שהחיישן יעבור הוא צריך לקבל אות טריגר שהוא לפחות ברוחב 10 מיקרושניות בכדי לזהות שיש בקשה להתחלת מדידה 

-- מספר מחזורי שעון מינימלי בין שתי מדידות
-- נועד למנוע מדידות חופפות 
constant pulsesfor60ms : integer :=C_TRIG_TO_TRIG_DELAY_ms * (C_CLK_FREQ / 1e3);

-- מונה לרוחב פולס TRIG
signal trig_pulse_width_counter : integer range 0 to TRIG_WIDTH-1 := 0;

-- מונה בסיס זמן ל־0.25 ס"מ
signal time_base_cnt   : integer range 0 to C_CLKS_PER_Q_CM-1 := 0;
signal time_base_pulse : std_logic;
-- מונה משך אות ה־ECHO
signal echo_duration : std_logic_vector(11 downto 0) := (others => '0');-- בכדי לייצג את המרחק הנמדד ביחידות 0.25 ס"מ 
-- אות ECHO לאחר סנכרון
signal echo_synchronized : std_logic;
-- פולס שמציין נפילה של ECHO
signal echo_fall : std_logic;
-- מונה זמן בין מדידות
signal cnt60ms : integer range 0 to pulsesfor60ms := 0;


-- FSM – מכונת מצבים
-- המכונה שולטת על כל תהליך המדידה
-- ומבטיחה זרימה מסודרת ללא התנגשויות
type sm_states is (
    st_wait_for_trig_in,     -- המתנה לבקשת מדידה
    st_wait_for_echo_fall,   -- מדידת זמן ההחזרה
    st_wait_for_new_trig_in  -- השהייה בין מדידות
);
signal sm : sm_states := st_wait_for_trig_in;
begin

-- סנכרון אות ECHO
-- אות ECHO מגיע מהעולם החיצוני ואינו מסונכרן לשעון
-- רכיב זה מבטיח שהאות ייכנס למערכת בצורה בטוחה
-- וללא בעיות אי סינכרון בין השעון של הרכיב לבין האות
echo_sync : synchronizer
generic map (
    SIG_IN_INIT_VALUE => '0'
)
port map (
    CLK     => CLK,
    RST     => RST,
    SIG_IN  => ECHO,
    SIG_OUT => echo_synchronized
);

-- זיהוי נפילת אות ECHO(falling edge)
-- של אות ECHO – כלומר הרגע שבו החיישן סיים את ההחזרה
echo_diff : derivative
generic map (
    DERIVATE_RISING_EDGE => false,
    SIG_IN_INIT_VALUE    => '0'
)
port map (
    CLK     => CLK,
    RST     => RST,
    SIG_IN  => echo_synchronized,
    SIG_OUT => echo_fall
);


-- תהליך יצירת פולס TRIG
-- יוצר פולס מדויק ברוחב קבוע כאשר מתקבלת בקשת מדידה
-- הפולס נשלח רק כאשר המערכת במצב המתאים
TIG_OUT_PULSE : process(CLK, RST)
begin
    if RST = G_RESET_ACTIVE_VALUE then
        TRIG_OUT <= '0';
        trig_pulse_width_counter <= 0;

    elsif rising_edge(CLK) then

        if (TRIG_IN = '1') and (sm = st_wait_for_trig_in) then
            TRIG_OUT <= '1';
            trig_pulse_width_counter <= 0;

        elsif TRIG_OUT = '1' then
            if trig_pulse_width_counter = TRIG_WIDTH-1 then
                TRIG_OUT <= '0';
                trig_pulse_width_counter <= 0;
            else
                trig_pulse_width_counter <= trig_pulse_width_counter + 1;
            end if;
        end if;
    end if;
end process;
-- בסיס זמן למדידת מרחק
-- מייצר פולס מחזורי כך שכל פולס מייצג מרחק 0.25 ס"מ פולס הקודם
TIME_BASE_Qcm : process(CLK, RST)
begin
    if RST = G_RESET_ACTIVE_VALUE then
        time_base_pulse <= '0';
        time_base_cnt   <= 0;

    elsif rising_edge(CLK) then
        time_base_pulse <= '0';

        if time_base_cnt = 0 then
            time_base_pulse <= '1';
            time_base_cnt   <= C_CLKS_PER_Q_CM-1;
        else
            time_base_cnt   <= time_base_cnt - 1;
        end if;
    end if;
end process;
-- כאן מתבצע התיאום בין:
-- TRIG, ECHO, בסיס הזמן והשהיות החובה
process(CLK, RST)
begin
    if RST = G_RESET_ACTIVE_VALUE then
        sm <= st_wait_for_trig_in;
        echo_duration <= (others => '0');
        DURATION_VALID <= '0';
        cnt60ms <= 0;
    elsif rising_edge(CLK) then
        DURATION_VALID <= '0';
        case sm is
            -- המתנה לבקשת מדידה
            when st_wait_for_trig_in =>
                cnt60ms <= 0;
                if TRIG_IN = '1' then
                    echo_duration <= (others => '0');
                    sm <= st_wait_for_echo_fall;
                end if;
            -- מדידת זמן ה-ECHO
            when st_wait_for_echo_fall =>
                if cnt60ms < pulsesfor60ms-1 then
                    cnt60ms <= cnt60ms + 1;
                end if;
                if (echo_synchronized = '1') and (time_base_pulse = '1') then
                    echo_duration <= std_logic_vector(unsigned(echo_duration) + 1);
                end if;
                if echo_fall = '1' then
                    sm <= st_wait_for_new_trig_in;
                end if;
            -- השהייה חובה בין מדידות
            when st_wait_for_new_trig_in =>
                if cnt60ms < pulsesfor60ms-1 then
                    cnt60ms <= cnt60ms + 1;
                else
                    DURATION_VALID <= '1';
                    sm <= st_wait_for_trig_in;
                end if;

        end case;
    end if;
end process;
-- החזרת תוצאת המדידה החוצה
DURATION <= echo_duration;

end architecture;
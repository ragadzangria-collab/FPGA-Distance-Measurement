library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.distance_meter_pack.all;

entity controller is
generic (
    G_RESET_ACTIVE_VALUE   : std_logic := '0'
);
port (
    CLK             : in    std_logic;  
    RST             : in    std_logic;  
    DISTANCE        : in    std_logic_vector(9 downto 0);  -- קלטים מתהליך המדידה
    DISTANCE_VALID  : in    std_logic;  
    START_MEASURE   : in    std_logic; -- קלטי שליטה מהמשתמש
    MODE            : in    std_logic;
	
    MEASURE_REQ     : out   std_logic;
    SEND            : out   std_logic;
    ONES            : out   std_logic_vector(3 downto 0);-- פלטי ספרות לתצוגה / שליחה
    TENS            : out   std_logic_vector(3 downto 0);
    HUNDS           : out   std_logic_vector(3 downto 0);
    THOUS           : out   std_logic_vector(3 downto 0);
    ERROR           : out   std_logic;-- דגל שגיאה ותצוגת מצב
    MODE_LED        : out   std_logic
);
end entity;
-- רכיב זה הינו הבקר של המערכת שלנו
-- תפקידו:
-- 1. ניהול תהליך המדידה (ידני / אוטומטי)
-- 2. שליחת בקשת מדידה למודול measure_distance
-- 3. קבלת תוצאת המרחק
-- 4. המרת המרחק לפורמט עשרוני (BCD)
-- 5. הפעלת שליחת הנתונים (UART / תצוגה)
-- 6. ניהול מצבי עבודה ושגיאות

architecture behave of controller is

-- רכיב synchronizer
-- מסנכרן אותות חיצוניים במקובלים מהמשתמש ע"י לחיצה על לחצן (START_MEASURE, MODE)
-- לשעון המערכת ומונע מצבי אי יציבות
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
-- מזהה קצה (Edge Detection)
-- משמש כאן ליצירת פולס קצר בלחיצת הלחצן
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
-- רכיב bin2bcd
-- לארבע ספרות BCD לצורך תצוגה / שידור
component bin2bcd_12bit_sync is
port ( 
    binIN       : in  std_logic_vector (11 downto 0);
    ones        : out std_logic_vector (3 downto 0);
    tenths      : out std_logic_vector (3 downto 0);
    hunderths   : out std_logic_vector (3 downto 0);
    thousands   : out std_logic_vector (3 downto 0);
    clk         : in  std_logic
);
end component;
constant s_G_RESET_ACTIVE_VALUE : std_logic := '0';
constant s_SIG_IN_INIT_VALUE    : std_logic := '0';
constant s_DERIVATE_RISING_EDGE : boolean := true;

signal START_MEASURE_SYNC  : std_logic := '0';
signal START_MEASURE_PULSE : std_logic := '0';

signal MODE_SYNC  : std_logic := '0';
signal MODE_PULSE : std_logic := '0';

-- מצבי ה־FSM
type states is (
    waiting_for_start,              -- המתנה לבקשת מדידה
    send_trigger,                   -- שליחת בקשת מדידה
    waiting_for_distancevalid,      -- המתנה לתוצאה
    delay                            -- השהייה / שליחה / תצוגה
);
signal state : states := waiting_for_start;

-- קבוע השהייה בין מדידות במצב אוטומטי
constant C_DELAY_BETWEEN_MEASUREMENTS : integer := 25e6;
signal cnt500ms    : integer range 0 to C_DELAY_BETWEEN_MEASUREMENTS-1 := 0;
signal flagmodeled : std_logic := '0';
signal distance_ext : std_logic_vector(11 downto 0) := (others=>'0');-- הרחבת המרחק ל־12 ביט לצורך BCD
signal s_ONES  : std_logic_vector(3 downto 0) := (others=>'0');
signal s_TENS  : std_logic_vector(3 downto 0) := (others=>'0');
signal s_HUNDS : std_logic_vector(3 downto 0) := (others=>'0');
signal s_THOUS : std_logic_vector(3 downto 0) := (others=>'0');
signal send_pulse: std_logic:='0';

begin
-- סנכרון וזיהוי לחיצה על MODE
modesync : synchronizer
generic map (SIG_IN_INIT_VALUE => s_SIG_IN_INIT_VALUE)
port map (CLK, RST, MODE, MODE_SYNC);
modediff : derivative
generic map (
    DERIVATE_RISING_EDGE => not s_DERIVATE_RISING_EDGE,
    SIG_IN_INIT_VALUE    => s_SIG_IN_INIT_VALUE
)
port map (CLK, RST, MODE_SYNC, MODE_PULSE);

-- סנכרון וזיהוי לחיצה על START_MEASURE
startmeasuresync : synchronizer
generic map (SIG_IN_INIT_VALUE => s_SIG_IN_INIT_VALUE)
port map (CLK, RST, START_MEASURE, START_MEASURE_SYNC);
startmeasurediff : derivative
generic map (
    DERIVATE_RISING_EDGE => not s_DERIVATE_RISING_EDGE,
    SIG_IN_INIT_VALUE    => s_SIG_IN_INIT_VALUE
)
port map (CLK, RST, START_MEASURE_SYNC, START_MEASURE_PULSE);

bin2bcd : bin2bcd_12bit_sync
port map (distance_ext,s_ONES,s_TENS,s_HUNDS,s_THOUS,CLK);
process(CLK, RST)
begin
  if (RST = G_RESET_ACTIVE_VALUE) then
    MEASURE_REQ <= '0';
    SEND        <= '0';
    ONES        <= (others=>'0');
    TENS        <= (others=>'0');
    HUNDS       <= (others=>'0');
    THOUS       <= (others=>'0');
    ERROR       <= '0';
    MODE_LED    <= '0';
    flagmodeled <= '0';
    cnt500ms    <= 0;
	--דגל זה שימש אותנו כדי להעלות את
	--send למשך שעון אחד
	send_pulse <= '0';
  elsif rising_edge(CLK) then
    MEASURE_REQ <= '0';
    SEND        <= '0';
    if MODE_PULSE = '1' then
      flagmodeled <= not flagmodeled;-- החלפת מצב עבודה (ידני / אוטומטי)
    end if;
    MODE_LED <= flagmodeled;
    case state is
      -- המתנה לבקשת מדידה מהלחצן START_MESURE
      when waiting_for_start =>
        cnt500ms <= 0;
		send_pulse   <= '0';
        if START_MEASURE_PULSE = '1' then
          state <= send_trigger;
        end if;
      -- שליחת בקשת מדידה 
      when send_trigger =>
	     send_pulse   <= '0';
        MEASURE_REQ <= '1';
        state <= waiting_for_distancevalid;
      -- המתנה לתוצאה
      when waiting_for_distancevalid =>
        cnt500ms <= cnt500ms + 1;
        if DISTANCE_VALID = '1' then
          state <= delay;
        end if;
      -- הצגת תוצאה / השהייה / חזרה למצב מתאים
      when delay =>
        SEND  <= '0';
        ONES  <= s_ONES;
        TENS  <= s_TENS;
        HUNDS <= s_HUNDS;
        if unsigned(DISTANCE) > C_MAX_DISTANCE_IN_cm then        -- בדיקת חריגה מטווח
          ERROR <= '1';
          THOUS <= "1110"; -- סימון שגיאה(E)
        else
          ERROR <= '0';
        end if;
		if send_pulse = '0' then
			SEND        <= '1';      -- פולס של מחזור אחד
			send_pulse <= '1';
		end if;-- ננעל כדי שלא יחזור שוב
        if flagmodeled = '0' then-- מצב ידני
          if START_MEASURE_SYNC = '1' then
            state <= waiting_for_start;
          end if;
        else-- מצב אוטומטי
          if cnt500ms = C_DELAY_BETWEEN_MEASUREMENTS-1 then-- בדיקת הזמן בין כל מדידה ומדידה במצב אוטומטי  
            cnt500ms <= 0;
            state <= send_trigger;
          else
            cnt500ms <= cnt500ms + 1;
          end if;
        end if;
    end case;
  end if;
end process;
-- הרחבת המרחק ל־12 ביט לצורך קבלת הספרות של המרחק ב BCD 
distance_ext <= std_logic_vector(resize(unsigned(DISTANCE), 12));

end architecture;
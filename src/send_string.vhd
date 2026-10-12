library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.distance_meter_pack.all;
-- החבילה distance_meter_pack מספקת טיפוסים ופונקציות עזר
-- כגון slv8_array והגדרות כלליות המשמשות בפרויקט
entity send_string is
port (
    CLK             : in    std_logic;  -- שעון מערכת
    RST             : in    std_logic;  -- איפוס
    SEND            : in    std_logic;  -- בקשה להתחיל שליחת ההודעה

    -- ספרות המרחק בפורמט BCD
    ONES            : in    std_logic_vector(3 downto 0);
    TENS            : in    std_logic_vector(3 downto 0);
    HUNDS           : in    std_logic_vector(3 downto 0);
    THOUS           : in    std_logic_vector(3 downto 0);
    ERROR           : in    std_logic;  -- דגל שגיאה
    SER_TX          : out   std_logic   -- קו שידור UART
);
end entity;
-- מודול זה אחראי על בניית מחרוזת טקסט ושליחתה
-- בצורה סדרתית (UART), תו אחר תו.
-- הרעיון הכללי:
-- 1. בניית מחרוזת מלאה בזיכרון פנימי (Buffer)
-- 2. שליחת המחרוזת תו־תו דרך UART
-- 3. שימוש במכונת מצבים כדי לשלוט ברצף השידור

architecture struct of send_string is
    constant C_STR1 : string := "Distance is:"; -- קבועי המחרוזת
    constant C_STR2 : string := "[cm]" & LF;
    -- חישוב אורכי חלקי ההודעה
    constant L1 : integer := C_STR1'length; -- אורך הטקסט הקבוע
    constant L2 : integer := 4;              -- מקום ל־רווח/E + 3 ספרות
    constant L3 : integer := C_STR2'length; -- אורך הסיומת
    constant L  : integer := L1 + L2 + L3;  -- אורך כולל של ההודעה
    -- רכיב uart_tx
    component uart_tx is
    generic ( CLOCKS_PER_BIT : integer := 5208 ); -- 9600 Baud
    port (
        CLK      : in  std_logic;
        RST      : in  std_logic;
        PAR_DATA : in  std_logic_vector(7 downto 0);
        START    : in  std_logic;
        SER_TX   : out std_logic;
        TX_DONE  : out std_logic
    );
    end component;

    -- FSM – מכונת מצבים
    -- st_idle        : מצב מנוחה ובניית ההודעה
    -- st_start_char  : התחלת שידור תו
    -- st_wait_done   : המתנה לסיום שידור התו
    type t_state is (st_idle, st_start_char, st_wait_done);
    signal state : t_state := st_idle;
    signal par_data : std_logic_vector(7 downto 0); -- התו הנוכחי לשידור
    signal start_tx : std_logic;                    -- פולס התחלה ל־UART
    signal tx_done  : std_logic;                    -- סיום שידור תו
    signal tx_buf   : slv8_array(1 to L);-- Buffer פנימי שמכיל את כל ההודעה בפורמט ASCII
    signal data_cnt : integer range 0 to L := 0;-- מונה מיקום התו הנשלח מתוך ה־Buffer
begin
    u_uart : uart_tx
        generic map ( CLOCKS_PER_BIT => 5208 )
        port map (
            CLK      => CLK,
            RST      => RST,
            PAR_DATA => par_data,
            START    => start_tx,
            SER_TX   => SER_TX,
            TX_DONE  => tx_done
        );
    process(CLK, RST)
    begin
        if RST = '0' then
            state    <= st_idle;
            data_cnt <= 0;
            start_tx <= '0';
            par_data <= (others => '0');

        elsif rising_edge(CLK) then
            start_tx <= '0';
			tx_buf(1 to L1) <= to_slv(C_STR1);-- הכנסת החלק הקבוע הראשון
            tx_buf(L1 + L2 + 1 to L) <= to_slv(C_STR2); -- הכנסת הסיומת
            tx_buf(L1 + 2) <= std_logic_vector'("0011") & HUNDS;
            tx_buf(L1 + 3) <= std_logic_vector'("0011") & TENS;
            tx_buf(L1 + 4) <= std_logic_vector'("0011") & ONES;
            case state is
                -- מצב IDLE: בניית ההודעה והמתנה לפקודת SEND
                when st_idle =>
                    data_cnt <= 1;
                    if SEND = '1' then
                        if ERROR = '1' then-- תו שגיאה או רווח
                            tx_buf(L1 + 1) <= x"45"; -- 'E'
                        else
                            tx_buf(L1 + 1) <= x"20"; -- רווח
                        end if;
                        state <= st_start_char;
                    end if;
                -- מצב START_CHAR: התחלת שידור תו
                when st_start_char =>
                    par_data <= tx_buf(data_cnt); -- טעינת התו הנוכחי
                    start_tx <= '1';              -- פולס התחלה ל־UART
                    state    <= st_wait_done;
                -- מצב WAIT_DONE: המתנה לסיום שידור התו
                when st_wait_done =>
                    if tx_done = '1' then
                        if data_cnt = L then --האם כל ההודעה נשלחה ?
                            state <= st_idle;
                        else
                            data_cnt <= data_cnt + 1;-- מעבר לתו הבא
                            state <= st_start_char;
                        end if;
                    end if;

            end case;
        end if;
    end process;

end architecture;
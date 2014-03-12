LIBRARY IEEE;
LIBRARY altera_mf;
USE altera_mf.all;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY lcd_sync IS
PORT (
		clkin_50 : IN STD_LOGIC;
		keyboard_data: INOUT STD_LOGIC;
		keyboard_clk: INOUT STD_LOGIC;
		led : out std_logic_vector(7 downto 0);
		h_sync,v_sync,hc_nclk:OUT STD_LOGIC;
		video_on:inout std_logic;
		lcd_reset:OUT STD_LOGIC;
		pix_x,pix_y:OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		rgb_data  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		lcd_clock: buffer STD_LOGIC;
		reset     : IN STD_LOGIC);
END ENTITY;

ARCHITECTURE arch_rgb_mux OF lcd_sync IS
TYPE rgb_type IS (blue,green,red);
SIGNAL rgb_loop:rgb_type;
SIGNAL rgb_clock:STD_LOGIC;
SIGNAL blue_data,red_data,green_data:STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL pix_x_sig,pix_y_sig:UNSIGNED(11 DOWNTO 0);
SIGNAL h_sync_sig,v_sync_sig:STD_LOGIC;
SIGNAL video_on_sig:STD_LOGIC;
SIGNAL memory_on:std_logic;
COMPONENT pll_150 IS
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC  
	);
END COMPONENT;

component pll_romm IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component;

signal mouse_cursor_row,mouse_cursor_column:std_logic_vector(9 downto 0);
signal rom_addr:std_logic_vector(15 downto 0);
signal rom_data:std_logic_vector(31 downto 0);
signal char_addr:std_logic_vector(6 downto 0);
signal row_addr:std_logic_vector(2 downto 0);
signal bit_addr:std_logic_vector(2 downto 0);
signal font_bit:std_logic;
signal mouse_bit:std_logic;
BEGIN
inst_pll: pll_150 PORT MAP(clkin_50,rgb_clock);
inst_pll_rom:pll_romm port map(rom_addr,rgb_clock,rom_data);
hc_nclk <= rgb_clock;

--rom_addr <= (std_logic_vector(pix_y_sig(7 downto 0)) & std_logic_vector(pix_x_sig(7 downto 0))) when memory_on = '1'
--			else x"0000";
rom_addr <= "0000" & std_logic_vector(pix_x_sig);
PROCESS(rgb_clock,reset)
BEGIN
	IF RESET = '0' THEN
		rgb_loop <= blue;
	ELSIF RISING_EDGE(rgb_clock) THEN
		CASE rgb_loop IS
			WHEN blue =>
				rgb_data <= rom_data(23 downto 16);
				rgb_loop <= green;
				lcd_clock <= '0';
			WHEN green =>
				rgb_data <= rom_data(15 downto 8);
				rgb_loop <= red;
				lcd_clock <= '0';
			WHEN red =>
				rgb_data <= rom_data(7 downto 0);
				rgb_loop <= blue;
				lcd_clock <= '1';
			WHEN OTHERS =>
				NULL;
		END CASE;
		
			h_sync <= h_sync_sig;
			v_sync <= v_sync_sig;
			video_on <= video_on_sig;
		
	END IF;
END PROCESS;

PROCESS(rgb_clock,reset)
VARIABLE video_on_h,video_on_v:STD_LOGIC;
BEGIN
	IF RESET = '0' THEN		
		pix_x_sig <= "000000000000";
		pix_y_sig <= "000000000000";
		lcd_reset <= '0';
	ELSIF RISING_EDGE(rgb_clock) THEN
		lcd_reset <= '1';
		IF rgb_loop = red THEN
			IF pix_x_sig < 1056 THEN
				pix_x_sig <= pix_x_sig + 1;
			ELSE
				pix_x_sig <= "000000000000";
				IF pix_y_sig < 525 THEN	
					pix_y_sig <= pix_y_sig + 1;
				ELSE	
					pix_y_sig <= "000000000000";
				END IF;
			END IF;
--controlling horizontal video_on_h
			IF (pix_x_sig < 800) THEN
				video_on_h := '1';
			ELSE
				video_on_h := '0';
			END IF;
--controlling vertical video_on_v
			IF (pix_y_sig) < 480 THEN
				video_on_v := '1';
			ELSE
				video_on_v := '0';
			END IF;
--controlling h_sync
			IF pix_x_sig = 840  THEN
				h_sync_sig <= '1';
			ELSE
				h_sync_sig <= '0';
			END IF;
--controlling v_sync
			IF pix_y_sig = 490 THEN
				v_sync_sig <= '1';
			ELSE
				v_sync_sig <= '0';
			END IF;
-- read memory
			IF pix_x_sig < 512 and pix_y_sig < 382 then
				memory_on <= '1';
			ELSE
				memory_on <= '0';
			END IF;
			pix_x <= std_logic_vector(pix_x_sig);
			pix_y <= std_logic_vector(pix_y_sig);
			video_on_sig <= video_on_h and video_on_v;
		END IF;
	END IF;
END PROCESS;
--char_addr <= "0111001";
--char_addr <= std_logic_vector(pix_y_sig(6 downto 5)) & std_logic_vector(pix_x_sig(9 downto 5));
--row_addr <= std_logic_vector(pix_y_sig(4 downto 0));
--rom_addr <=  row_addr;
--bit_addr <= std_logic_vector(pix_x_sig(4 downto 0));
--font_bit <= rom_data(conv_integer(unsigned(not bit_addr)));
--char_addr <= std_logic_vector(pix_y_sig(4 downto 3)) & std_logic_vector(pix_x_sig(7 downto 3));
--row_addr <= std_logic_vector(pix_y_sig(2 downto 0));
--rom_addr <= char_addr & row_addr;
--bit_addr <= std_logic_vector(pix_x_sig(2 downto 0));
--font_bit <= rom_data(conv_integer(unsigned(not bit_addr)));


--process(rgb_clock)
--begin
--	if font_bit = '1' then
--		blue_data <= x"00";
--		green_data <= x"00";
--		red_data <= x"00";
--	else
--			
--			blue_data <= x"ff";
--			green_data <= x"ff";
--			red_data <= x"ff";
----		else
----			blue_data <= x"ff";
----			green_data <= x"ff";
----			red_data <= x"ff";
----		end if;
--	end if;
--end process;
END ARCHITECTURE;

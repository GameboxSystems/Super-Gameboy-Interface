--------------------------------------------------------------------------------
-- Engineer: Oleksandr Kiyenko
-- o.kiyenko@gmail.com
--------------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
--------------------------------------------------------------------------------
entity video_tg is
generic (
	C_VIDEO_ID_CODE			: integer	:= 4;	-- 720p
	C_WIDTH					: integer	:= 11;
	C_CNT_SHIFT				: integer	:= 2;
	C_SCALE					: integer	:= 1
);
port (
	clk_in					: in  STD_LOGIC;	-- Pixel clock
	x_pos_out				: out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
	y_pos_out				: out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
	xs_pos_out				: out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
	ys_pos_out				: out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
	hs_out					: out STD_LOGIC;	-- Horisontal sync pulse
	vs_out					: out STD_LOGIC;	-- Vertical sync pulse
	av_out					: out STD_LOGIC		-- Active video
);
end video_tg;
--------------------------------------------------------------------------------
architecture arch_imp of video_tg is
--------------------------------------------------------------------------------
-- |Resolution|ID Code|Frame Rate|Pixel Clock Frequency|
-- |----------|-------|----------|---------------------|
-- |640x480   |1      |60Hz      |25.2MHz              |
-- |640x480   |1      |59.94Hz   |25.175MHz            |
-- |720x480   |2,3    |60Hz      |27.027MHz            |
-- |720x480   |2,3    |59.94Hz   |27MHz                |
-- |1280x720  |4      |60Hz      |74.25MHz             |
-- |1280x720  |4      |59.94Hz   |74.176MHz            |
-- |1920x1080 |16     |60Hz      |148.5MHz             |
-- |1920x1080 |16     |59.94Hz   |148.352MHz           |
-- |720x576   |17,18  |50Hz      |27MHz                |
-- |1280x720  |19     |50Hz      |74.25MHz             |
--------------------------------------------------------------------------------
function get_frame_width(mode_id : INTEGER) return INTEGER is
	variable ret_val		: INTEGER := 0; 
begin					
	case mode_id is
		when 1			=> ret_val := 800;
		when 2|3		=> ret_val := 858;
		when 4			=> ret_val := 1650;
		when 16			=> ret_val := 2200;
		when 17|18		=> ret_val := 864;
		when 19			=> ret_val := 1980;
		when others		=> ret_val := 1650;
	end case;
    return ret_val;
end function;

function get_frame_height(mode_id : INTEGER) return INTEGER is
	variable ret_val		: INTEGER := 0; 
begin					
	case mode_id is
		when 1|2|3		=> ret_val := 525;
		when 4			=> ret_val := 750;
		when 16			=> ret_val := 1125;
		when 17|18		=> ret_val := 625;
		when 19			=> ret_val := 750;
		when others		=> ret_val := 750;
	end case;
    return ret_val;
end function;

function get_screen_width(mode_id : INTEGER) return INTEGER is
	variable ret_val		: INTEGER := 0; 
begin					
	case mode_id is
		when 1			=> ret_val := 640;
		when 2|3|17|18	=> ret_val := 720;
		when 4|19		=> ret_val := 1280;
		when 16			=> ret_val := 1920;
		when others		=> ret_val := 1280;
	end case;
    return ret_val;
end function;

function get_screen_height(mode_id : INTEGER) return INTEGER is
	variable ret_val		: INTEGER := 0; 
begin					
	case mode_id is
		when 1|2|3		=> ret_val := 480;
		when 4|19		=> ret_val := 720;
		when 16			=> ret_val := 1080;
		when 17|18		=> ret_val := 576;
		when others		=> ret_val := 720;
	end case;
    return ret_val;
end function;

function get_video_rate(mode_id : INTEGER) return INTEGER is
	variable ret_val		: INTEGER := 0; 
begin					
	case mode_id is
		when 1			=> ret_val := 25200000;
		when 2|3		=> ret_val := 27027000;
		when 4			=> ret_val := 74250000;
		when 16			=> ret_val := 148500000;
		when 17|18		=> ret_val := 27000000;
		when 19			=> ret_val := 74250000;
		when others		=> ret_val := 720;
	end case;
    return ret_val;
end function;

function get_sync_polarity(mode_id : INTEGER) return STD_LOGIC is
	variable ret_val		: STD_LOGIC := '0'; 
begin					
	case mode_id is
		when 1			=> ret_val := '0';
		when 2|3		=> ret_val := '0';
		when 4			=> ret_val := '1';
		when 16			=> ret_val := '1';
		when 17|18		=> ret_val := '0';
		when 19			=> ret_val := '1';
		when others		=> ret_val := '1';
	end case;
    return ret_val;
end function;
--------------------------------------------------------------------------------
constant FRAME_WIDTH	: INTEGER	:= get_frame_width(C_VIDEO_ID_CODE);
constant FRAME_HEIGHT	: INTEGER	:= get_frame_height(C_VIDEO_ID_CODE);
constant SCREEN_WIDTH	: INTEGER	:= get_screen_width(C_VIDEO_ID_CODE);
constant SCREEN_HEIGHT	: INTEGER	:= get_screen_height(C_VIDEO_ID_CODE);
constant SYNC_POLARITY	: STD_LOGIC	:= get_sync_polarity(C_VIDEO_ID_CODE);
constant C_SYNC_FRAMES	: integer	:= 600;


-- // // 720x480
-- // `define DISPLAY_WIDTH			720
-- // `define DISPLAY_HEIGHT		480
-- // `define FULL_WIDTH			858
-- // `define FULL_HEIGHT			525
-- // `define H_FRONT_PORCH			16
-- // `define H_SYNC				62 
-- // `define V_FRONT_PORCH			9
-- // `define V_SYNC 				6

-- // 1280x720
-- `define DISPLAY_WIDTH			1280
-- `define DISPLAY_HEIGHT			720
-- `define FULL_WIDTH				1650
-- `define FULL_HEIGHT				750

-- constant H_FRONT_PORCH	: INTEGER	:= 108;
-- constant H_SYNC			: INTEGER	:= 40;
-- constant V_FRONT_PORCH	: INTEGER	:= 9;
-- constant V_SYNC			: INTEGER	:= 6;


constant H_FRONT_PORCH		: integer := 110;
constant H_SYNC				: integer := 40;
constant V_FRONT_PORCH		: integer := 4;
constant V_SYNC 			: integer := 5;

--------------------------------------------------------------------------------
signal x_cnt			: UNSIGNED(C_WIDTH-1 downto 0)	:= (others => '0');
signal y_cnt			: UNSIGNED(C_WIDTH-1 downto 0)	:= (others => '0');
signal xs_cnt			: UNSIGNED(C_WIDTH-1 downto 0)	:= (others => '0');
signal ys_cnt			: UNSIGNED(C_WIDTH-1 downto 0)	:= (others => '0');
signal x_scale_cnt		: INTEGER range 0 to C_SCALE-1	:= 0;
signal y_scale_cnt		: INTEGER range 0 to C_SCALE-1	:= 0;
signal scanline_cnt		: UNSIGNED(2 downto 0)			:= (others => '0');
signal hs_i				: STD_LOGIC;
signal vs_i				: STD_LOGIC;
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
process(clk_in)
begin
	if rising_edge(clk_in) then
		if(x_cnt = (FRAME_WIDTH-1))then
			x_cnt			<= (others => '0');
			if(y_cnt = (FRAME_HEIGHT-1))then
				y_cnt		<= (others => '0');
			else
				y_cnt		<= y_cnt + 1;
			end if;
		else
			x_cnt			<= x_cnt + 1;
		end if;
	end if;
end process;

x_pos_out			<= STD_LOGIC_VECTOR(x_cnt);
y_pos_out			<= STD_LOGIC_VECTOR(y_cnt);

process(clk_in)
begin
	if rising_edge(clk_in) then
		if(x_cnt = (FRAME_WIDTH-C_CNT_SHIFT))then
			xs_cnt				<= (others => '0');
			x_scale_cnt			<= 0;
			if(y_cnt = (FRAME_HEIGHT-1))then
				ys_cnt			<= (others => '0');
				y_scale_cnt		<= 0;
			else
				if(y_scale_cnt = C_SCALE-1)then
					y_scale_cnt	<= 0;
					ys_cnt		<= ys_cnt + 1;
				else
					y_scale_cnt	<= y_scale_cnt + 1;
				end if;
			end if;
		else
			if(x_scale_cnt = C_SCALE-1)then
				x_scale_cnt		<= 0;
				xs_cnt			<= xs_cnt + 1;
			else
				x_scale_cnt		<= x_scale_cnt + 1;
			end if;
		end if;
	end if;
end process;

xs_pos_out			<= STD_LOGIC_VECTOR(xs_cnt);
ys_pos_out			<= STD_LOGIC_VECTOR(ys_cnt);
--------------------------------------------------------------------------------
process(clk_in)
begin
	if rising_edge(clk_in) then
		if((x_cnt >= (SCREEN_WIDTH + H_FRONT_PORCH)) and (x_cnt < (SCREEN_WIDTH + H_FRONT_PORCH + H_SYNC)))then
			hs_out	<= SYNC_POLARITY;
		else
			hs_out	<= not SYNC_POLARITY;
		end if;
	end if;
end process;

process(clk_in)
begin
	if rising_edge(clk_in) then
		if(
			(
				((y_cnt = (SCREEN_HEIGHT + V_FRONT_PORCH - 1)) and (x_cnt = (SCREEN_WIDTH + H_FRONT_PORCH))) or
				(y_cnt >= (SCREEN_HEIGHT + V_FRONT_PORCH))
			) 
			and 
			(
				((y_cnt = (SCREEN_HEIGHT + V_FRONT_PORCH + V_SYNC - 1)) and (x_cnt = (SCREEN_WIDTH + H_FRONT_PORCH))) or
				(y_cnt >= (SCREEN_HEIGHT + V_FRONT_PORCH + V_SYNC - 1))
			)
		)then
			vs_out	<= SYNC_POLARITY;
		else
			vs_out	<= not SYNC_POLARITY;
		end if;
	end if;
end process;

process(clk_in)
begin
	if rising_edge(clk_in) then
		if((x_cnt < SCREEN_WIDTH) and (y_cnt < SCREEN_HEIGHT))then
			av_out		<= '1';
		else
			av_out		<= '0';
		end if;
	end if;
end process;
--------------------------------------------------------------------------------
end arch_imp;

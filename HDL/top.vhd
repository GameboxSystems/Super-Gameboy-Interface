--------------------------------------------------------------------------------
-- Engineer: Oleksandr Kiyenko
-- o.kiyenko@gmail.com
--------------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
Library UNISIM;
use UNISIM.vcomponents.all;
Library UNIMACRO;
use UNIMACRO.vcomponents.all;
--------------------------------------------------------------------------------
entity top is
port (
	sclk_in				: in  STD_LOGIC;
	led_out				: out STD_LOGIC;
	sgb_clk 			: out STD_LOGIC;
	-- HDMI Interface
	hdmi_data_p 		: out STD_LOGIC_VECTOR(2 downto 0);
	hdmi_data_n 		: out STD_LOGIC_VECTOR(2 downto 0);
	hdmi_clk_p 			: out STD_LOGIC;
	hdmi_clk_n 			: out STD_LOGIC;
	-- SGB Interface
	mclk_out			: out STD_LOGIC;
	sysclk_out			: out STD_LOGIC;
	refresh_out			: out STD_LOGIC;
	reset_out			: out STD_LOGIC;
	wrn_out				: out STD_LOGIC;
	rdn_out				: out STD_LOGIC;
	data_inout			: inout STD_LOGIC_VECTOR(7 downto 0);
	data_dir			: out STD_LOGIC;
	data_oe				: out STD_LOGIC;
	addr_out			: out STD_LOGIC_VECTOR(9 downto 0);
	-- PCM1808 ADC
	SCK_FPGA			: out STD_LOGIC;
	BCK_FPGA			: in  STD_LOGIC;
	LRCK_FPGA			: in  STD_LOGIC;
	DOUT_FPGA			: in  STD_LOGIC;
	-- NES Controller
	nes_clock			: out STD_LOGIC;
	nes_latch			: out STD_LOGIC;
	nes_data			: in  STD_LOGIC
);
end top;
--------------------------------------------------------------------------------
architecture arch_imp of top is
--------------------------------------------------------------------------------
component clk_sys is
port (
	clk_in				: in  STD_LOGIC;	-- Input 50MHz
	pclk				: out STD_LOGIC;	-- 74MHz 
	pclk2x				: out STD_LOGIC;	-- 74MHz*2 
	pclk10x				: out STD_LOGIC;	-- 74MHz*10
	serdesstrobe		: out STD_LOGIC;
	serdesrst			: out STD_LOGIC;
	sysrst				: out STD_LOGIC;
	sysrstn				: out STD_LOGIC;
	ind_clk				: out STD_LOGIC;
	pll_lock			: out STD_LOGIC;
	buf_lock			: out STD_LOGIC
);
end component;

component clk_sgb is
port(
	clk_in				: in STD_LOGIC;
	sclk_out			: out STD_LOGIC	
);
end component;

component hdmi_if is
port ( 
	serdes_rst			: in STD_LOGIC;
	-- Clocks
	pclk				: in STD_LOGIC;
	pclkx2				: in STD_LOGIC;
	pclkx10				: in STD_LOGIC;
	serdesstrobe		: in STD_LOGIC;
	-- Video interface
	vid_data			: in  STD_LOGIC_VECTOR(23 downto 0);
	vid_hsync			: in  STD_LOGIC;
	vid_vsync			: in  STD_LOGIC;
	vid_active_video	: in  STD_LOGIC;
	x_pos_in 			: in  STD_LOGIC_VECTOR(10 downto 0);
	y_pos_in 			: in  STD_LOGIC_VECTOR(10 downto 0);
	-- Audio interface
	audio_data			: in  STD_LOGIC_VECTOR(31 downto 0);
	-- HDMI Interface
	hdmi_data_p 		: out STD_LOGIC_VECTOR( 2 downto 0);
	hdmi_data_n 		: out STD_LOGIC_VECTOR( 2 downto 0);
	hdmi_clk_p 			: out STD_LOGIC;
	hdmi_clk_n 			: out STD_LOGIC
);
end component;

component nes_controller is
generic (
	C_CLK_DIV			: integer	:= 74
);
port (
	clk					: in  STD_LOGIC;
	data_out			: out STD_LOGIC_VECTOR(7 downto 0);
	nes_clock			: out STD_LOGIC;
	nes_latch			: out STD_LOGIC;
	nes_data			: in  STD_LOGIC	:= '0'
);
end component;

component i2s_if is
generic (
	C_CLK_RATE			: integer := 8
);
port (
	clk_in				: in  STD_LOGIC;
	sck_out				: out STD_LOGIC;	-- ADC clock
	-- I2S
	bck_in				: in  STD_LOGIC;
	lrck_in				: in  STD_LOGIC;
	data_in				: in  STD_LOGIC;
	-- Audio data
	l_data_out			: out STD_LOGIC_VECTOR(23 downto 0);
	r_data_out			: out STD_LOGIC_VECTOR(23 downto 0);
	update_out			: out STD_LOGIC
);
end component;

component snes2sgb is
generic (
	C_BRAM_DATA_WIDTH		: integer	:= 7;
	C_BRAM_ADDR_WIDTH		: integer	:= 16;
	
	C_SNES_X_RES			: integer	:= 256;
	C_SNES_Y_RES			: integer	:= 224;
	C_SNES_GS_X_OFFSET		: integer	:= 48;
	C_SNES_GS_Y_OFFSET		: integer	:= 40;
	
	C_X_RES					: integer	:= 1280;
	C_Y_RES					: integer	:= 720;
	C_SCALE_FACTOR			: integer	:= 3;
	C_SCALE_X_OFFSET		: integer	:= 85;
	C_SCALE_Y_OFFSET		: integer	:= 8;

	C_BG_COLOR				: STD_LOGIC_VECTOR(23 downto 0)	:= x"808080";
	C_JP_TO					: integer	:= 400;
	C_SM_EN					: boolean	:= TRUE
);
port (
	aclk				: in  STD_LOGIC;	-- System clock
	vclk				: in  STD_LOGIC;	-- Video clock
	----------------------------------------------------------------------------
	-- SGB Interface
	mclk_out			: out STD_LOGIC;
	sysclk_out			: out STD_LOGIC;
	refresh_out			: out STD_LOGIC;
	reset_out			: out STD_LOGIC;
	wrn_out				: out STD_LOGIC;
	rdn_out				: out STD_LOGIC;
	data_inout			: inout STD_LOGIC_VECTOR(7 downto 0);
	data_dir			: out STD_LOGIC;
	data_oe				: out STD_LOGIC;
	addr_out			: out STD_LOGIC_VECTOR(9 downto 0);
	----------------------------------------------------------------------------
	-- Right & Left & Down & Up & Start & Select & B & A
	joypad_1_in			: in  STD_LOGIC_VECTOR(7 downto 0)	:= (others => '1');
	joypad_2_in			: in  STD_LOGIC_VECTOR(7 downto 0)	:= (others => '1');
	sm_switch			: in  STD_LOGIC		:= '0';
	bg_upd_in			: in  STD_LOGIC		:= '0';
	ns_command			: out STD_LOGIC_VECTOR(7 downto 0);
	---------------------------------------------------------------------
	-- Framebuffer BRAM Interface
	m_fbram_addr		: out STD_LOGIC_VECTOR(15 downto 0);
	m_fbram_clk			: out STD_LOGIC;
	m_fbram_din			: out STD_LOGIC_VECTOR( 6 downto 0);
	m_fbram_we			: out STD_LOGIC_VECTOR( 0 downto 0);
	m_fbram_en			: out STD_LOGIC;
	m_fbram_rst			: out STD_LOGIC;

	s_fbram_addr		: out STD_LOGIC_VECTOR(15 downto 0);
	s_fbram_clk			: out STD_LOGIC;
	s_fbram_dout		: in  STD_LOGIC_VECTOR( 6 downto 0);
	s_fbram_we			: out STD_LOGIC_VECTOR( 0 downto 0);
	s_fbram_en			: out STD_LOGIC;
	s_fbram_rst			: out STD_LOGIC;
	---------------------------------------------------------------------
	-- Tiles BRAM Interfaces
	m_tram_p1_addr		: out STD_LOGIC_VECTOR(13 downto 0); -- 256*8*8=16384
	m_tram_p1_clk		: out STD_LOGIC;
	m_tram_p1_din		: out STD_LOGIC_VECTOR( 1 downto 0);	-- 16 colors (half)
	m_tram_p1_we		: out STD_LOGIC_VECTOR( 0 downto 0);
	m_tram_p1_en		: out STD_LOGIC;
	m_tram_p1_rst		: out STD_LOGIC;
	
	s_tram_p1_addr		: out STD_LOGIC_VECTOR(13 downto 0); -- 256*8*8=16384
	s_tram_p1_clk		: out STD_LOGIC;
	s_tram_p1_dout		: in  STD_LOGIC_VECTOR( 1 downto 0)	:= (others => '0');	-- 16 colors
	s_tram_p1_en		: out STD_LOGIC;
	s_tram_p1_rst		: out STD_LOGIC;

	m_tram_p2_addr		: out STD_LOGIC_VECTOR(13 downto 0); -- 256*8*8=16384
	m_tram_p2_clk		: out STD_LOGIC;
	m_tram_p2_din		: out STD_LOGIC_VECTOR( 1 downto 0);	-- 16 colors (half)
	m_tram_p2_we		: out STD_LOGIC_VECTOR( 0 downto 0);
	m_tram_p2_en		: out STD_LOGIC;
	m_tram_p2_rst		: out STD_LOGIC;
	
	s_tram_p2_addr		: out STD_LOGIC_VECTOR(13 downto 0); -- 256*8*8=16384
	s_tram_p2_clk		: out STD_LOGIC;
	s_tram_p2_dout		: in  STD_LOGIC_VECTOR( 1 downto 0)	:= (others => '0');	-- 16 colors
	s_tram_p2_en		: out STD_LOGIC;
	s_tram_p2_rst		: out STD_LOGIC;
	---------------------------------------------------------------------
	-- Map BRAM Interfaces
	m_mram_addr			: out STD_LOGIC_VECTOR( 9 downto 0); -- 32*28=896
	m_mram_clk			: out STD_LOGIC;
	m_mram_din			: out STD_LOGIC_VECTOR(11 downto 0); -- 8+2+1+1=12 
	m_mram_we			: out STD_LOGIC_VECTOR( 0 downto 0);
	m_mram_en			: out STD_LOGIC;
	m_mram_rst			: out STD_LOGIC;

	s_mram_addr			: out STD_LOGIC_VECTOR( 9 downto 0); -- 32*28=896
	s_mram_clk			: out STD_LOGIC;
	s_mram_dout			: in  STD_LOGIC_VECTOR(11 downto 0)	:= (others => '0'); -- 8+2+1+1=12 
	s_mram_en			: out STD_LOGIC;
	s_mram_rst			: out STD_LOGIC;
	---------------------------------------------------------------------
	-- Pallete BRAM Interfaces
	m_pram_addr			: out STD_LOGIC_VECTOR( 6 downto 0); -- 8*16=128
	m_pram_clk			: out STD_LOGIC;
	m_pram_din			: out STD_LOGIC_VECTOR(14 downto 0);
	m_pram_we			: out STD_LOGIC_VECTOR( 0 downto 0);
	m_pram_en			: out STD_LOGIC;
	m_pram_rst			: out STD_LOGIC;

	s_pram_addr			: out STD_LOGIC_VECTOR( 6 downto 0); -- 8*16=128
	s_pram_clk			: out STD_LOGIC;
	s_pram_dout			: in  STD_LOGIC_VECTOR(14 downto 0)	:= (others => '0');
	s_pram_en			: out STD_LOGIC;
	s_pram_rst			: out STD_LOGIC;
	---------------------------------------------------------------------
	-- Video IO Interface
	x_pos_out			: out STD_LOGIC_VECTOR(10 downto 0);
	y_pos_out			: out STD_LOGIC_VECTOR(10 downto 0);
	vid_io_active_video	: out STD_LOGIC;
	vid_io_vsync		: out STD_LOGIC;
	vid_io_hsync		: out STD_LOGIC;
	vid_io_data			: out STD_LOGIC_VECTOR(23 downto 0)
);
end component;

component fbram
port (
	clka	: in  STD_LOGIC;
	wea		: in  STD_LOGIC_VECTOR( 0 downto 0);
	addra	: in  STD_LOGIC_VECTOR(15 downto 0);
	dina	: in  STD_LOGIC_VECTOR( 6 downto 0);
	clkb	: in  STD_LOGIC;
	addrb	: in  STD_LOGIC_VECTOR(15 downto 0);
	doutb	: out STD_LOGIC_VECTOR( 6 downto 0)
);
end component;

component tram
port (
	clka	: in  STD_LOGIC;
	wea		: in  STD_LOGIC_VECTOR( 0 downto 0);
	addra	: in  STD_LOGIC_VECTOR(13 downto 0);
	dina	: in  STD_LOGIC_VECTOR( 1 downto 0);
	clkb	: in  STD_LOGIC;
	addrb	: in  STD_LOGIC_VECTOR(13 downto 0);
	doutb	: out STD_LOGIC_VECTOR( 1 downto 0)
);
end component;

component mram
port (
	clka	: in  STD_LOGIC;
	wea		: in  STD_LOGIC_VECTOR( 0 downto 0);
	addra	: in  STD_LOGIC_VECTOR( 9 downto 0);
	dina	: in  STD_LOGIC_VECTOR(11 downto 0);
	clkb	: in  STD_LOGIC;
	addrb	: in  STD_LOGIC_VECTOR( 9 downto 0);
	doutb	: out STD_LOGIC_VECTOR(11 downto 0)
);
end component;

component pram
port (
	clka	: in  STD_LOGIC;
	wea		: in  STD_LOGIC_VECTOR( 0 downto 0);
	addra	: in  STD_LOGIC_VECTOR( 6 downto 0);
	dina	: in  STD_LOGIC_VECTOR(14 downto 0);
	clkb	: in  STD_LOGIC;
	addrb	: in  STD_LOGIC_VECTOR( 6 downto 0);
	doutb	: out STD_LOGIC_VECTOR(14 downto 0)
);
end component;

--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//
-- Debug
--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//
-- component icon IS
-- port (
    -- CONTROL0: inout std_logic_vector(35 downto 0)
-- );
-- END component;

-- component ila IS
-- port (
    -- CONTROL: inout std_logic_vector(35 downto 0);
    -- CLK: in std_logic;
    -- TRIG0: in std_logic_vector(0 to 0);
    -- TRIG1: in std_logic_vector(0 to 0);
    -- TRIG2: in std_logic_vector(14 downto 0);
    -- TRIG3: in std_logic_vector(17 downto 0)
-- );
-- END component;

-- component vio IS
-- port (
	-- CONTROL: inout std_logic_vector(35 downto 0);
	-- ASYNC_OUT: out std_logic_vector(7 downto 0)
-- );
-- END component;
--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//
--------------------------------------------------------------------------------
function blink(cnt :UNSIGNED; w : integer; b : integer) return STD_LOGIC is
variable bo : STD_LOGIC;
begin
	case b is
		when 0	=>	bo	:= '0';
		when 1	=>	bo	:= cnt(w-1) and cnt(w-2) and cnt(w-3) and cnt(w-4);
		when 2	=>	bo	:= cnt(w-1) and cnt(w-2) and cnt(w-4);
		when 3	=>	bo	:= cnt(w-1) and (cnt(w-2) or cnt(w-3)) and cnt(w-4);
		when 4	=>	bo	:= cnt(w-1) and cnt(w-4);
		when 5	=>	bo	:= (cnt(w-1) or (cnt(w-2) and cnt(w-3))) and cnt(w-4);
		when 6	=>	bo	:= (cnt(w-1) or cnt(w-2)) and cnt(w-4);
		when 7	=>	bo	:= (cnt(w-1) or cnt(w-2) or cnt(w-3)) and cnt(w-4);
		when 8	=>	bo	:= cnt(w-4);
		when others => bo	:= '0';
	end case;
	return bo;
end blink;
--------------------------------------------------------------------------------
constant DEBUG_MODE		: BOOLEAN	:= TRUE;
constant LED_CNT_WIDTH	: INTEGER	:= 29;
constant DMG_BRAM_WIDTH	: INTEGER 	:= 4;
constant GBC_BRAM_WIDTH	: INTEGER 	:= 18;
constant SYS_CLK_FREQ	: INTEGER	:= 74250000;
constant GB_X_RES		: INTEGER 	:= 160;
constant GB_Y_RES		: INTEGER 	:= 144;
constant DISPLAY_X_RES	: INTEGER 	:= 1280;
constant DISPLAY_Y_RES	: INTEGER 	:= 720;
constant SCALE_FACTOR	: INTEGER 	:= 5;
constant DB_CYCLES		: INTEGER 	:= 3;
--------------------------------------------------------------------------------
signal sclk				: STD_LOGIC;
signal pclk				: STD_LOGIC;
signal pclk2x			: STD_LOGIC;
signal pclk10x			: STD_LOGIC;
signal serdesstrobe		: STD_LOGIC;
signal serdesrst		: STD_LOGIC;
signal sysrst			: STD_LOGIC;
signal sysrstn			: STD_LOGIC;
-- Video
signal vid_io_active_video	: STD_LOGIC;
signal vid_io_vsync			: STD_LOGIC;
signal vid_io_hsync			: STD_LOGIC;
signal vid_io_vblank		: STD_LOGIC;
signal vid_io_hblank		: STD_LOGIC;
signal vid_io_data			: STD_LOGIC_VECTOR(23 downto 0);
signal vid_x_pos			: STD_LOGIC_VECTOR(10 downto 0);
signal vid_y_pos			: STD_LOGIC_VECTOR(10 downto 0);

-- Indication
signal pll_lock			: STD_LOGIC;
signal buf_lock			: STD_LOGIC;
signal vs_live_out		: STD_LOGIC;
signal clk_live_out		: STD_LOGIC;
signal ind_clk			: STD_LOGIC;
signal clk_cnt			: UNSIGNED(LED_CNT_WIDTH-1 downto 0);
signal led_drv			: STD_LOGIC;

signal dmg_addra		: STD_LOGIC_VECTOR(15 downto 0);
signal dmg_addrb		: STD_LOGIC_VECTOR(15 downto 0);
signal gbc_addra		: STD_LOGIC_VECTOR(14 downto 0);
signal gbc_addrb		: STD_LOGIC_VECTOR(14 downto 0);
signal dmg_dina			: STD_LOGIC_VECTOR(DMG_BRAM_WIDTH-1 downto 0);
signal dmg_doutb		: STD_LOGIC_VECTOR(DMG_BRAM_WIDTH-1 downto 0);
signal gbc_dina			: STD_LOGIC_VECTOR(GBC_BRAM_WIDTH-1 downto 0);
signal gbc_doutb		: STD_LOGIC_VECTOR(GBC_BRAM_WIDTH-1 downto 0);
signal wea				: STD_LOGIC_VECTOR( 0 downto 0);

signal red_data			: STD_LOGIC_VECTOR( 7 downto 0);
signal green_data		: STD_LOGIC_VECTOR( 7 downto 0);
signal blue_data		: STD_LOGIC_VECTOR( 7 downto 0);
signal x_pos_out		: STD_LOGIC_VECTOR(10 downto 0);
signal y_pos_out		: STD_LOGIC_VECTOR(10 downto 0);
signal cb_hcount		: STD_LOGIC_VECTOR(11 downto 0);
signal cb_vcount		: STD_LOGIC_VECTOR(11 downto 0);
signal scale_hcount		: STD_LOGIC_VECTOR( 7 downto 0);
signal scale_vcount		: STD_LOGIC_VECTOR( 7 downto 0);
signal sl_count			: STD_LOGIC_VECTOR( 2 downto 0);

signal nes_keys			: STD_LOGIC_VECTOR( 7 downto 0);
signal gb_palette		: STD_LOGIC_VECTOR( 3 downto 0)	:= x"0";
signal gb_menu			: STD_LOGIC_VECTOR( 1 downto 0)	:= "00";
signal gb_sl			: STD_LOGIC_VECTOR( 2 downto 0)	:= "000";

signal adc_audio_l		: STD_LOGIC_VECTOR(23 downto 0);
signal adc_audio_r		: STD_LOGIC_VECTOR(23 downto 0);
signal audio_data		: STD_LOGIC_VECTOR(31 downto 0);

signal scale_rst		: STD_LOGIC;
signal scale_x_inc		: STD_LOGIC;
signal scale_y_inc		: STD_LOGIC;

-- signal nes_clock_drv	: STD_LOGIC;
-- signal nes_latch_drv	: STD_LOGIC;

-- Framebuffer BRAM Interface
signal m_fbram_addr			: STD_LOGIC_VECTOR(15 downto 0);
signal m_fbram_clk			: STD_LOGIC;
signal m_fbram_din			: STD_LOGIC_VECTOR( 6 downto 0);
signal m_fbram_we			: STD_LOGIC_VECTOR( 0 downto 0);
signal m_fbram_en			: STD_LOGIC;
signal m_fbram_rst			: STD_LOGIC;
signal s_fbram_addr			: STD_LOGIC_VECTOR(15 downto 0);
signal s_fbram_clk			: STD_LOGIC;
signal s_fbram_dout			: STD_LOGIC_VECTOR( 6 downto 0);
signal s_fbram_we			: STD_LOGIC_VECTOR( 0 downto 0);
signal s_fbram_en			: STD_LOGIC;
signal s_fbram_rst			: STD_LOGIC;
-- Tiles BRAM Interfaces
signal m_tram_p1_addr		: STD_LOGIC_VECTOR(13 downto 0); -- 256*8*8=16384
signal m_tram_p1_clk		: STD_LOGIC;
signal m_tram_p1_din		: STD_LOGIC_VECTOR( 1 downto 0);	-- 16 colors (half)
signal m_tram_p1_we			: STD_LOGIC_VECTOR( 0 downto 0);
signal m_tram_p1_en			: STD_LOGIC;
signal m_tram_p1_rst		: STD_LOGIC;
signal s_tram_p1_addr		: STD_LOGIC_VECTOR(13 downto 0); -- 256*8*8=16384
signal s_tram_p1_clk		: STD_LOGIC;
signal s_tram_p1_dout		: STD_LOGIC_VECTOR( 1 downto 0)	:= (others => '0');	-- 16 colors
signal s_tram_p1_en			: STD_LOGIC;
signal s_tram_p1_rst		: STD_LOGIC;
signal m_tram_p2_addr		: STD_LOGIC_VECTOR(13 downto 0); -- 256*8*8=16384
signal m_tram_p2_clk		: STD_LOGIC;
signal m_tram_p2_din		: STD_LOGIC_VECTOR( 1 downto 0);	-- 16 colors (half)
signal m_tram_p2_we			: STD_LOGIC_VECTOR( 0 downto 0);
signal m_tram_p2_en			: STD_LOGIC;
signal m_tram_p2_rst		: STD_LOGIC;
signal s_tram_p2_addr		: STD_LOGIC_VECTOR(13 downto 0); -- 256*8*8=16384
signal s_tram_p2_clk		: STD_LOGIC;
signal s_tram_p2_dout		: STD_LOGIC_VECTOR( 1 downto 0)	:= (others => '0');	-- 16 colors
signal s_tram_p2_en			: STD_LOGIC;
signal s_tram_p2_rst		: STD_LOGIC;
-- Map BRAM Interfaces
signal m_mram_addr			: STD_LOGIC_VECTOR( 9 downto 0); -- 32*28=896
signal m_mram_clk			: STD_LOGIC;
signal m_mram_din			: STD_LOGIC_VECTOR(11 downto 0); -- 8+2+1+1=12 
signal m_mram_we			: STD_LOGIC_VECTOR( 0 downto 0);
signal m_mram_en			: STD_LOGIC;
signal m_mram_rst			: STD_LOGIC;
signal s_mram_addr			: STD_LOGIC_VECTOR( 9 downto 0); -- 32*28=896
signal s_mram_clk			: STD_LOGIC;
signal s_mram_dout			: STD_LOGIC_VECTOR(11 downto 0)	:= (others => '0'); -- 8+2+1+1=12 
signal s_mram_en			: STD_LOGIC;
signal s_mram_rst			: STD_LOGIC;
-- Pallete BRAM Interfaces
signal m_pram_addr			: STD_LOGIC_VECTOR( 6 downto 0); -- 8*16=128
signal m_pram_clk			: STD_LOGIC;
signal m_pram_din			: STD_LOGIC_VECTOR(14 downto 0);
signal m_pram_we			: STD_LOGIC_VECTOR( 0 downto 0);
signal m_pram_en			: STD_LOGIC;
signal m_pram_rst			: STD_LOGIC;
signal s_pram_addr			: STD_LOGIC_VECTOR( 6 downto 0); -- 8*16=128
signal s_pram_clk			: STD_LOGIC;
signal s_pram_dout			: STD_LOGIC_VECTOR(14 downto 0)	:= (others => '0');
signal s_pram_en			: STD_LOGIC;
signal s_pram_rst			: STD_LOGIC;
--------------------------------------------------------------------------------
-- Debug
--------------------------------------------------------------------------------
signal ila_control		: STD_LOGIC_VECTOR(35 downto 0);
signal ila_trig_a		: STD_LOGIC_VECTOR( 0 downto 0);
signal ila_trig_b		: STD_LOGIC_VECTOR( 0 downto 0);
signal ila_trig_c		: STD_LOGIC_VECTOR(14 downto 0);
signal ila_trig_d		: STD_LOGIC_VECTOR(17 downto 0);
signal adc_update		: STD_LOGIC;
signal vio_keys			: STD_LOGIC_VECTOR( 7 downto 0);
signal dbg_x_pos		: STD_LOGIC_VECTOR( 7 downto 0);
signal dbg_y_pos		: STD_LOGIC_VECTOR( 7 downto 0);

signal dbg_clk			: STD_LOGIC;
signal dbg_data			: STD_LOGIC_VECTOR(17 downto 0);

--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
clk_sys_inst: clk_sys
port map(
	clk_in				=> sclk_in,
	pclk				=> pclk,
	pclk2x				=> pclk2x,
	pclk10x				=> pclk10x,
	serdesstrobe		=> serdesstrobe,
	serdesrst			=> serdesrst,
	sysrst				=> sysrst,
	sysrstn				=> sysrstn,
	ind_clk				=> ind_clk,
	pll_lock			=> pll_lock,
	buf_lock			=> buf_lock
);

clk_sgb_inst: clk_sgb
port map(
	clk_in				=> pclk,
	sclk_out 			=> sclk
);

--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//
snes2sgb_inst: snes2sgb
generic map(
	C_BRAM_DATA_WIDTH		=> 7,
	C_BRAM_ADDR_WIDTH		=> 16,
	C_SNES_X_RES			=> 256,
	C_SNES_Y_RES			=> 224,
	C_SNES_GS_X_OFFSET		=> 48,
	C_SNES_GS_Y_OFFSET		=> 40,
	C_X_RES					=> 1280,
	C_Y_RES					=> 720,
	C_SCALE_FACTOR			=> 3,
	C_SCALE_X_OFFSET		=> 85,
	C_SCALE_Y_OFFSET		=> 8,
	C_BG_COLOR				=> x"808080",
	C_JP_TO					=> 400,
	C_SM_EN					=> TRUE
)
port map(
	aclk				=> sclk,
	vclk				=> pclk,
	----------------------------------------------------------------------------
	-- SGB Interface
	mclk_out			=> mclk_out,
	sysclk_out			=> sysclk_out,
	refresh_out			=> refresh_out,	
	reset_out			=> reset_out,
	wrn_out				=> wrn_out,	
	rdn_out				=> rdn_out,	
	data_inout			=> data_inout,
	data_dir			=> data_dir,	
	data_oe				=> data_oe,
	addr_out			=> addr_out,
	----------------------------------------------------------------------------
	-- Right & Left & Down & Up & Start & Select & B & A
	joypad_1_in			=> nes_keys,
	joypad_2_in			=> nes_keys,
	sm_switch			=> nes_keys(1),
	bg_upd_in			=> nes_keys(0),
	ns_command			=> open,
	---------------------------------------------------------------------
	-- Framebuffer BRAM Interface
	m_fbram_addr		=> m_fbram_addr,
	m_fbram_clk			=> m_fbram_clk,
	m_fbram_din			=> m_fbram_din,
	m_fbram_we			=> m_fbram_we,
	m_fbram_en			=> m_fbram_en,	
	m_fbram_rst			=> m_fbram_rst,	
	s_fbram_addr		=> s_fbram_addr,
	s_fbram_clk			=> s_fbram_clk,
	s_fbram_dout		=> s_fbram_dout,
	s_fbram_we			=> s_fbram_we,
	s_fbram_en			=> s_fbram_en,	
	s_fbram_rst			=> s_fbram_rst,	
	-- Tiles BRAM Interfaces
	m_tram_p1_addr		=> m_tram_p1_addr,
	m_tram_p1_clk		=> m_tram_p1_clk,
	m_tram_p1_din		=> m_tram_p1_din,	
	m_tram_p1_we		=> m_tram_p1_we,
	m_tram_p1_en		=> m_tram_p1_en,
	m_tram_p1_rst		=> m_tram_p1_rst,	
	s_tram_p1_addr		=> s_tram_p1_addr,	
	s_tram_p1_clk		=> s_tram_p1_clk,
	s_tram_p1_dout		=> s_tram_p1_dout,	
	s_tram_p1_en		=> s_tram_p1_en,
	s_tram_p1_rst		=> s_tram_p1_rst,	
	m_tram_p2_addr		=> m_tram_p2_addr,	
	m_tram_p2_clk		=> m_tram_p2_clk,
	m_tram_p2_din		=> m_tram_p2_din,	
	m_tram_p2_we		=> m_tram_p2_we,
	m_tram_p2_en		=> m_tram_p2_en,
	m_tram_p2_rst		=> m_tram_p2_rst,	
	s_tram_p2_addr		=> s_tram_p2_addr,	
	s_tram_p2_clk		=> s_tram_p2_clk,
	s_tram_p2_dout		=> s_tram_p2_dout,	
	s_tram_p2_en		=> s_tram_p2_en,
	s_tram_p2_rst		=> s_tram_p2_rst,	
	-- Map BRAM Interfaces
	m_mram_addr			=> m_mram_addr,
	m_mram_clk			=> m_mram_clk,
	m_mram_din			=> m_mram_din,	
	m_mram_we			=> m_mram_we,
	m_mram_en			=> m_mram_en,	
	m_mram_rst			=> m_mram_rst,	
	s_mram_addr			=> s_mram_addr,	
	s_mram_clk			=> s_mram_clk,
	s_mram_dout			=> s_mram_dout,	 
	s_mram_en			=> s_mram_en,
	s_mram_rst			=> s_mram_rst,	
	-- Pallete BRAM Interfaces
	m_pram_addr			=> m_pram_addr,
	m_pram_clk			=> m_pram_clk,
	m_pram_din			=> m_pram_din,	
	m_pram_we			=> m_pram_we,
	m_pram_en			=> m_pram_en,	
	m_pram_rst			=> m_pram_rst,	
	s_pram_addr			=> s_pram_addr,	
	s_pram_clk			=> s_pram_clk,
	s_pram_dout			=> s_pram_dout,	
	s_pram_en			=> s_pram_en,
	s_pram_rst			=> s_pram_rst,	
	-- Video IO Interface
	x_pos_out 			=> vid_x_pos,
	y_pos_out			=> vid_y_pos,
	
	vid_io_active_video	=> vid_io_active_video,
	vid_io_vsync		=> vid_io_vsync,
	vid_io_hsync		=> vid_io_hsync,	
	vid_io_data			=> vid_io_data			
);

fbram_inst: fbram
port map(
	clka	=> m_fbram_clk,
	wea		=> m_fbram_we,
	addra	=> m_fbram_addr,
	dina	=> m_fbram_din,
	clkb	=> s_fbram_clk,
	addrb	=> s_fbram_addr,
	doutb	=> s_fbram_dout
);

tram_p1_inst: tram
port map(
	clka	=> m_tram_p1_clk,
	wea		=> m_tram_p1_we,
	addra	=> m_tram_p1_addr,
	dina	=> m_tram_p1_din,
	clkb	=> s_tram_p1_clk,
	addrb	=> s_tram_p1_addr,
	doutb	=> s_tram_p1_dout
);

tram_p2_inst: tram
port map(
	clka	=> m_tram_p2_clk,
	wea		=> m_tram_p2_we,
	addra	=> m_tram_p2_addr,
	dina	=> m_tram_p2_din,
	clkb	=> s_tram_p2_clk,
	addrb	=> s_tram_p2_addr,
	doutb	=> s_tram_p2_dout
);

mram_inst: mram
port map(
	clka	=> m_mram_clk,
	wea		=> m_mram_we,
	addra	=> m_mram_addr,
	dina	=> m_mram_din,
	clkb	=> s_mram_clk,
	addrb	=> s_mram_addr,
	doutb	=> s_mram_dout
);

pram_inst: pram
port map(
	clka	=> m_pram_clk,
	wea		=> m_pram_we,
	addra	=> m_pram_addr,
	dina	=> m_pram_din,
	clkb	=> s_pram_clk,
	addrb	=> s_pram_addr,
	doutb	=> s_pram_dout
);
--------------------------------------------------------------------------------
-- HDMI Video
--------------------------------------------------------------------------------
hdmi_if_inst: hdmi_if
port map(
	serdes_rst			=> serdesrst,
	-- Clocks
	pclk				=> pclk,
	pclkx2				=> pclk2x,
	pclkx10				=> pclk10x,
	serdesstrobe		=> serdesstrobe,
	-- Video interface
	vid_data			=> vid_io_data,
	vid_hsync			=> vid_io_hsync,
	vid_vsync			=> vid_io_vsync,
	vid_active_video	=> vid_io_active_video,
	x_pos_in 			=> vid_x_pos,
	y_pos_in 			=> vid_y_pos,
	-- Audio interface
	audio_data			=> audio_data,
	-- HDMI Interface
	hdmi_data_p 		=> hdmi_data_p,
	hdmi_data_n 		=> hdmi_data_n,
	hdmi_clk_p 			=> hdmi_clk_p,
	hdmi_clk_n 			=> hdmi_clk_n
);
--------------------------------------------------------------------------------
-- Audio
--------------------------------------------------------------------------------
adc_inst: i2s_if
generic map(
	-- Master mode 256 fs ~ 32K
	C_CLK_RATE			=> 8
)
port map(
	clk_in				=> pclk,
	sck_out				=> SCK_FPGA,
	-- I2S
	bck_in				=> BCK_FPGA,
	lrck_in				=> LRCK_FPGA,
	data_in				=> DOUT_FPGA,
	-- Audio data
	l_data_out			=> adc_audio_l,
	r_data_out			=> adc_audio_r,
	update_out			=> adc_update
);
audio_data				<= adc_audio_l(23 downto 8) & adc_audio_r(23 downto 8);

--------------------------------------------------------------------------------
-- Debug
--------------------------------------------------------------------------------
-- icon_inst: icon
-- port map(
    -- CONTROL0	=> ila_control
-- );

-- ila_inst: ila
-- port map(
    -- CONTROL		=> ila_control,
    -- CLK			=> pclk,
    -- TRIG0		=> ila_trig_a,
    -- TRIG1		=> ila_trig_b,
    -- TRIG2		=> ila_trig_c,
    -- TRIG3		=> ila_trig_d
-- );

-- ila_trig_a(0)		<= dbg_clk;
-- ila_trig_b(0)		<= gbc_vs;
-- ila_trig_c			<= gbc_addra;
-- ila_trig_d			<= dbg_data;

-- ila_trig_a(0)		<= wea(0);
-- ila_trig_b(0)		<= gbc_vs;
-- ila_trig_c			<= gbc_addra;
-- ila_trig_d			<= gbc_dina;

-- ila_trig_a(0)		<= wea(0);
-- ila_trig_b(0)		<= gbc_vs;
-- ila_trig_c			<= gbc_addrb;
-- ila_trig_d			<= gbc_doutb;
--------------------------------------------------------------------------------
-- Keyboard
--------------------------------------------------------------------------------
nes_inst: nes_controller
generic map(
	C_CLK_DIV			=> 74
)
port map(
	clk					=> pclk,
	nes_clock			=> nes_clock,
	nes_latch			=> nes_latch,
	nes_data			=> nes_data,
	data_out			=> nes_keys
);

--------------------------------------------------------------------------------
-- Indication
--------------------------------------------------------------------------------
process(ind_clk)
begin
	if rising_edge(ind_clk) then
		clk_cnt			<= clk_cnt + 1;
		if(pll_lock = '0')then
			led_drv		<= blink(clk_cnt, LED_CNT_WIDTH, 1);
		elsif(buf_lock = '0')then
			led_drv		<= blink(clk_cnt, LED_CNT_WIDTH, 2);
		elsif(clk_live_out = '0')then
			led_drv		<= blink(clk_cnt, LED_CNT_WIDTH, 3);
		elsif(vs_live_out = '0')then
			led_drv		<= blink(clk_cnt, LED_CNT_WIDTH, 4);
		else
			led_drv		<= '0';--blink(clk_cnt, LED_CNT_WIDTH, 8);
		end if;
	end if;
end process;
led_out					<= led_drv;
--------------------------------------------------------------------------------
end arch_imp;

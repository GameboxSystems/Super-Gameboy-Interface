--------------------------------------------------------------------------------
-- Engineer: Oleksandr Kiyenko
-- o.kiyenko@gmail.com
--------------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
--------------------------------------------------------------------------------
entity snes2sgb is
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
	m_fbram_addr		: out STD_LOGIC_VECTOR(15 downto 0);	-- 256x224=57344
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
end snes2sgb;
--------------------------------------------------------------------------------
architecture arch_imp of snes2sgb is
--------------------------------------------------------------------------------
function next_buf(bufn :STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
begin
	if(UNSIGNED(bufn) = TO_UNSIGNED(17,5))then
		return STD_LOGIC_VECTOR(TO_UNSIGNED(0,5));
	else
		return STD_LOGIC_VECTOR(UNSIGNED(bufn) + 1);
	end if;
end function;


component sgb_phy is
port (
	aclk				: in  STD_LOGIC;	-- System clock
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
	s_valid				: in  STD_LOGIC;
	s_ready				: out STD_LOGIC;
	s_rnw				: in  STD_LOGIC;
	s_data				: in  STD_LOGIC_VECTOR(7 downto 0);
	s_addr				: in  STD_LOGIC_VECTOR(9 downto 0);
	m_valid				: out STD_LOGIC;
	m_data				: out STD_LOGIC_VECTOR(7 downto 0)
);
end component;

component sgb_trans is
generic (
	C_ADDR_WIDTH		: integer	:= 10;
	C_COUNT_WIDTH		: integer	:= 16;
	C_DEST_WIDTH		: integer	:= 2
);
port (
	aclk				: in  STD_LOGIC;	-- System clock
	----------------------------------------------------------------------------
	-- Control Interface
	s_trans_valid		: in  STD_LOGIC;
	s_trans_ready		: out STD_LOGIC;
	s_trans_rnw			: in  STD_LOGIC;
	s_trans_inc			: in  STD_LOGIC;
	s_trans_addr		: in  STD_LOGIC_VECTOR(C_ADDR_WIDTH-1 downto 0);
	s_trans_data		: in  STD_LOGIC_VECTOR( 7 downto 0);
	s_trans_count		: in  STD_LOGIC_VECTOR(C_COUNT_WIDTH-1 downto 0);
	s_trans_dest		: in  STD_LOGIC_VECTOR(C_DEST_WIDTH-1 downto 0);
	
	m_trans_dest_valid	: out STD_LOGIC_VECTOR(C_DEST_WIDTH-1 downto 0);
	m_trans_dest_ready	: in  STD_LOGIC_VECTOR(C_DEST_WIDTH-1 downto 0);
	m_trans_data		: out STD_LOGIC_VECTOR( 7 downto 0);
	
	-- PHY Interface
	phy_op_valid		: out STD_LOGIC;
	phy_op_ready		: in  STD_LOGIC;
	phy_op_rnw			: out STD_LOGIC;
	phy_op_data			: out STD_LOGIC_VECTOR(7 downto 0);
	phy_op_addr			: out STD_LOGIC_VECTOR(9 downto 0);
	phy_res_valid		: in  STD_LOGIC;
	phy_res_data		: in  STD_LOGIC_VECTOR(7 downto 0)
);
end component;

component video_dec is
generic (
	C_BRAM_DATA_WIDTH		: integer	:= 9;
	C_BRAM_ADDR_WIDTH		: integer	:= 16;
	C_SNES_X_RES			: integer	:= 256;
	C_SNES_Y_RES			: integer	:= 224;
	C_SNES_GS_X_OFFSET		: integer	:= 48;
	C_SNES_GS_Y_OFFSET		: integer	:= 40
);
port (
	clk_in					: in  STD_LOGIC;	-- System clock
	-- Control Interface	
	ctrl_valid				: in  STD_LOGIC;
	ctrl_data				: in  STD_LOGIC_VECTOR( 7 downto 0);
	-- Video Interface	
	vram_valid				: in  STD_LOGIC;
	vram_ready				: out STD_LOGIC;
	vram_data				: in  STD_LOGIC_VECTOR( 7 downto 0);
	-- Output Interface
	m_valid					: out STD_LOGIC;
	m_data					: out STD_LOGIC_VECTOR( 1 downto 0);
	m_dest					: out STD_LOGIC_VECTOR(C_BRAM_ADDR_WIDTH-1 downto 0)
);
end component;

component palette_enc is
generic(
	C_BRAM_DATA_WIDTH		: integer	:= 9;
	C_BRAM_ADDR_WIDTH		: integer	:= 16
);
port (
	clk						: in  STD_LOGIC;
	s_valid					: in  STD_LOGIC;
	s_dest					: in  STD_LOGIC_VECTOR(C_BRAM_ADDR_WIDTH-1 downto 0);
	s_data					: in  STD_LOGIC_VECTOR( 1 downto 0);
	m_valid					: out STD_LOGIC;
	m_data					: out STD_LOGIC_VECTOR(C_BRAM_DATA_WIDTH-1 downto 0);
	m_dest					: out STD_LOGIC_VECTOR(C_BRAM_ADDR_WIDTH-1 downto 0)
);
end component;

component tile_dec is
port (
	clk_in					: in  STD_LOGIC;
	-- Control Interface	
	ctrl_valid				: in  STD_LOGIC;
	ctrl_data				: in  STD_LOGIC_VECTOR( 1 downto 0);
	-- Video Interface	
	vram_valid				: in  STD_LOGIC;
	vram_ready				: out STD_LOGIC;
	vram_data				: in  STD_LOGIC_VECTOR( 7 downto 0);
	-- Output Interface
	m_valid_a				: out STD_LOGIC;
	m_valid_b				: out STD_LOGIC;
	m_data					: out STD_LOGIC_VECTOR( 3 downto 0);
	m_dest					: out STD_LOGIC_VECTOR(13 downto 0)
);
end component;

component map_dec is
port (
	clk_in					: in  STD_LOGIC;
	-- Control Interface	
	ctrl_valid				: in  STD_LOGIC;
	end_out					: out STD_LOGIC;
	-- Video Interface	
	vram_valid				: in  STD_LOGIC;
	vram_ready				: out STD_LOGIC;
	vram_data				: in  STD_LOGIC_VECTOR( 7 downto 0);
	-- GS Pallete update
	gspal_valid				: in  STD_LOGIC;
	gspal_data				: in  STD_LOGIC_VECTOR(14 downto 0);
	gspal_dest				: in  STD_LOGIC_VECTOR( 5 downto 0);
	-- Tiles Map
	map_valid				: out STD_LOGIC;
	map_data				: out STD_LOGIC_VECTOR(11 downto 0);
	map_dest				: out STD_LOGIC_VECTOR( 9 downto 0);
	-- Pallete
	pal_valid				: out STD_LOGIC;
	pal_data				: out STD_LOGIC_VECTOR(14 downto 0);
	pal_dest				: out STD_LOGIC_VECTOR( 6 downto 0)
);
end component;

component bg_draw is
port (
	clk_in					: in  STD_LOGIC;	-- System clock
	update_in				: in  STD_LOGIC;	
	-- Map BRAM Interface
	s_mram_addr				: out STD_LOGIC_VECTOR( 9 downto 0); -- 32*28=896
	s_mram_dout				: in  STD_LOGIC_VECTOR(11 downto 0)	:= (others => '0'); -- 8+2+1+1=12 
	-- Tiles BRAM Interfaces
	s_tram_addr				: out STD_LOGIC_VECTOR(13 downto 0); -- 256*8*8=16384
	s_tram_dout				: in  STD_LOGIC_VECTOR( 3 downto 0)	:= (others => '0');	-- 16 colors
	-- Pallete BRAM Interfaces
	s_pram_addr				: out STD_LOGIC_VECTOR( 6 downto 0); -- 4*16=64
	s_pram_dout				: in  STD_LOGIC_VECTOR(14 downto 0)	:= (others => '0');
	-- Framebuffer BRAM Interface
	m_fbram_addr			: out STD_LOGIC_VECTOR(15 downto 0);
	m_fbram_din				: out STD_LOGIC_VECTOR(14 downto 0);
	m_fbram_we				: out STD_LOGIC_VECTOR( 0 downto 0)
);
end component;

component bg_draw_p is
port (
	clk_in					: in  STD_LOGIC;	-- System clock
	update_in				: in  STD_LOGIC;	
	-- Map BRAM Interface
	s_mram_addr				: out STD_LOGIC_VECTOR( 9 downto 0); -- 32*28=896
	s_mram_dout				: in  STD_LOGIC_VECTOR(11 downto 0)	:= (others => '0'); -- 8+2+1+1=12 
	-- Tiles BRAM Interfaces
	s_tram_addr				: out STD_LOGIC_VECTOR(13 downto 0); -- 256*8*8=16384
	s_tram_dout				: in  STD_LOGIC_VECTOR( 3 downto 0)	:= (others => '0');	-- 16 colors
	-- -- Pallete BRAM Interfaces
	-- s_pram_addr				: out STD_LOGIC_VECTOR( 6 downto 0); -- 4*16=64
	-- s_pram_dout				: in  STD_LOGIC_VECTOR(14 downto 0)	:= (others => '0');
	-- Framebuffer BRAM Interface
	m_fbram_addr			: out STD_LOGIC_VECTOR(15 downto 0);
	m_fbram_din				: out STD_LOGIC_VECTOR( 6 downto 0);
	m_fbram_we				: out STD_LOGIC_VECTOR( 0 downto 0)
);
end component;

component video_tg is
generic (
	C_VIDEO_ID_CODE			: integer	:= 4;	-- 720p
	C_WIDTH					: integer	:= 11;
	C_CNT_SHIFT				: integer	:= 2;
	C_SCALE					: integer	:= 1
);
port (
	clk_in					: in  STD_LOGIC;	-- Pixel clock
	xs_pos_out				: out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
	ys_pos_out				: out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
	x_pos_out				: out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
	y_pos_out				: out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
	hs_out					: out STD_LOGIC;	-- Horisontal sync pulse
	vs_out					: out STD_LOGIC;	-- Vertical sync pulse
	av_out					: out STD_LOGIC		-- Active video
);
end component;
--------------------------------------------------------------------------------
constant MAX_PAUSE			: integer	:= 20000000;
constant DLL_PAUSE			: integer	:= 1000;
constant POOLING_PAUSE		: integer	:= 20;
--------------------------------------------------------------------------------
constant C_ADDR_WIDTH		: integer	:= 10;
constant C_DEST_WIDTH		: integer	:= 4;
constant C_COUNT_WIDTH		: integer	:= 16;
--------------------------------------------------------------------------------
constant DEST_SM			: integer	:= 0;
constant DEST_VDEC			: integer	:= 1;
constant DEST_TDEC			: integer	:= 2;
constant DEST_MDEC			: integer	:= 3;
constant TRANSFER_DEST_SM	: STD_LOGIC_VECTOR(C_DEST_WIDTH-1 downto 0)	:= (DEST_SM => '1', others => '0');
constant TRANSFER_DEST_VDEC	: STD_LOGIC_VECTOR(C_DEST_WIDTH-1 downto 0)	:= (DEST_VDEC => '1', others => '0');
constant TRANSFER_DEST_TDEC	: STD_LOGIC_VECTOR(C_DEST_WIDTH-1 downto 0)	:= (DEST_TDEC => '1', others => '0');
constant TRANSFER_DEST_MDEC	: STD_LOGIC_VECTOR(C_DEST_WIDTH-1 downto 0)	:= (DEST_MDEC => '1', others => '0');
--------------------------------------------------------------------------------
constant RNW_READ			: STD_LOGIC	:= '1';
constant RNW_WRITE			: STD_LOGIC	:= '0';
--------------------------------------------------------------------------------
constant COLOR_WIDTH		: integer	:= C_BRAM_DATA_WIDTH/3;
--------------------------------------------------------------------------------
constant REG_LCDCHW			: STD_LOGIC_VECTOR(9 downto 0)	:= b"0_01100_0000";	-- x"006000";
constant REG_LCDCHR			: STD_LOGIC_VECTOR(9 downto 0)	:= b"0_01100_0001";	-- x"006001";
constant REG_PKTRDY			: STD_LOGIC_VECTOR(9 downto 0)	:= b"0_01100_0010";	-- x"006002";
constant REG_CTL			: STD_LOGIC_VECTOR(9 downto 0)	:= b"0_01100_0011";	-- x"006003";
constant REG_PAD_0			: STD_LOGIC_VECTOR(9 downto 0)	:= b"0_01100_0100";	-- x"006004";
constant REG_PAD_1			: STD_LOGIC_VECTOR(9 downto 0)	:= b"0_01100_0101";	-- x"006005";
constant REG_PAD_2			: STD_LOGIC_VECTOR(9 downto 0)	:= b"0_01100_0110";	-- x"006006";
constant REG_PAD_3			: STD_LOGIC_VECTOR(9 downto 0)	:= b"0_01100_0111";	-- x"006007";
constant REG_PKT_0			: STD_LOGIC_VECTOR(9 downto 0)	:= b"0_01110_0000";	-- x"007000";
constant REG_CHDAT			: STD_LOGIC_VECTOR(9 downto 0)	:= b"0_01111_0000";	-- x"007800";
--------------------------------------------------------------------------------
constant PAL01		 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"00";	-- SGB Command 00h - PAL01
constant PAL23		 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"01";	-- SGB Command 01h - PAL23
constant PAL03		 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"02";	-- SGB Command 02h - PAL03
constant PAL12		 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"03";	-- SGB Command 03h - PAL12
constant ATTR_BLK	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"04";	-- SGB Command 04h - ATTR_BLK
constant ATTR_LIN	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"05";	-- SGB Command 05h - ATTR_LIN
constant ATTR_DIV	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"06";	-- SGB Command 06h - ATTR_DIV
constant ATTR_CHR	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"07";	-- SGB Command 07h - ATTR_CHR
constant SOUND		 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"08";	-- SGB Command 08h - SOUND
constant SOU_TRN	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"09";	-- SGB Command 09h - SOU_TRN
constant PAL_SET	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"0A";	-- SGB Command 0Ah - PAL_SET
constant PAL_TRN	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"0B";	-- SGB Command 0Bh - PAL_TRN
constant ATRC_EN	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"0C";	-- SGB Command 0Ch - ATRC_EN
constant TEST_EN	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"0D";	-- SGB Command 0Dh - TEST_EN
constant ICON_EN	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"0E";	-- SGB Command 0Eh - ICON_EN
constant DATA_SND	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"0F";	-- SGB Command 0Fh DATA_SND SUPER NES WRAM Transfer 1
constant DATA_TRN	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"10";	-- SGB Command 10h DATA_TRN SUPER NES WRAM Transfer 2
constant MLT_REQ	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"11";	-- SGB Command 11h - MLT_REQ
constant JUMP		 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"12";	-- SGB Command 12h - JUMP
constant CHR_TRN	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"13";	-- SGB Command 13h (0x99) - CHR_TRN
constant PCT_TRN	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"14";	-- SGB Command 14h (0xA1) - PCT_TRN
constant ATTR_TRN	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"15";	-- SGB Command 15h - ATTR_TRN
constant ATTR_SET	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"16";	-- SGB Command 16h - ATTR_SET
constant MASK_EN	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"17";	-- SGB Command 17h - MASK_EN
constant OBJ_TRN	 		: STD_LOGIC_VECTOR(7 downto 0)	:= x"18";	-- SGB Command 18h - OBJ_TRN
--------------------------------------------------------------------------------
-- Physical Layer
signal phy_op_valid			: STD_LOGIC;
signal phy_op_ready     	: STD_LOGIC;
signal phy_op_rnw       	: STD_LOGIC;
signal phy_op_data      	: STD_LOGIC_VECTOR(7 downto 0);
signal phy_op_addr      	: STD_LOGIC_VECTOR(9 downto 0);
signal phy_res_valid    	: STD_LOGIC;
signal phy_res_data     	: STD_LOGIC_VECTOR(7 downto 0);
--------------------------------------------------------------------------------
-- Transaction Layer
signal s_trans_valid		: STD_LOGIC;
signal s_trans_ready		: STD_LOGIC;
signal s_trans_rnw			: STD_LOGIC;
signal s_trans_inc			: STD_LOGIC;
signal s_trans_addr			: STD_LOGIC_VECTOR(C_ADDR_WIDTH-1 downto 0);
signal s_trans_data			: STD_LOGIC_VECTOR( 7 downto 0);
signal trans_count			: UNSIGNED(C_COUNT_WIDTH-1 downto 0);
signal s_trans_dest			: STD_LOGIC_VECTOR(C_DEST_WIDTH-1 downto 0);
signal m_trans_dest_valid	: STD_LOGIC_VECTOR(C_DEST_WIDTH-1 downto 0);
signal m_trans_dest_ready	: STD_LOGIC_VECTOR(C_DEST_WIDTH-1 downto 0);
signal m_trans_data			: STD_LOGIC_VECTOR( 7 downto 0);
--------------------------------------------------------------------------------
-- Video Decoder
signal vdec_valid			: STD_LOGIC						:= '0';
signal vdec_ready			: STD_LOGIC						:= '0';
signal vdec_data			: STD_LOGIC_VECTOR( 1 downto 0)	:= (others => '0');
signal vdec_dest			: STD_LOGIC_VECTOR(C_BRAM_ADDR_WIDTH-1 downto 0)	:= (others => '0');
-- GS Palette decoder
signal penc_valid			: STD_LOGIC						:= '0';
--signal penc_data			: STD_LOGIC_VECTOR(14 downto 0)	:= (others => '0');
signal penc_data			: STD_LOGIC_VECTOR( 6 downto 0)	:= (others => '0');
signal penc_dest			: STD_LOGIC_VECTOR(15 downto 0)	:= (others => '0');
--------------------------------------------------------------------------------
-- Tiles decoder
signal tdec_valid_a			: STD_LOGIC							:= '0';
signal tdec_valid_b			: STD_LOGIC							:= '0';
signal tdec_data			: STD_LOGIC_VECTOR( 3 downto 0)		:= (others => '0');
signal tdec_dest			: STD_LOGIC_VECTOR(13 downto 0)		:= (others => '0');
--------------------------------------------------------------------------------
-- Map/Pallete decoder
signal map_valid			: STD_LOGIC						:= '0';
signal map_data				: STD_LOGIC_VECTOR(11 downto 0)	:= (others => '0');
signal map_dest				: STD_LOGIC_VECTOR( 9 downto 0)	:= (others => '0');
signal pal_valid			: STD_LOGIC						:= '0';
signal pal_data				: STD_LOGIC_VECTOR(14 downto 0)	:= (others => '0');
signal pal_dest				: STD_LOGIC_VECTOR( 6 downto 0)	:= (others => '0');
-- GS Pallete update
signal gspal_valid			: STD_LOGIC						:= '0';
signal gspal_data			: STD_LOGIC_VECTOR(14 downto 0)	:= (others => '0');
signal gspal_dest			: STD_LOGIC_VECTOR( 5 downto 0)	:= (others => '0');
type gspal_sm_state_t is (ST_GSPAL_IDLE, ST_GSPAL_WR);
signal gspal_sm_state		: gspal_sm_state_t				:= ST_GSPAL_IDLE;
signal gspal_dest_cnt		: UNSIGNED( 5 downto 0)			:= (others => '0');
signal gspal_palette_cnt	: integer range 0 to 3			:= 0;
signal gspal_color_cnt		: integer range 0 to 3			:= 0;
--------------------------------------------------------------------------------
-- Joypads
signal joypad_1r			: STD_LOGIC_VECTOR(	7 downto 0);
signal joypad_2r			: STD_LOGIC_VECTOR(	7 downto 0);
signal jp_to_cnt			: integer range 0 to C_JP_TO	:= 0;
--------------------------------------------------------------------------------
type sm_state_t is (
	ST_INIT, ST_CLK_EN, ST_DLL_WAIT, ST_RST_DIS, ST_RST_WAIT, 
	ST_PKT_RDY_REQ, ST_PKT_RDY_RD, ST_PKT_REQ, ST_PKT_RD, 
	ST_BUF_REQ_A, ST_DMA_BUF_CHECK_A, ST_WR_JP1_A, ST_DMA_SYNC_A, ST_DMA_RUN_A,
	ST_BUF_REQ_B, ST_DMA_BUF_CHECK_B, ST_WR_JP1_B, ST_DMA_SYNC_B, ST_DMA_RUN_B,
	ST_DMA_SYNC_C, ST_DMA_RUN_C,
	--ST_LINE_REQ, ST_LINE_RD, ST_WR_SYNC, ST_LINE_DMA, 
	--ST_WR_JP1, ST_WR_JP2,
	ST_WAIT, ST_WAIT_TRANS, ST_WAIT_RD
	);
signal sm_state				: sm_state_t := ST_INIT;
signal sm_next_state		: sm_state_t := ST_INIT;
signal wait_cnt				: integer range 0 to MAX_PAUSE	:= 0;
	
signal video_buf			: UNSIGNED(7 downto 0)			:= (others => '0');
--signal video_buf_next		: UNSIGNED(7 downto 0)			:= (others => '0');
signal curr_line			: STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');
type arr2x8b is array (1 downto 0) of STD_LOGIC_VECTOR(7 downto 0);
signal prev_line			: arr2x8b	:= (others => (others => '0'));
signal prev_line_r			: STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');
signal bufs_diff			: UNSIGNED(4 downto 0)			:= (others => '0');
signal sync_val_prev		: STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');
signal sync_val				: STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');
signal sync_val_next		: STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');
signal buf_ptr				: integer range 0 to 15			:= 0;
type pkt_data_t is array (15 downto 0) of STD_LOGIC_VECTOR(7 downto 0);
signal pkt_data				: pkt_data_t	:= (others => (others => '0'));
signal req_dest				: STD_LOGIC_VECTOR(C_DEST_WIDTH-1 downto 0);
--------------------------------------------------------------------------------
-- Global paramthers
signal gameboy_screen_mask	: STD_LOGIC_VECTOR(1 downto 0)	:= (others => '0');
signal jp_2_en				: STD_LOGIC						:= '0';
signal obj_mode_eneble		: STD_LOGIC						:= '0';
signal test_mode			: STD_LOGIC						:= '0';
--------------------------------------------------------------------------------
signal vdec_ctrl_valid		: STD_LOGIC						:= '0';
signal vdec_ctrl_data		: STD_LOGIC_VECTOR( 7 downto 0)	:= (others => '0');
signal tdec_ctrl_valid		: STD_LOGIC						:= '0';
signal tdec_ctrl_data		: STD_LOGIC_VECTOR(1 downto 0)	:= (others => '0');
signal mdec_ctrl_valid		: STD_LOGIC						:= '0';
signal map_dec_end			: STD_LOGIC						:= '0';
--------------------------------------------------------------------------------
-- Background render
signal bgd_addr				: STD_LOGIC_VECTOR(15 downto 0);
--signal bgd_data				: STD_LOGIC_VECTOR(14 downto 0);
signal bgd_data				: STD_LOGIC_VECTOR( 6 downto 0);
signal bgd_we				: STD_LOGIC_VECTOR( 0 downto 0);
signal bg_draw_tram_addr	: STD_LOGIC_VECTOR(13 downto 0);
signal bg_draw_tram_data	: STD_LOGIC_VECTOR( 3 downto 0);
--------------------------------------------------------------------------------
-- Palletes
type gs_pallete_t is array(3 downto 0) of STD_LOGIC_VECTOR(14 downto 0);
type gs_palletes_t is array(3 downto 0) of gs_pallete_t;
signal gs_pallete	: gs_palletes_t	:= (
	(b"11111_11111_11111", b"10000_10000_10000", b"01000_01000_01000", b"00000_00000_00000"),
	(b"11111_11111_11111", b"10000_10000_10000", b"01000_01000_01000", b"00000_00000_00000"),
	(b"11111_11111_11111", b"10000_10000_10000", b"01000_01000_01000", b"00000_00000_00000"),
	(b"11111_11111_11111", b"10000_10000_10000", b"01000_01000_01000", b"00000_00000_00000")
);
signal gs_palette_update	: STD_LOGIC	:= '0';
--------------------------------------------------------------------------------
signal dma_transfer_size	: integer range 0 to 8192			:= 0;
signal dma_transfer_dest	: STD_LOGIC_VECTOR(C_DEST_WIDTH-1 downto 0);
--signal dma_in_sync			: boolean							:= FALSE;

-- TG and HDMI
constant CNT_WIDTH			: integer	:= 11;

signal xs_pos				: STD_LOGIC_VECTOR(CNT_WIDTH-1 downto 0);
signal ys_pos				: STD_LOGIC_VECTOR(CNT_WIDTH-1 downto 0);
signal x_pos				: STD_LOGIC_VECTOR(CNT_WIDTH-1 downto 0);
signal y_pos				: STD_LOGIC_VECTOR(CNT_WIDTH-1 downto 0);
signal x_addr				: UNSIGNED(CNT_WIDTH-1 downto 0);
signal y_addr				: UNSIGNED(CNT_WIDTH-1 downto 0);

signal tg_vsync				: STD_LOGIC;
signal tg_hsync				: STD_LOGIC;
signal tg_av				: STD_LOGIC;

constant C_PAL_DLY			: integer	:= 2;
signal tg_vsync_sr			: STD_LOGIC_VECTOR(C_PAL_DLY-1 downto 0);
signal tg_hsync_sr			: STD_LOGIC_VECTOR(C_PAL_DLY-1 downto 0);
signal tg_av_sr				: STD_LOGIC_VECTOR(C_PAL_DLY-1 downto 0);
--------------------------------------------------------------------------------
-- Debug
signal line_diff			: UNSIGNED(7 downto 0);
signal line_trig			: STD_LOGIC;
signal int_trig				: STD_LOGIC;
signal cmd_first			: STD_LOGIC_VECTOR(7 downto 0);
signal bg_update			: STD_LOGIC;
signal bg_update_sr			: STD_LOGIC_VECTOR(1 downto 0);
-- Fake BG pallete
type bg_pallete_t is array(15 downto 0) of STD_LOGIC_VECTOR(14 downto 0);
signal bg_pallete	: bg_pallete_t	:= (
	-- 0BBB BBGG GGGR RRRR
	b"00000_00000_00000", b"00000_00000_01000", b"00000_01000_00000", b"00000_01000_01000", 
	b"01000_00000_00000", b"01000_00000_01000", b"01000_01000_00000", b"01000_01000_01000", 
	b"10000_10000_10000", b"10000_10000_11000", b"10000_11000_10000", b"10000_11000_11000", 
	b"11000_10000_10000", b"11000_10000_11000", b"11000_11000_10000", b"11000_11000_11000"
	);
--------------------------------------------------------------------------------
attribute mark_debug	: string;
attribute keep 			: string;
--------------------------------------------------------------------------------
attribute keep of ns_command				: signal is "true";
attribute mark_debug of ns_command			: signal is "true";
attribute keep of gameboy_screen_mask		: signal is "true";
attribute mark_debug of gameboy_screen_mask	: signal is "true";
attribute keep of obj_mode_eneble			: signal is "true";
attribute mark_debug of obj_mode_eneble		: signal is "true";
attribute keep of sm_state					: signal is "true";
attribute mark_debug of sm_state			: signal is "true";
	
attribute keep of line_trig					: signal is "true";
attribute mark_debug of line_trig			: signal is "true";
attribute keep of line_diff					: signal is "true";
attribute mark_debug of line_diff			: signal is "true";

attribute keep of m_trans_dest_valid		: signal is "true";
attribute mark_debug of m_trans_dest_valid	: signal is "true";
attribute keep of m_trans_dest_ready		: signal is "true";
attribute mark_debug of m_trans_dest_ready	: signal is "true";
attribute keep of m_trans_data				: signal is "true";
attribute mark_debug of m_trans_data		: signal is "true";
-- attribute keep of s_trans_valid				: signal is "true";
-- attribute mark_debug of s_trans_valid		: signal is "true";
-- attribute keep of s_trans_ready				: signal is "true";
-- attribute mark_debug of s_trans_ready		: signal is "true";
-- attribute keep of s_trans_rnw				: signal is "true";
-- attribute mark_debug of s_trans_rnw			: signal is "true";
-- attribute keep of s_trans_inc				: signal is "true";
-- attribute mark_debug of s_trans_inc			: signal is "true";
-- attribute keep of s_trans_addr				: signal is "true";
-- attribute mark_debug of s_trans_addr		: signal is "true";
-- attribute keep of s_trans_data				: signal is "true";
-- attribute mark_debug of s_trans_data		: signal is "true";
-- attribute keep of trans_count				: signal is "true";
-- attribute mark_debug of trans_count			: signal is "true";
-- attribute keep of s_trans_dest				: signal is "true";
-- attribute mark_debug of s_trans_dest		: signal is "true";
attribute keep of bufs_diff					: signal is "true";
attribute mark_debug of bufs_diff			: signal is "true";
	
attribute keep of int_trig					: signal is "true";
attribute mark_debug of int_trig			: signal is "true";

attribute keep of tdec_ctrl_valid			: signal is "true";
attribute mark_debug of tdec_ctrl_valid		: signal is "true";
attribute keep of mdec_ctrl_valid			: signal is "true";
attribute mark_debug of mdec_ctrl_valid		: signal is "true";

attribute keep of map_valid					: signal is "true";
attribute mark_debug of map_valid			: signal is "true";
attribute keep of tdec_valid_a				: signal is "true";
attribute mark_debug of tdec_valid_a		: signal is "true";
 
attribute keep of prev_line					: signal is "true";
attribute mark_debug of prev_line			: signal is "true";
attribute keep of sync_val					: signal is "true";
attribute mark_debug of sync_val			: signal is "true";


--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
-- Physical Layer
phy_inst: sgb_phy
port map(
	aclk				=> aclk,
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
	-- Transaction interface
	s_valid				=> phy_op_valid,
	s_ready				=> phy_op_ready,
	s_rnw				=> phy_op_rnw,
	s_data				=> phy_op_data,
	s_addr				=> phy_op_addr,
	m_valid				=> phy_res_valid,
	m_data				=> phy_res_data
);
--------------------------------------------------------------------------------
-- Transaction Layer
trans_inst: sgb_trans
generic map(
	C_ADDR_WIDTH		=> 10,
	C_COUNT_WIDTH		=> C_COUNT_WIDTH,
	C_DEST_WIDTH		=> C_DEST_WIDTH
)
port map(
	aclk				=> aclk,
	-- PHY Interface
	phy_op_valid		=> phy_op_valid,
	phy_op_ready		=> phy_op_ready,
	phy_op_rnw			=> phy_op_rnw,
	phy_op_data			=> phy_op_data,
	phy_op_addr			=> phy_op_addr,
	phy_res_valid		=> phy_res_valid,
	phy_res_data		=> phy_res_data,
	-- Control Interface
	s_trans_valid		=> s_trans_valid,
	s_trans_ready		=> s_trans_ready,		
	s_trans_rnw			=> s_trans_rnw,		
	s_trans_inc			=> s_trans_inc,		
	s_trans_addr		=> s_trans_addr,		
	s_trans_data		=> s_trans_data,	
	s_trans_count		=> STD_LOGIC_VECTOR(trans_count),		
	s_trans_dest		=> s_trans_dest,	
	m_trans_dest_valid	=> m_trans_dest_valid,
	m_trans_dest_ready	=> m_trans_dest_ready,
	m_trans_data		=> m_trans_data		
);
--------------------------------------------------------------------------------
-- Gamevideo decoder
video_dec_inst: video_dec
generic map(
	C_BRAM_DATA_WIDTH	=> C_BRAM_DATA_WIDTH,
	C_BRAM_ADDR_WIDTH	=> C_BRAM_ADDR_WIDTH,
	C_SNES_X_RES		=> C_SNES_X_RES,
	C_SNES_Y_RES		=> C_SNES_Y_RES,
	C_SNES_GS_X_OFFSET	=> C_SNES_GS_X_OFFSET,
	C_SNES_GS_Y_OFFSET	=> C_SNES_GS_Y_OFFSET
)
port map(
	clk_in				=> aclk,
	-- Control Interface	
	ctrl_valid			=> vdec_ctrl_valid,
	ctrl_data			=> vdec_ctrl_data,
	-- Video Interface	
	vram_valid			=> m_trans_dest_valid(DEST_VDEC),
	vram_ready			=> m_trans_dest_ready(DEST_VDEC),
	vram_data			=> m_trans_data,
	-- Output Interface
	m_valid				=> vdec_valid,
	m_data				=> vdec_data,
	m_dest				=> vdec_dest
);
-- Apply GS Palette & process gameboy_screen_mask
process(aclk)
begin
	if rising_edge(aclk) then
		-- if(gameboy_screen_mask /= "01")then	-- Not Freeze screen
			penc_valid	<= vdec_valid;
		-- end if;
		penc_dest		<= vdec_dest;
		penc_data		<= "00000" & vdec_data;	-- Color from Pallete 0
		-- case gameboy_screen_mask is
			-- when "00"	=> 	-- Cancel Mask (Display activated)
				-- penc_data		<= gs_pallete(0)(TO_INTEGER(UNSIGNED(vdec_data)));	-- Pallete 0
			-- when "10"	=>	-- Blank Screen (Black)
				-- penc_data		<= b"00000_00000_00000";
			-- when "11"	=> 	-- Blank Screen (Color 0)
				-- penc_data		<= gs_pallete(0)(0); 
			-- when others	=>
				-- null;
		-- end case;
		
		--penc_data		<= gs_pallete(TO_INTEGER(UNSIGNED(gs_pal_in)))(TO_INTEGER(UNSIGNED(vdec_data)));
	end if;
end process;
--------------------------------------------------------------------------------
-- Tiles decoder
tile_dec_inst: tile_dec 
port map(
	clk_in				=> aclk,
	-- Control Interface	
	ctrl_valid			=> tdec_ctrl_valid,
	ctrl_data			=> tdec_ctrl_data,
	-- Video Interface	
	vram_valid			=> m_trans_dest_valid(DEST_TDEC),
	vram_ready			=> m_trans_dest_ready(DEST_TDEC),
	vram_data			=> m_trans_data,
	-- Output Interface
	m_valid_a			=> tdec_valid_a,
	m_valid_b			=> tdec_valid_b,
	m_data				=> tdec_data,
	m_dest				=> tdec_dest
);

m_tram_p1_addr		<= tdec_dest;
m_tram_p1_clk		<= aclk;
m_tram_p1_din		<= tdec_data(1 downto 0);
m_tram_p1_we(0)		<= tdec_valid_a;
m_tram_p1_en		<= '1';
m_tram_p1_rst		<= '0';

m_tram_p2_addr		<= tdec_dest;
m_tram_p2_clk		<= aclk;
m_tram_p2_din		<= tdec_data(3 downto 2);
m_tram_p2_we(0)		<= tdec_valid_b;
m_tram_p2_en		<= '1';
m_tram_p2_rst		<= '0';
--------------------------------------------------------------------------------
-- Map/Pallete decoder
map_dec_inst: map_dec
port map(
	clk_in				=> aclk,
	-- Control Interface	
	ctrl_valid			=> mdec_ctrl_valid,
	end_out				=> map_dec_end,
	-- Video Interface	
	vram_valid			=> m_trans_dest_valid(DEST_MDEC),
	vram_ready			=> m_trans_dest_ready(DEST_MDEC),
	vram_data			=> m_trans_data,
	-- GS Pallete update
	gspal_valid			=> gspal_valid,
	gspal_data			=> gspal_data,
	gspal_dest			=> gspal_dest,	
	-- Tiles Map
	map_valid			=> map_valid,
	map_data			=> map_data,
	map_dest			=> map_dest,
	-- Pallete          => 
	pal_valid			=> pal_valid,	
	pal_data			=> pal_data,	
	pal_dest			=> pal_dest	
);

m_mram_addr		<= map_dest;
m_mram_clk		<= aclk;
m_mram_din		<= map_data;
m_mram_we(0)	<= map_valid;
m_mram_en		<= '1';
m_mram_rst		<= '0';

m_pram_addr		<= pal_dest;
m_pram_clk		<= aclk;
m_pram_din		<= pal_data;
m_pram_we(0)	<= pal_valid;
m_pram_en		<= '1';
m_pram_rst		<= '0';
--------------------------------------------------------------------------------
process(aclk)
begin
	if rising_edge(aclk) then
		bg_update_sr	<= bg_update_sr(0) & bg_upd_in;
		bg_update		<= not bg_update_sr(1) and bg_update_sr(0);
	end if;
end process;

-- Border update
-- bg_draw_inst: bg_draw
-- port map(
	-- clk_in			=> aclk,
	-- update_in		=> bg_update,	--map_dec_end,
	-- -- Map BRAM Interface
	-- s_mram_addr		=> s_mram_addr,
	-- s_mram_dout		=> s_mram_dout,
	-- -- Tiles BRAM Interfaces
	-- s_tram_addr		=> bg_draw_tram_addr,
	-- s_tram_dout		=> bg_draw_tram_data,
	-- -- Pallete BRAM Interfaces
	-- s_pram_addr		=> s_pram_addr,
	-- s_pram_dout		=> s_pram_dout,
	-- -- Framebuffer BRAM Interface
	-- m_fbram_addr	=> bgd_addr,
	-- m_fbram_din		=> bgd_data,
	-- m_fbram_we		=> bgd_we
-- );
bg_draw_inst: bg_draw_p
port map(
	clk_in			=> aclk,
	update_in		=> bg_update,	--map_dec_end,
	-- Map BRAM Interface
	s_mram_addr		=> s_mram_addr,
	s_mram_dout		=> s_mram_dout,
	-- Tiles BRAM Interfaces
	s_tram_addr		=> bg_draw_tram_addr,
	s_tram_dout		=> bg_draw_tram_data,
	-- -- Pallete BRAM Interfaces
	-- s_pram_addr		=> s_pram_addr,
	-- s_pram_dout		=> s_pram_dout,
	-- Framebuffer BRAM Interface
	m_fbram_addr	=> bgd_addr,
	m_fbram_din		=> bgd_data,
	m_fbram_we		=> bgd_we
);

bg_draw_tram_data	<= s_tram_p2_dout & s_tram_p1_dout;

s_tram_p1_clk		<= aclk;
s_tram_p1_en		<= '1';
s_tram_p1_rst		<= '0';
s_tram_p1_addr		<= bg_draw_tram_addr;

s_tram_p2_clk		<= aclk;
s_tram_p2_en		<= '1';
s_tram_p2_rst		<= '0';
s_tram_p2_addr		<= bg_draw_tram_addr;

s_mram_clk			<= aclk;
s_mram_en			<= '1';
s_mram_rst			<= '0';

s_pram_clk			<= aclk;
s_pram_en			<= '1';
s_pram_rst			<= '0';

--------------------------------------------------------------------------------
-- Decode buttons
process(aclk)
begin
	if rising_edge(aclk) then
		joypad_1r(0)		<= not joypad_1_in(7);	-- Right
		joypad_1r(1)		<= not joypad_1_in(6);	-- Left
		joypad_1r(2)		<= not joypad_1_in(4);	-- Up
		joypad_1r(3)		<= not joypad_1_in(5);	-- Down
		joypad_1r(4)		<= not joypad_1_in(0);	-- A 
		joypad_1r(5)		<= not joypad_1_in(1);	-- B 
		joypad_1r(6)		<= not joypad_1_in(2);	-- Select 
		joypad_1r(7)		<= not joypad_1_in(3);	-- Start 
		joypad_2r(0)		<= not joypad_2_in(7);	-- Right
		joypad_2r(1)		<= not joypad_2_in(6);	-- Left
		joypad_2r(2)		<= not joypad_2_in(4);	-- Up
		joypad_2r(3)		<= not joypad_2_in(5);	-- Down
		joypad_2r(4)		<= not joypad_2_in(0);	-- A 
		joypad_2r(5)		<= not joypad_2_in(1);	-- B 
		joypad_2r(6)		<= not joypad_2_in(2);	-- Select 
		joypad_2r(7)		<= not joypad_2_in(3);	-- Start 
	end if;
end process;

process(m_trans_data)
begin
	case m_trans_data(1 downto 0) is
		when "00" 		=> sync_val <= x"03";
		when "01" 		=> sync_val <= x"00";
		when "10" 		=> sync_val <= x"01";
		when "11" 		=> sync_val <= x"02";
		when others		=> null;
	end case;		
end process;

process(sync_val_prev)
begin
	case sync_val_prev(1 downto 0) is
		when "00" 		=> sync_val_next <= x"01";
		when "01" 		=> sync_val_next <= x"02";
		when "10" 		=> sync_val_next <= x"03";
		when "11" 		=> sync_val_next <= x"00";
		when others		=> null;
	end case;		
end process;

-- process(m_trans_data)
-- begin
	-- case m_trans_data(2 downto 0) is
		-- when "000" 		=> sync_val <= x"03";
		-- when "001" 		=> sync_val <= x"00";
		-- when "010" 		=> sync_val <= x"01";
		-- when "011" 		=> sync_val <= x"02";
		-- when "100" 		=> sync_val <= x"03";
		-- when "101" 		=> sync_val <= x"04";
		-- when "110" 		=> sync_val <= x"05";
		-- when "111" 		=> sync_val <= x"06";
		-- when others		=> null;
	-- end case;		
-- end process;

process(m_trans_data)
begin
	if(UNSIGNED(m_trans_data(7 downto 3)) = TO_UNSIGNED(0,5))then
		video_buf		<= TO_UNSIGNED(17,8);
	else
		video_buf		<= resize(UNSIGNED(m_trans_data(7 downto 3)),8) - 1;
	end if;
end process;

-- process(prev_line)
-- begin
	-- if(UNSIGNED(prev_line(7 downto 3)) = TO_UNSIGNED(17,5))then
		-- video_buf_next		<= TO_UNSIGNED(0,8);
	-- else
	--	video_buf_next		<= resize(UNSIGNED(prev_line(0)(7 downto 3)),8);
	-- end if;
-- end process;

cmd_first		<= pkt_data(1);

process(m_trans_data, prev_line)
begin
	if(UNSIGNED(m_trans_data(7 downto 3)) > UNSIGNED(prev_line(0)(7 downto 3)))then
		bufs_diff	<= UNSIGNED(m_trans_data(7 downto 3)) - UNSIGNED(prev_line(0)(7 downto 3));
	else
		bufs_diff	<= TO_UNSIGNED(17,5) - UNSIGNED(prev_line(0)(7 downto 3)) + UNSIGNED(m_trans_data(7 downto 3));
	end if;
end process;
--------------------------------------------------------------------------------
process(aclk)
begin
	if rising_edge(aclk) then
		case sm_state is
			when ST_INIT		=>	-- 0
				if((sm_switch = '1') or C_SM_EN)then
					sm_state		<= ST_CLK_EN;
				end if;
			--------------------------------------------
			when ST_CLK_EN		=>	-- 1
				s_trans_rnw			<= RNW_WRITE;
				s_trans_inc			<= '0';
				s_trans_addr		<= REG_CTL;
				s_trans_data		<= x"01";
				trans_count			<= TO_UNSIGNED(1,C_COUNT_WIDTH);
				s_trans_dest		<= (DEST_SM => '1', others => '0');
				sm_next_state		<= ST_DLL_WAIT;
				sm_state			<= ST_WAIT_TRANS;
			when ST_DLL_WAIT	=>	-- 2
				wait_cnt			<= DLL_PAUSE;
				sm_next_state		<= ST_RST_DIS;
				sm_state			<= ST_WAIT;
			when ST_RST_DIS		=>	-- 3
				s_trans_rnw			<= RNW_WRITE;
				s_trans_inc			<= '0';
				s_trans_addr		<= REG_CTL;
				s_trans_data		<= x"91";	-- 2 JP
				trans_count			<= TO_UNSIGNED(1,C_COUNT_WIDTH);
				s_trans_dest		<= (DEST_SM => '1', others => '0');
				sm_next_state		<= ST_RST_WAIT;
				sm_state			<= ST_WAIT_TRANS;
			when ST_RST_WAIT	=>	-- 4
				wait_cnt			<= DLL_PAUSE;
				--sm_next_state		<= ST_LINE_REQ;
				sm_next_state		<= ST_PKT_RDY_REQ;
				sm_state			<= ST_WAIT;
			--------------------------------------------
			-- Cycle start
			when ST_PKT_RDY_REQ		=>	-- 5
				gs_palette_update	<= '0';
				--int_trig			<= '0';
				s_trans_rnw			<= RNW_READ;
				s_trans_inc			<= '0';
				s_trans_addr		<= REG_PKTRDY;
				s_trans_data		<= x"00";
				trans_count			<= TO_UNSIGNED(1,C_COUNT_WIDTH);
				s_trans_dest		<= (DEST_SM => '1', others => '0');
				sm_next_state		<= ST_PKT_RDY_RD;
				sm_state			<= ST_WAIT_TRANS;
			when ST_PKT_RDY_RD	=>	-- 6
				if(m_trans_data = x"01")then	-- Got a new packet
					sm_state			<= ST_PKT_REQ;
				else							-- Check for video data
					dma_transfer_size	<= 320;
					dma_transfer_dest	<= (DEST_VDEC => '1', others => '0');
					sm_state			<= ST_BUF_REQ_B;
				end if;
			--------------------------------------------------------------------
			-- Command read
			when ST_PKT_REQ		=>	-- 7
				s_trans_rnw			<= RNW_READ;
				s_trans_inc			<= '1';
				s_trans_addr		<= REG_PKT_0;
				s_trans_data		<= x"00";
				trans_count			<= TO_UNSIGNED(16,C_COUNT_WIDTH);
				s_trans_dest		<= (DEST_SM => '1', others => '0');
				sm_next_state		<= ST_PKT_RD;
				sm_state			<= ST_WAIT_TRANS;
			-- Command decode
			when ST_PKT_RD		=>	-- 8
				case pkt_data(0)(7 downto 3) is
					------------------------------------------------------------
					when PAL01(4 downto 0) 		=>	-- SGB Command 00h - PAL01
						gs_palette_update	<= '1';
						sm_state			<= ST_PKT_RDY_REQ;
					when PAL23(4 downto 0) 		=>	-- SGB Command 01h - PAL23
						gs_palette_update	<= '1';
						sm_state			<= ST_PKT_RDY_REQ;
					when PAL03(4 downto 0) 		=>	-- SGB Command 02h - PAL03
						gs_palette_update	<= '1';
						sm_state			<= ST_PKT_RDY_REQ;
					when PAL12(4 downto 0) 		=>	-- SGB Command 03h - PAL12
						gs_palette_update	<= '1';
						sm_state			<= ST_PKT_RDY_REQ;

					when ATTR_BLK(4 downto 0) 	=>	-- SGB Command 04h - ATTR_BLK
						-- Colorisation
						sm_state			<= ST_PKT_RDY_REQ;
						
					when ATTR_LIN(4 downto 0) 	=>	-- SGB Command 05h - ATTR_LIN
						-- Colorisation
						sm_state			<= ST_PKT_RDY_REQ;
					when ATTR_DIV(4 downto 0) 	=>	 -- SGB Command 06h - ATTR_DIV
						-- Colorisation
						sm_state			<= ST_PKT_RDY_REQ;
					when ATTR_CHR(4 downto 0) 	=>	 -- SGB Command 07h - ATTR_CHR
						-- Colorisation
						sm_state			<= ST_PKT_RDY_REQ;
						
					when SOUND(4 downto 0) 	=>	 	-- SGB Command 08h - SOUND	 - Skip cannot be supported
						sm_state			<= ST_PKT_RDY_REQ;
					
					when SOU_TRN(4 downto 0) =>		-- SGB Command 09h - SOU_TRN	- Skip cannot be supported
						dma_transfer_size	<= 4096;
						dma_transfer_dest	<= (DEST_SM => '1', others => '0');
						sm_state			<= ST_BUF_REQ_A;
					
					when PAL_SET(4 downto 0) =>		-- SGB Command 0Ah - PAL_SET	- Skip cannot be supported
						sm_state			<= ST_PKT_RDY_REQ;
					
					when PAL_TRN(4 downto 0) =>		-- SGB Command 0Bh - PAL_TRN	- Skip
						dma_transfer_size	<= 4096;
						dma_transfer_dest	<= (DEST_SM => '1', others => '0');
						sm_state			<= ST_BUF_REQ_A;
					
					when ATRC_EN(4 downto 0) =>		-- SGB Command 0Ch - ATRC_EN
						sm_state			<= ST_PKT_RDY_REQ;
						
					when TEST_EN(4 downto 0) 	=>	-- SGB Command 0Dh - TEST_EN
						test_mode			<= pkt_data(1)(0);
						sm_state			<= ST_PKT_RDY_REQ;
					
					when ICON_EN(4 downto 0) 	=>	-- SGB Command 0Eh - ICON_EN	 - Skip cannot be supported
						sm_state			<= ST_PKT_RDY_REQ;

					when DATA_SND(4 downto 0) 	=>	-- SGB Command 0Fh DATA_SND SUPER NES WRAM Transfer 1	 - Skip cannot be supported
						sm_state			<= ST_PKT_RDY_REQ;
					
					when DATA_TRN(4 downto 0) 	=>	-- SGB Command 10h DATA_TRN SUPER NES WRAM Transfer 2	 - Skip cannot be supported
						dma_transfer_size	<= 4096;
						dma_transfer_dest	<= (DEST_SM => '1', others => '0');
						sm_state			<= ST_BUF_REQ_A;
						
					when MLT_REQ(4 downto 0) 	=>	-- SGB Command 11h - MLT_REQ - Used to request multiplayer mode
						jp_2_en				<= pkt_data(1)(1);
						sm_state			<= ST_PKT_RDY_REQ;
					when JUMP(4 downto 0) 		=>	-- SGB Command 12h - JUMP - Skip cannot be supported
						sm_state			<= ST_PKT_RDY_REQ;
					when CHR_TRN(4 downto 0)	=>	-- SGB Command 13h - CHR_TRN - Used to transfer tile data (characters) to SNES Tile memory in VRAM
						tdec_ctrl_valid		<= '1';
						tdec_ctrl_data		<= pkt_data(1)(1 downto 0);
						dma_transfer_size	<= 4096;
						dma_transfer_dest	<= (DEST_TDEC => '1', others => '0');
						--dma_in_sync			<= FALSE;
						sm_state			<= ST_BUF_REQ_A;
					when PCT_TRN(4 downto 0)	=> 	-- SGB Command 14h - PCT_TRN - Used to transfer tile map data and palette data to SNES BG Map memory in VRAM to be used for the SGB border.
						mdec_ctrl_valid		<= '1';
						dma_transfer_size	<= 4096;
						dma_transfer_dest	<= (DEST_MDEC => '1', others => '0');
						--dma_in_sync			<= FALSE;
						sm_state			<= ST_BUF_REQ_A;
						
					when ATTR_TRN(4 downto 0)	=> 	-- SGB Command 15h - ATTR_TRN	 - Skip cannot be supported
						dma_transfer_size	<= 4096;
						dma_transfer_dest	<= (DEST_SM => '1', others => '0');
						sm_state			<= ST_BUF_REQ_A;

					when ATTR_SET(4 downto 0)	=> 	-- SGB Command 16h - ATTR_SET
						if(pkt_data(1)(6) = '1')then
							gameboy_screen_mask	<= "00";	-- When above Bit 6 is set, the Game Boy screen becomes re-enabled after the transfer
						end if;
						
					when MASK_EN(4 downto 0)	=> 	-- SGB Command 17h - MASK_EN - Used to mask the Game Boy window, among others this can be used to freeze the Game Boy screen before transferring data through VRAM
						gameboy_screen_mask	<= pkt_data(0)(1 downto 0);
						sm_state			<= ST_PKT_RDY_REQ;
						
					when OBJ_TRN(4 downto 0)	=> 	-- SGB Command 18h - OBJ_TRN
						obj_mode_eneble		<= pkt_data(0)(0);
						sm_state			<= ST_PKT_RDY_REQ;
						
					when b"1_1001"				=>	-- 19h Undocumented commands
						sm_state			<= ST_PKT_RDY_REQ;
					when b"1_1110"|b"1_1111"	=>	-- The SGB firmware explicitly ignores all commands with ID >= $1E
						sm_state			<= ST_PKT_RDY_REQ;
					when others					=> 	-- Not supported 
						--int_trig			<= '1';
						ns_command			<= pkt_data(0);
						sm_state			<= ST_PKT_RDY_REQ;
				end case;
			--------------------------------------------------------------------
			-- DMA not in sync
			when ST_BUF_REQ_A		=>	-- 9
				vdec_ctrl_valid			<= '0';
				tdec_ctrl_valid			<= '0';
				mdec_ctrl_valid			<= '0';
				s_trans_rnw				<= RNW_READ;
				s_trans_inc				<= '0';
				s_trans_addr			<= REG_LCDCHW;
				s_trans_data			<= x"00";
				trans_count				<= TO_UNSIGNED(1,C_COUNT_WIDTH);
				s_trans_dest			<= (DEST_SM => '1', others => '0');
				sm_next_state			<= ST_DMA_BUF_CHECK_A;
				sm_state				<= ST_WAIT_TRANS;
			when ST_DMA_BUF_CHECK_A	=>	-- 10
				prev_line_r				<= m_trans_data;
				if(m_trans_data(7 downto 3) /= prev_line(0)(7 downto 3))then	-- Got a new buf
					prev_line(0)		<= m_trans_data;
					prev_line(1)		<= prev_line(0);
					-- if(	(m_trans_data(7 downto 3) = next_buf(prev_line(0)(7 downto 3))) or 		-- Next
						-- (m_trans_data(7 downto 3) = next_buf(prev_line(1)(7 downto 3))))then	-- Skip
						-- sm_state		<= ST_DMA_SYNC_A;
						vdec_ctrl_valid	<= '1';
						vdec_ctrl_data	<= STD_LOGIC_VECTOR(video_buf);
					-- else																		-- Not match
						-- if(jp_to_cnt = 0)then	-- Update buttons
							-- sm_state		<= ST_WR_JP1_A;
						-- else
							-- jp_to_cnt		<= jp_to_cnt - 1;
							-- sm_state		<= ST_BUF_REQ_A;
						-- end if;
					-- end if;
					
					-- vdec_ctrl_valid		<= '1';
					-- vdec_ctrl_data		<= STD_LOGIC_VECTOR(video_buf);
					if(m_trans_data(7 downto 3) /= b"0000_1")then
						sm_state		<= ST_DMA_SYNC_A;
					else
						sm_state		<= ST_DMA_SYNC_B;
					end if;
				else
					if(jp_to_cnt = 0)then	-- Update buttons
						sm_state		<= ST_WR_JP1_A;
					else
						jp_to_cnt		<= jp_to_cnt - 1;
						sm_state		<= ST_BUF_REQ_A;
						-- sm_next_state	<= ST_BUF_REQ_A;
						-- wait_cnt		<= POOLING_PAUSE;
						-- sm_state		<= ST_WAIT;
					end if;
				end if;
			when ST_WR_JP1_A		=>	-- 11
				jp_to_cnt				<= C_JP_TO;
				s_trans_rnw				<= RNW_WRITE;
				s_trans_inc				<= '0';
				s_trans_addr			<= REG_PAD_0;
				s_trans_data			<= joypad_1r;
				trans_count				<= TO_UNSIGNED(1,C_COUNT_WIDTH);
				s_trans_dest			<= (DEST_SM => '1', others => '0');
				sm_next_state			<= ST_BUF_REQ_A;
				sm_state				<= ST_WAIT_TRANS;
			when ST_DMA_SYNC_A		=>	-- 12
				vdec_ctrl_valid			<= '0';
				s_trans_rnw				<= RNW_WRITE;
				s_trans_inc				<= '0';
				s_trans_addr			<= REG_LCDCHR;
				s_trans_data			<= sync_val;
				sync_val_prev			<= sync_val;
				trans_count				<= TO_UNSIGNED(1,C_COUNT_WIDTH);
				s_trans_dest			<= (DEST_SM => '1', others => '0');
				sm_next_state			<= ST_DMA_RUN_A;
				sm_state				<= ST_WAIT_TRANS;
			when ST_DMA_RUN_A		=>	-- 13
				s_trans_rnw				<= RNW_READ;
				s_trans_inc				<= '0';
				s_trans_addr			<= REG_CHDAT;
				s_trans_data			<= x"00";
				trans_count				<= TO_UNSIGNED(320,C_COUNT_WIDTH);
				--s_trans_dest			<= (DEST_VDEC => '1', others => '0');	-- Default
				s_trans_dest			<= (DEST_SM => '1', others => '0');	-- Skip
				sm_next_state			<= ST_BUF_REQ_A;
				sm_state				<= ST_WAIT_TRANS;
			--------------------------------------------------------------------
			-- DMA in sync
			when ST_BUF_REQ_B		=>	-- 14
				s_trans_rnw				<= RNW_READ;
				s_trans_inc				<= '0';
				s_trans_addr			<= REG_LCDCHW;
				s_trans_data			<= x"00";
				trans_count				<= TO_UNSIGNED(1,C_COUNT_WIDTH);
				s_trans_dest			<= (DEST_SM => '1', others => '0');
				sm_next_state			<= ST_DMA_BUF_CHECK_B;
				sm_state				<= ST_WAIT_TRANS;
			when ST_DMA_BUF_CHECK_B	=>	-- 15
				prev_line_r				<= m_trans_data;
				if(m_trans_data(7 downto 3) /= prev_line(0)(7 downto 3))then	-- Got a new buf
					prev_line(0)		<= m_trans_data;
					prev_line(1)		<= prev_line(0);
					-- if(	(m_trans_data(7 downto 3) = next_buf(prev_line(0)(7 downto 3))) or 		-- Next
						-- (m_trans_data(7 downto 3) = next_buf(prev_line(1)(7 downto 3))))then	-- Skip
						sm_state		<= ST_DMA_SYNC_B;
						vdec_ctrl_valid	<= '1';
						vdec_ctrl_data	<= STD_LOGIC_VECTOR(video_buf);
					-- else																		-- Not match
						-- if(jp_to_cnt = 0)then	-- Update buttons
							-- sm_state		<= ST_WR_JP1_B;
						-- else
							-- jp_to_cnt		<= jp_to_cnt - 1;
							-- sm_state		<= ST_BUF_REQ_B;
						-- end if;
					-- end if;
					
					-- if(bufs_diff > TO_UNSIGNED(1,5))then	-- 2 buffers transfer
						-- sm_state		<= ST_DMA_SYNC_C;
						-- vdec_ctrl_data	<= STD_LOGIC_VECTOR(video_buf_next);
					-- else		-- One buffer transfer
						-- sm_state		<= ST_DMA_SYNC_B;
						-- vdec_ctrl_data	<= STD_LOGIC_VECTOR(video_buf);
					-- end if;
					-- vdec_ctrl_valid		<= '1';
				else
					if(jp_to_cnt = 0)then	-- Update buttons
						sm_state		<= ST_WR_JP1_B;
					else
						jp_to_cnt		<= jp_to_cnt - 1;
						sm_state		<= ST_BUF_REQ_B;
						-- sm_next_state	<= ST_BUF_REQ_B;
						-- wait_cnt		<= POOLING_PAUSE;
						-- sm_state		<= ST_WAIT;
					end if;
				end if;
			when ST_WR_JP1_B		=>	-- 15
				jp_to_cnt				<= C_JP_TO;
				s_trans_rnw				<= RNW_WRITE;
				s_trans_inc				<= '0';
				s_trans_addr			<= REG_PAD_0;
				s_trans_data			<= joypad_1r;
				trans_count				<= TO_UNSIGNED(1,C_COUNT_WIDTH);
				s_trans_dest			<= (DEST_SM => '1', others => '0');
				sm_next_state			<= ST_BUF_REQ_B;
				sm_state				<= ST_WAIT_TRANS;
			when ST_DMA_SYNC_B		=>
				vdec_ctrl_valid			<= '0';
				s_trans_rnw				<= RNW_WRITE;
				s_trans_inc				<= '0';
				s_trans_addr			<= REG_LCDCHR;
				s_trans_data			<= sync_val;
				sync_val_prev			<= sync_val;
				trans_count				<= TO_UNSIGNED(1,C_COUNT_WIDTH);
				s_trans_dest			<= (DEST_SM => '1', others => '0');
				sm_next_state			<= ST_DMA_RUN_B;
				sm_state				<= ST_WAIT_TRANS;
			when ST_DMA_RUN_B		=>
				s_trans_rnw				<= RNW_READ;
				s_trans_inc				<= '0';
				s_trans_addr			<= REG_CHDAT;
				s_trans_data			<= x"00";
				s_trans_dest			<= dma_transfer_dest;
				if(dma_transfer_size <= 320)then
					trans_count			<= TO_UNSIGNED(dma_transfer_size,C_COUNT_WIDTH);
					dma_transfer_size	<= 0;
					dma_transfer_dest	<= (DEST_SM => '1', others => '0');
					sm_next_state		<= ST_PKT_RDY_REQ;
				else
					trans_count			<= TO_UNSIGNED(320,C_COUNT_WIDTH);
					dma_transfer_size	<= dma_transfer_size - 320;
					sm_next_state		<= ST_BUF_REQ_B;
				end if;
				sm_state				<= ST_WAIT_TRANS;
			when ST_DMA_SYNC_C		=>
				vdec_ctrl_valid			<= '0';
				s_trans_rnw				<= RNW_WRITE;
				s_trans_inc				<= '0';
				s_trans_addr			<= REG_LCDCHR;
				s_trans_data			<= sync_val_next;
				trans_count				<= TO_UNSIGNED(1,C_COUNT_WIDTH);
				s_trans_dest			<= (DEST_SM => '1', others => '0');
				sm_next_state			<= ST_DMA_RUN_C;
				sm_state				<= ST_WAIT_TRANS;
			when ST_DMA_RUN_C		=>
				s_trans_rnw				<= RNW_READ;
				s_trans_inc				<= '0';
				s_trans_addr			<= REG_CHDAT;
				s_trans_data			<= x"00";
				s_trans_dest			<= dma_transfer_dest;
				if(dma_transfer_size <= 320)then
					trans_count			<= TO_UNSIGNED(dma_transfer_size,C_COUNT_WIDTH);
					dma_transfer_size	<= 0;
					dma_transfer_dest	<= (DEST_SM => '1', others => '0');
					sm_next_state		<= ST_PKT_RDY_REQ;
				else
					trans_count			<= TO_UNSIGNED(320,C_COUNT_WIDTH);
					dma_transfer_size	<= dma_transfer_size - 320;
					sm_next_state		<= ST_DMA_SYNC_B;
				end if;
				sm_state				<= ST_WAIT_TRANS;
			--------------------------------------------
			when ST_WAIT		=>		-- 17 Wait some sycles
				vdec_ctrl_valid			<= '0';
				tdec_ctrl_valid			<= '0';
				mdec_ctrl_valid			<= '0';
				if(wait_cnt = 0)then
					sm_state			<= sm_next_state;
				else
					wait_cnt			<= wait_cnt - 1;
				end if;
			when ST_WAIT_TRANS		=>		-- 18 Wait for transaction
				vdec_ctrl_valid			<= '0';
				tdec_ctrl_valid			<= '0';
				mdec_ctrl_valid			<= '0';
				if(s_trans_ready = '1')then
					if(s_trans_rnw = RNW_READ)then
						buf_ptr			<= 0;
						sm_state		<= ST_WAIT_RD;
					else
						sm_state		<= sm_next_state;
					end if;
				end if;
			when ST_WAIT_RD		=>		-- 19 Wait for read result
				if(UNSIGNED(m_trans_dest_valid and m_trans_dest_ready) /= TO_UNSIGNED(0,C_DEST_WIDTH))then	-- Catch all dest
					pkt_data(buf_ptr)	<= m_trans_data;
					buf_ptr				<= buf_ptr + 1;
					if(trans_count = TO_UNSIGNED(1,C_COUNT_WIDTH))then
						sm_state		<= sm_next_state;
					else
						trans_count		<= trans_count - 1;
					end if;
				end if;
			--------------------------------------------	
		end case;
	end if;
end process;
m_trans_dest_ready(DEST_SM)		<= '1' when (sm_state = ST_WAIT_RD) else '0';
s_trans_valid					<= '1' when (sm_state = ST_WAIT_TRANS) else '0';

process(sm_state)
begin
	case sm_state is
		when ST_DMA_BUF_CHECK_A	=> 
			if(m_trans_data /= prev_line_r)then	-- Got a new buf
				int_trig	<= '1';
			else
				int_trig	<= '0';
			end if;
			
		when ST_DMA_SYNC_A		=> int_trig	<= '1';
		
		when ST_DMA_BUF_CHECK_B	=> 
			if(m_trans_data /= prev_line_r)then	-- Got a new buf
				int_trig	<= '1';
			else
				int_trig	<= '0';
			end if;
		
		when ST_DMA_SYNC_B		=> int_trig	<= '1';
		
		when others	=> int_trig	<= '0';
	end case;
end process;

process(m_trans_data, prev_line)
begin
	if(UNSIGNED(m_trans_data) >= UNSIGNED(prev_line(0)))then
		line_diff	<= UNSIGNED(m_trans_data) - UNSIGNED(prev_line(0));
	else
		line_diff	<= TO_UNSIGNED(144,8) - UNSIGNED(prev_line(0)) + UNSIGNED(m_trans_data);
	end if;
end process;

--line_trig	<= '1' when (vdec_ctrl_valid = '1') and (line_diff ) else '0';
--------------------------------------------------------------------------------
process(aclk)
begin
	if rising_edge(aclk) then
		case gspal_sm_state is
			when ST_GSPAL_IDLE 	=>
				gspal_palette_cnt	<= 0;
				gspal_color_cnt		<= 0;
				gspal_dest_cnt		<= (others => '0');
				if(gs_palette_update = '1')then
					gspal_sm_state	<= ST_GSPAL_WR;
					case pkt_data(0)(7 downto 3) is
						when PAL01(4 downto 0) =>
							gs_pallete(0)(1)	<= pkt_data( 4)(6 downto 0) & pkt_data( 3);
							gs_pallete(0)(2)	<= pkt_data( 6)(6 downto 0) & pkt_data( 5);
							gs_pallete(0)(3)	<= pkt_data( 8)(6 downto 0) & pkt_data( 7);
							gs_pallete(1)(1)	<= pkt_data(10)(6 downto 0) & pkt_data( 9);
							gs_pallete(1)(2)	<= pkt_data(12)(6 downto 0) & pkt_data(11);
							gs_pallete(1)(3)	<= pkt_data(14)(6 downto 0) & pkt_data(13);
							-- The value transferred as color 0 will be applied for all four palettes.
							gs_pallete(0)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
							gs_pallete(1)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
							gs_pallete(2)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
							gs_pallete(3)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
						when PAL23(4 downto 0) =>
							gs_pallete(2)(1)	<= pkt_data( 4)(6 downto 0) & pkt_data( 3);
							gs_pallete(2)(2)	<= pkt_data( 6)(6 downto 0) & pkt_data( 5);
							gs_pallete(2)(3)	<= pkt_data( 8)(6 downto 0) & pkt_data( 7);
							gs_pallete(3)(1)	<= pkt_data(10)(6 downto 0) & pkt_data( 9);
							gs_pallete(3)(2)	<= pkt_data(12)(6 downto 0) & pkt_data(11);
							gs_pallete(3)(3)	<= pkt_data(14)(6 downto 0) & pkt_data(13);
							-- The value transferred as color 0 will be applied for all four palettes.
							gs_pallete(0)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
							gs_pallete(1)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
							gs_pallete(2)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
							gs_pallete(3)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
						when PAL03(4 downto 0) =>
							gs_pallete(0)(1)	<= pkt_data( 4)(6 downto 0) & pkt_data( 3);
							gs_pallete(0)(2)	<= pkt_data( 6)(6 downto 0) & pkt_data( 5);
							gs_pallete(0)(3)	<= pkt_data( 8)(6 downto 0) & pkt_data( 7);
							gs_pallete(3)(1)	<= pkt_data(10)(6 downto 0) & pkt_data( 9);
							gs_pallete(3)(2)	<= pkt_data(12)(6 downto 0) & pkt_data(11);
							gs_pallete(3)(3)	<= pkt_data(14)(6 downto 0) & pkt_data(13);
							-- The value transferred as color 0 will be applied for all four palettes.
							gs_pallete(0)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
							gs_pallete(1)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
							gs_pallete(2)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
							gs_pallete(3)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
						when PAL12(4 downto 0) =>
							gs_pallete(1)(1)	<= pkt_data( 4)(6 downto 0) & pkt_data( 3);
							gs_pallete(1)(2)	<= pkt_data( 6)(6 downto 0) & pkt_data( 5);
							gs_pallete(1)(3)	<= pkt_data( 8)(6 downto 0) & pkt_data( 7);
							gs_pallete(2)(1)	<= pkt_data(10)(6 downto 0) & pkt_data( 9);
							gs_pallete(2)(2)	<= pkt_data(12)(6 downto 0) & pkt_data(11);
							gs_pallete(2)(3)	<= pkt_data(14)(6 downto 0) & pkt_data(13);
							-- The value transferred as color 0 will be applied for all four palettes.
							gs_pallete(0)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
							gs_pallete(1)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
							gs_pallete(2)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
							gs_pallete(3)(0)	<= pkt_data( 2)(6 downto 0) & pkt_data( 1);
						when others => null;
					end case;
				end if;
			when ST_GSPAL_WR	=>
				if(gspal_color_cnt = 3)then
					gspal_color_cnt			<= 0;
					if(gspal_palette_cnt = 3)then
						gspal_palette_cnt	<= 0;
						gspal_sm_state		<= ST_GSPAL_IDLE;
					else
						gspal_palette_cnt	<= gspal_palette_cnt + 3;
					end if;
					gspal_dest_cnt			<= gspal_dest_cnt + 13;
				else
					gspal_color_cnt			<= gspal_color_cnt + 1;
					gspal_dest_cnt			<= gspal_dest_cnt + 1;
				end if;
		end case;
	end if;
end process;

gspal_valid		<= '1' when gspal_sm_state = ST_GSPAL_WR else '0';
gspal_data		<= gs_pallete(gspal_palette_cnt)(gspal_color_cnt);
gspal_dest		<= STD_LOGIC_VECTOR(gspal_dest_cnt);
--------------------------------------------------------------------------------
tg_inst: video_tg
generic map(
	C_VIDEO_ID_CODE			=> 4,	-- 720p
	C_WIDTH					=> CNT_WIDTH,
	C_CNT_SHIFT				=> 4,
	C_SCALE					=> C_SCALE_FACTOR
)
port map(
	clk_in					=> vclk,
	xs_pos_out				=> xs_pos,
	ys_pos_out				=> ys_pos,
	x_pos_out				=> x_pos_out,
	y_pos_out				=> y_pos_out,
	hs_out					=> tg_hsync,
	vs_out					=> tg_vsync,
	av_out					=> tg_av
);

process(vclk)
begin
	if rising_edge(vclk) then
		tg_vsync_sr		<= tg_vsync_sr(C_PAL_DLY-2 downto 0) & tg_vsync;
		tg_hsync_sr		<= tg_hsync_sr(C_PAL_DLY-2 downto 0) & tg_hsync;
		tg_av_sr		<= tg_av_sr(C_PAL_DLY-2 downto 0) & tg_av;
	end if;
end process;

vid_io_hsync			<= tg_hsync_sr(C_PAL_DLY-1);
vid_io_vsync			<= tg_vsync_sr(C_PAL_DLY-1);
vid_io_active_video		<= tg_av_sr(C_PAL_DLY-1);

x_addr		<= UNSIGNED(xs_pos) - TO_UNSIGNED(C_SCALE_X_OFFSET, CNT_WIDTH);
y_addr		<= UNSIGNED(ys_pos) - TO_UNSIGNED(C_SCALE_Y_OFFSET, CNT_WIDTH);

s_fbram_addr		<= STD_LOGIC_VECTOR(y_addr(7 downto 0)) & STD_LOGIC_VECTOR(x_addr(7 downto 0));

process(xs_pos, ys_pos, s_pram_dout)
begin
	if(
		(UNSIGNED(xs_pos) >= C_SCALE_X_OFFSET) and (UNSIGNED(xs_pos) < (C_SCALE_X_OFFSET + C_SNES_X_RES)) and
		(UNSIGNED(ys_pos) >= C_SCALE_Y_OFFSET) and (UNSIGNED(ys_pos) < (C_SCALE_Y_OFFSET + C_SNES_Y_RES))
		)then
		vid_io_data	<= 	-- Color decoded from pallete information
			s_pram_dout(14 downto 10) & "000" &
			s_pram_dout( 9 downto  5) & "000" &
			s_pram_dout( 4 downto  0) & "000";
			-- s_fbram_dout(COLOR_WIDTH*1-1 downto COLOR_WIDTH*0) & STD_LOGIC_VECTOR(TO_UNSIGNED(0,8-COLOR_WIDTH)) &
			-- s_fbram_dout(COLOR_WIDTH*2-1 downto COLOR_WIDTH*1) & STD_LOGIC_VECTOR(TO_UNSIGNED(0,8-COLOR_WIDTH)) & 
			-- s_fbram_dout(COLOR_WIDTH*3-1 downto COLOR_WIDTH*2) & STD_LOGIC_VECTOR(TO_UNSIGNED(0,8-COLOR_WIDTH));
	else
		vid_io_data	<= C_BG_COLOR;
	end if;
end process;
s_pram_addr			<= s_fbram_dout;
--------------------------------------------------------------------------------
-- BRAM Write Interface
m_fbram_clk			<= aclk;
m_fbram_en			<= '1';
m_fbram_rst			<= '0';

s_fbram_clk			<= vclk;
s_fbram_en			<= '1';
s_fbram_rst			<= '0';

process(
	-- map_valid, map_data, map_dest,
	-- tdec_valid_a, tdec_data, tdec_dest,
	penc_valid, penc_data, penc_dest,
	bgd_we, bgd_addr, bgd_data
	)
begin
	-- if(map_valid = '1')then
		-- m_fbram_we				<= "1";
		-- m_fbram_din				<= "0" & map_data(7 downto 0);
		-- m_fbram_addr			<= "000" & map_dest(9 downto 5) & "111" & map_dest(4 downto 0);
	-- elsif(pal_valid = '1')then
		-- m_fbram_we				<= "1";
		-- m_fbram_din				<= 
			-- pal_data(14 downto 12) &
			-- pal_data( 9 downto  7) &
			-- pal_data( 4 downto  2);
		-- m_fbram_addr			<= b"1101_1111_0" & pal_dest;
	-- elsif(tdec_valid_a = '1')then
		-- m_fbram_we				<= "1";
		-- m_fbram_din				<= 
			-- bg_pallete(TO_INTEGER(UNSIGNED(tdec_data)))(14 downto 15-3) & 
			-- bg_pallete(TO_INTEGER(UNSIGNED(tdec_data)))( 9 downto 10-3) &
			-- bg_pallete(TO_INTEGER(UNSIGNED(tdec_data)))( 4 downto  5-3);
		-- m_fbram_addr			<=
			-- "0" &					-- Upper part of the screen 
			-- tdec_dest(13 downto 10) & 	-- 8 tiles in half
			-- tdec_dest( 5 downto  3) & -- 8 pixels in column
			-- "0"	&					-- Right half of the screen
			-- tdec_dest( 9 downto  6) & -- 16 tiles in row
			-- tdec_dest( 2 downto  0);	-- 8 pixels in row
	if(bgd_we = "1")then
		m_fbram_we				<= "1";
		m_fbram_addr			<= bgd_addr;
		m_fbram_din				<= bgd_data;	-- Pallete & color
			-- bgd_data(14 downto 15-COLOR_WIDTH) &
			-- bgd_data( 9 downto 10-COLOR_WIDTH) &
			-- bgd_data( 4 downto  5-COLOR_WIDTH);
	else	-- Video data
		m_fbram_we(0)			<= penc_valid;
		m_fbram_din				<= penc_data;	-- Color from palette 0
			-- penc_data(14 downto 15-COLOR_WIDTH) &
			-- penc_data( 9 downto 10-COLOR_WIDTH) &
			-- penc_data( 4 downto  5-COLOR_WIDTH);
		m_fbram_addr			<= penc_dest;
	end if;
end process;
--------------------------------------------------------------------------------
end arch_imp;

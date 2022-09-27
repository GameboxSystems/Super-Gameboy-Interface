--------------------------------------------------------------------------------
-- Engineer: Oleksandr Kiyenko
-- o.kiyenko@gmail.com
--------------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
--------------------------------------------------------------------------------
entity video_dec is
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
end video_dec;
--------------------------------------------------------------------------------
architecture arch_imp of video_dec is
--------------------------------------------------------------------------------
function get_next(lnum : UNSIGNED) return UNSIGNED is
begin
	if(lnum = TO_UNSIGNED(17,5))then
		return TO_UNSIGNED(0,5);
	else
		return lnum + 1;
	end if;
end function;

constant C_BLOCK_SIZE		: integer	:= 8;
constant C_SNES_GS_X_RES	: integer	:= 160;

type sm_state_type is (ST_FIRST, ST_SECOND, ST_WRITE, ST_SKIP);
signal sm_state		: sm_state_type	:= ST_FIRST;

signal bram_we			: STD_LOGIC_VECTOR(0 downto 0)	:= "0";
signal buf_a			: STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');
signal buf_b			: STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');
-- signal x_ch_cnt			: UNSIGNED(4 downto 0)			:= (others => '0');
-- signal x_cnt			: UNSIGNED(2 downto 0)			:= (others => '0');
--signal y_ch_cnt			: UNSIGNED(4 downto 0)			:= (others => '0');
signal y_cnt			: UNSIGNED(2 downto 0)			:= (others => '0');
-- signal x_addr			: UNSIGNED(7 downto 0)			:= (others => '0');

signal x_ch_cnt			: UNSIGNED(4 downto 0)			:= (others => '0');
signal x_cnt			: UNSIGNED(2 downto 0)			:= (others => '0');
signal y_ch_cnt			: UNSIGNED(4 downto 0)			:= (others => '0');
--signal y_cnt			: UNSIGNED(2 downto 0)			:= (others => '0');
signal x_addr			: UNSIGNED(7 downto 0)			:= (others => '0');
signal y_addr			: UNSIGNED(7 downto 0)			:= (others => '0');


signal pixel_cnt		: UNSIGNED(C_BRAM_ADDR_WIDTH-1 downto 0):= (others => '0');
signal pixel_cnt_g		: UNSIGNED(C_BRAM_ADDR_WIDTH-1 downto 0):= (others => '0');
signal pixel_cnt_l		: UNSIGNED(C_BRAM_ADDR_WIDTH-1 downto 0):= (others => '0');

signal in_sync			: STD_LOGIC						:= '0';

signal prev_line		: UNSIGNED(4 downto 0)			:= (others => '0');
signal next_line		: UNSIGNED(4 downto 0)			:= (others => '0');
signal line_err			: STD_LOGIC						:= '0';
--------------------------------------------------------------------------------
attribute mark_debug	: string;
attribute keep 			: string;
--------------------------------------------------------------------------------
attribute keep of ctrl_valid				: signal is "true";
attribute mark_debug of ctrl_valid			: signal is "true";
attribute keep of ctrl_data					: signal is "true";
attribute mark_debug of ctrl_data			: signal is "true";
attribute keep of next_line					: signal is "true";
attribute mark_debug of next_line			: signal is "true";
attribute keep of line_err					: signal is "true";
attribute mark_debug of line_err			: signal is "true";
-- attribute keep of addra					: signal is "true";
-- attribute mark_debug of addra			: signal is "true";
-- attribute keep of dina					: signal is "true";
-- attribute mark_debug of dina			: signal is "true";
-- attribute keep of wea					: signal is "true";
-- attribute mark_debug of wea				: signal is "true";
-- attribute keep of y_cnt					: signal is "true";
-- attribute mark_debug of y_cnt			: signal is "true";

-- attribute keep of pixel_cnt					: signal is "true";
-- attribute mark_debug of pixel_cnt			: signal is "true";
-- attribute keep of pixel_cnt_g					: signal is "true";
-- attribute mark_debug of pixel_cnt_g			: signal is "true";
-- attribute keep of pixel_cnt_l					: signal is "true";
-- attribute mark_debug of pixel_cnt_l			: signal is "true";

--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
next_line	<= get_next(prev_line);

process(clk_in)
begin
	if rising_edge(clk_in) then
		case sm_state is
			when ST_FIRST		=>
				if(ctrl_valid = '1')then
					prev_line		<= UNSIGNED(ctrl_data(4 downto 0));
					if(UNSIGNED(ctrl_data(4 downto 0)) < TO_UNSIGNED(18,5))then
						y_ch_cnt	<= UNSIGNED(ctrl_data(4 downto 0)) + TO_UNSIGNED(C_SNES_GS_Y_OFFSET/8,5);
					end if;
					x_cnt			<= (others => '0');
					x_ch_cnt		<= TO_UNSIGNED(C_SNES_GS_X_OFFSET/8,5);
					y_cnt			<= (others => '0');
					if(UNSIGNED(ctrl_data(4 downto 0)) /= next_line)then
					--	sm_state	<= ST_SKIP;
						line_err	<= '1';
					else
						line_err	<= '0';
					end if;
				elsif(vram_valid = '1')then
					line_err		<= '0';
					buf_a			<= vram_data;
					sm_state		<= ST_SECOND;
				end if;
			when ST_SECOND		=>
				if(ctrl_valid = '1')then
					prev_line		<= UNSIGNED(ctrl_data(4 downto 0));
					if(UNSIGNED(ctrl_data(4 downto 0)) < TO_UNSIGNED(18,5))then
						y_ch_cnt	<= UNSIGNED(ctrl_data(4 downto 0)) + TO_UNSIGNED(C_SNES_GS_Y_OFFSET/8,5);
					end if;
					x_cnt			<= (others => '0');
					x_ch_cnt		<= TO_UNSIGNED(C_SNES_GS_X_OFFSET/8,5);
					y_cnt			<= (others => '0');
					--if(UNSIGNED(ctrl_data(4 downto 0)) = get_next(prev_line))then
						sm_state	<= ST_FIRST;
					--else
					--	sm_state	<= ST_SKIP;
					--end if;
				elsif(vram_valid = '1')then
					buf_b			<= vram_data;
					if(x_ch_cnt < TO_UNSIGNED((C_SNES_GS_X_OFFSET/8 + C_SNES_GS_X_RES/8),5))then
						sm_state	<= ST_WRITE;
					else
						sm_state	<= ST_FIRST;
					end if;
				end if;
			when ST_WRITE		=>
				if(x_cnt = TO_UNSIGNED(7,3))then
					x_cnt			<= (others => '0');
					sm_state		<= ST_FIRST;
					if(y_cnt = TO_UNSIGNED(7,3))then
						y_cnt		<= (others => '0');
						x_ch_cnt	<= x_ch_cnt + 1;
					else
						y_cnt		<= y_cnt + 1;
					end if;
				else
					x_cnt			<= x_cnt + 1;
				end if;
				-- Shift left
				buf_a				<= buf_a(6 downto 0) & "0";
				buf_b				<= buf_b(6 downto 0) & "0";
			when ST_SKIP		=>
				if(ctrl_valid = '1')then
					prev_line		<= UNSIGNED(ctrl_data(4 downto 0));
					if(UNSIGNED(ctrl_data(4 downto 0)) < TO_UNSIGNED(18,5))then
						y_ch_cnt	<= UNSIGNED(ctrl_data(4 downto 0)) + TO_UNSIGNED(C_SNES_GS_Y_OFFSET/8,5);
					end if;
					x_cnt			<= (others => '0');
					x_ch_cnt		<= TO_UNSIGNED(C_SNES_GS_X_OFFSET/8,5);
					y_cnt			<= (others => '0');
					if(UNSIGNED(ctrl_data(4 downto 0)) = get_next(prev_line))then
						sm_state	<= ST_FIRST;
					end if;
				end if;
		end case;
	end if;
end process;

vram_ready		<= '1' when (sm_state = ST_FIRST) or (sm_state = ST_SECOND) else '0';
bram_we			<= "1" when (sm_state = ST_WRITE) else "0";
x_addr			<= x_ch_cnt(4 downto 0) & x_cnt(2 downto 0);
y_addr			<= y_ch_cnt(4 downto 0) & y_cnt(2 downto 0);

process(clk_in)
begin
	if rising_edge(clk_in) then
		m_valid			<= bram_we(0);
		m_data			<=  not buf_a(7) & not buf_b(7);
		m_dest			<= STD_LOGIC_VECTOR(y_ch_cnt(4 downto 0)) & STD_LOGIC_VECTOR(y_cnt(2 downto 0)) & STD_LOGIC_VECTOR(x_addr);
	end if;
end process;
--------------------------------------------------------------------------------
end arch_imp;

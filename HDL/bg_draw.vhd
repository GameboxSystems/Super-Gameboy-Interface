--------------------------------------------------------------------------------
-- Engineer: Oleksandr Kiyenko
-- o.kiyenko@gmail.com
--------------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
--------------------------------------------------------------------------------
entity bg_draw is
port (
	clk_in				: in  STD_LOGIC;	-- System clock
	update_in			: in  STD_LOGIC;	
	-- Map BRAM Interface
	s_mram_addr			: out STD_LOGIC_VECTOR( 9 downto 0); -- 32*28=896
	s_mram_dout			: in  STD_LOGIC_VECTOR(11 downto 0)	:= (others => '0'); -- 8+2+1+1=12 
	-- Tiles BRAM Interfaces
	s_tram_addr			: out STD_LOGIC_VECTOR(13 downto 0); -- 256*8*8=16384
	s_tram_dout			: in  STD_LOGIC_VECTOR( 3 downto 0)	:= (others => '0');	-- 16 colors
	-- Pallete BRAM Interfaces
	s_pram_addr			: out STD_LOGIC_VECTOR( 6 downto 0); -- 4*16=64
	s_pram_dout			: in  STD_LOGIC_VECTOR(14 downto 0)	:= (others => '0');
	-- Framebuffer BRAM Interface
	m_fbram_addr		: out STD_LOGIC_VECTOR(15 downto 0);
	m_fbram_din			: out STD_LOGIC_VECTOR(14 downto 0);
	m_fbram_we			: out STD_LOGIC_VECTOR( 0 downto 0)
);
end bg_draw;
--------------------------------------------------------------------------------
architecture arch_imp of bg_draw is
--------------------------------------------------------------------------------
type sm_state_t is (ST_IDLE,ST_GET_MAP, ST_MAP_DEC, ST_GET_TILE, ST_GET_COLOR, ST_WRITE);
signal sm_state		: sm_state_t	:= ST_IDLE;

signal map_x_cnt		: UNSIGNED(4 downto 0)	:= (others => '0');
signal map_y_cnt		: UNSIGNED(4 downto 0)	:= (others => '0');

signal tile_p_cnt		: UNSIGNED(5 downto 0)	:= (others => '0');

signal wait_cnt			: integer range 0 to 2	:= 0;
signal tile_num			: STD_LOGIC_VECTOR( 7 downto 0)	:= (others => '0');
signal pallete_num		: STD_LOGIC_VECTOR( 1 downto 0)	:= (others => '0');
signal pallete_color	: STD_LOGIC_VECTOR( 3 downto 0)	:= (others => '0');
signal pallete_color_m	: STD_LOGIC_VECTOR( 3 downto 0)	:= (others => '0');
signal flip_mask		: STD_LOGIC_VECTOR( 1 downto 0)	:= (others => '0');

signal pix_x_cnt		: STD_LOGIC_VECTOR(2 downto 0)	:= (others => '0');
signal pix_y_cnt		: STD_LOGIC_VECTOR(2 downto 0)	:= (others => '0');


--------------------------------------------------------------------------------
attribute mark_debug	: string;
attribute keep 			: string;
--------------------------------------------------------------------------------
-- attribute keep of update_in				: signal is "true";
-- attribute mark_debug of update_in		: signal is "true";

-- attribute keep of sm_state				: signal is "true";
-- attribute mark_debug of sm_state		: signal is "true";
-- attribute mark_debug of map_x_cnt		: signal is "true";
-- attribute keep of map_x_cnt				: signal is "true";
-- attribute mark_debug of map_y_cnt		: signal is "true";
-- attribute keep of map_y_cnt				: signal is "true";
-- attribute mark_debug of tile_p_cnt		: signal is "true";
-- attribute keep of tile_p_cnt			: signal is "true";
-- attribute mark_debug of wait_cnt		: signal is "true";
-- attribute keep of wait_cnt				: signal is "true";
-- attribute mark_debug of tile_num		: signal is "true";
-- attribute keep of tile_num				: signal is "true";
-- attribute mark_debug of pallete_num		: signal is "true";
-- attribute keep of pallete_num			: signal is "true";
-- attribute mark_debug of pallete_color	: signal is "true";
-- attribute keep of pallete_color			: signal is "true";
-- attribute mark_debug of flip_mask		: signal is "true";
-- attribute keep of flip_mask				: signal is "true";
-- attribute mark_debug of pix_x_cnt		: signal is "true";
-- attribute keep of pix_x_cnt				: signal is "true";
-- attribute mark_debug of pix_y_cnt		: signal is "true";
-- attribute keep of pix_y_cnt				: signal is "true";

-- attribute mark_debug of s_mram_addr		: signal is "true";
-- attribute keep of s_mram_addr				: signal is "true";
-- attribute mark_debug of s_mram_dout		: signal is "true";
-- attribute keep of s_mram_dout				: signal is "true";
-- attribute mark_debug of s_tram_addr		: signal is "true";
-- attribute keep of s_tram_addr				: signal is "true";
-- attribute mark_debug of s_pram_addr		: signal is "true";
-- attribute keep of s_pram_addr				: signal is "true";
-- attribute mark_debug of s_pram_dout		: signal is "true";
-- attribute keep of s_pram_dout				: signal is "true";
-- attribute mark_debug of m_fbram_addr		: signal is "true";
-- attribute keep of m_fbram_addr				: signal is "true";
-- attribute mark_debug of m_fbram_din		: signal is "true";
-- attribute keep of m_fbram_din				: signal is "true";
-- attribute mark_debug of m_fbram_we			: signal is "true";
-- attribute keep of m_fbram_we				: signal is "true";
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
process(clk_in)
begin
	if rising_edge(clk_in) then
		case sm_state is
			when ST_IDLE		=>
				map_x_cnt				<= (others => '0');
				map_y_cnt				<= (others => '0');
				if(update_in = '1')then
					sm_state			<= ST_GET_MAP;
				end if;
			when ST_GET_MAP		=>
				wait_cnt				<= 2;
				sm_state				<= ST_MAP_DEC;
			when ST_MAP_DEC		=>
				if(wait_cnt = 0)then
					tile_num			<= s_mram_dout( 7 downto  0);
					pallete_num			<= s_mram_dout( 9 downto  8);
					flip_mask			<= s_mram_dout(11 downto 10);
					tile_p_cnt			<= (others => '0');
					wait_cnt			<= 2;
					sm_state			<= ST_GET_TILE;
				else	
					wait_cnt			<= wait_cnt - 1;
				end if;
			when ST_GET_TILE	=>
				if(wait_cnt = 0)then
					pallete_color		<= s_tram_dout;
					wait_cnt			<= 2;
					sm_state			<= ST_GET_COLOR;
				else
					wait_cnt			<= wait_cnt - 1;
				end if;
			when ST_GET_COLOR	=>
				if(wait_cnt = 0)then
					m_fbram_din		<= s_pram_dout;
					sm_state			<= ST_WRITE;
				else
					wait_cnt			<= wait_cnt - 1;
				end if;
			when ST_WRITE		=>
				wait_cnt				<= 2;
				if(tile_p_cnt = TO_UNSIGNED(63,6))then	-- End of tile
					tile_p_cnt			<= (others => '0');
					if(map_x_cnt = TO_UNSIGNED(31,5))then
						map_x_cnt		<= (others => '0');
						if(map_y_cnt = TO_UNSIGNED(27,5))then
							sm_state	<= ST_IDLE;
						else
							map_y_cnt	<= map_y_cnt + 1;
							sm_state	<= ST_GET_MAP;
						end if;
					else
						map_x_cnt		<= map_x_cnt + 1;
						sm_state		<= ST_GET_MAP;
					end if;
				else
					tile_p_cnt			<= tile_p_cnt + 1;
					sm_state			<= ST_GET_TILE;
				end if;
			
		end case;
	end if;
end process;

pix_x_cnt		<= STD_LOGIC_VECTOR(tile_p_cnt(2 downto 0)) when flip_mask(0) = '0' else not STD_LOGIC_VECTOR(tile_p_cnt(2 downto 0));
pix_y_cnt		<= STD_LOGIC_VECTOR(tile_p_cnt(5 downto 3)) when flip_mask(1) = '0' else not STD_LOGIC_VECTOR(tile_p_cnt(5 downto 3));

s_mram_addr		<= STD_LOGIC_VECTOR(map_y_cnt) & STD_LOGIC_VECTOR(map_x_cnt);
s_tram_addr		<= tile_num & STD_LOGIC_VECTOR(tile_p_cnt);
s_pram_addr		<= "1" & pallete_num & pallete_color(2) & pallete_color(3) & pallete_color(0) & pallete_color(1);
m_fbram_addr	<= STD_LOGIC_VECTOR(map_y_cnt) & pix_y_cnt & STD_LOGIC_VECTOR(map_x_cnt) & pix_x_cnt;
m_fbram_we		<= "1" when sm_state = ST_WRITE else "0";
--------------------------------------------------------------------------------
end arch_imp;

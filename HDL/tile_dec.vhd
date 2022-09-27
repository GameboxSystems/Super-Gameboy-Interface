--------------------------------------------------------------------------------
-- Engineer: Oleksandr Kiyenko
-- o.kiyenko@gmail.com
--------------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
--------------------------------------------------------------------------------
entity tile_dec is
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
end tile_dec;
--------------------------------------------------------------------------------
architecture arch_imp of tile_dec is
--------------------------------------------------------------------------------
type sm_state_t is (ST_RCV, ST_SEND);
signal sm_state		: sm_state_t	:= ST_RCV;
signal tile_cnt		: UNSIGNED( 6 downto 0)	:= (others => '0');
signal pixel_cnt	: UNSIGNED( 5 downto 0)	:= (others => '0');
signal pixel_plane	: STD_LOGIC				:= '0';
signal pp_cnt		: integer range 0 to 1	:= 0;
signal send_cnt		: integer range 0 to 7	:= 0;
signal byte_cnt		: UNSIGNED( 4 downto 0)	:= (others => '0');

type buf_arr_t is array(1 downto 0) of STD_LOGIC_VECTOR(7 downto 0);
signal buf_arr		: buf_arr_t		:= (others => (others => '0'));
signal high_bank	: STD_LOGIC		:= '0';
--------------------------------------------------------------------------------
attribute mark_debug	: string;
attribute keep 			: string;
--------------------------------------------------------------------------------
-- attribute keep of ctrl_valid			: signal is "true";
-- attribute mark_debug of ctrl_valid		: signal is "true";
-- attribute keep of vram_valid			: signal is "true";
-- attribute mark_debug of vram_valid		: signal is "true";
-- attribute keep of vram_data				: signal is "true";
-- attribute mark_debug of vram_data		: signal is "true";
-- attribute keep of m_valid_a				: signal is "true";
-- attribute mark_debug of m_valid_a		: signal is "true";
-- attribute keep of m_valid_b				: signal is "true";
-- attribute mark_debug of m_valid_b		: signal is "true";
-- attribute keep of m_data				: signal is "true";
-- attribute mark_debug of m_data			: signal is "true";
-- attribute keep of m_dest				: signal is "true";
-- attribute mark_debug of m_dest			: signal is "true";
-- attribute keep of sm_state				: signal is "true";
-- attribute mark_debug of sm_state		: signal is "true";
-- attribute keep of tile_cnt				: signal is "true";
-- attribute mark_debug of tile_cnt		: signal is "true";
-- attribute keep of pixel_cnt				: signal is "true";
-- attribute mark_debug of pixel_cnt		: signal is "true";
-- attribute keep of pixel_plane			: signal is "true";
-- attribute mark_debug of pixel_plane		: signal is "true";
-- attribute keep of pp_cnt				: signal is "true";
-- attribute mark_debug of pp_cnt			: signal is "true";
-- attribute keep of send_cnt				: signal is "true";
-- attribute mark_debug of send_cnt		: signal is "true";
-- attribute keep of byte_cnt				: signal is "true";
-- attribute mark_debug of byte_cnt		: signal is "true";
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
process(clk_in)
begin
	if rising_edge(clk_in) then
		if(ctrl_valid = '1')then
			high_bank					<= ctrl_data(0);
			tile_cnt					<= (others => '0');
			pixel_cnt					<= (others => '0');
			byte_cnt					<= (others => '0');
			pp_cnt						<= 0;
			sm_state					<= ST_RCV;
		else
			case sm_state is
				when ST_RCV		=>
					send_cnt				<= 0;
					if(vram_valid = '1')then
						buf_arr(pp_cnt)		<= vram_data;
						byte_cnt			<= byte_cnt + 1;
						if(pp_cnt = 1)then
							pp_cnt			<= 0;
							sm_state		<= ST_SEND;
						else
							pp_cnt			<= pp_cnt + 1;
						end if;
					end if;
					
				when ST_SEND	=>
					if(send_cnt = 7)then
						send_cnt			<= 0;
						sm_state			<= ST_RCV;
						if(pixel_cnt = TO_UNSIGNED(63,6))then
							pixel_cnt		<= (others => '0');
							if(pixel_plane = '1')then
								pixel_plane	<= '0';
								tile_cnt	<= tile_cnt + 1;
							else
								pixel_plane	<= '1';
							end if;
						else
							pixel_cnt		<= pixel_cnt + 1;
						end if;
					else
						send_cnt			<= send_cnt + 1;
						pixel_cnt			<= pixel_cnt + 1;
					end if;
					for i in 0 to 1 loop
						buf_arr(i)(7 downto 1)	<= buf_arr(i)(6 downto 0);
					end loop;
					
			end case;
		end if;
	end if;
end process;

vram_ready		<= '1' when (sm_state = ST_RCV) else '0';
m_valid_a		<= '1' when (sm_state = ST_SEND) and (pixel_plane = '0') else '0';
m_valid_b		<= '1' when (sm_state = ST_SEND) and (pixel_plane = '1') else '0';
m_data			<= buf_arr(0)(7) & buf_arr(1)(7) & buf_arr(0)(7) & buf_arr(1)(7);
m_dest			<= 
	high_bank & 					-- 13
	STD_LOGIC_VECTOR(tile_cnt) & 	-- 12:6
	STD_LOGIC_VECTOR(pixel_cnt);	-- 5:0
--------------------------------------------------------------------------------
end arch_imp;

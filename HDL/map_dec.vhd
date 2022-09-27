--------------------------------------------------------------------------------
-- Engineer: Oleksandr Kiyenko
-- o.kiyenko@gmail.com
--------------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
--------------------------------------------------------------------------------
entity map_dec is
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
end map_dec;
--------------------------------------------------------------------------------
architecture arch_imp of map_dec is
--------------------------------------------------------------------------------
type sm_state_t is (ST_IDLE, ST_RCV, ST_SEND);
signal sm_state		: sm_state_t	:= ST_IDLE;

signal transfer_cnt		: UNSIGNED(11 downto 0)			:= (others => '0');
signal bg_map_buf		: STD_LOGIC_VECTOR( 7 downto 0)	:= (others => '0');
signal map_info			: STD_LOGIC_VECTOR(15 downto 0)	:= (others => '0');
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
vram_ready				<= '1';
map_info				<= vram_data & bg_map_buf;

process(clk_in)
begin
	if rising_edge(clk_in) then
		if(ctrl_valid = '1')then
			transfer_cnt					<= (others => '0');
			map_valid						<= '0';
			pal_valid						<= '0';
		elsif(gspal_valid = '1')then
			pal_valid						<= '1';
			pal_data						<= gspal_data;
			pal_dest						<= "0" & gspal_dest;	-- Palettes 0-3
		else
			if(vram_valid = '1')then
				if(transfer_cnt = TO_UNSIGNED(4095,12))then
					transfer_cnt			<= (others => '0');
				else
					transfer_cnt			<= transfer_cnt + 1;
				end if;

				-- 000-6FF BG Map 32x28 Entries of 16bit each (1792 bytes)
				if(transfer_cnt <= TO_UNSIGNED(1791 ,12))then
					if(transfer_cnt(0) = '0')then
						map_valid			<= '0';
						bg_map_buf			<= vram_data;
					else
						map_valid			<= '1';
						map_data			<= map_info(15 downto 14) & map_info(11 downto 10) & map_info(7 downto 0);
						map_dest			<= STD_LOGIC_VECTOR(transfer_cnt(10 downto 1));
					end if;
				else
					map_valid				<= '0';
				end if;
				-- 800-87F BG Palette Data (Palettes 4-7, each 16 colors of 16bits each)
				if((transfer_cnt >= TO_UNSIGNED(2048 ,12)) and (transfer_cnt < TO_UNSIGNED(2175 ,12)))then
					if(transfer_cnt(0) = '0')then
						bg_map_buf			<= vram_data;
					else
						pal_valid			<= '1';
						pal_data			<= map_info(14 downto 0);
						pal_dest			<= "1" & STD_LOGIC_VECTOR(transfer_cnt(6 downto 1));	-- Palettes 4-7
					end if;
				else
					pal_valid				<= '0';
				end if;
				
				if(transfer_cnt = TO_UNSIGNED(2176 ,12))then
					end_out					<= '1';
				else
					end_out					<= '0';
				end if;
			else
				map_valid					<= '0';
				pal_valid					<= '0';
				end_out						<= '0';
			end if;
		end if;
	end if;
end process;
--------------------------------------------------------------------------------
end arch_imp;

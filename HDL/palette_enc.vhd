--------------------------------------------------------------------------------
-- Engineer: Oleksandr Kiyenko
-- o.kiyenko@gmail.com
--------------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------------------------------
entity palette_enc is
generic(
	C_BRAM_DATA_WIDTH		: integer	:= 9;
	C_BRAM_ADDR_WIDTH		: integer	:= 16
);
port (
	clk					: in  STD_LOGIC;
	s_valid				: in  STD_LOGIC;
	s_dest				: in  STD_LOGIC_VECTOR(C_BRAM_ADDR_WIDTH-1 downto 0);
	s_data				: in  STD_LOGIC_VECTOR( 1 downto 0);
	m_valid				: out STD_LOGIC;
	m_data				: out STD_LOGIC_VECTOR(C_BRAM_DATA_WIDTH-1 downto 0);
	m_dest				: out STD_LOGIC_VECTOR(C_BRAM_ADDR_WIDTH-1 downto 0)
);
end palette_enc;
----------------------------------------------------------------------------------------------------
architecture arch_imp of palette_enc is
----------------------------------------------------------------------------------------------------
-- constant COLOR_BITS		: integer 	:= C_BRAM_DATA_WIDTH/3;
-- component palette_rom is
-- port (
	-- clk					: in STD_LOGIC;
	-- addr_in				: in  STD_LOGIC_VECTOR( 5 downto 0);
	-- data_out			: out STD_LOGIC_VECTOR(23 downto 0)
-- );
-- end component;

-- signal palette_addr		: STD_LOGIC_VECTOR( 5 downto 0);
-- signal palette_data		: STD_LOGIC_VECTOR(23 downto 0);
----------------------------------------------------------------------------------------------------
begin
----------------------------------------------------------------------------------------------------
-- palette_addr	<= palette_in & (not s_data(C_BRAM_DATA_WIDTH-1)) & (not s_data(C_BRAM_DATA_WIDTH-2));

-- palette_inst: palette_rom
-- port map(
	-- clk 		=> clk,
	-- addr_in		=> palette_addr,
	-- data_out	=> palette_data
-- );

m_valid			<= s_valid;
m_dest			<= s_dest;
-- m_data			<= 
	-- palette_data(23 downto 24-COLOR_BITS) & 
	-- palette_data(15 downto 16-COLOR_BITS) & 
	-- palette_data(7 downto 8-COLOR_BITS);
process(s_data)
begin
	case s_data is
		when "00"	=> m_data <= b"000_000_000";
		when "01"	=> m_data <= b"010_010_010";
		when "10"	=> m_data <= b"100_100_100";
		when "11"	=> m_data <= b"111_111_111";
	end case;
end process;
----------------------------------------------------------------------------------------------------
end arch_imp;

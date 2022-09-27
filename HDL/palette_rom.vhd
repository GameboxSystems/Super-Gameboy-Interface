--------------------------------------------------------------------------------
-- Engineer: Oleksandr Kiyenko
-- o.kiyenko@gmail.com
--------------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------------------------------
entity palette_rom is
port (
	clk					: in STD_LOGIC;
	addr_in				: in  STD_LOGIC_VECTOR( 5 downto 0);
	data_out			: out STD_LOGIC_VECTOR(23 downto 0)
);
end palette_rom;
----------------------------------------------------------------------------------------------------
architecture arch_imp of palette_rom is
----------------------------------------------------------------------------------------------------
type rom_t is array (0 to 63) of STD_LOGIC_VECTOR(23 downto 0);
signal rom	: rom_t := (
x"E0FFC0",x"90AA60",x"405530",x"000000",
x"FFFFFF",x"52FF00",x"FF4200",x"000000",
x"FFFFFF",x"FFFF00",x"FF0000",x"000000",
x"FFFFFF",x"FFAD63",x"843100",x"000000",
x"000000",x"008484",x"FFDE00",x"FFFFFF",
x"FFFFFF",x"A5A5A5",x"525252",x"000000",
x"FFFFA5",x"FF9494",x"9494FF",x"000000",
x"FFE6C5",x"CE9C84",x"846B29",x"5A3108",
x"FFFFFF",x"7BFF31",x"0063C5",x"000000",
x"FFFFFF",x"8C8CDE",x"52528C",x"000000",
x"FFFFFF",x"FF8484",x"943A3A",x"000000",
x"FFFFFF",x"63A5FF",x"0000FF",x"000000",
x"FFFFFF",x"FFFF00",x"7B4A00",x"000000",
x"FFFFFF",x"7BFF31",x"008400",x"000000",
x"FFFFFF",x"63A5FF",x"0000FF",x"000000",
x"FFFFFF",x"FF8484",x"943A3A",x"000000"
);
----------------------------------------------------------------------------------------------------
begin
----------------------------------------------------------------------------------------------------
-- process(clk)
-- begin
	-- if rising_edge(clk) then
		-- data_out	<= rom(TO_INTEGER(UNSIGNED(addr_in)));
	-- end if;
-- end process;
data_out	<= rom(TO_INTEGER(UNSIGNED(addr_in)));
----------------------------------------------------------------------------------------------------
end arch_imp;

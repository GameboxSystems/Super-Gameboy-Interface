--------------------------------------------------------------------------------
-- Engineer: Oleksandr Kiyenko
--------------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
--------------------------------------------------------------------------------
entity debounce is
generic(
	C_DB_CYCLES			: integer	:= 100				
);
port (
	clk_in				: in  STD_LOGIC;
	btn_in				: in  STD_LOGIC;
	btn_out				: out STD_LOGIC
);
end debounce;
--------------------------------------------------------------------------------
architecture arch_imp of debounce is
--------------------------------------------------------------------------------
signal btn_sr			: STD_LOGIC_VECTOR(1 downto 0)		:= (others => '0');
signal cnt				: integer range 0 to C_DB_CYCLES-1	:= 0;
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
process(clk_in)
begin
	if(clk_in = '1' and clk_in'event)then
		btn_sr	<= btn_sr(0) & btn_in;
		if(btn_sr(0) /= btn_sr(1))then
			cnt		<= 0;
		elsif(cnt /= C_DB_CYCLES-1)then
			cnt		<= cnt + 1;
		else
			btn_out	<= btn_sr(1);
		end if;
	end if;
end process;
--------------------------------------------------------------------------------
end arch_imp;

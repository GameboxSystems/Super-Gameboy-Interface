--------------------------------------------------------------------------------
-- Engineer: Oleksandr Kiyenko
-- o.kiyenko@gmail.com
--------------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
Library UNISIM;
use UNISIM.vcomponents.all;
--------------------------------------------------------------------------------
entity sgb_phy is
port (
	aclk				: in  STD_LOGIC;	-- System clock
	----------------------------------------------------------------------------
	-- SGB Interface
	mclk_out			: out STD_LOGIC;
	sysclk_out			: out STD_LOGIC;
	refresh_out			: out STD_LOGIC;
	reset_out			: out STD_LOGIC;
	wrn_out				: out STD_LOGIC		:= '1';
	rdn_out				: out STD_LOGIC		:= '1';
	data_inout			: inout STD_LOGIC_VECTOR(7 downto 0);
	data_dir			: out STD_LOGIC;
	data_oe				: out STD_LOGIC		:= '1';
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
end sgb_phy;
--------------------------------------------------------------------------------
architecture arch_imp of sgb_phy is
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
constant CLK_HIGH_WIDTH			: INTEGER	:= 4;
constant CLK_LOW_WIDTH			: INTEGER	:= 4;
constant CLK_BURST_CYCLES		: INTEGER	:= 170;
constant REFRESH_BURST_CYCLES	: INTEGER	:= 5;
constant RDWR_START				: INTEGER	:= 0;
constant RDWR_WIDTH				: INTEGER	:= 4;
constant RDWR_HOLD				: INTEGER	:= 1;
constant A2B					: STD_LOGIC	:= '1';
constant B2A					: STD_LOGIC	:= '0';
--------------------------------------------------------------------------------
type sm_state_type is (ST_CLK_HIGH, ST_CLK_LOW, ST_REFRESH_HIGH, ST_REFRESH_LOW);
signal sm_state			: sm_state_type							:= ST_CLK_HIGH;
signal clk_cnt			: integer range 0 to CLK_HIGH_WIDTH-1 	:= 0;
signal burst_cnt		: integer range 0 to CLK_BURST_CYCLES-1 := 0;
signal data_I			: STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');
signal data_O			: STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');
signal data_T			: STD_LOGIC						:= '0';
signal rnw				: STD_LOGIC						:= '0';
signal active_op		: STD_LOGIC						:= '0';
--------------------------------------------------------------------------------
attribute mark_debug	: string;
attribute keep 			: string;
--------------------------------------------------------------------------------
-- attribute keep of sm_state			: signal is "true";
-- attribute mark_debug of sm_state	: signal is "true";
-- attribute keep of clk_cnt			: signal is "true";
-- attribute mark_debug of clk_cnt		: signal is "true";
-- attribute keep of data_I			: signal is "true";
-- attribute mark_debug of data_I		: signal is "true";
-- attribute keep of data_O			: signal is "true";
-- attribute mark_debug of data_O		: signal is "true";
-- attribute keep of data_T			: signal is "true";
-- attribute mark_debug of data_T		: signal is "true";
-- attribute keep of rnw				: signal is "true";
-- attribute mark_debug of rnw			: signal is "true";
-- attribute keep of active_op			: signal is "true";
-- attribute mark_debug of active_op	: signal is "true";
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------

process(aclk)
begin
	if rising_edge(aclk) then
		case sm_state is
			when ST_CLK_HIGH		=>
				if(clk_cnt = CLK_HIGH_WIDTH-1)then
					clk_cnt			<= 0;
					sm_state		<= ST_CLK_LOW;
					sysclk_out		<= '0';
				else
					clk_cnt			<= clk_cnt + 1;
				end if;
				if(clk_cnt = 0)then
					if(s_valid = '1')then
						active_op	<= '1';
						rnw			<= s_rnw;
						addr_out	<= s_addr;
						data_O		<= s_data;
						if(s_rnw = '1')then		-- Read
							data_dir	<= A2B;
							data_T		<= '1';
						else					-- Write
							data_dir	<= B2A;
							data_T		<= '0';
						end if;
						data_oe		<= '0';		-- Enable
					else
						active_op	<= '0';
						data_oe		<= '1';		-- Isolation
					end if;
				end if;
				if(clk_cnt = 1)then
					if(active_op = '1')then
						if(rnw = '1')then		-- Read
							rdn_out	<= '0';
						else					-- Write
							wrn_out	<= '0';
						end if;
					end if;
				end if;
			when ST_CLK_LOW			=>
				if(clk_cnt = CLK_LOW_WIDTH-1)then
					clk_cnt			<= 0;
					if(burst_cnt = CLK_BURST_CYCLES-1)then
						burst_cnt	<= 0;
						sm_state	<= ST_REFRESH_HIGH;
						refresh_out	<= '1';
					else
						burst_cnt	<= burst_cnt + 1;
						sm_state	<= ST_CLK_HIGH;
						sysclk_out	<= '1';
					end if;
				else
					clk_cnt			<= clk_cnt + 1;
				end if;
				if(clk_cnt = (RDWR_WIDTH + RDWR_START - CLK_HIGH_WIDTH))then
					rdn_out			<= '1';
					wrn_out			<= '1';
					--data_oe			<= '1';		-- Isolation
					--data_T			<= '0';
					if((active_op = '1') and (rnw = '1'))then
						m_data		<= data_I;
						m_valid		<= '1';
					else
						m_valid		<= '0';
					end if;
				else
					m_valid			<= '0';
				end if;
				if(clk_cnt = (RDWR_WIDTH + RDWR_START + RDWR_HOLD - CLK_HIGH_WIDTH))then
					--rdn_out			<= '1';
					--wrn_out			<= '1';
					data_oe			<= '1';		-- Isolation
					data_T			<= '1';
				end if;
			when ST_REFRESH_HIGH	=> 
				if(clk_cnt = CLK_HIGH_WIDTH-1)then
					clk_cnt			<= 0;
					sm_state		<= ST_REFRESH_LOW;
					refresh_out		<= '0';
				else
					clk_cnt			<= clk_cnt + 1;
				end if;
			when ST_REFRESH_LOW		=>
				if(clk_cnt = CLK_LOW_WIDTH-1)then
					clk_cnt			<= 0;
					if(burst_cnt = REFRESH_BURST_CYCLES-1)then
						burst_cnt	<= 0;
						sm_state	<= ST_CLK_HIGH;
						sysclk_out	<= '1';
					else
						burst_cnt	<= burst_cnt + 1;
						sm_state	<= ST_REFRESH_HIGH;
						refresh_out	<= '1';
					end if;
				else
					clk_cnt			<= clk_cnt + 1;
				end if;
		end case;
	end if;
end process;

reset_out	<= '1';
s_ready		<= '1' when ((sm_state = ST_CLK_HIGH) and (clk_cnt = 0)) else '0';

data_io_gen: for i in 0 to 7 generate
	IOBUF_inst : IOBUF
	port map (
		O	=> data_I(i), 	-- 1-bit output: Buffer output
		I	=> data_O(i), 	-- 1-bit input: Buffer input
		T	=> data_T, 		-- 1-bit input: 3-state enable input
		IO	=> data_inout(i)
	);	
end generate;

CLK_buf: ODDR
port map (
	Q   => mclk_out,	--[out]
	C   => aclk,		--[in]
	CE  => '1',			--[in]
	D1  => '1',			--[in]
	D2  => '0',			--[in]
	S   => '0',			--[in]
	R   => '0'			--[in]
);
--------------------------------------------------------------------------------
end arch_imp;

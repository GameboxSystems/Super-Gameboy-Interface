--------------------------------------------------------------------------------
-- Engineer: Oleksandr Kiyenko
-- o.kiyenko@gmail.com
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
--------------------------------------------------------------------------------
entity sgb_phy_tb is
end sgb_phy_tb;
--------------------------------------------------------------------------------
architecture tb of sgb_phy_tb is
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
signal aclk				: STD_LOGIC;
signal mclk_out         : STD_LOGIC;
signal sysclk_out       : STD_LOGIC;
signal refresh_out      : STD_LOGIC;
signal reset_out        : STD_LOGIC;
signal wrn_out          : STD_LOGIC;
signal rdn_out          : STD_LOGIC;
signal data_inout       : STD_LOGIC_VECTOR(7 downto 0);
signal data_dir         : STD_LOGIC;
signal data_oe          : STD_LOGIC;
signal addr_out         : STD_LOGIC_VECTOR(9 downto 0);

signal phy_op_valid		: STD_LOGIC;
signal phy_op_ready     : STD_LOGIC;
signal phy_op_rnw       : STD_LOGIC;
signal phy_op_data      : STD_LOGIC_VECTOR(7 downto 0);
signal phy_op_addr      : STD_LOGIC_VECTOR(9 downto 0);
signal phy_res_valid    : STD_LOGIC;
signal phy_res_data     : STD_LOGIC_VECTOR(7 downto 0);
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
phy_inst: sgb_phy
port map(
	aclk				=> aclk,
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
	s_valid				=> phy_op_valid,
	s_ready				=> phy_op_ready,
	s_rnw				=> phy_op_rnw,
	s_data				=> phy_op_data,
	s_addr				=> phy_op_addr,
	m_valid				=> phy_res_valid,
	m_data				=> phy_res_data
);


-- clock generation
clkgen : process
begin
	aclk <= '1';
	loop
		wait for 10 ns;
		aclk		<= not aclk;
	end loop;
end process;


-- Main process
main: process
begin
	phy_op_valid	<= '0';
	phy_op_rnw		<= '0';
	phy_op_data		<= (others => '0');
	phy_op_addr		<= (others => '0');
	wait for 20 us;
	phy_op_valid	<= '1';
	phy_op_rnw		<= '1';		-- Read
	phy_op_addr		<= b"00_1100_0000";
	wait for 20 us;
	phy_op_rnw		<= '0';		-- Write
	phy_op_addr		<= b"00_1000_0000";
	phy_op_data		<= x"55";
	wait;
end process;

--------------------------------------------------------------------------------
end tb;

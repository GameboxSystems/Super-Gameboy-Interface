--------------------------------------------------------------------------------
-- Engineer: Oleksandr Kiyenko
-- o.kiyenko@gmail.com
--------------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
--------------------------------------------------------------------------------
entity sgb_trans is
generic (
	C_ADDR_WIDTH			: integer	:= 10;
	C_COUNT_WIDTH			: integer	:= 16;
	C_DEST_WIDTH			: integer	:= 2
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
end sgb_trans;
--------------------------------------------------------------------------------
architecture arch_imp of sgb_trans is
--------------------------------------------------------------------------------
constant RNW_READ		: STD_LOGIC	:= '1';
constant RNW_WRITE		: STD_LOGIC	:= '0';
-------------------------------------------------------------------------------
type sm_state_type is (ST_IDLE, ST_WRITE, ST_READ, ST_READ_WAIT, ST_DST_WAIT);
signal sm_state 		: sm_state_type			:= ST_IDLE;
signal rnw				: STD_LOGIC				:= '0';

signal dest				: STD_LOGIC_VECTOR(C_DEST_WIDTH-1 downto 0);
signal inc				: STD_LOGIC								:= '0';
signal addr_cnt			: UNSIGNED(C_ADDR_WIDTH-1 downto 0)		:= (others => '0');
signal trans_cnt		: UNSIGNED(C_COUNT_WIDTH-1 downto 0)	:= (others => '0');
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
process(aclk)
begin
	if rising_edge(aclk) then
		case sm_state is
			when ST_IDLE 		=>
				m_trans_dest_valid			<= (others => '0');
				if(s_trans_valid = '1')then
					if(s_trans_rnw = RNW_WRITE)then
						sm_state			<= ST_WRITE;
					else	-- s_trans_rnw = RNW_READ
						sm_state			<= ST_READ;
					end if;
					rnw						<= s_trans_rnw;
					inc						<= s_trans_inc;
					dest					<= s_trans_dest;
					trans_cnt				<= UNSIGNED(s_trans_count);
					addr_cnt				<= UNSIGNED(s_trans_addr);
					phy_op_data				<= s_trans_data;
				end if;
			
			when ST_WRITE		=>
				if(phy_op_ready = '1')then
					sm_state				<= ST_IDLE;
				end if;
				
			when ST_READ		=>
				if(phy_op_ready = '1')then
					sm_state				<= ST_READ_WAIT;
				end if;

			when ST_READ_WAIT	=>
				if(phy_res_valid = '1')then
					m_trans_dest_valid		<= dest;
					m_trans_data			<= phy_res_data;
					sm_state				<= ST_DST_WAIT;
				end if;
			
			when ST_DST_WAIT	=>
				if((m_trans_dest_ready and dest) /= STD_LOGIC_VECTOR(TO_UNSIGNED(0,C_DEST_WIDTH)))then
					m_trans_dest_valid		<= (others => '0');
					if(trans_cnt = TO_UNSIGNED(1, C_COUNT_WIDTH))then
						sm_state			<= ST_IDLE;
					else
						if(inc = '1')then
							addr_cnt		<= addr_cnt + 1;
						end if;
						sm_state			<= ST_READ;
						trans_cnt			<= trans_cnt - 1;
					end if;
				end if;
		end case;
	end if;
end process;

phy_op_valid	<= '1' when (sm_state = ST_WRITE) or (sm_state = ST_READ) else '0';
phy_op_rnw		<= rnw;
phy_op_addr		<= STD_LOGIC_VECTOR(addr_cnt);

s_trans_ready	<= '1' when (sm_state = ST_IDLE) else '0';
--------------------------------------------------------------------------------
end arch_imp;

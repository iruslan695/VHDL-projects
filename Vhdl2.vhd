LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
--------------------------------------------------------------------------
entity i2c_master is 
	port(
		CLK			: in std_logic;
		enable		: in std_logic;
		reset       : in std_logic;
		addr			: in std_logic_vector(7 downto 0);
		rw_user		: in std_logic;
		data_wr		: in std_logic_vector(7 downto 0);
		data_rd		: out std_logic_vector(7 downto 0);
		sda			: inout std_logic;
		scl			: out std_logic;
		busy			: out std_logic);
end entity;
--------------------------------------------------------------------------
architecture logic of i2c_master is
	type state_machine is(idle,start,command,r_or_w,write_in_slv,read_from_slv,slv_ack,mstr_ack,stop);
	signal state			: state_machine;
	signal bit_cnt			: integer range 0 to 8 :=0;
	signal slv_addr		: std_logic_vector(7 downto 0):="00000000";--address of slave
	signal data_to_wr 	: std_logic_vector(7 downto 0):="00000000";--data to write in slave
	signal data_to_rd 	: std_logic_vector(7 downto 0):="00000000";--data from slave
	signal internalCLK	: std_logic:='0';
	signal rw				: std_logic;
begin
--------------------------------------------------------------------------
	process(internalCLK)
	begin
		if (reset='1') then
			state<=idle;
			scl<='0';
			sda<='1';
			bit_cnt:=0;
			data_to_rd<="00000000";
			busy<='0';
		else
			if (rising_edge(internalCLK)) then
				case state is
					when idle=>
						if (enable='1') then
							busy<='1';
							state<=start;
						else
							busy<='0';
							state<=idle;
						end if;
					when start=>
						slv_addr<=addr;
						data_to_wr<=data_wr;
						sda<='0';
						state<=command;
					when command=>
						if (bit_cnt=7) then
							bit_cnt:=0;
							state<=r_or_w;
						else
							bit_cnt:=bit_cnt+1;
							slv_addr(bit_cnt)<=addr(bit_cnt);
							sda<=slv_addr(bit_cnt);
							state<=command;
						end if;
					when r_or_w=>
						if (rw='0') then
							sda<='0';
							state<=write_in_slv;
						else
							sda<='1';
							state<=read_from_slv;
						end if;
					when write_in_slv=>
						if (bit_cnt=7) then
							bit_cnt:=0;
							state<=slv_ack;
						else
							bit_cnt:=bit_cnt+1;
							data_to_wr(bit_cnt)<=data_wr(bit_cnt);
							sda<=data_to_wr(bit_cnt);
							state<=write_in_slv;
						end if;
					when slv_ack=>
						if (enable='1') then
							if (sda='0' and slv_addr=addr and rw='0') then
								state<=write_in_slv;
							else
								slv_addr<="00000000";
								data_to_rd<="00000000";
								state<=start;
							end if;
						else
							state<=stop;
						end if;
					when read_from_slv=>
						if (bit_cnt=7) then
							bit_cnt:=0;
							state<=mstr_ack;
						else
							bit_cnt:=bit_cnt+1;
							data_to_rd(bit_cnt)<=sda;
							state<=read_from_slv;
						end if;
					when mstr_ack=>
						if (enable='1') then
							if (rw='1' and slv_addr=addr) then
								sda<='1';
								state<=start;
							else
								sda<='0';
								state<=read_from_slv;
							end if;
						else
							state<=stop;
						end if;
					when stop=>
						sda<='1';
						state<=idle;
				end if;
			end if;
	end process;
--------------------------------------------------------------------------
	SCL: process(CLK)
	variable counter: integer:=0;
	begin
		if(rising_edge(CLK)) then
			counter:=counter+1;
			if (counter=80) then
				counter:=0;
				internalCLK<='1';
			else
				internalCLK<='0';
			end if;
		end if;
	end process;
--------------------------------------------------------------------------
	rw<= NOT rw_user;
	data_rd<=data_to_rd;
--------------------------------------------------------------------------
end logic;
















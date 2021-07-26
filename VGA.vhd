library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.numeric_std.all;
--------------------------------------------------------------------------------------------------------
entity VGA is
	port(
		CLK50Mhz	: in 	std_logic;
		RESET		: in 	std_logic;
		H_SYNC	: out std_logic;
		V_SYNC	: out std_logic;
		TUMBLER	: in 	std_logic_vector(7 downto 0);
		BLANK_N	: out std_logic;
		SYNC_N	: out std_logic;
		R,G,B		: out std_logic_vector(7 downto 0)
		);
end entity;
--------------------------------------------------------------------------------------------------------
architecture VGA_arch of VGA is
--------------------------------------------------------------------------------------------------------
	signal 	CLK25Mhz	: std_logic	:='0';
	signal 	H_POS		: integer	:=0;
	signal 	V_POS		: integer	:=0;
	signal 	DRAW_EN	: std_logic	:='0';
--------------------------------------------------------------------------------------------------------
	constant H_AREA	: integer	:=639;
	constant HFP		: integer	:=16;
	constant H_SYNC_P	: integer	:=96;
	constant HBP		: integer	:=48;
		
	constant V_AREA	: integer	:=479;
	constant VFP		: integer	:=10;
	constant V_SYNC_P	: integer	:=2;
	constant VBP		: integer	:=33;
--------------------------------------------------------------------------------------------------------
	type FONT is array (0 to 15) of std_logic_vector (127 downto 0);
	constant NUMBER: FONT:=(
									x"003C4242424242424242424242423C00",x"0002020202020202020202120A060200",x"003E4040404040403E02020202027C00",
									x"003C4202020202040402020202423C00",x"00020202020202023E22222222222200",x"007C0202020202023C40404040403E00",
									x"003C42424242427C4040404040403E00",x"00020202020202020202020202027C00",x"00324242424242423C42424242423C00",
									x"003C0202020202023E42424242423C00",x"00424242424242427E42424242423C00",x"007C4242424242427C42424242427C00",
									x"003C4240404040404040404040423C00",x"00784442424242424242424242447800",x"007E4040404040407E40404040407E00",
									x"00404040404040407E40404040407E00"
									);
--------------------------------------------------------------------------------------------------------
	signal TUMBLER_NUMBER1: std_logic_vector(127 to 0);
	signal TUMBLER_NUMBER2: std_logic_vector(127 to 0);
--------------------------------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------------------------------
	BLANK_N<= NOT DRAW_EN;
	SYNC_N<='0';
--------------------------------------------------------------------------------------------------------
TUMB_TO_NUMB:
	process(CLK25Mhz,TUMBLER)
	begin
		if (rising_edge(CLK50Mhz)) then
			TUMBLER_NUMBER2<=NUMBER(to_integer(unsigned(TUMBLER(3 downto 0))));
			TUMBLER_NUMBER1<=NUMBER(to_integer(unsigned(TUMBLER(7 downto 4))));
		end if;
	end process;
--------------------------------------------------------------------------------------------------------
H_POS_COUNT:
	process(CLK25Mhz,RESET)
	begin
		if (RESET='1') then
			H_POS<=0;
		else
			if (rising_edge(CLK25Mhz)) then
				if (H_POS=(H_AREA+HFP+H_SYNC_P+HBP)) then
					H_POS<=0;
				else
					H_POS<=H_POS+1;
				end if;
			end if;
		end if;
	end process;
--------------------------------------------------------------------------------------------------------
V_POS_COUNT:
	process(CLK25Mhz,RESET,H_POS)
	begin
		if (RESET='1') then
			V_POS<=0;
		else
			if (rising_edge(CLK25Mhz)) then
				if (H_POS=(H_AREA+HFP+H_SYNC_P+HBP)) then
					if (V_POS=(V_AREA+VFP+V_SYNC_P+HBP)) then
						V_POS<=0;
					else
						V_POS<=V_POS+1;
					end if;
				end if;
			end if;
		end if;
	end process;
--------------------------------------------------------------------------------------------------------
H_SYNC_INIT:
	process(CLK25Mhz,RESET,H_POS)
	begin
		if (RESET='1') then
			H_SYNC<='0';
		else
			if (rising_edge(CLK25Mhz)) then
				if ((H_POS<=(H_AREA+HFP)) OR (H_POS>=(H_AREA+HFP+H_SYNC_P))) then
					H_SYNC<='1';
				else
					H_SYNC<='0';
				end if;
			end if;
		end if;
	end process;
--------------------------------------------------------------------------------------------------------
V_SYNC_INIT:
	process(CLK25Mhz,RESET,V_POS)
	begin
		if (RESET='1') then
			V_SYNC<='0';
		else
			if (rising_edge(CLK25Mhz)) then
				if ((V_POS<=(V_AREA+VFP)) OR (V_POS>=(V_AREA+VFP+V_SYNC_P))) then
					V_SYNC<='1';
				else
					V_SYNC<='0';
				end if;
			end if;
		end if;
	end process;	
--------------------------------------------------------------------------------------------------------
DRAW_EN_CONTROL:
	process(CLK25Mhz,RESET,V_POS,H_POS)
	begin
		if (RESET='1') then
			DRAW_EN<='0';
		else
			if (rising_edge(CLK25Mhz)) then
				if (H_POS<=H_AREA AND V_POS<=V_AREA) then
					DRAW_EN<='1';
				else
					DRAW_EN<='0';
				end if;
			end if;
		end if;
	end process;
--------------------------------------------------------------------------------------------------------
DRAWING:
	process(CLK25Mhz,RESET,DRAW_EN,H_POS,V_POS,TUMBLER)
	variable X: integer:=7;
	variable Y: integer:=0;
	begin
		if (RESET='1') then
			R<=x"00";
			G<=x"00";
			B<=x"00";
		else
			if (rising_edge(CLK25Mhz)) then
				if (DRAW_EN='1') then
					if ((H_POS>=10 and H_POS<=17) and (V_POS>=10 and V_POS<=25)) then --(V_POS>=10 and V_POS<=25))(H_POS>=10 and H_POS<=17)
							if (TUMBLER_NUMBER1(X)='1') then
								R<=x"FF";
								G<=x"FF";
								B<=x"FF";
							else
								R<=x"00";
								G<=x"00";
								B<=x"00";
							end if;
							X:=X-1;
							if (X=Y) then
								X:=X+15;
								Y:=Y+8;
							end if; 
					elsif ((H_POS>=20 and H_POS<=27) and (V_POS>=10 and V_POS<=25)) then --(V_POS>=10 and V_POS<=25))
							if (TUMBLER_NUMBER2(X)='1') then
								R<=x"FF";
								G<=x"FF";
								B<=x"FF";
							else
								R<=x"00";
								G<=x"00";
								B<=x"00";
							end if;
							X:=X-1;
							if (X=Y) then
								X:=X+15;
								Y:=Y+8;
							end if;
					else 
						X:=7;
						Y:=0;	
						R<=x"00";
						G<=x"00";
						B<=x"00";
					end if;
				else
					R<=x"00";
					G<=x"00";
					B<=x"00";
				end if;
			end if;
		end if;
	end process;
--------------------------------------------------------------------------------------------------------
init_CLK25Mhz:
	process(CLK50Mhz)
	begin
		if (rising_edge(CLK50Mhz)) then
			CLK25Mhz<= NOT CLK25Mhz;
		end if;
	end process;
--------------------------------------------------------------------------------------------------------
end VGA_arch;
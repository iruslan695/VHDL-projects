library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;
entity main is
	port(
		CLK50Hz	: 	in std_logic;
		button	: 	in std_logic;
		hex1		: 	out std_logic_vector(6 downto 0);
		hex2		: 	out std_logic_vector(6 downto 0);
		hex3		: 	out std_logic_vector(6 downto 0);
		hex4		: 	out std_logic_vector(6 downto 0)
	);
end entity;

architecture rtl of main is
-----------------------------------------------------
	component segment is
		port(
			hex		: out 	std_logic_vector(6 downto 0);
			tumbler	: in 	std_logic_vector(3 downto 0)
		);
	end component;
-----------------------------------------------------
	signal tumbler1	:	std_logic_vector(3 downto 0);
	signal tumbler2	:	std_logic_vector(3 downto 0);
	signal tumbler3	:	std_logic_vector(3 downto 0);
	signal tumbler4	:	std_logic_vector(3 downto 0);
	signal internalCLK: 	std_logic := '0';
	signal enabled		: 	std_logic :='0';
	
	signal counter_hex1	: integer:= 0;
	signal counter_hex2	: integer:= 0;
	signal counter_hex3	: integer:= 0;
	signal counter_hex4	: integer:= 0;
-----------------------------------------------------
	--shared variable counter_hex1	: integer:= 0;
	--shared variable counter_hex2	: integer:= 0;
	--shared variable counter_hex3	: integer:= 0;
	--shared variable counter_hex4	: integer:= 0;	
-----------------------------------------------------
begin
-----------------------------------------------------
	segment1: segment port map(hex1,tumbler1);
	segment2: segment port map(hex2,tumbler2);
	segment3: segment port map(hex3,tumbler3);
	segment4: segment port map(hex4,tumbler4);
-----------------------------------------------------
	process(internalCLK,enabled)
-----------------------------------------------------
	variable mseconds		: integer:=	0;
	variable counter_CLK	: integer:= 0;
-----------------------------------------------------
	begin
		if (enabled='0') then
			counter_hex4<=0;
			counter_hex3<=0;
			counter_hex2<=0;
			counter_hex1<=0;
			mseconds:=0;
			counter_CLK:=0;
		else
			if (rising_edge(internalCLK)) then
				counter_CLK:=counter_CLK+1;
				if (counter_CLK=50000) then
					mseconds:=mseconds+1;
					counter_hex4<=mseconds/1000;
					counter_hex3<=(mseconds mod 1000)/100;
					counter_hex2<=((mseconds mod 1000) mod 100)/10;
					counter_hex1<=((mseconds mod 1000) mod 100) mod 10;
					if (mseconds=10000) then
						mseconds:=0;
					end if;
					counter_CLK:=0;
				end if;
			end if;
		end if;
	end process;
-----------------------------------------------------
	process(button)
	begin
			enabled<=NOT enabled;
	end process;
-----------------------------------------------------
	with enabled select internalCLK <=
		CLK50Hz when '1', '0' when others;
-----------------------------------------------------	
	with enabled select tumbler4<=std_logic_vector(to_unsigned(counter_hex4,4)) when '1', "0000" when others;
	with enabled select tumbler3<=std_logic_vector(to_unsigned(counter_hex3,4)) when '1', "0000" when others;
	with enabled select tumbler2<=std_logic_vector(to_unsigned(counter_hex2,4)) when '1', "0000" when others;
	with enabled select tumbler1<=std_logic_vector(to_unsigned(counter_hex1,4)) when '1', "0000" when others;	
-----------------------------------------------------		
	--tumbler4 <=std_logic_vector(to_unsigned(counter_hex4,4));
	--tumbler3 <=std_logic_vector(to_unsigned(counter_hex3,4));
	--tumbler2 <=std_logic_vector(to_unsigned(counter_hex2,4));
	--tumbler1 <=std_logic_vector(to_unsigned(counter_hex1,4));
-----------------------------------------------------	
end rtl;
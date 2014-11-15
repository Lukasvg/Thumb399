-- Johnny Sim, Cody Harris, Tyler Mcgrew

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity memory is 
  port(
    address: in std_logic_vector(31 downto 0);
    instructions: inout std_logic_vector(15 downto 0) := "0000000000000000";
    reset: in std_logic;
    clock: in std_logic
  );
end memory;

architecture memory of memory is 
  -- Actual Memory
  /*
  type mem is array(0 to 1023) of std_logic_vector(15 downto 0);
	signal RamUse:mem; 
	attribute ramstyle : string;
	attribute ram_init_file  : string;
  attribute ramstyle of RamUse : signal is "M4K";
  attribute ram_init_file of RamUse : signal is "init.mif"; -- Synthesizable, not simulated
  */
  component romlpm is 
    port(		
      address		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		  clock		: IN STD_LOGIC  := '1';
		  q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		); 
  end component;
begin
  uut: romlpm port map (
    address => address(10 downto 1),
    clock => clock,
    q => instructions
  );
  /*
  process(clock) 
  begin
    -- On the positive edge of the clock output
    if(rising_edge(clock)) then
      if(reset = '1') then 
        instructions <= "UUUUUUUUUUUUUUUU"; -- Send garbage
      elsif unsigned(address) < 150 then
        instructions <= RamUse(to_integer(unsigned(address(30 downto 1))));
      else 
        null;
      end if;
    end if;
  end process; 
  */
end memory;

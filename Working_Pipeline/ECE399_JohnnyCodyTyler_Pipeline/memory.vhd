-- Johnny Sim, Cody Harris, Tyler Mcgrew

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.MemoryInit.all;
  
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
	signal RamUse:mem := InitializeMemory; /* synthesis ramstyle = "M4K" */
	attribute romstyle : string;
  attribute romstyle of RamUse : signal is "M4K";
begin
  process(clock) 
  begin
    -- On the positive edge of the clock output
    if(rising_edge(clock)) then
      if(reset = '1') then 
        instructions <= "UUUUUUUUUUUUUUUU"; -- Send garbage
      elsif unsigned(address) < 150 then
        instructions <= RamUse(to_integer(unsigned(address))) & RamUse(to_integer(unsigned(address)+1));
      else 
        null;
      end if;
    end if;
  end process; 
  
end memory;

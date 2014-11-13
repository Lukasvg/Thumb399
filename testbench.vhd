-- ARM Thumb design sample testbench
-- (C) Digipen 2014 - ECE 399

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
  -- top level entity
end testbench;

architecture tb of testbench is
  component integer_unit is
    port (clock: in std_logic;
        instruction: in unsigned(15 downto 0)
        );
  end component;
  
  type register_file_t is array(0 to 15) of unsigned(31 downto 0);

  signal clock: std_logic := '0';
  signal instruction: unsigned(15 downto 0);
begin
  
  -- unit under test
  uut: integer_unit port map(
    clock => clock, 
    instruction => instruction);
    
  clock <= not clock after 10 ns; -- 20 ns clock period
  
  process
    -- access the register file within the uut (VDHL 2008 only)
    alias reg is << signal .testbench.uut.reg: register_file_t>>;
  begin
    instruction <= "00100" & "000" & "00000000"; -- MOV R0, #0
    wait for 20 ns;
    assert reg(0) = 0 report "Zero reg 0 fail";
    
    instruction <= "0001110" & "001" & "000" & "001"; -- ADD R1, R0, #1
    wait for 20 ns;
    assert reg(1) = 1 report "Add 1 fail";
    
    instruction <= "0001110" & "101" & "001" & "010"; -- ADD R2, R1, #5
    wait for 20 ns;
    assert reg(2) = 6 report "Add 5 fail";
    
    instruction <= "0001110" & "111" & "010" & "011"; -- ADD R3, R2, #7
    wait for 20 ns;
    assert reg(3) = 13 report "Add 7 fail";
    
    instruction <= "01000110" & "1" & "0011" & "001"; -- MOV R9, R3
    wait for 20 ns;
    assert reg(9) = 13 report "Move reg fail";
    
    report "Simulation complete";
    wait;
  end process;
end tb;

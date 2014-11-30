-- Authors : Johnny Sim, Cassandra Chow, Hyunil Lee
-- Instruction Set: ADD, Logical Shift, and Logical Operators
-- Note: For All Tests put 1040 ns on the clock

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test2 is
  -- top level entity
end test2;

architecture t2 of test2 is
  
  -- Component ALU(Integer_Unit)
  component integer_unit is
    port (
        clock : in std_logic;
			  instructionTemp: in unsigned(15 downto 0);
			  address : out std_logic_vector(31 downto 0);
			  stall : out std_logic; -- The Reset Line to goto memory
			  reset : in std_logic -- External Input
        );
  end component;

  type register_file_t is array(0 to 15) of unsigned(31 downto 0);
  type imem_t is array(0 to 1000) of unsigned(15 downto 0);
  
  signal imem: imem_t := (
  0 => x"ABCD",
  others => x"0000"
  );

  signal clock: std_logic := '0';
  signal instruction: unsigned(15 downto 0) := "UUUUUUUUUUUUUUUU";
--  signal instructionConversion: std_logic_vector(15 downto 0);
  signal address : std_logic_vector(31 downto 0);
  signal stall : std_logic := '0'; -- Stall Reset
  signal reset : std_logic := '0'; -- External Reset
  
begin
  
  -- unit under test
  uut: integer_unit port map(
    clock => clock, 
    instructionTemp => instruction,
    address => address,
    stall => stall,
    reset => reset );
    
  -- memory
  process (clock)
    variable ix: integer;
  begin
    if(rising_edge(clock)) then
      ix := to_integer(unsigned(address(31 downto 1)));
      instruction <= imem(ix);
    end if;
  end process;
    
  clock <= not clock after 10 ns; -- 20 ns clock period
  
--  instruction <= unsigned(instructionConversion); -- Created to Convert UNSIGNED to STD_LOGIC_VECTOR
 process
    -- access the register file within the uut (VDHL 2008 only)
    alias reg is << signal .test2.uut.reg: register_file_t>>;
    alias statusRegisters is << signal .testbench2.uut.statusRegisters: unsigned >>;
  begin
    /*
    imem(0) <= "0010000100000100"; -- MOV R1, #4
    imem(1) <= "0001110100001001"; -- ADD R1, #4
    imem(2) <= "0110000000001001"; -- STR R1, [R1]
    imem(3) <= "1110011111111110"; -- B -4 -- skip back
    */
    
    imem(0) <= "0010000000000100"; -- MOV R0, #4
    imem(1) <= "1110000000000100"; -- B +4 -- skip 
    imem(2) <= "0010000000001010"; -- MOV R0, #10 -- this instruction skipped
    imem(3) <= "0010000100001111"; -- MOV R1, #15
    wait for 120 ns; -- Because it starts at zero meaning its gone through phase 1 and 2
    assert reg(0) = 4 report "Reg 0 fail";
    assert reg(1) = 15 report "Reg 1 fail";  
    
    report "Simulation complete";
    wait;
  end process;

end t2;

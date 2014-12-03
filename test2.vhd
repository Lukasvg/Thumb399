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
			  reset : in std_logic; -- External Input
			  flush : out std_logic
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
  signal flush : std_logic := '0'; -- Flush Pipeline
begin
  
  -- unit under test
  uut: integer_unit port map(
    clock => clock, 
    instructionTemp => instruction,
    address => address,
    stall => stall,
    reset => reset, 
    flush => flush);
    
  -- memory
  process (clock, stall)
    variable ix: integer;
  begin
    if(rising_edge(clock)) then
      if(stall = '1' and flush = '1') then -- FLUSH
        instruction <= "UUUUUUUUUUUUUUUU"; -- OR NOP
      else
        ix := to_integer(unsigned(address(31 downto 1)));
        instruction <= imem(ix);
      end if;
    end if;
  end process;
    
  clock <= not clock after 10 ns; -- 20 ns clock period
  
--  instruction <= unsigned(instructionConversion); -- Created to Convert UNSIGNED to STD_LOGIC_VECTOR
 process
    -- access the register file within the uut (VDHL 2008 only)
    alias reg is << signal .test2.uut.reg: register_file_t>>;
    alias statusRegisters is << signal .test2.uut.statusRegisters: unsigned >>;
  begin
    /*
    imem(0) <= "0010000100000100"; -- MOV R1, #4
    imem(1) <= "0001110100001001"; -- ADD R1, #4
    imem(2) <= "0110000000001001"; -- STR R1, [R1]
    imem(3) <= "1110011111111110"; -- B -4 -- skip back
    */
    
    imem(0) <= "0010000000000000"; -- MOV R0, #0 Load Address of "DigiPen" String to R0
    -- Change imem(1) to n = 6E for Valid test
    imem(1) <= "0010000101101110"; -- MOV R1, 'n' Fill Character 'n' in R1
    imem(2) <= "0010001000000010"; -- MOV R2, #2 Load Address(2) into R2
    imem(3) <= "0010010100000000"; -- MOV Counter(R5), #0
    --Start: ;/*Find Character*/
    imem(4) <= "0110100000000011"; -- LDR ExtractWord(R3), [StringData(R0)] Grab Data Location apply Offset
    imem(5) <= "0001110000011111"; -- MOV R7, ExtractWord(R3); Move the Contents of ExtractWord to R7
    --ByteReview: 
    imem(6) <= "1011001011011100"; -- UXTB ByteCheck(R4), ExtractWord(R3);
    imem(7) <= "0100001010001100"; -- CMP ByteCheck(R4), CharacterToTest(R1); Compare it with Data
    imem(8) <= "1101000000001000"; -- BEQ ExitBlock;
    imem(9) <= "0010110000000000"; -- CMP ByteCheck(R4), #0; Check Null
    imem(10)<= "1101000000001000"; -- BEQ FoundNothing; Found a null exit 
    imem(11)<= "0001110001101101"; -- ADD Counter(R5), Counter(R5), #1; Move the Counter up by 1
    imem(12)<= "0010011000001000"; -- MOV R6, #8;
    imem(13)<= "0100000111110011"; -- ROR ExtractWord(R3), R6 ; Remove the LSBytes
    imem(14)<= "0100001010111011"; -- CMP ExtractWord(R3), R7; Check with Rotated Content
    imem(15)<= "1101000111110101"; -- BNE ByteReview;
    imem(16)<= "0001110001000000"; -- ADD StringData(R0), StringData(R0), #1; // Changed Shift by 4(0001110100000000)
    imem(17)<= "1110011111110001"; -- B Start; Start over
    --ExitBlock:
    imem(18)<= "0110000000010101"; -- STR Counter(R5), [ReturnLocation(R2)];
    imem(19)<= "1110000000000010"; -- B EndStuff; Finished Right
    --FoundNothing:
    imem(20)<= "0010010100000000"; -- MOV R5, #0;
    imem(21)<= "0001111001101101"; -- SUB R5, R5, #1; Stupid way of getting -1
    imem(22)<= "0110000000010101"; -- STR R5, [ReturnLocation(R2)];
    --EndStuff
    -- Change imem(1) to @ = 40 for -1 test
    imem(23) <= "0010000000000000"; -- MOV R0, #0 Load Address of "DigiPen" String to R0
    imem(24) <= "0010000101000000"; -- MOV R1, 'n' Fill Character '40' in R1
    imem(25) <= "0010010100000000"; -- MOV Counter(R5), #0
    imem(26) <= "1110011111110101"; -- B Start; Start over
    wait for 80 ns; -- Instruction 0 and 1 pass
    assert reg(1) = 110 report "Failed to Fill R1 with 'n'"; 
    wait for 20 ns; -- Instruction 2
    assert reg(2) = 2 report "Failed to Fill R2 with 2";
    wait for 20 ns; -- Instruction 3
    assert reg(5) = 0 report "Failed to Clear the Counter";
    wait for 20 ns; -- Instruction 4 LDR NEEDS TO CHANGE AND TIMING NEEDS TO CHANGE AS WELL
    wait for 40 ns; -- Instruction 4 hold
    assert reg(3) = x"69676944" report "Failed to Grab first byte";
    wait for 20 ns; -- Instruction 5
    assert reg(7) = x"69676944" report "Failed to Move Extracted Word";
    -- Loop starts here
    wait for 20 ns; -- Instruction 6
    assert reg(4) = x"44" report "Failed to Extract First Byte"; -- Letter D
    wait for 20 ns; -- Instruction 7 CMP First 
    wait for 20 ns; -- Instruction 8 Skip Branch First Time
    wait for 20 ns; -- Instruction 9 CMP Second
    wait for 20 ns; -- Instruction 10 Skip Branch
    wait for 20 ns; -- Instruction 11 
    assert reg(5) = 1 report "Did not add counter First Character";
    wait for 20 ns; -- Instruction 12
    assert reg(6) = 8 report "Did not Rotate Move";
    wait for 20 ns; -- Instruction 13 
    assert reg(3) = x"44696769" report "Failed to Shift";
    wait for 20 ns; -- Instruction 14
    wait for 60 ns; -- Instruction 15 Branch should happen (need to change time)
    wait for 180 ns; -- Skip through Instruction 6-15 (Letter i)
    wait for 60 ns; -- Instruction 15 Branch should happen (need to change time)
    wait for 180 ns; -- Skip through Instruction 6-15 (Letter g)
    wait for 60 ns; -- Instruction 15 Branch should happen (need to change time)
    wait for 180 ns; -- Skip through Instruction 6-15 (Letter i)
    wait for 20 ns; -- Branch should NOT happen
    wait for 20 ns; -- Instruction 16
    assert reg(0) = 1 report "Address was shifted by one";
    wait for 60 ns; -- Branch to start (need to change branch time)
    wait for 80 ns; -- Instruction 4 and 5
    wait for 180 ns; -- Skip through Instruction 6-15 (Letter p)
    wait for 60 ns; -- Instruction 15 Branch should happen (need to change time)
    wait for 160 ns; -- Skip through Instruction 6-15 (Letter e)
    wait for 60 ns; -- Instruction 15 Branch should happen (need to change time)
    wait for 120 ns; -- Skip through Instruction Success (Letter n)
    wait for 60 ns; -- Instruction 8 Branch should happen (need to change time)
    wait for 40 ns; -- Instruction 18 and 19
    assert reg(5) = 6 report "Character Find Failed to Happen";
    wait for 2240 ns; -- Skip through 
    assert reg(5) = x"FFFFFFFF" report "Miss character"; -- A certain amount of time later the project is complete
    report "Simulation complete";
    wait;
  end process;

end t2;

-- Author: Lukas van Ginneken
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
    
    /*
    imem(0) <= "0010000000000100"; -- MOV R0, #4
    imem(1) <= "1110000000000000"; -- B +4 -- skip 
    imem(2) <= "0010000000001010"; -- MOV R0, #10 -- this instruction skipped
    imem(3) <= "0010000100001111"; -- MOV R1, #15
    wait for 120 ns; -- Because it starts at zero meaning its gone through phase 1 and 2
    assert reg(0) = 4 report "Reg 0 fail";
    assert reg(1) = 15 report "Reg 1 fail";
    */
    
    ------------------------------------------------------------------------
    -- Section Author: Cassadra Chow ---------------------------------------
    ------------------------------------------------------------------------
    
    -- PREPARE DATA
    imem(0) <= "0010000000000011"; -- MOV R0, #3 -- length of large number
    imem(1) <= "0010000100001010"; -- MOV R1, 0x0A -- memory address of integer* a
    imem(2) <= "0010001010110000"; -- MOV R2, 0xB0 -- memory address of integer* b
    -- 100 ns;
    imem(3) <= "0100011000001100"; -- MOV R4, R1 -- copy int* a
    imem(4) <= "0100011000010101"; -- MOV R5, R2 -- copy int* b
    -- 40 ns;
    -- a[0] = -1
    imem(5) <= "0010011100000001"; -- MOV R7, #1
    imem(6) <= "0100001001111111"; -- NEG R7, R7
    imem(7) <= "0110000000100111"; -- STR R7, [R4]
    imem(8) <= "0011010000000100"; -- ADD R4, #4
    -- 80 ns;
    -- a[1] = 3
    imem(9) <= "0010011100000011"; -- MOV R7, #3
    imem(10) <= "0110000000100111"; -- STR R7, [R4]
    imem(11) <= "0011010000000100"; -- ADD R4, #4
    -- 60 ns
    -- a[2] = 26
    imem(12) <= "0010011100011010"; -- MOV R7, #26
    imem(13) <= "0110000000100111"; -- STR R7, [R4]
    -- 40 ns
    
    -- b[0] = -5
    imem(14) <= "0010011100000101"; -- MOV R7, #5
    imem(15) <= "0100001001111111"; -- NEG R7, R7
    imem(16) <= "0110000000101111"; -- STR R7, [R5]
    imem(17) <= "0011010100000100"; -- ADD R5, #4
    -- 80 ns
    -- b[1] = 0x7FFFFFFF (max postive integer)
    imem(18) <= "0010011101111111"; -- MOV R7, 0x7F
    imem(19) <= "0010011011111111"; -- MOV R6, 0xFF
    imem(20) <= "0000001000111111"; -- LSL R7, R7, #8
    imem(21) <= "0100001100110111"; -- ORR R7, R6
    imem(22) <= "0000001000111111"; -- LSL R7, R7, #8
    imem(23) <= "0100001100110111"; -- ORR R7, R6
    imem(24) <= "0000001000111111"; -- LSL R7, R7, #8
    imem(25) <= "0100001100110111"; -- ORR R7, R6
    imem(26) <= "0110000000101111"; -- STR R7, [R5]
    imem(27) <= "0011010100000100"; -- ADD R5, #4
    -- 200 ns
    -- b[2] = -32
    imem(28) <= "0010011100000010"; -- MOV R7, #2
    imem(29) <= "0110000000101111"; -- STR R7, [R5]
    -- 40 ns
    
    
    -- int* a = { -1, 3, 26 }         ; R1 = a
    -- int* b = { 16, max_int, -32 }  ; R2 = b
    
    -- For Testing Data was properly initialized
    imem(30) <= "0100011000001100"; -- MOV R4, R1 -- copy int* a
    imem(31) <= "0100011000010101"; -- MOV R5, R2 -- copy int* b
    -- 40 ns
    
    -- a[0] == -1
    imem(32) <= "0110100000100011"; -- LDR R3, [R4] -- WARNING : LDR needs 60 ns to complete
    -- TEST : wait for 740 ns
    imem(33) <= "0011010000000100"; -- ADD R4, #4
    -- a[1] == 3
    imem(34) <= "0110100000100011"; -- LDR R3, [R4]
    -- TEST : wait for 80 ns
    imem(35) <= "0011010000000100"; -- ADD R4, #4
    -- a[2] == 26
    imem(36) <= "0110100000100011"; -- LDR R3, [R4]
    -- TEST : wait for 80 ns
    
    -- b[0] == 16
    imem(37) <= "0110100000101011"; -- LDR R3, [R5]
    -- TEST : wait for 60 ns
    imem(38) <= "0011010100000100"; -- ADD R5, #4
    -- b[1] == 0x7FFFFFFF
    imem(39) <= "0110100000101011"; -- LDR R3, [R5]
    -- TEST : wait for 80 ns
    imem(40) <= "0011010100000100"; -- ADD R5, #4
    -- b[2] == -32
    imem(41) <= "0110100000101011"; -- LDR R3, [R5]
    -- TEST : wait for 80 ns
    -- skip 42-44 imem in order to give time for testing memory initialization
    
    
    -- ADD_LARGE_NUMBERS BEGIN -- 
    imem(42) <= "0010011000000000"; -- MOV R6, #0
    imem(43) <= "0010011100000000"; -- MOV R7, #0
    -- 40 ns
    -- imem(44) blank instruction here for branch label -- LOOP
    imem(45) <= "0110100000001100";  -- LDR R4, [R1]
    imem(46) <= "0110100000010101";  -- LDR R5, [R2]
    -- 120 ns
    imem(47) <= "0100000101111110";  -- ADC R6, R7
    imem(48) <= "0100000101101100";  -- ADC R4, R5
    -- 40 ns
    imem(49) <= "0110100000001110";  -- LDR R6, [R1]
    imem(50) <= "0110100000010111";  -- LDR R7, [R2]
    -- 120 ns
    imem(51) <= "0110000000001100";  -- STR R4, [R1]
    -- 20 ns
    imem(52) <= "0011000100000100";  -- ADD R1, #4
    imem(53) <= "0011001000000100";  -- ADD R2, #4
    imem(54) <= "0001111001000000";  -- SUB R0, R0, #1
    -- 60 ns
    imem(55) <= "0010100000000000";  -- CMP R0, #0
    imem(56) <= "1101000111110011";  -- BNE #243 ; jump back to LOOP
    -- 60 ns
    -- whole loop takes 480 ns
    -- ADD_LARGE_NUMBERS END --
    
    -- 480 ns * 3 = 1440 ns
    -- last iteration doesn't branch so subtract 40 ns
    -- 1440 - 40 = 1400 ns
    -- prepare to test algorithm results
    imem(57) <= "0010010000001010"; -- MOV R4, 0x0A -- copy int* a
    -- a[0] = -1 + -5 == -6 (set carry)
    imem(58) <= "0110100000100011"; -- LDR R3, [R4]
    imem(59) <= "0011010000000100"; -- ADD R4, #4
    -- a[1] = 3 + max_int + carry == -2147483645 (reset carry)
    imem(60) <= "0110100000100011"; -- LDR R3, [R4]
    imem(61) <= "0011010000000100"; -- ADD R4, #4
    -- a[2] = 26 + 2 == 28 (reset carry)
    imem(62) <= "0110100000100011"; -- LDR R3, [R4]
    
    -- TEST DATA INITIALIZATION
    wait for 740 ns;
    assert reg(3) = "11111111111111111111111111111111" Report "Failed to initialize a[0]";
    wait for 80 ns;
    assert reg(3) = 3 Report "Failed to initialize a[1]";
    wait for 80 ns;
    assert reg(3) = 26 Report "Failed to initialize a[2]";
    wait for 60 ns;
    assert reg(3) = "11111111111111111111111111111011" Report "Failed to initialize b[0]";
    wait for 80 ns;
    assert reg(3) = "01111111111111111111111111111111" Report "Failed to initialize b[1]";
    wait for 80 ns;
    assert reg(3) = 2 Report "Failed to initialize b[2]";
    
    -- TEST ADD_LARGE_NUMBERS
    wait for 1400 ns;
    wait for 80 ns;
    assert reg(3) = "11111111111111111111111111111010" Report "Failed to add a[0] + b[0]";
    wait for 80 ns;
    assert reg(3) = "10000000000000000000000000000011" Report "Failed to add a[1] + b[1]";
    wait for 80 ns;
    assert reg(3) = 28 Report "Failed to add a[2] + b[2]";
    
    ------------------------------------------------------------------------
    -- End Section ---------------------------------------------------------
    ------------------------------------------------------------------------
    
    report "Simulation complete";
    wait;
  end process;

end t2;

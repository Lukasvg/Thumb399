-- Authors : Johnny Sim, Cassandra Chow, Hyunil Lee
-- Instruction Set: ADD, Logical Shift, and Logical Operators
-- Note: For All Tests put 1040 ns on the clock

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
  -- top level entity
end testbench;

architecture tb of testbench is
  
  -- Component ALU(Integer_Unit)
  component integer_unit is
    port (
        clock : in std_logic;
			  instructions: in unsigned(15 downto 0);
			  address : out std_logic_vector(31 downto 0);
			  stall : out std_logic; -- The Reset Line to goto memory
			  reset : in std_logic -- External Input
        );
  end component;
  -- Component Memory
  component memory is 
    port (
        address: in std_logic_vector(31 downto 0);
        instructions: inout std_logic_vector(15 downto 0);
        reset: in std_logic; -- Reset Line to Flush Pipeline
        clock: in std_logic
        );
  end component;   

  
  type register_file_t is array(0 to 15) of unsigned(31 downto 0);

  signal clock: std_logic := '0';
  signal instruction: unsigned(15 downto 0) := "UUUUUUUUUUUUUUUU";
  signal instructionConversion: std_logic_vector(15 downto 0);
  signal address : std_logic_vector(31 downto 0);
  signal stall : std_logic := '0'; -- Stall Reset
  signal reset : std_logic := '0'; -- External Reset
begin
  
  -- unit under test
  uut: integer_unit port map(
    clock => clock, 
    instructions => instruction,
    address => address,
    stall => stall,
    reset => reset );
    
  vut: memory port map(
    address => address,
    instructions => instructionConversion,
    reset => stall,
    clock => clock );
    
  clock <= not clock after 10 ns; -- 20 ns clock period
  instruction <= unsigned(instructionConversion); -- Created to Convert UNSIGNED to STD_LOGIC_VECTOR
 process
    -- access the register file within the uut (VDHL 2008 only)
    alias reg is << signal .testbench.uut.reg: register_file_t>>;
  begin
    -- Move Registers 
    -- 1
    -- MOV R0, #2
    wait for 60 ns; -- Startup time is necessary for the instruction to be fed into the pipeline
    assert reg(0) = 2 report "2 reg 0 fail";
    -- 2
    -- MOV R1, R0
    wait for 40 ns; -- This instruction started at phase 2 of the above instruction
    assert reg(1) = 2 report "Move reg fail";  
    -- 3
    -- MOV R9, R3
    wait for 20 ns;
    assert reg(9) = 2 report "Move reg fail";
    
    -- Logical Shift
    -- ASR
    -- 4
    -- ASR R2, R1, #4
    wait for 20 ns;
    assert reg(2) = reg(1) sra 4 report "Arithmatic Right Shift Failed";

    -- MOV Literals R1 = 2 R2 = 4
    -- 5
    -- MOV R1, #2
    wait for 20 ns;
    -- 6
    -- MOV R2, #4
    wait for 20 ns;  
    
    -- ASR Register
    -- 7
    -- ASR R2, R1
    wait for 20 ns;
    assert reg(2) = 1 report "Arithmetic Right Register Shift Failed";
    -- ADD R1, #11
    wait for 20 ns;
    assert reg(1) = 13 report "Add 11 fail"; 
    
    -- Add Registers 
    -- 28
    -- Add R3, R2, R1 -- Add Registers
    wait for 20 ns;
    assert reg(3) = reg(2) + reg(1) report "Add Registers Fail";
    
    -- 29
    -- ADD R8, R1 --------------
    wait for 20 ns;
    assert reg(8) = 13 report "Add Registers Fail";
    
    -- Add Stack Pointer
    -- Clear Stack Pointer
    -- 30
    -- MOV R1, #0
    wait for 20 ns;
    -- 31
    -- MOV R13, R1
    wait for 20 ns;
    
    -- 32
    -- Add R1, #2;
    wait for 20 ns;
    assert reg(1) = reg(13) + 2 report "SP Add Failed";

    -- 33
    -- Add Stack Pointer with itself
    wait for 20 ns;
    assert reg(13) = 1 report "SP Add Failed";
       
    -- Add Program counter 
    -- 34
    -- MOV R1, #0
    wait for 20 ns;
    -- ADD R1, #1
    wait for 20 ns;
    assert reg(1) = 40 report "Add Program Counter Failed"; -- Add program counter

    -- Add With Carry
    -- 35
    -- MOV R1, #32
    wait for 20 ns;
    -- 36
    -- MOV R2, #1
    wait for 20 ns;  
    -- 37
    -- MOV R3, #1
    wait for 20 ns;
    -- 38  
    -- LSL R2, R1
    wait for 20 ns; 
    -- 39
    -- LSL R3, R1
    wait for 20 ns; 
    -- 40
    -- Add R3, R2, R3 -- Add Registers
    wait for 20 ns;
    -- 41
    -- ADC R3, R2 -- With Carry
    wait for 20 ns;
    assert reg(3) = reg(2) + 1 report "Add With Carry Fail";
    
    -- LSL 
    -- 8
    -- MOV R1, #1
    wait for 20 ns;
    -- LSL R2, R1, #4
    wait for 20 ns;
    assert reg(2) = 16 report "Left Shift Fail"; 
  
    -- MOV Literals R1 = 4 R2 = 1
    -- 9
    -- MOV R1, #4
    wait for 20 ns;
    -- 10
    -- MOV R2, #1
    wait for 20 ns;  

    -- LSL Register
    -- 11
    -- LSL R2, R1
    wait for 20 ns;
    assert reg(2) = 16 report "Logic Shift Left Register Failed";
     
    -- LSR 
    -- 12
    -- LSR R2, R1, #4
    wait for 20 ns;
    assert reg(2) = reg(1) srl 4 report "Logic Shift Right Failed";
    
    -- MOV Literals R1 = 4 R2 = 16
    -- 13
    -- MOV R1, #4
    wait for 20 ns;
    -- 14
    -- MOV R2, #16
    wait for 20 ns;    
    
    -- LSR Register
    -- 15
    -- LSR R2, R1
    wait for 20 ns;
    assert reg(2) = 1 report "Logical Shift Right Register Failed";

    -- MOV Literals R1 = 4 R2 = 16
    -- 16
    -- MOV R1, #4
    wait for 20 ns;
    -- 17
    -- MOV R2, #16
    wait for 20 ns;    

    -- ROR  
    -- 18
    -- ROR R2, R1
    wait for 20 ns;
    assert reg(2) = 1 report "Logical Shift Right Register Failed";
   
    -- Immediate Add
    -- MOV Literals R1 = 0 R2 = 0
    -- 19
    -- MOV R0, #0
    wait for 20 ns;
    -- 20
    -- MOV R1, #0
    wait for 20 ns;    
    
    -- 21
    -- ADD R1, R0, #1
    wait for 20 ns;
    assert reg(1) = 1 report "Add 1 fail";
    
    -- 22
    -- ADD R2, R1, #5
    wait for 20 ns;
    assert reg(2) = 6 report "Add 5 fail";
    
    -- 23
    -- ADD R3, R2, #7
    wait for 20 ns;
    assert reg(3) = 13 report "Add 7 fail";
 
    -- Add with Imm8
    -- 24
    -- MOV R1, #0
    wait for 20 ns;
    -- Used for Register Add R8(1) = R4(1) + R8(0)
    -- 25
    -- MOV R8, R1
    wait for 20 ns;
    -- 26
    -- MOV R4, #1
    wait for 20 ns;
    ----------------------  
    -- 27
    -- ADD R1, #11
    wait for 20 ns;
    assert reg(1) = 11 report "Add 11 fail"; 
    

    -- Logical Operation
    -- MOV R1, #32
    wait for 20 ns;
    -- MOV R2, #32
    wait for 20 ns; 
    -- AND
    -- 42
    -- AND R2, R1
    wait for 20 ns;
    assert reg(2) = 31 report "AND operation failed";
    
    -- BIC
    -- 43
    -- BIC R2, R1
    wait for 20 ns;
    assert reg(2) = 0 report "BIC operation failed"; -- Might need to be changed
    
    -- EOR
    -- 44
    -- EOR R2, R1
    wait for 20 ns;
    assert reg(2) = 31 report "XOR operation failed";

    -- MVN
    -- 45
    -- MVN R2, R1
    wait for 20 ns;
    assert reg(2) = unsigned(not std_logic_vector(reg(1)));
  
  
    -- MOV R1, #32
    wait for 20 ns;
    -- MOV R2, #63
    wait for 20 ns; 
    -- OR
    -- 46
    -- OR R2, R1
    wait for 20 ns;
    assert reg(2) <= 63 report "OR operation failed";
    
    -- MOV R1, #4
    wait for 20 ns;
    -- B 
    wait for 20 ns;
    -- Add R1, #2
    wait for 60 ns;
    assert reg(1) = 6 report "B operation failed";
    
    -- Mov R0, #4
    wait for 20 ns;
    -- BX R0
    wait for 20 ns;
    -- Add R1, #2
    wait for 60 ns;
    assert reg(1) = 8 report "BX operation failed";
    
    -- BLX R0
    wait for 20 ns;
    -- Add R1, #2
    wait for 60 ns;
    assert reg(1) = 8 report "BLX operation failed";
    
    -- BL 
    wait for 20 ns;
    wait for 20 ns; -- it's a two step operation
    -- Add R1, #2
    wait for 60 ns;
    assert reg(1) = 12 report "BL operation failed";

    wait for 40 ns;
    reset <= '1';
    wait for 20 ns;
    assert reg(15) = 0 report "reset error";
    WAIT FOR 60 NS;
    reset <= '0';
    WAIT FOR 100 NS;

    report "Simulation complete";
    wait;
  end process;

end tb;

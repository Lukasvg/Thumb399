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
			  instructionTemp: in unsigned(15 downto 0);
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
    instructionTemp => instruction,
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
    alias statusRegisters is << signal .testbench.uut.statusRegisters: unsigned >>;
  begin
    -- Move Registers 
    -- 1 -- MOV R0, #2
    wait for 40 ns; -- Because it starts at zero meaning its gone through phase 1 and 2
    assert reg(0) = 2 report "2 reg 0 fail";
    -- 2 -- MOV R1, R0
    wait for 40 ns; -- Because it has to take two cycles to adjust to phase 
    assert reg(1) = 2 report "Move reg fail";  
    -- 3 -- MOV R9, R3
    wait for 20 ns;
    assert reg(9) = 2 report "Move reg fail";
    
    -- Logical Shift
    -- ASR
    -- 4 -- ASR R2, R1, #4
    wait for 20 ns;
    assert reg(2) = reg(1) sra 4 report "Arithmatic Right Shift Failed";

    -- MOV Literals R1 = 2 R2 = 4
    -- 5 -- MOV R1, #2
    -- 6 -- MOV R2, #4
     
    -- ASR Register
    -- 7 -- ASR R2, R1
    wait for 60 ns; -- MOV, MOV, ASR
    assert reg(2) = 1 report "Arithmetic Right Register Shift Failed";
    
    -- LSL 
    -- 8 -- LSL R2, R1, #4
    wait for 20 ns;
    assert reg(2) = reg(1) sll 4 report "Logic Shift Left Failed";

    -- MOV Literals R1 = 4 R2 = 1
    -- 9 -- MOV R1, #4
    -- 10 -- MOV R2, #1

    -- LSL Register
    -- 11 -- LSL R2, R1
    wait for 60 ns; -- MOV, MOV, LSL
    assert reg(2) = 16 report "Logic Shift Left Register Failed";
    
    -- LSR 
    -- 12 -- LSR R2, R1, #4
    wait for 20 ns;
    assert reg(2) = reg(1) srl 4 report "Logic Shift Right Failed";
    
    -- MOV Literals R1 = 4 R2 = 16
    -- 13 -- MOV R1, #4
    -- 14 -- MOV R2, #16    
    
    -- LSR Register
    -- 15 -- LSR R2, R1
    wait for 60 ns; -- MOV, MOV, LSR
    assert reg(2) = 1 report "Logical Shift Right Register Failed";

    -- MOV Literals R1 = 4 R2 = 16
    -- 16 -- MOV R1, #4
    -- 17 -- MOV R2, #16  

    -- ROR  
    -- 18 -- ROR R2, R1
    wait for 60 ns; -- MOV, MOV, ROR
    assert reg(2) = 1 report "Rotate Right Register Failed";
    
    -- Immediate Add
    -- MOV Literals R1 = 0 R2 = 0
    -- 19 -- MOV R0, #0
    -- 20 -- MOV R1, #0   
    
    -- 21 -- ADD R1, R0, #1
    wait for 60 ns; -- MOV, MOV, ADD
    assert reg(1) = 1 report "Add 1 fail";
    
    -- 22 -- ADD R2, R1, #5
    wait for 20 ns;
    assert reg(2) = 6 report "Add 5 fail";
    
    -- 23 -- ADD R3, R2, #7
    wait for 20 ns;
    assert reg(3) = 13 report "Add 7 fail";
    
    -- Add with Imm8
    -- 24 -- MOV R1, #0
    -- 25 -- MOV R8, R1
    -- 26 -- MOV R4, #1
    ----------------------  
    -- 27 -- ADD R1, #11
    wait for 80 ns; -- MOV, MOV, MOV, ADD
    assert reg(1) = 11 report "Add 11 ffail"; 
    
    -- Add Registers 
    -- 28 -- Add R3, R2, R1
    wait for 20 ns;
    assert reg(3) = reg(2) + reg(1) report "Add Registers Fail";
    
    -- 29 -- ADD R8, R4;
    wait for 20 ns;
    assert reg(8) = 1 report "Add Registers Fail";
    
    -- Add Stack Pointer
    -- Clear Stack Pointer
    -- 30 -- MOV R1, #0
    -- 31 -- MOV R13, R1
    
    -- 32 -- Add R1, #2;
    wait for 60 ns; -- MOV, MOV, ADD
    assert reg(1) = reg(13) + 2 report "SP Add Failed";
    
    -- 33 -- Add #1
    wait for 20 ns;
    assert reg(13) = 1 report "SP Add Failed";
    
    -- Add Program counter 
    -- 34 -- MOV R1, #0
    -- 35 -- ADR R1, #1
    wait for 40 ns; -- MOV, ADR
    assert reg(1) = 76 report "Add Program Counter Failed"; -- Add program counter

    -- Add With Carry
    -- 36 -- MOV R1, #32
    -- 37 -- MOV R2, #1 
    -- 38 -- MOV R3, #1
    -- 39 -- LSL R2, R1
    -- 40 -- LSL R3, R1 
    -- 41 -- ADD R3, R2, R3
    -- 42 -- ADC R3, R2
    wait for 140 ns; -- MOV, MOV, MOV, LSL, LSL, ADD, ADC
    assert reg(3) = reg(2) + 1 report "Add With Carry Fail";

    -- Logical Operation
    -- 43 -- MOV R1, #32
    -- 44 -- MOV R2, #32
    -- AND 
    -- 45 -- AND R2, R1
    wait for 60 ns; -- MOV, MOV, AND
    assert reg(2) = 31 report "AND operation failed";
    
    -- BIC
    -- 46 -- BIC R2, R1
    wait for 20 ns;
    assert reg(2) = 0 report "BIC operation failed"; -- Might need to be changed
    
    -- EOR
    -- 47 -- EOR R2, R1
    wait for 20 ns;
    assert reg(2) = 31 report "XOR operation failed";

    -- MVN
    -- 48 -- MVN R2, R1
    wait for 20 ns;
    assert reg(2) = unsigned(not std_logic_vector(reg(1)));
  
    -- 49 -- MOV R1, #32
    -- 50 -- MOV R2, #63
    -- OR
    -- 51 -- OR R2, R1
    -- wait for 20 ns;
    wait for 60 ns; -- MOV, MOV, OR
    assert reg(2) = 63 report "OR operation failed";
    
    ------------------------------------------------------
    -- MOV R1, #4
    wait for 20 ns;
    -- B 
    wait for 20 ns;
    -- Add R1, #2
    wait for 100 ns;
    assert reg(1) = 6 report "B operation failed";
    
    -- Mov R0, #4
    wait for 20 ns;
    -- BX R0
    wait for 20 ns;
    -- Add R1, #2
    wait for 100 ns;
    assert reg(1) = 8 report "BX operation failed";
    
    -- BLX R0
    wait for 20 ns;
    -- Add R1, #2
    wait for 100 ns;
    assert reg(1) = 10 report "BLX operation failed";
    
    -- BL 
    wait for 20 ns;
    wait for 20 ns; -- it's a two step operation
    -- Add R1, #2
    wait for 40 ns;
    assert reg(1) = 12 report "BL operation failed";
    
    -- B 
    wait for 20 ns;
    
    -- Cody's Test Code. Instruction Memory 200-299 
    -- MOV
    wait for 100 ns;
    assert reg(0) = 1 report "Mov != 1";
    

    -- Johnny's Test Code. Instruction Memory 500-599
    -- CMP Instructions Tests
    -------------------------------------------------------------------------------
    wait for 20 ns; -- MOV R0, 0
    wait for 20 ns; -- MOV R1, 0
    wait for 20 ns; -- CMN R0, R1
    assert statusRegisters(2) = '1' report "CMN Zero Register Updated";
    wait for 20 ns; -- CMP Constant
    assert statusRegisters(2) = '1' report "CMP Constant Zero Register Updated";
    wait for 20 ns; -- CMP Register
    assert statusRegisters(2) = '1' report "CMP Registers Zero Register Updated";
    wait for 20 ns; -- CMP Extend Register
    assert statusRegisters(2) = '1' report "CMP Extend Reg Zero Register Updated";
    wait for 20 ns; -- TST Registers
    assert statusRegisters(2) = '1' report "TST Register Zero Updated";
    
    wait for 20 ns; -- SUB R0, 1
    wait for 20 ns; -- CMN R0, R1;
    assert statusRegisters(1) = '1' report "CMN Negative Register Updated";
    wait for 20 ns; -- CMP Constant
    assert statusRegisters(1) = '1' report "CMP Constant Negative Register Updated";
    wait for 20 ns; -- CMP Register
    assert statusRegisters(1) = '1' report "CMP Registers Negative Register Updated";
    wait for 20 ns; -- CMP Extend Register
    assert statusRegisters(1) = '1' report "CMP Extend Reg Negative Register Updated";
  
    wait for 20 ns; -- SUB r1, 1
    wait for 20 ns; -- TST Registers
    assert statusRegisters(1) = '1' report "TST Register Negative Updated";
    
    wait for 20 ns; -- CMN R0, R1;
    assert statusRegisters(3) = '1' report "CMN Carry Register Updated";
    
    wait for 20 ns; -- MOV R0, 0
    wait for 20 ns; -- MOV R1, 1
    wait for 20 ns; -- CMP Constant
    assert statusRegisters(3) = '1' report "CMP Constant Carry Register Updated";
    assert statusRegisters(0) = '1' report "CMP Overflow Register Updated";
    wait for 20 ns; -- CMP Register
    assert statusRegisters(3) = '1' report "CMP Registers Carry Register Updated";
    assert statusRegisters(0) = '1' report "CMP Overflow Register Updated";
    wait for 20 ns; -- CMP Extend Register
    assert statusRegisters(3) = '1' report "CMP Extend Reg Carry Register Updated";
    assert statusRegisters(0) = '1' report "CMP Overflow Register Updated";
    -----------------------------------------------------------------------------------
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

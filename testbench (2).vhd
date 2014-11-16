-- Group 1 Authors : Johnny Sim, Cassandra Chow, Hyunil Lee
-- Instruction Set: ADD, Logical Shift, and Logical Operators
-- Note: For All Tests put 1040 ns on the clock

-- Group 2 Authors : Louis Coyle, Cassandra Chow, Hyunil Lee

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
  -- top level entity
end testbench;

architecture tb of testbench is
  component integer_unit is
    port (clock: in std_logic);
  end component;
  
  type register_file_t is array(0 to 15) of unsigned(31 downto 0);

  signal clock: std_logic := '0';
begin
  
  -- unit under test
  uut: integer_unit port map(
    clock => clock);
    
  clock <= not clock after 10 ns; -- 20 ns clock period
  
  process
    -- access the register file within the uut (VDHL 2008 only)
    alias reg is << signal .testbench.uut.reg: register_file_t>>;
  begin
    -- Move Registers 
    -- 1 -- MOV R0, #2
    wait for 40 ns;
    assert reg(0) = 2 report "2 reg 0 fail";
    -- 2 -- MOV R1, R0
    wait for 20 ns;
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
    assert reg(1) = 11 report "Add 11 fail"; 
    
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
    assert reg(1) = reg(15) + 4 report "Add Program Counter Failed"; -- Add program counter

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
    
    -- 52 -- MOV R1, R15 (PC)
    -- 53 -- B #2
    wait for 40 ns; -- MOV, B
    assert reg(15) = reg(1) + 4 - 2 report "B(unconditional) operation failed";
    
    -- 54 ~ MOV R0, #204
    -- 55 -- MOV R0, #255
    wait for 20 ns; -- wait for instruction after branch
    assert reg(0) = 255 report "Failed to flush after B(unconditional)";
    
    -- 56 -- ADR R1, #2
    -- 57 -- BX R1
    wait for 40 ns; -- ADR, BX
    assert reg(15) = reg(1) - 2 report "BX operation failed";
    
    -- 58 ~ MOV R2, #204
    -- 59 ~ MOV R2, #204
    -- 60 -- MOV R2, #255
    wait for 20 ns; -- wait for instruction after branch
    assert reg(2) = 255 report "Failed to flush after BX";
    
    -- 61 -- ADR R1, #2
    -- 62 -- BLX R1
    wait for 40 ns; -- ADR, BLX
    assert reg(15) = reg(1) - 2 report "BLX operation failed";
    
    -- 63 ~ MOV R4, #204
    -- 64 ~ MOV R4, #204
    -- 65 -- MOV R4, #255
    wait for 20 ns; -- wait for instruction after branch
    assert reg(4) = 255 report "Failed to flush after BLX";
    
    -- 66 -- BL(1)
    -- 67 -- BL(2) 0x015C
    wait for 40 ns; -- BL(1), BL(2)
    assert reg(15) = 348 - 2 report "BL operation failed";
    
    -- 68 ~ MOV R6, #204
    -- 69 -- MOV R6, #255
    wait for 20 ns; -- wait for instruction after branch
    assert reg(6) = 255 report "Failed to flush after BL";
    
    report "Simulation complete";
    wait;
  end process;
end tb;

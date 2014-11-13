-- ARM Thumb design sample testbench
-- (C) Digipen 2014 - ECE 399

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
  -- top level entity
end testbench;

architecture tb of testbench is
  component instruction_decoder is
    port (clock: in std_logic;
        instruction: in unsigned(15 downto 0)
        );
  end component;
  
  type reg is array(15 downto 0) of unsigned(31 downto 0);

  signal clock: std_logic := '0';
  signal instruction: unsigned(15 downto 0);
begin
  
  -- unit under test
  uut: instruction_decoder port map(
    clock => clock, 
    instruction => instruction);
    
  clock <= not clock after 10 ns; -- 20 ns clock period
  
  process
    -- access the register file within the uut (VDHL 2008 only)
    alias reg is << signal .testbench.uut.registers: reg >>;
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
    
    instruction <= "00110" & "011" & "11110100"; -- ADD R3, #244
    wait for 20 ns;
    assert reg(3) = 257 report "Add 244 fail";
    
    instruction <= "00100" & "000" & "00000001"; -- MOV R0, #1
    wait for 20 ns;
    assert reg(0) = 1 report "MOV 1 into R0 fail";

    instruction <= "00100" & "001" & "00000001"; -- MOV R1, #1
    wait for 20 ns;
    assert reg(1) = 1 report "MOV 1 into R1 fail";

    instruction <= "0100000111" & "001" & "000"; -- ROR R0, R1, #1
    wait for 20 ns;
    assert reg(0) = "10000000000000000000000000000000" report "ROR With Registers";

    instruction <= "0001100" & "000" & "000" & "000"; -- ADD R0, R0, R0
    wait for 20 ns;
    assert reg(0) = 0 report "Add R0 and R0 fail";
  
    instruction <= "0100000" & "101" & "000" & "001"; -- ADC R1, R0
    wait for 20 ns; -- R0 is 0, R1 is 1 and C is 1 so answer should be 2
    assert reg(1) = 2 report "ADC R1 += R0 + carry fail";
    
    instruction <= "0001100" & "010" & "011" & "100"; -- ADD R4, R2, R1
    wait for 20 ns;
    assert reg(4) = 263 report "Add R2(6) and R1(1) fail";
    
    instruction <= "00100" & "101" & "00000000"; -- MOV R0, #
    wait for 20 ns;
    assert reg(5) = "00000000" report "00001101 reg 0 fail";
    
    instruction <= "01000110" & "1" & "0101" & "101"; -- MOV R0, #
    wait for 20 ns;
    assert reg(13) = "0" report "0 reg 0 fail";
    
    instruction <= "01000100" & "1" & "0100" & "101";-- ADD R13, R4
    wait for 20 ns;
    assert reg(13) = 263 report "Add R4 to SP fail";
    
    instruction <= "10101" & "011" & "00001101"; -- ADD R4, R13, #13
    wait for 20 ns;
    assert reg(3) = 276 report "Add R4 = SP + 13 fail";
    
    instruction <= "10110000" & "01111000"; -- ADD R13, #120
    wait for 20 ns;
    assert reg(13) = 383 report "Add 120 to SP fail";
    
    -- Louis' Test Bench Ends, Tyler's Test Bench Begins --
    
    instruction <= "00100" & "000" & "01010101"; -- MOV R0, #
    wait for 20 ns;
    assert reg(0) = "01010101" report "01010101 reg 0 fail";
    
    instruction <= "00100" & "001" & "11111111"; -- MOV R1, #
    wait for 20 ns;
    assert reg(1) = "11111111" report "11111111 reg 1 fail";
    
    instruction <= "0100000000" & "000" & "001"; -- and
    wait for 20 ns;
    assert reg(1) = "01010101" report "and fail";
    
    instruction <= "00100" & "001" & "11111111"; -- MOV R1, #
    wait for 20 ns;
    assert reg(1) = "11111111" report "11111111 reg 1 fail";
    
    instruction <= "00100" & "000" & "00000010"; -- MOV R0, #
    wait for 20 ns;
    assert reg(0) = "00000010" report "01010101 reg 0 fail";
    
    instruction <= "0100001110" & "000" & "001"; -- bic
    wait for 20 ns;
    assert reg(1) = "11111101" report " bic fail";
    
    instruction <= "00100" & "000" & "01010101"; -- MOV R0, #
    wait for 20 ns;
    assert reg(0) = "01010101" report "01010101 reg 0 fail";
    
    instruction <= "00100" & "001" & "11111111"; -- MOV R1, #
    wait for 20 ns;
    assert reg(1) = "11111111" report "11111111 reg 1 fail";
    
    instruction <= "0100000001" & "000" & "001"; -- eor
    wait for 20 ns;
    assert reg(1) = "10101010" report "eor fail";
    
    instruction <= "0100001111" & "000" & "001"; -- mvn
    wait for 20 ns;
    assert reg(1) = "11111111111111111111111110101010" report "mvn fail";
    
    instruction <= "00100" & "000" & "01010101"; -- MOV R0, #
    wait for 20 ns;
    assert reg(0) = "01010101" report "01010101 reg 0 fail";
    
    instruction <= "00100" & "001" & "11110000"; -- MOV R1, #
    wait for 20 ns;
    assert reg(1) = "11110000" report "11111111 reg 1 fail";

    instruction <= "0100001100" & "000" & "001"; -- orr
    wait for 20 ns;
    assert reg(1) = "11110101" report "orr fail";  
    
    -- Tyler's Test Bench Ends, Cody's Test Bench Begins --     
    
    -- ASR Without Registers
    instruction <= "00100" & "001" & "10000010"; -- MOV R1, #130
    wait for 20 ns;
    assert reg(1) = 130 report "Zero reg 0 fail";


    instruction <= "00010" & "00001" & "001" & "000"; -- ASR R0, #1
    wait for 20 ns;
    assert reg(0) = 65 report "ASR Without Registers";

    --ASR With Registers
    instruction <= "00100" & "000" & "10000010"; -- MOV R0, #130
    wait for 20 ns;
    assert reg(0) = 130 report "Zero reg 0 fail";

    instruction <= "00100" & "001" & "00000001"; -- MOV R1, #1
    wait for 20 ns;
    assert reg(1) = 1 report "Zero reg 1 fail";

    instruction <= "0100000100" & "001" & "000"; -- ASR R0, R1
    wait for 20 ns;
    assert reg(0) = 65 report "ASR With Registers ";

    --LSL Without Registers
    instruction <= "00100" & "000" & "10000010"; -- MOV R0, #130
    wait for 20 ns;
    assert reg(0) = 130 report "Zero reg 0 fail";

    instruction <= "00000" & "00001" & "000" & "001"; -- LSL R1, R0, #1
    wait for 20 ns;
    assert reg(1) = 260 report "LSL Without Registers";

    --LSL With Registers
    instruction <= "00100" & "000" & "10000010"; -- MOV R0, #130
    wait for 20 ns;
    assert reg(0) = 130 report "Zero reg 0 fail";

    instruction <= "00100" & "001" & "00000001"; -- MOV R1, #1
    wait for 20 ns;
    assert reg(1) = 1 report "Zero reg 0 fail";

    instruction <= "0100000010" & "001" & "000"; -- LSL R0, R1, #1
    wait for 20 ns;
    assert reg(0) = 260 report "LSL With Registers";

    --LSR
    instruction <= "00100" & "001" & "10000010"; -- MOV R1, #130
    wait for 20 ns;
    assert reg(1) = 130 report "Zero reg 0 fail";

    instruction <= "00001" & "00001" & "001" & "000"; -- LSR R0, R1, #1
    wait for 20 ns;
    assert reg(0) = 65 report "LSR Without Registers";

    --LSR With Registers
    instruction <= "00100" & "000" & "10000010"; -- MOV R0, #130
    wait for 20 ns;
    assert reg(0) = 130 report "MOV 130 fail";

    instruction <= "00100" & "001" & "00000001"; -- MOV R1, #1
    wait for 20 ns;
    assert reg(1) = 1 report "Zero reg 0 fail";

    instruction <= "0100000011" & "001" & "000"; -- LSL R0, R1, #1
    wait for 20 ns;
    assert reg(0) = 65 report "LSR With Registers";

    --ROR
    instruction <= "00100" & "000" & "00000001"; -- MOV R0, #1
    wait for 20 ns;
    assert reg(0) = 1 report "MOV 1 fail";

    instruction <= "00100" & "001" & "00000010"; -- MOV R1, #2
    wait for 20 ns;
    assert reg(1) = 2 report "MOV 2 into R1 fail";

    instruction <= "0100000111" & "001" & "000"; -- ROR R0, R1, #2
    wait for 20 ns;
    assert reg(0) = 1073741824 report "ROR With Registers";
    
    report "Simulation complete";
    wait;
  end process;
end tb;

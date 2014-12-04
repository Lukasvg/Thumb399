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
  
/* ASM file to be implemented in instruction memory
  
  MOV r0, #0   -- source address
  MOV r1, #10  -- dest address
  MOV r2, #0   -- to store each word of the string
  MOV r3, #0   -- to save each word during byte testing
  MOV r6, #0   -- to count the number of words copied
  MOV r7, #0   -- for storing the number of bytes to rotate by

copy:

  MOV r4, #255  -- initialize register to and words with to get bytes
  MOV r5, #0    -- and register to count number of bytes checked

  LDR r2, [r0]    -- load and store 1 word
  STR r2, [r1]

  ADD r0, #1    -- increment source and dest addresses to next word
  ADD r1, #1
  ADD r6, #1    -- increment the number of words copied

checknull:

  MOV r3, r2  -- save loaded value
  ROR r3, r7  -- rotate the word to check the next byte for null terminator
  
  AND r3, r4  -- select the rightmost byte

  CMP r3, #0  -- check if it is the null terminator
  BEQ verify  -- if so, end program

  ADD r7, #8  -- increment the amount to rotate by a byte
  ADD r5, #1  -- increment the counter for number of bytes checked

  CMP r5, #4  -- if all bytes have been checked and there is no null
  BEQ copy    -- then return to the start of the program (after initialization)
  B checknull -- otherwise there are more bytes to check

verify:
  SUB r0, #1  -- decrement source and dest addresses to previous word
  SUB r1, #1  -- they are at the last word because of previous instructions
  
  LDR r2, [r0]  -- load r2 with the source word
  LDR r3, [r1]  -- and r3 with the dest word

  SUB r6, #1  -- decrement the number of words that have been copied

  CMP r2, r3  -- cmp the two
  BNE fail    -- if they are not equivalent, the strcpy failed
  CMP r6, #0  -- if there are no words left to copy, and strcpy didnt fail
  BEQ success -- then report a success
  B verify    -- otherwise there are still words to check


fail:
  MOV r0, #255 -- 0xFF is exit failure

success:
  MOV r0, #0  -- 0 is exit success
  
*/
  
  signal imem: imem_t := (
  0 => x"2000", -- MOV r0, #0 (source contains "helloworld!")
  1 => x"210A", -- MOV r1, #10 (dest)
  2 => x"2200", -- MOV r2, #0
  3 => x"2300", -- MOV r3, #0
  4 => x"2600", -- MOV r6, #0
  5 => x"2700", -- MOV r7, #0
  6 => x"24FF", -- copy: MOV r4, #255
  7 => x"2500", -- MOV r5, #0
  8 => x"6802", -- LDR r2, [r0]
  9 => x"600A", -- STR r2, [r1]
  10 => x"3001", -- ADD r0, #1
  11 => x"3101", -- ADD r1, #1
  12 => x"3601", -- ADD r6, #1
  13 => x"1C13", -- checknull: MOV r3, r2
  14 => x"41FB", -- ROR r3, r7
  15 => x"4023", -- AND r3, r4
  16 => x"2B00", -- CMP r3, #0
  17 => x"D004", -- BEQ verify
  18 => x"3708", -- ADD r7, #8
  19 => x"3501", -- ADD r5, #1
  20 => x"2D04", -- CMP r5, #4
  21 => x"D0F0", -- BEQ copy
  22 => x"E7F5", -- B checknull
  23 => x"1E40", -- verify: SUB r0, #1
  24 => x"1E49", -- SUB r1, #1
  25 => x"6802", -- LDR r2, [r0]
  26 => x"680B", -- LDR r3, [r1]
  27 => x"1E76", -- SUB r6, #1
  28 => x"429A", -- CMP r2, r3
  29 => x"D102", -- BNE fail
  30 => x"2E00", -- CMP r6, #0
  31 => x"D001", -- BEQ success
  32 => x"E7F5", -- B verify
  33 => x"20FF", -- fail: MOV r0, #255
  34 => x"2000", -- success: MOV r0, #0
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
    wait for 3660 ns; -- wait some long period of time until it is done copying and verifying
    assert reg(0) = 0 report "strcpy failed, program reported exit failure";
    report "Simulation complete";
    wait;
  end process;

end t2;

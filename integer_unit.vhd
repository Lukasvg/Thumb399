-- Authors : Johnny Sim, Cassandra Chow, Hyunil Lee
-- Instruction Set: ADD, Logical Shift, and Logical Operators

--cody
--Added to entitiy address that will be sent to johnnny, 
--stall to reset pipline, reset to reset program counter and pipline
--At the bottom of the file before the end of if I increment the PC
--I added a check in the if for reset line
--after the process block i set the PC to 0 if reset is high

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
entity integer_unit is
	port (clock : in std_logic;
			  instructionTemp: in unsigned(15 downto 0);
			  address : out std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			  stall : out std_logic := '0';
			  reset : in std_logic;
			  flush : out std_logic := '0');
end integer_unit;

architecture integer_unit of integer_unit is
  type register_file_t is array(0 to 15) of unsigned(31 downto 0);
	signal reg : register_file_t := (others => (others => '0'));
	signal statusRegisters : unsigned(3 downto 0) := to_unsigned(0, 4);
	 -- 3 => Carry
	 -- 2 => Zero
	 -- 1 => Negative
	 -- 0 => Overflow
	signal instruction : unsigned(15 downto 0);
	signal stallHappened: std_logic := '0';
	signal ram_addr : std_logic_vector (11 downto 0) := std_logic_vector(to_unsigned(0, 12));
	signal ram_data : std_logic_vector (31 downto 0) := std_logic_vector(to_unsigned(0, 32));
	signal ram_wren : std_logic := '0';
	signal ram_out : std_logic_vector (31 downto 0) := std_logic_vector(to_unsigned(0, 32));
begin
  process (instructionTemp,stall,reset) 
    variable tempCpy: unsigned(15 downto 0);
    begin
    tempCpy := instruction;
    if(flush = '1') then
      instruction <= "0000000000000000"; -- All zeroes
    elsif(falling_edge(stall) and flush = '0') then
      instruction <= instructionTemp;
    elsif(stall = '1' and flush = '0') then
      instruction <= tempCpy;
    else
      instruction <= instructionTemp;
    end if;
  end process;
  RAM : entity work.ramlpm port map(ram_addr, clock, ram_data, ram_wren, ram_out);
    
	process(instruction, clock)
		-- variables
		variable bl_var: unsigned ( 11 downto 0 );
		variable ram_offset : unsigned (31 downto 0);
		variable conCat : unsigned(10 downto 0);
		
	  -- General Purpose Status Register Update Procedures
	  -- For Negative - pass in 32 bits
	  procedure NegativeRegisterUpdate( result : unsigned ) is
	  begin
	    statusRegisters(1) <= result(31); -- Negative
	  end NegativeRegisterUpdate;
	  -- For Carry - pass in 33 bits
	  procedure CarryRegisterUpdate( result : unsigned ) is
	  begin
	    statusRegisters(3) <= result(32); -- Carry
	  end CarryRegisterUpdate;
		-- For Zero - No designated size
		procedure ZeroRegisterUpdate( result : unsigned ) is
		begin
		  statusRegisters(2) <= '1' when (result = 0) else '0';
		end ZeroRegisterUpdate;
		-- For Overflow - Pass in the two src's and result. Make sure all are 32 bits in size
		procedure OverflowRegisterUpdate( src1: unsigned; src2: unsigned; result: unsigned) is
		begin
		  statusRegisters(0) <= '1' when (src1(31) = src2(31)) and (src1(31) /= result(31)) else '0'; 
		end OverflowRegisterUpdate;
		
		-- PROCEDURES HERE
		
		----[ CMN ]
		procedure CMN16(src1: unsigned;
		                src2: unsigned) is 
		variable temp : unsigned(32 downto 0) := to_unsigned(0, 33);
		begin
		  temp := resize(src1,33) + resize(src2,33);
      NegativeRegisterUpdate(temp);
   	  CarryRegisterUpdate(temp);
   	  ZeroRegisterUpdate(temp);
   	  OverflowRegisterUpdate(src1, src2, temp);
		end CMN16;               
		
		----[ CMP ]
		procedure CMP16(src1 : unsigned;
		                src2 : unsigned) is
		variable temp : unsigned(32 downto 0) := to_unsigned(0,33);
		begin
		  temp := resize(src1,33) - resize(src2, 33);
      NegativeRegisterUpdate(temp);
   	  CarryRegisterUpdate(temp);
   	  ZeroRegisterUpdate(temp);
   	  OverflowRegisterUpdate(src1, src2, temp);
		end CMP16;

    ----[ TST ]
    procedure TST16(src1 : unsigned;
                    src2 : unsigned) is
 	  variable temp : unsigned(32 downto 0) := to_unsigned(0,33);                   
    begin
      temp := resize(src1,33) and resize(src2, 33);
		  NegativeRegisterUpdate(temp);
   	  CarryRegisterUpdate(temp);
   	  ZeroRegisterUpdate(temp);
    end TST16;           

		----[ LSL ]
		procedure LSL16(dest, src : integer range 0 to 15;
							 n : integer range 0 to 32) is
		  -- store result with carry
		  variable RwC : unsigned(32 downto 0) := to_unsigned(0, 33);
		begin
		  if(n /= 0) then
		    RwC(31 downto 0) := reg(src);
			RwC := RwC sll n;
			  reg(dest) <= RwC(31 downto 0);
			  CarryRegisterUpdate(RwC);
			else
			  reg(dest) <= reg(src);
			end if;
			NegativeRegisterUpdate(RwC(31 downto 0));
			ZeroRegisterUpdate(RwC(31 downto 0));
		end LSL16;
		
		----[ LSR ]
		procedure LSR16(dest, src : integer range 0 to 15; 
							 n : integer range 0 to 32) is
		  -- store result with carry
		  variable RwC : unsigned(32 downto 0) := to_unsigned(0, 33);
		begin
		  if(n /= 0) then
		    RwC(32) := reg(src)(n - 1); -- carry flag is set to last bit shifted out
			RwC(31 downto 0) := reg(src) srl n;
			  reg(dest) <= RwC(31 downto 0);
			  CarryRegisterUpdate(RwC);
			else
			  RwC(31 downto 0) := reg(src);
			  reg(dest) <= RwC(31 downto 0);
			end if;
			NegativeRegisterUpdate(RwC(31 downto 0));
			ZeroRegisterUpdate(RwC(31 downto 0));
		end LSR16;
		
		----[ ASR ]
		procedure ASR16(dest, src : integer range 0 to 15;
							 n : integer range 0 to 32) is
		  -- store result with carry
		  variable RwC : unsigned(32 downto 0) := to_unsigned(0, 33);
		begin
		  if(n /= 0) then
		    RwC(32) := reg(src)(n - 1); -- carry flag is set to last bit shifted out
			RwC(31 downto 0) := unsigned(to_stdlogicvector(to_bitvector(std_logic_vector(reg(src))) sra n));
			reg(dest) <= RwC(31 downto 0);
			CarryRegisterUpdate(RwC);
		  else
			RwC(31 downto 0) := reg(src);
			reg(dest) <= RwC(31 downto 0);
	      end if;
		  NegativeRegisterUpdate(RwC(31 downto 0));
		  ZeroRegisterUpdate(RwC(31 downto 0));
		end ASR16;
		
		----[ ROR ]
		procedure ROR16(dest, src : integer range 0 to 15; 
							 n : integer range 0 to 31) is
			-- store result with carry
		  variable RwC : unsigned(32 downto 0) := to_unsigned(0, 33);
		begin
		  if(n /= 0) then
		    RwC(32) := reg(src)(n - 1); -- carry flag is set to last bit rotated
			  RwC(31 downto 0) := reg(src) ror n;
			  reg(dest) <= RwC(31 downto 0);
			  CarryRegisterUpdate(RwC);
			else
			  RwC(31 downto 0) := reg(src);
			  reg(dest) <= RwC(31 downto 0);
			end if;
			NegativeRegisterUpdate(RwC(31 downto 0));
			ZeroRegisterUpdate(RwC(31 downto 0));
		end ROR16;
    
		----[ MOV ]
		procedure MOV16(dest : integer range 0 to 15;
                    src : in unsigned) is					
		begin
			reg(dest) <= src;
			NegativeRegisterUpdate(src);
			ZeroRegisterUpdate(src);
		end MOV16;
		
		----[ ADC ]
		procedure ADC16( dest, src : integer range 0 to 7) is
		  -- store result with carry
		  variable RwC : unsigned(32 downto 0) := to_unsigned(0, 33);
		begin
		  RwC := resize(reg(src), 33) + resize(reg(dest), 33) + resize(statusRegisters srl 3, 33);
			reg(dest) <= RwC(31 downto 0);
			CarryRegisterUpdate(RwC);
			NegativeRegisterUpdate(RwC(31 downto 0));
			ZeroRegisterUpdate(RwC(31 downto 0));
		end ADC16;
		
		----[ ADD ]
		procedure ADD16( dest, src : integer range 0 to 15;
							  n : unsigned) is
		  -- store result with carry
		  variable RwC : unsigned(32 downto 0) := to_unsigned(0, 33);
		begin
			RwC := resize(reg(src), 33) + resize(n, 33);
			reg(dest) <= RwC(31 downto 0);
			CarryRegisterUpdate(RwC);
			NegativeRegisterUpdate(RwC(31 downto 0));
			ZeroRegisterUpdate(RwC(31 downto 0));
		end ADD16;
		
		-- [ ADD ] Stack/ADR Pointer does not update flags
		procedure ADD16S( dest, src : integer range 0 to 15;
							  n : integer range 0 to 255) is
		begin
			reg(dest) <= reg(src) + to_unsigned(n, 32);
		end ADD16S;
		
		----[ SUB ]
		procedure SUB16( dest, src : integer range 0 to 15;
							  n : unsigned) is
		variable temp : unsigned(32 downto 0) := to_unsigned(0, 33);
		begin
			temp := resize(reg(src), 33) - resize(n, 33);
			reg(dest) <= temp(31 downto 0);
			NegativeRegisterUpdate(temp);
			CarryRegisterUpdate(temp);
			ZeroRegisterUpdate(temp);
		end SUB16;
		
		procedure SUB16S( dest, src : integer range 0 to 15;
							  n : integer range 0 to 128) is
		begin
			reg(dest) <= reg(src) + to_unsigned(n, 32);
		end SUB16S;
		
		----[ SBC ]
		procedure SBC16( dest, src : integer range 0 to 7) is
		variable temp : unsigned(32 downto 0) := to_unsigned(0, 33);
		begin
			temp := resize(reg(src), 33) - resize(reg(dest), 33) - resize(statusRegisters srl 3, 33);
			reg(dest) <= temp(31 downto 0);
			NegativeRegisterUpdate(temp);
			CarryRegisterUpdate(temp);
			ZeroRegisterUpdate(temp);
		end SBC16;
	
		----[ NEG ] || RSB
		procedure NEG16( dest, src : integer range 0 to 7) is
		variable temp : unsigned(32 downto 0) := to_unsigned(0, 33);
		begin
			temp := 0 - resize(reg(src), 33);
			reg(dest) <= temp(31 downto 0);
			NegativeRegisterUpdate(temp);
			CarryRegisterUpdate(temp);
			ZeroRegisterUpdate(temp);
		end NEG16;
		
		----[ MUL ]
		procedure MUL16( dest, src : integer range 0 to 15) is
		variable temp : unsigned(65 downto 0) := to_unsigned(0, 66);
		begin
			temp := resize(reg(dest), 33) * resize(reg(src), 33);
			reg(dest) <= temp(31 downto 0);
			NegativeRegisterUpdate(temp);
			CarryRegisterUpdate(temp);
			ZeroRegisterUpdate(temp);
		end MUL16;
		
		----[ ADR ]
		procedure ADR16( dest, src : integer range 0 to 15;
							  n : integer range 0 to 255) is
		begin
			reg(dest) <= reg(src) + to_unsigned(n, 32);
		end ADR16;
		
		----[ AND ]
		procedure AND16( dest, src : integer range 0 to 15) is
		  -- store immediate result to update flags
		  variable immR : unsigned(31 downto 0) := to_unsigned(0, 32);
		begin
			immR := reg(dest) and reg(src);
			reg(dest) <= immR;
			NegativeRegisterUpdate(immR);
			ZeroRegisterUpdate(immR);
		end AND16;

		----[ BIC ]
		procedure BIC16( dest, src : integer range 0 to 15) is
			-- store immediate result to update flags
		  variable immR : unsigned(31 downto 0) := to_unsigned(0, 32);
		begin
			immR := reg(dest) and not reg(src);
			reg(dest) <= immR;
			NegativeRegisterUpdate(immR);
			ZeroRegisterUpdate(immR);
		end BIC16;

		----[ EOR ]
		procedure EOR16( dest, src : integer range 0 to 15) is
			-- store immediate result to update flags
		  variable immR : unsigned(31 downto 0) := to_unsigned(0, 32);
		begin
			immR := reg(dest) xor reg(src);
			reg(dest) <= immR;
			NegativeRegisterUpdate(immR);
			ZeroRegisterUpdate(immR);
		end EOR16;

		----[ MVN ]
		procedure MVN16( dest, src : integer range 0 to 15) is
			-- store immediate result to update flags
		  variable immR : unsigned(31 downto 0) := to_unsigned(0, 32);
		begin
			immR := not reg(src);
			reg(dest) <= immR;
			NegativeRegisterUpdate(immR);
			ZeroRegisterUpdate(immR);
		end MVN16;

		----[ ORR ]
		procedure ORR16( dest, src : integer range 0 to 15) is
			-- store immediate result to update flags
		  variable immR : unsigned(31 downto 0) := to_unsigned(0, 32);
		begin
			immR := reg(dest) or reg(src);
			reg(dest) <= immR;
			NegativeRegisterUpdate(immR);
			ZeroRegisterUpdate(immR);
		end ORR16;
		
		----[ B ]
		procedure B16( inst : unsigned) is
		begin
      if(inst(10) = '1') then
				reg(15) <= reg(15) + ("11111111111111111111" & inst & "0");
			else
				reg(15) <= reg(15) + (inst & "0");
			end if;
			stall <= '1';
			flush <= '1';
		end B16;
		
		----[ BX ]
		procedure BX16( src : integer range 0 to 15 ) is
		begin
			reg(15) <= reg(src);
			stall <= '1';
			flush <= '1';
		end BX16;
		
		----[ BLX ]
		procedure BLX16( src : integer range 0 to 15 ) is
		begin
			reg(14) <= reg(15) - "00000000000000000000000000000100";
			reg(15) <= reg(src);
			stall <= '1';
			flush <= '1';
		end BLX16;
		
		--[ BL ]
		procedure BL16( inst : unsigned(15 downto 0)) is
		begin
			reg(14) <= reg(15) - 2;
			reg(15) <= bl_var(10) & bl_var(10) & bl_var(10) & bl_var(10) & bl_var(10) & bl_var(10) & bl_var(10) & bl_var(10) & -- simple sign extend 7 bits
			not(instruction(13) xor bl_var(10)) & not(instruction(11) xor bl_var(10)) & bl_var(9 downto 0) & instruction(10 downto 0) & '0';
					-- sssssssss(8) & 
					-- I1 & I2 & 
					-- imm10 & imm11 & 0 
			bl_var(11) := '0';  -- resets the bl hold 
			stall <= '1';
			flush <= '1';
		end BL16;
		
		----[ UXTB ]
		procedure UXTB16( src, dest : integer range 0 to 7 ) is 
		begin
		  reg(dest) <= "000000000000000000000000" & reg(src)(7 downto 0);
		end UXTB16;
		  
	  ----[ UXTH ]
		procedure UXTH16( src, dest : integer range 0 to 7 ) is 
		begin
		  reg(dest) <= "0000000000000000" & reg(src)(15 downto 0);
		end UXTH16;
		
		----[ SXTB ]
		procedure SXTB16( src, dest : integer range 0 to 7 ) is 
		begin
		  if reg(src)(7) = '1' then
		    reg(dest) <= "111111111111111111111111" & reg(src)(7 downto 0);
		  else
		    reg(dest) <= "000000000000000000000000" & reg(src)(7 downto 0);
		  end if;
		end SXTB16;
		
		----[ SXTH ]
		procedure SXTH16( src, dest : integer range 0 to 7 ) is 
		begin
		  if reg(src)(15) = '1' then
		    reg(dest) <= "1111111111111111" & reg(src)(15 downto 0);
		  else
		    reg(dest) <= "0000000000000000" & reg(src)(15 downto 0);
		  end if;
		end SXTH16;
		
		----[ LDR16 ]
		procedure LDR16( dest : integer range 0 to 7;
		                 src, offset : unsigned (31 downto 0)) is
		variable temp_addr : unsigned(31 downto 0); 
		begin
		  -- Load dest register with value in RAM at [src + offset]
		  -- dest = [src + offset]
		  temp_addr := src + offset;
		  ram_addr <= std_logic_vector(temp_addr(11 downto 0));
		  ram_wren <= '0';
		  reg(dest) <= unsigned(ram_out);
		  --reg(15) <= reg(15) - 2;
		  if(stallHappened = '0') then
		    stall <= '1'; -- Stall the pipeline
		  end if;
		end LDR16;
		
		----[ STR16 ]
		procedure STR16( src, offset, value : unsigned (31 downto 0)) is
		variable temp_addr : unsigned(31 downto 0);
		begin
		  -- Store value into RAM at [src + offset]
		  -- [src + offset] = value
		  temp_addr := src + offset;
		  ram_addr <= std_logic_vector(temp_addr(11 downto 0));
		  ram_wren <= '1';
		  ram_data <= std_logic_vector(value);
		end STR16;
		
	-- Bug note
	-- If the clock changes for any reason it will repeat the instruction so we have to check both edges of the clock
	-- in order to make sure it saves and doesn't repeat the instruction twice.
	
   -- BEGIN PROCESS
	begin -- store data
	if(rising_edge(clock)) then
	  if(reset = '1') then
		  --reset the program counter
      reg(15) <= to_unsigned(0, 32);
    end if;
			--increment the PC if not in resest
		if((not falling_edge(stall))) then
		   address <= std_logic_vector(reg(15));
		end if;
		if(flush = '1') then
		  flush <= '0';
		end if;
		if(STALL = '1') THEN
		  stall <= '0';
    else 
	     address <= std_logic_vector(reg(15));	
	     stallHappened <= '0';
		end if;
    if(reset = '0' and not falling_edge(stall)) then
      reg(15) <= reg(15) + 2; 
    end if;
    if(ram_wren = '1') then
      ram_wren <= '0';
    end if;
  end if;
	
	if(falling_edge(clock)) then
	 if(stall = '1' and flush = '1') then
	   -- Flush clears out pipeline
	 elsif(stall = '1') then -- just stall
	   address <=  std_logic_vector(unsigned(address) - 4); -- Shift To previous Cycle before stall
	   reg(15) <= reg(15) - 4; -- shift to previous cycle before stall
	   stallHappened <= '1';
   end if;
	end if;
	
  if ( bl_var(11) = '1') then -- bl second part
		BL16( instruction );
	elsif (rising_edge(clock)) then
		case? instruction(15 downto 10) is
			-- SHIFT(immediate), ADD, SUBTRACT, MOVE, and COMPARE
			when "00----" =>
				case? instruction(13 downto 9) is
					when "000--" =>							
						-- LSL (imm5)
						LSL16(to_integer(instruction(2 downto 0)),		-- Rd
								to_integer(instruction(5 downto 3)),	   -- Rm
								to_integer(instruction(10 downto 6))); 	-- imm5
					when "001--" =>
						-- LSR (imm5)
						LSR16(to_integer(instruction(2 downto 0)), 		-- Rd
								to_integer(instruction(5 downto 3)),	   -- Rm
								to_integer(instruction(10 downto 6)));	  	-- imm5
					when "010--" =>
						-- ASR (imm5)
						ASR16(to_integer(instruction(2 downto 0)), 		-- Rd
								to_integer(instruction(5 downto 3)),	 	-- Rm
								to_integer(instruction(10 downto 6)));	   -- imm5
					when "01100" =>
						-- ADD (reg)
						ADD16(to_integer(instruction(2 downto 0)),								-- Rd
								to_integer(instruction(5 downto 3)),								-- Rn
								(reg(to_integer(instruction(8 downto 6))))); --regField(Rm)
					when "01110" =>
						-- ADD (imm3)
						ADD16(to_integer(instruction(2 downto 0)),		-- Rd
								to_integer(instruction(5 downto 3)),		-- Rn
								(instruction(8 downto 6)));		-- imm3
					when "100--" =>
						-- MOV (imm8) proc
						MOV16(to_integer(instruction(10 downto 8)), resize(instruction(7 downto 0), 32));
					when "110--" =>
						-- ADD (imm8)
						ADD16(to_integer(instruction(10 downto 8)),		-- Rdn
								to_integer(instruction(10 downto 8)),		-- Rdn
								(instruction(7 downto 0)));		-- imm8
					when "101--" =>
					  -- CMP (imm8)
					  CMP16(reg(to_integer(instruction(10 downto 8))),
					        resize(instruction(7 downto 0),32));
					when "01111" =>
					  -- Temp Subtract
					  reg(to_integer(instruction(2 downto 0))) <= reg((to_integer(instruction(5 downto 3)))) - instruction(8 downto 6);
					when others =>
						null;
				end case?;
			-- DATA PROCESSING
			when "010000" =>
				case? instruction(9 downto 6) is
					when "0000" =>
						-- AND
						AND16(to_integer(instruction(2 downto 0)),		-- Rd
								to_integer(instruction(5 downto 3)));		-- Rm
					when "0001" =>
						-- EOR
						EOR16(to_integer(instruction(2 downto 0)),		-- Rd
								to_integer(instruction(5 downto 3)));		-- Rm
					when "0010" =>
						-- LSL (reg)
						if(reg(to_integer(instruction(5 downto 3))) > 32) then -- shift of 32 or greater is the same op
						  LSL16(to_integer(instruction(2 downto 0)),								-- Rdn
								    to_integer(instruction(2 downto 0)),								-- Rdn
								    32);
						else
						  LSL16(to_integer(instruction(2 downto 0)),								-- Rdn
								    to_integer(instruction(2 downto 0)),								-- Rdn
								    to_integer(reg(to_integer(instruction(5 downto 3)))));	-- regField(Rm)
						end if;
					when "0011" =>
						-- LSR (reg)
						if(reg(to_integer(instruction(5 downto 3))) > 32) then -- shift of 32 or greater is the same op
						  LSR16(to_integer(instruction(2 downto 0)),				-- Rdn
								    to_integer(instruction(2 downto 0)),								-- Rdn
								    32);
						else
						  LSR16(to_integer(instruction(2 downto 0)),								-- Rdn
								    to_integer(instruction(2 downto 0)),								-- Rdn
								    to_integer(reg(to_integer(instruction(5 downto 3)))));	-- regField(Rm)
						end if;
					when "0100" =>
						-- ASR (reg)
						if(reg(to_integer(instruction(5 downto 3))) > 32) then -- shift of 32 or greater is the same op
						  ASR16(to_integer(instruction(2 downto 0)),								-- Rdn
								    to_integer(instruction(2 downto 0)),								-- Rdn
								    32);
						else
						  ASR16(to_integer(instruction(2 downto 0)),								-- Rdn
								    to_integer(instruction(2 downto 0)),								-- Rdn
								    to_integer(reg(to_integer(instruction(5 downto 3)))));	-- regField(Rm)
					  end if;
					when "0101" =>
						-- ADC
						ADC16(to_integer(instruction(2 downto 0)),								-- Rd
								to_integer(instruction(5 downto 3)));								-- Rm
					when "0110" =>
						-- SBC
						ADC16(to_integer(instruction(2 downto 0)),								-- Rd
								to_integer(instruction(5 downto 3)));								-- Rm
					when "0111" =>
						-- ROR
						ROR16(to_integer(instruction(2 downto 0)),								-- Rdn
								to_integer(instruction(2 downto 0)),								-- Rdn
								to_integer(reg(to_integer(instruction(5 downto 3)))(4 downto 0)));	-- regField(Rm)(4 downto 0)
					when "1100" =>
						-- ORR
						ORR16(to_integer(instruction(2 downto 0)),		-- Rd
								to_integer(instruction(5 downto 3)));		-- Rm
					when "1110" =>
						-- BIC
						BIC16(to_integer(instruction(2 downto 0)),		-- Rd
								to_integer(instruction(5 downto 3)));		-- Rm
					when "1111" =>
						-- MVN
						MVN16(to_integer(instruction(2 downto 0)),		-- Rd
								to_integer(instruction(5 downto 3)));		-- Rm
					when "1011" =>
					  CMN16(reg(to_integer(instruction(5 downto 3))), 
					     	reg(to_integer(instruction(2 downto 0))));
					when "1010" =>
					  -- CMP (REG)
					  CMP16(reg(to_integer(instruction(5 downto 3))),
					       reg(to_integer(instruction(2 downto 0))));
					when "1000" =>
					  -- TST
					  TST16(reg(to_integer(instruction(5 downto 3))),
					       reg(to_integer(instruction(2 downto 0))));

					when "1001" =>
						-- NEG || RSB
						NEG16(to_integer(instruction(2 downto 0)),
					        to_integer(instruction(5 downto 3)));
					when "1101" =>
						-- MUL
						MUL16(to_integer(instruction(2 downto 0)),
					        to_integer(instruction(5 downto 3)));

					when others =>
						null;
				end case?;
			-- SPECIAL DATA, BRANCH, and EXCHANGE
			when "010001" =>
				case? instruction(9 downto 6) is
					when "00--" =>
						-- ADD(dn)
						ADD16(to_integer(instruction(7) & instruction(2 downto 0)),		-- Rdn
								to_integer(instruction(7) & instruction(2 downto 0)),		-- Rdn
								(reg(to_integer(instruction(6 downto 3)))));		-- Rm
					when "10--" =>
						-- MOV(reg)
						MOV16(to_integer(instruction(7) & instruction(2 downto 0)), 
						  reg(to_integer(instruction(6 downto 3))));
					when "110-" =>
						-- BX
						BX16(to_integer(instruction(6 downto 3)));
					when "1110" =>
						-- BLX
						BLX16(to_integer(instruction(6 downto 3)));
					when "0101" =>
					  -- CMP (Extend)
					  CMP16(reg(to_integer(instruction(6 downto 3))),
					        reg(to_integer(instruction(7) & instruction(2 downto 0))));
					when "011-" =>
					  -- CMP (Extend)
					  CMP16(reg(to_integer(instruction(6 downto 3))),
					        reg(to_integer(instruction(7) & instruction(2 downto 0))));
					when others =>
						null;
				end case?;
			-- MISCELLANEOUS
			when "1011--" =>
				case? instruction(11 downto 5) is
				  when "1111000" =>
				    -- NOP
				    null;
					when "00000--" =>
						-- ADD(SP+imm7)
						ADD16S(13,												-- SP
								13,												--	SP
								to_integer(instruction(6 downto 0)));  -- imm7
					when "001011-" =>
					  -- UXTB
					  UXTB16( to_integer(instruction(5 downto 3)),
					          to_integer(instruction(2 downto 0)));
					when "001010-" =>
					  -- UXTH
					  UXTH16( to_integer(instruction(5 downto 3)),
					          to_integer(instruction(2 downto 0)));
					when "001001-" =>
					  -- SXTB
					  SXTB16( to_integer(instruction(5 downto 3)),
					          to_integer(instruction(2 downto 0)));					
					when "001000-" =>
					  -- SXTH
					  SXTH16( to_integer(instruction(5 downto 3)),
					          to_integer(instruction(2 downto 0)));
					when others =>
						null;
				end case?;
			when "10101-" =>
				-- ADD(SP+imm8)
				ADD16S(to_integer(instruction(10 downto 8)),			-- Rd
						13,														-- SP
						to_integer(instruction(7 downto 0)));			-- imm8
			when "10100-" =>
			  -- Generate PC Relative Address ADR(PC+Imm8<<2)
			  ADD16S(to_integer(instruction(10 downto 8)),			-- Rd
					  15,														-- PC
						(to_integer(instruction(7 downto 0) sll 2) ));			-- imm8
			when "11100-" =>
			-- Unconditional Branch
			  b16( instruction(10 downto 0));
			when "11110-" => 
				bl_var(11) := '1';
				bl_var(10 downto 0) := instruction(10 downto 0); 
				reg(14) <= "000000000000000000000" & instruction(10 downto 0);
		  when "1101--" => 
			   Case instruction(11 downto 8) is
			     --EQ
			     when "0000" =>
			       if(statusRegisters(2) = '1' ) then
			         conCat := ("111" & instruction(7 downto 0)) when instruction(7) = '1' else ("000" & instruction(7 downto 0));
			         b16(conCat);
			       end if;
			       
			     --NE
			     when "0001" =>
			       if(statusRegisters(2) = '0' ) then
			         conCat := ("111" & instruction(7 downto 0)) when instruction(7) = '1' else ("000" & instruction(7 downto 0));
			         b16(conCat);
			       end if;
			     
			     --CS
			     when "0010" =>
			       if(statusRegisters(3) = '1' ) then
			         conCat := ("111" & instruction(7 downto 0)) when instruction(7) = '1' else ("000" & instruction(7 downto 0));
			         b16(conCat);
			       end if;
			     --CC
			     when "0011" =>
			       if(statusRegisters(3) = '0' ) then
			         conCat := ("111" & instruction(7 downto 0)) when instruction(7) = '1' else ("000" & instruction(7 downto 0));
			         b16(conCat);
			       end if;
			     --MI
			     when "0100" =>
			       if(statusRegisters(1) = '1' ) then
			         conCat := ("111" & instruction(7 downto 0)) when instruction(7) = '1' else ("000" & instruction(7 downto 0));
			         b16(conCat);
			       end if;
			       
			     --PL
			     when "0101" => 
			       if(statusRegisters(1) = '0' ) then
			         conCat := ("111" & instruction(7 downto 0)) when instruction(7) = '1' else ("000" & instruction(7 downto 0));
			         b16(conCat);
			       end if;
			       
			     when others => --Note valide condition
			   end case;
			when "01101-" => 
			-- LDR Rd = [Rm + #Imm5<<2]
			  ram_offset := resize(instruction(10 downto 6), 32) sll 2;
			  LDR16(to_integer(instruction(2 downto 0)),      -- Rd (dest)
			        reg(to_integer(instruction(5 downto 3))), -- Rm (src)
			        ram_offset);                              -- Imm5<<2 (offset)
			when "01100-" => 
			-- STR [Rn+#Imm5<<2] = Rt
			  ram_offset := resize(instruction(10 downto 6), 32) sll 2;
			  STR16(reg(to_integer(instruction(5 downto 3))),  -- Rn (src)
			        ram_offset,                                -- Imm5<<2 (offset)
			        reg(to_integer(instruction(2 downto 0)))); -- Rt (value)
			when "010110" => 
			-- LDR Rt = [Rn + Rm]
			  LDR16(to_integer(instruction(2 downto 0)),       -- Rt (dest)
			        reg(to_integer(instruction(5 downto 3))),  -- Rn (src)
			        reg(to_integer(instruction(8 downto 6)))); -- Rm (offset)
			when "010100" => 
			-- STR [Rm+Rn] = Rt
			  STR16(reg(to_integer(instruction(8 downto 6))),  -- Rm (src)
			        reg(to_integer(instruction(5 downto 3))),  -- Rn (offset)
			        reg(to_integer(instruction(2 downto 0)))); -- Rt (value)
			when others => -- Start will be all uuuu's report "Bad Instruction" severity ERROR;
		end case?;	
	 end if;
	end process;
	

	
end integer_unit;
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
			  reset : in std_logic);
end integer_unit;

architecture integer_unit of integer_unit is
  type register_file_t is array(0 to 15) of unsigned(31 downto 0);
	signal reg : register_file_t := (others => (others => '0'));
	signal statusRegisters : unsigned(3 downto 0) := to_unsigned(0, 4);
	signal instruction : unsigned(15 downto 0); 
begin
  instruction <= (instructionTemp and not (stall or reset));
    
	process(instruction, clock)
		-- variables
		variable bl_var: unsigned ( 11 downto 0 );
	 
		-- PROCEDURES HERE
		
		----[ LSL ]
		procedure LSL16(dest, src : integer range 0 to 15;
							 n : integer range 0 to 31) is
		begin
			reg(dest) <= reg(src) sll n;
		end LSL16;
		
		----[ LSR ]
		procedure LSR16(dest, src : integer range 0 to 15; 
							 n : integer range 0 to 31) is
		begin
			reg(dest) <= reg(src) srl n;
		end LSR16;
		
		----[ ASR ]
		procedure ASR16(dest, src : integer range 0 to 15;
							 n : integer range 0 to 31) is
		begin
			reg(dest) <= unsigned(to_stdlogicvector(to_bitvector(std_logic_vector(reg(src))) sra n));
		end ASR16;
		
		----[ ROR ]
		procedure ROR16(dest, src : integer range 0 to 15; 
							 n : integer range 0 to 31) is
		begin
			reg(dest) <= reg(src) ror n;
		end ROR16;
    
		----[ MOV ]
		procedure MOV16(dest : integer range 0 to 15;
                    src : in unsigned) is 
		begin
			reg(dest) <= src;
		end MOV16; 
		
		----[ ADC ]
		procedure ADC16( dest, src : integer range 0 to 7) is
		variable temp : unsigned(32 downto 0) := to_unsigned(0, 33);
		begin
		  temp := resize(reg(src), 33) + resize(reg(dest), 33) + resize(statusRegisters srl 3, 33);
			reg(dest) <= temp(31 downto 0);
			statusRegisters(3) <= temp(32);
		end ADC16;
		
		----[ ADD ]
		procedure ADD16( dest, src : integer range 0 to 15;
							  n : unsigned) is
		variable temp : unsigned(32 downto 0) := to_unsigned(0, 33);
		begin
			temp := resize(reg(src), 33) + resize(n, 33);
			reg(dest) <= temp(31 downto 0);
			statusRegisters(3) <= temp(32);
		end ADD16;
		
		-- [ ADD ] Stack/ADR Pointer does not update flags
		procedure ADD16S( dest, src : integer range 0 to 15;
							  n : integer range 0 to 255) is
		begin
			reg(dest) <= reg(src) + to_unsigned(n, 32);
		end ADD16S;
		
		----[ AND ]
		procedure AND16( dest, src : integer range 0 to 15) is
		begin
			reg(dest) <= reg(dest) and reg(src);
		end AND16;

		----[ BIC ]
		procedure BIC16( dest, src : integer range 0 to 15) is
		begin
			reg(dest) <= reg(dest) and not reg(src);
		end BIC16;

		----[ EOR ]
		procedure EOR16( dest, src : integer range 0 to 15) is
		begin
			reg(dest) <= reg(dest) xor reg(src);
		end EOR16;

		----[ MVN ]
		procedure MVN16( dest, src : integer range 0 to 15) is
		begin
			reg(dest) <= not reg(src);
		end MVN16;

		----[ ORR ]
		procedure ORR16( dest, src : integer range 0 to 15) is
		begin
			reg(dest) <= reg(dest) or reg(src);
		end ORR16;
		
		----[ B ]
		procedure B16( inst : unsigned( 10 downto 0 )) is
		begin
		  
			if(inst(10) = '1') then
				reg(15) <= reg(15) - inst( 9 downto 0 ) - "00000000000000000000000000000110";
			else
				reg(15) <= reg(15) + inst( 9 downto 0 ) - "00000000000000000000000000000110";
			end if;
			stall <= '1';
		end B16;
		
		----[ BX ]
		procedure BX16( src : integer range 0 to 15 ) is
		begin
			reg(15) <= reg(src);
			stall <= '1';
		end BX16;
		
		----[ BLX ]
		procedure BLX16( src : integer range 0 to 15 ) is
		begin
			reg(14) <= reg(15) - "00000000000000000000000000000100";
			reg(15) <= reg(src);
			stall <= '1';
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
		end BL16;
		
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
		if(STALL = '1') THEN
		  stall <= '0';
		else 
		   address <= std_logic_vector(reg(15));
		end if;
    if(reset = '0' and stall = '0') then
      reg(15) <= reg(15) + 2; 
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
						LSL16(to_integer(instruction(2 downto 0)),								-- Rdn
								to_integer(instruction(2 downto 0)),								-- Rdn
								to_integer(reg(to_integer(instruction(5 downto 3)))));	-- regField(Rm)
					when "0011" =>
						-- LSR (reg)
						LSR16(to_integer(instruction(2 downto 0)),								-- Rdn
								to_integer(instruction(2 downto 0)),								-- Rdn
								to_integer(reg(to_integer(instruction(5 downto 3)))));	-- regField(Rm)
					when "0100" =>
						-- ASR (reg)
						ASR16(to_integer(instruction(2 downto 0)),								-- Rdn
								to_integer(instruction(2 downto 0)),								-- Rdn
								to_integer(reg(to_integer(instruction(5 downto 3)))));	-- regField(Rm)
					when "0101" =>
						-- ADC
						ADC16(to_integer(instruction(2 downto 0)),								-- Rd
								to_integer(instruction(5 downto 3)));								-- Rm
					when "0111" =>
						-- ROR
						ROR16(to_integer(instruction(2 downto 0)),								-- Rdn
								to_integer(instruction(2 downto 0)),								-- Rdn
								to_integer(reg(to_integer(instruction(5 downto 3)))));	-- regField(Rm)
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
			when others => -- Start will be all uuuu's report "Bad Instruction" severity ERROR;
		end case?;	
	 end if;
	end process;
	

	
end integer_unit;
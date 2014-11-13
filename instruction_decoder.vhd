-- Tyler McGrew, Louis Coyle, Cody Harris
-- ECE 399
-- First Group Assignment	

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity instruction_decoder is
	port( clock: in std_logic;
	      instruction: in unsigned( 15 downto 0 ) );
end instruction_decoder;

architecture id of instruction_decoder is 

type regs is array( 15 downto 0 ) of unsigned( 31 downto 0 );

signal registers: regs;

signal c : std_logic;

signal nothing: unsigned(1 downto 0) := "00";

signal one: unsigned( 31 downto 0 ) := "00000000000000000000000000000001";

begin	

  process(clock)
    variable rd, rn, rm, temp: integer;
    variable sum : unsigned (32 downto 0);
    variable other_temp: unsigned( 31 downto 0 );
  begin
    temp := to_integer( registers( to_integer( instruction( 5 downto 3 ) ) ) - 1 );
    other_temp := ( one sll temp );
    if( rising_edge( clock ) ) then
	    case? instruction is 
		  when "0100000000------" => -- AND
			   registers( to_integer( instruction( 2 downto 0 ) ) ) <= 
				  registers( to_integer( instruction( 5 downto 3 ) ) ) and 
				  registers( to_integer( instruction( 2 downto 0 ) ) );
		  when "0100001110------" => -- BIC
			   registers( to_integer( instruction( 2 downto 0 ) ) ) <= 
				  ( registers( to_integer( instruction( 2 downto 0 ) ) ) and ( not other_temp ) );
		  when "0100000001------" => -- EOR
			   registers( to_integer( instruction( 2 downto 0 ) ) ) <= 
				  registers( to_integer( instruction( 5 downto 3 ) ) ) xor 
				  registers( to_integer( instruction( 2 downto 0 ) ) );
		  when "0100001111------" => -- MVN
			   registers( to_integer( instruction( 2 downto 0 ) ) ) <= 
				  not registers( to_integer( instruction( 5 downto 3 ) ) );
		  when "0100001100------" => -- ORR
			   registers( to_integer( instruction( 2 downto 0 ) ) ) <= 
				  registers( to_integer( instruction( 5 downto 3 ) ) ) or 
				  registers( to_integer( instruction( 2 downto 0 ) ) );
		  when others =>
			   nothing <= nothing + 1;
	    end case?;
	end if;
	
  if(rising_edge(clock)) then
    case? instruction(15 downto 8) is
        
       when "01000001" => -- ADC rd, rm, c
          rd := to_integer(instruction(2 downto 0));
          rm := to_integer(instruction(5 downto 3));
          sum := "0" & registers(rd) + registers(rm) + c;
          c <= sum(32);
          registers(rd) <= resize(sum, 32);

        when "0001110-" => -- ADD rd, rn, Imm3
          rd := to_integer(instruction(2 downto 0));
          rn := to_integer(instruction(5 downto 3));
          sum := "0" & registers(rn) + instruction(8  downto 6);
          c <= sum(32);
          registers(rd) <= resize(sum, 32);

        when "00110---" => -- ADD rd, Imm8
          rd := to_integer(instruction(10 downto 8));
          sum := "0" & registers(rd) + instruction(7 downto 0);
          c <= sum(32);
          registers(rd) <= resize(sum, 32);

        when "0001100-" => -- ADD rd, rn, rm
          rd := to_integer(instruction(2 downto 0));
          rn := to_integer(instruction(5 downto 3));
          rm := to_integer(instruction(8 downto 6));
          sum := "0" & registers(rn) + registers(rm);
          c <= sum(32);
          registers(rd) <= resize(sum, 32);

        when "10101---" => -- ADD rd, SP, Imm8
          -- no status flag update
          rd := to_integer(instruction(10 downto 8));
          registers(rd) <= registers(13) + instruction(7 downto 0);

        when "10110000" => -- ADD SP, Imm7
          -- no status flag update
          registers(13) <= registers(13) + instruction(6 downto 0);

        when "01000100" => -- ADD dn, rd, SP & ADD dn, rd, SP & ADD SP, rm
          -- no status flag update
          rd := to_integer(instruction(7) & instruction (2 downto 0));
          rm := to_integer(instruction(6 downto 3));
          registers(rd) <= registers(rd) + registers(rm);

        when "00100---" => -- MOV rd, Imm8
          rd := to_integer(instruction(10 downto 8));
          registers(rd) <= resize(instruction(7 downto 0), 32);
        when "01000110" => -- MOV rd, rn
          rd := to_integer(instruction(7) & instruction(2 downto 0));
          rn := to_integer(instruction(6 downto 3));
          registers(rd) <= registers(rn);
        when others => null;
        end case?;
      end if;
    
    if(rising_edge(clock)) then
	       case? instruction(15 downto 6) is 
				
				--ASR  Rd = Rm>>#Imm5
		        when "00010-----" => registers(to_integer(instruction(2 downto 0))) <= registers(to_integer(instruction(5 downto 3))) sra to_integer(instruction(11 downto 6));
				
				--ASR Rd = Rd>>Rm
				    when "0100000100" => registers(to_integer(instruction(2 downto 0))) <= registers(to_integer(instruction(2 downto 0))) sra  to_integer(registers(to_integer(instruction(5 downto 3))));
			         
				--LSL Rd = Rd<<Rm
		        when "0100000010" => registers(to_integer(instruction(2 downto 0))) <= registers(to_integer(instruction(2 downto 0))) sll  to_integer(registers(to_integer(instruction(5 downto 3))));
			            
				--LSR Rd = Rd>>Rm
		        when "0100000011" => registers(to_integer(instruction(2 downto 0))) <= registers(to_integer(instruction(2 downto 0))) srl  to_integer(registers(to_integer(instruction(5 downto 3))));
			     
				--ROR Rd = Rd:Rd>>Rm
		        when "0100000111" => registers(to_integer(instruction(2 downto 0))) <= registers(to_integer(instruction(2 downto 0))) ror  to_integer(registers(to_integer(instruction(5 downto 3))));
		           
				--LSL Rd = Rm<<#Imm5
		        when "00000-----" => registers(to_integer(instruction(2 downto 0))) <= registers(to_integer(instruction(5 downto 3))) sll  to_integer(instruction(10 downto 6));
		             
				--LSR Rd = Rm>>#Imm5
		        when "00001-----" => registers(to_integer(instruction(2 downto 0))) <= registers(to_integer(instruction(5 downto 3))) srl  to_integer(instruction(10 downto 6));
		        
				--Dont Do anything
		        when others => 
			          null;
	       end case?;
	   end if;
	 end process;
	 
end id;
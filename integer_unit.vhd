-- ARM Thumb processor example
-- (C) Digipen 2014 - ECE 399

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity integer_unit is
    port (clock: in std_logic;
        instruction: in unsigned(15 downto 0) );
end integer_unit;

architecture iu of integer_unit is
  type register_file_t is array(0 to 15) of unsigned(31 downto 0);
  signal reg: register_file_t;
begin
    process(clock)
      variable rd, rn: integer;
    begin
      if(rising_edge(clock)) then
        case? instruction(15 downto 8) is
        when "0001110-" => -- ADD rd, rn, Imm3
          rd := to_integer(instruction(2 downto 0));
          rn := to_integer(instruction(5 downto 3));
          reg(rd) <= reg(rn) + instruction(8  downto 6);
        when  "00100---" => -- MOV rd, Imm8
          rd := to_integer(instruction(10 downto 8));
          reg(rd) <= resize(instruction(7 downto 0), 32);
        when "01000110" => -- MOV rd, rn
          rd := to_integer(instruction(7) & instruction(2 downto 0));
          rn := to_integer(instruction(6 downto 3));
          reg(rd) <= reg(rn);
        when others => report "Bad Instruction" severity ERROR;
        end case?;
      end if;
    end process;
end iu;

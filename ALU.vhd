LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.math_real.all;

ENTITY ALU IS
GENERIC(
WIDTH : NATURAL := 32);
PORT(
a_i : in STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --prvi operand
b_i : in STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --drugi operand
op_i : in STD_LOGIC_VECTOR(4 DOWNTO 0); --port za izbor operacije
res_o : out STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0) --rezultat
);
end ALU;

--sw, lw i addi add => op_i=00010 
--sub => op_i=00110
--and => op_i=00000
--or => op_i=00001

architecture Behavioral of ALU is

begin

process(a_i, b_i, op_i) is
begin
    case(op_i) is
        when "00000" =>
            res_o <= a_i and b_i;
        when "00001" =>
            res_o <= a_i or b_i;
        when "00110" =>
            res_o <= std_logic_vector(unsigned(a_i) - unsigned(b_i));
        when "00010" =>
            res_o <= std_logic_vector(unsigned(a_i) + unsigned(b_i));
        when others =>
            res_o <= (others=>'0');
    end case;
end process;

end Behavioral;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity immediate is
port (
instruction_i : in std_logic_vector (31 downto 0);
immediate_extended_o : out std_logic_vector (31 downto 0)
);
end entity;
 
architecture Behavioral of immediate is
 
--type instruct is (I_typei, I_typel, S_type, R_type, B_type); --I typei: addi
                                                             --I typel: lw
                                                             --S type: sw
                                                             --R type: add, sub, and, or
                                                             --B type: beq
--attribute enum_encoding: string;
--attribute enum_encoding of instruct: type is "0010011 0000011 0100011 0110011 1100011";
 
begin

immediate_extended_o(31 downto 12) <= std_logic_vector(to_unsigned(1, 20)) when instruction_i(31)='1' else
                                      std_logic_vector(to_unsigned(0, 20));

IMM: process(instruction_i)
begin
    
    case (instruction_i(6 downto 0)) is
        when "0010011"|"0000011" => --addi lw
            immediate_extended_o(11 downto 0) <= instruction_i(31 downto 20);
        when "0100011" => --sw
            immediate_extended_o(11 downto 0) <= instruction_i(31 downto 25)&instruction_i(11 downto 7);
        when "1100011" => --beq
            immediate_extended_o(11 downto 0) <= instruction_i(31)&instruction_i(7)&instruction_i(30 downto 25)&instruction_i(11 downto 8);
        when others =>
            immediate_extended_o <= (others => '0');
    end case;
end process;

end Behavioral;


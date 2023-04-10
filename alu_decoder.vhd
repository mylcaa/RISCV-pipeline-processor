library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity alu_decoder is
port (
--******** Controlpath ulazi *********
alu_2bit_op_i : in std_logic_vector(1 downto 0);
--******** Polja instrukcije *******
funct3_i : in std_logic_vector (2 downto 0);
funct7_i : in std_logic_vector (6 downto 0);
--******** Datapath izlazi ********
alu_op_o : out std_logic_vector(4 downto 0));
end entity;


architecture Behavioral of alu_decoder is
signal funct10_i: std_logic_vector(9 downto 0);

begin

funct10_i <= funct7_i & funct3_i;

process(alu_2bit_op_i, funct10_i) is
begin
    if(alu_2bit_op_i="11") then --lw sw addi
        alu_op_o <= "00010";
    elsif(alu_2bit_op_i="10") then                      --10 za R instrukcije 
        if(funct10_i="0000000000") then    --sabiranje
            alu_op_o <= "00010";
        elsif(funct10_i="0100000000") then --oduzimanje
            alu_op_o <= "00110";
        elsif(funct10_i="0000000111") then  --and
            alu_op_o <= "00000";
        else                                --or 0000000110
            alu_op_o <= "00001";
        end if;
    else                                    --01 beq kod koga alu ne treba nista da radi i 00 kod others tj nemamo instrukciju
        alu_op_o <= "11111";
    end if;
end process;

end Behavioral;
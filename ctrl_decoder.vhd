library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity ctrl_decoder is
port (
-- opcode instrukcije
opcode_i : in std_logic_vector (6 downto 0);
-- kontrolni signali
branch_o : out std_logic;                       --ako imamo beq
mem_to_reg_o : out std_logic;                   --upis iz mem u reg banku
data_mem_we_o : out std_logic;                  --dozvola upisa u DM
alu_src_b_o : out std_logic;                    --da li je R tip ili I tip lw sw
rd_we_o : out std_logic;                        --dozvola upisa u registarsku banku
rs1_in_use_o : out std_logic;                   --koristi se rs1
rs2_in_use_o : out std_logic;                   --koristi se rs2
alu_2bit_op_o : out std_logic_vector(1 downto 0);--za ALU decoder
--JALR:
jalr_o: out std_logic  
);
end entity;

--addi op 0010011 
--lw op 0000011
--sw op 0100011
--R type op 0110011
--beq op 1100011
--jalr op 1100111

architecture Behavioral of ctrl_decoder is

begin

process(opcode_i) is
begin
    case (opcode_i) is
        when "0110011" => --R type
            branch_o <= '0';
            mem_to_reg_o <= '0';
            data_mem_we_o <= '0';
            alu_src_b_o <= '0';
            rd_we_o <= '1';
            rs1_in_use_o <= '1';
            rs2_in_use_o <= '1';
            alu_2bit_op_o <= "10";
            jalr_o <= '0';
        when "0010011" => --addi 0010011
            branch_o <= '0';
            mem_to_reg_o <= '0';
            data_mem_we_o <= '0';
            alu_src_b_o <= '1';
            rd_we_o <= '1';
            rs1_in_use_o <= '1';
            rs2_in_use_o <= '0';
            alu_2bit_op_o <= "11"; --hocu da vrsi sabiranje a ne oduzimanje kao u pdfu
            jalr_o <= '0';
        when "0000011" => --lw
            branch_o <= '0';
            mem_to_reg_o <= '1';
            data_mem_we_o <= '0';
            alu_src_b_o <= '1';
            rd_we_o <= '1';
            rs1_in_use_o <= '1';
            rs2_in_use_o <= '0';
            alu_2bit_op_o <= "11";
            jalr_o <= '0';
        when "0100011" => --sw
            branch_o <= '0';
            mem_to_reg_o <= '0';
            data_mem_we_o <= '1';
            alu_src_b_o <= '1';
            rd_we_o <= '0';
            rs1_in_use_o <= '1';
            rs2_in_use_o <= '1';
            alu_2bit_op_o <= "11";
            jalr_o <= '0';
        when "1100011" => --beq
            branch_o <= '1';
            mem_to_reg_o <= '0';
            data_mem_we_o <= '0';
            alu_src_b_o <= '0';
            rd_we_o <= '0';
            rs1_in_use_o <= '1';
            rs2_in_use_o <= '1';
            alu_2bit_op_o <= "01";
            jalr_o <= '0';
        when "1100111" => --jalr
            branch_o <= '0';
            mem_to_reg_o <= '0';
            data_mem_we_o <= '0';
            alu_src_b_o <= '1';
            rd_we_o <= '1';
            rs1_in_use_o <= '1';
            rs2_in_use_o <= '0';
            alu_2bit_op_o <= "11";
            jalr_o <= '1';
        when others => 
            branch_o <= '0';
            mem_to_reg_o <= '0';
            data_mem_we_o <= '0';
            alu_src_b_o <= '0';
            rd_we_o <= '0';
            rs1_in_use_o <= '0';
            rs2_in_use_o <= '0';
            alu_2bit_op_o <= "00";
            jalr_o <= '0';
    end case;
end process;

end Behavioral;

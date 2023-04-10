library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_unit is
port (
-- ulazni signali
rs1_address_id_i : in std_logic_vector(4 downto 0);
rs2_address_id_i : in std_logic_vector(4 downto 0);
rs1_in_use_i : in std_logic;
rs2_in_use_i : in std_logic;
branch_id_i : in std_logic;
rd_address_ex_i : in std_logic_vector(4 downto 0);
mem_to_reg_ex_i : in std_logic;
rd_we_ex_i : in std_logic;
rd_address_mem_i : in std_logic_vector(4 downto 0);
mem_to_reg_mem_i : in std_logic;
-- izlazni kontrolni signali
-- pc_en_o je signal dozvole rada za pc registar
pc_en_o : out std_logic;
-- if_id_en_o je signal dozvole rada za if/id registar
if_id_en_o : out std_logic;
-- control_pass_o kontrolise da li ce u execute fazu biti prosledjeni
-- kontrolni signali iz ctrl_decoder-a ili sve nule
control_pass_o : out std_logic
);
end entity;

architecture Behavioral of hazard_unit is

begin

process(rs1_address_id_i, rs2_address_id_i, rs1_in_use_i, rs2_in_use_i, branch_id_i, rd_address_ex_i, mem_to_reg_ex_i, rd_we_ex_i, rd_address_mem_i, mem_to_reg_mem_i) is
begin

control_pass_o <= '1';
if_id_en_o <= '1';
pc_en_o <= '1';

if(branch_id_i='0') then --instrukcija u id nije beq
    if(((rs1_address_id_i=rd_address_ex_i and rs1_in_use_i='1') or (rs2_address_id_i=rd_address_ex_i and rs2_in_use_i='1')) and (mem_to_reg_ex_i='1' and rd_we_ex_i='1')) then --lw je ispred garant
        control_pass_o <= '0';
        if_id_en_o <= '0';
        pc_en_o <= '0';
    end if;
elsif(branch_id_i='1') then --instrukcija u id je beq
    if((rs1_address_id_i=rd_address_ex_i or rs2_address_id_i=rd_address_ex_i) and (rd_we_ex_i='1')) then --lw ili R ili I tip instrukcije je ispred beq
        control_pass_o <= '0';
        if_id_en_o <= '0';
        pc_en_o <= '0';
    elsif((rs1_address_id_i=rd_address_mem_i or rs2_address_id_i=rd_address_mem_i) and (mem_to_reg_mem_i='1')) then --lw u mem fazi prije beq -> treba drugi stall
        control_pass_o <= '0';
        if_id_en_o <= '0';
        pc_en_o <= '0';
    end if;
end if;
end process;

end Behavioral;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity TOP_RISCV is
port(
-- Globalna sinhronizacija
clk : in std_logic;
reset : in std_logic;
-- Interfejs ka memoriji za podatke
instr_mem_read_i : in std_logic_vector(31 downto 0);
instr_mem_address_o : out std_logic_vector(31 downto 0);
-- Interfejs ka memoriji za instrukcije
data_mem_we_o: out std_logic_vector(3 downto 0);
data_mem_address_o: out std_logic_vector(31 downto 0);
data_mem_read_i: in std_logic_vector(31 downto 0);
data_mem_write_o: out std_logic_vector(31 downto 0)
);
end entity;

architecture Behavioral of TOP_RISCV is

signal instruction_s: std_logic_vector(31 downto 0);
signal jalr_s, if_id_s, pc_en_s, if_id_flush_s, branch_forward_a_s, branch_forward_b_s, branch_condition_s, mem_to_reg_s, alu_src_s, rd_we_i_s: std_logic;
signal alu_op_s: std_logic_vector(4 downto 0);
signal alu_forward_a_s, alu_forward_b_s, pc_next_sel_s: std_logic_vector(1 downto 0); --IZMJENAAAA

begin

DATA_PATH: entity work.data_path
port map(
-- sinhronizacioni signali
clk => clk,
reset => reset,
-- interfejs ka memoriji za instrukcije
instr_mem_address_o => instr_mem_address_o,
instr_mem_read_i =>instr_mem_read_i,
instruction_o => instruction_s,
-- interfejs ka memoriji za podatke
data_mem_address_o => data_mem_address_o,
data_mem_write_o => data_mem_write_o,
data_mem_read_i => data_mem_read_i,
-- kontrolni signali
mem_to_reg_i => mem_to_reg_s,
alu_op_i => alu_op_s,
alu_src_b_i => alu_src_s,
pc_next_sel_i => pc_next_sel_s,
rd_we_i => rd_we_i_s,
branch_condition_o => branch_condition_s,
jalr_i => jalr_s,
-- kontrolni signali za prosledjivanje operanada u ranije faze protocne
--obrade
alu_forward_a_i => alu_forward_a_s,
alu_forward_b_i => alu_forward_b_s,
branch_forward_a_i => branch_forward_a_s,
branch_forward_b_i => branch_forward_b_s,
-- kontrolni signal za resetovanje if/id registra
if_id_flush_i => if_id_flush_s,
-- kontrolni signali za zaustavljanje protocne obrade  
pc_en_i => pc_en_s,
if_id_en_i => if_id_s
);

CONTROL_PATH: entity work.control_path
port map(
-- sinhronizacija
clk => clk,
reset => reset,
-- instrukcija dolazi iz datapah-a
instruction_i => instruction_s,
-- Statusni signaln iz datapath celine
branch_condition_i => branch_condition_s,
-- kontrolni signali koji se prosledjiuju u datapath
mem_to_reg_o => mem_to_reg_s,
alu_op_o => alu_op_s,
alu_src_b_o => alu_src_s,
rd_we_o => rd_we_i_s,
pc_next_sel_o => pc_next_sel_s,
data_mem_we_o => data_mem_we_o,
jalr_o => jalr_s,
-- kontrolni signali za prosledjivanje operanada u ranije faze protocne obrade
alu_forward_a_o => alu_forward_a_s,
alu_forward_b_o => alu_forward_b_s,
branch_forward_a_o => branch_forward_a_s,
branch_forward_b_o => branch_forward_b_s,
--sw_forward_o => sw_forward_s, --IZMJENAAAAAA
-- kontrolni signal za resetovanje if/id registra
if_id_flush_o => if_id_flush_s,
-- kontrolni signali za zaustavljanje protocne obrade
pc_en_o => pc_en_s,
if_id_en_o => if_id_s
);

end Behavioral;


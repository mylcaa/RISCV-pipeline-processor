library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_path is
port(
-- sinhronizacioni signali
clk : in std_logic;
reset : in std_logic;
-- interfejs ka memoriji za instrukcije
instr_mem_address_o : out std_logic_vector (31 downto 0);
instr_mem_read_i : in std_logic_vector(31 downto 0);
instruction_o : out std_logic_vector(31 downto 0);
-- interfejs ka memoriji za podatke
data_mem_address_o : out std_logic_vector(31 downto 0);
data_mem_write_o : out std_logic_vector(31 downto 0);
data_mem_read_i : in std_logic_vector (31 downto 0);
-- kontrolni signali
mem_to_reg_i : in std_logic;                                --isk
alu_op_i : in std_logic_vector (4 downto 0);                --isk
alu_src_b_i : in std_logic;                                 --isk
pc_next_sel_i : in std_logic_vector(1 downto 0);            --isk
rd_we_i : in std_logic;                                     --isk
branch_condition_o : out std_logic;                         --isk
--dodatni kontrolni signal za JALR:
jalr_i : in std_logic;
-- kontrolni signali za prosledjivanje operanada u ranije faze protocne
--obrade
alu_forward_a_i : in std_logic_vector (1 downto 0); 
alu_forward_b_i : in std_logic_vector (1 downto 0);
branch_forward_a_i : in std_logic;
branch_forward_b_i : in std_logic;
-- kontrolni signal za resetovanje if/id registra
if_id_flush_i : in std_logic;
-- kontrolni signali za zaustavljanje protocne obrade  
pc_en_i : in std_logic;
if_id_en_i : in std_logic
);
end entity;

architecture Behavioral of data_path is

--IF FAZA SIGNALI:
signal pc_if_d, pc_if, inc_norm_if: std_logic_vector(31 downto 0);
--ID FAZA SINGALI:
signal pc_4_id, instr_id, rs1_id, rs2_id, imm_id, pc_id, pc_bran_id, muxa_id, muxb_id: std_logic_vector(31 downto 0);
signal rd_id: std_logic_vector(4 downto 0);
--EX FAZA SIGNALI:
signal pc_4_ex, a, b, mux_ex, rs1_ex, rs2_ex, imm_ex, rs2_sw_ex, alu_res_ex: std_logic_vector(31 downto 0);
signal rd_ex: std_logic_vector(4 downto 0);
--MEM FAZA SIGNALI:
signal pc_4_mem, rd_data_mem: std_logic_vector(31 downto 0);
signal rd_mem: std_logic_vector(4 downto 0);
--WB FAZA SIGNALI:
signal pc_4_wb, mux1_wb, mux0_wb, rd_data_wb, rd_data: std_logic_vector(31 downto 0);
signal rd_wb: std_logic_vector(4 downto 0);

begin

--IF FAZA ***********************************************************************************************************

--mux pred pc
MUX_PC: process(pc_next_sel_i, inc_norm_if, pc_bran_id, rd_data_mem) is
begin
    if(pc_next_sel_i="00") then
        pc_if_d <= inc_norm_if;
    elsif(pc_next_sel_i="01") then
        pc_if_d <= pc_bran_id;
    elsif(pc_next_sel_i="10") then
        pc_if_d <= rd_data_mem;
    else
        pc_if_d <= (others => '0');
    end if;
end process;
--pc_if_d <= inc_norm_if when pc_next_sel_i='0' else
--           pc_bran_id;          

--uvecanje PC za jedan
inc_norm_if <= std_logic_vector(unsigned(pc_if)+4);
--proslijedjivanje adrese memoriji
instr_mem_address_o <= pc_if;

PC: process(clk) is
begin
    if(rising_edge(clk)) then
        if(reset='0') then
            pc_if <= (others => '0');
        else
            if(pc_en_i='1') then
                pc_if <= pc_if_d;
            end if;
        end if;   
    end if;
end process;

----------------------------------------------------------------------------------------------------------------------------------

IF_ID_reg: process(clk) is
begin
    if(rising_edge(clk)) then
        if(reset='0') then
            instr_id <= (others => '0');
            pc_id <= (others => '0');
            --JALR
            pc_4_id <= (others => '0');
        else
            if(if_id_en_i='1') then
                if(if_id_flush_i='1') then
                    instr_id <= (others => '0');
                    pc_id <= (others => '0');
                    --JALR
                    pc_4_id <= (others => '0');
                else
                    instr_id <= instr_mem_read_i; --prihvat instrukcije iz mem
                    pc_id <= pc_if; --proslijedi pc iz if u id fazu za slucaj skoka
                    --JALR
                    pc_4_id <= inc_norm_if;
                end if;
            end if;
        end if;       
    end if;
end process;

--ID FAZA ---------------------------------------------------------------------------------------------------------------------------

instruction_o <= instr_id;

REG_BANKA: entity work.register_bank
port map(
clk => clk,
reset => reset,
rs1_address_i => instr_id(19 downto 15),
rs1_data_o => rs1_id,
rs2_address_i => instr_id(24 downto 20),
rs2_data_o => rs2_id,
rd_we_i => rd_we_i,
rd_address_i => rd_wb,
rd_data_i => rd_data
);

--tu samo radi lakseg prepoznavanja signala za adresu rd:
rd_id <= instr_id(11 downto 7);

IMMEDIATE: entity work.immediate
port map(
instruction_i => instr_id,
immediate_extended_o => imm_id
);
--donji dio za branch skok:
pc_bran_id <= std_logic_vector(unsigned(pc_id) + unsigned(shift_left(unsigned(imm_id), 1)));

--branch forward:
muxa_id <= rs1_id when branch_forward_a_i='0' else
           rd_data_mem;
muxb_id <= rs2_id when branch_forward_b_i='0' else
           rd_data_mem;
branch_condition_o <= '0' when muxa_id /= muxb_id else
                      '1';

--*******************************************************************************************************************

ID_EX_reg: process(clk) is
begin
    if(rising_edge(clk)) then
        if(reset='0') then
           rs1_ex <= (others => '0');
           rs2_ex <= (others => '0');
           imm_ex <= (others => '0');
           rd_ex <=  (others => '0');
           rs2_sw_ex <= (others => '0');
           --JALR
           pc_4_ex <= (others => '0');
        else
           rs1_ex <= rs1_id;
           rs2_ex <= rs2_id;
           imm_ex <= imm_id;
           rd_ex <= rd_id;
           rs2_sw_ex <= rs2_id;
           --JALR
           pc_4_ex <= pc_4_id;
        end if;
    end if;
end process;

--EX FAZA ***********************************************************************************************************

MUX_A_ALU_EX: process(alu_forward_a_i, rs1_ex, rd_data_wb, rd_data_mem) is
begin
    if(alu_forward_a_i="00") then
        a <= rs1_ex;
    elsif(alu_forward_a_i="01") then
        a <= rd_data_wb;
    elsif(alu_forward_a_i="10") then
        a <= rd_data_mem;
    else
        a <= (others => '0');
    end if;
end process;

MUX_B_ALU_EX: process(alu_forward_b_i, rs2_ex, rd_data_wb, rd_data_mem) is
begin
    if(alu_forward_b_i="00") then
        mux_ex <= rs2_ex;
    elsif(alu_forward_b_i="01") then
        mux_ex <= rd_data_wb;
    elsif(alu_forward_b_i="10") then
        mux_ex <= rd_data_mem;
    else
        mux_ex <= (others => '0');
    end if;
end process;

--mux_alu:
b <= mux_ex when alu_src_b_i='0' else
          imm_ex;

ALU: entity work.ALU
port map(
a_i => a,
b_i => b,
op_i => alu_op_i,
res_o => alu_res_ex
);

--*******************************************************************************************************************

EX_MEM_reg: process(clk) is
begin
    if(rising_edge(clk)) then
        if(reset='0') then
           rd_data_mem <= (others => '0');
           rd_mem <= (others => '0');
           data_mem_write_o <= (others => '0');
           --JALR
           pc_4_mem <= (others => '0');
        else
           rd_data_mem <= alu_res_ex;
           rd_mem <= rd_ex;
           data_mem_write_o <= rs2_sw_ex;
           --JALR
           pc_4_mem <= pc_4_ex;
        end if;
    end if;
end process;

--MEM FAZA ***********************************************************************************************************

data_mem_address_o <= rd_data_mem;

--*******************************************************************************************************************

MEM_WB_reg: process(clk) is
begin
    if(rising_edge(clk)) then
        if(reset='0') then
           mux1_wb <= (others => '0');
           mux0_wb <= (others => '0');
           rd_wb <= (others => '0');
           --JALR
           pc_4_wb <= (others => '0');
        else
           mux1_wb <= data_mem_read_i;
           mux0_wb <= rd_data_mem;
           rd_wb <= rd_mem;
           --JALR
           pc_4_wb <= pc_4_mem;
        end if;
    end if;
end process;

rd_data_wb <= mux0_wb when mem_to_reg_i='0' else
           mux1_wb;
           
rd_data <= rd_data_wb when jalr_i='0' else
           pc_4_wb;

end Behavioral;


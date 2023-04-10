library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity control_path is
port (
-- sinhronizacija
clk : in std_logic;
reset : in std_logic;
-- instrukcija dolazi iz datapah-a
instruction_i : in std_logic_vector (31 downto 0);
-- Statusni signaln iz datapath celine
branch_condition_i : in std_logic;
-- kontrolni signali koji se prosledjiuju u datapath
mem_to_reg_o : out std_logic;
alu_op_o : out std_logic_vector(4 downto 0);
alu_src_b_o : out std_logic;
rd_we_o : out std_logic;
pc_next_sel_o : out std_logic_vector(1 downto 0);
data_mem_we_o : out std_logic_vector(3 downto 0);
jalr_o: out std_logic;
-- kontrolni signali za prosledjivanje operanada u ranije faze protocne obrade
alu_forward_a_o : out std_logic_vector (1 downto 0);
alu_forward_b_o : out std_logic_vector (1 downto 0);
branch_forward_a_o : out std_logic; -- mux a
branch_forward_b_o : out std_logic; -- mux b
--sw_forward_o: out std_logic_vector(1 downto 0); --IZMJENAAAAAA
-- kontrolni signal za resetovanje if/id registra
if_id_flush_o : out std_logic;
-- kontrolni signali za zaustavljanje protocne obrade
pc_en_o : out std_logic;
if_id_en_o : out std_logic
);
end entity;


architecture Behavioral of control_path is

--ID FAZA 
signal jalr_id_s, control_pass, branch_id_s, mem_to_reg_id_s, data_mem_we_id_s, alu_src_b_id_s, rd_we_id_s, rs1_in_use_id, rs2_in_use_id: std_logic;
signal alu_2bit_op_id_s: std_logic_vector(1 downto 0);
signal rd_address_id_s, rs1_address_id_s, rs2_address_id_s: std_logic_vector(4 downto 0);
signal funct3_id_s: std_logic_vector(2 downto 0);
signal funct7_id_s: std_logic_vector(6 downto 0);


--EX FAZA
signal  jalr_ex_s, mem_to_reg_ex_s, rd_we_ex_s, alu_src_b_ex_s, data_mem_we_ex_s: std_logic;
signal rd_address_ex_s, rs1_address_ex_s, rs2_address_ex_s: std_logic_vector(4 downto 0);
signal funct3_ex_s: std_logic_vector(2 downto 0);
signal funct7_ex_s: std_logic_vector(6 downto 0);
signal alu_2bit_op_ex_s: std_logic_vector(1 downto 0);

--MEM FAZA
signal rd_address_mem_s: std_logic_vector(4 downto 0);
signal jalr_mem_s, mem_to_reg_mem_s, rd_we_mem_s, data_mem_we_mem_s: std_logic;

--WB FAZA
signal jalr_wb_s, rd_we_wb_s: std_logic;
signal rd_address_wb_s: std_logic_vector(4 downto 0);

begin

--ID FAZA -------------------------------------------------------------------------------------

rd_address_id_s <= instruction_i(11 downto 7);
rs1_address_id_s <= instruction_i(19 downto 15);
rs2_address_id_s <= instruction_i(24 downto 20);
funct3_id_s <= instruction_i(14 downto 12);
funct7_id_s <= instruction_i(31 downto 25);

HAZARD_UNIT: entity work.hazard_unit
port map(
rs1_address_id_i => rs1_address_id_s,
rs2_address_id_i => rs2_address_id_s,
rs1_in_use_i => rs1_in_use_id,
rs2_in_use_i => rs2_in_use_id,
branch_id_i => branch_id_s,
rd_address_ex_i => rd_address_ex_s,
mem_to_reg_ex_i => mem_to_reg_ex_s,
rd_we_ex_i => rd_we_ex_s,
rd_address_mem_i => rd_address_mem_s,
mem_to_reg_mem_i => mem_to_reg_mem_s,
pc_en_o => pc_en_o,
if_id_en_o => if_id_en_o,
control_pass_o => control_pass
);

CTRL_DEC: entity work.ctrl_decoder
port map(
opcode_i => instruction_i(6 downto 0),
branch_o => branch_id_s,
mem_to_reg_o => mem_to_reg_id_s,           
data_mem_we_o => data_mem_we_id_s,             
alu_src_b_o => alu_src_b_id_s,                  
rd_we_o => rd_we_id_s,                        
rs1_in_use_o => rs1_in_use_id,          
rs2_in_use_o => rs2_in_use_id,           
alu_2bit_op_o => alu_2bit_op_id_s,
jalr_o => jalr_id_s
);

branch_jalr: process(branch_condition_i, branch_id_s, jalr_mem_s) is
begin
    if((branch_condition_i and branch_id_s) = '1') then
        pc_next_sel_o <= "01";
    elsif(jalr_mem_s = '1') then
        pc_next_sel_o <= "10";
    else
        pc_next_sel_o <= "00";
    end if;
end process;

--pc_next_sel_o <= branch_id_s and branch_condition_i;

flush_stall: if_id_flush_o <= (branch_id_s and branch_condition_i) or jalr_id_s or jalr_ex_s or jalr_mem_s;

--ID-EX REG -------------------------------------------------------------------------------------

ID_EX_REG: process(clk) is
begin

if(rising_edge(clk)) then
    if(reset='0') then
        mem_to_reg_ex_s <= '0';
        data_mem_we_ex_s <= '0';
        rd_we_ex_s <= '0';
        alu_src_b_ex_s <= '0';
        alu_2bit_op_ex_s <= (others => '0');
        jalr_ex_s <= '0';
        
        rd_address_ex_s <= (others => '0');
        rs1_address_ex_s <= (others => '0');
        rs2_address_ex_s <= (others => '0');
        funct3_ex_s <= (others => '0');
        funct7_ex_s <= (others => '0');
    else
        if(control_pass = '0') then
            mem_to_reg_ex_s <= '0';
            data_mem_we_ex_s <= '0';
            rd_we_ex_s <= '0';
            alu_src_b_ex_s <= '0';
            alu_2bit_op_ex_s <= (others => '0');
            jalr_ex_s <= '0';
            
            rd_address_ex_s <= (others => '0');
            rs1_address_ex_s <= (others => '0');
            rs2_address_ex_s <= (others => '0');
            funct3_ex_s <= (others => '0');
            funct7_ex_s <= (others => '0');
        else
            mem_to_reg_ex_s <= mem_to_reg_id_s;
            data_mem_we_ex_s <= data_mem_we_id_s;
            rd_we_ex_s <= rd_we_id_s;
            alu_src_b_ex_s <= alu_src_b_id_s;
            alu_2bit_op_ex_s <= alu_2bit_op_id_s;
            jalr_ex_s <= jalr_id_s;
            
            rd_address_ex_s <= rd_address_id_s;
            rs1_address_ex_s <= rs1_address_id_s;
            rs2_address_ex_s <= rs2_address_id_s;
            funct3_ex_s <= funct3_id_s;
            funct7_ex_s <= funct7_id_s;
        end if;
    end if;
end if;

end process;

--EX FAZA -------------------------------------------------------------------------------------

FORWARDING_UNIT: entity work.forwarding_unit
port map(
rs1_address_id_i => rs1_address_id_s,
rs2_address_id_i => rs2_address_id_s,
-- ulazi iz EX faze
rs1_address_ex_i => rs1_address_ex_s,
rs2_address_ex_i => rs2_address_ex_s,
--data_mem_we_ex_i => data_mem_we_ex_s, --izmjena
-- ulazi iz MEM faze
mem_to_reg_mem_i => mem_to_reg_mem_s,
rd_we_mem_i => rd_we_mem_s,
rd_address_mem_i => rd_address_mem_s,
-- ulazi iz WB faze
rd_we_wb_i => rd_we_wb_s,
rd_address_wb_i => rd_address_wb_s,
-- izlazi za prosledjivanje operanada ALU jedinici
alu_forward_a_o => alu_forward_a_o,
alu_forward_b_o => alu_forward_b_o,
-- izlazi za prosledjivanje operanada komparatoru za odredjivanje uslova skoka
branch_forward_a_o => branch_forward_a_o,
branch_forward_b_o => branch_forward_b_o
--izlaz za prosledjivanje operanda muxu za sw operacije
--sw_forward => sw_forward_o --izmjena
);

ALU_DECODER: entity work.alu_decoder
port map(
--******** Controlpath ulazi *********
alu_2bit_op_i => alu_2bit_op_ex_s,
--******** Polja instrukcije *******
funct3_i => funct3_ex_s,
funct7_i => funct7_ex_s,
--******** Datapath izlazi ********
alu_op_o => alu_op_o
);

alu_src_b_o <= alu_src_b_ex_s;

--EX_MEM_REG: -------------------------------------------------------------------------------------

EX_MEM_REG: process(clk) is
begin
if(rising_edge(clk)) then
    if(reset='0') then
        mem_to_reg_mem_s <= '0';
        data_mem_we_mem_s <= '0';
        rd_we_mem_s <= '0';
        rd_address_mem_s <= (others => '0');
        jalr_mem_s <= '0';
    else
        mem_to_reg_mem_s <= mem_to_reg_ex_s;
        data_mem_we_mem_s <= data_mem_we_ex_s;
        rd_we_mem_s <= rd_we_ex_s;
        rd_address_mem_s <= rd_address_ex_s;
        jalr_mem_s <= jalr_ex_s;
    end if;
end if;
end process;

--MEM FAZA-------------------------------------------------------------------------------------

MUX_MEM: data_mem_we_o <= "1111" when data_mem_we_mem_s = '1' else
                          "0000";
--MEM-WB REG + WB: -------------------------------------------------------------------------------------

MEM_WB_REG: process(clk) is
begin
if(rising_edge(clk)) then
    if(reset='0') then
        mem_to_reg_o <= '0';
        rd_we_wb_s <= '0';
        rd_address_wb_s <= (others => '0');
        jalr_wb_s <= '0';
        
    else
        mem_to_reg_o <= mem_to_reg_mem_s;
        rd_we_wb_s <= rd_we_mem_s;
        rd_address_wb_s <= rd_address_mem_s;
        jalr_wb_s <= jalr_mem_s;
    end if;
end if;
end process;

rd_we_o <= rd_we_wb_s;
jalr_o <= jalr_wb_s;
---------------------------------------------------------------------------------------

end Behavioral;


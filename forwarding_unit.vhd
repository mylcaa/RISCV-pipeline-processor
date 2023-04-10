library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity forwarding_unit is
port (
-- ulazi iz ID faze
rs1_address_id_i : in std_logic_vector(4 downto 0);
rs2_address_id_i : in std_logic_vector(4 downto 0);
-- ulazi iz EX faze
rs1_address_ex_i : in std_logic_vector(4 downto 0);
rs2_address_ex_i : in std_logic_vector(4 downto 0);
--data_mem_we_ex_i : in std_logic; --izmjena
-- ulazi iz MEM faze
mem_to_reg_mem_i : in std_logic;
rd_we_mem_i : in std_logic;
rd_address_mem_i : in std_logic_vector(4 downto 0);
-- ulazi iz WB faze
rd_we_wb_i : in std_logic;
rd_address_wb_i : in std_logic_vector(4 downto 0);
-- izlazi za prosledjivanje operanada ALU jedinici
alu_forward_a_o : out std_logic_vector (1 downto 0);
alu_forward_b_o : out std_logic_vector(1 downto 0);
-- izlazi za prosledjivanje operanada komparatoru za odredjivanje uslova skoka
branch_forward_a_o : out std_logic;
branch_forward_b_o : out std_logic
--izlaz za prosledjivanje operanda muxu za sw operacije
--sw_forward: out std_logic_vector(1 downto 0) --izmjena
);
end entity;

architecture Behavioral of forwarding_unit is

begin

EX_FORWARD: process(rs1_address_ex_i, rs2_address_ex_i, rd_address_mem_i, rd_we_mem_i, rd_address_wb_i, rd_we_wb_i, mem_to_reg_mem_i) is
begin  --data_mem_we_ex_i

--forward za ALU i sw ako nema zavisnosti (default):
alu_forward_a_o <="00";
alu_forward_b_o <="00";
--sw_forward <= "00";

--neophodno je postaviti uslove za forwarding iz MEM i WB faze
--WB je iza MEM jer MEM faza sadrzi "svjezije" info u slucaju da se isti registar mijenjao dva puta za redom
--if-ovi za WB i MEM su nezavisni jer se forwarding moze desiti i za jednu i za drugu fazu u istom taktu 
--ako smo npr mijenjali rs1 u MEM a rs2 u WB
 --neophodno je prvo razgraniciti da li je u slucaju sw operacija ili neka druga -> uslov: data_mem_we_ex_i='1'

--if(data_mem_we_ex_i='0') then --slucaj kada nemamo sw
    
    if(rd_we_wb_i='1' and rd_address_wb_i/="00000") then
        if(rs1_address_ex_i = rd_address_wb_i) then
            alu_forward_a_o <="01";
        end if;
        
        if(rs2_address_ex_i = rd_address_wb_i) then
            alu_forward_b_o <="01";
        end if;
    end if;
    
    if(rd_we_mem_i='1' and rd_address_mem_i/="00000") then
        if(rs1_address_ex_i = rd_address_mem_i) then
            alu_forward_a_o <="10";
        end if;
        
        if(rs2_address_ex_i = rd_address_mem_i) then
            alu_forward_b_o <="10";
        end if;
    end if;
    
--else                         --slucaj kada imamo sw

    --if(rd_address_wb_i/="00000") then
        --if(rs2_address_ex_i = rd_address_wb_i) then
            --sw_forward <="01";
        --end if;
    --end if;
    
    --if(rd_address_mem_i/="00000") then
        --if(mem_to_reg_mem_i='0') then --nije lw prije sw nego R ili I tip
           -- if(rs2_address_ex_i = rd_address_mem_i) then
               -- sw_forward <="10";
           -- end if;
       -- else                        --jeste lw prije sw
          --  if(rs2_address_ex_i = rd_address_mem_i) then
          --      sw_forward <="11";
          --  end if;
        --end if;
    --end if;

--end if;

end process;

ID_FORWARD: process(rs1_address_id_i, rs2_address_id_i, rd_address_mem_i, rd_we_mem_i) is
begin

branch_forward_a_o <= '0';
branch_forward_b_o <= '0';

if(rd_we_mem_i='1' and rd_address_mem_i/="00000") then
        if(rs1_address_id_i = rd_address_mem_i) then
            branch_forward_a_o <='1';
        end if;
        
        if(rs2_address_id_i = rd_address_mem_i) then
            branch_forward_b_o <='1';
        end if;
end if;

end process;

end Behavioral;